// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'

/**
 * The address pin on Google Maps (QA GEN-01): it was a read-only OpenStreetMap embed.
 * `google.maps` is faked — a Map that records listeners and a Marker that records where it
 * was put — so the test drives the picker the way a tap and a drag would.
 */
const lang = await vi.hoisted(async () => (await import('../helpers/mockApi')).createLang('en'))
mockNuxtImport('useLang', () => () => lang)

const maps = vi.hoisted(() => ({ loadFails: false, instances: [], markers: [] }))
mockNuxtImport('useGoogleMaps', () => () => ({
  available: true,
  load: () => (maps.loadFails ? Promise.reject(new Error('blocked')) : Promise.resolve(window.google.maps)),
  onAuthFailure: (callback) => { maps.authFailure = callback; return () => {} },
}))

class FakeMap {
  constructor(el, options) { this.options = options; this.listeners = {}; this.panned = null; maps.instances.push(this) }
  addListener(name, fn) { this.listeners[name] = fn }
  panTo(position) { this.panned = position }
}
class FakeMarker {
  constructor(options) { this.position = options.position; this.listeners = {}; maps.markers.push(this) }
  addListener(name, fn) { this.listeners[name] = fn }
  setPosition(position) { this.position = position }
  setMap() {}
}
const latLng = (lat, lng) => ({ lat: () => lat, lng: () => lng })

const Picker = (await import('~/components/address/AddressMapPicker.vue')).default

beforeEach(() => {
  maps.loadFails = false
  maps.instances.length = 0
  maps.markers.length = 0
  window.google = { maps: { Map: FakeMap, Marker: FakeMarker } }
})

describe('AddressMapPicker', () => {
  it('opens on Riyadh with no pin, and a tap drops one and reports it', async () => {
    const wrapper = await mountSuspended(Picker, { props: { lat: '', lng: '' } })
    await flushPromises()

    const map = maps.instances[0]
    expect(map.options.center).toEqual({ lat: 24.7136, lng: 46.6753 })
    expect(maps.markers).toHaveLength(0)

    map.listeners.click({ latLng: latLng(21.543333, 39.172778) })

    expect(maps.markers[0].position).toEqual({ lat: 21.543333, lng: 39.172778 })
    expect(wrapper.emitted('pick')[0][0]).toEqual({ lat: '21.543333', lng: '39.172778' })
  })

  it('reports a dragged pin too', async () => {
    const wrapper = await mountSuspended(Picker, { props: { lat: '24.7136', lng: '46.6753' } })
    await flushPromises()

    maps.markers[0].listeners.dragend({ latLng: latLng(24.8, 46.7) })

    expect(wrapper.emitted('pick').at(-1)[0]).toEqual({ lat: '24.800000', lng: '46.700000' })
  })

  it('follows coordinates typed or looked up outside the map', async () => {
    const wrapper = await mountSuspended(Picker, { props: { lat: '24.7136', lng: '46.6753' } })
    await flushPromises()

    await wrapper.setProps({ lat: '26.4207', lng: '50.0888' })
    await flushPromises()

    expect(maps.markers[0].position).toEqual({ lat: 26.4207, lng: 50.0888 })
    expect(maps.instances[0].panned).toEqual({ lat: 26.4207, lng: 50.0888 })
  })

  it('says to type the coordinates when the map cannot load', async () => {
    maps.loadFails = true
    const wrapper = await mountSuspended(Picker, { props: { lat: '', lng: '' } })
    await flushPromises()

    expect(wrapper.find('[data-test="address-map-unavailable"]').text()).toContain('type the coordinates below')
  })

  it('falls back to typing when Google refuses the key for this address', async () => {
    const wrapper = await mountSuspended(Picker, { props: { lat: '', lng: '' } })
    await flushPromises()

    // What Google does on a referrer it doesn't allow (www., localhost): the script loads,
    // then gm_authFailure fires.
    maps.authFailure()
    await flushPromises()

    expect(wrapper.find('[data-test="address-map-unavailable"]').exists()).toBe(true)
  })
})
