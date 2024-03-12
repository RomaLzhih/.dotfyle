-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- This is where you actually apply your config choices
config.color_scheme = "Rosé Pine (base16)"
-- config.color_scheme = "Gruvbox Dark (Gogh)"
-- config.color_scheme = "Tokyo Night"

-- config.font = wezterm.font("Maple Mono NF")
-- config.font_size = 11.5
-- config.line_height = 0.95

-- config.font = wezterm.font({
-- 	family = "CartographCF Nerd Font",
-- 	harfbuzz_features = {
-- 		"liga",
-- 		"ss02",
-- 	},
-- })
-- config.font_size = 12
-- config.line_height = 1

config.font = wezterm.font({
	family = "Carto Lisa",
	-- family = "Mono Lisa Nerd Font",
	-- family = "JetBrains Mono Nerd Font",
	harfbuzz_features = {
		"liga",
		"ss02",
	},
})
config.font_size = 11
config.line_height = 1

-- config.font = wezterm.font({
-- 	family = "MonoLisa Nerd Font",
-- 	harfbuzz_features = {
-- 		"liga",
-- 		"ss01",
-- 		"ss02",
-- 		-- "ss03", -- alter g
-- 		"ss07",
-- 		"ss11",
-- 		"ss12",
-- 		"ss14",
-- 	},
-- })
-- config.font_size = 11
-- config.line_height = 1

-- config.font = wezterm.font("DankMono Nerd Font")
-- config.font_size = 12.5
-- config.font = wezterm.font("SFMono Nerd Font Mono")
-- config.font = wezterm.font("SauceCodePro Nerd Font")
-- config.font = wezterm.font("Recursive")
--
config.animation_fps = 60
config.default_cursor_style = "BlinkingBlock"
config.max_fps = 120
config.window_padding = {
	left = 1.5,
	right = 1.5,
	top = 0,
	bottom = 0,
}

config.mouse_bindings = {
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = wezterm.action_callback(function(window, pane)
			local has_selection = window:get_selection_text_for_pane(pane) ~= ""
			if has_selection then
				window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
				window:perform_action(act.ClearSelection, pane)
			else
				window:perform_action(act({ PasteFrom = "Clipboard" }), pane)
			end
		end),
	},
}

return config
