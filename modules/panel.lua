local Button = import('/lua/maui/button.lua').Button
local LayoutHelpers = import('/lua/maui/layouthelpers.lua') 
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')

local Units = import('/mods/common/units.lua')

local helpers = import('/mods/EcoPanel/modules/helpers.lua')


local tech_cat_short = {
    TECH1 = "T1",
    TECH2 = "T2",
    TECH3 = "T3",
    TECH4 = "T4",
}



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
    panel:DisableHitTest(true)
    
    -- catch mouse clicks by putting the UI in front of game, we don't want to be able to click through our panel
    panel.Depth:Set(100)

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
    

    local bg = Bitmap(panel)
    bg:SetSolidColor('ff111111')
    bg.Left:Set(panel.Left()+2)
    bg.Top:Set(panel.Top()+2)
    bg.Width:Set(panel.Width()-4)
    bg.Height:Set(panel.Height()-4)

    -- close button
    local close_button = helpers.create_button(panel, "X", 70, 60)
    close_button.Top  :Set(panel.Top() + 5)
    close_button.Right:Set(panel.Right() - 5)
    close_button.OnClick = function (self, modifiers)
		panel:Destroy()
        panel = nil
	end

    local factories_label = UIUtil.CreateText(panel, 'FACTORIES', 30, UIUtil.titleFont)
	factories_label:SetColor('white')
    factories_label.Top:Set(panel.Top() + 10)
    factories_label.Left:Set(panel.Left() + 20)


    local all_factories = Units.Get(categories.FACTORY)

    local x = panel.Left() + 20
    local y = factories_label.Bottom() + 10
    
    for _, factory in all_factories do
        LOG(">>> factory:")
        --helpers.LOG_OBJ(factory, true)
        

        local data = Units.Data(factory)
        local bp = factory:GetBlueprint()

        LOG("    >>> DATA:")
        --helpers.LOG_OBJ(data)
        LOG("is idle? ", factory:IsIdle())
        LOG("is paused? ", GetIsPaused({factory}))
        helpers.LOG_OBJ(factory:GetEconData())

        --LOG("    >>> BLUEPRINT:")
        --helpers.LOG_OBJ(bp)
     
        add_factory(factory, x, y)
        x = x + 150
    end
end


function add_factory(factory, x, y)
    local bp = factory:GetBlueprint()

    local bg = Bitmap(panel, UIUtil.UIFile(bp['RuntimeData']['IconFileName']))
    --bg:SetSolidColor('fffcaf3e')
    bg.Left:Set(x)
    bg.Top:Set(y)
    bg.Width:Set(140)
    bg.Height:Set(140)


    --INFO:         RuntimeData = table: 1F522190 {
    --INFO:                 IconFileName = /textures/ui/common/icons/units/ueb0101_icon.dds
    --INFO:                 UpIconFileName = /textures/ui/common/icons/units/ueb0101_icon.dds
    --INFO:                 DownIconFileName = /textures/ui/common/icons/units/ueb0101_icon.dds
    --INFO:                 OverIconFileName = /textures/ui/common/icons/units/ueb0101_icon.dds
    --INFO:         }

    

    local label = UIUtil.CreateText(panel, LOC(bp['Interface']['HelpText']), 15, UIUtil.bodyFont)
	label:SetColor('white')
	--label:SetDropShadow(true)
    label.Top:Set(bg.Bottom() + 5)
    label.Left = bg.Left

    local tech = UIUtil.CreateText(panel, tech_cat_short[bp['TechCategory']], 15, UIUtil.bodyFont)
    tech:SetColor('ffbbbbbb')
    tech.Right = bg.Right
    tech.Top = label.Top

    local pause_button = helpers.create_button(panel, "pause", 50, 30)
    pause_button.Top:Set(label.Bottom() + 5)
    pause_button.Left = label.Left
    pause_button.OnClick = function (self, modifiers)
        if GetIsPaused({factory}) then
            SetPaused({factory},  false)
            pause_button.label:SetText("pause")
        else
            SetPaused({factory},  true)
            pause_button.label:SetText("unpause")
        end
	end
end