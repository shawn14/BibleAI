// November 1 approved ASO replacement: cancel only the existing 2.0.1/build 8 review.
// Retains the established reviewSubmissions cancellation path; never renames or selects a build.
import fs from 'node:fs';
import assert from 'node:assert/strict';
const APP='6756225286';
const EDITABLE=new Set(['PREPARE_FOR_SUBMISSION','DEVELOPER_REJECTED','REJECTED','METADATA_REJECTED']);
export default async api=>{
 const app=(await api.get(`/v1/apps/${APP}`)).data;
 assert.equal(app.attributes.bundleId,'com.shawncarpenter.bibleai-companion');
 const versions=(await api.all(`/v1/apps/${APP}/appStoreVersions?filter[platform]=IOS`)).filter(v=>v.attributes.versionString==='2.0.1');
 assert.equal(versions.length,1);const version=versions[0];
 assert.equal(version.attributes.appStoreState,'WAITING_FOR_REVIEW','Review state changed: stop before cancellation');
 assert.equal(version.attributes.releaseType,'MANUAL');
 const build=(await api.get(`/v1/appStoreVersions/${version.id}/build`)).data;
 assert.equal(build?.attributes.version,'8');assert.equal(build?.attributes.processingState,'VALID');
 const active=(await api.all(`/v1/reviewSubmissions?filter[app]=${APP}&filter[platform]=IOS`)).filter(s=>['WAITING_FOR_REVIEW','IN_REVIEW','READY_FOR_REVIEW','UNRESOLVED_ISSUES'].includes(s.attributes.state));
 assert.equal(active.length,1,'Expected exactly one active BibleAI iOS review');
 const sub=active[0];assert.equal(sub.attributes.state,'WAITING_FOR_REVIEW');
 const items=await api.all(`/v1/reviewSubmissions/${sub.id}/items`);
 const ids=items.map(i=>i.relationships?.appStoreVersion?.data?.id).filter(Boolean);
 assert(ids.includes(version.id),'Review does not contain the approved version');
 assert(ids.every(id=>id===version.id),'Review contains another version');
 fs.mkdirSync('build/aso-refresh',{recursive:true});
 fs.writeFileSync('build/aso-refresh/cancel-review-before.json',JSON.stringify({observedAt:new Date().toISOString(),version,build,submission:sub,items},null,2)+'\n');
 await api.patch(`/v1/reviewSubmissions/${sub.id}`,{data:{type:'reviewSubmissions',id:sub.id,attributes:{canceled:true}}});
 for(let i=0;i<30;i++){
  const current=(await api.get(`/v1/appStoreVersions/${version.id}`)).data;
  const review=(await api.get(`/v1/reviewSubmissions/${sub.id}`)).data;
  if(EDITABLE.has(current.attributes.appStoreState)&&review.attributes.state==='COMPLETE'){
   const afterBuild=(await api.get(`/v1/appStoreVersions/${version.id}/build`)).data;
   assert.equal(afterBuild.id,build.id);
   return {version:'2.0.1',build:'8',submission:sub.id,reviewState:review.attributes.state,versionState:current.attributes.appStoreState,canceled:true};
  }
  await new Promise(resolve=>setTimeout(resolve,6000));
 }
 throw new Error('Cancellation still processing after 180 seconds; inspect read-only, do not repeat cancellation');
};
