--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local ReactiveCombatState = require(ServerScriptService.Domains.Combat.ReactiveCombatState)

type Harness = HarnessApi.Harness

local ReactiveCombatSpec = {}

function ReactiveCombatSpec.run(Harness: Harness)
	local userId = 932001
	ReactiveCombatState:Clear(userId)
	Harness.assert(
		not ReactiveCombatState:ObserveDefense(userId, { "Hit" }, 10, 5),
		"normal hit does not open defense reaction"
	)
	Harness.assert(
		ReactiveCombatState:ObserveDefense(userId, { "Dodge" }, 10, GameConstants.REACTIVE_DEFENSE_WINDOW_SECONDS),
		"Dodge opens defense reaction"
	)
	Harness.assert(ReactiveCombatState:Has(userId, "Defense", 10.1), "reaction remains ready inside its window")
	Harness.assert(ReactiveCombatState:Consume(userId, "Defense", 10.2), "reaction is consumed once")
	Harness.assert(not ReactiveCombatState:Has(userId, "Defense", 10.3), "consumed reaction is no longer ready")

	ReactiveCombatState:ObserveDefense(userId, { "Block" }, 20, 2)
	Harness.assert(not ReactiveCombatState:Has(userId, "Defense", 22.01), "reaction expires deterministically")
	ReactiveCombatState:Clear(userId)

	local reckoning = AbilityCatalog.get("Reckoning")
	Harness.assert(reckoning ~= nil, "Reckoning exists")
	Harness.assert(
		reckoning ~= nil and table.find(reckoning.Requirements, "ReactiveDefense") ~= nil,
		"Reckoning consumes the defense reaction contract"
	)
end

return ReactiveCombatSpec
