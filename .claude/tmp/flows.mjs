/**
 * The money paths, end to end, against the real backend:
 *   register → book a workshop (quote, discount, create, pay, cancel)
 *            → shop (cart, address, quote, checkout, pay, order timeline)
 *            → gift (buy, pay, share link, redeem as a second account)
 *
 * Run: node .claude/tmp/flows.mjs [--port 3000] [--locale en]
 */
import puppeteer from 'puppeteer-core'

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
const arg = (n, d) => { const i = process.argv.indexOf(`--${n}`); return i > -1 ? process.argv[i + 1] : d }
const BASE = `http://localhost:${arg('port', '3000')}`
const LOCALE = arg('locale', 'en')
const PASSWORD = 'Str0ngP@ssw0rd!'
const newPhone = () => `5${String(Math.floor(Math.random() * 90000000) + 10000000)}`

const results = []
const step = async (name, fn) => {
  try {
    const detail = await fn()
    results.push({ name, ok: true })
    console.log(`PASS  ${name}${detail ? ` — ${detail}` : ''}`)
    return detail
  } catch (err) {
    results.push({ name, ok: false })
    console.log(`FAIL  ${name} — ${String(err?.message ?? err).split('\n')[0].slice(0, 200)}`)
    return null
  }
}

const settle = (ms = 1200) => new Promise((r) => setTimeout(r, ms))

/** SSR paints the markup before Vue owns it; typing too early is silently discarded. */
const hydrated = async (page) => {
  await page.waitForFunction(() => window.useNuxtApp?.()?.isHydrating === false || !!document.querySelector('#__nuxt')?.firstElementChild, { timeout: 20000 }).catch(() => {})
  await settle(1800)
}

const fill = async (page, selector, value) => {
  await page.waitForSelector(selector, { timeout: 20000 })
  for (let attempt = 0; attempt < 3; attempt++) {
    await page.click(selector, { clickCount: 3 }).catch(() => {})
    await page.type(selector, value, { delay: 15 })
    const got = await page.$eval(selector, (el) => el.value)
    if (got === value) return
    await settle(700)
  }
  throw new Error(`could not fill ${selector} (kept losing the value)`)
}

const clickText = async (page, ...needles) => {
  const last = needles[needles.length - 1] === '@last' ? needles.pop() : null
  const hit = await page.evaluate(({ needles, last }) => {
    const nodes = [...document.querySelectorAll('button, a, [role=button]')]
      .filter((n) => !n.disabled && needles.some((needle) => (n.innerText || '').trim().includes(needle)))
    const el = last ? nodes[nodes.length - 1] : nodes[0]
    if (!el) return false
    el.click()
    return true
  }, { needles, last })
  if (hit) await settle(1800)
  return hit
}

const text = (page) => page.evaluate(() => document.body.innerText)
const go = async (page, path) => {
  try { await page.goto(`${BASE}${path}`, { waitUntil: 'domcontentloaded', timeout: 45000 }) }
  catch (e) { if (!/ERR_ABORTED/.test(String(e.message))) throw e; await settle(800); await page.goto(`${BASE}${path}`, { waitUntil: 'domcontentloaded', timeout: 45000 }) }
  await hydrated(page)
  return page.url().replace(BASE, '') || '/'
}

const newPage = async (browser) => {
  const page = await browser.newPage()
  await page.setViewport({ width: 1280, height: 1400 })
  await page.setCookie(
    { name: 'i18n_locale', value: LOCALE, domain: 'localhost', path: '/' },
    { name: 'lang', value: encodeURIComponent(JSON.stringify({ code: LOCALE, direction: LOCALE === 'ar' ? 'rtl' : 'ltr' })), domain: 'localhost', path: '/' },
  )
  return page
}

const register = async (page) => {
  const phone = newPhone()
  await go(page, '/register')
  await fill(page, '#name', 'Flow Tester')
  await fill(page, 'input[inputmode="numeric"]', phone)
  await settle(1500)
  await fill(page, '#password', PASSWORD)
  await fill(page, '#confirm', PASSWORD)
  await page.click('[role=checkbox]')
  await settle(500)
  await page.waitForFunction(() => { const b = document.querySelector('button[type=submit]'); return b && !b.disabled }, { timeout: 20000 })
  await page.click('button[type=submit]')
  await page.waitForFunction(() => !location.pathname.startsWith('/register'), { timeout: 30000 })
  await settle(1500)
  return `+966${phone}`
}

const run = async () => {
  const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox', '--window-size=1280,1400'] })
  const page = await newPage(browser)
  const apiCalls = []
  page.on('request', (r) => { if (r.url().includes('/api/') && r.method() !== 'GET') apiCalls.push(`${r.method()} ${r.url().replace(BASE, '')}`) })
  page.on('response', async (r) => {
    if (!r.url().includes('/api/') || r.request().method() === 'GET') return
    if (r.status() < 400) return
    let body = ''
    try { body = JSON.stringify(await r.json()).slice(0, 400) } catch { try { body = (await r.text()).slice(0, 400) } catch {} }
    console.log(`   ↳ ${r.status()} ${r.url().replace(BASE, '')} ${body}`)
  })

  const who = await step('register', () => register(page))

  // ---------------- workshop booking ----------------
  await step('booking: pick a date and slot', async () => {
    await go(page, '/workshops/1/book')
    await page.waitForSelector('[data-test="date-strip"] button:not([disabled])', { timeout: 25000 })
    // Not today: a booking made inside the workshop's cancellation window (3h here) has no
    // cancel right at all, so pick a day far enough out to exercise it.
    await page.evaluate(() => {
      const open = [...document.querySelectorAll('[data-test="date-strip"] button:not([disabled])')]
      ;(open[2] ?? open[0])?.click()
    })
    await settle(2500)
    const slots = await page.$$('[data-test="slot-list"] button:not([disabled]), [data-test="slot"]:not([disabled])')
    if (!slots.length) {
      const t = await text(page)
      throw new Error(`no selectable slot. page says: ${t.slice(0, 200).replace(/\n+/g, ' / ')}`)
    }
    await slots[0].click()
    await settle(1500)
    return `${slots.length} slot(s) offered`
  })

  await step('booking: reach the payment step with a quote', async () => {
    const moved = await clickText(page, 'Continue', 'Next', 'التالي', 'الدفع', 'Payment')
    if (!moved) throw new Error('no continue/pay button')
    await settle(2500)
    const t = await text(page)
    if (!/Amount due|المبلغ المستحق|Total|الإجمالي/.test(t)) throw new Error(`no quote rendered: ${t.slice(0, 200).replace(/\n+/g, ' / ')}`)
    return 'quote shown'
  })

  await step('booking: apply WELCOME10 and see the total move', async () => {
    const before = await text(page)
    await fill(page, '#discount_code', 'WELCOME10')
    await clickText(page, 'Apply', 'تطبيق')
    await settle(2500)
    const after = await text(page)
    if (before === after) throw new Error('nothing changed after applying the code')
    if (/not valid|غير صالح|expired/i.test(after)) throw new Error('code refused')
    return 'discount applied'
  })

  const bookingPath = await step('booking: create and settle', async () => {
    // The CTA is disabled while a re-quote is in flight (the discount just changed it).
    await page.waitForFunction(() => [...document.querySelectorAll('button')]
      .some((b) => !b.disabled && /Confirm the booking|تاكيد الحجز/i.test(b.innerText)), { timeout: 25000 })
    const created = await clickText(page, 'Confirm the booking', 'تاكيد الحجز', '@last')
    if (!created) {
      const btns = await page.evaluate(() => [...document.querySelectorAll('button')].map((b) => `${(b.innerText||'').trim().slice(0,40)}${b.disabled?'[disabled]':''}`).filter(Boolean))
      throw new Error(`no confirm button. buttons: ${btns.join(' · ')}`)
    }
    await settle(4000)
    // Either the wallet/discount settled it on creation, or a hold is waiting to be paid.
    const held = await page.evaluate(() => !!([...document.querySelectorAll('button')].find((b) => /Pay now|ادفع الآن/i.test(b.innerText))))
    if (held) {
      await clickText(page, 'Pay now', 'ادفع الآن')
      await settle(4000)
    }
    const after = await text(page)
    if (!/All set|Track|تتبع|booked|confirmed|مؤكد/i.test(after)) throw new Error(`no confirmation after ${held ? 'paying the hold' : 'creating'}: ${after.slice(0, 200).replace(/\n+/g, ' / ')}`)
    return held ? 'held then paid' : 'settled on creation'
  })

  await step('booking: appears in my bookings', async () => {
    await go(page, '/bookings')
    const cards = await page.evaluate(() => document.querySelectorAll('a[href^="/bookings/"]').length)
    if (!cards) throw new Error('no booking cards')
    return `${cards} booking(s)`
  })

  await step('booking: detail opens and offers cancel', async () => {
    const href = await page.evaluate(() => document.querySelector('a[href^="/bookings/"]')?.getAttribute('href'))
    await go(page, href)
    const t = await text(page)
    if (!/Cancel|الغاء|إلغاء/.test(t)) throw new Error(`no cancel action: ${t.replace(/\n+/g, ' / ').slice(0, 200)}`)
    return href
  })

  // ---------------- shop ----------------
  await step('shop: add a product to the cart', async () => {
    await go(page, '/shop/1')
    if (!await clickText(page, 'Add', 'اضافة', 'إضافة')) throw new Error('no add button')
    await go(page, '/cart')
    const lines = await page.evaluate(() => document.querySelectorAll('[data-line]').length)
    if (!lines) throw new Error('cart empty after add')
    return `${lines} line(s)`
  })

  await step('shop: save a Riyadh address from checkout', async () => {
    await go(page, '/checkout')
    if (!await clickText(page, 'Add a new address', 'إضافة عنوان جديد')) throw new Error('no add-address button')
    await settle(1200)
    await fill(page, '#building_number', '8228')
    await fill(page, '#additional_number', '2933')
    await fill(page, '#street', 'Prince Turki')
    await fill(page, '#district', 'Al Muhammadiyah')
    await fill(page, '#postal_code', '12362')
    const phoneInputs = await page.$$('input[inputmode="numeric"]')
    await phoneInputs[phoneInputs.length - 1].type('500000000', { delay: 15 })
    await page.evaluate(() => {
      const lat = document.querySelector('input[aria-label="Latitude"], input[aria-label="خط العرض"]')
      const lng = document.querySelector('input[aria-label="Longitude"], input[aria-label="خط الطول"]')
      const set = (el, v) => { if (!el) return; const s = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set; s.call(el, v); el.dispatchEvent(new Event('input', { bubbles: true })) }
      set(lat, '24.7136'); set(lng, '46.6753')
    })
    await settle(600)
    if (!await clickText(page, 'Save address', 'حفظ العنوان')) throw new Error('no save button')
    await settle(3000)
    const t = await text(page)
    if (/must be inside Saudi|4 digits|5 digits|required/i.test(t)) throw new Error(`address rejected: ${t.match(/[^\n]*(must be inside|digits|required)[^\n]*/i)?.[0]}`)
    return 'address saved'
  })

  const orderPath = await step('shop: place the order and settle it', async () => {
    await settle(2000)
    const t0 = await text(page)
    if (!/Amount due|المبلغ المستحق/.test(t0)) throw new Error('no quote on checkout')
    if (!await clickText(page, 'Place order', 'Confirm payment', 'تاكيد الدفع', 'تأكيد الدفع', '@last')) throw new Error('no place-order button')
    await settle(4500)
    const held = await page.evaluate(() => !!([...document.querySelectorAll('button')].find((b) => /Pay now|ادفع الآن/i.test(b.innerText))))
    if (held) { await clickText(page, 'Pay now', 'ادفع الآن'); await settle(4000) }
    const url = page.url().replace(BASE, '')
    const after = await text(page)
    if (!/order|طلب/i.test(after)) throw new Error(`no order confirmation: ${after.slice(0, 160)}`)
    return url
  })

  await step('shop: the order shows a timeline', async () => {
    await go(page, '/orders')
    const href = await page.evaluate(() => document.querySelector('a[href^="/orders/"]')?.getAttribute('href'))
    if (!href) throw new Error('no order in the list')
    await go(page, href)
    const t = await text(page)
    if (!/Paid|Pending|Preparing|Placed|Awaiting|Delivered|قيد|مدفوع|بانتظار|تم/i.test(t)) {
      throw new Error(`no status on the order: ${t.replace(/\n+/g, ' / ').slice(0, 220)}`)
    }
    return href
  })

  // ---------------- gift ----------------
  const shareUrl = await step('gift: buy one and get its share link', async () => {
    await go(page, '/gifts/new')
    await fill(page, '#recipient_name', 'Sara')
    if (!await clickText(page, 'Pay', 'الدفع', 'Buy', 'شراء')) throw new Error('no pay button')
    await settle(3500)
    const t = await text(page)
    if (/Pay now|ادفع الآن/.test(t)) { await clickText(page, 'Pay now', 'ادفع الآن'); await settle(3500) }
    const link = await page.evaluate(() => {
      const el = [...document.querySelectorAll('a[href*="/gift/"], input')].find((n) => (n.href || n.value || '').includes('/gift/'))
      return el ? (el.href || el.value) : (document.body.innerText.match(/https?:\/\/\S+\/gift\/\S+/)?.[0] ?? null)
    })
    if (!link) throw new Error(`no share link: ${(await text(page)).slice(0, 200).replace(/\n+/g, ' / ')}`)
    return link
  })

  if (shareUrl) {
    await step('gift: a second account redeems it', async () => {
      const context = await browser.createBrowserContext()
      const page2 = await context.newPage()
      await page2.setViewport({ width: 1280, height: 1400 })
      await page2.setCookie({ name: 'i18n_locale', value: LOCALE, domain: 'localhost', path: '/' })
      const path = shareUrl.replace(/^https?:\/\/[^/]+/, '')
      await page2.goto(`${BASE}${path}`, { waitUntil: 'domcontentloaded' })
      await hydrated(page2)
      const preview = await page2.evaluate(() => document.body.innerText)
      if (/total_price|amount_due|wallet_applied/i.test(preview)) throw new Error('public preview leaked buyer amounts')

      // Register the recipient, then come back to the link.
      const phone = newPhone()
      await page2.goto(`${BASE}/register`, { waitUntil: 'domcontentloaded' })
      await hydrated(page2)
      await fill(page2, '#name', 'Gift Recipient')
      await fill(page2, 'input[inputmode="numeric"]', phone)
      await settle(1500)
      await fill(page2, '#password', PASSWORD)
      await fill(page2, '#confirm', PASSWORD)
      await page2.click('[role=checkbox]')
      await settle(500)
      await page2.click('button[type=submit]')
      await page2.waitForFunction(() => !location.pathname.startsWith('/register'), { timeout: 30000 })

      await page2.goto(`${BASE}${path}`, { waitUntil: 'domcontentloaded' })
      await hydrated(page2)
      const claimed = await page2.evaluate(() => {
        const el = [...document.querySelectorAll('button, a')].find((n) => /Claim|Redeem|استلام/i.test(n.innerText || ''))
        if (!el) return false
        el.click()
        return true
      })
      if (!claimed) throw new Error(`no claim control: ${(await page2.evaluate(() => document.body.innerText)).slice(0, 200).replace(/\n+/g, ' / ')}`)
      await settle(3500)
      const after = await page2.evaluate(() => document.body.innerText)
      await context.close()
      if (!/wallet|رصيد|balance/i.test(after)) throw new Error(`no wallet confirmation: ${after.slice(0, 200).replace(/\n+/g, ' / ')}`)
      return 'redeemed, wallet credited'
    })
  }

  await page.screenshot({ path: `/tmp/flows-${LOCALE}.png` }).catch(() => {})
  await browser.close()

  const failed = results.filter((r) => !r.ok)
  console.log(`\n=== ${LOCALE}: ${results.length - failed.length}/${results.length} passed   (user ${who})`)
  console.log('mutating API calls made:')
  ;[...new Set(apiCalls)].forEach((c) => console.log(`  ${c}`))
  process.exit(failed.length ? 1 : 0)
}

run().catch((e) => { console.error('runner crashed:', e); process.exit(1) })
