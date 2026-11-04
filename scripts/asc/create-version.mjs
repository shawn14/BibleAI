// Create the next App Store version (default 2.0.2) if it does not exist, and set the new app name
// and subtitle on the editable app info. Text fields are pushed later by deliver (submit_review).
import fs from "node:fs";
import path from "node:path";
const APP = "6756225286";
const VERSION = process.env.ASC_VERSION || "2.0.2";
const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), "../..");
const txt = (f) => fs.readFileSync(path.join(root, "docs/aso/en-US", f), "utf8").trim();
export default async (api) => {
  const log = [];
  let v = (await api.get(`/v1/apps/${APP}/appStoreVersions?filter[platform]=IOS&filter[versionString]=${VERSION}`)).data[0];
  if (!v) {
    v = (await api.post(`/v1/appStoreVersions`, { data: { type: "appStoreVersions",
      attributes: { platform: "IOS", versionString: VERSION, releaseType: "MANUAL", copyright: "2026 Center Mark Capital, LLC" },
      relationships: { app: { data: { type: "apps", id: APP } } } } })).data;
    log.push(`created ${VERSION} ${v.id}`);
  } else log.push(`${VERSION} exists ${v.attributes.appStoreState}`);
  const infos = (await api.get(`/v1/apps/${APP}/appInfos`)).data;
  const info = infos.find((i) => ["PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED"].includes(i.attributes.appStoreState ?? i.attributes.state));
  if (!info) throw new Error("no editable app info: " + JSON.stringify(infos.map((i) => i.attributes)));
  const loc = (await api.get(`/v1/appInfos/${info.id}/appInfoLocalizations`)).data.find((l) => l.attributes.locale === "en-US");
  await api.patch(`/v1/appInfoLocalizations/${loc.id}`, { data: { type: "appInfoLocalizations", id: loc.id,
    attributes: { name: txt("name.txt"), subtitle: txt("subtitle.txt"), privacyPolicyUrl: txt("privacy_url.txt") } } });
  const after = (await api.get(`/v1/appInfoLocalizations/${loc.id}`)).data.attributes;
  log.push(`name=${after.name} | subtitle=${after.subtitle}`);
  return log;
};
