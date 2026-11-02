// Asset upload helper. Call only through the guarded apply_aso action.
// Existing Apple API path; 18 screenshots, one preview, two creative placements.
import fs from "node:fs";
import assert from "node:assert/strict";
import path from "node:path";
const APP = "6756225286";
const VERSION = "2.0.1";
const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), "../..");
const aso = (p) => path.join(root, "docs/aso", p);
const record = data => fs.appendFileSync(path.join(root, "build/aso-refresh/apply-progress.jsonl"), JSON.stringify({at:new Date().toISOString(),...data}) + "\n");
const pngs = (dir) => fs.readdirSync(aso(dir)).filter((f) => f.endsWith(".png")).sort().map((f) => aso(path.join(dir, f)));
async function asset(api, kind, rel, relType, relId, file, extra = {}) {
  const res = (await api.post(`/v1/${kind}`, { data: { type: kind, attributes: { fileName: path.basename(file), fileSize: fs.statSync(file).size, ...extra },
    relationships: { [rel]: { data: { type: relType, id: relId } } } } })).data;
  record({kind: typeof kind === "string" ? kind : "video", id:res.id, file, state:"reserved"});
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
async function libraryVideo(api, loc, placementType, kind, file, options = {}) {
  const recordVideo = options.record || record;
  const sha = api.md5(file).slice(0, 12);
  let res;
  if (options.existingHeaderId && kind === "header") {
    res = (await api.get(`/v1/appAssetLibraryVideos/${options.existingHeaderId}`)).data;
    assert.equal(res.attributes.category, "CREATIVE_ASSETS");
    assert.equal(res.attributes.fileName, path.basename(file));
    assert.equal(res.attributes.fileSize, fs.statSync(file).size);
    assert(res.attributes.referenceName.includes(`BibleAI-${VERSION}-${kind}-${sha}-`));
  } else {
  res = (await api.post(`/v1/appAssetLibraryVideos`, { data: { type: "appAssetLibraryVideos",
    attributes: { category: "CREATIVE_ASSETS", fileName: path.basename(file), fileSize: fs.statSync(file).size, referenceName: `BibleAI-${VERSION}-${kind}-${sha}-${Date.now()}` },
    relationships: { assetLibrary: { data: { type: "appAssetLibraries", id: APP } } } } })).data;
  recordVideo({kind: typeof kind === "string" ? kind : "video", id:res.id, file, state:"reserved"});
  for (const op of res.attributes.uploadOperations) await api.upload(op, file);
  await api.patch(`/v1/appAssetLibraryVideos/${res.id}`, { data: { type: "appAssetLibraryVideos", id: res.id, attributes: { uploaded: true } } });
  }
  let state, previousState;
  for (let i = 0; i < 60; i++) {
    state = (await api.get(`/v1/appAssetLibraryVideos/${res.id}`)).data.attributes;
    if (state.state !== previousState) recordVideo({kind:"video-state", assetKind:kind, id:res.id, state:state.state});
    previousState = state.state;
    if (!["AWAITING_UPLOAD", "UPLOAD_COMPLETE", "PROCESSING", "COMPLETE"].includes(state.state)) break;
    await new Promise((r) => setTimeout(r, 10000));
  }
  if (!["PREPARE_FOR_SUBMISSION", "APPROVED"].includes(state.state))
    throw new Error(`${kind} video ${state.state}: ${JSON.stringify(state.stateDetails)}`);
  const existing = (await api.get(`/v1/appStoreVersionLocalizations/${loc}/placements?filter[placementType]=${placementType}&filter[placementGroup]=DEFAULT_PROFILE&include=video`)).data;
  if (options.expectedPlacements) {
    const expected = options.expectedPlacements.filter(p => p.attributes.placementType === placementType);
    assert.deepEqual(existing.map(p => [p.id, p.relationships?.video?.data?.id]), expected.map(p => [p.id, p.relationships?.video?.data?.id]), "Creative placements changed during upload");
  }
  for (const p of existing) await api.del(`/v1/appAssetLibraryPlacements/${p.id}`);
  const placed = (await api.post(`/v1/appAssetLibraryPlacements`, { data: { type: "appAssetLibraryPlacements",
    attributes: { placementType, placementGroup: "DEFAULT_PROFILE" },
    relationships: { video: { data: { type: "appAssetLibraryVideos", id: res.id } },
      appStoreVersionLocalization: { data: { type: "appStoreVersionLocalizations", id: loc } } } } })).data;
  return `${kind} video ${state.state}, placed ${placed.id}`;
}
export default async (api, options = {}) => {
  if (!options.guarded) throw new Error("Use apply_aso: direct unguarded store uploads are disabled");
  const log = [];
  const v = (await api.get(`/v1/apps/${APP}/appStoreVersions?filter[platform]=IOS&filter[versionString]=${VERSION}`)).data[0];
  if (!v) throw new Error(`no ${VERSION}`);
  const loc = (await api.get(`/v1/appStoreVersions/${v.id}/appStoreVersionLocalizations`)).data.find((l) => l.attributes.locale === "en-US").id;
  if (!options.videosOnly) {
  log.push(await screenshotSet(api, loc, "APP_IPHONE_67", pngs("screenshots-6.9")));
  log.push(await screenshotSet(api, loc, "APP_IPHONE_61", pngs("screenshots-6.3")));
  log.push(await screenshotSet(api, loc, "APP_IPAD_PRO_3GEN_129", pngs("screenshots-ipad-13")));
  const psets = (await api.get(`/v1/appStoreVersionLocalizations/${loc}/appPreviewSets`)).data;
  let pset = psets.find((s) => s.attributes.previewType === "IPHONE_67");
  if (pset) { for (const p of (await api.get(`/v1/appPreviewSets/${pset.id}/appPreviews`)).data) await api.del(`/v1/appPreviews/${p.id}`); }
  else pset = (await api.post("/v1/appPreviewSets", { data: { type: "appPreviewSets", attributes: { previewType: "IPHONE_67" },
    relationships: { appStoreVersionLocalization: { data: { type: "appStoreVersionLocalizations", id: loc } } } } })).data;
  await asset(api, "appPreviews", "appPreviewSet", "appPreviewSets", pset.id, aso("preview/BibleAI-preview-6.9.mp4"), { mimeType: "video/mp4", previewFrameTimeCode: "00:00:05:00" });
  log.push("app preview uploaded");
  }
  log.push(await libraryVideo(api, loc, "PRODUCT_PAGE_HEADER_ASSET", "header", aso("header-video/product-page-header.mp4"), options));
  log.push(await libraryVideo(api, loc, "APP_STORE_SEARCH_RESULTS_ASSET", "search", aso("header-video/search-results.mp4"), options));
  return log;
};
