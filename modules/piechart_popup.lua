local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')

local helpers = import('/mods/EcoPanel/modules/helpers.lua')

PieChartPopup = Class(Group) {
	__init = function(self, parent, chart)
		Group.__init(self, parent)

		self.Top = chart.Top
		self.Left = chart.Left
		self.Width = chart.Width
		self.Height = chart.Height

		self.chart = chart

		self.chart.pie_hover_callback = function (segment)
			self:show_popup_callback(segment)
		end

		self.diag_line = Bitmap(self, '/mods/EcoPanel/textures/diagonal_line.png')
		self.diag_line.Depth:Set(function() return chart.mask.Depth() + 1 end)

		self.horiz_line = Bitmap(self)
		self.horiz_line:SetSolidColor('ffffffff')
		self.horiz_line.Top:Set(0)
		self.horiz_line.Left:Set(0)
		self.horiz_line.Width:Set(200)
		self.horiz_line.Height:Set(2)
		self.horiz_line.Depth:Set(function() return self.diag_line.Depth() end)

		self.title_lbl = UIUtil.CreateText(self, "Something", 20, UIUtil.titleFont)
		self.title_lbl:SetColor('white')
		--self.title_lbl.label:SetDropShadow(true)
		self.title_lbl.Bottom:Set(function() return math.floor(self.horiz_line.Top()+0.5) end)

		self.text_lbl1 = UIUtil.CreateText(self, "Some Details Here", 12, UIUtil.bodyFont)
		self.text_lbl1.Top:Set(function() return self.title_lbl.Bottom() + 5 end)
		self.text_lbl2 = UIUtil.CreateText(self, "Value: XXX", 12, UIUtil.bodyFont)
		self.text_lbl2.Top:Set(function() return self.text_lbl1.Bottom() + 2 end)
		
		self:Hide()
	end,

	show_popup_callback = function(self, segment)
		if segment == nil then
			self:Hide()
			return
		end

		self.text_lbl2:SetText("Value: " .. tostring(segment.value))

		local R1 = self.chart.Width()/2 + 4
		local R2 = R1 + 20
		local angle = (segment.angle_from + segment.angle_to)/2

		self.diag_line.Left  :Set( self.chart:centerX() + math.cos(angle)*R1 - 1)
		self.diag_line.Bottom:Set( self.chart:centerY() - math.sin(angle)*R1 + 1)

		self.diag_line.Right :Set( self.chart:centerX() + math.cos(angle)*R2 + 1)
		self.diag_line.Top   :Set( self.chart:centerY() - math.sin(angle)*R2 - 1)

		self.diag_line.Width :Set( self.diag_line.Right() - self.diag_line.Left())
		self.diag_line.Height:Set( self.diag_line.Bottom() - self.diag_line.Top())

		self.diag_line:SetUV(0, 0.9, 0.1, 1)


		self.horiz_line.Width:Set( self.chart:Width()/2 - math.abs(math.cos(angle)*R2) + 200 )

		if angle > math.pi/2 and angle < math.pi/2*3 then
			-- line should go to the left of the chart
			self.horiz_line.Left :Set( self.diag_line.Right() - self.horiz_line.Width())

			self.title_lbl.Left  :Set( self.horiz_line.Left() )
			self.text_lbl1.Left   :Set( self.horiz_line.Left() )
			self.text_lbl2.Left   :Set( self.horiz_line.Left() )
		else
			-- right side of chart
			self.horiz_line.Left :Set( self.diag_line.Right() )
			self.title_lbl.Left  :Set( self.horiz_line.Right() - self.title_lbl.Width() )
			self.text_lbl1.Left   :Set( self.horiz_line.Right() - self.text_lbl1.Width() )
			self.text_lbl2.Left   :Set( self.horiz_line.Right() - self.text_lbl1.Width() )
		end
		self.horiz_line.Top  :Set( self.diag_line.Top() )

		self:Show()
	end,
}
