// No mutation until the exact prepared version, build, rights, review slot and product page agree.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import inventory, { requireDistributionClearance } from './reading-release-state.mjs';
export default async api=>{
  const app='6756225286',version=process.env.READING_VERSION,build=process.env.READING_BUILD;
  assert.match(version??'',/^\d+\.\d+\.\d+$/);assert.match(build??'',/^\d+$/);
  const live=await inventory(api);
  const target=live.versions.find(v=>v.version===version);
  assert(target && target.build===build && target.release==='MANUAL','Wrong draft, build or public-release mode');
  const linked=(await api.get('/v1/appStoreVersions/'+target.id+'/build')).data;
  assert.equal(linked.attributes.version,build);assert.equal(linked.attributes.processingState,'VALID');
  const pre=(await api.get('/v1/builds/'+linked.id+'/preReleaseVersion')).data;
  assert.equal(pre.attributes.version,version); assert.equal(pre.attributes.platform,'IOS');
  const done=live.review.find(s=>['WAITING_FOR_REVIEW','IN_REVIEW'].includes(s.state) && s.items.some(i=>i.versionId===target.id));
  if(done)return {alreadySubmitted:true,version,build,id:done.id,state:done.state};
  assert(live.review.length<=1,'Review slot is occupied; no review will be canceled');
  const draft=live.review[0];
  if(draft)assert(draft.state==='READY_FOR_REVIEW' && draft.items.length===1 && draft.items[0].versionId===target.id,'A different review is open');
  requireDistributionClearance(live.GBR,version,build);
  const loc=(await api.all('/v1/appStoreVersions/'+target.id+'/appStoreVersionLocalizations')).find(l=>l.attributes.locale==='en-US');
  assert(loc);const txt=n=>fs.readFileSync('docs/aso/en-US/'+n+'.txt','utf8').trim();
  assert.equal(loc.attributes.description,txt('description'));assert.equal(loc.attributes.whatsNew,txt('release_notes'));
  assert.equal(loc.attributes.keywords,txt('keywords'));
  const reviewDetail=(await api.get('/v1/appStoreVersions/'+target.id+'/appStoreReviewDetail')).data;
  assert.equal(reviewDetail.attributes.notes,txt('review_notes'));
  const sets=await api.all('/v1/appStoreVersionLocalizations/'+loc.id+'/appScreenshotSets');
  for(const [family,dir] of [['APP_IPHONE_67','screenshots-6.9'],['APP_IPHONE_61','screenshots-6.3'],['APP_IPAD_PRO_3GEN_129','screenshots-ipad-13']]){
    const set=sets.find(s=>s.attributes.screenshotDisplayType===family);assert(set);
    const shots=await api.all('/v1/appScreenshotSets/'+set.id+'/appScreenshots');
    const folder='docs/aso/'+dir;const files=fs.readdirSync(folder).filter(f=>f.endsWith('.png')).sort();
    assert.equal(files.length,6);
    assert.deepEqual(shots.map(s=>[s.attributes.sourceFileChecksum,s.attributes.assetDeliveryState.state]),files.map(f=>[api.md5(folder+'/'+f),'COMPLETE']));
  }
  const ref=(type,id)=>({data:{type,id}});
  const sub=draft??(await api.post('/v1/reviewSubmissions',{data:{type:'reviewSubmissions',attributes:{platform:'IOS'},relationships:{app:ref('apps',app)}}})).data;
  if(!draft)await api.post('/v1/reviewSubmissionItems',{data:{type:'reviewSubmissionItems',relationships:{reviewSubmission:ref('reviewSubmissions',sub.id),appStoreVersion:ref('appStoreVersions',target.id)}}});
  const items=await api.all('/v1/reviewSubmissions/'+sub.id+'/items?include=appStoreVersion');
  assert.equal(items.length,1);assert.equal(items[0].relationships.appStoreVersion.data.id,target.id);
  await api.patch('/v1/reviewSubmissions/'+sub.id,{data:{type:'reviewSubmissions',id:sub.id,attributes:{submitted:true}}});
  const after=(await api.get('/v1/reviewSubmissions/'+sub.id)).data;
  return {id:sub.id,state:after.attributes.state,version,build,versionId:target.id,buildId:linked.id,release:'MANUAL'};
};
