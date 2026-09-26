--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtraPoolCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.ExtraPoolCatalog)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local VitalsLogic = require(script.Parent.Parent.VitalsLogic)

type JsonObject = JsonTypes.JsonObject
type JsonValue = JsonTypes.JsonValue

export type ExtraPoolBar = UiTypes.ExtraPoolBar

local POOL_COLORS: { [string]: Color3 } = {
	Focus = Color3.fromRGB(168, 120, 220),
	Momentum = Color3.fromRGB(220, 132, 48),
	Guard = Color3.fromRGB(72, 132, 196),
	Charge = Color3.fromRGB(220, 196, 64),
	Overdrive = Color3.fromRGB(196, 56, 48),
	AstralPower = Color3.fromRGB(120, 188, 220),
	StaminaResource = Color3.fromRGB(88, 168, 88),
}

local ExtraPools = {}

local function maxRemoteKey(remoteKey: string): string
	return "max" .. string.upper(string.sub(remoteKey, 1, 1)) .. string.sub(remoteKey, 2)
end

function ExtraPools.poolColor(statId: string): Color3?
	return POOL_COLORS[statId]
end

function ExtraPools.parseBars(data: JsonObject): { ExtraPoolBar }
	local bars: { ExtraPoolBar } = {}
	for _, entry in ExtraPoolCatalog.all() do
		local maxVal = Json.numberOr(data[maxRemoteKey(entry.RemoteKey)], 0)
		if maxVal <= 0 then
			continue
		end
		local current = Json.numberOr(data[entry.RemoteKey], 0)
		table.insert(bars, {
			statId = entry.StatId,
			label = entry.ShortLabel,
			current = current,
			max = maxVal,
		})
	end
	return bars
end

function ExtraPools.parsePartyRows(raw: JsonValue?): { ExtraPoolBar }
	local bars: { ExtraPoolBar } = {}
	local rows = Json.asArray(raw)
	if rows == nil then
		return bars
	end
	for _, rowValue in rows do
		local row = Json.asObject(rowValue)
		if row == nil then
			continue
		end
		local statId = Json.stringOr(row.statId, "")
		local entry = ExtraPoolCatalog.get(statId)
		if entry == nil then
			continue
		end
		local maxVal = Json.numberOr(row.max, 0)
		if maxVal <= 0 then
			continue
		end
		table.insert(bars, {
			statId = statId,
			label = entry.ShortLabel,
			current = Json.numberOr(row.current, 0),
			max = maxVal,
		})
	end
	return bars
end

function ExtraPools.tip(bar: ExtraPoolBar): string
	local name = ExtraPoolCatalog.costLabel(bar.statId)
	return `{name}  {string.format("%.0f", bar.current)} / {string.format("%.0f", bar.max)}`
end

function ExtraPools.sheetValue(statId: string, pools: { ExtraPoolBar }, fallback: string): string
	for _, bar in pools do
		if bar.statId == statId then
			return `{string.format("%.0f", bar.current)} / {string.format("%.0f", bar.max)}`
		end
	end
	return fallback
end

function ExtraPools.sig(bars: { ExtraPoolBar }): string
	local bits: { string } = {}
	for _, bar in bars do
		table.insert(bits, `{bar.statId}:{string.format("%.2f", bar.current)}:{string.format("%.2f", bar.max)}`)
	end
	return table.concat(bits, "|")
end

function ExtraPools.paintMeters(meters: { Frame }, bars: { ExtraPoolBar }, visible: boolean)
	for _, meter in meters do
		meter.Visible = false
	end
	if not visible then
		return
	end
	for i, bar in bars do
		if i > #meters then
			break
		end
		local meter = meters[i]
		meter.Visible = true
		local tint = ExtraPools.poolColor(bar.statId)
		if tint ~= nil then
			local track = meter:FindFirstChild("Track")
			if track and track:IsA("Frame") then
				local fill = track:FindFirstChild("Fill")
				if fill and fill:IsA("Frame") then
					fill.BackgroundColor3 = tint
				end
			end
		end
		Paint.setFill(meter, VitalsLogic.fillRatio(bar.current, bar.max))
		Paint.setMeterText(meter, bar.label)
	end
end

return ExtraPools
