import puppeteer from 'puppeteer-core'

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
const BASE = 'http://localhost:3000'
const paths = process.argv.slice(2).filter((a) => a.startsWith('/'))

const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox'] })

for (const path of paths.length ? paths : ['/', '/shop', '/shop/1', '/workshops', '/workshops/1', '/gallery']) {
  const page = await browser.newPage()
  await page.setViewport({ width: 1280, height: 1200 })
  await page.setCookie(
    { name: 'i18n_locale', value: 'en', domain: 'localhost', path: '/' },
    { name: 'lang', value: encodeURIComponent(JSON.stringify({ code: 'en', direction: 'ltr' })), domain: 'localhost', path: '/' },
  )
  const warnings = []
  page.on('console', (m) => {
    const t = m.text()
    if (/Hydration|mismatch/i.test(t)) warnings.push(t.replace(/\s+/g, ' ').slice(0, 260))
  })
  await page.goto(`${BASE}${path}`, { waitUntil: 'domcontentloaded' })
  await new Promise((r) => setTimeout(r, 3500))
  console.log(`\n${path} → ${warnings.length} hydration warning(s)`)
  ;[...new Set(warnings)].slice(0, 4).forEach((w) => console.log(`   ${w}`))
  await page.close()
}
await browser.close()
