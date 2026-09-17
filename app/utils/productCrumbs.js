/**
 * The trail a piece sits under, shared by the page and the view it mounts.
 *
 * Both product pages build schema.org breadcrumbs from this while `ProductDetailView`
 * draws the visible bar from it — they were separate before, and the pages referenced a
 * `crumbs` that only ever existed inside the component, so every server render of a
 * product threw `crumbs is not defined` and answered 500.
 */
export const productCrumbs = ({ product, sectionTo, sectionLabel, t }) => [
  { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
  { to: sectionTo, label: sectionLabel },
  ...(product?.category ? [{ label: product.category }] : []),
  { label: product?.title ?? '' },
]
