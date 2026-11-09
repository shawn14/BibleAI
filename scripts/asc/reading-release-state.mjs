import fs from 'node:fs';
import assert from 'node:assert/strict';
// Read-only inventory for release decisions. Storefront availability is app-wide.
export default async api => {
  const app = '6756225286';
  const [territories, versions, builds, submissions] = await Promise.all([
    api.all('/v2/appAvailabilities/'+app+'/territoryAvailabilities?limit=200&include=territory'),
    api.all('/v1/apps/'+app+'/appStoreVersions?filter[platform]=IOS'),
    api.get('/v1/builds?filter[app]='+app+'&sort=-uploadedDate&limit=8&include=preReleaseVersion'),
    api.all('/v1/reviewSubmissions?filter[app]='+app+'&filter[platform]=IOS')
  ]);
  const territory = code => {
    const row=territories.find(t=>t.relationships.territory.data.id===code);
    if (typeof row?.attributes.available !== 'boolean') throw Error('Unknown availability for '+code);
    return {available:row.attributes.available, releaseDate:row.attributes.releaseDate??null};
  };
  const prerelease=Object.fromEntries((builds.included??[]).map(v=>[v.id,v.attributes.version]));
  const records=[];
  for(const v of versions.slice(0,6)){
    let build=null;
    try {build=(await api.get('/v1/appStoreVersions/'+v.id+'/build')).data;} catch(e){if(e.status!==404) throw e;}
    records.push({version:v.attributes.versionString,id:v.id,state:v.attributes.appStoreState,release:v.attributes.releaseType,build:build?.attributes.version??null});
  }
  const review=[];
  for(const item of submissions.filter(s=>!['COMPLETE','CANCELED','CANCELLED'].includes(s.attributes.state))){
    const parts=await api.all('/v1/reviewSubmissions/'+item.id+'/items?include=appStoreVersion');
    review.push({id:item.id,state:item.attributes.state,items:parts.map(p=>({versionId:p.relationships?.appStoreVersion?.data?.id,state:p.attributes.state}))});
  }
  return {observedAt:new Date().toISOString(), GBR:territory('GBR'),USA:territory('USA'),territoryCount:territories.filter(t=>t.attributes.available).length,
    versions:records,builds:builds.data.map(b=>({version:prerelease[b.relationships.preReleaseVersion.data?.id],build:b.attributes.version,processing:b.attributes.processingState})),review};
};

// Store scope applies to the entire app. This release must not infer a UK licence.
export function requireDistributionClearance(gbr,version,build){
  assert.equal(typeof gbr?.available,'boolean','Could not verify the UK storefront');
  if(!gbr.available && !(gbr.releaseDate && Date.parse(gbr.releaseDate)>Date.now())) return;
  const file='docs/testing/uk-kjv-clearance-'+version+'-'+build+'.json';
  assert(fs.existsSync(file),'UK is enabled: missing build-specific rights confirmation');
  const approval=JSON.parse(fs.readFileSync(file,'utf8'));
  assert.equal(approval.version,version);assert.equal(approval.build,build);
  assert.equal(approval.ukDigitalDistribution,true);assert(approval.evidence?.trim(),'Missing rights basis for this build');
}
