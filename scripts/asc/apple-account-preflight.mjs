import { execFileSync } from 'node:child_process';

export default async (api) => {
  const unique = JSON.parse(execFileSync('ruby', ['-rxcodeproj', '-rjson', '-e',
    'p = Xcodeproj::Project.open("BibleAI.xcodeproj"); ' +
    'a = p.targets.select { |t| t.product_type == "com.apple.product-type.application" }; ' +
    'abort "Expected one app target" unless a.length == 1; ' +
    'puts JSON.generate(a.first.build_configurations.map { |c| c.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] }.uniq)'
  ], { encoding: 'utf8' }));
  if (unique.length !== 1 || typeof unique[0] !== 'string') throw new Error('Expected one native app identifier');
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
