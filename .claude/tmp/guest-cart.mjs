import puppeteer from 'puppeteer-core'

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
const BASE = 'http://localhost:3000'
const PASSWORD = 'Str0ngP@ssw0rd!'
const LOCALE = process.argv[2] || 'en'
const settle = (ms = 1200) => new Promise((r) => setTimeout(r, ms))

let pass = 0, fail = 0
const check = (name, ok, detail = '') => {
  console.log(`${ok ? '  ok  ' : '  FAIL'} ${name}${detail ? ` — ${detail}` : ''}`)
  ok ? pass++ : fail++
}

const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox'] })
const page = await browser.newPage()
await page.setViewport({ width: 1280, height: 1400 })
await page.setCookie(
  { name: 'i18n_locale', value: LOCALE, domain: 'localhost', path: '/' },
  { name: 'lang', value: encodeURIComponent(JSON.stringify({ code: LOCALE, direction: LOCALE === 'ar' ? 'rtl' : 'ltr' })), domain: 'localhost', path: '/' },
)
const apiCalls = []
page.on('response', (r) => { if (/\/api\//.test(r.url())) apiCalls.push(`${r.status()} ${r.request().method()} ${r.url().replace(BASE, '')}`) })

const store = (key) => page.evaluate((k) => JSON.parse(localStorage.getItem(k) || 'null'), key)
const setStore = (key, value) => page.evaluate((k, v) => localStorage.setItem(k, JSON.stringify(v)), key, value)
const text = () => page.evaluate(() => document.body.innerText)
const hydrated = () => page.waitForFunction(() => !!window.__NUXT__ && !document.querySelector('#__nuxt [aria-busy="true"]'), { timeout: 20000 }).catch(() => {})

console.log(`\n=== guest cart, locale ${LOCALE}`)

// 1. a guest adds to the cart without being sent to /login
await page.goto(`${BASE}/shop/1`, { waitUntil: 'domcontentloaded' })
await hydrated(); await settle(1500)
await page.evaluate(() => {
  const b = [...document.querySelectorAll('button')].find((n) => /^(add|adding|اضافة|إضافة)/i.test((n.innerText || '').trim()) && !n.disabled)
  b?.click()
})
await settle(1500)
check('add-to-cart does not bounce a guest to /login', !page.url().includes('/login'), page.url())
check('cart line written to localStorage', JSON.stringify(await store('terracotta:cart')) === JSON.stringify([{ id: 1, quantity: 1 }]), JSON.stringify(await store('terracotta:cart')))

// 2. hearting works for a guest
await page.evaluate(() => {
  const b = [...document.querySelectorAll('button')].find((n) => /favorit|favourite|مفضل/i.test(n.getAttribute('aria-label') || ''))
  b?.click()
})
await settle(1200)
check('favourite written to localStorage', JSON.stringify(await store('terracotta:favorites')) === JSON.stringify([1]), JSON.stringify(await store('terracotta:favorites')))

// 3. the cart page renders the line and the right total
await page.goto(`${BASE}/cart`, { waitUntil: 'domcontentloaded' })
await hydrated(); await settle(2500)
check('guest reaches /cart', page.url().endsWith('/cart'), page.url())
const body = await text()
check('line rendered', (await page.$$('[data-line]')).length === 1)
check('total shows the sale price (35.00)', /35(\.00)?/.test(body))

// 4. a product that no longer exists is pruned
await setStore('terracotta:cart', [{ id: 1, quantity: 1 }, { id: 99999, quantity: 2 }])
await setStore('terracotta:favorites', [1, 99999])
await page.reload({ waitUntil: 'domcontentloaded' })
await hydrated(); await settle(3000)
check('missing product pruned from the cart store', JSON.stringify(await store('terracotta:cart')) === JSON.stringify([{ id: 1, quantity: 1 }]), JSON.stringify(await store('terracotta:cart')))
await page.goto(`${BASE}/favorites`, { waitUntil: 'domcontentloaded' })
await hydrated(); await settle(3000)
check('missing product pruned from the favourites store', JSON.stringify(await store('terracotta:favorites')) === JSON.stringify([1]), JSON.stringify(await store('terracotta:favorites')))

// 5. registering pushes the basket to the server
const fill = async (sel, val) => {
  await page.waitForSelector(sel, { timeout: 20000 })
  for (let i = 0; i < 3; i++) {
    await page.click(sel, { clickCount: 3 }).catch(() => {})
    await page.type(sel, val, { delay: 15 })
    if (await page.$eval(sel, (e) => e.value) === val) return
    await settle(600)
  }
}
const phone = `5${String(Math.floor(Math.random() * 90000000) + 10000000)}`
await page.goto(`${BASE}/register`, { waitUntil: 'domcontentloaded' })
await hydrated(); await settle(2500)
await fill('#name', 'Guest Cart Probe')
await fill('input[inputmode="numeric"]', phone)
await settle(1500)
await fill('#password', PASSWORD)
await fill('#confirm', PASSWORD)
await page.click('[role=checkbox]'); await settle(600)
apiCalls.length = 0
await page.click('button[type=submit]')
await page.waitForFunction(() => !location.pathname.startsWith('/register'), { timeout: 45000 }).catch(() => {})
// The push runs off a watcher after the session lands — poll for it rather than guessing.
for (let i = 0; i < 30 && !apiCalls.some((c) => /POST \/api\/shop\/cart$/.test(c)); i++) await settle(1000)
await settle(2000)
check('registered', !page.url().includes('/register'), page.url())
check('cart pushed on login', apiCalls.some((c) => /POST \/api\/shop\/cart$/.test(c)), apiCalls.filter((c) => /shop\/(cart|favorites)/.test(c)).join(' | ') || 'no push seen')
check('favourite pushed on login', apiCalls.some((c) => /POST \/api\/shop\/favorites\//.test(c)))
check('local cart cleared after the push', JSON.stringify(await store('terracotta:cart')) === JSON.stringify([]), JSON.stringify(await store('terracotta:cart')))

await page.goto(`${BASE}/cart`, { waitUntil: 'domcontentloaded' })
await hydrated(); await settle(3000)
const after = await text()
check('server cart shows the pushed line', (await page.$$('[data-line]')).length === 1, after.replace(/\n+/g, ' / ').slice(0, 160))

console.log(`\n${pass} passed, ${fail} failed`)
await browser.close()
process.exit(fail ? 1 : 0)
