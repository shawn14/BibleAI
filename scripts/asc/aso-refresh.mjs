// Milepost's inspect/apply/verify pattern, restricted to BibleAI's existing 2.0.1/build 8.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import inspect from './aso-inspect.mjs';
import uploadAssets from './store-assets.mjs';
import {localPackage,digest,root} from '../aso-package.mjs';
const mode=process.env.BIBLEAI_ASO_MODE;
const work=path.join(root,'build/aso-refresh');
const only=(xs,label)=>{assert.equal(xs.length,1,`Expected one ${label}`);return xs[0];};
const editable=new Set(['PREPARE_FOR_SUBMISSION','DEVELOPER_REJECTED','REJECTED','READY_FOR_REVIEW']);
const target=r=>only(r.localizations.filter(l=>l.locale==='en-US'),'en-US version locale');
const info=r=>only(r.appInfos.filter(i=>i.appStoreState!=='READY_FOR_SALE'),'pending app info');
const infoLoc=r=>only(info(r).localizations.filter(l=>l.attributes.locale==='en-US'),'en-US app info');
const identity=r=>({app:r.app.id,version:r.version.id,build:r.build?.id,localization:target(r).id,info:info(r).id});
const inventory=r=>({identity:identity(r),copy:Object.fromEntries(['description','keywords','promotionalText','whatsNew','supportUrl','marketingUrl'].map(k=>[k,target(r)[k]])),info:infoLoc(r).attributes,sets:target(r).screenshotSets.map(s=>({id:s.id,type:s.screenshotDisplayType,assets:s.assets.map(a=>({id:a.id,file:a.attributes.fileName,md5:a.attributes.sourceFileChecksum}))})),previews:target(r).previewSets.map(s=>({id:s.id,type:s.previewType,assets:s.assets.map(a=>({id:a.id,file:a.attributes.fileName,md5:a.attributes.sourceFileChecksum}))})),placements:target(r).placements.data.filter(p=>['PRODUCT_PAGE_HEADER_ASSET','APP_STORE_SEARCH_RESULTS_ASSET'].includes(p.attributes.placementType)).map(p=>({id:p.id,...p.attributes,relationships:p.relationships}))});
export default async api=>{
 const pkg=localPackage(true);
 const current=await inspect(api);
 assert.equal(current.build?.attributes.version,'8');assert.equal(current.build?.attributes.processingState,'VALID');
 assert.equal(current.version.versionString,'2.0.1');assert.equal(current.version.releaseType,'MANUAL');
 const loc=target(current),il=infoLoc(current);
 const review=(await api.get(`/v1/appStoreVersions/${current.version.id}/appStoreReviewDetail`)).data;
 const receipt=path.join(work,'apply-before.json');
 fs.mkdirSync(work,{recursive:true});
 if(mode==='verify'){
  const before=JSON.parse(fs.readFileSync(receipt,'utf8'));
  assert.equal(before.inputHash,pkg.inputHash,'Local package changed after application');
  assert.deepEqual(identity(current),identity(before.apple),'App/version/build changed');
  for(const k of ['name','subtitle','privacyPolicyUrl']) assert.equal(il.attributes[k],pkg.copy[k],`${k} differs`);
  for(const k of ['description','keywords','promotionalText','whatsNew','supportUrl','marketingUrl']) assert.equal(loc[k],pkg.copy[k],`${k} differs`);
  assert.equal(review.attributes.notes,pkg.reviewNotes);
  assert.deepEqual(current.appInfos.filter(i=>i.appStoreState==='READY_FOR_SALE'),before.apple.appInfos.filter(i=>i.appStoreState==='READY_FOR_SALE'),'Live app info changed');
  assert.deepEqual(current.customProductPages,before.apple.customProductPages,'Custom pages changed');
  for(const expected of pkg.sets){
   const set=only(loc.screenshotSets.filter(s=>s.screenshotDisplayType===expected.type),expected.type);
   assert.equal(set.assets.length,expected.files.length);
   for(let i=0;i<expected.files.length;i++){
    const a=set.assets[i].attributes,file=expected.files[i];
    assert.equal(a.fileName,path.basename(file));assert.equal(a.sourceFileChecksum,digest(file));assert.equal(a.assetDeliveryState?.state,'COMPLETE');
   }
  }
  const preview=only(only(loc.previewSets.filter(s=>s.previewType==='IPHONE_67'),'preview set').assets,'preview').attributes;
  assert.equal(preview.sourceFileChecksum,digest(pkg.videos[0].file));assert.equal(preview.assetDeliveryState?.state,'COMPLETE');
  assert.equal(preview.videoDeliveryState?.state,'COMPLETE');assert.equal(preview.previewFrameImage?.state?.state,'COMPLETE');
  for(const v of pkg.videos.filter(v=>v.placement)){
   const p=only(loc.placements.data.filter(p=>p.attributes.placementType===v.placement&&p.attributes.placementGroup==='DEFAULT_PROFILE'),v.kind+' placement');
   assert.equal(p.attributes.state,'ACTIVE');
   const video=only((loc.placements.included||[]).filter(a=>a.type==='appAssetLibraryVideos'&&a.id===p.relationships.video?.data?.id),v.kind+' video').attributes;
   assert.equal(video.fileSize,fs.statSync(v.file).size);assert(video.referenceName.includes(digest(v.file).slice(0,12)));
   assert(['PREPARE_FOR_SUBMISSION','APPROVED','WAITING_FOR_REVIEW','IN_REVIEW'].includes(video.state),`${v.kind}: ${video.state}`);
   assert.equal(video.previewFrameImage?.state?.state,'COMPLETE');
  }
  return {verified:true,version:'2.0.1',build:'8',screenshots:18,videos:3,inputHash:pkg.inputHash,state:current.version.appStoreState};
 }
 assert.equal(mode,'apply');
 assert(editable.has(current.version.appStoreState),`Stop: 2.0.1 is ${current.version.appStoreState}; no automatic review cancellation`);
 assert(editable.has(info(current).appStoreState),'App info is not editable');
 const baseline=JSON.parse(fs.readFileSync(path.join(work,'apple-inventory-before.json'),'utf8'));
 assert(Date.now()-Date.parse(baseline.observedAt)<24*60*60*1000,'Refresh read-only inspection after 24 hours');
 assert.deepEqual(inventory(current),inventory(baseline),'Apple copy/assets changed since inspection');
 assert(!fs.existsSync(receipt),'An apply already began. Inspect saved progress; never blindly repeat');
 assert.deepEqual(loc.screenshotSets.map(s=>s.screenshotDisplayType).sort(),['APP_IPAD_PRO_3GEN_129','APP_IPHONE_67'].sort(),'Unexpected existing screenshot sets');
 for(const s of loc.screenshotSets) assert.equal(s.assets.length,6);
 assert.equal(loc.previewSets.length,1);assert.equal(loc.previewSets[0].previewType,'IPHONE_67');assert.equal(loc.previewSets[0].assets.length,1);
 fs.writeFileSync(receipt,JSON.stringify({inputHash:pkg.inputHash,apple:current,review},null,2)+'\n');
 await api.patch(`/v1/appInfoLocalizations/${il.id}`,{data:{type:'appInfoLocalizations',id:il.id,attributes:Object.fromEntries(['name','subtitle','privacyPolicyUrl'].map(k=>[k,pkg.copy[k]]))}});
 await api.patch(`/v1/appStoreVersionLocalizations/${loc.id}`,{data:{type:'appStoreVersionLocalizations',id:loc.id,attributes:Object.fromEntries(['description','keywords','promotionalText','whatsNew','supportUrl','marketingUrl'].map(k=>[k,pkg.copy[k]]))}});
 await api.patch(`/v1/appStoreReviewDetails/${review.id}`,{data:{type:'appStoreReviewDetails',id:review.id,attributes:{notes:pkg.reviewNotes}}});
 const assets=await uploadAssets(api,{guarded:true});
 return {applied:true,assets,inputHash:pkg.inputHash,next:'verify_aso after Apple processing; no review, binary, pricing or release action performed'};
};
