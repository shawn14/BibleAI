// Write the en-US version copy from docs/aso/en-US onto the editable version (default 2.0.2).
import fs from "node:fs";
import path from "node:path";
const APP = "6756225286";
const VERSION = process.env.ASC_VERSION || "2.0.2";
const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), "../..");
const txt = (f) => fs.readFileSync(path.join(root, "docs/aso/en-US", f), "utf8").trim();
export default async (api) => {
  const v = (await api.get(`/v1/apps/${APP}/appStoreVersions?filter[platform]=IOS&filter[versionString]=${VERSION}`)).data[0];
  const loc = (await api.get(`/v1/appStoreVersions/${v.id}/appStoreVersionLocalizations`)).data.find((l) => l.attributes.locale === "en-US");
  await api.patch(`/v1/appStoreVersionLocalizations/${loc.id}`, { data: { type: "appStoreVersionLocalizations", id: loc.id, attributes: {
    description: txt("description.txt"), keywords: txt("keywords.txt"), promotionalText: txt("promotional_text.txt"),
    whatsNew: txt("release_notes.txt"), marketingUrl: txt("marketing_url.txt"), supportUrl: txt("support_url.txt") } } });
  const review = await api.get(`/v1/appStoreVersions/${v.id}/appStoreReviewDetail`).catch(() => null);
  if (review?.data) await api.patch(`/v1/appStoreReviewDetails/${review.data.id}`, { data: { type: "appStoreReviewDetails", id: review.data.id, attributes: { notes: txt("review_notes.txt") } } });
  const a = (await api.get(`/v1/appStoreVersionLocalizations/${loc.id}`)).data.attributes;
  return { version: v.attributes.versionString, state: v.attributes.appStoreState, whatsNew: a.whatsNew?.slice(0, 80), keywords: a.keywords, reviewNotes: !!review?.data };
};
