// Apple's Sept 2026 age-rating question "socialMedia" is required before review. BibleAI has no social feed,
// no user-to-user messaging and no user-generated content, so the honest answer is NO (false).
const APP = "6756225286";
export default async (api) => {
  const infos = (await api.get(`/v1/apps/${APP}/appInfos?include=ageRatingDeclaration`)).data;
  const out = [];
  for (const info of infos) {
    const rel = info.relationships?.ageRatingDeclaration?.data;
    if (!rel) continue;
    const decl = (await api.get(`/v1/ageRatingDeclarations/${rel.id}`).catch(() => null))
      ?? (await api.get(`/v1/appInfos/${info.id}/ageRatingDeclaration`));
    const a = decl.data.attributes;
    const row = { appInfo: info.id, state: info.attributes.appStoreState ?? info.attributes.state, socialMedia: a.socialMedia, socialMediaAgeRestricted: a.socialMediaAgeRestricted };
    if (a.socialMedia === null || a.socialMedia === undefined) {
      try {
        await api.patch(`/v1/ageRatingDeclarations/${rel.id}`, { data: { type: "ageRatingDeclarations", id: rel.id, attributes: { socialMedia: false } } });
        row.set = "socialMedia=false";
      } catch (e) { row.error = e.message.slice(0, 400); }
    }
    out.push(row);
  }
  const subs = await api.get(`/v1/reviewSubmissions?filter[app]=${APP}&limit=5`).catch((e) => ({ error: e.message }));
  return { declarations: out, reviewSubmissions: subs.data?.map((s) => ({ id: s.id, ...s.attributes })) ?? subs };
};
