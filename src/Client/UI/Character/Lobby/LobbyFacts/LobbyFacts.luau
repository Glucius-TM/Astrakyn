--!strict
-- Lobby detail fact rows + paint (presentation only).

local IdentityPaint = require(script:FindFirstAncestor("Client").Domains.Session.IdentityPaint)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local RosterParse = require(script.Parent.Parent.RosterParse.RosterParse)
local StatWidgets = require(script:FindFirstAncestor("Client").UI.HUD.StatSheet.StatWidgets)

type RosterSlot = RosterParse.RosterSlot

export type FactRow = {
	kind: string,
	label: string,
	value: string,
}

local LobbyFacts = {}

function LobbyFacts.rows(slot: RosterSlot): { FactRow }
	local specName = IdentityPaint.specName(slot.specializationId)
	local className = IdentityPaint.presentationName(slot.archetypeId, "Archetype")
	local raceName = IdentityPaint.presentationName(slot.raceId, "Race")
	local originName = IdentityPaint.presentationName(slot.originId, "Origin")
	local guildLine = if slot.guildName ~= "" then `{slot.guildName}  ·  {slot.guildRank}` else "Sin hermandad"
	local lastZone = RosterParse.zoneNameOf(slot.lastZoneId)
	local hearthZone = RosterParse.zoneNameOf(slot.bindZoneId)
	local restNeed = math.max(1, slot.xpNeed)
	local restPct = math.clamp(slot.restXp / restNeed, 0, 1)
	return {
		{ kind = "h", label = "Identidad", value = "" },
		{ kind = "r", label = "Nombre", value = slot.name },
		{ kind = "r", label = "Nivel", value = `{math.floor(slot.level)}` },
		{ kind = "r", label = "Raza", value = raceName },
		{ kind = "r", label = "Patria", value = originName },
		{ kind = "r", label = "Clase", value = className },
		{ kind = "r", label = "Especialización", value = specName },
		{ kind = "r", label = "Hermandad", value = guildLine },
		{ kind = "h", label = "Mundo", value = "" },
		{ kind = "r", label = "Última zona", value = lastZone },
		{ kind = "r", label = "Piedra de hogar", value = hearthZone },
		{ kind = "r", label = "Tiempo jugado", value = RosterParse.playedLine(slot.playedSeconds) },
		{ kind = "h", label = "Progreso", value = "" },
		{ kind = "r", label = "Experiencia", value = `{math.floor(slot.xpAmount)} / {math.floor(slot.xpNeed)}` },
		{ kind = "r", label = "XP de descanso", value = `{math.floor(slot.restXp)}  ({math.floor(restPct * 100)}%)` },
		{ kind = "r", label = "Misiones", value = `{math.floor(slot.questCount)}` },
		{
			kind = "r",
			label = "Talentos",
			value = `{math.floor(slot.talentCount)}  ({math.floor(slot.talentPoints)} pts)`,
		},
		{ kind = "r", label = "Maestrías", value = `{math.floor(slot.masteryPoints)} pts` },
		{ kind = "r", label = "Logros", value = `{math.floor(slot.achievementCount)}` },
		{ kind = "r", label = "Puntuación", value = `{math.floor(slot.endgameScore)}` },
		{ kind = "h", label = "Equipo y economía", value = "" },
		{ kind = "r", label = "Nivel de objeto", value = `{math.floor(slot.gearItemLevel)}` },
		{ kind = "r", label = "Poder de combate", value = `{math.floor(slot.gearCombatPower)}` },
		{ kind = "r", label = "Astral", value = Paint.money(slot.astral) },
		{ kind = "r", label = "Honor", value = `{math.floor(slot.honor)}` },
		{ kind = "r", label = "Conquista", value = `{math.floor(slot.conquest)}` },
		{ kind = "h", label = "Oficios", value = "" },
		{ kind = "r", label = "Minería", value = `{math.floor(slot.mining)}` },
		{ kind = "r", label = "Herrería", value = `{math.floor(slot.smithing)}` },
		{ kind = "r", label = "Cocina", value = `{math.floor(slot.cooking)}` },
		{ kind = "r", label = "Alquimia", value = `{math.floor(slot.alchemy)}` },
		{ kind = "r", label = "Latticecraft", value = `{math.floor(slot.latticecraft)}` },
		{ kind = "h", label = "Combate", value = "" },
		{ kind = "r", label = "PvP", value = `{math.floor(slot.pvpWins)}-{math.floor(slot.pvpLosses)}` },
		{ kind = "r", label = "MMR", value = `{math.floor(slot.mmr)}` },
		{ kind = "r", label = "Muertes", value = `{math.floor(slot.deaths)}` },
	}
end

function LobbyFacts.paint(detailScroll: ScrollingFrame, slot: RosterSlot?)
	Paint.clearFrame(detailScroll)
	if slot == nil then
		local empty = Paint.text(
			detailScroll,
			"Ningún personaje seleccionado.\n\nUn hueco vacío de la lista crea un Kyn.\nDoble clic o Entrar accede al mundo.",
			UDim2.fromOffset(6, 8),
			UDim2.new(1, -12, 0, 120),
			Enum.TextXAlignment.Left
		)
		empty.TextWrapped = true
		empty.TextYAlignment = Enum.TextYAlignment.Top
		empty.TextColor3 = Paint.TextColorSecondary
		empty.TextSize = Paint.TextSizeCaption
		detailScroll.CanvasSize = UDim2.fromOffset(0, 140)
		return
	end
	local y = 4
	for _, fact in LobbyFacts.rows(slot) do
		if fact.kind == "h" then
			if y > 8 then
				Paint.divider(detailScroll, UDim2.fromOffset(4, y - 2), UDim2.new(1, -8, 0, 1))
				y += 6
			end
			StatWidgets.sectionHeader(detailScroll, fact.label, UDim2.fromOffset(4, y), UDim2.new(1, -8, 0, 22))
			y += 26
		else
			local label = Paint.text(
				detailScroll,
				fact.label,
				UDim2.fromOffset(4, y),
				UDim2.new(0.44, -6, 0, 22),
				Enum.TextXAlignment.Left
			)
			label.TextSize = Paint.TextSizeCaption
			label.TextColor3 = Paint.TextColorSecondary
			local value = Paint.text(
				detailScroll,
				fact.value,
				UDim2.new(0.44, 0, 0, y),
				UDim2.new(0.56, -8, 0, 22),
				Enum.TextXAlignment.Right
			)
			value.TextSize = Paint.TextSizeCaption
			value.TextColor3 = Paint.TextColorBody
			value.TextTruncate = Enum.TextTruncate.AtEnd
			y += 24
		end
	end
	Paint.divider(detailScroll, UDim2.fromOffset(4, y + 2), UDim2.new(1, -8, 0, 1))
	local blurb = Paint.text(
		detailScroll,
		IdentityPaint.identityBlurb(slot.archetypeId),
		UDim2.fromOffset(4, y + 10),
		UDim2.new(1, -8, 0, 72),
		Enum.TextXAlignment.Left
	)
	blurb.TextWrapped = true
	blurb.TextYAlignment = Enum.TextYAlignment.Top
	blurb.TextSize = Paint.TextSizeCaption
	blurb.TextColor3 = Paint.TextColorBody
	detailScroll.CanvasSize = UDim2.fromOffset(0, y + 96)
end

return LobbyFacts
