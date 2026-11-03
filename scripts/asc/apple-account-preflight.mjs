import fs from 'node:fs';

export default async (api) => {
  const project = fs.readFileSync('BibleAI.xcodeproj/project.pbxproj', 'utf8');
  const identifiers = [...project.matchAll(/PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);/g)]
    .map((match) => match[1].replaceAll('"', ''))
    .filter((value) => !value.endsWith('UITests'));
  const unique = [...new Set(identifiers)];
  if (unique.length !== 1) throw new Error('Expected one native app identifier');
  const identifier = unique[0];
  const bundle = (await api.get(`/v1/bundleIds?filter[identifier]=${encodeURIComponent(identifier)}&filter[platform]=IOS`))
    .data.find((item) => item.attributes.identifier === identifier);
  if (!bundle) throw new Error('Native App ID was not found');
  const capabilities = (await api.get(`/v1/bundleIds/${bundle.id}/bundleIdCapabilities`)).data;
  return {
    observedAt: new Date().toISOString(), identifier, bundleResourceID: bundle.id,
    capabilities: capabilities.map((item) => item.attributes.capabilityType),
    signInWithAppleEnabled: capabilities.some((item) => item.attributes.capabilityType === 'APPLE_ID_AUTH'),
    writes: 0
  };
};
