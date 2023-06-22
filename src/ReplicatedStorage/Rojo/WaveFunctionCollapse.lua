-- Implements Wave Function Collapse

local WaveFunctionCollapse = {}

local class = {} 
class.__index = class

local DebugFolder = Instance.new("Folder", workspace)

local DebugColors = {} :: {[string]: Color3}

local function _PlaceDebugPart(cframe: CFrame, voxelName: string)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(1, 1, 1)
	part.CFrame = cframe
	part.Color = DebugColors[voxelName] or Color3.new(1, 1, 1)
	part.Parent = DebugFolder
end

local function IsCorner(x,y,z,SizeMagnitude)
	return math.abs(x) + math.abs(y) + math.abs(z) >= (SizeMagnitude + 1)
end

export type Options = {
	SizeMagnitude: number,
	CornersIncluded: boolean,
	ConstraintFunction: ((grid: Grid, voxel: Voxel, position: Vector3) -> boolean)?, -- Return true if the voxel is allowed to be placed at this position
}

export type VoxelName = string

export type Voxel = {
	Orientation: CFrame,
	Name: VoxelName,
}

export type Index = number

local function Vector3ToIndex(vector: Vector3) : Index
	return math.round(vector.Z + vector.X * 1000 + vector.Y * 1000000)
end

local function IndexToVector3(index: number) : Vector3
	local z = index % 1000
	local x = math.floor(index / 1000) % 1000
	local y = math.floor(index / 1000000)

	return Vector3.new(x, y, z)
end

WaveFunctionCollapse.Vector3ToIndex = Vector3ToIndex
WaveFunctionCollapse.IndexToVector3 = IndexToVector3

export type Grid = {
	[Index]: Voxel,
}

export type GridOfPossibilities = {
	[Index]: {
		Voxels: {Voxel},
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

local function OrientationsEqual(a: CFrame, b: CFrame) : boolean
    local lookVectorDot = a.LookVector:Dot(b.LookVector)
    local upVectorDot = a.UpVector:Dot(b.UpVector)
    return lookVectorDot > 0.999 and upVectorDot > 0.999
end

function WaveFunctionCollapse.new(options: Options)
	local self = setmetatable({}, class)

	self.SizeMagnitude = options.SizeMagnitude or 1
	self.CornersIncluded = if options.CornersIncluded~=nil then options.CornersIncluded else true
	print("self.CornersIncluded", self.CornersIncluded)
	self.ConstraintFunction = options.ConstraintFunction

	self.CountCollapsedVoxels = {} :: {[VoxelName]: number}

	self.VoxelList = {} :: VoxelList

	return self
end

function class:Generate(size: Vector3, starterGrid: Grid) : Grid

	DebugFolder:ClearAllChildren()

	local grid: Grid = {}

	if not next(starterGrid) then
		error("Starter grid is empty")
	end

	self.CountCollapsedVoxels = {} :: {[VoxelName]: number}

	for voxelName in pairs(self.VoxelList) do
		self.CountCollapsedVoxels[voxelName] = 0
	end

	for position, voxel in pairs(starterGrid) do
		grid[Vector3ToIndex(position)] = voxel
		self.CountCollapsedVoxels[voxel.Name] += 1
	end

	local gridOfPossibilities: GridOfPossibilities = {}


	local voxelList: VoxelList = self.VoxelList

	--print(voxelList)

	local function UpdateVoxelInformation(position: Vector3)

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

					if not self.CornersIncluded then
						if IsCorner(tx, ty, tz, self.SizeMagnitude) then
							continue
						end
					end

					local offset = Vector3.new(tx, ty, tz)

					local neighborPosition = position + offset
					

					local neighbor = grid[Vector3ToIndex(neighborPosition)]

					if not neighbor then
						continue
					end

					local neighborName = neighbor.Name
					local neighborOrientation = neighbor.Orientation

					local realOffset = neighborOrientation:Inverse() * offset

					local possibilities = voxelList[neighborName].Possibilites[Vector3ToIndex(-realOffset)]

					local weightadd =  - (math.abs(tx) + math.abs(ty) + math.abs(tz)) / (3)
					
					
					for k, possibility in pairs(allPossibilities) do
						local weight = nil

						for k2, neighborPossibility in pairs(possibilities) do
							if possibility.Name == neighborPossibility.Name and OrientationsEqual(possibility.Orientation, neighborOrientation * neighborPossibility.Orientation) then
								weight = (weight or 0) + neighborPossibility.Weight + weightadd
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

		if self.ConstraintFunction then
			for k, possibility in pairs(allPossibilities) do
				if not self.ConstraintFunction(grid, possibility, position) then
					allPossibilities[k] = nil
				end
			end
		end

		if not next(allPossibilities) then
			gridOfPossibilities[index] = {
				Voxels = allPossibilities,
				Weight = 0,
			}
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
	
	local maxDepth = 10
	local depth = 0

	local function CollapseHighestPossibilityVoxel()
		local highestWeight = 0
		local highestWeightPosition = nil

		for position, possibilities in pairs(gridOfPossibilities) do
			if possibilities.Weight >= highestWeight then
				highestWeight = possibilities.Weight
				highestWeightPosition = position
			end
		end

		if not gridOfPossibilities[highestWeightPosition] then

			depth = depth + 1
			if maxDepth < depth then
				return false
			end

			-- Recalculate possibilities in gridOfPossibilities
			for position, voxel in pairs(gridOfPossibilities) do
				UpdateVoxelInformation(IndexToVector3(position))
			end

			return true
		end

		local possibilities = gridOfPossibilities[highestWeightPosition].Voxels

		local totalWeight = 0

		for k, possibility in pairs(possibilities) do
			totalWeight = totalWeight + possibility.Weight
		end

		local randomWeight = (math.random(0, totalWeight) / totalWeight) ^ 2 * totalWeight

		local currentWeight = 0

		for k, possibility in pairs(possibilities) do
			currentWeight = currentWeight + possibility.Weight

			if currentWeight >= randomWeight then
				grid[highestWeightPosition] = possibility
				gridOfPossibilities[highestWeightPosition] = nil

				local pos = IndexToVector3(highestWeightPosition)

				_PlaceDebugPart(possibility.Orientation + Vector3.new(pos.X, pos.Y, pos.Z), possibility.Name)

				self.CountCollapsedVoxels[possibility.Name] += 1

				--if math.random() < 0.1 then
				--	task.wait()
				--end


				for x = -self.SizeMagnitude,self.SizeMagnitude do
					for y = -self.SizeMagnitude,self.SizeMagnitude do
						for z = -self.SizeMagnitude,self.SizeMagnitude do
							if x==0 and y==0 and z==0 then
								continue
							end

							if not self.CornersIncluded then
								if IsCorner(x, y, z, self.SizeMagnitude) then
									continue
								end
							end

							local position = IndexToVector3(highestWeightPosition) + Vector3.new(x, y, z)

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

	_PlaceDebugPart(startVoxel.Orientation + Vector3.new(starterPosition.X, starterPosition.Y, starterPosition.Z), startVoxel.Name)

	if not starterPosition then
		error("Need at least one voxel inside the starterGrid")
	end

	for x = -self.SizeMagnitude,self.SizeMagnitude do
		for y = -self.SizeMagnitude,self.SizeMagnitude do
			for z = -self.SizeMagnitude,self.SizeMagnitude do
				if x==0 and y==0 and z==0 then
					continue
				end

				if not self.CornersIncluded then
					if IsCorner(x, y, z, self.SizeMagnitude) then
						continue
					end
				end

				local offset = Vector3.new(x, y, z)
				UpdateVoxelInformation(starterPosition + offset)
			end
		end
	end

	while true do
		if not next(gridOfPossibilities) then
			break
		end
		if not CollapseHighestPossibilityVoxel() then
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

				if not self.CornersIncluded then
					if IsCorner(x, y, z, self.SizeMagnitude) then
						continue
					end
				end

				local offset = Vector3.new(x, y, z)
				local offsetIndex = Vector3ToIndex(offset)
				self.VoxelList[voxelName].Possibilites[offsetIndex] = {}
			end
		end
	end
end 

function class:AddEmptyVoxel()
	self:AddVoxel("Empty")
end

function class:ExtractPatternFromGridPosition(grid: Grid, position: Vector3)
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

				if not self.CornersIncluded then
					if IsCorner(x, y, z, self.SizeMagnitude) then
						continue
					end
				end

				local offset = Vector3.new(x, y, z)
				local offsetIndex = Vector3ToIndex(offset)

				local neighborPosition = position + voxelOrientation * offset
				local neighborPositionIndex = Vector3ToIndex(neighborPosition)

				local neighbor = grid[neighborPositionIndex]

				if not neighbor then
					continue
				end

				-- Add this neighbor to the list of possibilities
				local neighborName = neighbor.Name
				local neighborOrientation = voxelOrientation:Inverse() * neighbor.Orientation

				local possibilities = voxelList[voxelName].Possibilites[offsetIndex]

				local weightadd = 1
				--if voxelName == neighborName and RotationsEqual(voxelOrientation, neighborOrientation) then
				--	weightadd = 1
				--end

				local found = false
				for k, possibility in pairs(possibilities) do
					if possibility.Name == neighborName and RotationsEqual(possibility.Orientation, neighborOrientation) then
						possibility.Weight = possibility.Weight + weightadd
						found = true
						break
					end
				end
				
				if found then
					continue
				end

				table.insert(voxelList[voxelName].Possibilites[offsetIndex], {
					Name = neighborName,
					Weight = weightadd,
					Orientation = neighborOrientation,
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