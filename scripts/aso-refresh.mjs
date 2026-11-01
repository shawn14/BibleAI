import fs from 'node:fs';
import {execFileSync} from 'node:child_process';
import {localPackage} from './aso-package.mjs';
const mode=process.argv[2];
if(mode==='check'){
 const p=localPackage(true);
 console.log(JSON.stringify({localPackage:'passed',screenshots:p.sets.reduce((n,s)=>n+s.files.length,0),videos:p.videos.map(v=>({kind:v.kind,width:v.width,height:v.height,seconds:v.seconds})),copyLengths:Object.fromEntries(Object.entries(p.copy).map(([k,v])=>[k,[...v].length]))},null,2));
}else{
 if(!['apply','verify'].includes(mode)) throw new Error('Choose check, apply, or verify');
 if(!process.env.MAC_RUNNER_JOB_ID) throw new Error('Use the committed mac-run action');
 execFileSync(process.execPath,['scripts/asc/asc.mjs','scripts/asc/aso-refresh.mjs'],{stdio:'inherit',env:{...process.env,BIBLEAI_ASO_MODE:mode}});
 const r=JSON.parse(fs.readFileSync('scripts/asc/aso-refresh.out.json','utf8'));
 if(!r.ok) throw new Error(r.error);
 fs.mkdirSync('build/aso-refresh',{recursive:true});fs.writeFileSync(`build/aso-refresh/${mode}-result.json`,JSON.stringify(r,null,2)+'\n');
 console.log(JSON.stringify(r.result,null,2));
}
