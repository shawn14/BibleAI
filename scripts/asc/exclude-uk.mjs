// BibleAI only. Run without APPLY_BIBLEAI_UK_OFF for a read-only preview.
import assert from 'node:assert/strict';
const app = '6756225286', bundle = 'com.shawncarpenter.bibleai-companion';

export default async api => {
  const target = (await api.get('/v1/apps/'+app+'?fields[apps]=bundleId,name')).data;
  assert.equal(target.id,app); assert.equal(target.attributes.bundleId,bundle);
  const availability = (await api.get('/v1/apps/'+app+'/appAvailabilityV2')).data;
  assert.equal(availability.type,'appAvailabilities');
  async function inventory(){
    const rows = await api.all('/v2/appAvailabilities/'+availability.id+'/territoryAvailabilities?limit=200&include=territory');
    const index = {};
    for(const r of rows){
      const code=r.relationships.territory.data.id;
      assert.match(code,/^[A-Z]{3}$/); assert(!index[code]);
      assert.equal(r.type,'territoryAvailabilities'); assert.equal(typeof r.attributes.available,'boolean');
      index[code]={id:r.id,enabled:r.attributes.available,release:r.attributes.releaseDate??null,
        preOrder:r.attributes.preOrderEnabled??false,preOrderDate:r.attributes.preOrderPublishDate??null};
    }
    assert(index.GBR && index.USA && rows.length>1);
    return index;
  }
  const count=map=>Object.values(map).filter(t=>t.enabled).length;
  const before=await inventory();
  const receipt={app,bundle,before:count(before),territories:Object.keys(before).length,ukBefore:before.GBR.enabled};
  assert(!before.GBR.preOrder,'UK has a pre-order; inspect it before changing availability');
  if(!before.GBR.enabled){
    assert(!(before.GBR.release && Date.parse(before.GBR.release)>Date.now()),'A future UK release is scheduled');
    return {...receipt,after:count(before),changed:[],ukAfter:false};
  }
  if(process.env.APPLY_BIBLEAI_UK_OFF!=='1')return {...receipt,wouldChange:['GBR'],expectedAfter:count(before)-1};
  const id=before.GBR.id;
  await api.patch('/v1/territoryAvailabilities/'+id,{data:{type:'territoryAvailabilities',id,attributes:{available:false}}});
  const after=await inventory(); assert.deepEqual(Object.keys(before).sort(),Object.keys(after).sort());
  for(const k of Object.keys(before))if(k!=='GBR')assert.deepEqual(after[k],before[k],'Unexpected change to '+k);
  assert.equal(after.GBR.id,id); assert.equal(after.GBR.enabled,false);
  assert(!after.GBR.preOrder && !(after.GBR.release && Date.parse(after.GBR.release)>Date.now()),'Future UK release is scheduled');
  assert.equal(count(after),count(before)-1);
  return {...receipt,after:count(after),changed:['GBR'],ukAfter:false,usaAfter:after.USA.enabled,verifiedAt:new Date().toISOString()};
};
