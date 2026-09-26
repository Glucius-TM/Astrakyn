--!strict
-- Combat target pick (click / tab). Presentation intent only.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ClientRemotes = require(script.Parent.Parent.Parent.Parent.Runtime.Remotes.ClientRemotes)
local Id = require(ReplicatedStorage.Shared.Utility.Id)

export type TargetingDeps = {
	player: Player,
	tabRange: number,
	setHudTarget: (targetId: string, hp: number?, maxHp: number?) -> (),
	overGui: () -> boolean,
}

export type TargetingApi = {
	get: () -> string,
	set: (targetId: string) -> (),
	rootPart: () -> BasePart?,
	unitsFolder: () -> Folder?,
	click: () -> string?,
	tab: () -> (),
	findNamedPart: (root: Instance, name: string) -> BasePart?,
}

local Targeting = {}

function Targeting.create(deps: TargetingDeps): TargetingApi
	local currentTarget = ""

	local function findNamedPart(root: Instance, name: string): BasePart?
		local inst = root:FindFirstChild(name, true)
		if inst and inst:IsA("BasePart") then
			return inst
		end
		return nil
	end

	local function rootPart(): BasePart?
		local character = deps.player.Character
		if character == nil then
			return nil
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			return root
		end
		return nil
	end

	local function unitsFolder(): Folder?
		local world = Workspace:FindFirstChild("World")
		if world == nil then
			return nil
		end
		local continent = world:FindFirstChild("Kynfall")
		if continent == nil then
			return nil
		end
		local units = continent:FindFirstChild("Units")
		if units and units:IsA("Folder") then
			return units
		end
		return nil
	end

	local function unitModelFrom(instance: Instance): Model?
		local current: Instance? = instance
		local folder = unitsFolder()
		while current do
			if current:IsA("Model") and current.Parent == folder then
				return current
			end
			current = current.Parent
		end
		return nil
	end

	local function setTarget(targetId: string)
		if targetId == "" then
			return
		end
		currentTarget = targetId
		ClientRemotes.get("Combat", "TargetUnit"):FireServer({ targetId = targetId })
		deps.setHudTarget(targetId, nil, nil)
	end

	local function clickTarget(): string?
		if deps.overGui() then
			return nil
		end
		local mouse = deps.player:GetMouse()
		local hit = mouse.Target
		if not hit then
			return nil
		end
		local model = unitModelFrom(hit)
		if model then
			setTarget(model.Name)
			return model.Name
		end
		local inst: Instance? = hit
		while inst do
			if inst:IsA("Model") then
				local humanoid = inst:FindFirstChildOfClass("Humanoid")
				if humanoid then
					for _, other in Players:GetPlayers() do
						if other ~= deps.player and other.Character == inst then
							local id = Id.player(other.UserId)
							setTarget(id)
							return id
						end
					end
				end
			end
			inst = inst.Parent
		end
		return nil
	end

	local function tabTarget()
		local root = rootPart()
		if root == nil then
			return
		end
		local folder = unitsFolder()
		local best: Model? = nil
		local bestDist = deps.tabRange
		if folder then
			for _, child in folder:GetChildren() do
				if not child:IsA("Model") then
					continue
				end
				if child:GetAttribute("Alive") == false then
					continue
				end
				local kind = child:GetAttribute("FigureKind")
				if kind == "Npc" then
					continue
				end
				local primary = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
				if primary == nil or not primary:IsA("BasePart") then
					continue
				end
				local dist = (primary.Position - root.Position).Magnitude
				if dist < bestDist then
					bestDist = dist
					best = child
				end
			end
		end
		if best then
			setTarget(best.Name)
			return
		end
		local bestPlayer: Player? = nil
		local bestPlayerDist = deps.tabRange
		for _, other in Players:GetPlayers() do
			if other == deps.player then
				continue
			end
			local character = other.Character
			if character == nil then
				continue
			end
			local primary = character:FindFirstChild("HumanoidRootPart")
			if primary == nil or not primary:IsA("BasePart") then
				continue
			end
			local dist = (primary.Position - root.Position).Magnitude
			if dist < bestPlayerDist then
				bestPlayerDist = dist
				bestPlayer = other
			end
		end
		if bestPlayer then
			setTarget(Id.player(bestPlayer.UserId))
		end
	end

	return {
		get = function()
			return currentTarget
		end,
		set = setTarget,
		rootPart = rootPart,
		unitsFolder = unitsFolder,
		click = clickTarget,
		tab = tabTarget,
		findNamedPart = findNamedPart,
	}
end

return Targeting
