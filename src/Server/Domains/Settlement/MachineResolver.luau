--!strict

-- Pure resolver. No remotes, no persistence.
-- Optional machine finals: omitted / ≤0 treated as identity via StatFinal.

local StatFinal = require(script.Parent.Parent.Stats.StatFinal)

export type MachineInput = {
	Efficiency: number,
	Throughput: number,
	Heat: number,
	BaseProcessSeconds: number,
	TransportEfficiency: number?,
	MachineHeatResistance: number?,
	FailureResistance: number?,
	FuelEfficiency: number?,
	PowerEfficiency: number?,
	MaintenanceEfficiency: number?,
	MachinePrecision: number?,
	StorageEfficiency: number?,
	SignalRange: number?,
	SensorRange: number?,
	AutomationAffinity: number?,
}

export type MachineOutcome = {
	ProcessSeconds: number,
	OutputCount: number,
	HeatGain: number,
	Overheated: boolean,
}

export type PowerInput = {
	ZoneDraw: number,
	MachineDraw: number,
	Cap: number,
}

export type LinkFeedInput = {
	OutputItemId: string,
	OutputCount: number,
	DownstreamInputId: string,
	PipelineBonus: number?,
}

local MachineResolver = {}

function MachineResolver.resolve(input: MachineInput): MachineOutcome
	local efficiency = math.max(input.Efficiency, 0.25)
	local throughput = math.max(input.Throughput, 0.25)
	local heat = math.max(input.Heat, 0)
	local haul = StatFinal.mult(input.TransportEfficiency)
	local fuel = StatFinal.mult(input.FuelEfficiency)
	local power = StatFinal.mult(input.PowerEfficiency)
	local auto = StatFinal.mult(input.AutomationAffinity)
	local signal = StatFinal.mult(input.SignalRange)
	local sensor = StatFinal.mult(input.SensorRange)
	local seconds = math.max(0.5, input.BaseProcessSeconds / throughput / haul / fuel / power / auto / signal / sensor)
	local precision = StatFinal.mult(input.MachinePrecision)
	local storage = StatFinal.mult(input.StorageEfficiency)
	local outputCount = if efficiency * precision >= 1.5 then 2 else 1
	outputCount = math.max(1, math.floor(outputCount * storage + 1e-9))
	local heatResist = StatFinal.mult(input.MachineHeatResistance)
	local maintain = StatFinal.mult(input.MaintenanceEfficiency)
	local failResist = StatFinal.mult(input.FailureResistance)
	local heatGain = (0.08 + heat * 0.01) / heatResist / maintain / failResist
	local overheated = (heat + heatGain) >= 1
	if overheated then
		seconds *= 1.5
		outputCount = 1
	end
	return {
		ProcessSeconds = seconds,
		OutputCount = outputCount,
		HeatGain = heatGain,
		Overheated = overheated,
	}
end

function MachineResolver.canDrawPower(input: PowerInput): boolean
	local used = math.max(0, input.ZoneDraw)
	local draw = math.max(0, input.MachineDraw)
	return used + draw <= input.Cap
end

function MachineResolver.linkFeed(input: LinkFeedInput): number
	if input.OutputItemId ~= input.DownstreamInputId then
		return 0
	end
	local bonus = StatFinal.mult(input.PipelineBonus)
	return math.max(0, math.floor(input.OutputCount * bonus))
end

return MachineResolver
