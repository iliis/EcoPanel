local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local Group = import('/lua/maui/group.lua').Group

local helpers = import('/mods/EcoPanel/modules/helpers.lua')


local textures = { }

-- load textures
for i, filename in DiskFindFiles('/mods/EcoPanel/textures/triangle/', '*.png') do
	local name = Basename(filename, true)
	textures[name] = filename
	textures[i] = filename
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
			LOG("plotting segment for value " .. tostring(value))
			next_angle = next_angle + value

			while self:angle_to_sector(last_angle) != self:angle_to_sector(next_angle) do
				LOG(" - goes from sector " .. tostring(self:angle_to_sector(last_angle)) .. " to sector " .. tostring(self:angle_to_sector(next_angle)))
				-- segment spans sector border
				-- add segment from last value up until border
				local border_angle = (self:angle_to_sector(last_angle)+1)/8
				self:add_segment(last_angle, border_angle, idx)
				last_angle = border_angle
			end

			self:add_segment(last_angle, next_angle, idx)
			last_angle = next_angle
		end
	end,


	-- this function is private and will be called by plot()
	-- as the engine is quite restricted, we can maximally draw 1/8th of the full circle at a time
	-- plot() takes care of splitting the actual segments into smaller ones, so they fit into 8 quadrants
	-- each of these smaller segments is then drawn by add_segment()
	-- we therefore expect 'from' and 'to' angles to be in the same sector (1/8th = 45 degrees)
	add_segment = function(self, from, to, color)
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

		if sector < 2 then
			LOG("  >>> adding segment nr " .. tostring(idx) .. " ("..tostring(odd_sector)..") from " .. tostring(from) .. " to " .. tostring(to))
			local segment = Bitmap(self, textures[color])
			segment.Left   = function() return self:centerX() end
			segment.Bottom = function() return self:centerY() end

			if not odd_sector then
				segment.Width  = function () return math.ceil(self.Width() / 2) end
				segment.Height = function () return math.ceil(self.Height() / 2 * to*8) end
			else
				segment.Width  = function () return math.ceil(self.Width() / 2 * (1-from*8)) end
				segment.Height = function () return math.ceil(self.Height() / 2) end
			end

			if odd_sector then
				-- flip image along diagonal
				segment:SetUV(1, 1, 0, 0)
			else
				if to >= 1/8-0.01 then
					-- hack to prevent ugly seams
					-- smear out texture a bit so that we overlap slightly into next sector
					-- TODO: try fixing the texture 
					-- TODO: or alternatively, put something of the same color behind the two sectors
					segment:SetUV(0.02, 0.02, 1, 1)
				end
			end

			segment.Depth:Set(function () return self.Depth() + 50 - idx end) -- hack to sort this in reverse (let's hope there aren't ever more than 50 segments...)

			table.insert(self.pie_elements, segment)
		end

	end


}