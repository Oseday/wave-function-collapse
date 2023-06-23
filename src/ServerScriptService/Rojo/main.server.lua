local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WaveFunctionCollapse = require(ReplicatedStorage.Rojo.WaveFunctionCollapse)

local function testWaveFunctionCollapse()
    -- Initialize the module
    local wfc = WaveFunctionCollapse.new({
        SizeMagnitude = 1,
		CornersIncluded = false,
    })

    -- Add a voxel
    wfc:AddVoxel("Voxel1")
    wfc:AddVoxel("Voxel2")
    wfc:AddVoxel("Voxel3")
    wfc:AddVoxel("Voxel4")
    wfc:AddVoxel("Voxel5")
    wfc:AddVoxel("Voxel6")

    wfc:GenerateAllPossibilities()

    -- Give an example grid
    local exampleGrid = {
        [Vector3.new(1, 1, 1)] = {Orientation = CFrame.new(), Name = "Voxel1"},
        [Vector3.new(2, 1, 1)] = {Orientation = CFrame.new(), Name = "Voxel2"},
        [Vector3.new(1, 1, 2)] = {Orientation = CFrame.new(), Name = "Voxel2"},
        [Vector3.new(2, 1, 2)] = {Orientation = CFrame.new(), Name = "Voxel1"},
        
        [Vector3.new(1, 1, 3)] = {Orientation = CFrame.new(), Name = "Voxel1"},
        [Vector3.new(2, 1, 3)] = {Orientation = CFrame.new(), Name = "Voxel2"},
        


        [Vector3.new(1, 1, 4)] = {Orientation = CFrame.new(), Name = "Voxel3"},
        [Vector3.new(2, 1, 4)] = {Orientation = CFrame.new(), Name = "Voxel4"},
        
        [Vector3.new(1, 1, 5)] = {Orientation = CFrame.new(), Name = "Voxel4"},
        [Vector3.new(2, 1, 5)] = {Orientation = CFrame.new(), Name = "Voxel3"},
        
        [Vector3.new(1, 1, 6)] = {Orientation = CFrame.new(), Name = "Voxel3"},
        [Vector3.new(2, 1, 6)] = {Orientation = CFrame.new(), Name = "Voxel4"},
        


        [Vector3.new(2, 1, 7)] = {Orientation = CFrame.new(), Name = "Voxel3"},
        [Vector3.new(1, 1, 7)] = {Orientation = CFrame.new(), Name = "Voxel4"},
        
        [Vector3.new(2, 1, 8)] = {Orientation = CFrame.new(), Name = "Voxel4"},
        [Vector3.new(1, 1, 8)] = {Orientation = CFrame.new(), Name = "Voxel3"},
        
        [Vector3.new(2, 1, 9)] = {Orientation = CFrame.new(), Name = "Voxel3"},
        [Vector3.new(1, 1, 9)] = {Orientation = CFrame.new(), Name = "Voxel4"},
        


        [Vector3.new(1, 1, 10)] = {Orientation = CFrame.new(), Name = "Voxel5"},
        [Vector3.new(2, 1, 10)] = {Orientation = CFrame.new(), Name = "Voxel6"},
        
        [Vector3.new(1, 1, 11)] = {Orientation = CFrame.new(), Name = "Voxel6"},
        [Vector3.new(2, 1, 11)] = {Orientation = CFrame.new(), Name = "Voxel5"},
        
        [Vector3.new(1, 1, 12)] = {Orientation = CFrame.new(), Name = "Voxel5"},
        [Vector3.new(2, 1, 12)] = {Orientation = CFrame.new(), Name = "Voxel6"},
    }

    wfc:GiveExampleGrid(exampleGrid)

    local starterGrid = {
        [Vector3.new(1, 1, 1)] = {Orientation = CFrame.new(), Name = "Voxel1"},
    }

    -- Generate a grid
    local generatedGrid = wfc:Generate(Vector3.new(64, 1, 64), starterGrid)

    print(generatedGrid)

    -- Check if the grid was generated successfully
    assert(generatedGrid, "Failed to generate grid")
end

--testWaveFunctionCollapse()
local function testWaveFunctionCollapse2() 

local ExamplesFolder = workspace.Examples

local voxels = {}

for _, folder in ExamplesFolder:GetChildren() do
    for _, part:Part in folder:GetChildren() do
        table.insert(voxels, {
            Name = part.BrickColor.Name,
            Color = part.Color,
        })
    end
end

local wfc
wfc = WaveFunctionCollapse.new({
    SizeMagnitude = 1,
    CornersIncluded = true,
	ConstraintFunction = function(grid, voxel, position) 

		if voxel.Name == "Deep orange" then
			if wfc.CountCollapsedVoxels["Deep orange"] >= 3 then
				return false
			end
		end

		--Check the 6 sides and make sure at least one of them is a voxel
		local hasNeighbor = false

		for _, direction in ipairs({Vector3.new(0, 0, 1), Vector3.new(0, 0, -1), Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, -1, 0)}) do
			local nindex = WaveFunctionCollapse.Vector3ToIndex(position + direction)
			local nvoxel = grid[nindex]
			if nvoxel then
				hasNeighbor = true
				break
			end
		end

		if not hasNeighbor then
			return false
		end

		--if voxel.Name == "Black" then
		--	local nindex = WaveFunctionCollapse.Vector3ToIndex(position + voxel.Orientation * Vector3.new(0, 0, -1))
		--	local nvoxel = grid[nindex]
		--	if not nvoxel or nvoxel.Name ~= "Shamrock" then
		--		return false
		--	end
		--end

		return true
	end
})

for _, voxel in ipairs(voxels) do
    wfc:AddVoxel(voxel.Name, voxel.Color)
end

wfc:GenerateAllPossibilities()

local ExampleTables = {}

for i, folder in ExamplesFolder:GetChildren() do
    local name = i
    ExampleTables[name] = {}
    for _, part:Part in folder:GetChildren() do
        local x, y, z = part.Position.X, part.Position.Y, part.Position.Z
        local orientation = part.CFrame - part.Position
        ExampleTables[name][Vector3.new(x, y, z)] = {
            Orientation = orientation,
            Name = part.BrickColor.Name,
        }
    end
end

for name, exampleTable in pairs(ExampleTables) do
    wfc:GiveExampleGrid(exampleTable)
end

local starterGrid = {
    [Vector3.new(10, 1, 10)] = {Orientation = CFrame.new(), Name = "Forest green"},
}

local generatedGrid = wfc:Generate(Vector3.new(64, 1, 64), starterGrid)

print(wfc.VoxelList)

local i = 0

while true do

	i = i + 1

    local generatedGrid = wfc:Generate(Vector3.new(64, 1, 64), starterGrid)
    
	for _, voxel in pairs(generatedGrid) do
		if voxel.Name == "CGA brown" then
			--task.wait(3)
		end
	end

	task.wait(.1)

	if i % 10 == 0 then
    	task.wait()
	end
end

end

--testWaveFunctionCollapse2()

local function testWaveFunctionCollapse3()
	local RoomGenerator = require(ReplicatedStorage.Rojo.RoomGenerator)

	local rg = RoomGenerator.new()

	rg:AddRoom(workspace.Start)
	rg:AddRoom(workspace.End)
	rg:AddRoom(workspace.Middle)

	rg:GenerateAllPossibilities()

	rg:AddExample({
		[Vector3.new(0, 0, 10)] = {
			Orientation = CFrame.new(),
			Name = "Start",
		},
		[Vector3.new(0, 0, 9)] = {
			Orientation = CFrame.new(),
			Name = "Middle",
		},
		[Vector3.new(0, 0, 8)] = {
			Orientation = CFrame.new(),
			Name = "End",
		},
		
	})

	local folder = rg:Generate("Start", CFrame.new(0,10,0))

	folder.Parent = workspace
end


local RoomGenerator = require(ReplicatedStorage.Rojo.RoomGenerator)

local rg
rg = RoomGenerator.new(function(grid, voxel, position)
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

	return true
end, function(grid)
	local totalCount = 0

	local totalEndCount = 0

	for _, voxel in pairs(grid) do
		totalCount = totalCount + 1
		if voxel.Name == "End" then
			totalEndCount = totalEndCount + 1
		end
	end

	if totalEndCount ~= 1 then
		return false
	end

	if totalCount < 8 then
		return false
	end

	return true
end)

for _, room in ipairs(workspace.Rooms:GetChildren()) do
	rg:AddRoom(room)
end

rg:GenerateAllPossibilities()

local ExampleTables = {}

for i, folder in workspace.LayoutExamples:GetChildren() do
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

while true do
	local folder = rg:GenerateUntilNoErrors("Start", CFrame.new(0,100,0))

	folder.Parent = workspace
	
	task.wait(0.4)

	folder:Destroy()
end
