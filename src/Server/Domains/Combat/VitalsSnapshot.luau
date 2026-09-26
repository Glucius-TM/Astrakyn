--!strict

export type LiveVitals = {
	Health: number,
	Mana: number,
	Rage: number,
	Focus: number,
	Energy: number,
	Happiness: number,
	Rune: number,
	RunicPower: number,
}

local VitalsSnapshot = {}

function VitalsSnapshot.leaveFlushSteps(): { string }
	return { "AddRest", "Release", "Clear" }
end

function VitalsSnapshot.apply(profileVitals: LiveVitals, live: LiveVitals, hasPool: boolean)
	if not hasPool then
		return
	end
	for key, value in live do
		profileVitals[key] = value
	end
end

function VitalsSnapshot.fromService(
	health: number,
	mana: number,
	rage: number,
	focus: number,
	energy: number,
	happiness: number,
	rune: number,
	runicPower: number
): LiveVitals
	return {
		Health = health,
		Mana = mana,
		Rage = rage,
		Focus = focus,
		Energy = energy,
		Happiness = happiness,
		Rune = rune,
		RunicPower = runicPower,
	}
end

return VitalsSnapshot
