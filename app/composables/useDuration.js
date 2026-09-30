/**
 * A stretch of time in words, correctly inflected in both languages — "ساعتان و15 دقيقة",
 * "يوم واحد و6 ساعات", "2 hours and 15 minutes". Arabic has five plural forms (CLDR), which
 * is why "1 أيام" and "1 ساعات" kept shipping when one `:n` template was reused for every
 * count.
 *
 * `remaining(minutes)` picks the scale a person would: minutes under an hour, hours and
 * minutes under a day, days and hours beyond that.
 *
 * `counted(n, 'person')` is here too — a head count is the same inflection problem, and the
 * booking page showed "1 أشخاص" for a party of one.
 */
export const useDuration = () => {
  const { t, code } = useLang('web', 'bookings')

  const FORMS = {
    day: {
      one: () => t('unit_day_one', '1 day', 'يوم واحد'),
      two: () => t('unit_day_two', '2 days', 'يومان'),
      few: (n) => t('unit_day_few', ':n days', ':n أيام', { n }),
      many: (n) => t('unit_day_many', ':n days', ':n يومًا', { n }),
      other: (n) => t('unit_day_other', ':n days', ':n يوم', { n }),
    },
    hour: {
      one: () => t('unit_hour_one', '1 hour', 'ساعة واحدة'),
      two: () => t('unit_hour_two', '2 hours', 'ساعتان'),
      few: (n) => t('unit_hour_few', ':n hours', ':n ساعات', { n }),
      many: (n) => t('unit_hour_many', ':n hours', ':n ساعة', { n }),
      other: (n) => t('unit_hour_other', ':n hours', ':n ساعة', { n }),
    },
    person: {
      one: () => t('unit_person_one', '1 person', 'شخص واحد'),
      two: () => t('unit_person_two', '2 people', 'شخصان'),
      few: (n) => t('unit_person_few', ':n people', ':n أشخاص', { n }),
      many: (n) => t('unit_person_many', ':n people', ':n شخصًا', { n }),
      other: (n) => t('unit_person_other', ':n people', ':n شخص', { n }),
    },
    piece: {
      one: () => t('unit_piece_one', '1 piece', 'قطعة واحدة'),
      two: () => t('unit_piece_two', '2 pieces', 'قطعتان'),
      few: (n) => t('unit_piece_few', ':n pieces', ':n قطع', { n }),
      many: (n) => t('unit_piece_many', ':n pieces', ':n قطعة', { n }),
      other: (n) => t('unit_piece_other', ':n pieces', ':n قطعة', { n }),
    },
    photo: {
      one: () => t('unit_photo_one', '1 photo', 'صورة واحدة'),
      two: () => t('unit_photo_two', '2 photos', 'صورتان'),
      few: (n) => t('unit_photo_few', ':n photos', ':n صور', { n }),
      many: (n) => t('unit_photo_many', ':n photos', ':n صورة', { n }),
      other: (n) => t('unit_photo_other', ':n photos', ':n صورة', { n }),
    },
    minute: {
      one: () => t('unit_minute_one', '1 minute', 'دقيقة واحدة'),
      two: () => t('unit_minute_two', '2 minutes', 'دقيقتان'),
      few: (n) => t('unit_minute_few', ':n minutes', ':n دقائق', { n }),
      many: (n) => t('unit_minute_many', ':n minutes', ':n دقيقة', { n }),
      other: (n) => t('unit_minute_other', ':n minutes', ':n دقيقة', { n }),
    },
  }

  /** One count of one unit: `counted(3, 'hour')` → "3 ساعات". */
  const counted = (count, unit) => {
    const forms = FORMS[unit]
    const form = code.value === 'ar' ? arabicPluralForm(count) : count === 1 ? 'one' : 'other'

    return (forms[form] ?? forms.other)(count)
  }

  const pair = (first, second) =>
    t('unit_pair', ':first and :second', ':first و:second', { first, second })

  /** Whole minutes → the most natural two-unit phrase. */
  const remaining = (minutes) => {
    const total = Math.max(0, Math.floor(minutes))
    if (total < 60) return counted(Math.max(total, 1), 'minute')

    if (total < 24 * 60) {
      const hours = Math.floor(total / 60)
      const mins = total % 60
      return mins ? pair(counted(hours, 'hour'), counted(mins, 'minute')) : counted(hours, 'hour')
    }

    const days = Math.floor(total / (24 * 60))
    const hours = Math.floor((total % (24 * 60)) / 60)
    return hours ? pair(counted(days, 'day'), counted(hours, 'hour')) : counted(days, 'day')
  }

  /**
   * Minutes from now until an ISO instant, or null when it is missing or past. Rounded up:
   * a three-hour window read "2 hours and 59 minutes" the moment it was booked, and the last
   * seconds of a window must not read as zero while it is still open.
   */
  const minutesUntil = (iso) => {
    const at = iso ? new Date(iso).getTime() : NaN
    if (Number.isNaN(at)) return null
    const ms = at - Date.now()
    return ms > 0 ? Math.ceil(ms / 60000) : null
  }

  return { counted, remaining, minutesUntil }
}
