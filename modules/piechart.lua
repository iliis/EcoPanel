local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local Group = import('/lua/maui/group.lua').Group

local helpers = import('/mods/EcoPanel/modules/helpers.lua')


local textures = { }
local texture_count = 0

-- load textures
-- (i counts from 1!)
for i, filename in DiskFindFiles('/mods/EcoPanel/textures/triangle/', '*.png') do
	local name = Basename(filename, true)
	textures[name] = filename
	textures[i-1] = filename
	texture_count = i
end

function get_color_texture(idx)
	return textures[helpers.modulo(idx, texture_count)]
end


function get_colors()
	return textures
end


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

	__init = function(self, parent, values)
		Group.__init(self, parent)

		self.values = values
		self.pie_elements = {}

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
		self.mask.Depth:Set(function () return self.Depth() + 100 end)
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

		self.pie_elements = {}

		local normalized_values = normalize_list(self.values)

		-- from 0 to 1
		local last_angle = 0
		local next_angle = 0

		for idx, value in normalized_values do
			--LOG("plotting segment nr " .. tostring(idx) .. " for value " .. tostring(value))
			next_angle = next_angle + value

			while self:angle_to_sector(last_angle) != self:angle_to_sector(next_angle) do
				-- segment spans sector border
				-- add segment from last value up until border
				local border_angle = (self:angle_to_sector(last_angle)+1)/8
				self:add_segment_border_bg(self:angle_to_sector(last_angle), idx)
				self:add_segment(last_angle, border_angle, idx)
				last_angle = border_angle
			end

			self:add_segment(last_angle, next_angle, idx)
			last_angle = next_angle
		end
	end,


	-- on the 45degree borders between segments there is an ugly line as the textures don't fully overlap
	-- the solution? add a background of the same color as the segment that is cut in two there
	add_segment_border_bg = function(self, from_sector, color)
		if helpers.modulo(from_sector, 2) > 0 then
			-- we're on a vertical border between segments (e.g. segment 1 and 2) -> no aliasing, so no background fill required
			return
		end

		--LOG("adding bg segment for sector "..tostring(from_sector).."/"..tostring(from_sector+1).." with color "..get_color_texture(color))

		local bg = Bitmap(self, get_color_texture(color))

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
	add_segment = function(self, from, to, color)

		-- ignore very small or degenerate segments
		if math.abs(to-from) < 0.00001 then
			return
		end

		local sector = self:angle_to_sector(from)
		local odd_sector = helpers.modulo(sector, 2) > 0

		local idx = table.getn(self.pie_elements)

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
		local segment = Bitmap(self, get_color_texture(color))


		-- inner corner, X
		if sector < 2 or sector > 5 then
			-- right sectors
			segment.Left = function() return self:centerX() end
		else
			-- left sectors
			segment.Right = function() return self:centerX() end
		end

		-- inner corner, Y
		if sector < 4 then
			-- upper sectors
			segment.Bottom = function() return self:centerY() end
		else
			-- lower sectors
			segment.Top = function() return self:centerY() end
		end



		local tan_alpha;
		if odd_sector then
			tan_alpha = math.tan(math.pi/4-from)
	    else
			tan_alpha = math.tan(to)
		end

		-- segment size, this creates the actual size of the segment
		if sector == 0 or sector == 7 or sector == 3 or sector == 4 then
			segment.Width  = function() return math.ceil(self.Width()/2) end
			segment.Height = function() return math.ceil(self.Height()/2 * tan_alpha) end
		else
			segment.Width  = function() return math.ceil(self.Width()/2 * tan_alpha) end
			segment.Height = function() return math.ceil(self.Height()/2) end
		end

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
		elseif sector == 2 or sector == 7 then
			-- flip Y only
			segment:SetUV(0, 1, 1, 0)
		elseif sector == 3 or sector == 6 then
			-- flip X only
			segment:SetUV(1, 0, 0, 1)
		else
		    -- no flipping required
			segment:SetUV(0, 0, 1, 1) -- u0, v0, u1, v1
		end



		--LOG("  >>> adding segment nr " .. tostring(idx) .. " (in sector " .. tostring(sector) .. " odd? "..tostring(odd_sector)..") from " .. tostring(helpers.rad2deg(from)) .. "deg to " .. tostring(helpers.rad2deg(to)) .. "deg")
		--LOG("      tan = " .. tostring(tan_alpha))

		-- hack to sort this in reverse (let's hope there aren't ever more than 50 segments...)
		segment.Depth:Set(function () return self.Depth() + 50 - idx end)

		table.insert(self.pie_elements, segment)

	end


}