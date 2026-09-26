--!strict
-- Small system HUD helpers.

local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)

local SystemHints = {}

function SystemHints.emptyHint(parent: Instance, message: string): TextLabel
	local lab =
		Paint.text(parent, message, UDim2.fromOffset(12, 12), UDim2.new(1, -24, 0, 48), Enum.TextXAlignment.Left)
	lab.Name = "EmptyHint"
	lab.TextWrapped = true
	lab.TextYAlignment = Enum.TextYAlignment.Top
	lab.TextColor3 = Paint.Muted
	lab.TextSize = Paint.TextSizeCaption
	return lab
end

function SystemHints.keybindHelp(): { string }
	return {
		"1–9  0  -  =    Action bar",
		"C  Character     B  Bags     I  Spellbook",
		"N  Talents       H  Social   K  Macros",
		"Z  Map           O  Interface    Esc  Menu",
		"E  Interact      Shift+E  Turn in",
		"Tab  Nearest     Enter  Chat",
		"J  Queue Echo   Shift+J  Leave",
		"F  Gate bind    Shift+F  Set rest",
		"V  PvP flag      Q  Stop cast",
		"Y / X  Accept / decline",
		"R  Release       T  Trade / mail",
		"/p /g /z /w      Chat channels",
	}
end

function SystemHints.combatLogLine(
	abilityId: string,
	amount: number,
	targetName: string,
	crit: boolean,
	kind: string
): string
	local stamp = Paint.clockStamp()
	if kind == "heal" then
		return `[{stamp}]  {abilityId} heals {targetName} for {string.format("%.0f", amount)}`
	elseif kind == "miss" then
		return `[{stamp}]  {abilityId} misses {targetName}`
	elseif kind == "absorb" then
		return `[{stamp}]  {abilityId} absorbs {string.format("%.0f", amount)} on {targetName}`
	elseif kind == "interrupt" then
		return `[{stamp}]  Interrupted {targetName}`
	end
	return `[{stamp}]  {abilityId} hits {targetName} for {string.format("%.0f", amount)}{if crit
		then "  (Critical)"
		else ""}`
end

return SystemHints
