local Button = import('/lua/maui/button.lua').Button
local LayoutHelpers = import('/lua/maui/layouthelpers.lua') 
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')

local Units = import('/mods/common/units.lua')

local helpers = import('/mods/EcoPanel/modules/helpers.lua')

-------------------------------------------------------------------------------
-- Configuration

local ICON_SIZE = 120
local padding = 3
local margin = 5

-- if the 'stop' button is clicked, queue will be emptied except for the item
-- currently being built if this item is already above this percentage
local abort_unit_if_below = 0.2

-------------------------------------------------------------------------------

local ITEM_WIDTH = ICON_SIZE+2*padding+margin
local ITEM_COLUMNS = math.floor((GetFrame(0).Width()-200) / ITEM_WIDTH)

-------------------------------------------------------------------------------
-- State

local panel = nil -- main UI object (nil if panel is inactive)

-------------------------------------------------------------------------------


local tech_cat_short = {
    TECH1 = "T1",
    TECH2 = "T2",
    TECH3 = "T3",
    TECH4 = "T4",
}




function showhide()
    if panel == nil then
        --LOG("[EcoPanel] opening eco panel")
        create()
    else
        --LOG("[EcoPanel] closing eco panel")
        panel:Destroy()
        panel = nil
    end
end

function create()
    panel = Group(GetFrame(0))
    panel:DisableHitTest(true)

	local PieChart = import('/mods/EcoPanel/modules/piechart.lua').PieChart

	local chart = PieChart(panel, {1,5,20,5,30,18,20,10,20,30,40,10,10,10})
	--local chart = PieChart(panel, {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1})
	chart.Top:Set(300)
	chart.Left:Set(600)
	chart.Width:Set(300)
	chart.Height:Set(300)
	chart:plot()
    
    -- catch mouse clicks by putting the UI in front of game, we don't want to be able to click through our panel
    panel.Depth:Set(100)

    local f = GetFrame(0)


	panel.Width:Set(ITEM_COLUMNS * ITEM_WIDTH + margin) -- one margin is already included in ITEM_WIDTH
    panel.Left:Set(math.floor(f.Width()/2 - panel.Width()/2)) -- center horizontally

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
    --local close_button = helpers.create_button(panel, "X", 70, 60)
	local close_button= Button(panel,
		'/mods/EcoPanel/textures/close_btn/close_btn_dis.png',
		'/mods/EcoPanel/textures/close_btn/close_btn_down.png',
		'/mods/EcoPanel/textures/close_btn/close_btn_over.png',
		'/mods/EcoPanel/textures/close_btn/close_btn_dis.png')
	close_button:EnableHitTest(true)
	close_button.Depth:Set(panel.Depth() + 10)
	close_button.Width:Set(48)
	close_button.Height:Set(48)
    close_button.Top  :Set(panel.Top() + 5)
    close_button.Right:Set(panel.Right() - 5)
    close_button.OnClick = function (self, modifiers)
		panel:Destroy()
        panel = nil
	end

    panel.factories_label = UIUtil.CreateText(panel, 'FACTORIES', 30, UIUtil.titleFont)
	panel.factories_label:SetColor('white')
    panel.factories_label.Top:Set(panel.Top() + margin)
    panel.factories_label.Left:Set(panel.Left() + margin)


    local all_factories = Units.Get(categories.FACTORY)
    
	panel.factory_list = {}
    for _, factory in all_factories do
        --LOG(">>> factory:")
        --helpers.LOG_OBJ(factory, true)
		--helpers.LOG_OBJ(factory:GetHealth())
		--helpers.LOG_OBJ(factory:IsBeingBuilt())
        

        local data = Units.Data(factory)
        local bp = factory:GetBlueprint()

        --LOG("    >>> DATA:")
        --helpers.LOG_OBJ(data)
        --LOG("is idle? ", factory:IsIdle())
        --LOG("is paused? ", GetIsPaused({factory}))
        --helpers.LOG_OBJ(factory:GetEconData())

        --LOG("    >>> BLUEPRINT:")
        --helpers.LOG_OBJ(bp)

		if not factory:IsDead() then
			local obj = add_factory(factory)
		end
    end
end


function factory_state_str(factory)
	-- TODO: figure out if factory is still being built
	if factory:IsIdle() then
		return "IDLE" -- has priority over 'paused'
	elseif GetIsPaused({factory}) then
		return "PAUSED"
	else
		return "WORKING"
	end
end



--INFO: >>> factory:
--INFO:         functions():
--INFO:         GetEntityId = cfunction: 154296C0
--INFO:         GetWorkProgress = cfunction: 15429F80	-- how for along is the unit that the factory is building?
--INFO:         GetCommandQueue = cfunction: 15429F00
--INFO:         GetFocus = cfunction: 15429940
--INFO:         GetHealth = cfunction: 15429AC0			-- how alive is the building? returns HP, so need max from blueprint
--INFO:         SetCustomName = cfunction: 15429440
--INFO:         GetMissileInfo = cfunction: 15429EC0
--INFO:         CanAttackTarget = cfunction: 15429780
--INFO:         GetStat = cfunction: 154294C0			-- (name [,defaultVal])
--INFO:         HasSelectionSet = cfunction: 15429B40
--INFO:         GetBuildRate = cfunction: 15429A40
--INFO:         GetFootPrintSize = cfunction: 15429740
--INFO:         GetSelectionSets = cfunction: 15429B00
--INFO:         IsOverchargePaused = cfunction: 15429A00
--INFO:         IsAutoMode = cfunction: 154295C0
--INFO:         IsDead = cfunction: 154299C0
--INFO:         RemoveSelectionSet = cfunction: 15429B80
--INFO:         GetUnitId = cfunction: 15429700
--INFO:         GetArmy = cfunction: 15429840
--INFO:         __index = table: 15427910 {
--INFO:                 functions():
--INFO:         }
--INFO:         IsStunned = cfunction: 15429480
--INFO:         ProcessInfo = cfunction: 15429600
--INFO:         IsAutoSurfaceMode = cfunction: 15429580
--INFO:         IsInCategory = cfunction: 15429500
--INFO:         HasUnloadCommandQueuedUp = cfunction: 15429640
--INFO:         GetShieldRatio = cfunction: 15429FC0
--INFO:         GetCustomName = cfunction: 15429400
--INFO:         IsIdle = cfunction: 15429980
--INFO:         GetMaxHealth = cfunction: 15429A80
--INFO:         IsRepeatQueue = cfunction: 15429540
--INFO:         GetBlueprint = cfunction: 15429680
--INFO:         GetFuelRatio = cfunction: 15429800
--INFO:         GetEconData = cfunction: 15429F40
--INFO:         GetPosition = cfunction: 15429880
--INFO:         GetCreator = cfunction: 154298C0
--INFO:         AddSelectionSet = cfunction: 15429BC0
--INFO:         GetGuardedEntity = cfunction: 15429900


function add_factory(factory)

    local bp = factory:GetBlueprint()

	-- background and main object
	-----------------------------------------------------------------

	local obj = Bitmap(panel)
	obj:SetSolidColor('ff333333')

	local idx = table.getn(panel.factory_list)
	local col = helpers.modulo(idx, ITEM_COLUMNS)
	local row = math.floor(idx / ITEM_COLUMNS)

    obj.Left  :Set(panel.factories_label.Left() + col*(ICON_SIZE+2*padding+margin))
    obj.Width :Set(ICON_SIZE+2*padding)

	obj.Height:Set(210) -- temporary, will be updated once contents exist
	-- TODO: make layout responsive by using lambdas, so we can actually update Height (and thus position) later on
	--       this would also make it possible to move around items
    obj.Top   :Set(panel.factories_label.Bottom() + margin + row*(obj.Height() + margin))


	obj.factory = factory

	-- icon
	-----------------------------------------------------------------

	-- TODO: add land/water/air background depending on type

    obj.icon = Bitmap(obj, UIUtil.UIFile(bp['RuntimeData']['IconFileName']))
    obj.icon.Left:Set(function() return obj.Left() + padding end)
    obj.icon.Top :Set(function() return obj.Top() + padding end)
    obj.icon.Width :Set(ICON_SIZE)
    obj.icon.Height:Set(ICON_SIZE)


    --INFO:         RuntimeData = table: 1F522190 {
    --INFO:                 IconFileName = /textures/ui/common/icons/units/ueb0101_icon.dds
    --INFO:                 UpIconFileName = /textures/ui/common/icons/units/ueb0101_icon.dds
    --INFO:                 DownIconFileName = /textures/ui/common/icons/units/ueb0101_icon.dds
    --INFO:                 OverIconFileName = /textures/ui/common/icons/units/ueb0101_icon.dds
    --INFO:         }

    

	-- labels
	-----------------------------------------------------------------

    obj.name_label = UIUtil.CreateText(obj, LOC(bp['Interface']['HelpText']), 15, UIUtil.bodyFont)
	obj.name_label:SetColor('white')
	--label:SetDropShadow(true)
    obj.name_label.Top:Set(obj.icon.Bottom() + padding)
    obj.name_label.Left = obj.icon.Left

    obj.tech_label = UIUtil.CreateText(obj, tech_cat_short[bp['TechCategory']], 15, UIUtil.bodyFont)
    obj.tech_label:SetColor('ffbbbbbb')
    obj.tech_label.Right = obj.icon.Right
    obj.tech_label.Top = obj.name_label.Top


	obj.state_label = UIUtil.CreateText(obj, factory_state_str(factory), 15, UIUtil.bodyFont)
	obj.state_label:SetColor('ffbbbbbb')
	obj.state_label.Top:Set(function () return obj.name_label.Bottom() + padding end)
	obj.state_label.Left = obj.icon.Left



	-- buttons
	-----------------------------------------------------------------

	local button_size = (ICON_SIZE-2*padding)/3


	-- textures\ui\uef\game\pause_btn <- the pause button from top menu to pause the game
	-- textures\ui\common\game\infinite_btn / pause_btn <- repeat/pause buttons, but different ones than a factory uses?

	obj.repeat_button = Button(obj,
		'/textures/ui/common/game/orders/patrol_btn_dis.dds',
		'/textures/ui/common/game/orders/patrol_btn_down.dds',
		'/textures/ui/common/game/orders/patrol_btn_over.dds',
		'/textures/ui/common/game/orders/patrol_btn_dis.dds')
	obj.repeat_button.Left = obj.icon.Left
	obj.repeat_button.Top:Set(obj.state_label.Bottom() + padding)
	obj.repeat_button.Depth :Set(obj.Depth() + 10)
	obj.repeat_button.Width :Set(button_size)
	obj.repeat_button.Height:Set(button_size)
	obj.repeat_button:EnableHitTest(true)
	obj.repeat_button.OnClick = function (self, modifiers)
		if obj.factory:IsRepeatQueue() then
			obj.factory:ProcessInfo('SetRepeatQueue', 'false')
			obj.repeat_button.mNormal = '/textures/ui/common/game/orders/patrol_btn_dis.dds'
		else
			obj.repeat_button.mNormal = '/textures/ui/common/game/orders/patrol_btn_up.dds'
			obj.factory:ProcessInfo('SetRepeatQueue', 'true')
		end
		obj.repeat_button:ApplyTextures()
	end

	obj.pause_button = Button(obj,
		'/textures/ui/common/game/orders/pause_btn_up.dds',
		'/textures/ui/common/game/orders/pause_btn_down.dds',
		'/textures/ui/common/game/orders/pause_btn_up.dds',
		'/textures/ui/common/game/orders/pause_btn_dis.dds')
	obj.pause_button.Left:Set(obj.repeat_button:Right() + padding)
	obj.pause_button.Top:Set(obj.state_label.Bottom() + padding)
	obj.pause_button.Depth :Set(obj.Depth() + 10)
	obj.pause_button.Width :Set(button_size)
	obj.pause_button.Height:Set(button_size)
	obj.pause_button:EnableHitTest(true)
    obj.pause_button.OnClick = function (self, modifiers)
        if GetIsPaused({factory}) then
            SetPaused({factory},  false)
			obj.pause_button.mNormal = '/textures/ui/common/game/orders/pause_btn_dis.dds'
        else
            SetPaused({factory},  true)
			obj.pause_button.mNormal = '/textures/ui/common/game/orders/pause_btn_over.dds'
        end
		obj.pause_button:ApplyTextures()
	end

	--UIUtil.UIFile('')
	obj.abort_button = Button(obj,
		'/textures/ui/common/game/orders/stop_btn_dis.dds',
		'/textures/ui/common/game/orders/stop_btn_down.dds',
		'/textures/ui/common/game/orders/stop_btn_over.dds',
		'/textures/ui/common/game/orders/stop_btn_dis.dds')
	obj.abort_button.Left:Set(obj.pause_button:Right() + padding)
	obj.abort_button.Top:Set(obj.state_label.Bottom() + padding)
	obj.abort_button.Depth :Set(obj.Depth() + 10)
	obj.abort_button.Width :Set(button_size)
	obj.abort_button.Height:Set(button_size)
	obj.abort_button:EnableHitTest(true)
	obj.abort_button.OnClick = function (self, modifiers)
		LOG("abort clicked:")
		
		if obj.factory:GetWorkProgress() < abort_unit_if_below then
			-- stop production completely
			IssueUnitCommand(obj.factory, 'stop')
		else
			-- keep very first item in queue
			local queue = SetCurrentFactoryForQueueDisplay(obj.factory)
			if queue then
				for idx, item in queue do
					local count = item.count
					if idx == 1 then
						count = count - 1
					end
					-- TODO: is there a more efficient way of editing a build queue?
					DecreaseBuildCountInQueue(idx, count) -- remove the rest
				end
			end
		end

		-- disable repeat
		obj.factory:ProcessInfo('SetRepeatQueue', 'false')
		obj.repeat_button.mNormal = '/textures/ui/common/game/orders/patrol_btn_dis.dds'
		obj.repeat_button:ApplyTextures()

		-- unpause
		SetPaused({obj.factory},  false)
		obj.pause_button.mNormal = '/textures/ui/common/game/orders/pause_btn_dis.dds'
		obj.pause_button:ApplyTextures()
	end


	--obj.Height:Set(obj.repeat_button:Bottom() + padding - panel.factories_label:Bottom() - margin)

	-----------------------------------------------------------------

	obj.update = function (self)

		if self.factory:IsRepeatQueue() then
			self.repeat_button.mNormal = '/textures/ui/common/game/orders/patrol_btn_up.dds'
		else
			self.repeat_button.mNormal = '/textures/ui/common/game/orders/patrol_btn_dis.dds'
		end
		self.repeat_button:ApplyTextures()


		if GetIsPaused({self.factory}) then
			-- active button = "paused"
			self.pause_button.mNormal = '/textures/ui/common/game/orders/pause_btn_over.dds'
		else
			-- disabled button = "working"
			self.pause_button.mNormal = '/textures/ui/common/game/orders/pause_btn_dis.dds'
		end
		self.pause_button:ApplyTextures()
	end

	obj:update()


	table.insert(panel.factory_list, obj)

	return obj
end





-- BUTTON FUNCTIONS
--INFO:         __init = function: 1790FBE0
--INFO:         SetLoopPingPongPattern = cfunction: 1543B200
--INFO:         ApplyTextures = function: 179048A4
--INFO:         OnLoseKeyboardFocus = function: 17904DC8
--INFO:         SetAlpha = cfunction: 15439AC0
--INFO:         AcquireKeyboardFocus = cfunction: 15439400
--INFO:         UseAlphaHitTest = cfunction: 1543BCC0
--INFO:         GetCurrentFocusControl = cfunction: 15439440
--INFO:         ClearChildren = cfunction: 154397C0
--INFO:         SetFrame = cfunction: 1543B040
--INFO:         ResetLayout = function: 1790FDA0
--INFO:         SetNewTextures = function: 17904888
--INFO:         HandleEvent = function: 1790F800
--INFO:         GetParent = cfunction: 1543B3C0
--INFO:         ScrollSetTop = function: 17904AD4
--INFO:         Show = cfunction: 15439640
--INFO:         SetParent = cfunction: 15439780
--INFO:         SetRenderPass = cfunction: 15439540
--INFO:         InternalSetSolidColor = cfunction: 1543BD40
--INFO:         SetNeedsFrameUpdate = cfunction: 15439B40
--INFO:         OnAnimationStopped = function: 17904604
--INFO:         SetNewTexture = cfunction: 1543BD80
--INFO:         GetRenderPass = cfunction: 15439580
--INFO:         OnRolloverEvent = function: 17904700
--INFO:         SetFramePattern = cfunction: 1543B240
--INFO:         OnEnable = function: 1790471C
--INFO:         ApplyFunction = cfunction: 15439A40
--INFO:         GetScrollValues = function: 17904E00
--INFO:         OnInit = function: 1790FAA0
--INFO:         IsDisabled = function: 17904D20
--INFO:         Enable = function: 17904D04
--INFO:         __bases = table: 17919AC8 {
--INFO:                 functions():
--INFO:                 __call = function: 17667C80
--INFO:         }
--INFO:         EnableHitTest = cfunction: 15439700
--INFO:         ScrollPages = function: 17904AB8
--INFO:         OnClick = function: 179043B8
--INFO:         Hide = cfunction: 15439680
--INFO:         IsHidden = cfunction: 154395C0
--INFO:         DisableHitTest = cfunction: 15439740
--INFO:         GetName = cfunction: 15439500
--INFO:         Dump = cfunction: 15439480
--INFO:         SetName = cfunction: 154394C0
--INFO:         SetBackwardPattern = cfunction: 1543B180
--INFO:         GetNumFrames = cfunction: 1543B0C0
--INFO:         SetForwardPattern = cfunction: 1543B140
--INFO:         Disable = function: 17904CE8
--INFO:         OnHide = function: 17904DAC
--INFO:         OnKeyboardFocusChange = function: 17904DE4
--INFO:         ScrollLines = function: 17904E1C
--INFO:         IsScrollable = function: 17904AF0
--INFO:         OnFrame = function: 17904D58
--INFO:         SetUV = cfunction: 1543BD00
--INFO:         GetRootFrame = cfunction: 15439B00
--INFO:         ShareTextures = cfunction: 1543B280
--INFO:         Destroy = cfunction: 1543B380
--INFO:         SetHidden = cfunction: 15439600
--INFO:         GetFrame = cfunction: 1543B080
--INFO:         SetPingPongPattern = cfunction: 1543B1C0
--INFO:         __index = table: 17919B18 {
--INFO:                 functions():
--INFO:                 __newindex = function: 17315508
--INFO:                 __call = function: 17306140
--INFO:         }
--INFO:         HitTest = cfunction: 15439A00
--INFO:         OnDisable = function: 179046E4
--INFO:         IsHitTestDisabled = cfunction: 154396C0
--INFO:         SetSolidColor = function: 179045B0
--INFO:         SetTexture = function: 17904594
--INFO:         OnDestroy = function: 179045CC
--INFO:         NeedsFrameUpdate = cfunction: 15439B80
--INFO:         Play = cfunction: 1543BC00
--INFO:         AbandonKeyboardFocus = cfunction: 15439BC0
--INFO:         __spec = table: 17919AF0 {
--INFO:                 functions():
--INFO:         }
--INFO:         SetFrameRate = cfunction: 1543B100
--INFO:         Stop = cfunction: 1543B000
--INFO:         GetAlpha = cfunction: 15439A80
--INFO:         SetTiled = cfunction: 1543BC80
--INFO:         Loop = cfunction: 1543BC40
--INFO:         OnAnimationFinished = function: 179045E8
--INFO:         OnAnimationFrame = function: 17904620