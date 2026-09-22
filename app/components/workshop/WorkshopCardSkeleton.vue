<template>
  <!--
    The workshop card's own box, for both the catalogue and «ورشاتي».
    `WorkshopCard`'s shell and `BookingCard`'s are the same class string, so one
    placeholder stands in for both.

    A component rather than markup copied into each page, for the reason this exists at
    all: the cards were restyled from a tall bordered tile to this coloured band, and the
    two pages' hand-written skeletons were left describing the old one. `ProductCard` has
    `ProductCardSkeleton` beside it for the same reason.
  -->
  <div class="flex min-h-[110px] overflow-hidden rounded-control bg-card p-1">
    <div class="flex min-w-0 flex-1 flex-col gap-1 pb-4 pe-2 ps-4 pt-4">
      <AppSkeleton class="h-7 w-2/3" />
      <AppSkeleton class="h-4 w-24 !rounded-full" />
      <AppSkeleton class="h-3 w-full" />
      <AppSkeleton class="mt-auto h-7 w-32" />
    </div>
    <AppSkeleton class="w-[101px] shrink-0 self-stretch !rounded-[6px]" />
  </div>
</template>
