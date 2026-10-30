// What does BibleAI 2.0 still need before it can be submitted? Fills the copyright line from the live version.
const APP = "6756225286";
export default async (api) => {
  const out = {};
  const versions = (await api.get(`/v1/apps/${APP}/appStoreVersions?filter[platform]=IOS&limit=5`)).data;
  const v2 = versions.find((v) => v.attributes.versionString === "2.0.1");
  const live = versions.find((v) => v.attributes.appStoreState === "READY_FOR_SALE");
  out.v2 = v2.attributes; out.liveCopyright = live?.attributes.copyright;
  if (!v2.attributes.copyright) {
    const c = live?.attributes.copyright && /\d{4}/.test(live.attributes.copyright)
      ? live.attributes.copyright.replace(/\d{4}/, "2026") : "2026 Shawn Carpenter";
    await api.patch(`/v1/appStoreVersions/${v2.id}`, { data: { type: "appStoreVersions", id: v2.id, attributes: { copyright: c } } });
    out.setCopyright = c;
  }
  const loc = (await api.get(`/v1/appStoreVersions/${v2.id}/appStoreVersionLocalizations`)).data.find((l) => l.attributes.locale === "en-US");
  out.media = {};
  for (const set of (await api.get(`/v1/appStoreVersionLocalizations/${loc.id}/appScreenshotSets`)).data) {
    const shots = (await api.get(`/v1/appScreenshotSets/${set.id}/appScreenshots`)).data;
    out.media[set.attributes.screenshotDisplayType] = shots.map((s) => s.attributes.assetDeliveryState?.state);
  }
  for (const set of (await api.get(`/v1/appStoreVersionLocalizations/${loc.id}/appPreviewSets`)).data) {
    const p = (await api.get(`/v1/appPreviewSets/${set.id}/appPreviews`)).data;
    out.media["PREVIEW_" + set.attributes.previewType] = p.map((x) => x.attributes.assetDeliveryState?.state);
  }
  const build = await api.get(`/v1/appStoreVersions/${v2.id}/build`).catch((e) => ({ error: e.message }));
  out.build = build.data?.attributes?.version ?? build;
  const review = await api.get(`/v1/appStoreVersions/${v2.id}/appStoreReviewDetail`).catch((e) => ({ error: e.message }));
  out.reviewDetail = review.data?.attributes ?? review;
  const subs = await api.get(`/v1/reviewSubmissions?filter[app]=${APP}&limit=5`).catch((e) => ({ error: e.message }));
  out.reviewSubmissions = subs.data?.map((s) => s.attributes) ?? subs;
  return out;
};
