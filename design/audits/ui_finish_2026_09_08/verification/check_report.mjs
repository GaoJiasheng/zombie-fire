// Offline desktop/mobile QA. A fresh headless browser profile; no user browser.
import {spawn} from 'node:child_process';
import {mkdtemp,readFile,writeFile} from 'node:fs/promises';
import {dirname,join} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
const here=dirname(fileURLToPath(import.meta.url)), audit=dirname(here);
const profile=await mkdtemp('/private/tmp/zf-fix-report-');
const browser=spawn('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',['--headless','--disable-gpu','--disable-background-networking','--no-first-run','--no-default-browser-check',`--user-data-dir=${profile}`,'--remote-debugging-port=0'],{stdio:'ignore'});
const delay=ms=>new Promise(r=>setTimeout(r,ms));
let socket;
try {
 let port;
 for(let i=0;i<100;i++){try{port=(await readFile(join(profile,'DevToolsActivePort'),'utf8')).split('\n')[0];break;}catch{await delay(100);}}
 if(!port)throw Error('Browser not started');
 const tab=await(await fetch(`http://127.0.0.1:${port}/json/new?about:blank`,{method:'PUT'})).json();
 socket=new WebSocket(tab.webSocketDebuggerUrl);
 await new Promise((ok,no)=>{socket.onopen=ok;socket.onerror=no;});
 let id=0; const pending=new Map();
 socket.onmessage=e=>{const m=JSON.parse(e.data);if(m.id){const p=pending.get(m.id);pending.delete(m.id);m.error?p.no(Error(JSON.stringify(m.error))):p.ok(m.result);}};
 const call=(method,params={})=>new Promise((ok,no)=>{const key=++id;pending.set(key,{ok,no});socket.send(JSON.stringify({id:key,method,params}));});
 await call('Page.enable');
 const results=[];
 for(const view of [{name:'desktop',width:1440,height:1100},{name:'mobile',width:412,height:1000}]){
  await call('Emulation.setDeviceMetricsOverride',{width:view.width,height:view.height,deviceScaleFactor:1,mobile:false});
  await call('Page.navigate',{url:pathToFileURL(join(audit,'UI收尾对比报告.html')).href});
  await delay(900);
  // Validate the expandable comparisons too, not just the collapsed header.
  await call('Runtime.evaluate',{expression:`(async()=>{document.querySelectorAll('details').forEach(d=>d.open=true);await Promise.all([...document.images].map(i=>{i.loading='eager';return i.complete?Promise.resolve():new Promise(r=>{i.onload=r;i.onerror=r;});}));})()`,awaitPromise:true});
  const result=JSON.parse((await call('Runtime.evaluate',{expression:`JSON.stringify({viewport:innerWidth,document:document.documentElement.scrollWidth,sections:document.querySelectorAll('section[id]').length,missingImages:[...document.images].filter(i=>i.complete&&!i.naturalWidth).map(i=>i.src)})`,returnByValue:true})).result.value);
  const shot=await call('Page.captureScreenshot',{format:'png',captureBeyondViewport:false,fromSurface:true});
  await writeFile(join(here,`report_${view.name}.png`),Buffer.from(shot.data,'base64'));
  results.push({...view,...result});
  if(result.document>view.width||result.sections!==29||result.missingImages.length)throw Error(JSON.stringify(result));
 }
 await writeFile(join(here,'report_layout_qa.json'),JSON.stringify(results,null,2));
 console.log(JSON.stringify(results,null,2));
 await call('Browser.close');
}finally{socket?.close();browser.kill('SIGTERM');}
