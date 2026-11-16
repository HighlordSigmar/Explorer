-- Explorer: a world map addon for OctoWoW (1.12 client, Lua 5.0)
-- Coordinates, mouse wheel zoom, retail-style markers for dungeons, raids,
-- world bosses and transports, and zone level ranges.
-- Lua 5.0: no "#" operator, no "%" operator, string.gfind instead of gmatch.

Explorer = Explorer or {}
local E = Explorer

E.version = "1.0.1"
E.TEXTURES = "Interface\\AddOns\\Explorer\\Textures\\"

-- features another loaded addon already provides are switched off here
E.blocked = {}

local DEFAULTS = {
  coords = true,          -- cursor and player coordinates under the map
  zoom = true,            -- mouse wheel zoom and drag to pan
  maxZoom = 3,
  keepZoom = true,        -- keep zoom and position when the map is closed
  arrow = true,           -- player arrow that follows the zoom
  arrowScale = 1,
  markers = true,
  iconScale = 1,
  show = { dungeon = true, raid = true, worldboss = true, boat = true, zeppelin = true, tram = true },
  transports = "mine",    -- "mine": your faction and neutral ones, "all"
  levels = true,          -- "Westfall (10-20)" when hovering a zone
  info = true,            -- zone info box (faction, dungeons, raids, fishing)
  infoFaction = true,
  infoInstances = true,
  infoRaids = true,
  infoBosses = true,
  infoFishing = true,
}
E.DEFAULTS = DEFAULTS

local function Fill(db, defaults)
  for k, v in pairs(defaults) do
    if db[k] == nil then
      if type(v) == "table" then
        db[k] = {}
        Fill(db[k], v)
      else
        db[k] = v
      end
    elseif type(v) == "table" and type(db[k]) == "table" then
      Fill(db[k], v)
    end
  end
end

function E.Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff7fd0ffExplorer|r: " .. msg)
end

----------------------------------------------------------------------------
-- colors

function E.Hex(c)
  return string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
end

local COLORS = {
  impossible = { r = 1, g = 0.1, b = 0.1 },
  verydifficult = { r = 1, g = 0.5, b = 0.25 },
  difficult = { r = 1, g = 1, b = 0 },
  standard = { r = 0.25, g = 0.75, b = 0.25 },
  trivial = { r = 0.5, g = 0.5, b = 0.5 },
}
E.COLORS = COLORS

-- the game's quest colors for a level, compared with yours
function E.LevelColor(level)
  local diff = level - (UnitLevel("player") or 1)
  local green = GetQuestGreenRange and GetQuestGreenRange() or 8
  if diff >= 5 then return COLORS.impossible end
  if diff >= 3 then return COLORS.verydifficult end
  if diff >= -2 then return COLORS.difficult end
  if -diff <= green then return COLORS.standard end
  return COLORS.trivial
end

-- color for a range: above you = its lowest level, inside = yellow,
-- outgrown = its top level
function E.RangeColor(min, max)
  local level = UnitLevel("player") or 1
  if level < min then return E.LevelColor(min) end
  if level > max then return E.LevelColor(max - 2) end
  return COLORS.difficult
end

function E.RangeText(min, max)
  if min == max then return tostring(min) end
  return min .. "-" .. max
end

----------------------------------------------------------------------------
-- maps

-- name of the zone the world map shows now, or nil (world / continent /
-- instance maps)
function E.MapZoneName()
  local c = GetCurrentMapContinent()
  local z = GetCurrentMapZone()
  if not c or not z or c < 1 or z < 1 then return nil, c end
  E.zoneNames = E.zoneNames or {}
  if not E.zoneNames[c] then E.zoneNames[c] = { GetMapZones(c) } end
  return E.zoneNames[c][z], c
end

-- index of a zone on its continent map, for SetMapZoom
function E.ZoneIndex(c, name)
  E.zoneNames = E.zoneNames or {}
  if not E.zoneNames[c] then E.zoneNames[c] = { GetMapZones(c) } end
  local list = E.zoneNames[c]
  for i = 1, table.getn(list) do
    if list[i] == name then return i end
  end
  return nil
end

----------------------------------------------------------------------------
-- hooks on the game's map code, shared by all parts of Explorer

local mapUpdaters = {}   -- every frame while the map is open
local mapChangers = {}   -- the map shows another zone / continent
local mapRefreshers = {} -- the game redrew the map (WORLD_MAP_UPDATE)
function E.OnMapUpdate(fn) table.insert(mapUpdaters, fn) end
function E.OnMapChange(fn) table.insert(mapChangers, fn) end
function E.OnMapRefresh(fn) table.insert(mapRefreshers, fn) end

local lastC, lastZ
local function HookMap()
  -- WorldMapFrame.xml calls WorldMapButton_OnUpdate by name every frame
  local oldUpdate = WorldMapButton_OnUpdate
  WorldMapButton_OnUpdate = function(a1)
    if oldUpdate then oldUpdate(a1) end
    for i = 1, table.getn(mapUpdaters) do mapUpdaters[i](a1) end
  end
  -- and WorldMapFrame_Update whenever the map changes
  local oldMapUpdate = WorldMapFrame_Update
  WorldMapFrame_Update = function(a1)
    if oldMapUpdate then oldMapUpdate(a1) end
    local c, z = GetCurrentMapContinent(), GetCurrentMapZone()
    if c ~= lastC or z ~= lastZ then
      lastC, lastZ = c, z
      for i = 1, table.getn(mapChangers) do mapChangers[i]() end
    end
    for i = 1, table.getn(mapRefreshers) do mapRefreshers[i]() end
  end
end

----------------------------------------------------------------------------
-- start up

-- addons that already do one of our jobs: that part of Explorer stays off
local CONFLICTS = {
  { "Magnify", "zoom", "mouse wheel zoom and coordinates" },
  { "ModernMapMarkers", "markers", "map markers" },
  { "LevelRange-Turtle", "info", "zone info box" },
  { "LevelRange", "info", "zone info box" },
}

local modules = {}
function E.Module(fn) table.insert(modules, fn) end

local f = CreateFrame("Frame")
f:RegisterEvent("VARIABLES_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function()
  if event == "VARIABLES_LOADED" then
    Explorer_DB = Explorer_DB or {}
    Fill(Explorer_DB, DEFAULTS)
    E.db = Explorer_DB
    local off = {}
    for i = 1, table.getn(CONFLICTS) do
      local c = CONFLICTS[i]
      if IsAddOnLoaded(c[1]) and not E.blocked[c[2]] then
        E.blocked[c[2]] = c[1]
        table.insert(off, c[1] .. " (Explorer's " .. c[3] .. " is off)")
      end
    end
    HookMap()
    for i = 1, table.getn(modules) do modules[i]() end
    if table.getn(off) > 0 then
      E.Print("these addons do the same job, turn them off to use Explorer's version: " .. table.concat(off, ", "))
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    if E.OnEnterWorld then E.OnEnterWorld() end
  end
end)

----------------------------------------------------------------------------
-- slash commands

local function Toggle(key, label)
  E.db[key] = not E.db[key]
  E.Print(label .. ": " .. (E.db[key] and "|cff40ff40on|r" or "|cffff4040off|r"))
  E.Apply()
end

-- every module registers how to re-apply its settings
E.appliers = {}
function E.Apply()
  for i = 1, table.getn(E.appliers) do E.appliers[i]() end
end

SLASH_EXPLORER1 = "/explorer"
SLASH_EXPLORER2 = "/expl"
SlashCmdList["EXPLORER"] = function(msg)
  msg = string.lower(msg or "")
  if msg == "" or msg == "options" then
    E.ToggleOptions()
  elseif msg == "coords" then
    Toggle("coords", "Coordinates")
  elseif msg == "zoom" then
    Toggle("zoom", "Mouse wheel zoom (takes effect after /reload)")
  elseif msg == "markers" then
    Toggle("markers", "Map markers")
  elseif msg == "levels" then
    Toggle("levels", "Zone level ranges")
  elseif msg == "info" then
    Toggle("info", "Zone info box")
  elseif msg == "transports" then
    E.db.transports = (E.db.transports == "all") and "mine" or "all"
    E.Print("Transports shown: " .. (E.db.transports == "all" and "all" or "your faction and neutral"))
    E.Apply()
  elseif msg == "reset" then
    if E.ResetZoom then E.ResetZoom() end
    E.Print("Map zoom reset.")
  else
    E.Print("/explorer - options window")
    E.Print("/explorer coords | zoom | markers | levels | info - turn a part on/off")
    E.Print("/explorer transports - your faction's transports or all of them")
    E.Print("/explorer reset - zoom the map back out")
  end
end
