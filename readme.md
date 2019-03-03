Eco Panel
=========

Overview of your economy.

TODO
----

- scrolling
- show build queue
- make icons interactive (so we can select/deselect factories via panel)
- update panel when stuff changes trough other means (mainly the original UI, but also e.g. due to enemy action)
- show and control assisting engies
- show ressource consumption


Pie Chart Renderer
------------------

The UI layer of Supreme Commander does not support anything other than textured
rectangles. Therefore, drawing pie-slices with diagonal and round edges can
only be accomplished through some workarounds.

The way it is implemented here, is by stretching and overlaying triangle
textures in such a way that it results in triangles with the correct angles. A
simple masking texture (black with a transparent circle in the middle) on top
of it all provides the circular shape.

Limitations:
- The "background", i.e. the area outside the chart that is still inside its
  bounding box is not transparent. And if you want it to be a different color
  there you need another texture.
- Dynamically coloring a texture isn't supported, so there must be a texture
  for every color you want to have in your chart. So far, there are 9 different
  ones that will be repeated if necessary.
- It's not pixel-perfect. Not sure if something is wrong with the math or if
  this is just due to way this works and how textures are strechted and overlaid.
- The current implementation is limited to a bit less than 50 segments due to a
  small hack. This could easily be fixed if required.

TODO:
- Parametrize texture folder, so the library can be used with different colors
  if so desired, without having to edit pie-chart drawing code.
- Draw diagonal lines out from segments to some textboxes.
- Implement interactivity (hover, select), both via mouse and via API (so that
  for example you can highlight something in the chart based on your currently
  selected unit).
- Use objects to store values, so that we can add more info (like the original
  value or some text) and callbacks.