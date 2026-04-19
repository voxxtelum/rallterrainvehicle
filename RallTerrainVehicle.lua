local addon = LibStub("AceAddon-3.0"):NewAddon("RallTerrainVehicle", "AceEvent-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

local DURATION = 1800 -- 30 min

local timers = {}
local bars = {}

-- stupid cringe scope fix
addon.isDragging = false

-- defaults
local defaults = {
  profile = {
    width = 200,
    height = 20,
    fontSize = 12,
    font = "Friz Quadrata TT",
    texture = "Blizzard",
    color = { 1, 0.7, 0 },
    spacing = 2,
    x = 0,
    y = 0,
    anchorX = 0,
    anchorY = 0,
    sort = "time", -- "time" or "name"
    locked = true,
    excludedSubzones = {
      ["Browman Mill"] = true,
      ["Northdale"] = true,
      ["Eastwall Tower"] = true,
      ["Northpass Tower"] = true,
    },
  }
}

-- init
function addon:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("RallTerrainVehicleDB", defaults, true)

  local db = self.db.profile

  if not db.anchorX or not db.anchorY then
    db.anchorX = 0.5 * UIParent:GetWidth()
    db.anchorY = 0.5 * UIParent:GetHeight()
  end

  local AceConfig = LibStub("AceConfig-3.0")
  local AceConfigDialog = LibStub("AceConfigDialog-3.0")

  AceConfig:RegisterOptionsTable("RallTerrainVehicle", RallTerrainVehicleOptions)
  AceConfigDialog:AddToBlizOptions("RallTerrainVehicle", "RallTerrainVehicle")
end

function addon:OnEnable()
  self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

  self.frame = CreateFrame("Frame")
  self.frame:SetScript("OnUpdate", function()
    addon:UpdateBars()
  end)

  -- restore saved timers
  if self.db.global and self.db.global.timers then
    timers = self.db.global.timers
  end
end

-- mine event
function addon:UNIT_SPELLCAST_SUCCEEDED(event, unit, _, spellID)
  if unit ~= "player" then return end
  if spellID ~= 10248 then return end
  local zoneText = GetZoneText()
  if zoneText ~= "Eastern Plaguelands" then return end

  local now = GetTime()

  local subzone = GetSubZoneText()
  local zoneName

  if subzone and subzone ~= "" and not self.db.profile.excludedSubzones[subzone] then
    zoneName = subzone
  else
    local mapID = C_Map.GetBestMapForUnit("player")
    local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")

    if not pos then return end

    local x, y = pos.x, pos.y

    if x > 0.54 and x < 0.65 and y > 0.23 and y < 0.34 then
      zoneName = "ZM South"
    elseif x > 0.65 and x < 0.77 and y > 0.37 and y < 0.51 then
      zoneName = "Hill"
    elseif x > 0.66 and x < 0.78 and y > 0.25 and y < 0.36 then
      zoneName = "Northdale"
    else
      zoneName = string.format("Grid %d-%d",
        math.floor(x),
        math.floor(y)
      )
    end
  end

  timers[zoneName] = {
    startTime = now,
    isTest = false
  }
  self:SaveTimers()
end

-- save/load
function addon:SaveTimers()
  self.db.global = self.db.global or {}
  self.db.global.timers = timers
end

-- create bar
local function CreateBar(name)
  local bar = CreateFrame("StatusBar", nil, UIParent)

  bar:SetMovable(true)

  bar.isDragging = false

  local texture = LSM:Fetch("statusbar", addon.db.profile.texture, true)
  bar:SetStatusBarTexture(texture or "Interface\\TARGETINGFRAME\\UI-StatusBar")
  bar:SetMinMaxValues(0, DURATION)
  bar:SetValue(0)

  bar.bg = bar:CreateTexture(nil, "BACKGROUND")
  bar.bg:SetAllPoints(bar)
  bar.bg:SetColorTexture(0, 0, 0, 0.5)

  -- text
  bar.leftText = bar:CreateFontString(nil, "OVERLAY")
  bar.leftText:SetPoint("LEFT", bar, "LEFT", 4, 0)
  bar.leftText:SetJustifyH("LEFT")

  bar.rightText = bar:CreateFontString(nil, "OVERLAY")
  bar.rightText:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
  bar.rightText:SetJustifyH("RIGHT")

  -- mover
  bar.handle = CreateFrame("Frame", nil, bar)
  bar.handle:SetSize(16, 16)
  bar.handle:SetPoint("LEFT", bar, "LEFT", -18, 0)

  bar.handle:EnableMouse(true)
  bar.handle:RegisterForDrag("LeftButton")

  -- visual
  bar:SetOrientation("HORIZONTAL")
  bar.handle.texture = bar.handle:CreateTexture(nil, "OVERLAY")
  bar.handle.texture:SetAllPoints()
  bar.handle.texture:SetColorTexture(0, 0.7, 1, 0.8)

  bar.handle:Hide()

  -- drag logic
  bar.handle:SetScript("OnDragStart", function(self)
    if addon.db.profile.locked then return end
    addon.isDragging = true
    bar.isDragging = true
    bar:StartMoving()
  end)

  bar.handle:SetScript("OnDragStop", function(self)
    bar:StopMovingOrSizing()
    bar.isDragging = false
    addon.isDragging = false

    local scale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()

    -- convert to UI coordinates
    x = x / scale
    y = y / scale

    addon.db.profile.anchorX = x
    addon.db.profile.anchorY = y
  end)


  bars[name] = bar
  return bar
end

-- settings stuff
function addon:ApplySettings(bar, index)
  local db = self.db.profile

  bar:SetSize(db.width, db.height)
  --bar:SetStatusBarTexture(LSM:Fetch("statusbar", db.texture))
  bar:SetStatusBarColor(unpack(db.color))

  bar.leftText:SetFont(LSM:Fetch("font", db.font), db.fontSize)
  bar.rightText:SetFont(LSM:Fetch("font", db.font), db.fontSize)

  if not addon.isDragging then
    bar:ClearAllPoints()
    bar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT",
      db.anchorX,
      db.anchorY - ((index - 1) * (db.height + db.spacing))
    )
  end

  if index == 1 and not db.locked then
    bar.handle:Show()
  else
    bar.handle:Hide()
  end
end

-- sorting
local function SortTimers()
  local sorted = {}

  for zone, data in pairs(timers) do
    table.insert(sorted, {
      zone = zone,
      startTime = data.startTime,
      isTest = data.isTest
    })
  end

  table.sort(sorted, function(a, b)
    local mode = addon.db.profile.sort

    if mode == "name" then
      return a.zone < b.zone
    else
      -- sort by time remaining
      local now = GetTime()

      local remainingA = DURATION - (now - a.startTime)
      local remainingB = DURATION - (now - b.startTime)

      return remainingA < remainingB
    end
  end)

  return sorted
end

-- test bars
function addon:SpawnTestBars()
  local now = GetTime()

  for i = 1, 4 do
    local name = "Test " .. i

    timers[name] = {
      startTime = now - (i * 300),
      isTest = true
    }
  end
end

function addon:ClearTestBars()
  for name, data in pairs(timers) do
    if data.isTest then
      timers[name] = nil

      if bars[name] then
        bars[name]:Hide()
      end
    end
  end
end

function addon:ResetPosition()
  local db = self.db.profile

  db.anchorX = 0.5 * UIParent:GetWidth()
  db.anchorY = 0.5 * UIParent:GetHeight()

  self:UpdateBars()
end

-- update loop
function addon:UpdateBars()
  if addon.isDragging then
    return
  end

  local db = self.db.profile
  local now = GetTime()
  local index = 1

  local sorted = SortTimers()

  for _, data in ipairs(sorted) do
    local zone = data.zone
    local startTime = data.startTime

    local elapsed = (now - startTime)

    if elapsed >= DURATION then
      timers[zone] = nil
      if bars[zone] then bars[zone]:Hide() end
    else
      local bar = bars[zone] or CreateBar(zone)

      self:ApplySettings(bar, index)

      local m = math.floor(elapsed / 60)
      local s = math.floor(elapsed % 60)

      --bar.leftText:SetText(math.floor(elapsed) .. " - " .. DURATION)
      bar.leftText:SetText(zone)
      bar.leftText:SetWidth(db.width * 0.6)
      bar.leftText:SetWordWrap(false)
      bar.leftText:SetMaxLines(1)

      bar.rightText:SetText(string.format("%d:%02d", m, s))

      bar:SetValue(elapsed)

      bar:Show()
      index = index + 1
    end
  end
end

-- refresh
function addon:RefreshBars()
  local db = self.db.profile
  for i, bar in pairs(bars) do
    local texture = LSM:Fetch("statusbar", db.texture, true)
    bar:SetStatusBarTexture(texture or "Interface\\TARGETINGFRAME\\UI-StatusBar")

    self:ApplySettings(bar, i)
  end
end

-- slash commands
SLASH_RALLTERRAINVEHICLE1 = "/rtv"
SlashCmdList["RALLTERRAINVEHICLE"] = function()
  LibStub("AceConfigDialog-3.0"):Open("RallTerrainVehicle")
end
