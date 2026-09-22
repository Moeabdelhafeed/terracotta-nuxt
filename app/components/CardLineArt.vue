<template>
  <!-- The studio's drawn line, white on transparent, laid over a filled tile. Unpositioned
       and unsized: the caller places it, because a square tile takes the whole of it and a
       wide row takes a square of it at its end.

       `object-contain`, not cover: the drawing is a closed loop, and cropping it to fill a
       tile that is not square left two arcs at the edges that read as a different mark
       altogether. Contain keeps the whole shape whatever box it is given. -->
  <img
    src="/card-line-art.png"
    alt=""
    aria-hidden="true"
    class="pointer-events-none object-contain"
  />
</template>
