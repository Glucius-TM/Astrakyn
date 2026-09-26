--!strict

-- Copies live VitalsService pools onto PlayerProfile.Vitals.
-- Bootstrap owns leave order: AddRest → DataService:Release (this apply) → VitalsService:Clear.
-- DataService's deferred leave fallback is idempotent; apply also no-ops without a pool.

export type LiveVitals = {
	Health: number,
	Energy: number,
	Focus: number,
	Momentum: number,
	Guard: number,
	Charge: number,
	Overdrive: number,
	AstralPower: number,
	StaminaResource: number,
}

local VitalsSnapshot = {}

function VitalsSnapshot.leaveFlushSteps(): { string }
	return { "AddRest", "Release", "Clear" }
end

function VitalsSnapshot.apply(profileVitals: LiveVitals, live: LiveVitals, hasPool: boolean)
	if not hasPool then
		return
	end
	profileVitals.Health = live.Health
	profileVitals.Energy = live.Energy
	profileVitals.Focus = live.Focus
	profileVitals.Momentum = live.Momentum
	profileVitals.Guard = live.Guard
	profileVitals.Charge = live.Charge
	profileVitals.Overdrive = live.Overdrive
	profileVitals.AstralPower = live.AstralPower
	profileVitals.StaminaResource = live.StaminaResource
end

function VitalsSnapshot.fromService(
	health: number,
	energy: number,
	focus: number,
	momentum: number,
	guard: number,
	charge: number,
	overdrive: number,
	astralPower: number,
	staminaResource: number
): LiveVitals
	return {
		Health = health,
		Energy = energy,
		Focus = focus,
		Momentum = momentum,
		Guard = guard,
		Charge = charge,
		Overdrive = overdrive,
		AstralPower = astralPower,
		StaminaResource = staminaResource,
	}
end

return VitalsSnapshot
