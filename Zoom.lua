-- Explorer: zoom the world map with the mouse wheel, drag it to pan
--
-- The zoom works like Magnify by lookino (MIT license, see CREDITS.txt):
-- the map picture goes inside a scroll frame, the wheel scales it around
-- the cursor and dragging moves it. The game's 3D player arrow cannot
-- follow that, so it is replaced by a flat arrow that turns with you.

local E = Explorer

local STEP = 1.25          -- each wheel notch zooms in or out by 25%
local scroll               -- ExplorerScrollFrame
local playerModel          -- the game's arrow, hidden while we draw ours
local active = false

E.baseZoom = 1             -- map scale when zoomed out (0.7 in the small map)

local function Detail() return WorldMapDetailFrame end

local function Clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

-- how far the map can scroll at this scale, in map units
local function Limits(scale)
  local maxX = (Detail():GetWidth() * scale - scroll:GetWidth()) / scale
  local maxY = (Detail():GetHeight() * scale - scroll:GetHeight()) / scale
  if maxX < 0 then maxX = 0 end
  if maxY < 0 then maxY = 0 end
  return maxX, maxY
end

local function ZoomChanged()
  if E.OnZoom then E.OnZoom() end
end

function E.ResetZoom()
  if not active then return end
  Detail():SetScale(E.baseZoom)
  scroll:SetHorizontalScroll(0)
  scroll:SetVerticalScroll(0)
  scroll.zoomed = false
  ZoomChanged()
end

-- how much bigger than "zoomed out" the map is now
function E.ZoomFactor()
  if not active then return 1 end
  return Detail():GetScale() / E.baseZoom
end

local function OnWheel()
  -- Ctrl / Shift + wheel stay ShaguTweaks' (map window size / transparency)
  if IsControlKeyDown() or IsShiftKeyDown() then
    local other = WorldMapFrame:GetScript("OnMouseWheel")
    if other then
      local o = this
      this = WorldMapFrame
      other()
      this = o
    end
    return
  end
  local oldH, oldV = scroll:GetHorizontalScroll(), scroll:GetVerticalScroll()
  local x, y = GetCursorPosition()
  local eff = scroll:GetEffectiveScale()
  local frameX = x / eff - scroll:GetLeft()
  local frameY = scroll:GetTop() - y / eff

  local old = Detail():GetScale()
  local new = (arg1 > 0) and old * STEP or old / STEP
  new = Clamp(new, E.baseZoom, E.baseZoom * (E.db.maxZoom or 3))
  if math.abs(new - E.baseZoom) < 0.01 then new = E.baseZoom end
  if new == old then return end
  Detail():SetScale(new)

  -- keep the spot under the cursor under the cursor
  local maxX, maxY = Limits(new)
  local spotX = -oldH + frameX / old
  local spotY = oldV + frameY / old
  local h = Clamp(spotX - frameX / new, 0, maxX)
  local v = Clamp(spotY - frameY / new, 0, maxY)
  scroll:SetHorizontalScroll(-h)
  scroll:SetVerticalScroll(v)
  scroll.zoomed = new > E.baseZoom
  ZoomChanged()
end

local function OnMouseDown()
  if arg1 == "LeftButton" and scroll.zoomed then
    local x, y = GetCursorPosition()
    scroll.panning = true
    scroll.moved = false
    scroll.startX, scroll.startY = x, y
    scroll.startH, scroll.startV = scroll:GetHorizontalScroll(), scroll:GetVerticalScroll()
  end
end

local function OnMouseUp()
  local wasMoved = scroll.moved
  scroll.panning = false
  scroll.moved = false
  if not wasMoved then
    -- a plain click: the map does what it always does (open a zone, zoom out)
    WorldMapButton_OnClick(arg1, "WorldMapButton")
  end
end

local function OnUpdate()
  if not scroll.panning then return end
  if not IsMouseButtonDown("LeftButton") then scroll.panning = false return end
  local x, y = GetCursorPosition()
  local eff = Detail():GetEffectiveScale()   -- screen pixels per map unit
  local dX = (scroll.startX - x) / eff
  local dY = (y - scroll.startY) / eff
  if math.abs(dX) >= 1 or math.abs(dY) >= 1 then scroll.moved = true end
  if scroll.moved then
    local maxX, maxY = Limits(Detail():GetScale())
    scroll:SetHorizontalScroll(-Clamp(dX - scroll.startH, 0, maxX))
    scroll:SetVerticalScroll(Clamp(dY + scroll.startV, 0, maxY))
  end
end

----------------------------------------------------------------------------
-- layout for the big and the small (windowed) map, and for ShaguTweaks'
-- map window

local function Layout()
  local windowed = (WORLDMAP_WINDOWED == 1)
  local x, y
  if windowed then
    E.baseZoom = 0.7
    scroll:SetWidth(702)
    scroll:SetHeight(468)
    x, y = 2, -24
  else
    E.baseZoom = 1
    scroll:SetWidth(1002)
    scroll:SetHeight(668)
    x, y = 0, -70
  end
  if IsAddOnLoaded("ShaguTweaks") then
    x = 0
    if windowed and ShaguTweaks_config and ShaguTweaks_config["WorldMap Window"] == 1 then
      y = -24
    else
      y = -48
    end
  end
  scroll:ClearAllPoints()
  scroll:SetPoint("TOP", WorldMapFrame, "TOP", x, y)
  scroll:SetScrollChild(Detail())
  WorldMapButton:SetScale(1)

  -- the zone name stays at the top of the map, not on the moving picture
  WorldMapFrameAreaFrame:SetParent(WorldMapFrame)
  WorldMapFrameAreaFrame:ClearAllPoints()
  WorldMapFrameAreaFrame:SetPoint("TOP", WorldMapFrame, "TOP", 0, windowed and -15 or -60)
  WorldMapFrameAreaFrame:SetFrameStrata("FULLSCREEN_DIALOG")

  -- ShaguTweaks-extras' "reveal map" checkbox
  local reveal = getglobal("shagutweaks_mapreveal_onmap")
  if reveal then
    reveal:SetParent(WorldMapFrame)
    reveal:SetFrameStrata("FULLSCREEN_DIALOG")
    reveal:ClearAllPoints()
    reveal:SetPoint("TOPLEFT", scroll, "TOPLEFT", 1, 19)
  end

  E.ResetZoom()
  if E.OnLayout then E.OnLayout() end
end
E.MapLayout = Layout

----------------------------------------------------------------------------
-- player arrow

local function SetupArrow()
  -- the game's arrow model is an unnamed Model on the map frame
  local children = { WorldMapFrame:GetChildren() }
  for i = 1, table.getn(children) do
    local v = children[i]
    if v:GetFrameType() == "Model" and not v:GetName() then
      playerModel = v
      v:SetScript("OnShow", function() this:Hide() end)
      v:Hide()
      break
    end
  end
  if WorldMapPing then
    WorldMapPing.Show = function() end
    WorldMapPing:Hide()
  end
  local icon = WorldMapPlayer:CreateTexture("ExplorerPlayerArrow", "OVERLAY")
  icon:SetTexture(E.TEXTURES .. "arrow")
  icon:SetPoint("CENTER", WorldMapPlayer, "CENTER", 0, 0)
  WorldMapPlayer.explorerArrow = icon
  WorldMapPlayer:SetFrameLevel(WorldMapButton:GetFrameLevel() + 20)
end

-- turning a square texture: corners of the picture for the facing
-- (see wowwiki "SetTexCoord Transformations")
local function TurnArrow(icon, r)
  local s = math.sqrt(2)
  local pi = math.pi
  local ULx, ULy = 0.5 + math.cos(r + 1.25 * pi) / s, 0.5 + math.sin(r + 1.25 * pi) / s
  local LLx, LLy = 0.5 + math.cos(r + 0.75 * pi) / s, 0.5 + math.sin(r + 0.75 * pi) / s
  local URx, URy = 0.5 + math.cos(r - 0.25 * pi) / s, 0.5 + math.sin(r - 0.25 * pi) / s
  local LRx, LRy = 0.5 + math.cos(r + 0.25 * pi) / s, 0.5 + math.sin(r + 0.25 * pi) / s
  icon:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
end

local function UpdateArrow()
  local icon = WorldMapPlayer.explorerArrow
  if not icon then return end
  local x, y = GetPlayerMapPosition("player")
  if not x or (x == 0 and y == 0) then
    icon:Hide()
    return
  end
  icon:Show()
  WorldMapPlayer:ClearAllPoints()
  WorldMapPlayer:SetPoint("CENTER", WorldMapButton, "TOPLEFT",
    x * WorldMapButton:GetWidth(), -y * WorldMapButton:GetHeight())
  -- same size on screen at any zoom
  local size = 24 * (E.db.arrowScale or 1) / E.ZoomFactor()
  icon:SetWidth(size)
  icon:SetHeight(size)
  if playerModel and playerModel.GetFacing then
    TurnArrow(icon, playerModel:GetFacing() or 0)
  end
end

----------------------------------------------------------------------------

E.Module(function()
  if not E.db.zoom or E.blocked.zoom then return end
  if not WorldMapDetailFrame or not WorldMapButton or not WorldMapFrame then return end
  active = true

  scroll = CreateFrame("ScrollFrame", "ExplorerScrollFrame", WorldMapFrame)
  -- level 1: above the map button (0), below every map pin, so that
  -- InstanceJournal's pins and ours can still be clicked
  scroll:SetFrameLevel(1)
  scroll:EnableMouse(true)
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", OnWheel)
  scroll:SetScript("OnMouseDown", OnMouseDown)
  scroll:SetScript("OnMouseUp", OnMouseUp)
  scroll:SetScript("OnUpdate", OnUpdate)
  E.scroll = scroll

  WorldMapButton:SetParent(Detail())
  WorldMapButton:SetFrameLevel(0)

  -- the small and big map buttons (OctoWoW)
  if WorldMapFrame_Minimize then
    local oldMin = WorldMapFrame_Minimize
    WorldMapFrame_Minimize = function(a1, a2)
      oldMin(a1, a2)
      Layout()
    end
  end
  if WorldMapFrame_Maximize then
    local oldMax = WorldMapFrame_Maximize
    WorldMapFrame_Maximize = function(a1, a2)
      oldMax(a1, a2)
      Layout()
    end
  end
  if WORLDMAP_WINDOWED and WorldMapFrame_Minimize and WorldMapFrame_Maximize then
    if WORLDMAP_WINDOWED == 1 then WorldMapFrame_Minimize() else WorldMapFrame_Maximize() end
  else
    Layout()
  end

  if E.db.arrow then
    SetupArrow()
    E.OnMapUpdate(UpdateArrow)
  end

  local oldHide = WorldMapFrame:GetScript("OnHide")
  WorldMapFrame:SetScript("OnHide", function()
    if oldHide then oldHide() end
    scroll.panning = false
    if not E.db.keepZoom then E.ResetZoom() end
  end)

  -- a different map (another zone, continent...) starts zoomed out
  E.OnMapChange(function() E.ResetZoom() end)
end)

-- ShaguTweaks sets up its map window when you enter the world: lay out again
local oldEnter = E.OnEnterWorld
E.OnEnterWorld = function()
  if oldEnter then oldEnter() end
  if active then Layout() end
end
