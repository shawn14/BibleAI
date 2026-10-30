// Re-upload any 2.0 en-US screenshot stuck before COMPLETE (Apple sometimes leaves one at UPLOAD_COMPLETE),
// then restore filename order in its set.
import fs from "node:fs";
import path from "node:path";
const APP = "6756225286";
const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), "../..");
const DIRS = { APP_IPHONE_67: "screenshots-6.9", APP_IPAD_PRO_3GEN_129: "screenshots-ipad-13" };
export default async (api) => {
  const v = (await api.get(`/v1/apps/${APP}/appStoreVersions?filter[platform]=IOS&filter[versionString]=2.0`)).data[0];
  const loc = (await api.get(`/v1/appStoreVersions/${v.id}/appStoreVersionLocalizations`)).data.find((l) => l.attributes.locale === "en-US").id;
  const log = [];
  for (const set of (await api.get(`/v1/appStoreVersionLocalizations/${loc}/appScreenshotSets`)).data) {
    const dir = DIRS[set.attributes.screenshotDisplayType]; if (!dir) continue;
    const shots = (await api.get(`/v1/appScreenshotSets/${set.id}/appScreenshots`)).data;
    for (const s of shots) {
      const st = s.attributes.assetDeliveryState?.state;
      if (st === "COMPLETE") continue;
      const file = path.join(root, "docs/aso", dir, s.attributes.fileName);
      await api.del(`/v1/appScreenshots/${s.id}`);
      const res = (await api.post(`/v1/appScreenshots`, { data: { type: "appScreenshots", attributes: { fileName: path.basename(file), fileSize: fs.statSync(file).size },
        relationships: { appScreenshotSet: { data: { type: "appScreenshotSets", id: set.id } } } } })).data;
      for (const op of res.attributes.uploadOperations) await api.upload(op, file);
      await api.patch(`/v1/appScreenshots/${res.id}`, { data: { type: "appScreenshots", id: res.id, attributes: { uploaded: true, sourceFileChecksum: api.md5(file) } } });
      let state;
      for (let i = 0; i < 24; i++) { state = (await api.get(`/v1/appScreenshots/${res.id}`)).data.attributes.assetDeliveryState?.state; if (state === "COMPLETE" || state === "FAILED") break; await new Promise((r) => setTimeout(r, 5000)); }
      log.push(`${set.attributes.screenshotDisplayType} ${s.attributes.fileName}: was ${st}, re-uploaded -> ${state}`);
    }
    const now = (await api.get(`/v1/appScreenshotSets/${set.id}/appScreenshots`)).data;
    const ordered = [...now].sort((a, b) => a.attributes.fileName.localeCompare(b.attributes.fileName));
    if (ordered.some((s, i) => s.id !== now[i].id)) {
      await api.patch(`/v1/appScreenshotSets/${set.id}/relationships/appScreenshots`, { data: ordered.map((s) => ({ type: "appScreenshots", id: s.id })) });
      log.push(`${set.attributes.screenshotDisplayType} reordered`);
    }
    log.push(`${set.attributes.screenshotDisplayType}: ${ordered.map((s) => s.attributes.fileName.replace(/^BibleAI-/, "")).join(", ")}`);
  }
  return log;
};
