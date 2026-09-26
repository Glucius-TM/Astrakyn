--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local BootstrapContext = require(script.Parent.BootstrapContext)
local VitalsSnapshot = require(ServerScriptService.Domains.Combat.VitalsSnapshot)

type Context = BootstrapContext.Context

local PersistenceHooks = {}

function PersistenceHooks.registerPersistenceHooks(ctx: Context)
	local DataService = ctx.app.DataService
	local VitalsService = ctx.app.VitalsService

	DataService:OnBeforeSave(function(player, profile)
		VitalsSnapshot.apply(
			profile.Vitals,
			VitalsSnapshot.fromService(
				VitalsService:Get(player, "Health"),
				VitalsService:Get(player, "Energy"),
				VitalsService:Get(player, "Focus"),
				VitalsService:Get(player, "Momentum"),
				VitalsService:Get(player, "Guard"),
				VitalsService:Get(player, "Charge"),
				VitalsService:Get(player, "Overdrive"),
				VitalsService:Get(player, "AstralPower"),
				VitalsService:Get(player, "StaminaResource")
			),
			VitalsService:Has(player)
		)
		local started = ctx.sessionClock[player.UserId]
		if started then
			profile.Progression.PlayedSeconds += math.max(0, math.floor(os.clock() - started))
			ctx.sessionClock[player.UserId] = os.clock()
		end
	end)
end

return PersistenceHooks
