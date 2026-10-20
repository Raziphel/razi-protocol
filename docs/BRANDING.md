# Razi Protocol v3 identity

The supplied corporate dragon emblem connects Protocol to Raziel and Razi's
Realm while preserving the industrial expedition identity. The portal thumbnail
is 256×256 RGBA; the journal uses a 128×128 RGBA source at its existing 28px
masthead size. `resize_to_sprite=false` and the existing native icon sizing
remain in force. The HUD's book button and individual chapter, technology,
planet, hazard and quest icons retain their functional meaning.

`graphics/branding/razi-protocol-lockup.png` is the transparent 900×300
promotional/README lockup. It is not a startup texture or full-screen background.
No custom main-menu renderer or loading screen is introduced.

Original source: `RAZI Protocol Dragon Emblem.png`, supplied with the official
Raziel artwork. The complete unmodified source collection and reproducible
Pillow exporter live in the `razis-realm-website` repository at
`branding/` and `tools/build-raziel-branding.py`. Production uses only committed
local PNGs; no sibling repository or website download is needed.

Midnight Archive's charcoal, cream and brass remain the base. Pink, teal and
amethyst are restrained accents in the official emblem, never replacements
for hazard or chapter colors. The website's full character illustrations
belong to community presentation, not technology icons.

Changes are authored on `feat/razi-3.0`. Run `python scripts/audit_assets.py`
to check these dimensions, PNG alpha and prototype paths. Native client review
at different UI scales is still required for a renderer-level guarantee.
