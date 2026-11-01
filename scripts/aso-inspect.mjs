// Reuse Milepost's receipt-aware wrapper: an ASC client error must fail the runner job.
import fs from 'node:fs';
import {execFileSync} from 'node:child_process';
execFileSync(process.execPath,['scripts/asc/asc.mjs','scripts/asc/aso-inspect.mjs'],{stdio:'inherit'});
const result=JSON.parse(fs.readFileSync('scripts/asc/aso-inspect.out.json','utf8'));
if(!result.ok) throw new Error(result.error);
fs.mkdirSync('build/aso-refresh',{recursive:true});
fs.writeFileSync('build/aso-refresh/apple-inventory-before.json',JSON.stringify(result.result,null,2)+'\n');
const r=result.result;
console.log(JSON.stringify({observedAt:r.observedAt,version:r.version.versionString,state:r.version.appStoreState,
 build:r.build?.attributes.version,locales:r.localizations.map(l=>({locale:l.locale,
 screenshots:l.screenshotSets.map(s=>({type:s.screenshotDisplayType,count:s.assets.length,states:s.assets.map(a=>a.attributes.assetDeliveryState?.state)})),
 previews:l.previewSets.map(s=>({type:s.previewType,count:s.assets.length,states:s.assets.map(a=>a.attributes.assetDeliveryState?.state)})),
 placements:l.placements.data.map(p=>({type:p.attributes.placementType,group:p.attributes.placementGroup}))})),customPages:r.customProductPages.length},null,2));
