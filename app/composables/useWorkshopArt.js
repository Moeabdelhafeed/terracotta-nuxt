/**
 * A workshop's fallback drawing, through dynamic storage.
 *
 * The three family illustrations are CMS assets like everything else the site paints, so
 * the studio can swap one without a deploy. The `/public` file is only the seed: it is
 * uploaded the first time the key renders missing, and stands in until it resolves.
 */
export const useWorkshopArt = () => {
  const { media } = useMedia('web', 'workshops')

  const artFor = (workshop) => {
    const key = workshopArtKey(workshop)
    return key ? media(key, workshopArt(workshop)) : null
  }

  return { artFor }
}
