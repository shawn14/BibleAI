// Read-only: the 8 most recent builds for every version, any processing state.
const APP = "6756225286";
export default async (api) => {
  const r = await api.get(`/v1/builds?filter[app]=${APP}&filter[processingState]=PROCESSING,FAILED,INVALID,VALID&sort=-uploadedDate&limit=8&include=preReleaseVersion`);
  const pre = Object.fromEntries((r.included || []).map((v) => [v.id, v.attributes.version]));
  return r.data.map((b) => ({ version: pre[b.relationships.preReleaseVersion.data?.id], build: b.attributes.version, state: b.attributes.processingState, uploaded: b.attributes.uploadedDate }));
};
