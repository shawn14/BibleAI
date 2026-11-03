import inspect from './apple-account-preflight.mjs';

export default async (api) => {
  if (process.env.APPLY_APPLE_ACCOUNT !== '1') throw new Error('Use the approved enable_apple_account action');
  const before = await inspect(api);
  if (before.signInWithAppleEnabled) return { before, after: before, writes: 0 };
  await api.post('/v1/bundleIdCapabilities', {
    data: {
      type: 'bundleIdCapabilities',
      attributes: {
        capabilityType: 'APPLE_ID_AUTH',
        // Same primary-app configuration used by fastlane produce.
        settings: [{ key: 'APPLE_ID_AUTH_APP_CONSENT', options: [{ key: 'PRIMARY_APP_CONSENT' }] }]
      },
      relationships: { bundleId: { data: { type: 'bundleIds', id: before.bundleResourceID } } }
    }
  });
  const after = await inspect(api);
  if (!after.signInWithAppleEnabled || after.bundleResourceID !== before.bundleResourceID
      || before.capabilities.some((type) => !after.capabilities.includes(type))) {
    throw new Error('Apple capability readback mismatch; stop before any signing or upload');
  }
  return { before, after, writes: 1, next: 'Regenerate and verify the signed provisioning profile before device validation.' };
};
