import puppeteer from 'puppeteer-core'
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: 'new', args: ['--no-sandbox'] })
const page = await browser.newPage()
await page.setViewport({ width: 1280, height: 1400 })
await page.setCookie({ name: 'i18n_locale', value: 'en', domain: 'localhost', path: '/' })
const warn = []
page.on('console', (m) => { if (/Hydration|mismatch/i.test(m.text())) warn.push(m.text().replace(/\s+/g,' ').slice(0,200)) })
await page.goto('http://localhost:3000/shop/1', { waitUntil: 'domcontentloaded' })
await new Promise(r => setTimeout(r, 4000))
console.log('BUTTONS:', JSON.stringify(await page.evaluate(() => [...document.querySelectorAll('button')].map(b => ({ t: (b.innerText||'').trim().slice(0,30), aria: b.getAttribute('aria-label'), dis: b.disabled }))), null, 1))
console.log('hydration warnings:', warn.length, warn.slice(0,3))
await browser.close()
