-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Font settings
config.font = wezterm.font 'Fira Code'
config.font_size = 14
config.font_shaper = "Harfbuzz"
config.font_rules={
    {
      font=wezterm.font("Fira Code Medium", {
        -- you can override the default bold text color with this
        -- foreground="tomato",
      })
    },
    {
      intensity="Bold",
      font=wezterm.font("Fira Code Bold", {
        -- you can override the default bold text color with this
        -- foreground="tomato",
      })
    },
    {
      italic=true,
      font=wezterm.font("Source Code Pro Medium Italic", {
        -- you can override the default bold text color with this
        -- foreground="tomato",
      })
    },
  }

-- For example, changing the color scheme:
config.color_scheme = 'Dracula'

-- and finally, return the configuration to wezterm
return config
