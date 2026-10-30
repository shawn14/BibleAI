// Shawn 2026-10-30: replace the 2.0 (6) submission with 2.0.1 (8, iCloud sync).
// Cancels the active review submission, waits until the version is editable, renames it 2.0.1.
const APP = "6756225286";
const EDITABLE = ["PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED"];
export default async (api) => {
  const log = [];
  const subs = (await api.get(`/v1/reviewSubmissions?filter[app]=${APP}&filter[platform]=IOS&limit=10`)).data
    .filter((s) => ["WAITING_FOR_REVIEW", "IN_REVIEW", "READY_FOR_REVIEW", "UNRESOLVED_ISSUES"].includes(s.attributes.state));
  for (const s of subs) {
    if (s.attributes.state === "IN_REVIEW") throw new Error("already IN_REVIEW; not cancelling");
    await api.patch(`/v1/reviewSubmissions/${s.id}`, { data: { type: "reviewSubmissions", id: s.id, attributes: { canceled: true } } });
    log.push(`canceled submission ${s.id} (${s.attributes.state})`);
  }
  let v;
  for (let i = 0; i < 30; i++) {
    v = (await api.get(`/v1/apps/${APP}/appStoreVersions?filter[platform]=IOS&limit=5`)).data
      .find((x) => ["2.0", "2.0.1"].includes(x.attributes.versionString) && x.attributes.appStoreState !== "READY_FOR_SALE");
    if (v && EDITABLE.includes(v.attributes.appStoreState)) break;
    await new Promise((r) => setTimeout(r, 6000));
  }
  log.push(`version ${v.attributes.versionString} now ${v.attributes.appStoreState}`);
  if (!EDITABLE.includes(v.attributes.appStoreState)) throw new Error("version not editable yet; rerun later");
  if (v.attributes.versionString !== "2.0.1") {
    await api.patch(`/v1/appStoreVersions/${v.id}`, { data: { type: "appStoreVersions", id: v.id, attributes: { versionString: "2.0.1" } } });
    log.push("renamed to 2.0.1");
  }
  return log;
};
