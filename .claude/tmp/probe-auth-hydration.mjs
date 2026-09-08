import puppeteer from 'puppeteer-core'
const settle=(ms=1200)=>new Promise(r=>setTimeout(r,ms))
const browser = await puppeteer.launch({ executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless:'new', args:['--no-sandbox'] })
const page = await browser.newPage()
await page.setViewport({width:1280,height:1400})
await page.setCookie(
  {name:'i18n_locale',value:'en',domain:'localhost',path:'/'},
  {name:'lang',value:encodeURIComponent(JSON.stringify({code:'en',direction:'ltr'})),domain:'localhost',path:'/'},
)
const fill=async(sel,val)=>{await page.waitForSelector(sel,{timeout:20000});for(let i=0;i<3;i++){await page.click(sel,{clickCount:3}).catch(()=>{});await page.type(sel,val,{delay:15});if(await page.$eval(sel,e=>e.value)===val)return;await settle(600)}}
// guest basket first, so the registered cart has a line
await page.goto('http://localhost:3000/shop/1',{waitUntil:'domcontentloaded'});await settle(3000)
await page.evaluate(()=>{const b=[...document.querySelectorAll('button')].find(n=>/^(add|اضافة)/i.test((n.innerText||'').trim())&&!n.disabled);b?.click()})
await settle(1200)
const phone=`5${String(Math.floor(Math.random()*90000000)+10000000)}`
await page.goto('http://localhost:3000/register',{waitUntil:'domcontentloaded'});await settle(2500)
await fill('#name','Hydration Probe');await fill('input[inputmode="numeric"]',phone);await settle(1500)
await fill('#password','Str0ngP@ssw0rd!');await fill('#confirm','Str0ngP@ssw0rd!')
await page.click('[role=checkbox]');await settle(600)
await page.click('button[type=submit]')
await page.waitForFunction(()=>!location.pathname.startsWith('/register'),{timeout:45000}).catch(()=>{})
await settle(8000)
console.log('registered', phone, page.url())
for (const path of ['/','/shop','/shop/1','/cart','/checkout','/orders','/favorites','/profile']) {
  const warnings=[]
  page.on('console',(m)=>{const t=m.text();if(/Hydration|mismatch/i.test(t))warnings.push(t.replace(/\s+/g,' ').slice(0,240))})
  await page.goto(`http://localhost:3000${path}`,{waitUntil:'domcontentloaded'})
  await settle(4500)
  console.log(`  ${warnings.length?'FAIL':'ok  '} ${path} — ${warnings.length}`)
  ;[...new Set(warnings)].slice(0,2).forEach(w=>console.log(`        ${w}`))
  page.removeAllListeners('console')
}
await browser.close()
