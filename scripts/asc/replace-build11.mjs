// The one older review Shawn asked to supersede. Preserve its version record, listing and media.
import assert from 'node:assert/strict';
const previous={version:'2.0.3',build:'11',record:'fa92c7d3-31ee-4382-bb15-b5f696cfaacb',review:'3bd24b24-918b-42e6-b80b-7e5e429b10af',binary:'5a2b86c0-1290-498f-b5c2-370fa336e861'};
const editable=new Set(['DEVELOPER_REJECTED','PREPARE_FOR_SUBMISSION','REJECTED','METADATA_REJECTED']);
export default async function replacePrevious(api,release,file){
  assert.equal(release.GBR.available,false);
  assert.equal(file.attributes.version,'13');assert.equal(file.attributes.processingState,'VALID');assert.equal(file.attributes.usesNonExemptEncryption,false);
  const row=release.versions.find(v=>v.id===previous.record);
  if(!row || row.version!=='2.0.3' || ['READY_FOR_SALE','READY_FOR_DISTRIBUTION'].includes(row.state))return;
  assert(!release.versions.some(v=>v.version==='2.0.4'),'Both versions exist: inspect manually');
  assert.equal(row.release,'MANUAL');assert(row.build==='11' || (row.build===null && editable.has(row.state)));
  const base='/v1/appStoreVersions/'+row.id;
  const oldBuild=async()=>{try{return (await api.get(base+'/build')).data;}catch(e){if(e.status===404)return null;throw e;}};
  let old=await oldBuild();
  if(old){assert.equal(old.id,previous.binary);assert.equal(old.attributes.version,previous.build);}
  if(release.review.length){
    assert.equal(release.review.length,1);
    const s=release.review[0];assert.equal(s.id,previous.review);assert.equal(s.state,'WAITING_FOR_REVIEW');assert.equal(row.state,'WAITING_FOR_REVIEW');
    assert.equal(s.items.length,1);assert.equal(s.items[0].versionId,row.id);
    assert.equal(old?.id,previous.binary);
    await api.patch('/v1/reviewSubmissions/'+s.id,{data:{type:'reviewSubmissions',id:s.id,attributes:{canceled:true}}});
  }
  let attrs;
  for(let n=0;n<30;n++){
    attrs=(await api.get(base)).data.attributes;
    if(editable.has(attrs.appStoreState))break;
    if(attrs.appStoreState!=='WAITING_FOR_REVIEW')throw Error('Unexpected state: '+attrs.appStoreState);
    await new Promise(r=>setTimeout(r,4000));
  }
  assert(editable.has(attrs.appStoreState));assert.equal(attrs.versionString,previous.version);assert.equal(attrs.releaseType,'MANUAL');
  old=await oldBuild();
  if(old){
    assert.equal(old.id,previous.binary);
    await api.patch(base+'/relationships/build',{data:null});
    assert.equal(await oldBuild(),null);
  }
  await api.patch(base,{data:{type:'appStoreVersions',id:row.id,attributes:{versionString:'2.0.4'}}});
  const changed=(await api.get(base)).data.attributes;
  assert.equal(changed.versionString,'2.0.4');assert.equal(changed.releaseType,'MANUAL');
}
