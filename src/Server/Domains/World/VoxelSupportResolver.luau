--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VoxelTypes = require(ReplicatedStorage.Shared.Types.VoxelTypes)

type StructureRecord = VoxelTypes.StructureRecord
type PlotBounds = VoxelTypes.PlotBounds

local VoxelSupportResolver = {}

export type Occupancy = {
	-- key "cx:cy:cz" → true if solid (structure or filled cell)
	Solid: { [string]: boolean },
	Structures: { [string]: StructureRecord },
	Bounds: PlotBounds,
}

local function key(cx: number, cy: number, cz: number): string
	return `{cx}:{cy}:{cz}`
end

local function neighbors(cx: number, cy: number, cz: number): { { number } }
	return {
		{ cx + 1, cy, cz },
		{ cx - 1, cy, cz },
		{ cx, cy, cz + 1 },
		{ cx, cy, cz - 1 },
		{ cx, cy - 1, cz },
		{ cx, cy + 1, cz },
	}
end

-- Returns structure ids that lack a support path down to plot MinY.
function VoxelSupportResolver.unsupportedIds(occ: Occupancy): { string }
	local supportedCells: { [string]: boolean } = {}
	local queue: { string } = {}

	-- Ground row at MinY is supported if solid.
	for x = occ.Bounds.MinX, occ.Bounds.MaxX do
		for z = occ.Bounds.MinZ, occ.Bounds.MaxZ do
			local k = key(x, occ.Bounds.MinY, z)
			if occ.Solid[k] then
				supportedCells[k] = true
				table.insert(queue, k)
			end
		end
	end

	local qi = 1
	while qi <= #queue do
		local current = queue[qi]
		qi += 1
		local cx, cy, cz = string.match(current, "^(%-?%d+):(%-?%d+):(%-?%d+)$")
		if cx and cy and cz then
			local x, y, z = tonumber(cx) :: number, tonumber(cy) :: number, tonumber(cz) :: number
			for _, n in neighbors(x, y, z) do
				local nx, ny, nz = n[1], n[2], n[3]
				if
					nx >= occ.Bounds.MinX
					and nx <= occ.Bounds.MaxX
					and ny >= occ.Bounds.MinY
					and ny <= occ.Bounds.MaxY
					and nz >= occ.Bounds.MinZ
					and nz <= occ.Bounds.MaxZ
				then
					local nk = key(nx, ny, nz)
					if occ.Solid[nk] and not supportedCells[nk] then
						-- Must connect via down or lateral from already-supported (BFS from ground).
						supportedCells[nk] = true
						table.insert(queue, nk)
					end
				end
			end
		end
	end

	local failed: { string } = {}
	for id, record in occ.Structures do
		local k = key(record.Cx, record.Cy, record.Cz)
		if not supportedCells[k] then
			table.insert(failed, id)
		end
	end
	return failed
end

function VoxelSupportResolver.wouldBeSupported(occ: Occupancy, cx: number, cy: number, cz: number): boolean
	local solid = table.clone(occ.Solid)
	solid[key(cx, cy, cz)] = true
	local probe: StructureRecord = {
		Id = "__probe",
		TemplateId = "SandboxBlock",
		Cx = cx,
		Cy = cy,
		Cz = cz,
		OwnerUserId = 0,
		PlacedAt = 0,
	}
	local structures = table.clone(occ.Structures)
	structures[probe.Id] = probe
	local failed = VoxelSupportResolver.unsupportedIds({
		Solid = solid,
		Structures = structures,
		Bounds = occ.Bounds,
	})
	for _, id in failed do
		if id == probe.Id then
			return false
		end
	end
	return true
end

return VoxelSupportResolver
