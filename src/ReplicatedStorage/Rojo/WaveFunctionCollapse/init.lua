-- Implements Wave Function Collapse

local WaveFunctionCollapse = {}

local class = {} 
class.__index = class

local DebugFolder = Instance.new("Folder", workspace)

local DebugColors = {} :: {[string]: Color3}

local function _PlaceDebugPart(position: Vector3int16, voxelName: string)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(1, 1, 1)
	part.Position = Vector3.new(position.X, position.Y, position.Z)
	part.Color = DebugColors[voxelName] or Color3.new(1, 1, 1)
	part.Parent = DebugFolder
end


export type Options = {
	SizeMagnitude: number,
}

export type VoxelName = string

export type Voxel = {
	Orientation: CFrame,
	Name: VoxelName,
}

export type Index = number

local function Vector3ToIndex(vector: Vector3int16) : Index
	return math.round(vector.X + vector.Y * 1000 + vector.Z * 1000000)
end

local function IndexToVector3(index: number) : Vector3int16
	local x = index % 1000
	local y = math.floor(index / 1000) % 1000
	local z = math.floor(index / 1000000)

	return Vector3int16.new(x, y, z)
end

export type Grid = {
	[Index]: Voxel,
}

export type GridOfPossibilities = {
	[Index]: {
		Voxels: Voxel,
		Weight: number,
	},
}

export type VoxelList = {
	[VoxelName]: {
		Possibilites: {
			[Index]: { 
				{
					Name: VoxelName,  
					Weight: number, 
					Orientation: CFrame,
				}
			}
		}
	}
}

local function GetRotationFromTo(from: CFrame, to: CFrame) : Vector3
	local rCF = from:Inverse() * to
	local axis, angle = rCF:ToAxisAngle()
	return axis * angle
end

local function RotationsEqual(a: CFrame, b: CFrame) : boolean
	return GetRotationFromTo(a, b).Magnitude < 0.01
end

function WaveFunctionCollapse.new(options: Options) : typeof(class)
	local self = setmetatable({}, class)

	self.SizeMagnitude = options.SizeMagnitude or 1

	self.VoxelList = {}

	return self
end

function class:Generate(size: Vector3int16, starterGrid: Grid) : Grid

	DebugFolder:ClearAllChildren()

	local grid: Grid = {}

	if not next(starterGrid) then
		error("Starter grid is empty")
	end

	for position, voxel in pairs(starterGrid) do
		grid[Vector3ToIndex(position)] = voxel
	end

	local gridOfPossibilities: GridOfPossibilities = {}

	local voxelList: VoxelList = self.VoxelList

	local function UpdateVoxelInformation(position: Vector3int16)

		if position.X > size.X then
			return
		end
		if position.Y > size.Y then
			return
		end
		if position.Z > size.Z then
			return
		end
		
		if position.X < 1 then 
			return 
		end
		if position.Y < 1 then 
			return 
		end
		if position.Z < 1 then 
			return 
		end

		local index = Vector3ToIndex(position)
		local voxel = grid[index]

		if voxel then
			return
		end

		local allPossibilities = table.clone(self.AllPossibilities) :: {Voxel}

		for tx = -self.SizeMagnitude,self.SizeMagnitude do
			for ty = -self.SizeMagnitude,self.SizeMagnitude do
				for tz = -self.SizeMagnitude,self.SizeMagnitude do
					if tx==0 and ty==0 and tz==0 then
						continue
					end

					local offset = Vector3int16.new(tx, ty, tz)

					local neighborPosition = position + offset
					

					local neighbor = grid[Vector3ToIndex(neighborPosition)]

					if not neighbor then
						continue
					end

					local neighborName = neighbor.Name
					local neighborOrientation = neighbor.Orientation

					local possibilities = voxelList[neighborName].Possibilites[Vector3ToIndex(-offset)]

					
					for k, possibility in pairs(allPossibilities) do
						local weight = nil

						for k2, neighborPossibility in pairs(possibilities) do
							if possibility.Name == neighborPossibility.Name and RotationsEqual(possibility.Orientation, neighborOrientation * neighborPossibility.Orientation) then
								weight = (weight or 0) + neighborPossibility.Weight
								break
							end
						end

						if not weight then
							allPossibilities[k] = nil
						else
							possibility.Weight = weight
						end
					end

				end
			end
		end

		if not next(allPossibilities) then
			--gridOfPossibilities[index] = {
			--	Voxels = allPossibilities,
			--	Weight = 0,
			--}
			return
			--error("No possibilities for voxel at " .. tostring(position))
		end

		local totalWeight = 0

		for k, possibility in pairs(allPossibilities) do
			totalWeight = totalWeight + possibility.Weight
		end

		gridOfPossibilities[index] = {
			Voxels = allPossibilities,
			Weight = totalWeight,
		}
	end
	
	local function CollapseHighestPossibilityVoxel()
		local highestWeight = 0
		local highestWeightPosition = nil

		for position, possibilities in pairs(gridOfPossibilities) do
			if possibilities.Weight > highestWeight then
				highestWeight = possibilities.Weight
				highestWeightPosition = position
			end
		end

		if not gridOfPossibilities[highestWeightPosition] then
			return false
		end

		local possibilities = gridOfPossibilities[highestWeightPosition].Voxels

		local totalWeight = 0

		for k, possibility in pairs(possibilities) do
			totalWeight = totalWeight + possibility.Weight
		end

		local randomWeight = math.random(0, totalWeight)

		local currentWeight = 0

		for k, possibility in pairs(possibilities) do
			currentWeight = currentWeight + possibility.Weight

			if currentWeight >= randomWeight then
				grid[highestWeightPosition] = possibility
				gridOfPossibilities[highestWeightPosition] = nil

				_PlaceDebugPart(IndexToVector3(highestWeightPosition), possibility.Name)

				--if math.random() < 0.1 then
				--	task.wait()
				--end


				for x = -self.SizeMagnitude,self.SizeMagnitude do
					for y = -self.SizeMagnitude,self.SizeMagnitude do
						for z = -self.SizeMagnitude,self.SizeMagnitude do
							if x==0 and y==0 and z==0 then
								continue
							end

							local position = IndexToVector3(highestWeightPosition) + Vector3int16.new(x, y, z)

							UpdateVoxelInformation(position)
						end
					end
				end

				return true
			end
		end
		
		return false
	end

	local starterPosition, startVoxel = next(starterGrid)

	_PlaceDebugPart(starterPosition, startVoxel.Name)

	if not starterPosition then
		error("Need at least one voxel inside the starterGrid")
	end

	for x = -self.SizeMagnitude,self.SizeMagnitude do
		for y = -self.SizeMagnitude,self.SizeMagnitude do
			for z = -self.SizeMagnitude,self.SizeMagnitude do
				if x==0 and y==0 and z==0 then
					continue
				end

				local offset = Vector3int16.new(x, y, z)
				UpdateVoxelInformation(starterPosition + offset)
			end
		end
	end

	while true do
		if not next(gridOfPossibilities) then
			print("Done, no gridOfPossibilities")
			break
		end
		if not CollapseHighestPossibilityVoxel() then
			print("Done, no CollapseHighestPossibilityVoxel")
			break
		end
	end


	return grid
end

function class:AddVoxel(voxelName: VoxelName, debugColor: Color3?)
	if self.VoxelList[voxelName] then
		return
	end

	DebugColors[voxelName] = debugColor or Color3.new(math.random(), math.random(), math.random())

	self.VoxelList[voxelName] = {
		Possibilites = {},
	}

	for x = -self.SizeMagnitude,self.SizeMagnitude do
		for y = -self.SizeMagnitude,self.SizeMagnitude do
			for z = -self.SizeMagnitude,self.SizeMagnitude do
				if x==0 and y==0 and z==0 then
					continue
				end

				local offset = Vector3int16.new(x, y, z)
				local offsetIndex = Vector3ToIndex(offset)
				self.VoxelList[voxelName].Possibilites[offsetIndex] = {}
			end
		end
	end
end 

function class:AddEmptyVoxel()
	self:AddVoxel("Empty")
end

function class:ExtractPatternFromGridPosition(grid: Grid, position: Vector3int16)
	local index = Vector3ToIndex(position)
	local voxel = grid[index]

	if not voxel then
		return nil
	end

	local voxelName = voxel.Name
	local voxelOrientation = voxel.Orientation

	if voxelName == "Empty" then
		return nil
	end

	local voxelList: VoxelList = self.VoxelList

	if not voxelList[voxelName] then
		error("Voxel " .. voxelName .. " is not registered")
	end

	for x = -self.SizeMagnitude, self.SizeMagnitude do
		for y = -self.SizeMagnitude, self.SizeMagnitude do
			for z = -self.SizeMagnitude, self.SizeMagnitude do
				if x==0 and y==0 and z==0 then
					continue
				end

				local offset = Vector3int16.new(x, y, z)
				local offsetIndex = Vector3ToIndex(offset)

				local neighborPosition = position + offset
				local neighborPositionIndex = Vector3ToIndex(neighborPosition)

				local neighbor = grid[neighborPositionIndex]

				if not neighbor then
					continue
				end

				-- Add this neighbor to the list of possibilities
				local neighborName = neighbor.Name
				local neighborOrientation = neighbor.Orientation

				local possibilities = voxelList[voxelName].Possibilites[offsetIndex]

				local found = false
				for k, possibility in pairs(possibilities) do
					if possibility.Name == neighborName and RotationsEqual(possibility.Orientation, neighborOrientation) then
						possibility.Weight = possibility.Weight + 1
						found = true
						break
					end
				end
				
				if found then
					continue
				end

				table.insert(voxelList[voxelName].Possibilites[offsetIndex], {
					Name = neighborName,
					Weight = 1,
					Orientation = voxelOrientation:Inverse() * neighborOrientation,
				})
			end
		end
	end

	return 
end

function class:GiveExampleGrid(grid: Grid)
	for position, voxel in pairs(grid) do
		self:AddVoxel(voxel.Name)
	end

	local ngrid = {}
	for position, voxel in pairs(grid) do
		local index = Vector3ToIndex(position)
		ngrid[index] = voxel
	end

	for position, voxel in pairs(grid) do
		self:ExtractPatternFromGridPosition(ngrid, position)
	end
end

function class:GenerateAllPossibilities()
	local voxelList: VoxelList = self.VoxelList

	local allPossibilities = {}

	for voxelName, voxel in pairs(voxelList) do
		table.insert(allPossibilities, {
			Name = voxelName,
			Orientation = CFrame.Angles(0, 0, 0),
		})
		table.insert(allPossibilities, {
			Name = voxelName,
			Orientation = CFrame.Angles(0, math.pi/2, 0),
		})
		table.insert(allPossibilities, {
			Name = voxelName,
			Orientation = CFrame.Angles(0, math.pi, 0),
		})
		table.insert(allPossibilities, {
			Name = voxelName,
			Orientation = CFrame.Angles(0, -math.pi/2, 0),
		})
	end

	self.AllPossibilities = allPossibilities
end

return WaveFunctionCollapse