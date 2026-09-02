const seededKeys = new Set()

export const useLang = (group = 'web', subGroup = 'general') => {
  const lang = useCookie('lang', { default: () => null })
  const transMode = useRuntimeConfig().public.translationsMode ?? 'remote'
  const i18n = (() => {
    try {
      return useI18n()
    } catch {
      return null
    }
  })()

  const { data: langsData, refresh: refreshLanguages } = useApiFetch('/api/languages', {
    key: 'languages'
  })
  const languages = computed(() => langsData.value?.data ?? [])
  const defaultLanguage = computed(
    () => languages.value.find((l) => l.is_default) ?? languages.value[0] ?? null
  )

  watch(defaultLanguage, (def) => {
    if (!lang.value && def) lang.value = def
  }, { immediate: true })

  if (i18n) {
    watch(() => lang.value?.code ?? defaultLanguage.value?.code, async (c) => {
      if (!c) return
      try {
        if (typeof i18n.setLocale === 'function') await i18n.setLocale(c)
        else if (i18n.locale && typeof i18n.locale === 'object' && 'value' in i18n.locale) i18n.locale.value = c
      } catch {}
    }, { immediate: true })
  }

  const code = computed(() => lang.value?.code ?? defaultLanguage.value?.code ?? 'en')
  const dir = computed(() => lang.value?.direction ?? defaultLanguage.value?.direction ?? 'ltr')

  // One fetch per group returns the whole group nested by sub_group:
  //   data: { group, locale, translations: { [subGroup]: { key: value } } }
  // Every useLang(group, subGroup) instance shares this fetch and slices its own sub-group.
  const {
    data: transData,
    refresh: refreshTranslations,
    pending: translationsPending,
  } = useApiFetch('/api/translations', {
    key: `translations-${group}`,
    query: { group },
    watch: [code],
  })
  // Whole group nested by sub_group: { [subGroup]: { key: value } }.
  // Tolerate a payload that is already the nested map.
  const groupTranslations = computed(() => {
    const payload = transData.value?.data ?? {}
    return payload.translations ?? payload ?? {}
  })

  // Default slice for this composable's sub_group (a per-call override can pick another).
  const translations = computed(() => groupTranslations.value?.[subGroup] ?? {})

  const client = useSanctumClient()

  const seedTranslation = async (key, defaults, seedSubGroup = subGroup) => {
    // Scope the guard by group + sub_group so the same key can seed independently per sub-group.
    const seedId = `${group}:${seedSubGroup}:${key}`
    if (seededKeys.has(seedId)) return
    const entries = Object.entries(defaults).filter(([, v]) => v !== undefined && v !== null)
    if (!entries.length) return
    seededKeys.add(seedId)
    try {
      if (transMode === 'local') {
        await $fetch('/api/dev-translations', {
          method: 'POST',
          body: { key, defaults: Object.fromEntries(entries) },
        })
        if (i18n) {
          for (const [locale, value] of entries) {
            i18n.mergeLocaleMessage?.(locale, { [key]: value })
          }
        }
      } else {
        await Promise.all(entries.map(([locale, value]) => client('/api/translations', {
          method: 'POST',
          headers: { 'Accept-Language': locale },
          body: { translations: { [key]: value }, group, sub_group: seedSubGroup },
        })))
        refreshTranslations()
      }
    } catch {
      seededKeys.delete(seedId)
    }
  }

  // A trailing options bag carries a per-call sub_group override, e.g. { subGroup: 'auth' }.
  // Recognized only when it is a plain object whose keys are all option keys, so it can never
  // be confused with a defaults object ({ en, ar, ... }) or a params replacement map.
  const isOptionsBag = (o) =>
    o && typeof o === 'object' && !Array.isArray(o) &&
    Object.keys(o).length > 0 && Object.keys(o).every((k) => k === 'subGroup')

  // Signatures supported:
  //   t(key)
  //   t(key, defaultEn)
  //   t(key, defaultEn, defaultAr)
  //   t(key, defaultEn, defaultAr, params)
  //   t(key, defaultEn, params)
  //   t(key, { en, ar, fr, ... })
  //   t(key, { en, ar, fr, ... }, params)
  // Any of the above may take a trailing options bag to override the sub_group:
  //   t(key, ..., { subGroup: 'auth' })
  const t = (key, second, third, fourth) => {
    let defaults = {}
    let params
    let optSubGroup

    // Strip the trailing options bag (checked from the end) before the overload parsing.
    if (isOptionsBag(fourth)) { optSubGroup = fourth.subGroup; fourth = undefined }
    else if (isOptionsBag(third)) { optSubGroup = third.subGroup; third = undefined }
    else if (isOptionsBag(second)) { optSubGroup = second.subGroup; second = undefined }

    if (second !== undefined) {
      if (typeof second === 'string') {
        defaults.en = second
        if (typeof third === 'string') {
          defaults.ar = third
          params = fourth
        } else {
          params = third
        }
      } else if (typeof second === 'object' && !Array.isArray(second)) {
        defaults = { ...second }
        params = third
      }
    }

    const effectiveSubGroup = optSubGroup ?? subGroup

    let value, ready
    if (transMode === 'local' && i18n) {
      ready = true
      const localeMsgs = i18n.getLocaleMessage?.(code.value) ?? {}
      value = localeMsgs[key]
    } else {
      ready = transData.value !== null && transData.value !== undefined
      const slice = groupTranslations.value?.[effectiveSubGroup] ?? {}
      value = ready ? slice[key] : undefined
    }
    const has = typeof value === 'string' && value !== ''
    let str
    if (has) str = value
    else if (defaults[code.value] !== undefined && defaults[code.value] !== null) str = defaults[code.value]
    else str = key

    if (ready && !has && Object.keys(defaults).length && import.meta.client) {
      seedTranslation(key, defaults, effectiveSubGroup)
    }

    if (params) {
      for (const [k, v] of Object.entries(params)) {
        str = str.replaceAll(`:${k}`, String(v))
      }
    }
    return str
  }

  const setLanguage = (codeOrLang) => {
    const target =
      typeof codeOrLang === 'string'
        ? languages.value.find((l) => l.code === codeOrLang)
        : codeOrLang
    if (target) lang.value = target
  }

  return {
    lang,
    languages,
    defaultLanguage,
    code,
    dir,
    translations,
    translationsPending,
    t,
    setLanguage,
    refreshLanguages,
    refreshTranslations,
  }
}
