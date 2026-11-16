# Explorer dev notes

Lua 5.0 (1.12 client): no `#`, no `%` operator, `string.gfind`, `table.getn`.

## Tests
`lua50 devkit/test_explorer.lua` from the addon folder. `harness.lua` mocks just
enough of the frame API and WorldMapFrame.lua (WorldMapButton_OnUpdate,
WorldMapFrame_Update, WorldMapButton_OnClick, OctoWoW's
WorldMapFrame_Minimize/Maximize) to load the addon and drive the map.
Lua 5.0 can be built from github.com/lua/lua tag `v5.0` (leave out linit.c).

## Data
- `Instances.lua` is generated: `lua50 devkit/gen_instances.lua /path/to/InstanceJournal/ > Instances.lua`.
  InstanceJournal (public domain) keys zones by their index in GetMapZones();
  `devkit/zones.lua` has those lists by name. Instances whose entrance is on a
  sub-map (Blackrock Mountain, Dire Maul...) also get a pin on every outdoor
  zone that leads there (IJDB.POI entrances), listing what is inside.
  OctoWoW's instance maps are "continents" 3-46 (`SetMapZoom(mapId, floor)`).
- `Zones.lua`: Questie-Octo's audited level ranges (same as Loremaster 2.8.0 had),
  LevelRange's factions and fishing skills.
- `Transports.lua`: by hand.
- Icons: `python3 devkit/make_icons.py Textures` (PIL), 64x64 RLE TGA, bottom-left origin.

## How it hooks the map
- Core wraps the globals `WorldMapButton_OnUpdate` (every frame, called by name
  from WorldMapFrame.xml) and `WorldMapFrame_Update` (map redrawn) at
  VARIABLES_LOADED, after every addon has loaded.
- Zoom: `ExplorerScrollFrame` holds WorldMapDetailFrame as its scroll child and
  takes no mouse; WorldMapButton is re-parented to the picture (level 2) and gets
  the wheel and the drag. In WorldMapFrame.xml the map button has no OnClick: it
  calls `WorldMapButton_OnClick(arg1)` from OnMouseUp (left = ProcessMapClick,
  right = zoom out one level). Explorer wraps only OnMouseUp: the end of a drag
  does nothing; zoomed in, a left click goes through a stand-in button whose
  GetScale/GetEffectiveScale return the real effective scale (the game divides
  the cursor by `button:GetScale()`, and indexes `button` as a frame - passing a
  name errors at WorldMapFrame.lua:471); everything else is the game's own
  OnMouseUp, once. Adding an OnClick as well made right-click zoom out twice. Layout numbers
  (1002x668 at TOP -70, small map 702x468 at -24 and zoom 0.7, -48 / -24 with
  ShaguTweaks) are Magnify's, which work on OctoWoW.
- Markers are children of WorldMapButton, sized `base / ZoomFactor()` so they
  keep their size on screen.
- InstanceJournal: `IJ_ShowInstanceEntrancesIcon` / `IJ_ShowPOIEntrancesIcon`
  are skipped on maps where Explorer has instance pins.
- Conflicts: Magnify (zoom + coords), ModernMapMarkers (markers),
  LevelRange(-Turtle) (info box) switch that part of Explorer off.
