local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DungeonGenerator = require(ReplicatedStorage.Rojo.DungeonGenerator)

local dungeonTemplateFolder = workspace.DungeonTemplate1

local dg = DungeonGenerator.new(dungeonTemplateFolder)

while true do
local folder = dg:Generate("Start" , CFrame.new(0,20,0)) 

folder.Parent = workspace

task.wait(1)

folder:ClearAllChildren()

print("Generated")
end