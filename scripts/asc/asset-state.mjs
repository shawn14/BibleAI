// Read-only: state of every screenshot/preview and every Asset Library placement on 2.0 en-US.
const APP = "6756225286";
export default async (api) => {
  const v2 = (await api.get(`/v1/apps/${APP}/appStoreVersions?filter[versionString]=2.0.2&filter[platform]=IOS`)).data[0];
  const loc = (await api.get(`/v1/appStoreVersions/${v2.id}/appStoreVersionLocalizations`)).data.find((l) => l.attributes.locale === "en-US");
  const out = { version: v2.attributes.appStoreState, placements: [] };
  const pl = await api.get(`/v1/appStoreVersionLocalizations/${loc.id}/placements?include=image,video`).catch((e) => ({ error: e.message }));
  if (pl.error) out.placements = pl.error;
  for (const p of pl.data ?? []) {
    const v = p.relationships?.video?.data, i = p.relationships?.image?.data;
    const inc = (pl.included ?? []).find((x) => x.id === (v ?? i)?.id);
    out.placements.push({ type: p.attributes.placementType, group: p.attributes.placementGroup, item: (v ?? i)?.type, state: inc?.attributes?.state, details: inc?.attributes?.stateDetails });
  }
  out.shots = [];
  for (const set of (await api.get(`/v1/appStoreVersionLocalizations/${loc.id}/appScreenshotSets`)).data)
    for (const s of (await api.get(`/v1/appScreenshotSets/${set.id}/appScreenshots`)).data)
      if (s.attributes.assetDeliveryState?.state !== "COMPLETE") out.shots.push({ set: set.attributes.screenshotDisplayType, file: s.attributes.fileName, delivery: s.attributes.assetDeliveryState, size: s.attributes.fileSize });
  return out;
};
