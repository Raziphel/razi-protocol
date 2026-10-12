# Razi Expedition Route Highlights

Inspired by [Space Route Overlay](https://mods.factorio.com/mod/space-route-overlay)
by valent125. Original artwork/masks and implementation, with no copied assets.

**Purpose:** Color only major interstellar journeys and dangerous asteroid
crossings. Ordinary intra-system supply routes remain unobtrusive instead of
turning dense planetary clusters into an unreadable colored web.

The default **Subtle** startup setting uses faint, narrow strokes.
**Clear** uses stronger strokes and displays an additional asteroid-belt
approach. **Off** disables all visual additions without altering routes.

The visual vocabulary is calm teal, amber, orange and violet. The planned
chapter sets a conservative minimum danger grade; the final asteroid spawn
definitions can increase that grade. This is not an accurate forecast of
platform damage, and asteroid hazards themselves never change.

The implementation is data-only. No `control.lua` ticks, player events or
surface render objects are needed. Each layered PNG is indexed (2-bit)
and tinted by `prototypes/system/route_highlights.lua`. The layer is added
to Factorio's `utility-sprites.default.starmap_star.layers` only after
all Razi routes and orbit positions have finalized. It never changes native
map route shapes, distances, discoveries, or native belt loot.

The mask manifests are generated from fixed map endpoint coordinates.
A mismatch of at least 1.5 map units causes the mask to be dropped so it
cannot paint a visibly wrong location when another mod moves the endpoints.
If the original Space Route Overlay mod is also installed, Razi skips its
graphical pass to avoid double overlays.

**Limitations:** Factorio does not expose a color property on individual
space connections. These masks follow Razi's *straight expedition routes*
rather than using a native line tint. Short native asteroid crossings have
separate dotted masks; arbitrary third-party curved routes stay unmodified.
The full in-game view should be checked after updating the six-star layout.

Assets in `graphics/route-highlights/` must be regenerated if the
corresponding layout anchors move or the route topology is replaced.

## Route lighting refinement

Expedition masks now use three render passes from the **same source PNG**:
a near-invisible broad bloom, a tighter middle halo, and the unchanged
crisp centerline. The small differences in scale keep the luminous fringe
close to the accurate original endpoints. Early routes stay restrained;
outer corridors and belt crossings get a modest increase in contrast.
Colors still come from the final actual asteroid hazard definitions.

The pass is idempotent by guide filename and still skips missing, moved,
or unsupported curved routes. At most 42 route layers are composed from
the 14 existing masks (rather than 28 before). There are no per-tick
animations, rebuilt render objects, new routes, or extra textures.

## In-transit asteroid field ornaments

Four existing route guides now have faint native Razi debris or gravity-lens
sprites centered at their real midpoints to indicate concentrated asteroid
spawn windows. These visuals do not create additional connections, consume
new textures, or execute on simulation ticks.
