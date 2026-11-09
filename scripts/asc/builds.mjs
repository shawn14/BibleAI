// Read-only: the 8 most recent builds for every version, any processing state.
const APP = "6756225286";
export default async (api) => {
  const r = await api.get(`/v1/builds?filter[app]=${APP}&filter[processingState]=PROCESSING,FAILED,INVALID,VALID&sort=-uploadedDate&limit=8&include=preReleaseVersion`);
  const pre = Object.fromEntries((r.included || []).map((v) => [v.id, v.attributes.version]));
  const rows = r.data.map((b) => ({
    id: b.id, version: pre[b.relationships.preReleaseVersion.data?.id],
    build: b.attributes.version, state: b.attributes.processingState,
    uploaded: b.attributes.uploadedDate, expired: b.attributes.expired,
    encryption: b.attributes.usesNonExemptEncryption,
  }));
  if (rows[0]?.state === "VALID") {
    const detail = await api.get(`/v1/builds/${rows[0].id}/buildBetaDetail`);
    rows[0].internalBuildState = detail.data.attributes.internalBuildState;
  }
  return rows;
};
