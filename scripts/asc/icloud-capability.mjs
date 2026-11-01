// Turn on the iCloud capability (key-value storage) for the BibleAI App ID so 2.0.1 can sync via iCloud.
const BUNDLE = "com.shawncarpenter.bibleai-companion";
export default async (api) => {
  const bundle = (await api.get(`/v1/bundleIds?filter[identifier]=${BUNDLE}&filter[platform]=IOS`)).data.find((b) => b.attributes.identifier === BUNDLE);
  if (!bundle) throw new Error("bundle id not found");
  const caps = (await api.get(`/v1/bundleIds/${bundle.id}/bundleIdCapabilities`)).data;
  const before = caps.map((c) => c.attributes.capabilityType);
  if (!before.includes("ICLOUD")) {
    await api.post(`/v1/bundleIdCapabilities`, { data: { type: "bundleIdCapabilities",
      attributes: { capabilityType: "ICLOUD", settings: [{ key: "ICLOUD_VERSION", options: [{ key: "XCODE_6" }] }] },
      relationships: { bundleId: { data: { type: "bundleIds", id: bundle.id } } } } });
  }
  const after = (await api.get(`/v1/bundleIds/${bundle.id}/bundleIdCapabilities`)).data.map((c) => c.attributes.capabilityType);
  return { bundle: bundle.id, before, after };
};
