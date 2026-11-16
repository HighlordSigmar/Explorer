-- Explorer: level ranges, faction and fishing skill of the zones
--
-- Level ranges for OctoWoW 1.18.1 as audited against the current client by
-- Questie-Octo (Docs/ZONE_LEVEL_RANGE_AUDIT_2026-08-21.md, MIT license).
-- Faction and fishing skill as in LevelRange-Turtle. Keyed by the name the
-- map shows.
-- { min level, max level, faction, fishing skill }
-- faction: "A" Alliance, "H" Horde, "C" contested, nil unknown

local A, H, C = "A", "H", "C"

Explorer.Zones = {
  -- Eastern Kingdoms
  ["Elwynn Forest"] = { 1, 10, A, 25 },        ["Dun Morogh"] = { 1, 10, A, 25 },
  ["Tirisfal Glades"] = { 1, 10, H, 25 },      ["Loch Modan"] = { 10, 20, A, 75 },
  ["Silverpine Forest"] = { 10, 20, H, 75 },   ["Westfall"] = { 10, 20, A, 75 },
  ["Redridge Mountains"] = { 15, 25, C, 150 }, ["Duskwood"] = { 18, 30, C, 150 },
  ["Hillsbrad Foothills"] = { 20, 30, C, 150 }, ["Wetlands"] = { 20, 30, C, 150 },
  ["Alterac Mountains"] = { 30, 40, C, 225 },  ["Arathi Highlands"] = { 30, 40, C, 225 },
  ["Stranglethorn Vale"] = { 30, 45, C, 225 }, ["Badlands"] = { 35, 45, C },
  ["Swamp of Sorrows"] = { 35, 45, C, 225 },   ["The Hinterlands"] = { 40, 50, C, 300 },
  ["Searing Gorge"] = { 43, 50, C },           ["Blasted Lands"] = { 45, 55, C },
  ["Burning Steppes"] = { 50, 58, C },         ["Western Plaguelands"] = { 51, 58, C, 300 },
  ["Eastern Plaguelands"] = { 53, 60, C },     ["Deadwind Pass"] = { 55, 60, C },
  -- Kalimdor
  ["Durotar"] = { 1, 10, H, 25 },              ["Mulgore"] = { 1, 10, H, 25 },
  ["Teldrassil"] = { 1, 10, A, 25 },           ["Darkshore"] = { 10, 20, A, 75 },
  ["The Barrens"] = { 10, 25, H, 75 },         ["Stonetalon Mountains"] = { 15, 27, C, 150 },
  ["Ashenvale"] = { 18, 30, C, 150 },          ["Thousand Needles"] = { 25, 35, C, 225 },
  ["Desolace"] = { 30, 40, C, 225 },           ["Dustwallow Marsh"] = { 35, 45, C, 225 },
  ["Feralas"] = { 40, 50, C, 300 },            ["Tanaris"] = { 40, 50, C, 300 },
  ["Azshara"] = { 45, 55, C, 300 },            ["Felwood"] = { 48, 55, C, 300 },
  ["Un'Goro Crater"] = { 48, 55, C, 300 },     ["Silithus"] = { 55, 60, C },
  ["Winterspring"] = { 55, 60, C },            ["Moonglade"] = { 1, 60, C, 300 },
  -- OctoWoW zones
  ["Thalassian Highlands"] = { 1, 10, A },     ["Blackstone Island"] = { 1, 10, H },
  ["Northwind"] = { 28, 34, C },               ["Balor"] = { 29, 34, C },
  ["Grim Reaches"] = { 33, 38, C },            ["Gilneas"] = { 39, 46, C },
  ["Icepoint Rock"] = { 40, 50 },              ["Gillijim's Isle"] = { 48, 53, C },
  ["Lapidis Isle"] = { 48, 53, C },            ["Moonwhisper Coast"] = { 50, 56 },
  ["Tel'Abim"] = { 54, 60, C },                ["Scarlet Enclave"] = { 55, 60, C },
  ["Hyjal"] = { 58, 60, C },
}

-- capitals show the range of the zone around them
Explorer.ZoneAliases = {
  ["Stormwind City"] = "Elwynn Forest", ["Ironforge"] = "Dun Morogh",
  ["Undercity"] = "Tirisfal Glades",    ["Orgrimmar"] = "Durotar",
  ["Thunder Bluff"] = "Mulgore",        ["Darnassus"] = "Teldrassil",
  ["Alah'Thalas"] = "Thalassian Highlands",
}

-- the name the map shows, trimmed (OctoWoW writes "Northwind " with a space)
function Explorer.ZoneData(name)
  if not name then return nil end
  name = string.gsub(string.gsub(name, "^%s+", ""), "%s+$", "")
  local key = Explorer.ZoneAliases[name] or name
  return Explorer.Zones[key], name, key
end
