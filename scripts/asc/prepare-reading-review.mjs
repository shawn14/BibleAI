// Prepare build 13; only its explicitly identified previous waiting review may be replaced.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import inventory, { requireDistributionClearance } from './reading-release-state.mjs';
import replacePrevious from './replace-build11.mjs';
const app = '6756225286';
export default async api => {
  const { READING_VERSION: version, READING_BUILD: build } = process.env;
  assert.match(version ?? '', /^\d+\.\d+\.\d+$/); assert.match(build ?? '', /^\d+$/);
  assert.equal(version,'2.0.4');assert.equal(build,'13');
  let release=await inventory(api);
  requireDistributionClearance(release.GBR,version,build);
  assert.equal(release.GBR.available,false,'UK must be excluded for this release');
  const txt = name => fs.readFileSync('docs/aso/en-US/'+name+'.txt','utf8').trim();
  const builds = await api.get('/v1/builds?filter[app]='+app+'&filter[version]='+build+'&include=preReleaseVersion');
  const versionIDs = new Set((builds.included??[]).filter(v=>v.type==='preReleaseVersions' && v.attributes.version===version && v.attributes.platform==='IOS').map(v=>v.id));
  const found = builds.data.filter(b=>versionIDs.has(b.relationships.preReleaseVersion.data?.id) && b.attributes.version===build && b.attributes.processingState==='VALID' && !b.attributes.expired);
  assert.equal(found.length,1,'Missing exact, non-expired, VALID iOS candidate');
  const candidate=found[0];
  // Same export classification as build 12. Never edit another build or overwrite a positive declaration.
  if(candidate.attributes.usesNonExemptEncryption==null){
    const old=(await api.get('/v1/builds/56f78e5d-487c-470b-a012-20e44f08e143')).data;
    assert.equal(old.attributes.version,'12');assert.equal(old.attributes.usesNonExemptEncryption,false);
    await api.patch('/v1/builds/'+candidate.id,{data:{type:'builds',id:candidate.id,attributes:{usesNonExemptEncryption:false}}});
  }
  const verified=(await api.get('/v1/builds/'+candidate.id)).data;
  assert.equal(verified.attributes.usesNonExemptEncryption,false,'Missing export compliance for this exact build');
  await replacePrevious(api,release,verified);
  release=await inventory(api);
  assert.equal(release.GBR.available,false);assert.equal(release.review.length,0,'Another review is open; stop');
  const versions=await api.all('/v1/apps/'+app+'/appStoreVersions?filter[platform]=IOS');
  const current=versions.filter(v=>['READY_FOR_SALE','READY_FOR_DISTRIBUTION'].includes(v.attributes.appStoreState)).sort((a,b)=>b.attributes.versionString.localeCompare(a.attributes.versionString,'en',{numeric:true}))[0];
  assert(current?.attributes.copyright,'Missing reference copyright');
  let target=versions.find(v=>v.attributes.versionString===version);
  const editable = ['PREPARE_FOR_SUBMISSION','DEVELOPER_REJECTED','METADATA_REJECTED','REJECTED'];
  const open=versions.filter(v=>v.attributes.versionString!==version && (editable.includes(v.attributes.appStoreState) || ['READY_FOR_REVIEW','WAITING_FOR_REVIEW','IN_REVIEW','PENDING_DEVELOPER_RELEASE','PENDING_APPLE_RELEASE'].includes(v.attributes.appStoreState)));
  assert.equal(open.length,0,'Another version is open; leaving it unchanged: '+open.map(v=>v.attributes.versionString+' '+v.attributes.appStoreState).join(', '));
  assert(version.localeCompare(current.attributes.versionString,'en',{numeric:true})>0,'Target must be newer than public version');
  if(!target) target=(await api.post('/v1/appStoreVersions',{data:{type:'appStoreVersions',attributes:{platform:'IOS',versionString:version,releaseType:'MANUAL',copyright:current.attributes.copyright},relationships:{app:{data:{type:'apps',id:app}}}}})).data;
  assert(editable.includes(target.attributes.appStoreState),'Target is not editable');
  assert.equal(target.attributes.releaseType,'MANUAL','Do not change an existing release policy');
  const endpoint='/v1/appStoreVersions/'+target.id;
  let attached;
  try { attached=(await api.get(endpoint+'/build')).data; } catch(e){if(e.status!==404) throw e;}
  if(attached && attached.id!==found[0].id) throw Error('A different build is already attached; leaving it unchanged');
  const loc=(await api.all(endpoint+'/appStoreVersionLocalizations')).find(l=>l.attributes.locale==='en-US');
  const review=(await api.get(endpoint+'/appStoreReviewDetail')).data;
  assert(loc && review,'Missing en-US or review details; do not overwrite contact information');
  for(const [type, resource, fields] of [
    ['appStoreVersionLocalizations',loc,{description:txt('description'),whatsNew:txt('release_notes')}],
    ['appStoreReviewDetails',review,{notes:txt('review_notes')}]
  ]){
    if(Object.entries(fields).some(([k,v])=>resource.attributes[k]!==v))
      await api.patch('/v1/'+type+'/'+resource.id,{data:{type,id:resource.id,attributes:fields}});
    const actual=(await api.get('/v1/'+type+'/'+resource.id)).data.attributes;
    for(const [k,v] of Object.entries(fields)) assert.equal(actual[k],v);
  }
  if(!attached) await api.patch(endpoint+'/relationships/build',{data:{type:'builds',id:found[0].id}});
  const readback=(await api.get(endpoint+'/build')).data;
  assert.equal(readback.id,found[0].id);assert.equal(readback.attributes.processingState,'VALID');
  return {version,build,versionID:target.id,buildID:readback.id,release:'MANUAL',metadataVerified:true};
};
