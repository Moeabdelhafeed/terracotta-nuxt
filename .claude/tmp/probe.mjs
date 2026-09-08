import puppeteer from 'puppeteer-core'

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
const BASE = 'http://localhost:3000'
const PHONE = `5${String(Math.floor(Math.random() * 90000000) + 10000000)}`

const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox'] })
const page = await browser.newPage()
await page.setViewport({ width: 1280, height: 1400 })
await page.setCookie(
  { name: 'i18n_locale', value: 'en', domain: 'localhost', path: '/' },
  { name: 'lang', value: encodeURIComponent(JSON.stringify({ code: 'en', direction: 'ltr' })), domain: 'localhost', path: '/' },
)

// register
await page.goto(`${BASE}/register`, { waitUntil: 'domcontentloaded' })
await page.waitForSelector('#name', { timeout: 15000 })
await page.type('#name', 'Probe User')
await (await page.$('input[inputmode="numeric"]')).type(PHONE)
await new Promise((r) => setTimeout(r, 1200))
await page.type('#password', 'Str0ngP@ssw0rd!')
await page.type('#confirm', 'Str0ngP@ssw0rd!')
await (await page.$('[role=checkbox]')).click()
// The identifier probe is debounced; submitting while it runs hits a disabled button.
await page.waitForFunction(() => {
  const b = document.querySelector('button[type=submit]')
  return b && !b.disabled
}, { timeout: 20000 })
page.on('response', async (r) => {
  if (/\/api\/(register|login|check-identifier)/.test(r.url())) {
    let b=''; try { b = JSON.stringify(await r.json()).slice(0,200) } catch {}
    console.log('  RES', r.status(), r.url().replace(BASE,''), b)
  }
})
await page.click('button[type=submit]')
await new Promise((r) => setTimeout(r, 8000))
console.log('after submit url:', page.url())
console.log('errors:', await page.evaluate(() => [...document.querySelectorAll('.text-destructive')].map(e=>e.innerText.trim()).filter(Boolean)))
if (page.url().includes('/register')) { await browser.close(); process.exit(1) }
console.log('registered +966' + PHONE)

const dump = async (path) => {
  await page.goto(`${BASE}${path}`, { waitUntil: 'domcontentloaded' })
  await new Promise((r) => setTimeout(r, 2500))
  const info = await page.evaluate(() => ({
    url: location.pathname,
    dataTests: [...new Set([...document.querySelectorAll('[data-test]')].map((e) => e.getAttribute('data-test')))],
    buttons: [...document.querySelectorAll('button')].map((b) => ({ t: (b.innerText || '').trim().slice(0, 40), disabled: b.disabled })).filter((b) => b.t),
    headings: [...document.querySelectorAll('h1,h2,h3')].map((h) => h.innerText.trim().slice(0, 50)),
  }))
  console.log(`\n=== ${path} → ${info.url}`)
  console.log('  data-test:', info.dataTests.join(', ') || '(none)')
  console.log('  headings :', info.headings.join(' | '))
  console.log('  buttons  :', info.buttons.map((b) => `${b.t}${b.disabled ? '[disabled]' : ''}`).join(' · ').slice(0, 700))
}

await dump('/workshops/1/book')
await dump('/cart')
await dump('/checkout')
await dump('/gifts/new')

await browser.close()
