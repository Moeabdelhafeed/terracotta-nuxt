import puppeteer from 'puppeteer-core'
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox'] })
const page = await browser.newPage()
await page.setViewport({ width: 1280, height: 700 })
await page.goto('http://localhost:3000/', { waitUntil: 'domcontentloaded', timeout: 60000 })
await new Promise((r) => setTimeout(r, 1200))

const probe = await page.evaluate(async () => {
  // Exactly what the address dialog renders today, with the body scroll-locked the way
  // useModalScrollLock does it.
  document.body.style.overflow = 'hidden'
  const wrap = document.createElement('div')
  wrap.className = 'fixed inset-0 z-50 flex items-center justify-center overflow-y-auto p-4'
  wrap.innerHTML = `<div class="fixed inset-0 bg-black/50"></div>
    <div id="panel" class="relative my-auto max-h-[90svh] w-full max-w-2xl overflow-y-auto rounded-2xl border bg-background p-6 shadow-lg">
      <div style="height:1800px">tall</div>
    </div>`
  document.body.appendChild(wrap)
  await new Promise((r) => requestAnimationFrame(r))

  const panel = document.getElementById('panel')
  const before = panel.scrollTop
  panel.scrollTop = 400
  const afterPanel = panel.scrollTop
  const wrapScrollable = wrap.scrollHeight > wrap.clientHeight

  const out = {
    panelCanScroll: panel.scrollHeight > panel.clientHeight,
    panelScrolled: afterPanel !== before,
    wrapperAlsoScrolls: wrapScrollable,
    wrapperScrollbarWidth: wrap.offsetWidth - wrap.clientWidth,
    panelScrollbarWidth: panel.offsetWidth - panel.clientWidth,
  }
  wrap.remove()
  document.body.style.overflow = ''
  return out
})
console.log(JSON.stringify(probe, null, 1))
await browser.close()
