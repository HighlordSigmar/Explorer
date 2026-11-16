-- Minimal mock of the 1.12 UI API, enough to load Explorer in Lua 5.0 and
-- drive the world map from tests. Run tests from the addon folder:
--   lua50 devkit/test_explorer.lua

LOG = {}
function log(s) table.insert(LOG, s) end

-- frames -----------------------------------------------------------------
local Frame = {}
local FIELDS = { parent = 1, name = 1, point = 1, text = 1, texture = 1, highlight = 1, owner = 1,
  lines = 1, left = 1, top = 1, hs = 1, vs = 1, child = 1, coords = 1, facing = 1, pin = 1,
  continent = 1, zoomed = 1, panning = 1, moved = 1, startX = 1, startY = 1, startH = 1, startV = 1,
  explorerArrow = 1, icon = 1, coordsFrame = 1, player = 1, coords = 1 }
local FrameMT = { __index = function(t, k)
  if Frame[k] then return Frame[k] end
  if FIELDS[k] or type(k) ~= "string" or string.find(k, "^%l") then return nil end
  return function() return nil end     -- unknown methods do nothing
end }

function NewFrame(kind, name, parent)
  local f = setmetatable({ kind = kind or "Frame", name = name, parent = parent, scripts = {},
    w = 0, h = 0, scale = 1, shown = true, level = 1, points = {}, text = nil, children = {} }, FrameMT)
  if parent and parent.children then table.insert(parent.children, f) end
  if name then setglobal(name, f) end
  return f
end

function Frame:SetScript(k, fn) self.scripts[k] = fn end
function Frame:GetScript(k) return self.scripts[k] end
function Frame:HookScript(k, fn) local o = self.scripts[k]; self.scripts[k] = function() if o then o() end fn() end end
function Frame:SetWidth(w) self.w = w end
function Frame:SetHeight(h) self.h = h end
function Frame:GetWidth() return self.w end
function Frame:GetHeight() return self.h end
function Frame:SetScale(s) self.scale = s end
function Frame:GetScale() return self.scale end
function Frame:GetEffectiveScale()
  local s, p = self.scale, self.parent
  while p do s = s * p.scale; p = p.parent end
  return s
end
function Frame:SetParent(p) self.parent = p end
function Frame:GetParent() return self.parent end
function Frame:Show() self.shown = true; if self.scripts.OnShow then local o = this; this = self; self.scripts.OnShow(); this = o end end
function Frame:Hide() local was = self.shown; self.shown = false; if was and self.scripts.OnHide then local o = this; this = self; self.scripts.OnHide(); this = o end end
function Frame:IsShown() return self.shown end
function Frame:IsVisible()
  local f = self
  while f do if not f.shown then return false end f = f.parent end
  return true
end
function Frame:SetPoint(a, rel, b, x, y) table.insert(self.points, { a, rel, b, x, y }) self.point = { a, rel, b, x, y } end
function Frame:ClearAllPoints() self.points = {}; self.point = nil end
function Frame:GetPoint() local p = self.point or {} return p[1], p[2], p[3], p[4], p[5] end
function Frame:SetFrameLevel(l) self.level = l end
function Frame:GetFrameLevel() return self.level end
function Frame:SetText(t) self.text = t end
function Frame:GetText() return self.text end
function Frame:SetTexture(t) self.texture = t end
function Frame:SetHighlightTexture(t) self.highlight = t end
function Frame:GetName() return self.name end
function Frame:GetFrameType() return self.kind end
function Frame:GetChildren() return unpack(self.children) end
function Frame:CreateTexture(name) return NewFrame("Texture", name, self) end
function Frame:CreateFontString(name) return NewFrame("FontString", name, self) end
function Frame:SetTexCoord(a, b, c, d, e, f, g, h) self.coords = { a, b, c, d, e, f, g, h } end
function Frame:GetLeft() return self.left or 0 end
function Frame:GetCenter() return (self.left or 0) + self.w / 2, (self.top or 0) - self.h / 2 end
function Frame:GetTop() return self.top or 0 end
function Frame:SetHorizontalScroll(v) self.hs = v end
function Frame:GetHorizontalScroll() return self.hs or 0 end
function Frame:SetVerticalScroll(v) self.vs = v end
function Frame:GetVerticalScroll() return self.vs or 0 end
function Frame:SetScrollChild(c) self.child = c; c.parent = self end
function Frame:SetOwner(o, a) self.owner = o; self.lines = {} end
function Frame:AddLine(t, r, g, b) table.insert(self.lines, t) end
function Frame:AddDoubleLine(l, r) table.insert(self.lines, l .. " | " .. r) end
function Frame:SetTextFrame(t) self.lines = { t } end
function Frame:GetFacing() return self.facing or 0 end

-- tooltips keep their lines
local oldSetText = Frame.SetText
function Frame:SetText(t, r, g, b)
  if self.kind == "GameTooltip" then self.lines = { t } end
  oldSetText(self, t)
end

function setglobal(k, v) getfenv(0)[k] = v end
function getglobal(k) return getfenv(0)[k] end

function CreateFrame(kind, name, parent, template)
  local f = NewFrame(kind, name, parent)
  if template == "UICheckButtonTemplate" or template == "OptionsSliderTemplate" then
    for _, s in ipairs({ "Text", "Low", "High" }) do NewFrame("FontString", name .. s, f) end
  end
  return f
end

-- game state ---------------------------------------------------------------
PLAYER_LEVEL = 15
PLAYER_FACTION = "Alliance"
MAP_C, MAP_Z = 2, 38       -- Westfall
PLAYER_X, PLAYER_Y = 0.5, 0.5
CURSOR_X, CURSOR_Y = 500, 400
LOADED = {}

function UnitLevel() return PLAYER_LEVEL end
function UnitFactionGroup() return PLAYER_FACTION, PLAYER_FACTION end
function GetQuestGreenRange() return 8 end
function GetCurrentMapContinent() return MAP_C end
function GetCurrentMapZone() return MAP_Z end
function SetMapZoom(c, z) log("SetMapZoom " .. tostring(c) .. " " .. tostring(z)); MAP_C, MAP_Z = c, z or 0; WorldMapFrame_Update() end
function GetPlayerMapPosition() return PLAYER_X, PLAYER_Y end
function GetCursorPosition() return CURSOR_X, CURSOR_Y end
function IsAddOnLoaded(n) return LOADED[n] end
function IsMouseButtonDown() return MOUSE_DOWN end
function IsControlKeyDown() return CTRL end
function IsShiftKeyDown() return SHIFT end
function MouseIsOver() return true end
function GetNumSkillLines() return 1 end
function GetSkillLineInfo(i) return "Fishing", nil, nil, FISHING or 1 end

dofile("devkit/zones.lua")
function GetMapZones(c) return unpack(ZONE_LIST[c] or {}) end

DEFAULT_CHAT_FRAME = { AddMessage = function(self, m) log("chat: " .. m) end }
UISpecialFrames = {}
SlashCmdList = {}

-- the game's world map frames
UIParent = NewFrame("Frame", "UIParent")
WorldMapFrame = NewFrame("Frame", "WorldMapFrame", UIParent)
WorldMapFrame.shown = false
WorldMapDetailFrame = NewFrame("Frame", "WorldMapDetailFrame", WorldMapFrame)
WorldMapDetailFrame.w, WorldMapDetailFrame.h = 1002, 668
WorldMapButton = NewFrame("Button", "WorldMapButton", WorldMapFrame)
WorldMapButton.w, WorldMapButton.h = 1002, 668
WorldMapPlayer = NewFrame("Frame", "WorldMapPlayer", WorldMapButton)
WorldMapPing = NewFrame("Model", "WorldMapPing", WorldMapFrame)
ARROW_MODEL = NewFrame("Model", nil, WorldMapFrame)
WorldMapFrameAreaFrame = NewFrame("Frame", "WorldMapFrameAreaFrame", WorldMapFrame)
WorldMapFrameAreaLabel = NewFrame("FontString", "WorldMapFrameAreaLabel", WorldMapFrameAreaFrame)
WorldMapTooltip = NewFrame("GameTooltip", "WorldMapTooltip", WorldMapFrame)

-- the game's map functions, as WorldMapFrame.lua has them
function WorldMapButton_OnUpdate(elapsed)
  if not WorldMapFrame.poiHighlight then WorldMapFrameAreaLabel:SetText(WorldMapFrame.areaName) end
end
function WorldMapFrame_Update() log("WorldMapFrame_Update") end
-- like the game's: the second argument is the button frame itself
function WorldMapButton_OnClick(mouseButton, button)
  if mouseButton == "LeftButton" then
    if not button then button = this end
    local x, y = GetCursorPosition()
    x = x / button:GetScale()
    y = y / button:GetScale()
    local cx, cy = button:GetCenter()
    local w, h = button:GetWidth(), button:GetHeight()
    log(string.format("ProcessMapClick %.3f %.3f", (x - (cx - w / 2)) / w, (cy + h / 2 - y) / h))
  else
    log("ZoomOut")
  end
end
WorldMapButton.scripts.OnClick = function() WorldMapButton_OnClick(arg1) end  -- the XML

-- run a script with this/arg1 set, like the game does
function Fire(frame, script, a1)
  local o, oa = this, arg1
  this, arg1 = frame, a1
  frame.scripts[script]()
  this, arg1 = o, oa
end

function Event(name)
  local o = event
  event = name
  for _, f in ipairs(EVENT_FRAMES) do Fire(f, "OnEvent") end
  event = o
end

-- every frame that registers events
EVENT_FRAMES = {}
function Frame:RegisterEvent() for _, f in ipairs(EVENT_FRAMES) do if f == self then return end end table.insert(EVENT_FRAMES, self) end

function LoadAddon(toc)
  for line in io.lines(toc) do
    if not string.find(line, "^#") and string.find(line, "%.lua%s*$") then
      dofile((string.gsub(line, "%s+$", "")))
    end
  end
end

function OpenMap()
  WorldMapFrame:Show()
  WorldMapFrame_Update()
end

function Tick(n)
  for i = 1, (n or 1) do
    local o, oa = this, arg1
    this, arg1 = WorldMapButton, 0.1
    WorldMapButton_OnUpdate(0.1)
    this, arg1 = o, oa
  end
end

function check(cond, msg)
  if cond then print("ok   " .. msg) else print("FAIL " .. msg); FAILED = (FAILED or 0) + 1 end
end
