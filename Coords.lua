-- Explorer: cursor and player coordinates under the world map

local E = Explorer
local frame, cursorText, playerText
local elapsed = 0

local LABEL = "|cffffd100%s:|r %s"

local function Position()
  if not frame then return end
  local area = E.scroll or WorldMapDetailFrame
  local y = (WORLDMAP_WINDOWED == 1) and -20 or -24
  frame:ClearAllPoints()
  frame:SetPoint("TOPLEFT", area, "BOTTOMLEFT", 10, y + 18)
  frame:SetPoint("TOPRIGHT", area, "BOTTOMRIGHT", -10, y + 18)
end

-- ShaguTweaks has its own coordinates in the same spot
local function HideShagu()
  local b = WorldMapButton
  if b.coords then b.coords:SetScript("OnUpdate", nil); b.coords:Hide() end
  if b.player then b.player:SetScript("OnUpdate", nil); b.player:Hide() end
end

local function Update()
  elapsed = elapsed + (arg1 or 0)
  if elapsed < 0.05 then return end
  elapsed = 0

  -- cursor, on the map picture (it follows the zoom)
  local area = E.scroll or WorldMapButton
  local text = "-"
  if MouseIsOver(area) then
    local b = WorldMapButton
    local x, y = GetCursorPosition()
    local scale = b:GetEffectiveScale()
    local left, top = b:GetLeft(), b:GetTop()
    if left and top then
      local cx = (x / scale - left) / b:GetWidth()
      local cy = (top - y / scale) / b:GetHeight()
      if cx >= 0 and cx <= 1 and cy >= 0 and cy <= 1 then
        text = string.format("%.1f, %.1f", cx * 100, cy * 100)
      end
    end
  end
  cursorText:SetText(string.format(LABEL, "Cursor", text))

  local px, py = GetPlayerMapPosition("player")
  if px and py and (px > 0 or py > 0) then
    playerText:SetText(string.format(LABEL, "Player", string.format("%.1f, %.1f", px * 100, py * 100)))
  else
    playerText:SetText(string.format(LABEL, "Player", "-"))
  end
end

local function Apply()
  if not frame then return end
  if E.db.coords and not E.blocked.zoom then
    frame:Show()
    HideShagu()
  else
    frame:Hide()
  end
end
table.insert(E.appliers, Apply)

E.Module(function()
  if E.blocked.zoom then return end   -- Magnify shows coordinates already
  frame = CreateFrame("Frame", "ExplorerCoords", WorldMapFrame)
  frame:SetHeight(18)
  frame:SetFrameStrata("FULLSCREEN_DIALOG")
  cursorText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  cursorText:SetPoint("LEFT", frame, "LEFT", 0, 0)
  playerText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  playerText:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
  frame:SetScript("OnUpdate", Update)
  frame:SetScript("OnShow", HideShagu)
  Position()
  Apply()

  local oldLayout = E.OnLayout
  E.OnLayout = function()
    if oldLayout then oldLayout() end
    Position()
  end
  local oldEnter = E.OnEnterWorld
  E.OnEnterWorld = function()
    if oldEnter then oldEnter() end
    Apply()
  end
end)
