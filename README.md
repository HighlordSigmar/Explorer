# Explorer

A world map addon for **OctoWoW** (1.12 client): coordinates, mouse wheel zoom, retail-style markers for dungeons, raids, world bosses and transports, and zone level ranges.

## Install
Put the `Explorer` folder in `Interface\AddOns\` (or add this repo in Wuddle). Explorer does the jobs of these addons, so turn them off: **Magnify**, **ModernMapMarkers** and **LevelRange-Turtle**. If one of them is still on, Explorer leaves that part to it and tells you in the chat.

## Features
- **Coordinates** under the map: where your cursor is on the map and where you are. They replace ShaguTweaks' map coordinates
- **Zoom**: mouse wheel over the map zooms in and out around the cursor, drag the zoomed map to move it. Works with OctoWoW's small and big map and with ShaguTweaks' map window (Ctrl / Shift + wheel still resize / fade that window). Your arrow stays the same size and turns with you
- **Markers** on zone maps, in the style of retail's map icons:
  - Dungeons and raids, with their level range colored for your level. Click one to open its map; places with several instances (Blackrock Mountain, Dire Maul, Scarlet Monastery, the Gates of Ahn'Qiraj...) open their own map first. With **InstanceJournal** installed, right-click opens its journal page, and its own entrance pins are left out where Explorer has a marker
  - World bosses
  - Boats, zeppelins and the Deeprun Tram, with where they go. By default only your faction's and neutral ones
- **Zone level ranges**: hover a zone on the continent map and its name gets its levels, like retail: "Westfall (10-20)". Red/orange while it is above you, yellow while you are in it, green/gray once you outgrew it. Includes OctoWoW's zones (Gilneas, Tel'Abim, Grim Reaches, Balor, Northwind, Moonwhisper Coast...)
- **Zone info box**, like LevelRange had: friendly / hostile / contested, the zone's dungeons and raids with their levels, its world bosses, and the fishing skill it needs (green if yours is enough)

## Commands
`/explorer` options window · `/explorer coords` · `/explorer zoom` · `/explorer markers` · `/explorer levels` · `/explorer info` · `/explorer transports` · `/explorer reset`

## For developers
`devkit/` has the test harness (`lua50 devkit/test_explorer.lua`, Lua 5.0 with a mocked map API), the instance data generator and the icon drawing script. See `devkit/NOTES.md` and `CREDITS.txt`.
