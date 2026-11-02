// Narrow rename of the already verified 2.0.1/build 8 package. Never repeat a full ASO upload.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import inspect from './aso-inspect.mjs';
import cancelReview from './swap-to-201.mjs';
import uploadAssets from './store-assets.mjs';
import {localPackage,digest,root} from '../aso-package.mjs';
const work=path.join(root,'build/aso-rebrand');
const mode=process.env.BIBLEAI_REBRAND_MODE;
const OLD='Scroll Bible', BRAND='Bright Scroll', TITLE='Bright Scroll: Bible AI';
const one=(xs,label)=>{assert.equal(xs.length,1,`Expected one ${label}`);return xs[0];};
const loc=r=>one(r.localizations.filter(l=>l.locale==='en-US'),'en-US localization');
const pending=r=>one(r.appInfos.filter(i=>i.appStoreState!=='READY_FOR_SALE'),'pending app info');
const infoLoc=r=>one(pending(r).localizations.filter(l=>l.attributes.locale==='en-US'),'en-US app info');
const creative=r=>loc(r).placements.data.filter(p=>['PRODUCT_PAGE_HEADER_ASSET','APP_STORE_SEARCH_RESULTS_ASSET'].includes(p.attributes.placementType));
const identity=r=>({app:r.app.id,version:r.version.id,build:r.build.id,localization:loc(r).id,info:pending(r).id});
const copy=r=>({...Object.fromEntries(['description','keywords','promotionalText','whatsNew','supportUrl','marketingUrl'].map(k=>[k,loc(r)[k]])),...Object.fromEntries(['name','subtitle','privacyPolicyUrl'].map(k=>[k,infoLoc(r).attributes[k]]))});
const screenshotProjection=r=>loc(r).screenshotSets.map(s=>({id:s.id,type:s.screenshotDisplayType,assets:s.assets.map(a=>({id:a.id,file:a.attributes.fileName,md5:a.attributes.sourceFileChecksum}))}));
const previewProjection=r=>loc(r).previewSets.map(s=>({id:s.id,type:s.previewType,assets:s.assets.map(a=>({id:a.id,file:a.attributes.fileName,md5:a.attributes.sourceFileChecksum}))}));
const placementProjection=r=>creative(r).map(p=>({id:p.id,type:p.attributes.placementType,group:p.attributes.placementGroup,video:p.relationships.video?.data?.id}));
const live=r=>r.appInfos.filter(i=>i.appStoreState==='READY_FOR_SALE');
const write=(name,value)=>fs.writeFileSync(path.join(work,name),JSON.stringify(value,null,2)+'\n');
function validateTarget(r){
 assert.equal(r.version.versionString,'2.0.1');assert.equal(r.version.releaseType,'MANUAL');
 assert.equal(r.build.attributes.version,'8');assert.equal(r.build.attributes.processingState,'VALID');
}
function validateRetained(r,pkg){
 assert.equal(loc(r).screenshotSets.length,pkg.sets.length);
 for(const expected of pkg.sets){
  const set=one(loc(r).screenshotSets.filter(s=>s.screenshotDisplayType===expected.type),expected.type);
  assert.equal(set.assets.length,expected.files.length);
  set.assets.forEach((asset,i)=>{const a=asset.attributes;
   assert.equal(a.fileName,path.basename(expected.files[i]));assert.equal(a.sourceFileChecksum,digest(expected.files[i]));
   assert.equal(a.assetDeliveryState?.state,'COMPLETE');
  });
 }
 assert.equal(loc(r).previewSets.length,1);
 const a=one(one(loc(r).previewSets.filter(s=>s.previewType==='IPHONE_67'),'preview set').assets,'preview').attributes;
 assert.equal(a.sourceFileChecksum,digest(pkg.videos.find(v=>v.kind==='preview').file));
 assert.equal(a.assetDeliveryState?.state,'COMPLETE');assert.equal(a.videoDeliveryState?.state,'COMPLETE');
 assert.equal(a.previewFrameImage?.state?.state,'COMPLETE');
}
function validatePreserved(r,plan){
 assert.deepEqual(identity(r),plan.identity,'Target identity changed');
 assert.deepEqual(screenshotProjection(r),plan.screenshots,'Screenshot ids/order/checksums changed');
 assert.deepEqual(previewProjection(r),plan.previews,'Preview ids/checksums changed');
 assert.deepEqual(live(r),plan.liveInfo,'Live app information changed');
 assert.deepEqual(r.customProductPages,plan.customProductPages,'Custom product pages changed');
}
function validateOriginal(r,review,plan){
 validatePreserved(r,plan);
 assert.deepEqual(copy(r),plan.oldCopy,'Submitted copy changed');
 assert.equal(review.attributes.notes,plan.oldReviewNotes,'Review notes changed');
 assert.deepEqual(placementProjection(r),plan.placements,'Creative placement ids changed');
 for(const p of creative(r)) assert.equal(p.attributes.state,'ACTIVE');
}
export default async api=>{
 assert(['plan','apply','verify'].includes(mode));
 const pkg=localPackage(true);assert.equal(pkg.copy.name,TITLE);
 const r=await inspect(api);validateTarget(r);validateRetained(r,pkg);
 const review=(await api.get(`/v1/appStoreVersions/${r.version.id}/appStoreReviewDetail`)).data;
 fs.mkdirSync(work,{recursive:true});
 const planFile=path.join(work,'plan.json'), receipt=path.join(work,'apply-before.json');
 if(mode==='plan'){
  assert(!fs.existsSync(receipt),'A rebrand apply already began; inspect, never overwrite its plan');
  assert.equal(r.version.appStoreState,'WAITING_FOR_REVIEW');
  const before=copy(r);assert.equal(before.name,'Scroll Bible: Daily Verses');
  assert.deepEqual(pkg.copy,{...before,name:TITLE,description:before.description.replaceAll(OLD,BRAND)},'Only name and description brand may change');
  assert.equal(pkg.reviewNotes,review.attributes.notes.replaceAll(OLD,BRAND),'Only review-note brand may change');
  const sub=one(r.reviewSubmissions,'active review');assert.equal(sub.attributes.state,'WAITING_FOR_REVIEW');
  assert(sub.items.length>0);
  for(const item of sub.items) assert.equal(item.relationships?.appStoreVersion?.data?.id,r.version.id);
  assert.equal(creative(r).length,2);for(const p of creative(r))assert.equal(p.attributes.state,'ACTIVE');
  const plan={observedAt:r.observedAt,inputHash:pkg.inputHash,identity:identity(r),submission:sub.id,
   oldCopy:before,oldReviewNotes:review.attributes.notes,newCopy:pkg.copy,newReviewNotes:pkg.reviewNotes,
   screenshots:screenshotProjection(r),previews:previewProjection(r),placements:placementProjection(r),
   liveInfo:live(r),customProductPages:r.customProductPages};
  write('plan.json',plan);
  return {planned:true,from:before.name,to:TITLE,version:'2.0.1',build:'8',submission:sub.id,
   writes:['cancel the exact pending review','update name, description brand and review-note brand','replace two branded creative placements'],
   preserved:['18 screenshots','App Preview','other metadata','build 8','MANUAL release','pricing','live app info'],
   inputHash:pkg.inputHash,next:'Review package and obtain approval before apply_rebrand; submit_review remains separate'};
 }
 const plan=JSON.parse(fs.readFileSync(planFile,'utf8'));
 assert.equal(plan.inputHash,pkg.inputHash,'Prepared package changed');validatePreserved(r,plan);
 if(mode==='verify'){
  assert(fs.existsSync(receipt),'No rebrand application receipt');
  assert.deepEqual(copy(r),pkg.copy);assert.equal(review.attributes.notes,pkg.reviewNotes);
  assert.equal(creative(r).length,2);
  for(const v of pkg.videos.filter(v=>v.placement)){
   const p=one(creative(r).filter(p=>p.attributes.placementType===v.placement&&p.attributes.placementGroup==='DEFAULT_PROFILE'),v.kind);
   assert.equal(p.attributes.state,'ACTIVE');
   const a=one((loc(r).placements.included||[]).filter(a=>a.type==='appAssetLibraryVideos'&&a.id===p.relationships.video?.data?.id),v.kind+' video').attributes;
   assert.equal(a.fileSize,fs.statSync(v.file).size);assert(a.referenceName.includes(digest(v.file).slice(0,12)));
   assert(['PREPARE_FOR_SUBMISSION','APPROVED','WAITING_FOR_REVIEW','IN_REVIEW'].includes(a.state));
   assert.equal(a.previewFrameImage?.state?.state,'COMPLETE');
  }
  return {verified:true,name:TITLE,version:'2.0.1',build:'8',screenshotsPreserved:18,previewPreserved:true,videos:2,state:r.version.appStoreState,inputHash:pkg.inputHash};
 }
 assert(!fs.existsSync(receipt),'Rebrand already began; inspect saved progress instead of repeating');
 assert(Date.now()-Date.parse(plan.observedAt)<24*60*60*1000,'Refresh read-only plan after 24 hours');
 assert.equal(r.version.appStoreState,'WAITING_FOR_REVIEW');validateOriginal(r,review,plan);
 assert.equal(one(r.reviewSubmissions,'active review').id,plan.submission);
 write('apply-before.json',{observedAt:new Date().toISOString(),inputHash:pkg.inputHash,apple:r,review});
 const cancellation=await cancelReview(api,{expectedSubmission:plan.submission,receiptDir:work});write('cancel-result.json',cancellation);
 const editable=await inspect(api);validateTarget(editable);validateRetained(editable,pkg);
 validateOriginal(editable,(await api.get(`/v1/appStoreVersions/${editable.version.id}/appStoreReviewDetail`)).data,plan);
 assert(['DEVELOPER_REJECTED','PREPARE_FOR_SUBMISSION','REJECTED','METADATA_REJECTED'].includes(editable.version.appStoreState));
 assert(['DEVELOPER_REJECTED','PREPARE_FOR_SUBMISSION','REJECTED','METADATA_REJECTED'].includes(pending(editable).appStoreState));
 const il=infoLoc(editable),l=loc(editable);
 await api.patch(`/v1/appInfoLocalizations/${il.id}`,{data:{type:'appInfoLocalizations',id:il.id,attributes:{name:TITLE}}});
 await api.patch(`/v1/appStoreVersionLocalizations/${l.id}`,{data:{type:'appStoreVersionLocalizations',id:l.id,attributes:{description:pkg.copy.description}}});
 await api.patch(`/v1/appStoreReviewDetails/${review.id}`,{data:{type:'appStoreReviewDetails',id:review.id,attributes:{notes:pkg.reviewNotes}}});
 const record=data=>fs.appendFileSync(path.join(work,'progress.jsonl'),JSON.stringify({at:new Date().toISOString(),...data})+'\n');
 const assets=await uploadAssets(api,{guarded:true,videosOnly:true,expectedPlacements:creative(editable),record});
 return {applied:true,name:TITLE,assets,inputHash:pkg.inputHash,next:'verify_rebrand, then separately approved existing submit_review; no new binary or price/release change'};
};
