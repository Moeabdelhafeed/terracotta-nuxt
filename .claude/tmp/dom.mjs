import puppeteer from 'puppeteer-core'
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: 'new', args: ['--no-sandbox'] })
const page = await browser.newPage()
await page.setCookie({ name: 'lang', value: encodeURIComponent(JSON.stringify({ code: 'en', direction: 'ltr' })), domain: 'localhost', path: '/' })
await page.goto('http://localhost:3000/shop/1', { waitUntil: 'domcontentloaded' })
await new Promise(r => setTimeout(r, 3500))
console.log(await page.evaluate(() => ({
  mainImgs: document.querySelectorAll('.aspect-square.w-full.object-cover').length,
  thumbs: document.querySelectorAll('button.size-20').length,
  altMatches: [...document.querySelectorAll('img')].filter(i => i.alt === 'Abbasi Cups 1').length,
})))
await browser.close()
