--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClockService = require(script.Parent.Parent.Parent.Platform.Scheduling.ClockService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local CooldownService = require(script.Parent.Parent.Combat.CooldownService)
local CraftResolver = require(script.Parent.CraftResolver)
local CraftingCatalog = require(ReplicatedStorage.Definitions.Items.CraftingCatalog)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local EconomyService = require(script.Parent.EconomyService)
local InventoryService = require(script.Parent.Parent.Items.InventoryService)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local ItemResolver = require(script.Parent.Parent.Items.ItemResolver)
local ProfessionCatalog = require(ReplicatedStorage.Definitions.Items.ProfessionCatalog)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local StatService = require(script.Parent.Parent.Stats.StatService)
local WornBags = require(ReplicatedStorage.Shared.Utility.WornBags)

local CraftingService = { Name = "CraftingService" }
local _inv: typeof(InventoryService)
local _econ: typeof(EconomyService)
local _data: typeof(DataService)
local _stats: typeof(StatService)
local _cooldowns: typeof(CooldownService)
local _clock: typeof(ClockService)

function CraftingService:Init(container: ContainerTypes.Container)
	_inv = container:Get(InventoryService.Name) :: typeof(InventoryService)
	_econ = container:Get(EconomyService.Name) :: typeof(EconomyService)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
	_cooldowns = container:Get(CooldownService.Name) :: typeof(CooldownService)
	_clock = container:Get(ClockService.Name) :: typeof(ClockService)
end

function CraftingService:Start() end

local function applyProfessionModifiers(player: Player, skills: { [string]: number })
	_stats:ClearSource(player, "Profession")
	for _, modifier in ProfessionCatalog.modifiersFor(skills) do
		_stats:AddModifier(player, modifier)
	end
end

function CraftingService:Craft(player: Player, templateId: string): Result.Result<boolean>
	local recipe = CraftingCatalog.get(templateId)
	if recipe == nil then
		return Result.err("unknown recipe")
	end
	local profile = _data:Get(player)
	if profile and profile.Progression.ProfessionCraft < recipe.RequiredSkill then
		return Result.err("profession skill")
	end
	local professionId = recipe.ProfessionId
	if profile ~= nil and professionId ~= nil then
		local def = ProfessionCatalog.get(professionId)
		if def ~= nil then
			local skill = ProfessionCatalog.skillOf(profile.Progression.ProfessionSkills, professionId)
			if not ProfessionCatalog.meetsGate(def, skill) then
				return Result.err("profession gate")
			end
		end
	end
	local values = _stats:GetValues(player)
	local power = values.CraftingPower or 0
	if power <= 0 then
		power = 1
	end
	if recipe.MinCraftingPower > 0 and power < recipe.MinCraftingPower then
		return Result.err("crafting power")
	end
	if _inv:IsFull(player) then
		return Result.err("inventory full")
	end
	local speed = values.CraftingSpeed or 1
	local quality = values.CraftingQuality or 1
	local materialInstance = ""
	if recipe.MaterialId ~= "" then
		if profile then
			for _, item in WornBags.flat(profile) do
				if item.TemplateId == recipe.MaterialId and not _inv:IsEquipped(player, item.InstanceId) then
					materialInstance = item.InstanceId
					break
				end
			end
		end
		if materialInstance == "" then
			return Result.err("missing material")
		end
	end
	local outcome = CraftResolver.resolve({
		CraftingPower = power,
		CraftingSpeed = speed,
		CraftingQuality = quality,
		CraftingPrecision = values.CraftingPrecision,
		CraftingStability = values.CraftingStability,
		RecipeKnowledge = values.RecipeKnowledge,
		ToolWearReduction = values.ToolWearReduction,
		CraftingYield = values.CraftingYield,
		SmeltingEfficiency = values.SmeltingEfficiency,
		MaterialEfficiency = values.MaterialEfficiency,
		CriticalCraftChance = values.CriticalCraftChance,
		CraftFailureResistance = values.CraftFailureResistance,
		EnchantingPower = values.EnchantingPower,
		SalvageBonus = values.SalvageBonus,
		AstralCost = recipe.AstralCost,
		HasMaterial = materialInstance ~= "",
	})
	if not _cooldowns:Arm(player, `craft:{templateId}`, _clock.now(), outcome.CooldownSeconds) then
		return Result.err("cooldown")
	end
	local spent = _econ:TrySpend(player, "Astral", outcome.AstralCost)
	if spent.Ok == false then
		return Result.errOf(spent)
	end
	if materialInstance ~= "" then
		if not _inv:Remove(player, materialInstance) then
			_econ:Grant(player, "Astral", outcome.AstralCost)
			return Result.err("remove failed")
		end
		if outcome.RefundMaterial then
			_inv:Grant(player, recipe.MaterialId, false)
		end
	end
	if outcome.Failed then
		return Result.err("craft failed")
	end
	local grantQuality: string? = nil
	if outcome.QualityBumpChance > 0 and math.random() < outcome.QualityBumpChance then
		local output = ItemCatalog.get(recipe.OutputId)
		if output ~= nil then
			local bumped = ItemResolver.nextQuality(output.Quality)
			if bumped ~= output.Quality then
				grantQuality = bumped
			end
		end
	end
	local granted = _inv:Grant(player, recipe.OutputId, true, grantQuality)
	if granted.Ok == false then
		_econ:Grant(player, "Astral", outcome.AstralCost)
		if recipe.MaterialId ~= "" and not outcome.RefundMaterial then
			_inv:Grant(player, recipe.MaterialId, false)
		end
		return Result.errOf(granted)
	end
	_data:Mutate(player, function(nextProfile)
		nextProfile.Progression.ProfessionCraft += 1
		if professionId ~= nil then
			local def = ProfessionCatalog.get(professionId)
			if def ~= nil then
				local current = ProfessionCatalog.skillOf(nextProfile.Progression.ProfessionSkills, professionId)
				ProfessionCatalog.writeSkill(
					nextProfile.Progression.ProfessionSkills,
					professionId,
					ProfessionCatalog.advance(def, current)
				)
			end
		end
	end)
	local updated = _data:Get(player)
	if updated ~= nil then
		applyProfessionModifiers(player, updated.Progression.ProfessionSkills)
	end
	return Result.ok(true)
end

return CraftingService
