--!strict
-- Masteries character-sheet tab.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local MasteryCatalog = require(ReplicatedStorage.Definitions.Characters.MasteryCatalog)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local Tabs = require(script.Parent.Parent.Parent.HUD.Tabs.Tabs)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowHost = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowHost)

type JsonObject = JsonTypes.JsonObject
type WindowCtx = UiTypes.WindowCtx

local Masteries = {}

function Masteries.sig(ctx: WindowCtx): string
	local bits = { string.format("%.0f", ctx.masteryPoints) }
	local keys = {}
	for id in ctx.masteryRanks do
		table.insert(keys, id)
	end
	table.sort(keys)
	for _, id in keys do
		table.insert(bits, `{id}:{string.format("%.0f", ctx.masteryRanks[id])}`)
	end
	return table.concat(bits, "|")
end

function Masteries.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	local gate = host.getGate()

	local function fire(folder: string, name: string, payload: JsonObject)
		host.fire(folder, name, payload)
	end

	local function tipOn(guiObject: GuiObject, text: string, titleColor: Color3?)
		host.tipOn(guiObject, text, titleColor)
	end

	local masteriesBody = Tabs.sharedFrame("Masteries")
	assert(masteriesBody, "Masteries tab frame missing")
	local masteryShell =
		Paint.parchment(masteriesBody, "Shell", UDim2.fromScale(0.01, 0.01), UDim2.fromScale(0.98, 0.98))
	local masteryTitle = Paint.text(
		masteryShell,
		"Masteries",
		UDim2.fromScale(0.03, 0.02),
		UDim2.fromScale(0.94, 0.06),
		Enum.TextXAlignment.Left
	)
	masteryTitle.Font = Paint.FontTitle
	masteryTitle.TextColor3 = Paint.Gold
	masteryTitle.TextSize = Paint.TextSizeTitle
	local masteryPts =
		Paint.text(masteryShell, "", UDim2.fromScale(0.03, 0.08), UDim2.fromScale(0.92, 0.05), Enum.TextXAlignment.Left)
	masteryPts.TextColor3 = Paint.Cast
	masteryPts.TextSize = Paint.TextSizeCaption
	local masteryList = Paint.scroll(masteryShell, "Ranks", UDim2.fromScale(0.03, 0.15), UDim2.fromScale(0.94, 0.82))

	local handle: WindowHost.PanelHandle = {
		ids = { "Masteries" },
		refresh = function(ctx: WindowCtx)
			if not host.isSheetTab("Masteries") then
				return
			end
			gate.gate("Masteries", Masteries.sig(ctx), function()
				masteryPts.Text = `{string.format("%.0f", ctx.masteryPoints)} mastery points`
				Paint.clearFrame(masteryList)
				local y = 6
				for _, mastery in MasteryCatalog.all() do
					local rank = ctx.masteryRanks[mastery.Id] or 0
					local card =
						Paint.parchment(masteryList, mastery.Id, UDim2.fromOffset(8, y), UDim2.new(1, -16, 0, 56))
					Paint.text(
						card,
						mastery.Id,
						UDim2.fromScale(0.04, 0.1),
						UDim2.fromScale(0.5, 0.4),
						Enum.TextXAlignment.Left
					).TextColor3 =
						Paint.Gold
					local bar =
						Paint.labeledMeter(card, UDim2.fromScale(0.04, 0.55), UDim2.fromScale(0.7, 0.3), Paint.Cast)
					Paint.setFill(bar, rank / mastery.MaxRank)
					Paint.setMeterText(bar, `{string.format("%.0f", rank)} / {mastery.MaxRank}`)
					local plus = Paint.primaryButton(card, "+", UDim2.fromScale(0.78, 0.2), UDim2.fromScale(0.18, 0.6))
					local masteryId = mastery.Id
					plus.MouseButton1Click:Connect(function()
						fire("Character", "LearnMastery", { masteryId = masteryId })
					end)
					tipOn(plus, `{mastery.StatId} +{string.format("%.2f", mastery.PerRank)} per rank`)
					y += 64
				end
			end)
		end,
	}
	host.register(handle)
	return handle
end

return Masteries
