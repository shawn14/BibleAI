// Read-only inventory for the complete BibleAI listing refresh. No writes or review changes.
import assert from 'node:assert/strict';
const APP='6756225286';
export default async api=>{
 const app=(await api.get(`/v1/apps/${APP}`)).data;
 assert.equal(app.attributes.bundleId,'com.shawncarpenter.bibleai-companion');
 const versions=await api.all(`/v1/apps/${APP}/appStoreVersions?filter[platform]=IOS`);
 const version=versions.find(v=>v.attributes.versionString==='2.0.1');
 assert(version,'Expected existing iOS 2.0.1');
 const build=(await api.get(`/v1/appStoreVersions/${version.id}/build`)).data;
 const infos=await api.all(`/v1/apps/${APP}/appInfos`);
 const appInfos=[];
 for(const info of infos){
  const localizations=await api.all(`/v1/appInfos/${info.id}/appInfoLocalizations`);
  appInfos.push({id:info.id,...info.attributes,relationships:info.relationships,localizations});
 }
 const locales=await api.all(`/v1/appStoreVersions/${version.id}/appStoreVersionLocalizations`);
 const localizations=[];
 for(const loc of locales){
  const screenshotSets=[];
  for(const set of await api.all(`/v1/appStoreVersionLocalizations/${loc.id}/appScreenshotSets`))
   screenshotSets.push({id:set.id,...set.attributes,assets:await api.all(`/v1/appScreenshotSets/${set.id}/appScreenshots`)});
  const previewSets=[];
  for(const set of await api.all(`/v1/appStoreVersionLocalizations/${loc.id}/appPreviewSets`))
   previewSets.push({id:set.id,...set.attributes,assets:await api.all(`/v1/appPreviewSets/${set.id}/appPreviews`)});
  const placements=await api.get(`/v1/appStoreVersionLocalizations/${loc.id}/placements?include=image,video`);
  localizations.push({id:loc.id,...loc.attributes,screenshotSets,previewSets,placements});
 }
 return {observedAt:new Date().toISOString(),app:{id:APP,...app.attributes},
  version:{id:version.id,...version.attributes},build,appInfos,localizations,
  customProductPages:await api.all(`/v1/apps/${APP}/appCustomProductPages`)};
};
