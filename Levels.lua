-- Explorer: zone level ranges and the zone info box
--
-- Hover a zone on the continent map: its name gets its level range, like
-- retail ("Westfall (10-20)"), colored for your level: red/orange while it
-- is above you, yellow while you are in it, green/gray once you outgrew it.
-- A box in the corner of the map adds what LevelRange showed: whose
-- territory it is, its dungeons, raids and world bosses with their levels,
-- and the fishing skill the zone needs.

local E = Explorer
local tip
local lastName, lastLevel

local TERRITORY = {
  friendly = { "Friendly territory", 0.25, 1, 0.25 },
  hostile = { "Hostile territory", 1, 0.25, 0.25 },
  contested = { "Contested territory", 1, 0.7, 0.2 },
}

-- " (10-20)" in the colors of your level
function E.ZoneRangeText(name)
  local z = E.ZoneData(name)
  if not z then return nil end
  local c = E.RangeColor(z[1], z[2])
  return " " .. E.Hex(c) .. "(" .. E.RangeText(z[1], z[2]) .. ")|r"
end

local function FishingSkill()
  for i = 1, (GetNumSkillLines and GetNumSkillLines() or 0) do
    local name, header, _, rank = GetSkillLineInfo(i)
    if not header and name == "Fishing" then return rank end
  end
  return nil
end

-- dungeons, raids and world bosses of a zone, from the map markers
local function ZoneContent(c, name)
  local dungeons, raids, bosses, seen = {}, {}, {}, {}
  local list = E.InstancePins[c] and E.InstancePins[c][name]
  if not list then return dungeons, raids, bosses end
  for i = 1, table.getn(list) do
    local p = list[i]
    local ids = p.ids or (p.id and { p.id }) or {}
    for j = 1, table.getn(ids) do
      local id = ids[j]
      local inst = E.Instances[id]
      if inst and not seen[id] then
        seen[id] = true
        table.insert(inst[2] == "raid" and raids or dungeons, inst)
      end
    end
    if p[3] == "worldboss" then table.insert(bosses, p.name) end
  end
  local byLevel = function(a, b) return a[3] < b[3] or (a[3] == b[3] and a[1] < b[1]) end
  table.sort(dungeons, byLevel)
  table.sort(raids, byLevel)
  table.sort(bosses)
  return dungeons, raids, bosses
end

local function AddList(title, list)
  if table.getn(list) == 0 then return end
  tip:AddLine(" ")
  tip:AddLine(title, 1, 0.82, 0)
  for i = 1, table.getn(list) do
    local inst = list[i]
    local c = E.RangeColor(inst[3], inst[4])
    tip:AddDoubleLine("  " .. inst[1], E.RangeText(inst[3], inst[4]), 1, 1, 1, c.r, c.g, c.b)
  end
end

local function ShowInfo(name, c)
  local z, shownName = E.ZoneData(name)
  local dungeons, raids, bosses = ZoneContent(c, shownName)
  if not z and table.getn(dungeons) == 0 and table.getn(raids) == 0 then
    tip:Hide()
    return
  end
  tip:SetOwner(WorldMapFrame, "ANCHOR_NONE")
  tip:SetText(shownName, 1, 1, 1)
  if z then
    local col = E.RangeColor(z[1], z[2])
    tip:AddLine("Level " .. E.RangeText(z[1], z[2]), col.r, col.g, col.b)
    if E.db.infoFaction and z[3] then
      local t
      if z[3] == "C" then
        t = TERRITORY.contested
      elseif (z[3] == "A") == (UnitFactionGroup("player") == "Alliance") then
        t = TERRITORY.friendly
      else
        t = TERRITORY.hostile
      end
      tip:AddLine(t[1], t[2], t[3], t[4])
    end
    if E.db.infoFishing and z[4] then
      local skill = FishingSkill()
      local r, g, b = 0.8, 0.8, 0.8
      if skill then
        if skill >= z[4] then r, g, b = 0.25, 1, 0.25 else r, g, b = 1, 0.25, 0.25 end
      end
      tip:AddLine("Fishing skill " .. z[4], r, g, b)
    end
  end
  if E.db.infoInstances then AddList("Dungeons", dungeons) end
  if E.db.infoRaids then AddList("Raids", raids) end
  if E.db.infoBosses and table.getn(bosses) > 0 then
    tip:AddLine(" ")
    tip:AddLine("World bosses", 1, 0.82, 0)
    for i = 1, table.getn(bosses) do tip:AddLine("  " .. bosses[i], 1, 1, 1) end
  end
  tip:ClearAllPoints()
  tip:SetPoint("BOTTOMLEFT", E.scroll or WorldMapDetailFrame, "BOTTOMLEFT", 8, 8)
  tip:Show()
end

local function Update()
  local name = WorldMapFrame.areaName
  local onContinent = GetCurrentMapZone() == 0 and GetCurrentMapContinent() > 0
  local hovering = name and name ~= "" and not WorldMapFrame.poiHighlight

  -- the range after the zone's name
  if E.db.levels and hovering then
    local text = E.ZoneRangeText(name)
    if text then
      local _, trimmed = E.ZoneData(name)
      WorldMapFrameAreaLabel:SetText(trimmed .. text)
    end
  end

  -- the info box, rebuilt only when something changed
  if not tip then return end
  if not (E.db.info and hovering and onContinent) then
    if tip:IsShown() then tip:Hide() end
    lastName = nil
    return
  end
  local level = UnitLevel("player")
  if name == lastName and level == lastLevel and tip:IsShown() then return end
  lastName, lastLevel = name, level
  ShowInfo(name, GetCurrentMapContinent())
end

table.insert(E.appliers, function()
  lastName = nil
  if tip and not E.db.info then tip:Hide() end
end)

E.Module(function()
  if not E.blocked.info then
    tip = CreateFrame("GameTooltip", "ExplorerZoneInfo", WorldMapFrame, "GameTooltipTemplate")
    tip:SetFrameStrata("TOOLTIP")
  end
  E.OnMapUpdate(Update)
  local oldHide = WorldMapFrame:GetScript("OnHide")
  WorldMapFrame:SetScript("OnHide", function()
    if oldHide then oldHide() end
    if tip then tip:Hide() end
    lastName = nil
  end)
end)
