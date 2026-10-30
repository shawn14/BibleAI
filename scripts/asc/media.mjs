// Replace the BibleAI 2.0 listing's 6.9" screenshots and app preview (docs/aso/). Safe to re-run.
import fs from "node:fs";
import path from "node:path";
const APP = "6756225286";
const VERSION = "2.0.1";
const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), "../..");
async function asset(api, kind, parentRel, parentType, parentId, file, extra = {}) {
  const res = (await api.post(`/v1/${kind}`, { data: { type: kind, attributes: { fileName: path.basename(file), fileSize: fs.statSync(file).size, ...extra },
    relationships: { [parentRel]: { data: { type: parentType, id: parentId } } } } })).data;
  for (const op of res.attributes.uploadOperations) await api.upload(op, file);
  await api.patch(`/v1/${kind}/${res.id}`, { data: { type: kind, id: res.id, attributes: { uploaded: true, sourceFileChecksum: api.md5(file) } } });
}
export default async (api) => {
  const log = [];
  const vers = (await api.get(`/v1/apps/${APP}/appStoreVersions?filter[platform]=IOS&filter[versionString]=${VERSION}`)).data;
  const ver = vers[0];
  if (!ver) throw new Error(`Version ${VERSION} not found; run the listing push first`);
  const vloc = (await api.get(`/v1/appStoreVersions/${ver.id}/appStoreVersionLocalizations`)).data.find((l) => l.attributes.locale === "en-US");
  // Screenshots
  const shotDir = path.join(root, "docs/aso/screenshots-6.9");
  const files = fs.readdirSync(shotDir).filter((f) => f.endsWith(".png")).sort().map((f) => path.join(shotDir, f));
  let sets = (await api.get(`/v1/appStoreVersionLocalizations/${vloc.id}/appScreenshotSets`)).data;
  let set = sets.find((s) => s.attributes.screenshotDisplayType === "APP_IPHONE_67");
  if (set) { for (const s of (await api.get(`/v1/appScreenshotSets/${set.id}/appScreenshots`)).data) await api.del(`/v1/appScreenshots/${s.id}`); }
  else set = (await api.post(`/v1/appScreenshotSets`, { data: { type: "appScreenshotSets", attributes: { screenshotDisplayType: "APP_IPHONE_67" },
    relationships: { appStoreVersionLocalization: { data: { type: "appStoreVersionLocalizations", id: vloc.id } } } } })).data;
  for (const f of files) await asset(api, "appScreenshots", "appScreenshotSet", "appScreenshotSets", set.id, f);
  log.push(`${files.length} screenshots uploaded to ${VERSION}`);
  // App preview
  const video = path.join(root, "docs/aso/preview/BibleAI-preview-6.9.mp4");
  const psets = (await api.get(`/v1/appStoreVersionLocalizations/${vloc.id}/appPreviewSets`)).data;
  let pset = psets.find((s) => s.attributes.previewType === "IPHONE_67");
  if (pset) { for (const p of (await api.get(`/v1/appPreviewSets/${pset.id}/appPreviews`)).data) await api.del(`/v1/appPreviews/${p.id}`); }
  else pset = (await api.post("/v1/appPreviewSets", { data: { type: "appPreviewSets", attributes: { previewType: "IPHONE_67" },
    relationships: { appStoreVersionLocalization: { data: { type: "appStoreVersionLocalizations", id: vloc.id } } } } })).data;
  await asset(api, "appPreviews", "appPreviewSet", "appPreviewSets", pset.id, video, { mimeType: "video/mp4", previewFrameTimeCode: "00:00:05:00" });
  log.push("app preview uploaded");
  return log;
};
