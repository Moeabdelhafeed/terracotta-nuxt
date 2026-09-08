import puppeteer from 'puppeteer-core'
const settle = (ms=1200)=>new Promise(r=>setTimeout(r,ms))
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: 'new', args: ['--no-sandbox'] })
let fail = 0
for (const locale of ['en','ar']) {
  const page = await browser.newPage()
  await page.setViewport({ width: 1280, height: 1400 })
  await page.setCookie(
    { name: 'i18n_locale', value: locale, domain: 'localhost', path: '/' },
    { name: 'lang', value: encodeURIComponent(JSON.stringify({ code: locale, direction: locale === 'ar' ? 'rtl' : 'ltr' })), domain: 'localhost', path: '/' },
  )
  // Seed a non-empty guest basket, then reload every page that renders a badge from it.
  await page.goto('http://localhost:3000/shop', { waitUntil: 'domcontentloaded' })
  await page.evaluate(() => {
    localStorage.setItem('terracotta:cart', JSON.stringify([{ id: 1, quantity: 2 }, { id: 2, quantity: 1 }]))
    localStorage.setItem('terracotta:favorites', JSON.stringify([1, 3]))
  })
  for (const path of ['/', '/shop', '/shop/1', '/cart', '/favorites']) {
    const warnings = []
    page.on('console', (m) => { if (/Hydration|mismatch/i.test(m.text())) warnings.push(m.text().replace(/\s+/g,' ').slice(0,220)) })
    await page.goto(`http://localhost:3000${path}`, { waitUntil: 'domcontentloaded' })
    await settle(4000)
    const ok = warnings.length === 0
    if (!ok) fail++
    console.log(`  ${ok ? 'ok  ' : 'FAIL'} ${locale} ${path} — ${warnings.length} hydration warning(s)`)
    ;[...new Set(warnings)].slice(0,2).forEach(w => console.log(`        ${w}`))
    page.removeAllListeners('console')
  }
  await page.close()
}
console.log(fail ? `\n${fail} page(s) mismatched` : '\nno hydration mismatches with a non-empty guest basket')
await browser.close()
process.exit(fail ? 1 : 0)
