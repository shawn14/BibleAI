// Before submitting 2.0: upload iPad 13" screenshots, drop the stale 6.5" iPhone set (6.9" scales down),
// and give the copyright line a year.
import fs from "node:fs";
import path from "node:path";
const APP = "6756225286";
const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), "../..");
async function asset(api, setId, file) {
  const res = (await api.post(`/v1/appScreenshots`, { data: { type: "appScreenshots", attributes: { fileName: path.basename(file), fileSize: fs.statSync(file).size },
    relationships: { appScreenshotSet: { data: { type: "appScreenshotSets", id: setId } } } } })).data;
  for (const op of res.attributes.uploadOperations) await api.upload(op, file);
  await api.patch(`/v1/appScreenshots/${res.id}`, { data: { type: "appScreenshots", id: res.id, attributes: { uploaded: true, sourceFileChecksum: api.md5(file) } } });
}
export default async (api) => {
  const log = [];
  const v2 = (await api.get(`/v1/apps/${APP}/appStoreVersions?filter[platform]=IOS&filter[versionString]=2.0`)).data[0];
  if (!/\d{4}/.test(v2.attributes.copyright || "")) {
    await api.patch(`/v1/appStoreVersions/${v2.id}`, { data: { type: "appStoreVersions", id: v2.id, attributes: { copyright: "2026 Center Mark Capital, LLC" } } });
    log.push("copyright: 2026 Center Mark Capital, LLC");
  }
  const loc = (await api.get(`/v1/appStoreVersions/${v2.id}/appStoreVersionLocalizations`)).data.find((l) => l.attributes.locale === "en-US");
  const sets = (await api.get(`/v1/appStoreVersionLocalizations/${loc.id}/appScreenshotSets`)).data;
  const old65 = sets.find((s) => s.attributes.screenshotDisplayType === "APP_IPHONE_65");
  if (old65) { await api.del(`/v1/appScreenshotSets/${old65.id}`); log.push("removed old 6.5in set"); }
  const dir = path.join(root, "docs/aso/screenshots-ipad-13");
  const files = fs.readdirSync(dir).filter((f) => f.endsWith(".png")).sort().map((f) => path.join(dir, f));
  let set = sets.find((s) => s.attributes.screenshotDisplayType === "APP_IPAD_PRO_3GEN_129");
  if (set) { for (const s of (await api.get(`/v1/appScreenshotSets/${set.id}/appScreenshots`)).data) await api.del(`/v1/appScreenshots/${s.id}`); }
  else set = (await api.post(`/v1/appScreenshotSets`, { data: { type: "appScreenshotSets", attributes: { screenshotDisplayType: "APP_IPAD_PRO_3GEN_129" },
    relationships: { appStoreVersionLocalization: { data: { type: "appStoreVersionLocalizations", id: loc.id } } } } })).data;
  for (const f of files) await asset(api, set.id, f);
  log.push(`${files.length} iPad 13in screenshots uploaded`);
  return log;
};
