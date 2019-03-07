local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local Group = import('/lua/maui/group.lua').Group
local Control = import('/lua/maui/control.lua').Control

local helpers = import('/mods/EcoPanel/modules/helpers.lua')




function normalize_list(values)
	
	local sum = 0
	for _, v in values do
		sum = sum + v
	end

	local normalized = {}
	for k, v in values do
		normalized[k] = v / sum
	end

	return normalized
end

PieChart = Class(Group) {

	textures = { },
	texture_count = 0,
	pie_pieces = {},
	highlight = nil,
	pie_clicked_callback = function(pie_piece) end,
	pie_hover_callback = function(pie_piece) end, -- will also be called with 'nil', when no segment shall be highlighted

	get_color_texture = function (self, idx)
		return self.textures[helpers.modulo(idx, self.texture_count)]
	end,

	__init = function(self, parent, values, colors)
		Group.__init(self, parent)

		colors = colors or '/mods/EcoPanel/textures/triangle/'
		self.pie_pieces = {}

		-- load textures
		-- (i counts from 1!)
		self.textures = {}
		self.texture_count = 0
		for i, filename in DiskFindFiles(colors, '*.png') do
			local name = Basename(filename, true)
			self.textures[name] = filename
			self.textures[i-1] = filename
			self.texture_count = i
		end

		-- load values
		local normalized_values = normalize_list(values)
		for idx, value in values do
			-- TODO: use object with callbacks here
			table.insert(self.pie_pieces, {
				idx = idx,
				value = value,
				normalized_value = normalized_values[idx],
				color = self:get_color_texture(idx),
				segments = {}, -- segments (cut, so that they fit into 1/8th's)
				overlays_bright = {}, -- white transparent overlay to brighten this piece
				overlays_dark   = {}, -- black transparent overlay to darken this piece
			})
		end

		self.background = Bitmap(parent)
		self.background :SetSolidColor('ff330000')
		self.background.Left   = self.Left
		self.background.Right  = self.Right
		self.background.Top    = self.Top
		self.background.Bottom = self.Bottom
		self.background.Width  = self.Width
		self.background.Height = self.Height
		self.background.Depth:Set(function () return self.Depth() + 1 end)

		self.mask = Bitmap(parent, '/mods/EcoPanel/textures/circle_mask.png')
		self.mask.Left   = self.Left
		self.mask.Right  = self.Right
		self.mask.Top    = self.Top
		self.mask.Bottom = self.Bottom
		self.mask.Width  = self.Width
		self.mask.Height = self.Height
		self.mask.Depth:Set(function () return self.Depth() + 500 end)

		local chart = self
		self.mask.HandleEvent = function (self, event)
			if event.Type == 'MouseMotion' then
				local segment = chart:segment_from_cursor(event.MouseX, event.MouseY)
				chart:highlight_piece(segment, true, false)
			elseif event.Type == 'MouseExit' then
				-- clear highlight
				chart:highlight_piece(nil, false, false)
			elseif event.Type == 'ButtonPress' then
				local segment = chart:segment_from_cursor(event.MouseX, event.MouseY)
				if segment != nil then
					chart.pie_clicked_callback(segment)
				end
			else
				--LOG(tostring(event.Type))
			end
		end
	end,

	segment_from_cursor = function (self, MouseX, MouseY)
		-- calculate angle from center of pie chart to mouse cursor
		local rel_x = MouseX - self:centerX()
		local rel_y = MouseY - self:centerY()

		-- TODO: return nil if distance to center > radius

		local angle = math.atan2(rel_y, rel_x)

		-- convert from +pi to -pi radians to 0-1
		angle = 1-helpers.modulo(angle / math.pi / 2, 1)

		-- find corresponding segment
		local from_val = 0
		for idx, piece in self.pie_pieces do
			-- +eps is required as normalized_values don't necessarily sum exactly to 1
			if from_val <= angle and angle < from_val + piece.normalized_value + 0.00001 then
				return piece
			end
			from_val = from_val + piece.normalized_value
		end
		return nil
	end,

	centerX = function(self)
		return self.Left() + self.Width()/2
	end,

	centerY = function(self)
		return self.Top() + self.Height()/2
	end,

	angle_to_sector = function(self, angle)
		-- angle should be between 0 and 1
		-- returns int showing to which sector the angle belongs:
		--   \    |    /
		--    \ 2 | 1 /
		--  3  \  |  /  0
		--  ---------------
		--  4  /  |  \
		--   etc.
		return math.floor(angle*8)
	end,

	plot = function(self)

		-- from 0 to 1
		local last_angle = 0
		local next_angle = 0

		for idx, piece in self.pie_pieces do
			--LOG("plotting segment nr " .. tostring(idx) .. " for value " .. tostring(piece.normalized_value))
			next_angle = next_angle + piece.normalized_value
			piece.segments = {}
			piece.overlays_bright = {}
			piece.overlays_dark   = {}

			while self:angle_to_sector(last_angle) != self:angle_to_sector(next_angle) do
				-- segment spans sector border
				-- add segment from last value up until border
				local border_angle = (self:angle_to_sector(last_angle)+1)/8

				self:add_segment_border_bg(piece, self:angle_to_sector(last_angle))
				self:add_segment(piece, last_angle, border_angle)

				last_angle = border_angle
			end

			self:add_segment(piece, last_angle, next_angle)
			last_angle = next_angle
		end
	end,

	show_highlight = function(piece, bright, dark)
		--LOG("show hightlight for "..tostring(piece))
		for _, o in piece.overlays_bright do
			if bright then
				o:Show()
			else
				o:Hide()
			end
		end
		for _, o in piece.overlays_dark do
			if dark then
				o:Show()
			else
				o:Hide()
			end
		end
	end,

	-- brighten: if true make it brighter, otherwise darker
	-- inver: if true, do NOT highlight piece but everything else instead
	highlight_piece = function(self, piece, brighten, invert)
		-- no need to highlight the same piece again
		if self.highlight == piece then
			return
		end

		for _, p in self.pie_pieces do
			if p == piece then
				if invert then
					self.show_highlight(p, false, false)
				elseif brighten then
					self.show_highlight(p, true, false)
				else
					self.show_highlight(p, false, true)
				end
			else
				if invert then
					if brighten then
						self.show_highlight(p, true, false)
					else
						self.show_highlight(p, false, true)
					end
				else
					self.show_highlight(p, false, false)
				end
			end
		end

		self.highlight = piece
		self.pie_hover_callback(piece)
	end,


	-- on the 45degree borders between segments there is an ugly line as the textures don't fully overlap
	-- the solution? add a background of the same color as the segment that is cut in two there
	add_segment_border_bg = function(self, piece, from_sector)
		if helpers.modulo(from_sector, 2) > 0 then
			-- we're on a vertical border between segments (e.g. segment 1 and 2) -> no aliasing, so no background fill required
			return
		end

		--LOG("adding bg segment for sector "..tostring(from_sector).."/"..tostring(from_sector+1).." with color "..get_color_texture(color))

		local bg = Bitmap(self, piece.color)

		if from_sector == 0 or from_sector == 6 then
			-- right half
			bg.Left = function() return self:centerX() end
		else
			-- left half
			bg.Left = function() return self.Left() end
		end

		if from_sector == 0 or from_sector == 2 then
			-- top half
			bg.Top = function() return self.Top() end
		else
			-- bottom half
			bg.Top = function() return self:centerY() end
		end

		bg.Width  = function() return self.Width()/2 end
		bg.Height = function() return self.Height()/2 end

		bg:SetUV(0.5, 0.5, 1, 1) -- draw full rectangle
		bg.Depth:Set(function () return self.background.Depth() + 1 end)
	end,


	-- this function is private and will be called by plot()
	-- as the engine is quite restricted, we can maximally draw 1/8th of the full circle at a time
	-- plot() takes care of splitting the actual segments into smaller ones, so they fit into 8 quadrants
	-- each of these smaller segments is then drawn by add_segment()
	-- we therefore expect 'from' and 'to' angles to be in the same sector (1/8th = 45 degrees)
	-- attention: angles (from and to) are in percent of 360 degrees, ie. go from 0 to 1!
	add_segment = function(self, piece, from, to)

		-- ignore very small or degenerate segments
		if math.abs(to-from) < 0.00001 then
			return
		end

		local sector = self:angle_to_sector(from)
		local odd_sector = helpers.modulo(sector, 2) > 0

		local idx = piece.idx

		-- even sectors are painted in normal order, odd sectors are painted in reverse
		if odd_sector then
			idx = -idx
		end

		-- convert absolute angles into ones relative to current sector
		from = from - sector/8
		to   = to   - sector/8

		-- convert them to actual angles in radians
		from = from * math.pi * 2
		to   = to   * math.pi * 2


		-- calculate coordinates for segment
		local segment = Bitmap(self, piece.color)


		-- inner corner, X
		if sector < 2 or sector > 5 then
			-- right sectors
			segment.Left:Set(function() return self:centerX() end)
		else
			-- left sectors
			segment.Right:Set(function() return self:centerX() end)
		end

		-- inner corner, Y
		if sector < 4 then
			-- upper sectors
			segment.Bottom:Set(function() return self:centerY() end)
		else
			-- lower sectors
			segment.Top:Set(function() return self:centerY() end)
		end



		local tan_alpha;
		if odd_sector then
			tan_alpha = math.tan(math.pi/4-from)
	    else
			tan_alpha = math.tan(to)
		end

		-- segment size, this creates the actual size of the segment
		if sector == 0 or sector == 7 or sector == 3 or sector == 4 then
			segment.Width:Set( function() return math.ceil(self.Width()/2) end)
			segment.Height:Set(function() return math.ceil(self.Height()/2 * tan_alpha) end)
		else
			segment.Width:Set( function() return math.ceil(self.Width()/2 * tan_alpha) end)
			segment.Height:Set(function() return math.ceil(self.Height()/2) end)
		end


		-- hack to sort this in reverse (let's hope there aren't ever more than 50 segments...)
		segment.Depth:Set(function () return self.Depth() + 150 - idx*3 end)


		local add_overlay = function (segment, bright)
			local overlay
			if bright then
				overlay = Bitmap(self, '/mods/EcoPanel/textures/triangle_white.png')
			else
				overlay = Bitmap(self, '/mods/EcoPanel/textures/triangle_black.png')
			end

			overlay.Left  :Set(function() return segment.Left() end)
			overlay.Top   :Set(function() return segment.Top () end)
			overlay.Width :Set(function() return segment.Width() end)
			overlay.Height:Set(function() return segment.Height() end)
			overlay.Depth :Set(function() return segment.Depth() + 1 end)

			overlay:Hide()
			overlay:SetAlpha(0.4)

			return overlay
		end

		-- build overlay segments to brighten or darken a pie piece
		local overlay_bright = add_overlay(segment, true)
		local overlay_dark   = add_overlay(segment, false)

		-- flip segment if necessary (segment 0 is not flipped)
		--   \  Y | XY /
		--  3 \ 2 | 1 / 0
		--  X  \  |  /  -
		--  ---------------
		--  XY /  |  \  Y
		--  4 / 5 | 6 \ 7
		--   /  - | X  \
		if sector == 1 or sector == 4 then
			-- flip X and Y
			segment:SetUV(1, 1, 0, 0)
			overlay_bright:SetUV(1, 1, 0, 0)
			overlay_dark  :SetUV(1, 1, 0, 0)
		elseif sector == 2 or sector == 7 then
			-- flip Y only
			segment:SetUV(0, 1, 1, 0)
			overlay_bright:SetUV(0, 1, 1, 0)
			overlay_dark  :SetUV(0, 1, 1, 0)
		elseif sector == 3 or sector == 6 then
			-- flip X only
			segment:SetUV(1, 0, 0, 1)
			overlay_bright:SetUV(1, 0, 0, 1)
			overlay_dark  :SetUV(1, 0, 0, 1)
		else
		    -- no flipping required
			segment:SetUV(0, 0, 1, 1) -- u0, v0, u1, v1
			overlay_bright:SetUV(0, 0, 1, 1)
			overlay_dark  :SetUV(0, 0, 1, 1)
		end



		--LOG("  >>> adding segment nr " .. tostring(idx) .. " (in sector " .. tostring(sector) .. " odd? "..tostring(odd_sector)..") from " .. tostring(helpers.rad2deg(from)) .. "deg to " .. tostring(helpers.rad2deg(to)) .. "deg")
		--LOG("      tan = " .. tostring(tan_alpha))

		table.insert(piece.segments, segment)
		table.insert(piece.overlays_bright, overlay_bright)
		table.insert(piece.overlays_dark  , overlay_dark)
	end,




}