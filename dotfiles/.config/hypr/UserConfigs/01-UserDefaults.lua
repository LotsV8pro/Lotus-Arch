-- 01-UserDefaults.lua - Default apps and search engine
-- Converted from UserConfigs/01-UserDefaults.conf

-- Set your default editor here
-- NOTE, this will be automatically uncommented if you select neovim or vim to your default editor
-- hl.env("EDITOR", "vim")

-- Define preferred text editor for the Quick Settings Menu (SUPER SHIFT E)
-- script will take the default EDITOR and nano as fallback
local edit = os.getenv("EDITOR") or "nano"

-- These two are for UserKeybinds.conf & Waybar Modules
local term = "kitty"
local files = "thunar"

-- Default Search Engine for ROFI Search (SUPER S)
local search_engine = "https://www.google.com/search?q={}"

-- Export variables for use in other modules
return {
    edit = edit,
    term = term,
    files = files,
    search_engine = search_engine,
}
