export default async function reviewState(api) {
  const app = '6756225286';
  const versions = await api.all('/v1/apps/' + app + '/appStoreVersions?filter[platform]=IOS');
  const read = async (number) => {
    const version = versions.find(v => v.attributes.versionString === number);
    if (!version) throw Error('ASC version missing: ' + number);
    const locales = await api.all('/v1/appStoreVersions/' + version.id + '/appStoreVersionLocalizations');
    const loc = locales.find(l => l.attributes.locale === 'en-US');
    const previewSets = await api.all('/v1/appStoreVersionLocalizations/' + loc.id + '/appPreviewSets');
    const previews = [];
    for (const set of previewSets) {
      const files = await api.all('/v1/appPreviewSets/' + set.id + '/appPreviews');
      for (const file of files) previews.push([set.attributes.previewType, file.attributes.sourceFileChecksum, file.attributes.assetDeliveryState?.state]);
    }
    const placements = await api.all('/v1/appStoreVersionLocalizations/' + loc.id + '/placements?include=video');
    const videos = placements.map(p => [p.attributes.placementType,p.relationships?.video?.data?.id]);
    let build;
    try { build = (await api.get('/v1/appStoreVersions/' + version.id + '/build')).data; }
    catch (e) { if (e.status !== 404) throw e; }
    return { id: version.id, version: number, state: version.attributes.appStoreState, release: version.attributes.releaseType,
      build: build?.attributes.version, processing: build?.attributes.processingState, previews, videos };
  };
  const live = await read('2.0.2');
  const candidate = await read('2.0.3');
  const submissions = await api.all('/v1/reviewSubmissions?filter[app]=' + app + '&filter[platform]=IOS');
  const review = [];
  for (const submission of submissions.filter(s => ['WAITING_FOR_REVIEW','IN_REVIEW','READY_FOR_REVIEW','UNRESOLVED_ISSUES'].includes(s.attributes.state))) {
    const items = await api.all('/v1/reviewSubmissions/' + submission.id + '/items?include=appStoreVersion');
    if (items.some(i => i.relationships?.appStoreVersion?.data?.id === candidate.id)) review.push({id:submission.id,state:submission.attributes.state});
  }
  return { observedAt: new Date().toISOString(), live, candidate, review };
}
