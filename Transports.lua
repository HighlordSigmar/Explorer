-- Explorer: boats, zeppelins and the tram
-- [continent][zone] = { x, y, kind, destination, faction ("A", "H", "N") }
-- Coordinates are 0-100 on the zone map. Positions as charted by
-- ModernMapMarkers for TurtleWoW / OctoWoW.

Explorer.TransportPins = {
  [1] = {
    ["Darkshore"] = {
      { 32.4, 44.0, "boat", "Stormwind", "A" },
      { 30.4, 41.0, "boat", "Alah'Thalas", "A" },
      { 33.3, 39.9, "boat", "Rut'theran Village", "A" },
    },
    ["Desolace"] = {
      { 20.5, 75.0, "boat", "Moonhoof Village", "H" },
    },
    ["Durotar"] = {
      { 51.2, 13.5, "zeppelin", "Undercity and Grom'gol", "H" },
      { 41.5, 18.4, "zeppelin", "Thunder Bluff and Kargath", "H" },
      { 59.8, 23.6, "boat", "Revantusk Village", "H" },
    },
    ["Dustwallow Marsh"] = {
      { 71.8, 56.6, "boat", "Menethil Harbor", "A" },
    },
    ["Feralas"] = {
      { 31.1, 39.5, "boat", "the Forgotten Coast", "A" },
      { 43.1, 42.8, "boat", "Sardor Isle", "A" },
    },
    ["Moonwhisper Coast"] = {
      { 71.0, 38.0, "boat", "Shadowprey Village", "H" },
    },
    ["Teldrassil"] = {
      { 55.2, 94.9, "boat", "Auberdine", "A" },
    },
    ["The Barrens"] = {
      { 63.6, 38.9, "boat", "Booty Bay", "N" },
    },
    ["Thunder Bluff"] = {
      { 16.5, 23.0, "zeppelin", "Orgrimmar", "H" },
    },
  },
  [2] = {
    ["Alah'Thalas"] = {
      { 53.1, 4.7, "boat", "Auberdine", "A" },
    },
    ["Badlands"] = {
      { 7.5, 48.0, "zeppelin", "Orgrimmar", "H" },
    },
    ["Ironforge"] = {
      { 76.2, 51.1, "tram", "Stormwind", "A" },
    },
    ["Stormwind City"] = {
      { 69.4, 29.4, "tram", "Ironforge", "A" },
      { 21.8, 56.3, "boat", "Auberdine", "A" },
    },
    ["Stranglethorn Vale"] = {
      { 25.7, 73.0, "boat", "Ratchet", "N" },
      { 31.2, 29.8, "zeppelin", "Undercity and Orgrimmar", "H" },
    },
    ["The Hinterlands"] = {
      { 81.2, 79.4, "boat", "Sparkwater Port", "H" },
    },
    ["Tirisfal Glades"] = {
      { 61.6, 57.1, "zeppelin", "Orgrimmar and Grom'gol", "H" },
    },
    ["Wetlands"] = {
      { 6.8, 61.3, "boat", "Theramore Isle", "A" },
    },
  },
}
