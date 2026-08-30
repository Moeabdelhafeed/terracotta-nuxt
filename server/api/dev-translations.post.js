import { promises as fs } from 'node:fs'
import { resolve } from 'node:path'

const locks = new Map()
const withLock = (key, fn) => {
  const prev = locks.get(key) ?? Promise.resolve()
  const next = prev.then(fn, fn)
  locks.set(key, next.catch(() => {}))
  return next
}

// vue-i18n linked-message syntax uses `@:`, `@.mod:`, `{...}`, `|`.
// Escape literals so AOT compiler doesn't blow up.
const escapeForI18n = (str) => {
  if (typeof str !== 'string') return str
  return str
    .replace(/@/g, "{'@'}")
    .replace(/(?<!\{')\|(?!'\})/g, "{'|'}")
}

export default defineEventHandler(async (event) => {
  if (process.env.NODE_ENV === 'production') {
    throw createError({ statusCode: 403, statusMessage: 'Dev only' })
  }
  const body = await readBody(event)
  const { key, defaults } = body || {}
  if (!key || !defaults || typeof defaults !== 'object') {
    throw createError({ statusCode: 400, statusMessage: 'Bad payload' })
  }

  const localesDir = resolve(process.cwd(), 'i18n/locales')
  const written = []
  const errors = []

  await Promise.all(Object.entries(defaults).map(async ([locale, value]) => {
    if (value === undefined || value === null) return
    const file = resolve(localesDir, `${locale}.json`)
    await withLock(file, async () => {
      let json = {}
      try {
        const raw = await fs.readFile(file, 'utf8')
        json = raw.trim() ? JSON.parse(raw) : {}
      } catch (e) {
        if (e.code !== 'ENOENT') {
          errors.push({ locale, error: String(e) })
          return
        }
        json = {}
      }
      const safe = escapeForI18n(value)
      if (json[key] === safe) return
      json[key] = safe
      try {
        await fs.writeFile(file, JSON.stringify(json, null, 2) + '\n', 'utf8')
        written.push(locale)
      } catch (e) {
        errors.push({ locale, error: String(e) })
      }
    })
  }))

  return { success: errors.length === 0, written, errors }
})
