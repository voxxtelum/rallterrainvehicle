local addon = LibStub("AceAddon-3.0"):GetAddon("RallTerrainVehicle")
local LSM = LibStub("LibSharedMedia-3.0")
local options = {
  name = "RallTerrainVehicle",
  type = "group",
  args = {
    general = {
      type = "group",
      name = "General",
      order = 1,
      args = {
        lock = {
          type = "toggle",
          name = "Lock Position",
          desc = "Unlock to move bars using the drag handle",
          order = 0,
          get = function() return addon.db.profile.locked end,
          set = function(_, val)
            addon.db.profile.locked = val
            addon:RefreshBars()
          end,
        },
        testBars = {
          type = "execute",
          name = "Spawn Test Bars",
          order = 99,
          func = function()
            addon:SpawnTestBars()
          end,
        },
        clearTest = {
          type = "execute",
          name = "Clear Test Bars",
          order = 100,
          func = function()
            addon:ClearTestBars()
          end,
        },
        resetPosition = {
          type = "execute",
          name = "Reset Position",
          desc = "Moves bars back to screen center",
          order = 101,
          func = function()
            addon:ResetPosition()
          end,
        },
        width = {
          type = "range",
          name = "Bar Width",
          min = 100,
          max = 400,
          step = 10,
          order = 1,
          get = function() return addon.db.profile.width end,
          set = function(_, val)
            addon.db.profile.width = val
            addon:RefreshBars()
          end,
        },

        height = {
          type = "range",
          name = "Bar Height",
          min = 10,
          max = 50,
          step = 1,
          order = 2,
          get = function() return addon.db.profile.height end,
          set = function(_, val)
            addon.db.profile.height = val
            addon:RefreshBars()
          end,
        },

        spacing = {
          type = "range",
          name = "Bar Spacing",
          min = 0,
          max = 20,
          step = 1,
          order = 3,
          get = function() return addon.db.profile.spacing end,
          set = function(_, val)
            addon.db.profile.spacing = val
            addon:RefreshBars()
          end,
        },

        fontSize = {
          type = "range",
          name = "Font Size",
          min = 8,
          max = 24,
          step = 1,
          order = 4,
          get = function() return addon.db.profile.fontSize end,
          set = function(_, val)
            addon.db.profile.fontSize = val
            addon:RefreshBars()
          end,
        },

        color = {
          type = "color",
          name = "Bar Color",
          order = 5,
          get = function()
            local c = addon.db.profile.color
            return c[1], c[2], c[3]
          end,
          set = function(_, r, g, b)
            addon.db.profile.color = { r, g, b }
            addon:RefreshBars()
          end,
        },
      },

    },

    appearance = {
      type = "group",
      name = "Appearance",
      order = 2,
      args = {

        font = {
          type = "select",
          dialogControl = "LSM30_Font",
          name = "Font",
          order = 1,
          values = LSM:HashTable("font"),
          get = function() return addon.db.profile.font end,
          set = function(_, val)
            addon.db.profile.font = val
            addon:RefreshBars()
          end,
        },

        texture = {
          type = "select",
          dialogControl = "LSM30_Statusbar",
          name = "Bar Texture",
          order = 2,
          values = LSM:HashTable("statusbar"),
          get = function() return addon.db.profile.texture end,
          set = function(_, val)
            addon.db.profile.texture = val
            addon:RefreshBars()
          end,
        },
      },
    },

    sorting = {
      type = "group",
      name = "Sorting",
      order = 3,
      args = {

        sort = {
          type = "select",
          name = "Sort By",
          order = 1,
          values = {
            time = "Time Remaining",
            name = "Zone Name",
          },
          get = function() return addon.db.profile.sort end,
          set = function(_, val)
            addon.db.profile.sort = val
          end,
        },
      },
    },
  },
}

_G.RallTerrainVehicleOptions = options
