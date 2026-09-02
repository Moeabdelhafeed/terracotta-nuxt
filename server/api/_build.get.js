/**
 * Which build is answering, and from which worker.
 *
 * Hostinger runs Node apps under Phusion Passenger, which keeps a pool of worker
 * processes and spawns them on demand — so several different `pid`s is normal and fine.
 * What is not fine is two different `buildId`s: that means an old worker survived the
 * deploy and is still serving the previous bundle, which makes the site behave two ways
 * at once (a page in Arabic here, English there) with nothing wrong in the code.
 *
 * Hit it a handful of times and compare.
 */
export default defineEventHandler((event) => {
  const { buildId } = useRuntimeConfig(event).public

  return {
    buildId,
    pid: process.pid,
    startedAt: new Date(Date.now() - Math.round(process.uptime() * 1000)).toISOString(),
    features: ['locale-query', 'locale-mismatch-guard'],
  }
})
