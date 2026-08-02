# Pour Toujours — Asset and Data Manifest

This document locks the first production-quality visual and data sources for the app. The rule is simple: every asset must either be original, explicitly licensed, or generated from a documented data source.

## 1. Visual system

### Typography

- Primary UI font: Manrope
- Optional editorial accent: Newsreader, limited to major headings and birthday/event moments
- Delivery: self-host font files in the app bundle; do not depend on runtime font downloads
- Numerals: use tabular figures for clocks, temperatures, and timelines

### Icons

- Primary icon system: Material Symbols or Lucide
- Weather icons: one coherent custom subset derived from the selected icon system
- Do not mix Material, Cupertino, emoji, and random SVG icon packs on one screen

### App mark

- Keep the four-pane Pour Toujours mark as the base concept
- Redraw it as a compact optical icon suitable for 16–1024 px
- Required exports: SVG master, monochrome SVG, adaptive Android foreground, iOS icon source, favicon

## 2. Dynamic visual assets

### Weather scenes

The primary visual language should be generated in-app rather than downloaded as stock artwork.

Required scene states:

- clear dawn
- clear day
- overcast day
- rain
- storm
- sunset
- clear night
- cloudy night
- heat
- snow/ice

Each scene should be built from reusable layers: sky gradient, sun/moon, cloud coverage, precipitation, horizon glow, and subtle grain. City identity should be conveyed by labels, family faces, and optional photography—not by low-detail skyline placeholders.

### City photography

Photography is secondary, never the background behind critical text.

Initial target: 4–8 verified images per city:

- Karachi
- Chiba
- Dublin
- Hattiesburg

Preferred source order:

1. Family-owned photographs with explicit permission
2. Manually curated Pexels photographs with creator/source metadata retained
3. Openverse results after manually verifying the original work and license
4. Unsplash API only if its hotlinking, attribution, and download-event requirements are implemented

Every image record must store:

- city
- source
- source URL
- photographer/creator
- license
- license URL
- attribution text
- season
- daypart
- weather tags
- focal point/crop notes

Never use a photo merely because it depicts the same country. Chiba must be Chiba; Hattiesburg must be Hattiesburg.

### Family photography

- Profile photo is optional
- Initials fallback must remain first-class and visually polished
- Family photos remain local/private unless a future backend is explicitly enabled
- Never upload family photos to a third-party image-processing service without consent

## 3. Data sources

### Weather

Selected source: Open-Meteo

Required fields:

- current temperature
- apparent temperature
- weather code
- precipitation probability and timing
- daily high/low
- sunrise/sunset
- wind only when meaningfully strong
- UV or air quality only when actionable

Cache weather by city, not person. All Karachi profiles share one weather request.

### Public holidays

Selected source: Nager.Date

Use public/national holiday data as context, not proof that a person is off work. Regional, optional, religious, school, and family-specific dates require separate flags or manual entries.

### Time zones

- Store IANA identifiers only
- Asia/Karachi
- Asia/Tokyo
- Europe/Dublin
- America/Chicago

Never store a fixed UTC offset as the source of truth.

### Identity selection

Selected local persistence: shared_preferences

The first-launch profile choice is stored locally. No PIN, account, or cloud login is required. Settings must expose “Switch person.”

## 4. Map and globe material

The globe is a later production feature, not a decorative home-screen requirement.

### Production-safe first map

- Use flutter_map for a flat family-world view if a map is needed before the globe
- Display only the four family cities
- No live location
- No generic map labels or route clutter

### Experimental globe spike

Candidate packages:

- flutter_earth_globe
- flutter_globe_3d

Before adoption, validate:

- 60 fps on a mid-range Android phone
- web compatibility
- day/night terminator accuracy
- screen-reader fallback
- reduced-motion mode
- battery impact
- marker legibility

If the globe fails those checks, replace it with a custom two-dimensional world/daylight visualization.

## 5. Required asset folders

```text
assets/
  brand/
    mark/
    app_icon/
  fonts/
    manrope/
    newsreader/
  icons/
    weather/
    status/
  weather_scenes/
    layers/
  city_photos/
    karachi/
    chiba/
    dublin/
    hattiesburg/
  family/
    placeholders/
  maps/
    textures/
  licenses/
    ATTRIBUTION.md
    third_party_assets.json
```

## 6. Asset acceptance checklist

An asset may enter the production bundle only when:

- the source is recorded
- the license is compatible
- attribution requirements are understood
- the city/location is accurate
- the crop works at phone and widget sizes
- text never depends on the image remaining bright or dark
- the asset has a non-image fallback
- compressed output has been inspected for quality

## 7. Explicitly rejected material

- random image-search downloads
- AI-generated city landmarks presented as real places
- generic country photos substituted for a specific city
- mixed icon families
- emoji as production weather/status icons
- low-detail skyline placeholders
- decorative 3D globe without useful interaction
- photographs with unknown license or attribution
- third-party tracking embedded only to fetch decorative imagery

## 8. Next acquisition batch

1. Self-host Manrope and optional Newsreader font files
2. Select one icon family and export the exact weather/status subset
3. Build ten reusable weather-scene layer sets
4. Curate four verified candidate photos per city with metadata
5. Build the one-time identity-selection avatar set
6. Prototype the family timeline before investing in a globe
