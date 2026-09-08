import puppeteer from 'puppeteer-core'

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
const BASE = 'http://localhost:3000'
const PHONE_LOCAL = `5${String(Math.floor(Math.random() * 90000000) + 10000000)}`

const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox'] })
const page = await browser.newPage()
await page.setViewport({ width: 1280, height: 1200 })

page.on('request', (r) => { if (r.url().includes('/api/register') || r.url().includes('/api/check-identifier')) console.log('REQ', r.method(), r.url().replace(BASE, ''), r.postData()) })
page.on('response', async (r) => {
  if (r.url().includes('/api/register') || r.url().includes('/api/check-identifier') || r.url().includes('/api/login')) {
    let b = ''
    try { b = JSON.stringify(await r.json()).slice(0, 400) } catch {}
    console.log('RES', r.status(), r.url().replace(BASE, ''), b)
  }
})
page.on('pageerror', (e) => console.log('PAGEERROR', String(e.message).slice(0, 200)))

await page.setCookie(
  { name: 'i18n_locale', value: 'ar', domain: 'localhost', path: '/' },
  { name: 'lang', value: encodeURIComponent(JSON.stringify({ code: 'ar', direction: 'rtl' })), domain: 'localhost', path: '/' },
)

await page.goto(`${BASE}/register`, { waitUntil: 'domcontentloaded' })
await page.waitForSelector('#name', { timeout: 15000 })
await new Promise((r) => setTimeout(r, 1500))

console.log('--- inputs on page:')
console.log(await page.evaluate(() => [...document.querySelectorAll('input')].map((i) => ({ id: i.id, type: i.type, inputmode: i.inputMode, required: i.required }))))
console.log('--- checkbox elements:')
console.log(await page.evaluate(() => [...document.querySelectorAll('[role=checkbox], #policy')].map((e) => ({ tag: e.tagName, role: e.getAttribute('role'), state: e.getAttribute('aria-checked') ?? e.getAttribute('data-state') }))))

await page.type('#name', 'Smoke Tester')
const phone = await page.$('input[inputmode="numeric"]')
await phone.type(PHONE_LOCAL)
await new Promise((r) => setTimeout(r, 1200))
await page.type('#password', 'Str0ngP@ssw0rd!')
await page.type('#confirm', 'Str0ngP@ssw0rd!')

const box = await page.$('[role=checkbox]')
if (box) { await box.click(); console.log('clicked checkbox') } else { console.log('NO CHECKBOX FOUND') }
await new Promise((r) => setTimeout(r, 400))
console.log('checkbox state after click:', await page.evaluate(() => document.querySelector('[role=checkbox]')?.getAttribute('data-state') ?? document.querySelector('[role=checkbox]')?.getAttribute('aria-checked')))

console.log('submit disabled?', await page.evaluate(() => document.querySelector('button[type=submit]')?.disabled))
await page.click('button[type=submit]')
await new Promise((r) => setTimeout(r, 5000))

console.log('--- url:', page.url())
console.log('--- visible errors:', await page.evaluate(() => [...document.querySelectorAll('.text-destructive')].map((e) => e.innerText.trim()).filter(Boolean)))
console.log('--- phone field value:', await page.evaluate(() => document.querySelector('input[inputmode="numeric"]')?.value))
await page.screenshot({ path: '/tmp/debug-register.png' })
await browser.close()
