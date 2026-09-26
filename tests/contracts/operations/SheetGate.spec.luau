--!strict

-- Character sheet remote payload and AgainstBoss smoke.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local RemoteCatalog = require(ReplicatedStorage.Shared.Protocols.RemoteCatalog)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)

type Harness = HarnessApi.Harness

local SheetGateSpec = {}

function SheetGateSpec.run(Harness: Harness)
	local sheetRemote = RemoteCatalog.get("RequestCharacterSheet")
	Harness.assert(sheetRemote ~= nil, "RequestCharacterSheet remote")
	if sheetRemote ~= nil then
		local hasDepth = false
		for _, key in sheetRemote.PayloadKeys do
			if key == "sheetDepth" then
				hasDepth = true
				break
			end
		end
		Harness.assert(not hasDepth, "sheetDepth payload key absent")
	end
	local against = StatCatalog.get("AgainstBoss")
	Harness.assert(against ~= nil and against.Layer == "L6" and against.Enabled ~= false, "AgainstBoss L6")
	local smash = AbilityCatalog.get("Smash")
	Harness.assert(smash ~= nil and smash.Scaling ~= nil, "Smash scaling axes")
	if smash ~= nil and smash.Scaling ~= nil then
		Harness.assert(smash.Scaling.WeaponDamage > 0, "WeaponDamage axis")
		Harness.assert(smash.Scaling.Mastery >= 0, "Mastery axis")
		Harness.assert(smash.Scaling.Versatility >= 0, "Versatility axis")
	end
end

return SheetGateSpec
