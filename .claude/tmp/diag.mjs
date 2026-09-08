import puppeteer from 'puppeteer-core'

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
const BASE = 'http://localhost:3000'
const PASSWORD = 'Str0ngP@ssw0rd!'
const settle = (ms = 1500) => new Promise((r) => setTimeout(r, ms))

const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox'] })
const page = await browser.newPage()
await page.setViewport({ width: 1280, height: 1400 })
await page.setCookie(
  { name: 'i18n_locale', value: 'en', domain: 'localhost', path: '/' },
  { name: 'lang', value: encodeURIComponent(JSON.stringify({ code: 'en', direction: 'ltr' })), domain: 'localhost', path: '/' },
)

page.on('response', async (r) => {
  if (!r.url().includes('/api/') || r.request().method() === 'GET') return
  let body = ''
  try { body = JSON.stringify(await r.json()).slice(0, 500) } catch { try { body = (await r.text()).slice(0, 500) } catch {} }
  console.log(`  ${r.status()} ${r.request().method()} ${r.url().replace(BASE, '')} ${body}`)
})

const fill = async (page, sel, val) => {
  await page.waitForSelector(sel, { timeout: 20000 })
  for (let i = 0; i < 3; i++) {
    await page.click(sel, { clickCount: 3 }).catch(() => {})
    await page.type(sel, val, { delay: 15 })
    if (await page.$eval(sel, (e) => e.value) === val) return
    await settle(600)
  }
}
const buttons = () => page.evaluate(() => [...document.querySelectorAll('button')].map((b) => `"${(b.innerText || '').trim().slice(0, 45)}"${b.disabled ? '[X]' : ''}`).filter((s) => s !== '""[X]' && s !== '""'))

// register
const phone = `5${String(Math.floor(Math.random() * 90000000) + 10000000)}`
await page.goto(`${BASE}/register`, { waitUntil: 'domcontentloaded' }); await settle(2500)
await fill(page, '#name', 'Diag User')
await fill(page, 'input[inputmode="numeric"]', phone)
await settle(1500)
await fill(page, '#password', PASSWORD)
await fill(page, '#confirm', PASSWORD)
await page.click('[role=checkbox]'); await settle(600)
await page.click('button[type=submit]')
await page.waitForFunction(() => !location.pathname.startsWith('/register'), { timeout: 30000 })
console.log(`\n=== registered +966${phone}\n`)

// booking to the pay step
await page.goto(`${BASE}/workshops/1/book`, { waitUntil: 'domcontentloaded' }); await settle(3000)
await page.waitForSelector('[data-test="date-strip"] button:not([disabled])', { timeout: 25000 })
await page.evaluate(() => document.querySelector('[data-test="date-strip"] button:not([disabled])').click()); await settle(2500)
const slot = await page.$('[data-test="slot-list"] button:not([disabled])')
if (slot) { await slot.click(); await settle(1500) }
console.log('STEP 1 primary buttons:', (await buttons()).filter((b)=>!/\d/.test(b)).join(' · '))
await page.evaluate(() => { const b = [...document.querySelectorAll('button')].find((n) => /Continue|Next/i.test(n.innerText)); b?.click() })
await settle(3000)
console.log('\nSTEP 2 (payment) buttons:', (await buttons()).filter((b)=>!/^"(سبتمبر|أكتوبر|September|October)/.test(b)).join(' · '))
console.log('STEP 2 text:', (await page.evaluate(() => document.body.innerText)).replace(/\n+/g, ' / ').slice(0, 600))

// try to create
console.log('\n--- clicking the primary CTA on the payment step')
await page.evaluate(() => {
  const b = [...document.querySelectorAll('button')].filter((n) => !n.disabled && /confirm|book|pay/i.test(n.innerText))
  b[b.length - 1]?.click()
})
await settle(5000)
console.log('after CTA url:', page.url())
console.log('after CTA buttons:', (await buttons()).filter((b)=>!/^"(سبتمبر|أكتوبر|September|October)/.test(b)).join(' · '))
const errs = await page.evaluate(() => [...document.querySelectorAll('.text-destructive')].map((e)=>e.innerText.trim()).filter(Boolean))
console.log('after CTA errors:', JSON.stringify(errs))
const post = await page.evaluate(() => {
  const txt = document.body.innerText
  return {
    hasReserved: /Reserved for you|محجوز لك/.test(txt),
    hasPayNow: !!([...document.querySelectorAll('button')].find((b) => /Pay now|ادفع الآن/i.test(b.innerText))),
    hasCountdown: /\d{2}:\d{2}/.test(txt),
    hasDone: /All set|Track|تتبع|booked|confirmed/i.test(txt),
    amountDueLine: (txt.match(/Amount due[^\n]*\n?[^\n]*/i) || [''])[0].replace(/\n/g,' '),
    tail: txt.replace(/\n+/g,' / ').slice(-400),
  }
})
console.log('post-create state:', JSON.stringify(post, null, 2))
await page.screenshot({ path: '/tmp/diag-booking.png', fullPage: true })

await browser.close()
