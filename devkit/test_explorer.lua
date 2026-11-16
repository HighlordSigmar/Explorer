-- Loads Explorer with the mocked map and checks each feature.
-- Run from the addon folder: lua50 devkit/test_explorer.lua

dofile("devkit/harness.lua")
LOADED = { ShaguTweaks = true, InstanceJournal = true }
ShaguTweaks_config = { ["WorldMap Window"] = 1 }
WORLDMAP_WINDOWED = 0
function WorldMapFrame_Minimize() log("game minimize") end
function WorldMapFrame_Maximize() log("game maximize") end
-- ShaguTweaks' coordinates
WorldMapButton.coords = NewFrame("Frame", nil, WorldMapButton)
WorldMapButton.player = NewFrame("Frame", nil, WorldMapButton)
-- InstanceJournal's pins
IJ_PINS = 0
function IJ_ShowInstanceEntrancesIcon() IJ_PINS = IJ_PINS + 1 end
function IJ_ShowPOIEntrancesIcon() IJ_PINS = IJ_PINS + 1 end
IJLib = { InstanceType = { Raid = "Raid", Dungeon = "Dungeon" } }
IJDB = { DG = { DEADMINES = { Name = "The Deadmines", Type = "Dungeon" } }, R = {} }
IJ_InstanceJournalFrame = NewFrame("Frame", "IJ_InstanceJournalFrame", UIParent)
IJ_InstanceJournalFrame.shown = false
function IJ_ShowEncounter(inst) log("IJ page " .. inst.Name) end

LoadAddon("Explorer.toc")
Event("VARIABLES_LOADED")
Event("PLAYER_ENTERING_WORLD")
local E = Explorer

print("== start up")
check(E.db and E.db.zoom == true, "settings filled with defaults")
check(ExplorerScrollFrame ~= nil, "scroll frame made")
check(ExplorerScrollFrame.child == WorldMapDetailFrame, "map picture is the scroll child")
check(WorldMapButton.parent == WorldMapDetailFrame, "map button moves with the picture")
local p = ExplorerScrollFrame.point
check(p and p[4] == 0 and p[5] == -48, "big map under ShaguTweaks window: TOP 0,-48 (got " .. tostring(p and p[5]) .. ")")
check(ExplorerScrollFrame.w == 1002 and E.baseZoom == 1, "big map size and zoom")
check(ARROW_MODEL.shown == false, "game arrow model hidden")
check(ExplorerPlayerArrow ~= nil, "own arrow made")

print("== small map")
WORLDMAP_WINDOWED = 1
WorldMapFrame_Minimize()
check(ExplorerScrollFrame.w == 702 and E.baseZoom == 0.7, "small map 702 wide, zoom 0.7")
check(ExplorerScrollFrame.point[5] == -24, "small map in ShaguTweaks window: TOP -24")
check(WorldMapDetailFrame.scale == 0.7, "picture at 0.7")
WORLDMAP_WINDOWED = 0
WorldMapFrame_Maximize()
check(WorldMapDetailFrame.scale == 1, "back to the big map at 1")

print("== markers in Westfall")
OpenMap()
check(ExplorerPin1 and ExplorerPin1.shown, "a pin is shown")
check(ExplorerPin1.pin.poi == "The Deadmines", "it is the Deadmines")
check(ExplorerPin1.icon.texture == "Interface\\AddOns\\InstanceJournal\\media\\ui\\dungeon-icon", "InstanceJournal's dungeon icon (" .. tostring(ExplorerPin1.icon.texture) .. ")")
this = ExplorerPin1; Fire(ExplorerPin1, "OnEnter")
check(ExplorerPin1.icon.texture == "Interface\\AddOns\\InstanceJournal\\media\\ui\\dungeon-icon-selected", "hovered icon")
Fire(ExplorerPin1, "OnLeave")
check(ExplorerPin1.icon.texture == "Interface\\AddOns\\InstanceJournal\\media\\ui\\dungeon-icon", "back after hover")
check(ExplorerPin1.point[4] == 0.425 * 1002, "placed at 42.5% across")
check(not ExplorerPin2 or not ExplorerPin2.shown, "only one pin in Westfall")
IJ_PINS = 0
IJ_ShowPOIEntrancesIcon({})
check(IJ_PINS == 0, "InstanceJournal's own pin is left out in Westfall")

this = ExplorerPin1; Fire(ExplorerPin1, "OnEnter")
print("   tooltip: " .. table.concat(WorldMapTooltip.lines, " / "))
check(WorldMapTooltip.lines[2] and string.find(WorldMapTooltip.lines[2], "The Deadmines | 16%-24"), "tooltip lists the dungeon and its levels")
LOG = {}
Fire(ExplorerPin1, "OnClick", "LeftButton")
check(MAP_C == 2 and MAP_Z == 32, "click opens The Deadmines map (2:32), got " .. MAP_C .. ":" .. MAP_Z)
check(ExplorerPin1.shown and ExplorerPin1.pin.id == "DEADMINES", "the Deadmines map shows the entrance")
Fire(ExplorerPin1, "OnClick", "LeftButton")
check(MAP_C == 21, "click on the entrance opens the instance map (21)")
check(not ExplorerPin1.shown, "no pins on the instance map")
MAP_C, MAP_Z = 2, 32; WorldMapFrame_Update()
LOG = {}
Fire(ExplorerPin1, "OnClick", "RightButton")
check(LOG[1] == "IJ page The Deadmines", "right-click opens InstanceJournal")
IJ_ShowEncounter = nil
LOG = {}
Fire(ExplorerPin1, "OnClick", "RightButton")
check(LOG[1] == "ZoomOut", "without InstanceJournal right-click on a marker zooms out")

print("== transports")
MAP_C, MAP_Z = 2, 28; WorldMapFrame:Show(); WorldMapFrame_Update()  -- Stormwind City
local kinds = {}
for i = 1, 10 do local b = getglobal("ExplorerPin" .. i) if b and b.shown then kinds[b.pin[3] .. (b.pin.id or b.pin[4] or "")] = true end end
check(kinds["dungeonSTOCKADES"] and kinds["dungeonSV"] and kinds["tramIronforge"] and kinds["boatAuberdine"], "Stormwind: Stockade, Vault, tram, boat")
MAP_C, MAP_Z = 1, 9; WorldMapFrame_Update()   -- Durotar, Horde transports
local n = 0
for i = 1, 10 do local b = getglobal("ExplorerPin" .. i) if b and b.shown then n = n + 1 end end
check(n == 0, "Alliance player: no Horde zeppelins in Durotar")
E.db.transports = "all"; E.Apply()
n = 0
for i = 1, 10 do local b = getglobal("ExplorerPin" .. i) if b and b.shown then n = n + 1 end end
check(n == 3, "all transports: 3 in Durotar (got " .. n .. ")")
E.db.transports = "mine"

print("== zoom")
MAP_C, MAP_Z = 2, 38; WorldMapFrame_Update()
local S = ExplorerScrollFrame
local B = WorldMapButton
check(S.scripts.OnMouseWheel == nil and B.scripts.OnMouseWheel ~= nil, "the wheel is on the map button, the scroll frame takes no mouse")
check(B.level == 2 and ExplorerPin1.level == 8, "map button under the pins")
S.left, S.top = 0, 668
CURSOR_X, CURSOR_Y = 501, 334        -- middle of the map
Fire(B, "OnMouseWheel", 1)
check(math.abs(WorldMapDetailFrame.scale - 1.25) < 0.001, "wheel up zooms to 1.25")
check(S.zoomed, "zoomed")
print(string.format("   scroll after zoom at the middle: h=%.1f v=%.1f", S.hs, S.vs))
check(math.abs(-S.hs - (501 - 501 / 1.25)) < 0.01, "zoomed around the cursor (horizontal)")
check(math.abs(ExplorerPin1.w - 26 / 1.25) < 0.01, "markers keep their size on screen")
for i = 1, 20 do Fire(B, "OnMouseWheel", 1) end
check(math.abs(WorldMapDetailFrame.scale - 3) < 0.001, "zoom stops at the most zoom (3)")
for i = 1, 20 do Fire(B, "OnMouseWheel", -1) end
check(WorldMapDetailFrame.scale == 1 and not S.zoomed, "zoomed all the way out")
check(S.hs == 0 and S.vs == 0, "and scrolled back to the corner")
local shagu = 0
WorldMapFrame:SetScript("OnMouseWheel", function() if this == WorldMapFrame then shagu = shagu + arg1 end end)
CTRL = true; Fire(B, "OnMouseWheel", 1); CTRL = nil
check(shagu == 1 and WorldMapDetailFrame.scale == 1, "Ctrl + wheel goes to ShaguTweaks' map window, no zoom")

print("== clicks")
B.left, B.top = 0, 668
CURSOR_X, CURSOR_Y = 250.5, 334
LOG = {}
Fire(B, "OnMouseDown", "LeftButton"); Fire(B, "OnMouseUp", "LeftButton"); Fire(B, "OnClick", "LeftButton")
check(LOG[1] == "ProcessMapClick 0.250 0.500", "not zoomed: the game's own click (" .. tostring(LOG[1]) .. ")")
LOG = {}
Fire(B, "OnClick", "RightButton")
check(LOG[1] == "ZoomOut", "right-click zooms the map out")
Fire(B, "OnMouseWheel", 1)
CURSOR_X, CURSOR_Y = 250.5 * 1.25, 334 * 1.25   -- same spot on the picture, drawn 25% bigger
LOG = {}
Fire(B, "OnMouseDown", "LeftButton"); Fire(B, "OnMouseUp", "LeftButton"); Fire(B, "OnClick", "LeftButton")
check(LOG[1] == "ProcessMapClick 0.250 0.500", "zoomed: the click lands on the same spot (" .. tostring(LOG[1]) .. ")")

print("== panning")
local h0 = S.hs
MOUSE_DOWN = true
Fire(B, "OnMouseDown", "LeftButton")
CURSOR_X = CURSOR_X - 100
Fire(S, "OnUpdate")
check(S.moved and S.hs < h0, "dragging left moves the map left")
MOUSE_DOWN = false
LOG = {}
Fire(B, "OnMouseUp", "LeftButton"); Fire(B, "OnClick", "LeftButton")
check(LOG[1] == nil, "the click ending a drag does nothing")
Fire(B, "OnMouseDown", "LeftButton"); Fire(B, "OnMouseUp", "LeftButton"); Fire(B, "OnClick", "LeftButton")
check(LOG[1] ~= nil and string.find(LOG[1], "ProcessMapClick"), "the next plain click works")
MAP_C, MAP_Z = 2, 13; WorldMapFrame_Update()
check(WorldMapDetailFrame.scale == 1, "another map starts zoomed out")

print("== coordinates")
WorldMapButton.left, WorldMapButton.top = 0, 668
CURSOR_X, CURSOR_Y = 250.5, 334
PLAYER_X, PLAYER_Y = 0.421, 0.73
Fire(ExplorerCoords, "OnUpdate", 0.1)
local kids = { ExplorerCoords:GetChildren() }
print("   " .. tostring(kids[1].text) .. "   " .. tostring(kids[2].text))
check(string.find(kids[1].text, "25.0, 50.0"), "cursor coordinates")
check(string.find(kids[2].text, "42.1, 73.0"), "player coordinates")
check(not WorldMapButton.coords.shown, "ShaguTweaks' coordinates hidden")

print("== level ranges and zone info")
MAP_C, MAP_Z = 2, 0; WorldMapFrame_Update()
WorldMapFrame.areaName = "Westfall"
PLAYER_LEVEL = 15
Tick()
check(WorldMapFrameAreaLabel.text == "Westfall |cffffff00(10-20)|r", "label: " .. WorldMapFrameAreaLabel.text)
PLAYER_LEVEL = 5; Tick()
check(string.find(WorldMapFrameAreaLabel.text, "|cffff1919%(10%-20%)"), "above you: red")
PLAYER_LEVEL = 30; Tick()
check(string.find(WorldMapFrameAreaLabel.text, "|cff7f7f7f%(10%-20%)"), "outgrown: gray")
PLAYER_LEVEL = 15; FISHING = 80
WorldMapFrame.areaName = "Burning Steppes"; Tick()
print("   info box: " .. table.concat(ExplorerZoneInfo.lines, " / "))
check(ExplorerZoneInfo.shown, "info box shown")
check(ExplorerZoneInfo.lines[3] == "Contested territory", "contested")
local txt = table.concat(ExplorerZoneInfo.lines, "\n")
check(string.find(txt, "Blackrock Depths") and string.find(txt, "Hateforge Quarry") and string.find(txt, "Molten Core"), "its dungeons and raids")
WorldMapFrame.areaName = "Westfall"; Tick()
txt = table.concat(ExplorerZoneInfo.lines, "\n")
check(string.find(txt, "Friendly territory") and string.find(txt, "Fishing skill 75") and string.find(txt, "The Deadmines"), "Westfall: friendly, fishing 75, Deadmines")
WorldMapFrame.areaName = "Northwind "; Tick()
check(WorldMapFrameAreaLabel.text == "Northwind |cffff1919(28-34)|r", "trailing space in Northwind handled: " .. WorldMapFrameAreaLabel.text)
WorldMapFrame.areaName = "Stormwind City"; Tick()
check(string.find(WorldMapFrameAreaLabel.text, "%(1%-10%)"), "capital shows its zone's range")
WorldMapFrame.poiHighlight = 1; WorldMapFrameAreaLabel.text = "Some place"; Tick()
check(WorldMapFrameAreaLabel.text == "Some place", "hovering a map marker leaves the label alone")
WorldMapFrame.poiHighlight = nil
E.db.levels = false; Tick()
check(WorldMapFrameAreaLabel.text == "Stormwind City", "levels off")
E.db.levels = true
MAP_C, MAP_Z = 2, 38; WorldMapFrame_Update(); WorldMapFrame.areaName = "Westfall"; Tick()
check(not ExplorerZoneInfo.shown, "no info box on a zone map")

print("== arrow")
PLAYER_X, PLAYER_Y = 0.5, 0.25
ARROW_MODEL.facing = 0
Tick()
check(ExplorerPlayerArrow.shown ~= false and WorldMapPlayer.point[4] == 501, "arrow on the player")
check(ExplorerPlayerArrow.coords ~= nil, "arrow turned")

print("== icons")
INSTALLED.ModernMapMarkers = true    -- folder there, addon turned off
E.Apply()
check(ExplorerPin1.icon.texture == "Interface\\AddOns\\ModernMapMarkers\\Textures\\dungeon", "ModernMapMarkers' icons when its folder is there, even turned off")
check(not E.blocked.markers, "a turned-off ModernMapMarkers does not stop Explorer's markers")
SlashCmdList.EXPLORER("icons")
check(ExplorerPin1.icon.texture == "Interface\\AddOns\\Explorer\\Textures\\dungeon", "/explorer icons: Explorer's own")
SlashCmdList.EXPLORER("icons")
INSTALLED.ModernMapMarkers = nil
E.Apply()

print("== options and commands")
SlashCmdList.EXPLORER("")
check(ExplorerOptions and ExplorerOptions.shown, "options window opens")
SlashCmdList.EXPLORER("markers")
check(E.db.markers == false, "/explorer markers turns them off")
MAP_C, MAP_Z = 2, 38; WorldMapFrame_Update()
check(not ExplorerPin1.shown, "pins hidden")
SlashCmdList.EXPLORER("markers")

print("== Magnify and ModernMapMarkers installed")
ExplorerScrollFrame = nil
dofile("devkit/harness.lua")
LOADED = { Magnify = true, ModernMapMarkers = true }
Explorer = nil
LoadAddon("Explorer.toc")
Event("VARIABLES_LOADED")
check(ExplorerScrollFrame == nil, "no zoom with Magnify")
check(Explorer.blocked.markers == "ModernMapMarkers", "no markers with ModernMapMarkers")
local said = false
for _, l in ipairs(LOG) do if string.find(l, "Magnify") then said = true end end
check(said, "tells you which addons do the same job")


print("== data")
dofile("devkit/zones.lua")
local known = {}
for c = 1, 2 do for _, z in ipairs(ZONE_LIST[c]) do known[c .. z] = true end end
local bad = {}
for _, set in ipairs({ Explorer.InstancePins, Explorer.TransportPins }) do
  for c, zones in pairs(set) do
    for z, list in pairs(zones) do
      if not known[c .. z] then table.insert(bad, c .. ":" .. z) end
      for _, p in ipairs(list) do
        if p[1] < 0 or p[1] > 100 or p[2] < 0 or p[2] > 100 then table.insert(bad, z .. " coords") end
        if p.id and not Explorer.Instances[p.id] then table.insert(bad, "id " .. p.id) end
        if p.poi and not known[c .. p.poi] then table.insert(bad, "poi " .. p.poi) end
      end
    end
  end
end
for z in pairs(Explorer.Zones) do
  if not known["1" .. z] and not known["2" .. z] then table.insert(bad, "zone " .. z) end
end
check(table.getn(bad) == 0, "every zone, sub-map and instance in the data exists: " .. table.concat(bad, ", "))
print(FAILED and (FAILED .. " FAILED") or "ALL PASSED")
