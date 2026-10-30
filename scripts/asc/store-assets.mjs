// Push the full BibleAI 2.0 App Store creative set from docs/aso/ onto the editable 2.0 version (en-US):
//   iPhone 6.9" screenshots, iPad 13" screenshots, iPhone 6.9" app preview,
//   iOS 27 product-page header + search-results videos (Asset Library, placed DEFAULT_PROFILE),
//   copyright year; removes the stale 6.5" iPhone set so 6.9" scales down. Safe to re-run.
import fs from "node:fs";
import path from "node:path";
const APP = "6756225286";
const VERSION = "2.0.1";
const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), "../..");
const aso = (p) => path.join(root, "docs/aso", p);
const pngs = (dir) => fs.readdirSync(aso(dir)).filter((f) => f.endsWith(".png")).sort().map((f) => aso(path.join(dir, f)));
async function asset(api, kind, rel, relType, relId, file, extra = {}) {
  const res = (await api.post(`/v1/${kind}`, { data: { type: kind, attributes: { fileName: path.basename(file), fileSize: fs.statSync(file).size, ...extra },
    relationships: { [rel]: { data: { type: relType, id: relId } } } } })).data;
  for (const op of res.attributes.uploadOperations) await api.upload(op, file);
  await api.patch(`/v1/${kind}/${res.id}`, { data: { type: kind, id: res.id, attributes: { uploaded: true, sourceFileChecksum: api.md5(file) } } });
  return res.id;
}
async function screenshotSet(api, loc, type, files) {
  const sets = (await api.get(`/v1/appStoreVersionLocalizations/${loc}/appScreenshotSets`)).data;
  let set = sets.find((s) => s.attributes.screenshotDisplayType === type);
  if (set) { for (const s of (await api.get(`/v1/appScreenshotSets/${set.id}/appScreenshots`)).data) await api.del(`/v1/appScreenshots/${s.id}`); }
  else set = (await api.post(`/v1/appScreenshotSets`, { data: { type: "appScreenshotSets", attributes: { screenshotDisplayType: type },
    relationships: { appStoreVersionLocalization: { data: { type: "appStoreVersionLocalizations", id: loc } } } } })).data;
  for (const f of files) await asset(api, "appScreenshots", "appScreenshotSet", "appScreenshotSets", set.id, f);
  return `${files.length} ${type}`;
}
async function libraryVideo(api, loc, placementType, kind, file) {
  const sha = api.md5(file).slice(0, 12);
  const res = (await api.post(`/v1/appAssetLibraryVideos`, { data: { type: "appAssetLibraryVideos",
    attributes: { category: "CREATIVE_ASSETS", fileName: path.basename(file), fileSize: fs.statSync(file).size, referenceName: `BibleAI-${VERSION}-${kind}-${sha}-${Date.now()}` },
    relationships: { assetLibrary: { data: { type: "appAssetLibraries", id: APP } } } } })).data;
  for (const op of res.attributes.uploadOperations) await api.upload(op, file);
  await api.patch(`/v1/appAssetLibraryVideos/${res.id}`, { data: { type: "appAssetLibraryVideos", id: res.id, attributes: { uploaded: true } } });
  let state;
  for (let i = 0; i < 60; i++) {
    state = (await api.get(`/v1/appAssetLibraryVideos/${res.id}`)).data.attributes;
    if (!["AWAITING_UPLOAD", "UPLOAD_COMPLETE", "PROCESSING"].includes(state.state)) break;
    await new Promise((r) => setTimeout(r, 10000));
  }
  if (state.state === "FAILED" || ["AWAITING_UPLOAD", "UPLOAD_COMPLETE", "PROCESSING"].includes(state.state))
    throw new Error(`${kind} video ${state.state}: ${JSON.stringify(state.stateDetails)}`);
  const existing = (await api.get(`/v1/appStoreVersionLocalizations/${loc}/placements?filter[placementType]=${placementType}&filter[placementGroup]=DEFAULT_PROFILE`)).data;
  for (const p of existing) await api.del(`/v1/appAssetLibraryPlacements/${p.id}`);
  const placed = (await api.post(`/v1/appAssetLibraryPlacements`, { data: { type: "appAssetLibraryPlacements",
    attributes: { placementType, placementGroup: "DEFAULT_PROFILE" },
    relationships: { video: { data: { type: "appAssetLibraryVideos", id: res.id } },
      appStoreVersionLocalization: { data: { type: "appStoreVersionLocalizations", id: loc } } } } })).data;
  return `${kind} video ${state.state}, placed ${placed.id}`;
}
export default async (api) => {
  const log = [];
  const v = (await api.get(`/v1/apps/${APP}/appStoreVersions?filter[platform]=IOS&filter[versionString]=${VERSION}`)).data[0];
  if (!v) throw new Error(`no ${VERSION}`);
  if (!/\d{4}/.test(v.attributes.copyright || "")) {
    await api.patch(`/v1/appStoreVersions/${v.id}`, { data: { type: "appStoreVersions", id: v.id, attributes: { copyright: "2026 Center Mark Capital, LLC" } } });
    log.push("copyright set");
  }
  const loc = (await api.get(`/v1/appStoreVersions/${v.id}/appStoreVersionLocalizations`)).data.find((l) => l.attributes.locale === "en-US").id;
  const old65 = (await api.get(`/v1/appStoreVersionLocalizations/${loc}/appScreenshotSets`)).data.find((s) => s.attributes.screenshotDisplayType === "APP_IPHONE_65");
  if (old65) { await api.del(`/v1/appScreenshotSets/${old65.id}`); log.push("removed stale 6.5in set"); }
  log.push(await screenshotSet(api, loc, "APP_IPHONE_67", pngs("screenshots-6.9")));
  log.push(await screenshotSet(api, loc, "APP_IPAD_PRO_3GEN_129", pngs("screenshots-ipad-13")));
  const psets = (await api.get(`/v1/appStoreVersionLocalizations/${loc}/appPreviewSets`)).data;
  let pset = psets.find((s) => s.attributes.previewType === "IPHONE_67");
  if (pset) { for (const p of (await api.get(`/v1/appPreviewSets/${pset.id}/appPreviews`)).data) await api.del(`/v1/appPreviews/${p.id}`); }
  else pset = (await api.post("/v1/appPreviewSets", { data: { type: "appPreviewSets", attributes: { previewType: "IPHONE_67" },
    relationships: { appStoreVersionLocalization: { data: { type: "appStoreVersionLocalizations", id: loc } } } } })).data;
  await asset(api, "appPreviews", "appPreviewSet", "appPreviewSets", pset.id, aso("preview/BibleAI-preview-6.9.mp4"), { mimeType: "video/mp4", previewFrameTimeCode: "00:00:05:00" });
  log.push("app preview uploaded");
  log.push(await libraryVideo(api, loc, "PRODUCT_PAGE_HEADER_ASSET", "header", aso("header-video/product-page-header.mp4")));
  log.push(await libraryVideo(api, loc, "APP_STORE_SEARCH_RESULTS_ASSET", "search", aso("header-video/search-results.mp4")));
  return log;
};
