// Make sure Shawn can install the newest BibleAI build from TestFlight, and report what Apple shows.
// Fixes only TestFlight access: export compliance answer, internal-group build access, tester membership.
const APP = "6756225286";
const EMAILS = ["shawn@stockalarm.io"];
export default async (api) => {
  const out = {};
  const builds = (await api.get(`/v1/builds?filter[app]=${APP}&sort=-uploadedDate&limit=3&include=preReleaseVersion`));
  const pre = Object.fromEntries((builds.included || []).map((v) => [v.id, v.attributes.version]));
  out.builds = builds.data.map((b) => ({ id: b.id, version: pre[b.relationships.preReleaseVersion.data?.id], build: b.attributes.version,
    state: b.attributes.processingState, uploaded: b.attributes.uploadedDate, encryption: b.attributes.usesNonExemptEncryption, expired: b.attributes.expired }));
  const latest = builds.data[0];
  if (!latest) throw new Error("no builds");
  if (latest.attributes.processingState === "VALID" && latest.attributes.usesNonExemptEncryption == null) {
    await api.patch(`/v1/builds/${latest.id}`, { data: { type: "builds", id: latest.id, attributes: { usesNonExemptEncryption: false } } });
    out.fixedCompliance = true;
  }
  const groups = (await api.get(`/v1/apps/${APP}/betaGroups`)).data;
  out.groups = groups.map((g) => ({ id: g.id, name: g.attributes.name, internal: g.attributes.isInternalGroup, allBuilds: g.attributes.hasAccessToAllBuilds }));
  const group = groups.find((g) => g.attributes.isInternalGroup);
  if (!group) throw new Error("no internal group");
  if (!group.attributes.hasAccessToAllBuilds) {
    const gb = (await api.get(`/v1/betaGroups/${group.id}/builds?limit=50`)).data.map((b) => b.id);
    if (!gb.includes(latest.id)) {
      await api.post(`/v1/betaGroups/${group.id}/relationships/builds`, { data: [{ type: "builds", id: latest.id }] });
      out.addedBuildToGroup = true;
    }
  }
  const testers = (await api.get(`/v1/betaGroups/${group.id}/betaTesters?limit=200`)).data;
  out.testers = testers.map((t) => ({ email: t.attributes.email, state: t.attributes.state, invite: t.attributes.inviteType }));
  for (const email of EMAILS) {
    if (!testers.some((t) => (t.attributes.email || "").toLowerCase() === email)) {
      out.missing = (out.missing || []).concat(email);
    }
  }
  const status = await api.get(`/v1/builds/${latest.id}/buildBetaDetail`).catch((e) => ({ error: e.message }));
  out.betaDetail = status.data?.attributes ?? status;
  return out;
};
