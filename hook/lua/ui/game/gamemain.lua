
local KeyMapper = import('/lua/keymap/keymapper.lua')
KeyMapper.SetUserKeyAction('Show Eco Panel', {action = "UI_Lua import('/mods/EcoPanel/modules/panel.lua').showhide()", category = 'Mods', order = 900})
-- TODO: modify keyDescriptions table from /lua/keymap/keydescription.lua to add a description text for above shortcut