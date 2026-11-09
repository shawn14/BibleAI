//
//  ContentView.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

struct ContentView: View {
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @StateObject private var growth = GrowthStore.shared
    @State private var requestedPlace: ReadingPlace?
    @State private var requestedPlan: ReadingPlan?
    @State private var selectedTab = 0
    @State private var invalidInvitation = false

    var body: some View {
        Group {
            if let invitation = growth.pendingInvitation {
                InvitationLandingView(invitation: invitation) {
                    showOnboarding = false
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    growth.completeInvitation()
                    if let place = invitation.readingPlace {
                        requestedPlace = place
                        selectedTab = 0
                    } else if let plan = ReadingPlanService.shared.availablePlans.first(where: { $0.id == invitation.planID }) {
                        ReadingPlanService.shared.startPlan(plan)
                        requestedPlan = plan
                        selectedTab = 1
                    }
                }
            } else {
                TabView(selection: $selectedTab) {
                    ScriptureReaderView(requestedPlace: $requestedPlace, isActive: selectedTab == 0 && !showOnboarding, onChoosePlan: { selectedTab = 1 })
                        .tabItem { Label("The Bible", systemImage: "book") }.tag(0)
                    ReadingPlansListView(requestedPlan: $requestedPlan)
                        .tabItem { Label("Plans", systemImage: "list.bullet.rectangle") }.tag(1)
                    HighlightsListView()
                        .tabItem { Label("Saved", systemImage: "heart") }.tag(2)
                    AccountView()
                        .tabItem { Label("Account", systemImage: "person.crop.circle") }.tag(3)
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView(isPresented: $showOnboarding)
                }
            }
        }
        .tint(.accentColor)
        .onOpenURL { url in if !growth.receive(url: url) { invalidInvitation = true } }
        .alert("Couldn't open this invitation", isPresented: $invalidInvitation) {
            Button("OK", role: .cancel) { }
        } message: { Text("Ask the sender for a new BibleAI link. Your reading progress is unchanged.") }
    }
}

struct ChatContainerView: View {
    @StateObject private var conversationService = ConversationService.shared
    @Binding var currentConversation: Conversation?
    @State private var showConversationsList = false

    var body: some View {
        NavigationView {
            if let conversation = currentConversation {
                ChatView(conversation: conversation)
                    .id(conversation.id) // Force recreate when conversation changes
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                showConversationsList = true
                            }) {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showConversationsList) {
            NavigationView {
                ConversationListSheet(currentConversation: $currentConversation, isPresented: $showConversationsList)
            }
        }
    }
}

struct EmptyChatView: View {
    let onNewChat: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))

                VStack(spacing: 8) {
                    Text("BibleAI")
                        .font(.title)
                        .fontWeight(.semibold)

                    Text("Your AI-powered Bible study companion")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Button(action: onNewChat) {
                Text("Start Conversation")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: 300)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.6, green: 0.4, blue: 0.2))
                    .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ConversationListSheet: View {
    @StateObject private var conversationService = ConversationService.shared
    @Binding var currentConversation: Conversation?
    @Binding var isPresented: Bool

    var body: some View {
        List {
            // New Chat button at the top
            Section {
                Button(action: {
                    let newConversation = conversationService.createConversation()
                    currentConversation = newConversation
                    isPresented = false
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                        Text("New Chat")
                            .foregroundColor(.primary)
                            .fontWeight(.medium)
                    }
                }
            }

            // Existing conversations
            Section {
                ForEach(conversationService.conversations) { conversation in
                    Button(action: {
                        currentConversation = conversation
                        isPresented = false
                    }) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(conversation.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Text(conversation.preview)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteConversations)
            } header: {
                Text("Recent")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Conversations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    isPresented = false
                }
                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
            }
        }
    }

    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            let conversation = conversationService.conversations[index]
            conversationService.deleteConversation(conversation)

            // If we deleted the current conversation, create a new one
            if currentConversation?.id == conversation.id {
                currentConversation = conversationService.createConversation()
            }
        }
    }
}

struct BibleReaderView: View {
    var body: some View {
        NavigationView {
            BibleBooksListView()
        }
    }
}

#Preview {
    ContentView()
}
