local Button = import('/lua/maui/button.lua').Button
local LayoutHelpers = import('/lua/maui/layouthelpers.lua') 
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')

local helpers = import('/mods/EcoPanel/modules/helpers.lua')


local panel = nil

function showhide()
    if panel == nil then
        LOG("[EcoPanel] opening eco panel")
        create()
    else
        LOG("[EcoPanel] closing eco panel")
        panel:Destroy()
        panel = nil
    end
end

function create()
    panel = Group(GetFrame(0))

    local f = GetFrame(0)

    panel.Left:Set(f.Left() + 200)
    panel.Right:Set(f.Right() - 200)
    panel.Top:Set(f.Top() + 200)
    panel.Bottom:Set(f.Bottom() - 200)
    
    -- background
    local bg_border = Bitmap(panel)
    bg_border:SetSolidColor('ff3465a4')
    bg_border.Left = panel.Left
    bg_border.Top = panel.Top
    bg_border.Width = panel.Width
    bg_border.Height = panel.Height
    bg_border.Depth:Set(0) -- TODO

    local bg = Bitmap(panel)
    bg:SetSolidColor('ff111111')
    bg.Left:Set(panel.Left()+2)
    bg.Top:Set(panel.Top()+2)
    bg.Width:Set(panel.Width()-4)
    bg.Height:Set(panel.Height()-4)
    bg.Depth:Set(0) -- TODO

    -- close button
    local close_button = helpers.create_button(panel, "X", 70, 60)
    close_button.Top  :Set(panel.Top() + 5)
    close_button.Right:Set(panel.Right() - 5)
    close_button.OnClick = function (self, modifiers)
		panel:Destroy()
        panel = nil
	end

end