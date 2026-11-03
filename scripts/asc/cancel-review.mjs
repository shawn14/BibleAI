// Withdraw the active iOS review submission (not IN_REVIEW) and wait until the version is editable.
const APP = "6756225286";
const EDITABLE = ["PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED"];
const VERSION = process.env.ASC_VERSION || "2.0.2";
export default async (api) => {
  const log = [];
  const subs = (await api.get(`/v1/reviewSubmissions?filter[app]=${APP}&filter[platform]=IOS&limit=10`)).data
    .filter((s) => ["WAITING_FOR_REVIEW", "READY_FOR_REVIEW", "UNRESOLVED_ISSUES"].includes(s.attributes.state));
  for (const s of subs) {
    await api.patch(`/v1/reviewSubmissions/${s.id}`, { data: { type: "reviewSubmissions", id: s.id, attributes: { canceled: true } } });
    log.push(`canceled ${s.id} (${s.attributes.state})`);
  }
  let v;
  for (let i = 0; i < 30; i++) {
    v = (await api.get(`/v1/apps/${APP}/appStoreVersions?filter[platform]=IOS&filter[versionString]=${VERSION}`)).data[0];
    if (EDITABLE.includes(v.attributes.appStoreState)) break;
    await new Promise((r) => setTimeout(r, 6000));
  }
  log.push(`${VERSION} ${v.attributes.appStoreState}`);
  return log;
};
