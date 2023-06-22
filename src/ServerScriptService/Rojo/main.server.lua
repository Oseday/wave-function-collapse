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
			if wfc.CountCollapsedVoxels["Deep orange"] >= 2 then
				return false
			end
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
			task.wait(3)
		end
	end

	if i % 10 == 0 then
    	task.wait()
	end
end
