--!strict

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientRemotes = require(script.Parent.Parent.Parent.Parent.Runtime.Remotes.ClientRemotes)
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local Hud = require(script.Parent.Parent.Parent.Parent.Runtime.GameHud)
local IntentController = require(script.Parent.Parent.Parent.Parent.Input.IntentController)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local MachineCatalog = require(ReplicatedStorage.Definitions.World.MachineCatalog)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local PoiCatalog = require(ReplicatedStorage.Definitions.World.PoiCatalog)
local Targeting = require(script.Parent.Parent.Targeting.Targeting)
local WorldController = require(script.Parent.Parent.Parent.World.WorldController)
local WorldPoi = require(script.Parent.Parent.Poi.WorldPoi)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type JsonObject = JsonTypes.JsonObject

local INTERACT_RANGE = 22
local TAB_RANGE = 90

local player = Players.LocalPlayer

local pvpOn = false

local function overGui(): boolean
	local gui = player:FindFirstChild("PlayerGui")
	if gui == nil or not gui:IsA("PlayerGui") then
		return false
	end
	local pos = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
	local hits = gui:GetGuiObjectsAtPosition(pos.X, pos.Y)
	for _, obj in hits do
		if obj:IsA("GuiObject") and Paint.capturesInput(obj) then
			return true
		end
	end
	return false
end

local targeting = Targeting.create({
	player = player,
	tabRange = TAB_RANGE,
	setHudTarget = function(targetId: string, hp: number?, maxHp: number?)
		Hud.setTarget(targetId, hp, maxHp)
	end,
	overGui = overGui,
})

local function groundAt(): Vector3?
	local camera = Workspace.CurrentCamera
	local mouse = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	if player.Character then
		params.FilterDescendantsInstances = { player.Character }
	end
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 420, params)
	if hit then
		return hit.Position
	end
	return nil
end

local function useAbility(abilityId: string)
	if not Hud.created() then
		return
	end
	local def = AbilityCatalog.get(abilityId)
	local ground = if def and def.TargetType == "Ground" then groundAt() else nil
	IntentController.useAbility(abilityId, targeting.get(), ground)
end

local function useHotbar(kind: string, id: string)
	if kind == "Macro" then
		IntentController.startMacro(id)
	elseif kind == "Item" then
		for _, row in Hud.inventory() do
			if row.templateId == id then
				ClientRemotes.get("Inventory", "UseItem"):FireServer({ instanceId = row.instanceId })
				return
			end
		end
		Hud.notify("Item not in bags")
	else
		useAbility(id)
	end
end

local function hotbarKey(index: number)
	local bind = Hud.hotbarBinds[index]
	if bind then
		useHotbar(bind.kind, bind.id)
	end
end

local worldPoi = WorldPoi.create({
	interactRange = INTERACT_RANGE,
	zoneId = function()
		return WorldController.zoneId()
	end,
	rootPart = targeting.rootPart,
	findNamedPart = targeting.findNamedPart,
	setTarget = targeting.set,
	openPanel = function(kind: string)
		Hud.openPanel(kind)
	end,
	notify = function(message: string)
		Hud.notify(message)
	end,
	quests = function()
		return Hud.quests()
	end,
	fireQuestRemote = function(folder: string, name: string, payload: JsonObject)
		IntentController.fire(folder, name, payload)
	end,
})

Hud.bindSlots(useHotbar)

local function nearestOther(): Player?
	for _, other in Players:GetPlayers() do
		if other ~= player then
			return other
		end
	end
	return nil
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if not Hud.isVisible() then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		targeting.click()
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if overGui() then
			return
		end
		local picked = targeting.click()
		local targetId = picked or targeting.get()
		if targetId ~= "" then
			IntentController.startAutoAttack(targetId)
		end
		return
	end
	if input.KeyCode == Enum.KeyCode.Escape then
		if not Hud.closeTopWindow() then
			Hud.openGameMenu()
		end
	elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
		Hud.focusChat()
	elseif input.KeyCode == Enum.KeyCode.I then
		Hud.openPanel("Spellbook")
	elseif input.KeyCode == Enum.KeyCode.Tab then
		targeting.tab()
	elseif input.KeyCode == Enum.KeyCode.E then
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			worldPoi.fireQuest("turnin")
		else
			worldPoi.interact()
		end
	elseif input.KeyCode == Enum.KeyCode.C then
		Hud.toggleSheet()
	elseif input.KeyCode == Enum.KeyCode.B then
		Hud.openPanel("Bags")
	elseif input.KeyCode == Enum.KeyCode.N then
		Hud.openPanel("Talents")
	elseif input.KeyCode == Enum.KeyCode.H then
		Hud.openPanel("Social")
	elseif input.KeyCode == Enum.KeyCode.K then
		Hud.openPanel("Macros")
	elseif input.KeyCode == Enum.KeyCode.Z then
		Hud.openPanel("World")
	elseif input.KeyCode == Enum.KeyCode.LeftBracket then
		-- Sandbox place (plot cell under feet) for zones with VoxelFootprint.
		local zone = ZoneCatalog.get(WorldController.zoneId())
		local root = targeting.rootPart()
		local cx, cy, cz = 0, 0, 0
		if zone and root then
			local VoxelFootprint = require(ReplicatedStorage.Definitions.World.VoxelFootprint)
			local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
			local foot = VoxelFootprint.get(zone.Id)
			if foot then
				local sb = foot.Sandbox
				local localX = root.Position.X - zone.OriginX
				local localY = root.Position.Y - zone.OriginY
				local localZ = root.Position.Z - zone.OriginZ
				cx =
					math.clamp(math.floor((localX - sb.OriginLocalX) / GameConstants.VOXEL_CELL_SIZE), sb.MinX, sb.MaxX)
				cy =
					math.clamp(math.floor((localY - sb.OriginLocalY) / GameConstants.VOXEL_CELL_SIZE), sb.MinY, sb.MaxY)
				cz =
					math.clamp(math.floor((localZ - sb.OriginLocalZ) / GameConstants.VOXEL_CELL_SIZE), sb.MinZ, sb.MaxZ)
			end
		end
		ClientRemotes.get("World", "PlaceStructure"):FireServer({
			templateId = "SandboxBlock",
			cx = cx,
			cy = cy,
			cz = cz,
		})
	elseif input.KeyCode == Enum.KeyCode.RightBracket then
		local root = targeting.rootPart()
		if root then
			local bestId = ""
			local bestDist = INTERACT_RANGE
			local world = Workspace:FindFirstChild("World")
			local folder = if world then world:FindFirstChild("Kynfall", true) else nil
			local construction = if folder then folder:FindFirstChild("Construction", true) else nil
			if construction then
				for _, child in construction:GetChildren() do
					if child:IsA("BasePart") then
						local sid = child:GetAttribute("StructureId")
						if typeof(sid) == "string" and sid ~= "" then
							local dist = (child.Position - root.Position).Magnitude
							if dist < bestDist then
								bestDist = dist
								bestId = sid
							end
						end
					end
				end
			end
			if bestId ~= "" then
				ClientRemotes.get("World", "RemoveStructure"):FireServer({ structureId = bestId })
			end
		end
	elseif input.KeyCode == Enum.KeyCode.Semicolon then
		local zone = ZoneCatalog.get(WorldController.zoneId())
		if zone then
			for _, poi in PoiCatalog.forZone(zone.Id) do
				local machine = MachineCatalog.forPoi(poi.Id)
				if machine then
					ClientRemotes.get("World", "MachineDeposit"):FireServer({ machineId = machine.Id })
					break
				end
			end
		end
	elseif input.KeyCode == Enum.KeyCode.Equals then
		local zone = ZoneCatalog.get(WorldController.zoneId())
		if zone then
			for _, poi in PoiCatalog.forZone(zone.Id) do
				local machine = MachineCatalog.forPoi(poi.Id)
				if machine then
					ClientRemotes.get("World", "MachineCollect"):FireServer({ machineId = machine.Id })
					break
				end
			end
		end
	elseif input.KeyCode == Enum.KeyCode.M then
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			IntentController.stopMacro("PulsePriority")
		else
			IntentController.startMacro("PulsePriority")
		end
	elseif input.KeyCode == Enum.KeyCode.O then
		Hud.openPanel("Settings")
	elseif input.KeyCode == Enum.KeyCode.J then
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			ClientRemotes.get("PvP", "LeaveQueue"):FireServer({})
		else
			ClientRemotes.get("PvP", "QueueEcho"):FireServer({})
		end
	elseif input.KeyCode == Enum.KeyCode.Y then
		local leaderId = Hud.pendingParty()
		if leaderId > 0 then
			ClientRemotes.get("Social", "PartyAccept"):FireServer({ userId = leaderId })
		end
	elseif input.KeyCode == Enum.KeyCode.X then
		if Hud.pendingParty() > 0 then
			ClientRemotes.get("Social", "PartyDecline"):FireServer({})
		end
	elseif input.KeyCode == Enum.KeyCode.R then
		if Hud.isDead() then
			ClientRemotes.get("Character", "Respawn"):FireServer({})
		end
	elseif input.KeyCode == Enum.KeyCode.U then
		if not Hud.created() then
			return
		end
		for _, row in Hud.inventory() do
			if row.slot == "Consumable" then
				ClientRemotes.get("Inventory", "UseItem"):FireServer({ instanceId = row.instanceId })
				break
			end
		end
	elseif input.KeyCode == Enum.KeyCode.L then
		ClientRemotes.get("Social", "PartyLeave"):FireServer({})
	elseif input.KeyCode == Enum.KeyCode.T then
		local other = nearestOther()
		local bag = Hud.inventory()
		if other and bag[1] then
			ClientRemotes.get("Social", "TradeRequest"):FireServer({
				userId = other.UserId,
				instanceId = bag[1].instanceId,
				astral = 0,
			})
		elseif other then
			ClientRemotes.get("Social", "SendMail"):FireServer({
				userId = other.UserId,
				body = "Field note from the Threshold",
				astral = 5,
			})
		end
	elseif input.KeyCode == Enum.KeyCode.V then
		pvpOn = not pvpOn
		ClientRemotes.get("PvP", "FlagPvP"):FireServer({ enabled = pvpOn })
	elseif input.KeyCode == Enum.KeyCode.G then
		ClientRemotes.get("Social", "CreateGuild"):FireServer({ name = `{player.DisplayName} Kyn` })
	elseif input.KeyCode == Enum.KeyCode.P then
		local other = nearestOther()
		if other then
			ClientRemotes.get("Social", "PartyInvite"):FireServer({ userId = other.UserId })
		end
	elseif input.KeyCode == Enum.KeyCode.F then
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			ClientRemotes.get("Character", "SetGateBind"):FireServer({})
		else
			ClientRemotes.get("Character", "UseGateBind"):FireServer({})
		end
	elseif input.KeyCode == Enum.KeyCode.Q then
		IntentController.stopCast()
		IntentController.stopAutoAttack()
		IntentController.stopMacro("")
		Hud.startCast("", 0)
	elseif input.KeyCode == Enum.KeyCode.One then
		hotbarKey(1)
	elseif input.KeyCode == Enum.KeyCode.Two then
		hotbarKey(2)
	elseif input.KeyCode == Enum.KeyCode.Three then
		hotbarKey(3)
	elseif input.KeyCode == Enum.KeyCode.Four then
		hotbarKey(4)
	elseif input.KeyCode == Enum.KeyCode.Five then
		hotbarKey(5)
	elseif input.KeyCode == Enum.KeyCode.Six then
		hotbarKey(6)
	elseif input.KeyCode == Enum.KeyCode.Seven then
		hotbarKey(7)
	elseif input.KeyCode == Enum.KeyCode.Eight then
		hotbarKey(8)
	elseif input.KeyCode == Enum.KeyCode.Nine then
		hotbarKey(9)
	elseif input.KeyCode == Enum.KeyCode.Zero then
		hotbarKey(10)
	elseif input.KeyCode == Enum.KeyCode.Minus then
		hotbarKey(11)
	elseif input.KeyCode == Enum.KeyCode.Quote then
		hotbarKey(12)
	end
end)

task.spawn(function()
	while true do
		task.wait(0.15)
		Hud.setPrompt(worldPoi.promptText())
	end
end)

return {}
