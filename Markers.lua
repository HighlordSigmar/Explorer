-- Explorer: dungeon, raid, world boss and transport markers on zone maps
--
-- Click a dungeon or raid to open its map (Blackrock Mountain, Dire Maul and
-- the other places with several instances open their own map first).
-- With InstanceJournal installed, right-click opens its journal page, and
-- InstanceJournal's own entrance pins are left out where Explorer has one.

local E = Explorer
local pins = {}
local shown = 0

local SIZE = { dungeon = 26, raid = 26, worldboss = 24, boat = 22, zeppelin = 22, tram = 22 }
local KIND_NAME = { dungeon = "Dungeon", raid = "Raid", worldboss = "World boss",
  boat = "Boat", zeppelin = "Zeppelin", tram = "Tram" }
local FACTION_COLOR = { A = { r = 0.3, g = 0.6, b = 1 }, H = { r = 1, g = 0.25, b = 0.25 },
  N = { r = 1, g = 1, b = 1 } }
local FACTION_NAME = { A = "Alliance", H = "Horde", N = "Neutral" }

local function IJ() return IJDB and IJLib and IJDB.DG and IJDB.R end

local function IJInstance(id)
  if not IJ() or not id then return nil end
  return IJDB.DG[id] or IJDB.R[id]
end

----------------------------------------------------------------------------
-- tooltip

local function AddInstance(tip, id)
  local inst = E.Instances[id]
  if not inst then return end
  local c = E.RangeColor(inst[3], inst[4])
  tip:AddDoubleLine(inst[1], E.RangeText(inst[3], inst[4]), 1, 1, 1, c.r, c.g, c.b)
end

local function OnEnter()
  local p = this.pin
  local tip = WorldMapTooltip
  tip:SetOwner(this, "ANCHOR_RIGHT")
  local kind = p[3]
  if p.poi then
    tip:AddLine(p.poi, 1, 0.82, 0)
    for i = 1, table.getn(p.ids) do AddInstance(tip, p.ids[i]) end
    tip:AddLine("Click: open map", 0.6, 0.6, 0.6)
  elseif p.id then
    local inst = E.Instances[p.id]
    tip:AddLine(inst[1], 1, 0.82, 0)
    local c = E.RangeColor(inst[3], inst[4])
    tip:AddDoubleLine(KIND_NAME[inst[2]], "Level " .. E.RangeText(inst[3], inst[4]), 1, 1, 1, c.r, c.g, c.b)
    tip:AddLine("Click: open map", 0.6, 0.6, 0.6)
    if IJInstance(p.id) then tip:AddLine("Right-click: Instance Journal", 0.6, 0.6, 0.6) end
  elseif kind == "worldboss" then
    tip:AddLine(p.name, 1, 0.82, 0)
    local c = E.LevelColor(60)
    tip:AddDoubleLine("World boss", "Level 60", 1, 1, 1, c.r, c.g, c.b)
  else
    tip:AddLine(KIND_NAME[kind] .. " to " .. p[4], 1, 0.82, 0)
    local c = FACTION_COLOR[p[5]] or FACTION_COLOR.N
    tip:AddLine(FACTION_NAME[p[5]] or "", c.r, c.g, c.b)
  end
  tip:Show()
end

local function OnLeave()
  WorldMapTooltip:Hide()
end

local function OnClick()
  local p = this.pin
  WorldMapTooltip:Hide()
  if arg1 == "RightButton" then
    local inst = IJInstance(p.id)
    if inst and IJ_InstanceJournalFrame and IJ_ShowEncounter then
      if not IJ_InstanceJournalFrame:IsShown() then IJ_InstanceJournalFrame:Show() end
      IJ_ShowRaids = (inst.Type == IJLib.InstanceType.Raid)
      if PanelTemplates_SetTab then
        PanelTemplates_SetTab(IJ_InstanceJournalFrame, IJ_ShowRaids and 2 or 1)
      end
      IJ_ShowEncounter(inst)
      WorldMapFrame:Hide()
    else
      WorldMapButton_OnClick("RightButton")   -- zoom out, as usual
    end
    return
  end
  if p.poi then
    local c = this.continent
    local z = E.ZoneIndex(c, p.poi)
    if z then SetMapZoom(c, z) end
  elseif p.id then
    local inst = E.Instances[p.id]
    if inst and inst[5] and inst[5] > 0 then SetMapZoom(inst[5], p.floor or 1) end
  end
end

----------------------------------------------------------------------------
-- pins

local function GetPin(i)
  if pins[i] then return pins[i] end
  local b = CreateFrame("Button", "ExplorerPin" .. i, WorldMapButton)
  b:SetFrameLevel(WorldMapButton:GetFrameLevel() + 6)
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetAllPoints(b)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:SetScript("OnEnter", OnEnter)
  b:SetScript("OnLeave", OnLeave)
  b:SetScript("OnClick", OnClick)
  pins[i] = b
  return b
end

local function Wanted(kind, faction)
  if not E.db.show[kind] then return false end
  if faction and E.db.transports ~= "all" and faction ~= "N" then
    local mine = UnitFactionGroup("player")
    if FACTION_NAME[faction] ~= mine then return false end
  end
  return true
end

local function Place(b, p)
  local w, h = WorldMapButton:GetWidth(), WorldMapButton:GetHeight()
  local size = (SIZE[p[3]] or 22) * (E.db.iconScale or 1) / E.ZoomFactor()
  b:SetWidth(size)
  b:SetHeight(size)
  b:ClearAllPoints()
  b:SetPoint("CENTER", WorldMapButton, "TOPLEFT", p[1] / 100 * w, -p[2] / 100 * h)
end

local function Show(list, c)
  if not list then return end
  for i = 1, table.getn(list) do
    local p = list[i]
    if Wanted(p[3], p[5]) then
      shown = shown + 1
      local b = GetPin(shown)
      b.pin = p
      b.continent = c
      b.icon:SetTexture(E.TEXTURES .. p[3])
      b:SetHighlightTexture(E.TEXTURES .. p[3] .. "-highlight")
      Place(b, p)
      b:Show()
    end
  end
end

function E.RefreshMarkers()
  shown = 0
  if E.db.markers and not E.blocked.markers and WorldMapFrame:IsVisible() then
    local zone, c = E.MapZoneName()
    if zone then
      Show(E.InstancePins[c] and E.InstancePins[c][zone], c)
      Show(E.TransportPins[c] and E.TransportPins[c][zone], c)
    end
  end
  for i = shown + 1, table.getn(pins) do pins[i]:Hide() end
end

local function Resize()
  for i = 1, shown do Place(pins[i], pins[i].pin) end
end

-- InstanceJournal draws its own entrance pins; leave them out on the maps
-- where Explorer has markers (its boss pins inside instances stay)
local function HookIJ()
  local function covered()
    if not E.db.markers or not (E.db.show.dungeon or E.db.show.raid) then return false end
    local zone, c = E.MapZoneName()
    return zone and E.InstancePins[c] and E.InstancePins[c][zone] and true
  end
  if IJ_ShowInstanceEntrancesIcon then
    local old = IJ_ShowInstanceEntrancesIcon
    IJ_ShowInstanceEntrancesIcon = function(instance)
      if covered() then return end
      return old(instance)
    end
  end
  if IJ_ShowPOIEntrancesIcon then
    local old = IJ_ShowPOIEntrancesIcon
    IJ_ShowPOIEntrancesIcon = function(poi)
      if covered() then return end
      return old(poi)
    end
  end
end

table.insert(E.appliers, function() if E.RefreshMarkers then E.RefreshMarkers() end end)

E.Module(function()
  if E.blocked.markers then return end
  HookIJ()
  E.OnMapRefresh(E.RefreshMarkers)
  local oldZoom = E.OnZoom
  E.OnZoom = function()
    if oldZoom then oldZoom() end
    Resize()
  end
  local oldShow = WorldMapFrame:GetScript("OnShow")
  WorldMapFrame:SetScript("OnShow", function()
    if oldShow then oldShow() end
    E.RefreshMarkers()
  end)
end)
