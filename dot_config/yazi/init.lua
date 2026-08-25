-- ~/.config/yazi/init.lua

-- ya pkg add dedukun/relative-motions
-- ya pkg add yazi-rs/plugins:full-border
-- ya pkg add h-hg/yamb

-- require("relative-motions"):setup({ show_numbers = "relative", show_motion = true, enter_mode = "first" })

require("full-border"):setup({
	type = ui.Border.ROUNDED,
})

-- Bookmarks
local bookmarks = {}
local path_sep = package.config:sub(1, 1)
local home_path = ya.target_family() == "windows" and os.getenv("USERPROFILE") or os.getenv("HOME")

-- Detect whether the current Linux distro is Ubuntu via /etc/os-release.
local function is_ubuntu()
	local f = io.open("/etc/os-release", "r")
	if not f then
		return false
	end
	local content = f:read("*a")
	f:close()
	for line in content:gmatch("[^\n]+") do
		if line == "ID=ubuntu" or line == 'ID="ubuntu"' then
			return true
		end
	end
	return false
end

-- macOS bookmark set. Fully independent from the Ubuntu set below;
-- edit these freely without affecting any other OS.
local function add_macos_bookmarks()
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
end

-- Ubuntu bookmark set. Fully independent from the macOS set above;
-- edit these freely without affecting any other OS.
local function add_ubuntu_bookmarks()
	table.insert(bookmarks, {
		tag = "Dropbox",
		path = home_path .. path_sep .. "Dropbox" .. path_sep,
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
		path = "/mnt/data/code/",
		key = "c",
	})
	table.insert(bookmarks, {
		tag = "paper",
		path = "/mnt/data/paper/",
		key = "p",
	})
end

if ya.target_os() == "windows" then
	table.insert(bookmarks, {
		tag = "Dropbox",
		path = (home_path .. "/Users/ziyang/Library/CloudStorage/Dropbox") .. "\\",
		key = "p",
	})
elseif ya.target_os() == "linux" then
	if is_ubuntu() then
		add_ubuntu_bookmarks()
	else
		table.insert(bookmarks, {
			tag = "Home",
			path = home_path .. path_sep,
			key = "h",
		})
	end
elseif ya.target_os() == "macos" then
	add_macos_bookmarks()
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
