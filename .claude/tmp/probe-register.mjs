import puppeteer from 'puppeteer-core'
const settle = (ms=1200)=>new Promise(r=>setTimeout(r,ms))
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: 'new', args: ['--no-sandbox'] })
const page = await browser.newPage()
await page.setViewport({ width: 1280, height: 1400 })
await page.setCookie(
  { name: 'i18n_locale', value: 'en', domain: 'localhost', path: '/' },
  { name: 'lang', value: encodeURIComponent(JSON.stringify({ code: 'en', direction: 'ltr' })), domain: 'localhost', path: '/' },
)
page.on('response', async (r) => {
  if (!/\/api\//.test(r.url()) || r.request().method() === 'GET') return
  let b=''; try { b = JSON.stringify(await r.json()).slice(0,300) } catch {}
  console.log(' ', r.status(), r.request().method(), r.url().replace('http://localhost:3000',''), b)
})
const fill = async (sel, val) => {
  await page.waitForSelector(sel, { timeout: 20000 })
  for (let i=0;i<3;i++){ await page.click(sel,{clickCount:3}).catch(()=>{}); await page.type(sel,val,{delay:15}); if (await page.$eval(sel,e=>e.value)===val) return; await settle(600) }
}
// seed a guest basket first, like the real flow
await page.goto('http://localhost:3000/shop/1', { waitUntil: 'domcontentloaded' }); await settle(3000)
await page.evaluate(() => { const b=[...document.querySelectorAll('button')].find(n=>/^(add|اضافة)/i.test((n.innerText||'').trim())&&!n.disabled); b?.click() })
await settle(1500)
console.log('basket:', await page.evaluate(()=>localStorage.getItem('terracotta:cart')))
const phone = `5${String(Math.floor(Math.random()*90000000)+10000000)}`
await page.goto('http://localhost:3000/register', { waitUntil: 'domcontentloaded' }); await settle(3000)
await fill('#name','Probe Reg'); await fill('input[inputmode="numeric"]', phone); await settle(1500)
await fill('#password','Str0ngP@ssw0rd!'); await fill('#confirm','Str0ngP@ssw0rd!')
await page.click('[role=checkbox]'); await settle(600)
console.log('phone', phone)
await page.click('button[type=submit]')
await settle(9000)
console.log('url:', page.url())
console.log('errors:', await page.evaluate(()=>[...document.querySelectorAll('.text-destructive')].map(e=>e.innerText.trim()).filter(Boolean)))
console.log('basket after:', await page.evaluate(()=>localStorage.getItem('terracotta:cart')))
await browser.close()
