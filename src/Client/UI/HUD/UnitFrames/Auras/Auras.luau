--!strict
-- Player and target aura chips.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EffectCatalog = require(ReplicatedStorage.Definitions.Effects.EffectCatalog)
local FrameFactory = require(script.Parent.Parent.FrameFactory)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local Types = require(script.Parent.Parent.Types.Types)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local VitalsLogic = require(script.Parent.Parent.Parent.VitalsLogic)

type AuraChip = FrameFactory.AuraChip
type AuraRow = UiTypes.AuraRow
type AuraMeta = Types.AuraMeta
type ChromeShared = Types.ChromeShared

export type AurasApi = {
	setAuras: (playerRows: { AuraRow }, targetRows: { AuraRow }, meta: AuraMeta) -> (),
	tickAuras: (dt: number) -> (),
}

local AURA_COLUMNS = 4
local AURA_LIMIT = 8

local Auras = {}

local function isBuff(kind: string): boolean
	if string.sub(kind, 1, #"Interrupt:") == "Interrupt:" then
		return false
	end
	return kind ~= "Debuff"
		and kind ~= "CC"
		and kind ~= "Stun"
		and kind ~= "Root"
		and kind ~= "Fear"
		and kind ~= "Disorient"
		and kind ~= "Silence"
		and kind ~= "Slow"
		and kind ~= "Knock"
		and kind ~= "Launch"
end

local function auraGlyph(id: string): string
	if id == "" then
		return "?"
	end
	return string.upper(string.sub(id, 1, 3))
end

local function auraCopy(rows: { AuraRow }): { AuraRow }
	local list: { AuraRow } = {}
	for _, row in rows do
		table.insert(
			list,
			{ id = row.id, remaining = row.remaining, kind = row.kind, stacks = row.stacks, charges = row.charges }
		)
	end
	return list
end

function Auras.auraSig(playerRows: { AuraRow }, targetRows: { AuraRow }, meta: AuraMeta): string
	local bits = {
		if meta.pvp then "1" else "0",
		string.format("%.0f", meta.restXp),
		meta.form,
		meta.targetKind,
		meta.targetName,
		string.format("%.0f", meta.targetAbsorb),
	}
	for _, row in playerRows do
		table.insert(bits, `p:{row.id}:{row.kind}:{row.stacks or 1}:{row.charges or 0}`)
	end
	for _, row in targetRows do
		table.insert(bits, `t:{row.id}:{row.kind}:{row.stacks or 1}:{row.charges or 0}`)
	end
	return table.concat(bits, "|")
end

function Auras.mount(root: Frame, shared: ChromeShared): AurasApi
	local tooltip = shared.tooltip
	local gate = shared.gate

	local auraRow = Instance.new("Frame")
	auraRow.Name = "PlayerAuras"
	auraRow.BackgroundTransparency = 1
	auraRow.BorderSizePixel = 0
	auraRow.Position = UDim2.fromScale(0.24, 0.03)
	auraRow.Size = UDim2.fromScale(0.14, 0.12)
	auraRow.Active = false
	auraRow.Parent = root

	local targetAuraRow = Instance.new("Frame")
	targetAuraRow.Name = "TargetAuras"
	targetAuraRow.BackgroundTransparency = 1
	targetAuraRow.BorderSizePixel = 0
	targetAuraRow.Position = UDim2.fromScale(0.39, 0.145)
	targetAuraRow.Size = UDim2.fromScale(0.22, 0.06)
	targetAuraRow.Active = false
	targetAuraRow.Parent = root

	local playerAuras: { AuraRow } = {}
	local targetAuras: { AuraRow } = {}
	local playerTimers: { TextLabel } = {}
	local targetTimers: { TextLabel } = {}
	local auraMeta: AuraMeta = {
		pvp = false,
		restXp = 0,
		form = "",
		targetKind = "",
		targetName = "",
		targetAbsorb = 0,
	}

	local function pseudoChip(index: number, glyph: string, detail: string): AuraChip
		local col = (index - 1) % AURA_COLUMNS
		local row = math.floor((index - 1) / AURA_COLUMNS)
		local chip =
			FrameFactory.auraChip(auraRow, UDim2.fromScale(col * 0.26, row * 0.52), UDim2.fromScale(0.24, 0.48), true)
		chip.Glyph.Text = glyph
		chip.Timer.Text = ""
		chip.Stack.Text = ""
		chip.Root.Active = true
		chip.Root.MouseEnter:Connect(function()
			tooltip.show(detail)
		end)
		chip.Root.MouseLeave:Connect(function()
			tooltip.hide()
		end)
		return chip
	end

	local function paintAuras()
		Paint.clearFrame(auraRow)
		table.clear(playerTimers)
		local n = 0
		if auraMeta.pvp then
			n += 1
			pseudoChip(n, "PvP", "PvP flagged\nOpen season on the other faction.")
		end
		if auraMeta.restXp > 0 then
			n += 1
			pseudoChip(n, "Rest", `Rested\n+{string.format("%.0f", auraMeta.restXp)} bonus experience banked.`)
		end
		if auraMeta.form ~= "" then
			n += 1
			pseudoChip(n, string.sub(auraMeta.form, 1, 3), `Transformation\n{auraMeta.form}`)
		end
		for index, aura in playerAuras do
			if n >= AURA_LIMIT then
				break
			end
			n += 1
			local col = (n - 1) % AURA_COLUMNS
			local row = math.floor((n - 1) / AURA_COLUMNS)
			local chip = FrameFactory.auraChip(
				auraRow,
				UDim2.fromScale(col * 0.26, row * 0.52),
				UDim2.fromScale(0.24, 0.48),
				isBuff(aura.kind)
			)
			chip.Glyph.Text = auraGlyph(aura.id)
			chip.Timer.Text = Paint.formatDuration(aura.remaining)
			chip.Stack.Text = if aura.charges ~= nil
				then tostring(aura.charges)
				elseif (aura.stacks or 1) > 1 then tostring(aura.stacks)
				else ""
			chip.Root.Active = true
			local auraIndex = index
			chip.Root.MouseEnter:Connect(function()
				local live = playerAuras[auraIndex]
				if live == nil then
					return
				end
				local def = EffectCatalog.get(live.id)
				local title = if def then def.Id else live.id
				tooltip.show(`{title}\n{live.kind}  {Paint.formatDuration(live.remaining)}s`)
			end)
			chip.Root.MouseLeave:Connect(function()
				tooltip.hide()
			end)
			playerTimers[auraIndex] = chip.Timer
		end

		Paint.clearFrame(targetAuraRow)
		table.clear(targetTimers)
		local hasTarget = auraMeta.targetName ~= "" and auraMeta.targetName ~= "No target"
		if not hasTarget then
			return
		end
		local slot = 0
		local kindChip = FrameFactory.auraChip(targetAuraRow, UDim2.fromScale(0, 0), UDim2.fromScale(0.22, 0.9), false)
		kindChip.Glyph.Text = if auraMeta.targetKind ~= ""
			then string.upper(string.sub(auraMeta.targetKind, 1, 4))
			else "MOB"
		kindChip.Timer.Text = ""
		kindChip.Stack.Text = ""
		kindChip.Root.Active = true
		local kindName = if auraMeta.targetKind ~= "" then auraMeta.targetKind else "Unit"
		local targetLabel = auraMeta.targetName
		kindChip.Root.MouseEnter:Connect(function()
			tooltip.show(`{targetLabel}\n{kindName}`, Paint.classificationColor(kindName))
		end)
		kindChip.Root.MouseLeave:Connect(function()
			tooltip.hide()
		end)
		slot += 1
		if auraMeta.targetAbsorb > 0 then
			local absorbChip =
				FrameFactory.auraChip(targetAuraRow, UDim2.fromScale(slot * 0.24, 0), UDim2.fromScale(0.22, 0.9), true)
			absorbChip.Glyph.Text = "ABS"
			absorbChip.Timer.Text = string.format("%.0f", auraMeta.targetAbsorb)
			absorbChip.Stack.Text = ""
			slot += 1
		end
		for index, aura in targetAuras do
			if slot >= AURA_COLUMNS then
				break
			end
			local chip = FrameFactory.auraChip(
				targetAuraRow,
				UDim2.fromScale(slot * 0.24, 0),
				UDim2.fromScale(0.22, 0.9),
				isBuff(aura.kind)
			)
			chip.Glyph.Text = auraGlyph(aura.id)
			chip.Timer.Text = Paint.formatDuration(aura.remaining)
			chip.Stack.Text = if aura.charges ~= nil
				then tostring(aura.charges)
				elseif (aura.stacks or 1) > 1 then tostring(aura.stacks)
				else ""
			chip.Root.Active = true
			local auraIndex = index
			chip.Root.MouseEnter:Connect(function()
				local live = targetAuras[auraIndex]
				if live == nil then
					return
				end
				tooltip.show(`{live.id}\n{live.kind}  {Paint.formatDuration(live.remaining)}s`)
			end)
			chip.Root.MouseLeave:Connect(function()
				tooltip.hide()
			end)
			targetTimers[auraIndex] = chip.Timer
			slot += 1
		end
	end

	local function paintAuraTimers()
		for index, aura in playerAuras do
			local label = playerTimers[index]
			if label then
				label.Text = Paint.formatDuration(aura.remaining)
			end
		end
		for index, aura in targetAuras do
			local label = targetTimers[index]
			if label then
				label.Text = Paint.formatDuration(aura.remaining)
			end
		end
	end

	local function setAuras(playerRows: { AuraRow }, targetRows: { AuraRow }, meta: AuraMeta)
		playerAuras = auraCopy(playerRows)
		targetAuras = auraCopy(targetRows)
		auraMeta = meta
		gate.gate("auras", Auras.auraSig(playerRows, targetRows, meta), function()
			paintAuras()
		end)
		paintAuraTimers()
	end

	local function tickAuras(dt: number)
		if #playerAuras == 0 and #targetAuras == 0 then
			return
		end
		local keptPlayer = VitalsLogic.tickAuras(playerAuras, dt)
		local keptTarget = VitalsLogic.tickAuras(targetAuras, dt)
		local expired = #keptPlayer ~= #playerAuras or #keptTarget ~= #targetAuras
		playerAuras = keptPlayer
		targetAuras = keptTarget
		if expired then
			paintAuras()
			gate.clear("auras")
			return
		end
		paintAuraTimers()
	end

	return {
		setAuras = setAuras,
		tickAuras = tickAuras,
	}
end

return Auras
