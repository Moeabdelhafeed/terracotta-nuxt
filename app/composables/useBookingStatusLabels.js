/**
 * What each state is CALLED, once. The card and the badge both print it, and two copies
 * of the list drifted: «قيد التجهيز» ended up on the kiln stage in one and on the
 * wrapping stage in the other, so the same booking read as two different things
 * depending on which screen you were looking at.
 *
 * The app words the chip and the page heading apart on purpose — the chip labels the
 * lifecycle value in one word («قيد التجهيز»), the detail page says it the studio's way
 * («قيد التحضير») — so these are the chip's words only.
 */
export const useBookingStatusLabels = () => {
  const { t } = useLang("web", "bookings");

  return computed(() => ({
    pending_payment: t("status_pending_payment", "Awaiting payment", "بانتظار الدفع"),
    confirmed: t("status_confirmed", "Confirmed", "مؤكد"),
    attending: t("status_attending", "Checked in", "حاضرة"),
    absent: t("status_absent", "No-show", "لم تحضر"),
    preparing: t("status_preparing", "Being prepared", "قيد التجهيز"),
    ready: t("status_ready", "Piece ready", "القطعة جاهزة"),
    awaiting_pickup: t("status_awaiting_pickup", "Ready for pickup", "جاهزة للاستلام"),
    getting_ready: t("status_getting_ready", "Being wrapped", "قيد التغليف"),
    on_the_way: t("status_on_the_way", "Out for delivery", "خرجت للتوصيل"),
    delivered: t("status_delivered", "Delivered", "مسلمة"),
    cancelled: t("status_cancelled", "Cancelled", "ملغاة"),
  }));
};
