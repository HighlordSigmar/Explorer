-- Explorer options window (/explorer)

local E = Explorer
local panel
local refreshers = {}
local count = 0
local refreshing = false

-- settings are addressed by path, e.g. "show.dungeon"
local function Get(path)
  local t, last = E.db, nil
  for part in string.gfind(path, "[^%.]+") do
    if last then t = t[last] end
    last = part
  end
  return t[last]
end

local function Set(path, value)
  local t, last = E.db, nil
  for part in string.gfind(path, "[^%.]+") do
    if last then t = t[last] end
    last = part
  end
  t[last] = value
end

local function NextName(kind)
  count = count + 1
  return "ExplorerOpt" .. kind .. count
end

local function Header(parent, label, x, y)
  local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  fs:SetText(label)
  local line = parent:CreateTexture(nil, "ARTWORK")
  line:SetTexture(1, 0.82, 0, 0.25)
  line:SetHeight(1)
  line:SetWidth(250)
  line:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, -3)
end

local function Check(parent, label, key, x, y, note)
  local name = NextName("Check")
  local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
  cb:SetWidth(24); cb:SetHeight(24)
  cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  getglobal(name .. "Text"):SetText(label)
  cb:SetScript("OnClick", function()
    Set(key, this:GetChecked() and true or false)
    if note then E.Print(note) end
    E.Apply()
  end)
  table.insert(refreshers, function() cb:SetChecked(Get(key) and 1 or nil) end)
end

local function Slider(parent, label, key, minv, maxv, step, x, y)
  local name = NextName("Slider")
  local s = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
  s:SetWidth(230)
  s:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  s:SetMinMaxValues(minv, maxv)
  s:SetValueStep(step)
  getglobal(name .. "Low"):SetText(minv)
  getglobal(name .. "High"):SetText(maxv)
  local title = getglobal(name .. "Text")
  local function show(v) title:SetText(label .. ": " .. string.format("%.2f", v)) end
  s:SetScript("OnValueChanged", function()
    if refreshing then show(Get(key)); return end
    local v = math.floor(this:GetValue() / step + 0.5) * step
    show(v)
    if Get(key) ~= v then
      Set(key, v)
      E.Apply()
    end
  end)
  table.insert(refreshers, function() s:SetValue(Get(key)); show(Get(key)) end)
end

local function Cycle(parent, label, key, options, x, y)
  local b = CreateFrame("Button", NextName("Cycle"), parent, "UIPanelButtonTemplate")
  b:SetWidth(230); b:SetHeight(22)
  b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  local function index()
    for i = 1, table.getn(options) do
      if options[i][1] == Get(key) then return i end
    end
    return 1
  end
  local function refresh() b:SetText(label .. ": " .. options[index()][2]) end
  b:SetScript("OnClick", function()
    local i = index() + 1
    if i > table.getn(options) then i = 1 end
    Set(key, options[i][1])
    refresh()
    E.Apply()
  end)
  table.insert(refreshers, refresh)
end

local function Refresh()
  refreshing = true
  for i = 1, table.getn(refreshers) do refreshers[i]() end
  refreshing = false
end

local function Build()
  panel = CreateFrame("Frame", "ExplorerOptions", UIParent)
  panel:SetWidth(580); panel:SetHeight(440)
  panel:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
  panel:SetFrameStrata("DIALOG")
  panel:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })
  panel:EnableMouse(true)
  panel:SetMovable(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetScript("OnDragStart", function() this:StartMoving() end)
  panel:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  table.insert(UISpecialFrames, "ExplorerOptions")   -- Escape closes it

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
  title:SetPoint("TOP", panel, "TOP", 0, -18)
  title:SetText("|cff7fd0ffExplorer|r " .. E.version)
  local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -6, -6)

  -- left column: map and markers
  local x = 24
  Header(panel, "Map", x, -50)
  Check(panel, "Cursor and player coordinates", "coords", x, -70)
  Check(panel, "Mouse wheel zoom, drag to pan", "zoom", x, -94, "Zoom: takes effect after /reload")
  Check(panel, "Keep the zoom when closing the map", "keepZoom", x, -118)
  Slider(panel, "Most zoom", "maxZoom", 1.5, 5, 0.25, x + 4, -160)
  Slider(panel, "Player arrow size", "arrowScale", 0.5, 2, 0.1, x + 4, -200)

  Header(panel, "Markers", x, -234)
  Check(panel, "Show markers on zone maps", "markers", x, -254)
  Check(panel, "Dungeons", "show.dungeon", x + 16, -276)
  Check(panel, "Raids", "show.raid", x + 136, -276)
  Check(panel, "World bosses", "show.worldboss", x + 16, -298)
  Check(panel, "Boats", "show.boat", x + 136, -298)
  Check(panel, "Zeppelins", "show.zeppelin", x + 16, -320)
  Check(panel, "Tram", "show.tram", x + 136, -320)
  Cycle(panel, "Transports", "transports",
    { { "mine", "your faction" }, { "all", "all of them" } }, x + 4, -348)
  Slider(panel, "Marker size", "iconScale", 0.5, 2, 0.1, x + 4, -394)

  -- right column: zones
  x = 300
  Header(panel, "Zones (continent map)", x, -50)
  Check(panel, "Level range after the zone name", "levels", x, -70)
  Check(panel, "Zone info box", "info", x, -94)
  Check(panel, "Friendly / hostile / contested", "infoFaction", x + 16, -116)
  Check(panel, "Dungeons and their levels", "infoInstances", x + 16, -138)
  Check(panel, "Raids", "infoRaids", x + 16, -160)
  Check(panel, "World bosses", "infoBosses", x + 16, -182)
  Check(panel, "Fishing skill needed", "infoFishing", x + 16, -204)

  local help = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  help:SetPoint("TOPLEFT", panel, "TOPLEFT", x, -240)
  help:SetWidth(250)
  help:SetJustifyH("LEFT")
  help:SetText("Mouse wheel over the map: zoom in and out.\n" ..
    "Drag the zoomed map to move it.\n\n" ..
    "Click a dungeon or raid marker to open its map. " ..
    "With InstanceJournal, right-click opens its journal page.\n\n" ..
    "Hover a zone on the continent map to see its levels and what is in it.")
  panel:Hide()
end

function E.ToggleOptions()
  if not E.db then return end
  if not panel then Build() end
  if panel:IsShown() then
    panel:Hide()
  else
    Refresh()
    panel:Show()
  end
end
