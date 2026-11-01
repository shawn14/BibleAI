// Add a 7-day free trial (introductory offer) to the BibleAI yearly subscription in every territory
// where it is sold. Idempotent: territories that already have an intro offer are left alone.
const APP = "6756225286";
const PRODUCT = "com.shawncarpenter.bibleai_companion.premium.yearly";
export default async (api) => {
  const groups = (await api.get(`/v1/apps/${APP}/subscriptionGroups?include=subscriptions&limit=50`));
  const subs = (groups.included || []).filter((x) => x.type === "subscriptions");
  const yearly = subs.find((x) => x.attributes.productId === PRODUCT);
  if (!yearly) throw new Error(`yearly subscription ${PRODUCT} not found; have ${subs.map((x) => x.attributes.productId)}`);
  const territories = await api.all(`/v1/subscriptionAvailabilities/${yearly.id}/availableTerritories?limit=200`)
    .catch(async () => {
      const av = (await api.get(`/v1/subscriptions/${yearly.id}/subscriptionAvailability`)).data;
      return api.all(`/v1/subscriptionAvailabilities/${av.id}/availableTerritories?limit=200`);
    });
  const existing = await api.all(`/v1/subscriptions/${yearly.id}/introductoryOffers?include=territory&limit=200`);
  const covered = new Set(existing.map((o) => o.relationships?.territory?.data?.id).filter(Boolean));
  let created = 0, failed = [];
  for (const t of territories) {
    if (covered.has(t.id)) continue;
    try {
      await api.post("/v1/subscriptionIntroductoryOffers", { data: { type: "subscriptionIntroductoryOffers",
        attributes: { duration: "ONE_WEEK", numberOfPeriods: 1, offerMode: "FREE_TRIAL" },
        relationships: { subscription: { data: { type: "subscriptions", id: yearly.id } },
                         territory: { data: { type: "territories", id: t.id } } } } });
      created++;
    } catch (e) { failed.push(`${t.id}: ${String(e.message).slice(0, 160)}`); }
  }
  return { subscription: yearly.id, state: yearly.attributes.state, territories: territories.length,
           alreadyHadTrial: covered.size, created, failed: failed.slice(0, 10), failedCount: failed.length };
};
