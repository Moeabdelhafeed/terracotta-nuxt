const uploadingKeys = new Set()
/**
 * One seed per key per page, so a render cannot fire the same upload twice. Deliberately
 * *not* persisted: a key deleted from the CMS has to seed itself again on the next visit,
 * with no storage to clear and no hard refresh. Duplicate uploads across loads are
 * prevented by the media list being uncached, so the page after a seed already knows the
 * key exists — see CACHED_PATHS in server/api/[...].js.
 */
const seededMedia = new Set()

/**
 * Dynamic storage client — keyed media (image/video/file) by group + sub_group + key.
 * Mirrors `useLang`: one fetch per group returns every asset nested by sub_group; each
 * `useMedia(group, subGroup)` instance slices its own sub-group. Remote-only (files need
 * real storage — there is no local mode).
 *
 * Response shape from GET /api/media:
 *   data: { group, media: { [subGroup]: { [key]: { type, image|video|file: {…} } } } }
 * `type` is 'image' | 'video' | 'file' and the morph under that key is the canonical model
 * shape (Image: { id, url, type, blurhash, image_api }; Video: the same plus video_api and
 * a `thumbnail` Image). Render any of them with <AppMedia :src="asset" />.
 */
// The morph lives under the item's own type key — see MediaItem::toApi().
const assetUrl = (asset) => {
  const morph = asset?.[asset?.type]
  return morph?.image_api ?? morph?.video_api ?? morph?.file_api ?? null
}

export const useMedia = (group = 'web', subGroup = 'general') => {
  const {
    data: mediaData,
    refresh: refreshMedia,
    pending: mediaPending,
  } = useApiFetch('/api/media', {
    key: `media-${group}`,
    query: { group },
  })

  // Whole group nested by sub_group.
  const groupMedia = computed(() => mediaData.value?.data?.media ?? {})
  // The fetch has resolved (so a missing key is genuinely absent, not still loading).
  const ready = computed(() => mediaData.value !== null && mediaData.value !== undefined)

  // Full asset object { type, image|video|file } for a key.
  const mediaMeta = (key, { subGroup: sub } = {}) => {
    const slice = groupMedia.value?.[sub ?? subGroup] ?? {}
    return slice[key] ?? null
  }

  /**
   * Seed a missing key by uploading a local asset from Nuxt's /public folder.
   * Fetches the public path as a Blob, wraps it in a File, and uploads it. Client-only.
   */
  const seedMedia = async (key, defaultPath, effectiveSubGroup) => {
    const guardId = `${group}:${effectiveSubGroup}:${key}`
    if (seededMedia.has(guardId)) return
    seededMedia.add(guardId)
    try {
      const res = await fetch(defaultPath)
      if (!res.ok) throw new Error(`could not load ${defaultPath}`)
      const blob = await res.blob()
      const ext = (defaultPath.split(/[?#]/)[0].split('.').pop() || 'bin').toLowerCase()
      const file = new File([blob], `${key}.${ext}`, { type: blob.type || undefined })
      await uploadMedia(key, file, { subGroup: effectiveSubGroup })
      // Remembered only on success. Recording the attempt up front meant a failed upload —
      // or a key deleted from the CMS — could not be retried until the window expired.
      rememberSeed(guardId)
    } catch {
      // Allow a later retry if the seed failed.
      seededMedia.delete(guardId)
    }
  }

  /**
   * Resolve a key's asset — `{ type, image|video|file }`, ready for `<AppMedia :src="…" />`.
   * If the backend has no such key and a `defaultPath` (a file in
   * Nuxt's /public folder) is given, returns that path as a plain string for immediate
   * render AND — once, client-side — uploads it so the key is registered (exactly like
   * `useLang().t(key, default)` seeds a missing translation).
   *
   * Signatures:
   *   mediaAsset(key)
   *   mediaAsset(key, defaultPath)
   *   mediaAsset(key, defaultPath, { subGroup })
   *   mediaAsset(key, { subGroup })            // no default, just an override
   *
   * @param {string} key
   * @param {string|{subGroup?:string}} [defaultPath]
   * @param {{ subGroup?: string }} [opts]
   * @returns {{type:string,url:string,blurhash?:string}|string|null}
   */
  const mediaAsset = (key, defaultPath, opts = {}) => {
    if (defaultPath && typeof defaultPath === 'object') {
      opts = defaultPath
      defaultPath = undefined
    }
    const effectiveSubGroup = opts.subGroup ?? subGroup
    const asset = (groupMedia.value?.[effectiveSubGroup] ?? {})[key]

    if (assetUrl(asset)) return asset

    if (defaultPath && ready.value && import.meta.client) {
      seedMedia(key, defaultPath, effectiveSubGroup)
    }
    return defaultPath ?? null
  }

  /** Same as `mediaAsset`, narrowed to the public URL. Use it for `background-image`,
   *  `<link>`, og:image — anywhere an object is no use. @returns {string|null} */
  const media = (key, defaultPath, opts = {}) => {
    const asset = mediaAsset(key, defaultPath, opts)
    return typeof asset === 'string' ? asset : assetUrl(asset)
  }

  /**
   * Upload (create or replace) the asset at (key, group, sub_group). The backend infers the
   * type from the file's mime. Returns the API response, then refreshes the group.
   *
   * @param {string} key
   * @param {File|Blob} file
   * @param {{ subGroup?: string }} [opts]
   */
  const uploadMedia = async (key, file, { subGroup: sub } = {}) => {
    const effectiveSubGroup = sub ?? subGroup
    const guardId = `${group}:${effectiveSubGroup}:${key}`
    if (uploadingKeys.has(guardId)) return null
    uploadingKeys.add(guardId)

    try {
      const form = new FormData()
      form.append('group', group)
      form.append('sub_group', effectiveSubGroup)
      form.append('key', key)
      form.append('file', file)

      const res = await useApi()('/api/media', {
        method: 'POST',
        body: form,
      })
      await refreshMedia()
      return res
    } finally {
      uploadingKeys.delete(guardId)
    }
  }

  return {
    media,
    mediaAsset,
    mediaMeta,
    groupMedia,
    uploadMedia,
    refreshMedia,
    mediaPending,
  }
}
