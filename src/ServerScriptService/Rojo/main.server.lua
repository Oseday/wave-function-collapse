local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WaveFunctionCollapse = require(ReplicatedStorage.Rojo.WaveFunctionCollapse)

local function testWaveFunctionCollapse()
    -- Initialize the module
    local wfc = WaveFunctionCollapse.new({
        SizeMagnitude = 1
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
        [Vector3int16.new(1, 1, 1)] = {Orientation = CFrame.new(), Name = "Voxel1"},
        [Vector3int16.new(2, 1, 1)] = {Orientation = CFrame.new(), Name = "Voxel2"},
        [Vector3int16.new(1, 1, 2)] = {Orientation = CFrame.new(), Name = "Voxel2"},
        [Vector3int16.new(2, 1, 2)] = {Orientation = CFrame.new(), Name = "Voxel1"},
        
        [Vector3int16.new(1, 1, 3)] = {Orientation = CFrame.new(), Name = "Voxel1"},
        [Vector3int16.new(2, 1, 3)] = {Orientation = CFrame.new(), Name = "Voxel2"},
        


        [Vector3int16.new(1, 1, 4)] = {Orientation = CFrame.new(), Name = "Voxel3"},
        [Vector3int16.new(2, 1, 4)] = {Orientation = CFrame.new(), Name = "Voxel4"},
        
        [Vector3int16.new(1, 1, 5)] = {Orientation = CFrame.new(), Name = "Voxel4"},
        [Vector3int16.new(2, 1, 5)] = {Orientation = CFrame.new(), Name = "Voxel3"},
        
        [Vector3int16.new(1, 1, 6)] = {Orientation = CFrame.new(), Name = "Voxel3"},
        [Vector3int16.new(2, 1, 6)] = {Orientation = CFrame.new(), Name = "Voxel4"},
        


        [Vector3int16.new(2, 1, 7)] = {Orientation = CFrame.new(), Name = "Voxel3"},
        [Vector3int16.new(1, 1, 7)] = {Orientation = CFrame.new(), Name = "Voxel4"},
        
        [Vector3int16.new(2, 1, 8)] = {Orientation = CFrame.new(), Name = "Voxel4"},
        [Vector3int16.new(1, 1, 8)] = {Orientation = CFrame.new(), Name = "Voxel3"},
        
        [Vector3int16.new(2, 1, 9)] = {Orientation = CFrame.new(), Name = "Voxel3"},
        [Vector3int16.new(1, 1, 9)] = {Orientation = CFrame.new(), Name = "Voxel4"},
        


        [Vector3int16.new(1, 1, 10)] = {Orientation = CFrame.new(), Name = "Voxel5"},
        [Vector3int16.new(2, 1, 10)] = {Orientation = CFrame.new(), Name = "Voxel6"},
        
        [Vector3int16.new(1, 1, 11)] = {Orientation = CFrame.new(), Name = "Voxel6"},
        [Vector3int16.new(2, 1, 11)] = {Orientation = CFrame.new(), Name = "Voxel5"},
        
        [Vector3int16.new(1, 1, 12)] = {Orientation = CFrame.new(), Name = "Voxel5"},
        [Vector3int16.new(2, 1, 12)] = {Orientation = CFrame.new(), Name = "Voxel6"},
    }

    wfc:GiveExampleGrid(exampleGrid)

    local starterGrid = {
        [Vector3int16.new(1, 1, 1)] = {Orientation = CFrame.new(), Name = "Voxel1"},
    }

    -- Generate a grid
    local generatedGrid = wfc:Generate(Vector3int16.new(64, 1, 64), starterGrid)

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

local wfc = WaveFunctionCollapse.new({
    SizeMagnitude = 1
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
        local orientation = part.CFrame
        ExampleTables[name][Vector3int16.new(x, y, z)] = {
            Orientation = orientation,
            Name = part.BrickColor.Name,
        }
    end
end

for name, exampleTable in pairs(ExampleTables) do
    wfc:GiveExampleGrid(exampleTable)
end

local starterGrid = {
    [Vector3int16.new(1, 1, 1)] = {Orientation = CFrame.new(), Name = "Forest green"},
}

while task.wait(.1) do

    local generatedGrid = wfc:Generate(Vector3int16.new(64, 1, 64), starterGrid)

end
