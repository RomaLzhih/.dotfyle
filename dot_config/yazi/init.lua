-- ~/.config/yazi/init.lua

-- ya pkg add dedukun/relative-motions
require("relative-motions"):setup({ show_numbers = "relative", show_motion = true, enter_mode = "first" })

-- ya pkg add yazi-rs/plugins:full-border
require("full-border"):setup {
	type = ui.Border.ROUNDED,
}

-- Bookmarks
-- ya pack -a h-hg/yamb
local bookmarks = {}
local path_sep = package.config:sub(1, 1)
local home_path = ya.target_family() == "windows" and os.getenv("USERPROFILE") or os.getenv("HOME")
if ya.target_os() == "windows" then
	table.insert(bookmarks, {
		tag = "Dropbox",
		path = (home_path .. "/Users/ziyang/Library/CloudStorage/Dropbox") .. "\\",
		key = "p",
	})
elseif ya.target_os() == "linux" then
	table.insert(bookmarks, {
		tag = "Home",
		path = home_path .. path_sep,
		key = "h",
	})
elseif ya.target_os() == "macos" then
	table.insert(bookmarks, {
		tag = "Dropbox",
		path = home_path .. path_sep .. "Library/CloudStorage/Dropbox" .. path_sep,
		key = "d",
	})
	table.insert(bookmarks, {
		tag = "Download",
		path = home_path .. path_sep .. "Downloads" .. path_sep,
		key = "l",
	})
	table.insert(bookmarks, {
		tag = "Home",
		path = home_path .. path_sep,
		key = "h",
	})
	table.insert(bookmarks, {
		tag = "code",
		path = home_path .. path_sep .. "code" .. path_sep,
		key = "c",
	})
	table.insert(bookmarks, {
		tag = "paper",
		path = home_path .. path_sep .. "paper" .. path_sep,
		key = "p",
	})
	table.insert(bookmarks, {
		tag = "psi",
		path = home_path .. path_sep .. "code/SpatialTreeLib" .. path_sep,
		key = "s",
	})
end

require("yamb"):setup({
	-- Optional, the path ending with path seperator represents folder.
	bookmarks = bookmarks,
	-- Optional, recieve notification everytime you jump.
	jump_notify = true,
	-- Optional, the cli of fzf.
	cli = "fzf",
	-- Optional, the path of bookmarks
	path = (ya.target_family() == "windows" and os.getenv("APPDATA") .. "\\yazi\\config\\bookmark")
		or (os.getenv("HOME") .. "/.config/yazi/bookmark"),
})
