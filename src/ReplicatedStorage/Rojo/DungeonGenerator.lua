local DungeonGenerator = {}

local RoomGenerator = require(script.Parent.RoomGenerator)

local class = {}
class.__index = class

function DungeonGenerator.new(dungeonTemplateFolder: Folder)
	local rooms = dungeonTemplateFolder:FindFirstChild("Rooms")
	assert(rooms, "Missing Rooms folder in dungeon template folder " .. dungeonTemplateFolder.Name)
	
	local examples = dungeonTemplateFolder:FindFirstChild("Examples")
	assert(examples, "Missing Examples folder in dungeon template folder " .. dungeonTemplateFolder.Name)

	assert(#rooms:GetChildren() > 0, "No rooms in dungeon template folder " .. dungeonTemplateFolder.Name)
	assert(#examples:GetChildren() > 0, "No examples in dungeon template folder " .. dungeonTemplateFolder.Name)

	local startRoom = rooms:FindFirstChild("Start")
	assert(startRoom, "Missing Start room in dungeon template Rooms folder " .. dungeonTemplateFolder.Name)

	local endRoom = rooms:FindFirstChild("End")
	assert(endRoom, "Missing End room in dungeon template Rooms folder " .. dungeonTemplateFolder.Name)

	local startRoomScript = startRoom:FindFirstChild("Script")
	assert(startRoomScript, "Missing Script in Start room in dungeon template Rooms folder " .. dungeonTemplateFolder.Name)
	assert(startRoomScript:IsA("ModuleScript"), "Start room script must be a ModuleScript")

	local endRoomScript = endRoom:FindFirstChild("Script")
	assert(endRoomScript, "Missing Script in End room in dungeon template Rooms folder " .. dungeonTemplateFolder.Name)
	assert(endRoomScript:IsA("ModuleScript"), "End room script must be a ModuleScript")

	local self = setmetatable({}, class)

	local rg

	local voxelConstraintFunction = function(grid, voxel, position)
		if voxel.Name == "Start" then
			if rg.WFC.CountCollapsedVoxels["Start"] >= 1 then
				return false
			end
		end
	
		if voxel.Name == "End" then
			if rg.WFC.CountCollapsedVoxels["End"] >= 1 then
				return false
			end
		end

		if voxel.Name == "RoomB" then
			if rg.WFC.CountCollapsedVoxels["RoomB"] >= 1 then
				return false
			end
		end
	
		return true
	end
	
	local gridConstraintFunction = function(grid)
		local startCount = rg.WFC.CountCollapsedVoxels["Start"]
		local endCount = rg.WFC.CountCollapsedVoxels["End"]
	
		if startCount == 0 or endCount == 0 then
			return false
		end

		local total = 0

		for _, ct in pairs(rg.WFC.CountCollapsedVoxels) do
			total = total + ct
		end
	
		if total <= 5 then
			return false
		end

		return true
	end

	rg = RoomGenerator.new(voxelConstraintFunction, gridConstraintFunction)

	self.RoomGenerator = rg

	for _, room in ipairs(rooms:GetChildren()) do
		rg:AddRoom(room)
	end

	local ExampleTables = {}

	for i, folder in examples:GetChildren() do
		local name = i

		ExampleTables[name] = {}

		for _, part:Part in folder:GetChildren() do
			local x, y, z = part.Position.X, part.Position.Y, part.Position.Z
			local orientation = part.CFrame - part.Position

			ExampleTables[name][Vector3.new(x, y, z)] = {
				Orientation = orientation,
				Name = part.Name,
			}
		end
	end

	for name, exampleTable in pairs(ExampleTables) do
		rg:AddExample(exampleTable)
	end

	return self
end


function class:Generate(starterRoomName: string, originCFrame: CFrame)
	local rg = self.RoomGenerator

	local dungeonFolder = rg:GenerateUntilNoErrors(starterRoomName, originCFrame)

	self.RoomScripts = {}

	for _, room in ipairs(dungeonFolder:GetChildren()) do
		local scriptRoom = room:FindFirstChild("Script")
		if scriptRoom and scriptRoom:IsA("ModuleScript") then
			local script = require(scriptRoom)
			self.RoomScripts[room] = script
		end
	end

	return dungeonFolder
end

function class:Start(originCFrame: CFrame, players: {Player})
	local dungeon = self:Generate("Start", originCFrame)
	
	local startRoom = dungeon:FindFirstChild("Start")
	assert(startRoom, "Missing start room in dungeon")

	local roomScripts = self.RoomScripts

	local startRoomScript = roomScripts[startRoom]
	assert(startRoomScript, "Missing start room script in dungeon")

	assert(#players > 0, "No players to start dungeon with")
	assert(startRoomScript.Start, "Start room script missing Start function")

	for _, roomScript in pairs(roomScripts) do
		if roomScript.Init then
			roomScript.Init(players)
		end
	end

	for _, roomScript in pairs(roomScripts) do
		if roomScript.Start then
			task.spawn(roomScript.Start, players)
		end
	end
	
end

return DungeonGenerator