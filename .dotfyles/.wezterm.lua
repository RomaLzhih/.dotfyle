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

-- config.color_scheme = "Kanagawa (Gogh)"
-- config.color_scheme = "Gruvbox Dark (Gogh)"
config.color_scheme = "Rosé Pine (base16)"
-- config.color_scheme = "nord"

config.font = wezterm.font({
	-- family = "Carto Lisa",
	-- family = "JetBrainsMono NF",
	family = "MonoLisa Nerd Font",
	harfbuzz_features = {
		"liga",
		"ss02",
		"ss03", -- alter g
		-- "ss04", -- alter g
		"ss07",
		"ss11",
		"ss12",
		"ss14",
	},
})
-- local italic_font = "CartographCF Nerd Font"
local italic_font = "Maple Mono NF"
config.font_rules = {
	{
		intensity = "Bold",
		italic = true,
		font = wezterm.font({
			family = italic_font,
			weight = "Bold",
			style = "Italic",
		}),
	},
	{
		italic = true,
		intensity = "Half",
		font = wezterm.font({
			family = italic_font,
			weight = "DemiBold",
			style = "Italic",
		}),
	},
	{
		italic = true,
		intensity = "Normal",
		font = wezterm.font({
			family = italic_font,
			weight = "Regular",
			style = "Italic",
		}),
	},
}
config.font_size = 12

config.animation_fps = 60
config.default_cursor_style = "BlinkingBlock"
-- config.default_prog = { "powershell" }
-- config.default_cwd = "D:\\papers\\kdtree-paper"
-- config.default_cwd = "C:\\Users\\res0luti0n\\Dropbox\\"
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
