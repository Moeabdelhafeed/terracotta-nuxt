import puppeteer from 'puppeteer-core'

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
const BASE = 'http://localhost:3000'
const PHONE = `5${String(Math.floor(Math.random() * 90000000) + 10000000)}`

const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox'] })
const page = await browser.newPage()
await page.setViewport({ width: 1280, height: 1400 })
page.on('response', async (r) => {
  if (/\/api\/(register|login|check-identifier)/.test(r.url())) console.log('  RES', r.status(), r.url().replace(BASE, ''))
})
await page.setCookie({ name: 'i18n_locale', value: 'en', domain: 'localhost', path: '/' })

await page.goto(`${BASE}/register`, { waitUntil: 'domcontentloaded' })
await page.waitForSelector('#name', { timeout: 15000 })
await page.type('#name', 'Probe User')
await (await page.$('input[inputmode="numeric"]')).type(PHONE)
await new Promise((r) => setTimeout(r, 1500))
await page.type('#password', 'Str0ngP@ssw0rd!')
await page.type('#confirm', 'Str0ngP@ssw0rd!')

const state = async (label) => {
  const s = await page.evaluate(() => {
    const btn = document.querySelector('button[type=submit]')
    const rect = btn?.getBoundingClientRect()
    const topEl = rect ? document.elementFromPoint(rect.x + rect.width / 2, rect.y + rect.height / 2) : null
    return {
      checkbox: document.querySelector('[role=checkbox]')?.getAttribute('data-state'),
      submitDisabled: btn?.disabled,
      submitInView: rect ? `${Math.round(rect.y)}px, h=${Math.round(rect.height)}` : 'none',
      topElementAtSubmit: topEl ? `${topEl.tagName}.${String(topEl.className).slice(0, 60)}` : 'none',
      dialogOpen: !!document.querySelector('[role=dialog]'),
      overlays: [...document.querySelectorAll('.fixed.inset-0')].length,
    }
  })
  console.log(label, JSON.stringify(s))
  return s
}

await state('before checkbox:')
await (await page.$('[role=checkbox]')).click()
await new Promise((r) => setTimeout(r, 600))
await state('after checkbox :')

console.log('--- clicking submit via puppeteer')
await page.click('button[type=submit]')
await new Promise((r) => setTimeout(r, 4000))
console.log('url now:', page.url())

if (page.url().includes('/register')) {
  console.log('--- retrying with a DOM click (bypasses any overlay)')
  await page.evaluate(() => document.querySelector('button[type=submit]')?.click())
  await new Promise((r) => setTimeout(r, 5000))
  console.log('url now:', page.url())
  console.log('errors:', await page.evaluate(() => [...document.querySelectorAll('.text-destructive')].map((e) => e.innerText.trim()).filter(Boolean)))
}
await page.screenshot({ path: '/tmp/debug-submit.png' })
await browser.close()
