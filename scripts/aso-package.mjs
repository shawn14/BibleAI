// Local assets and copy are the inputs to the existing ASC upload path.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
export const root=path.resolve(import.meta.dirname,'..');
export const aso=path.join(root,'docs/aso');
export const digest=(file,algorithm='md5')=>crypto.createHash(algorithm).update(fs.readFileSync(file)).digest('hex');
const text=name=>fs.readFileSync(path.join(aso,'en-US',name+'.txt'),'utf8').trim();
export function localPackage(probe=false){
 const copy={name:text('name'),subtitle:text('subtitle'),keywords:text('keywords'),promotionalText:text('promotional_text'),description:text('description'),whatsNew:text('release_notes'),supportUrl:text('support_url'),marketingUrl:text('marketing_url'),privacyPolicyUrl:text('privacy_url')};
 for(const [field,limit] of Object.entries({name:30,subtitle:30,keywords:100,promotionalText:170,description:4000,whatsNew:4000})) assert(copy[field]&&[...copy[field]].length<=limit,`${field} exceeds ${limit}`);
 for(const field of ['supportUrl','marketingUrl','privacyPolicyUrl']) assert.equal(new URL(copy[field]).protocol,'https:');
 const sets=[['APP_IPHONE_67','screenshots-6.9',1320,2868],['APP_IPHONE_61','screenshots-6.3',1206,2622],['APP_IPAD_PRO_3GEN_129','screenshots-ipad-13',2064,2752]].map(([type,dir,width,height])=>{
  const files=fs.readdirSync(path.join(aso,dir)).filter(f=>f.endsWith('.png')).sort().map(f=>path.join(aso,dir,f));
  assert.equal(files.length,6,`${type} must have six screenshots`);
  for(const file of files){const b=fs.readFileSync(file);assert.equal(b.subarray(0,8).toString('hex'),'89504e470d0a1a0a');assert.equal(b.readUInt32BE(16),width);assert.equal(b.readUInt32BE(20),height);assert.equal(b[25],2,'Screenshots must be RGB without alpha');}
  return {type,files};
 });
 const videos=[
  {kind:'preview',file:path.join(aso,'preview/BibleAI-preview-6.9.mp4'),width:886,height:1920,seconds:25.5},
  {kind:'header',placement:'PRODUCT_PAGE_HEADER_ASSET',file:path.join(aso,'header-video/product-page-header.mp4'),width:3840,height:1646,seconds:10.5},
  {kind:'search',placement:'APP_STORE_SEARCH_RESULTS_ASSET',file:path.join(aso,'header-video/search-results.mp4'),width:3840,height:2560,seconds:10.5}
 ];
 for(const v of videos){
  assert(fs.statSync(v.file).size>10000,`Missing video ${v.kind}`);
  if(probe){
   const info=JSON.parse(execFileSync('ffprobe',['-v','error','-show_streams','-show_format','-of','json',v.file],{encoding:'utf8'}));
   const video=info.streams.find(s=>s.codec_type==='video');
   assert.equal(video.codec_name,'h264');assert.equal(video.width,v.width);assert.equal(video.height,v.height);assert.equal(video.r_frame_rate,'30/1');assert.equal(video.pix_fmt,'yuv420p');
   assert(Math.abs(Number(info.format.duration)-v.seconds)<0.1,`Unexpected ${v.kind} duration`);
   assert(info.streams.some(s=>s.codec_type==='audio'&&s.codec_name==='aac'),'Expected AAC audio track');
  }
 }
 const reviewNotes=text('review_notes');assert(reviewNotes.length<=4000);
 const files=[...sets.flatMap(s=>s.files),...videos.map(v=>v.file),...fs.readdirSync(path.join(aso,'en-US')).filter(f=>f.endsWith('.txt')).map(f=>path.join(aso,'en-US',f))];
 return {copy,reviewNotes,sets,videos,inputHash:crypto.createHash('sha256').update(JSON.stringify(files.map(file=>[path.relative(root,file),digest(file,'sha256')]))).digest('hex')};
}
