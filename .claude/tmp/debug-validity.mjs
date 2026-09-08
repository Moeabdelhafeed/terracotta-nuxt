import puppeteer from 'puppeteer-core'

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
const BASE = 'http://localhost:3000'
const PHONE = `5${String(Math.floor(Math.random() * 90000000) + 10000000)}`

const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox'] })
const page = await browser.newPage()
await page.setViewport({ width: 1280, height: 1400 })
page.on('response', (r) => { if (/\/api\//.test(r.url())) console.log('  RES', r.status(), r.url().replace(BASE, '')) })

await page.goto(`${BASE}/register`, { waitUntil: 'domcontentloaded' })
await page.waitForSelector('#name', { timeout: 15000 })

await page.type('#name', 'Probe User')
const phone = await page.$('input[inputmode="numeric"]')
await phone.click()
await phone.type(PHONE, { delay: 30 })
await new Promise((r) => setTimeout(r, 2000))
await page.type('#password', 'Str0ngP@ssw0rd!')
await page.type('#confirm', 'Str0ngP@ssw0rd!')
await (await page.$('[role=checkbox]')).click()
await new Promise((r) => setTimeout(r, 800))

const diag = await page.evaluate(() => {
  const form = document.querySelector('form')
  const fields = [...form.querySelectorAll('input')].map((i) => ({
    id: i.id || '(none)',
    value: i.value,
    required: i.required,
    valid: i.validity.valid,
    why: i.validationMessage,
  }))
  return {
    formValid: form.checkValidity(),
    fields,
    invalid: [...form.querySelectorAll(':invalid')].map((e) => `${e.tagName}#${e.id || ''}.${String(e.className).slice(0, 40)}`),
  }
})
console.log(JSON.stringify(diag, null, 2))

console.log('--- requestSubmit()')
await page.evaluate(() => document.querySelector('form')?.requestSubmit())
await new Promise((r) => setTimeout(r, 5000))
console.log('url:', page.url())
await browser.close()
