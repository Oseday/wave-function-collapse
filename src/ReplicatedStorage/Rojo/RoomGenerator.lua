local RoomGenerator = {}

local class = {}
class.__index = class

function class.new()
	local self = setmetatable({}, class)

	return self
end