local WaveFunctionCollapse = require(script.Parent.WaveFunctionCollapse)

local RoomGenerator = {}

local class = {}
class.__index = class

function RoomGenerator.new(voxelConstraintFunction: WaveFunctionCollapse.ConstraintFunction?, gridConstraintFunction: ((grid: WaveFunctionCollapse.Grid) -> boolean)?)
	local self = setmetatable({}, class)

	self.WFC = WaveFunctionCollapse.new({
		SizeMagnitude = 1,
		CornersIncluded = true,
		ConstraintFunction = voxelConstraintFunction,
	})

	self.Rooms = {}

	self.GridConstraintFunction = typeof(gridConstraintFunction) == "function" and gridConstraintFunction or nil

	return self
end

local AttachmentNameToDirection = {
	Front = Vector3.new(0, 0, -1),
	Back = Vector3.new(0, 0, 1),
	Left = Vector3.new(-1, 0, 0),
	Right = Vector3.new(1, 0, 0),
	Top = Vector3.new(0, 1, 0),
	Bottom = Vector3.new(0, -1, 0),
}

function class:AddRoom(room: Model)
	if self.GeneratedAllPossibilities then
		error("Cannot add room after generating all possibilities")
	end

	local roomName = room.Name

	assert(not self.Rooms[roomName], "Room " .. roomName .. " already exists")
	
	local attachmentsPart = room:FindFirstChild("Attachments")
	assert(attachmentsPart, "Missing Attachments part in room " .. roomName)

	local attachments = attachmentsPart:GetChildren()
	assert(#attachments > 0, "No attachments found in room " .. roomName)

	local roomData = {
		Attachments = {},
		Name = roomName,
		Model = room,
	}

	room.PrimaryPart = attachmentsPart

	for _, attachment: Attachment in ipairs(attachments) do
		local attachmentName = attachment.Name
		local direction = AttachmentNameToDirection[attachmentName]
		assert(direction, "Invalid attachment name " .. attachmentName .. " in room " .. roomName)

		local attachmentData = {
			Direction = direction,
			CFrame = attachment.CFrame,
		}

		table.insert(roomData.Attachments, attachmentData)
	end

	self.Rooms[roomName] = roomData

	self.WFC:AddVoxel(roomName)
end

function class:GenerateAllPossibilities()
	if self.GeneratedAllPossibilities then
		error("Already generated all possibilities")
	end

	self.WFC:GenerateAllPossibilities()

	self.GeneratedAllPossibilities = true
end

function class:AddExample(grid: WaveFunctionCollapse.Grid)
	if not self.GeneratedAllPossibilities then
		self:GenerateAllPossibilities()
	end

	self.WFC:GiveExampleGrid(grid)
end 

local DEBUG_MODE = true

function class:Generate(starterRoomName: string, originCFrame: CFrame) : Folder
	assert(typeof(starterRoomName) == "string", "Invalid starter room name " .. tostring(starterRoomName))
	assert(typeof(originCFrame) == "CFrame", "Invalid origin CFrame " .. tostring(originCFrame))

	if not self.GeneratedAllPossibilities then
		self:GenerateAllPossibilities()
	end

	local roomData = self.Rooms[starterRoomName]
	assert(roomData, "Invalid starter room name " .. starterRoomName)

	local folder = Instance.new("Folder")

	if DEBUG_MODE then
		folder.Name = "RoomGeneratorDebug"
		folder.Parent = workspace
	end
	

	local starterGrid = {
		[Vector3.new(32, 1, 32)] = {Orientation = CFrame.new(), Name = starterRoomName},
	}

	local grid: {[Vector3]: WaveFunctionCollapse.Voxel} 

	while true do
		grid = self.WFC:Generate(Vector3.new(64,1,64), starterGrid)

		if not self.GridConstraintFunction then
			break
		end

		if self.GridConstraintFunction(grid) then
			break
		end
	end

	grid = self.WFC:ConvertGridIndexToPosition(grid)

	local queue = {Vector3.new(32, 1, 32)}

	local firstRoomModel: Model = roomData.Model:Clone()
	firstRoomModel:PivotTo(originCFrame)
	firstRoomModel.Parent = folder

	local visitedRoomCFrames = {
		[Vector3.new(32, 1, 32)] = originCFrame,
	}

	local visited = {}

	while #queue > 0 do
		local currentPos = table.remove(queue, 1)
		local currentVoxel = grid[currentPos]
		local currentRoomData = self.Rooms[currentVoxel.Name]
		local currentRoomCFrame = visitedRoomCFrames[currentPos]

		if not visited[currentPos] then
			visited[currentPos] = true

			for _, attachmentData in ipairs(currentRoomData.Attachments) do
				local nextDirection: Vector3 = currentVoxel.Orientation * attachmentData.Direction -- This is the direction of the attachment in world space
				local nextPos: Vector3 = currentPos + currentVoxel.Orientation * attachmentData.Direction

				if not grid[nextPos] then
					folder:Destroy()
					error("Missing voxel at position " .. tostring(nextPos) .. ". This should not happen. The grid was not generated correctly.")
				end

				if grid[nextPos] and not visited[nextPos] then
					local nextVoxel = grid[nextPos]
					local nextRoomData = self.Rooms[nextVoxel.Name]
					local nextAttachmentData

					for _, attachment in ipairs(nextRoomData.Attachments) do
						if ((nextVoxel.Orientation) * -attachment.Direction - nextDirection).Magnitude < 0.01 then
							nextAttachmentData = attachment
							break
						end
					end

					if not nextAttachmentData then
						folder:Destroy()
						error("Missing attachment data for room " .. nextRoomData.Name .. " in direction " .. tostring(nextDirection))
					end

					local nextRoomModel: Model = nextRoomData.Model:Clone()

					--Set the pivot such that the two attachments have the same world CFrame
					local newRoomCFrame = currentRoomCFrame * (attachmentData.CFrame * CFrame.Angles(0,math.pi,0)) * nextAttachmentData.CFrame:Inverse()
					nextRoomModel:PivotTo( newRoomCFrame )

					if DEBUG_MODE then
						task.wait(0.3)
					end

					visitedRoomCFrames[nextPos] = newRoomCFrame

					nextRoomModel.Parent = folder

					table.insert(queue, nextPos)
				end
			end
		end
	end

	return folder
end

function class:GenerateUntilNoErrors(starterRoomName: string, originCFrame: CFrame) : Folder
	for i = 1, 100 do
		local success, result = pcall(function()
			return self:Generate(starterRoomName, originCFrame)
		end)

		if success then
			return result
		else
			warn("Failed to generate room: " .. tostring(result))
		end
	end

	error("Failed to generate room after 100 attempts")
end


return RoomGenerator