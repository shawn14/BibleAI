import AuthenticationServices
import Foundation
import Security

/// A native Apple-verified app session. Reading remains in the device's existing iCloud
/// store; purchases remain with the App Store. No passwords or Apple tokens are stored.
@MainActor
final class AppleAccount: ObservableObject {
    struct Profile: Codable {
        let userID: String
        var name: String?
        var email: String?
    }

    @Published private(set) var profile: Profile?
    @Published private(set) var checkingCredential = false
    @Published private(set) var signingIn = false
    @Published private(set) var errorMessage: String?
    var isSignedIn: Bool { profile != nil }

    private let keychain = AppleAccountKeychain()
    private let sessionKey = "apple.account.session.v1"
    private var requestState: String?
    private var revision = 0
    private var revocationObserver: NSObjectProtocol?

    init() {
        revocationObserver = NotificationCenter.default.addObserver(
            forName: ASAuthorizationAppleIDProvider.credentialRevokedNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in await self?.refreshCredential() }
        }
        Task { await refreshCredential() }
    }

    func prepare(_ request: ASAuthorizationAppleIDRequest) {
        revision += 1
        errorMessage = nil
        signingIn = true
        requestState = UUID().uuidString
        request.state = requestState
        request.requestedScopes = [.fullName, .email]
    }

    func complete(_ result: Result<ASAuthorization, Error>) {
        defer { signingIn = false; requestState = nil }
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  !credential.user.isEmpty, let expectedState = requestState,
                  credential.state == expectedState else {
                errorMessage = "Apple couldn't verify this sign-in. Please try again."
                return
            }
            do {
                // Apple normally supplies name/email only on the first authorization.
                // Keep that profile privately in Keychain for this same Apple user.
                let cached = try keychain.read(profileKey(credential.user))
                let name = credential.fullName.map {
                    PersonNameComponentsFormatter().string(from: $0)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
                let next = Profile(userID: credential.user,
                                   name: name.flatMap { $0.isEmpty ? nil : $0 } ?? cached?.name,
                                   email: credential.email ?? cached?.email)
                try keychain.write(next, key: profileKey(credential.user))
                try keychain.write(next, key: sessionKey)
                profile = next
                errorMessage = nil
            } catch {
                errorMessage = "Your sign-in couldn't be saved securely. Please unlock your iPhone and try again."
            }
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code == .canceled {
                errorMessage = nil
            } else {
                errorMessage = "Sign in with Apple didn't finish. Check your Apple Account in iPhone Settings and try again."
            }
        }
    }

    func signOut() {
        revision += 1
        do {
            try keychain.remove(sessionKey)
            profile = nil
            signingIn = false
            checkingCredential = false
            requestState = nil
            errorMessage = nil
        } catch {
            errorMessage = "Sign out couldn't finish securely. Please unlock your iPhone and try again."
        }
    }

    func refreshCredential() async {
        guard !checkingCredential, !signingIn else { return }
        let saved: Profile
        do {
            guard let stored = try keychain.read(sessionKey) else { return }
            saved = stored
        } catch {
            errorMessage = "Your saved sign-in is unavailable. Unlock your iPhone and try again."
            return
        }
        checkingCredential = true
        let current = revision
        defer { if current == revision { checkingCredential = false } }
        do {
            let state = try await ASAuthorizationAppleIDProvider().credentialState(forUserID: saved.userID)
            guard current == revision else { return }
            switch state {
            case .authorized:
                profile = saved
                errorMessage = nil
            case .revoked, .notFound, .transferred:
                // Explicit revocation ends the app session, without deleting reading or purchases.
                try keychain.remove(sessionKey)
                profile = nil
                errorMessage = "Please sign in with Apple again. Your saved reading is still here."
            @unknown default:
                profile = nil
                errorMessage = "Apple couldn't verify your account. Please sign in again."
            }
        } catch {
            guard current == revision else { return }
            // Unknown is not authorization. Keep the saved credential available for a later retry.
            profile = nil
            errorMessage = "Your Apple sign-in couldn't be checked. Please try again when you're connected."
        }
    }

    private func profileKey(_ userID: String) -> String { "apple.account.profile.v1." + userID }
}

private struct AppleAccountKeychain {
    private var service: String { Bundle.main.bundleIdentifier! }
    private struct Failure: Error { let status: OSStatus }

    func read(_ key: String) throws -> AppleAccount.Profile? {
        var query = query(key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw Failure(status: status) }
        return try JSONDecoder().decode(AppleAccount.Profile.self, from: data)
    }

    func write(_ profile: AppleAccount.Profile, key: String) throws {
        let data = try JSONEncoder().encode(profile)
        let query = query(key)
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecSuccess { return }
        guard status == errSecItemNotFound else { throw Failure(status: status) }
        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let added = SecItemAdd(item as CFDictionary, nil)
        guard added == errSecSuccess else { throw Failure(status: added) }
    }

    func remove(_ key: String) throws {
        let status = SecItemDelete(query(key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw Failure(status: status) }
    }

    private func query(_ key: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: key]
    }
}
