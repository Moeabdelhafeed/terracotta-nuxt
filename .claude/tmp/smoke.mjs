/**
 * Consolidated end-to-end smoke across every customer domain, in one browser session.
 *
 *   node .claude/tmp/smoke.mjs [--locale ar|en] [--port 3000]
 *
 * Drives the real UI against the real local Laravel. Registers its own Saudi user, so it
 * never depends on seeded fixtures (the seeded demo users are Jordanian and the config
 * restricts the picker to SA). Each step is isolated — one failure never ends the run.
 */
import puppeteer from 'puppeteer-core'

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
const arg = (name, fallback) => {
  const i = process.argv.indexOf(`--${name}`)
  return i > -1 ? process.argv[i + 1] : fallback
}
const LOCALE = arg('locale', 'ar')
const PORT = arg('port', '3000')
const BASE = `http://localhost:${PORT}`
const PHONE_LOCAL = `5${String(Math.floor(Math.random() * 90000000) + 10000000)}`
const PASSWORD = 'Str0ngP@ssw0rd!'

const results = []
const consoleErrors = []

const step = async (name, fn) => {
  try {
    const detail = await fn()
    results.push({ name, ok: true, detail })
    console.log(`PASS  ${name}${detail ? ` — ${detail}` : ''}`)
    return detail
  } catch (err) {
    const detail = String(err?.message ?? err).split('\n')[0].slice(0, 160)
    results.push({ name, ok: false, detail })
    console.log(`FAIL  ${name} — ${detail}`)
    return null
  }
}

const run = async () => {
  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: 'new',
    args: ['--no-sandbox', '--window-size=1280,1200'],
  })
  const page = await browser.newPage()
  await page.setViewport({ width: 1280, height: 1200 })

  page.on('console', (m) => {
    const t = m.text()
    if (/Failed to resolve component|Hydration|\[Vue warn\]|is not a function|undefined is not/.test(t)) {
      consoleErrors.push(t.slice(0, 200))
    }
  })
  page.on('pageerror', (e) => consoleErrors.push(`pageerror: ${String(e.message).slice(0, 200)}`))

  // Locale is a cookie the app owns — set it before the first paint, not via evaluate
  // (which races hydration's own navigation).
  await page.setCookie(
    { name: 'i18n_locale', value: LOCALE, domain: 'localhost', path: '/' },
    { name: 'lang', value: encodeURIComponent(JSON.stringify({ code: LOCALE, direction: LOCALE === 'ar' ? 'rtl' : 'ltr' })), domain: 'localhost', path: '/' },
  )

  const go = async (path) => {
    try {
      await page.goto(`${BASE}${path}`, { waitUntil: 'domcontentloaded', timeout: 45000 })
    } catch (err) {
      // A client-side redirect fired while the document was still loading; the second
      // attempt lands on wherever the app decided to send us.
      if (!/ERR_ABORTED/.test(String(err?.message))) throw err
      await new Promise((r) => setTimeout(r, 800))
      await page.goto(`${BASE}${path}`, { waitUntil: 'domcontentloaded', timeout: 45000 })
    }
    await new Promise((r) => setTimeout(r, 1200))
    return page.url().replace(BASE, '') || '/'
  }
  const body = () => page.evaluate(() => document.body.innerText).catch(() => '')
  const clickText = async (needle) => {
    const clicked = await page.evaluate((needle) => {
      const nodes = [...document.querySelectorAll('button, a, label, [role=button]')]
      const el = nodes.find((n) => (n.innerText || '').includes(needle) && !n.disabled)
      if (!el) return false
      el.click()
      return true
    }, needle)
    if (clicked) await new Promise((r) => setTimeout(r, 1800))
    return clicked
  }
  const mustReach = async (path) => {
    const at = await go(path)
    if (at.startsWith('/login')) throw new Error(`bounced to /login from ${path}`)
    const text = await body()
    if (text.length < 60) throw new Error(`page looks empty (${text.length} chars)`)
    return at
  }

  // ---------- public pages ----------
  await step('home renders', async () => { await go('/'); const t = await body(); if (t.length < 200) throw new Error('empty'); return `${t.length} chars` })
  await step('workshops list', async () => { await go('/workshops'); const t = await body(); if (!/ورشة|orkshop/.test(t)) throw new Error('no workshops'); return 'listed' })
  await step('workshop detail', () => mustReach('/workshops/1'))
  await step('shop list', () => mustReach('/shop'))
  await step('gallery list', () => mustReach('/gallery'))
  await step('CMS page /terms', () => mustReach('/terms'))

  // ---------- register ----------
  await step('register a fresh Saudi user', async () => {
    await go('/register')
    await page.waitForSelector('#name', { timeout: 15000 })
    await page.type('#name', 'Smoke Tester')
    const phone = await page.$('input[inputmode="numeric"]')
    if (!phone) throw new Error('no phone input')
    await phone.type(PHONE_LOCAL)
    await new Promise((r) => setTimeout(r, 1000))
    await page.type('#password', PASSWORD)
    await page.type('#confirm', PASSWORD)
    const box = await page.$('[role=checkbox]') ?? await page.$('#policy')
    if (box) await box.click()
    await new Promise((r) => setTimeout(r, 400))
    await page.click('button[type=submit]')
    // register → auto-login → redirect takes a few seconds against the real API.
    await page.waitForFunction(() => !location.pathname.startsWith('/register'), { timeout: 25000 })
      .catch(async () => {
        const errs = await page.evaluate(() => [...document.querySelectorAll('.text-destructive')].map((e) => e.innerText.trim()).filter(Boolean))
        throw new Error(`still on register${errs.length ? `: ${errs.join(' | ')}` : ''}`)
      })
    await new Promise((r) => setTimeout(r, 1500))
    return `+966${PHONE_LOCAL} → ${page.url().replace(BASE, '') || '/'}`
  })

  // ---------- account ----------
  await step('profile hub', () => mustReach('/profile'))
  await step('notifications', () => mustReach('/notifications'))
  await step('wallet', () => mustReach('/wallet'))
  await step('addresses', () => mustReach('/addresses'))
  await step('complaints (public)', () => mustReach('/complaints'))

  // ---------- shop ----------
  await step('product detail + add to cart', async () => {
    await go('/shop')
    const href = await page.evaluate(() => document.querySelector('a[href^="/shop/"]')?.getAttribute('href') ?? null)
    if (!href) throw new Error('no product link on /shop')
    await go(href)
    const added = await clickText(LOCALE === 'ar' ? 'اضافة' : 'Add')
    if (!added) throw new Error(`no add-to-cart button on ${href}`)
    return `${href} added`
  })
  await step('cart shows the line', async () => {
    await mustReach('/cart')
    const lines = await page.evaluate(() => document.querySelectorAll('[data-line]').length)
    if (!lines) throw new Error('cart is empty after add')
    return `${lines} line(s)`
  })
  await step('checkout page', () => mustReach('/checkout'))
  await step('orders', () => mustReach('/orders'))
  await step('favorites', () => mustReach('/favorites'))

  // ---------- workshops booking ----------
  await step('booking step 1 (dates + slots)', async () => {
    await mustReach('/workshops/1/book')
    await page.waitForSelector('[data-test="date-strip"]', { timeout: 20000 })
    const days = await page.evaluate(() => document.querySelectorAll('[data-test="date-strip"] button').length)
    if (!days) throw new Error('no dates rendered')
    const err = await page.evaluate(() => document.querySelector('[data-test="availability-error"]')?.innerText ?? '')
    if (err) throw new Error(`availability error: ${err}`)
    return `${days} days`
  })
  await step('my bookings', () => mustReach('/bookings'))

  // ---------- gifts ----------
  await step('gifts list', () => mustReach('/gifts'))
  await step('gift purchase page', async () => {
    const at = await mustReach('/gifts/new')
    const t = await body()
    if (!/\d/.test(t)) throw new Error('no package amount rendered')
    return at
  })

  await page.screenshot({ path: `/tmp/smoke-${LOCALE}.png`, fullPage: false }).catch(() => {})
  await browser.close()

  const failed = results.filter((r) => !r.ok)
  console.log(`\n=== ${LOCALE}: ${results.length - failed.length}/${results.length} passed`)
  if (consoleErrors.length) {
    console.log(`\nconsole/page errors (${consoleErrors.length}):`)
    ;[...new Set(consoleErrors)].slice(0, 12).forEach((e) => console.log(`  - ${e}`))
  }
  process.exit(failed.length ? 1 : 0)
}

run().catch((err) => { console.error('runner crashed:', err); process.exit(1) })
