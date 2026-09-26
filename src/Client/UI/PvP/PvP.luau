--!strict
-- PvP / Live window (queue, instances, ranked).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DungeonCatalog = require(ReplicatedStorage.Definitions.Encounters.DungeonCatalog)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local RaidCatalog = require(ReplicatedStorage.Definitions.Encounters.RaidCatalog)
local StatWidgets = require(script:FindFirstAncestor("Client").UI.HUD.StatSheet.StatWidgets)
local SystemHints = require(script:FindFirstAncestor("Client").UI.System.SystemHints)
local UiTypes = require(script.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowHost = require(script.Parent.Parent.Parent.Runtime.Windows.WindowHost)

type JsonObject = JsonTypes.JsonObject
type WindowCtx = UiTypes.WindowCtx

local PvP = {}

function PvP.liveSig(ctx: WindowCtx, liveTab: string): string
	local bits = {
		liveTab,
		if ctx.queuedPvp then "1" else "0",
		if ctx.pvpFlag then "1" else "0",
		string.format("%.0f", ctx.honor),
		string.format("%.0f", ctx.conquest),
		string.format("%.0f", ctx.mmr),
		string.format("%.0f", ctx.pvpWins),
		string.format("%.0f", ctx.pvpLosses),
		string.format("%.0f", ctx.restXp),
		string.format("%.0f", ctx.deserter),
		ctx.bindZoneId,
	}
	for _, row in ctx.board do
		table.insert(bits, `{row.name}:{string.format("%.0f", row.score)}:{string.format("%.0f", row.mmr)}`)
	end
	for _, row in ctx.lockouts do
		table.insert(bits, `{row.id}:{string.format("%.0f", row.remaining)}`)
	end
	return table.concat(bits, "|")
end

function PvP.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	local gate = host.getGate()
	local liveTab = "Queue"

	local function fire(folder: string, name: string, payload: JsonObject)
		host.fire(folder, name, payload)
	end

	local live = host.make("Live", UDim2.fromScale(0.16, 0.1), UDim2.fromScale(0.68, 0.7), "PvP & Live")
	local honorBar = Paint.labeledMeter(
		live.Body,
		UDim2.fromScale(0.04, 0.04),
		UDim2.fromScale(0.45, 0.07),
		Color3.fromRGB(180, 48, 48)
	)
	local conqBar = Paint.labeledMeter(
		live.Body,
		UDim2.fromScale(0.51, 0.04),
		UDim2.fromScale(0.45, 0.07),
		Color3.fromRGB(64, 140, 220)
	)
	local pvpMeta =
		Paint.text(live.Body, "", UDim2.fromScale(0.04, 0.12), UDim2.fromScale(0.92, 0.06), Enum.TextXAlignment.Left)
	pvpMeta.TextColor3 = Paint.Gold
	local liveTabs: { [string]: TextButton } = {}
	for i, name in { "Queue", "Instances", "Ranked" } do
		local btn =
			Paint.tabButton(live.Body, name, UDim2.fromScale(0.04 + (i - 1) * 0.31, 0.185), UDim2.fromScale(0.3, 0.06))
		local captured = name
		btn.MouseButton1Click:Connect(function()
			liveTab = captured
			host.requestRefresh()
		end)
		liveTabs[name] = btn
	end
	local queueEcho =
		Paint.primaryButton(live.Body, "Queue Echo  (J)", UDim2.fromScale(0.04, 0.26), UDim2.fromScale(0.3, 0.08))
	local queueBg = Paint.primaryButton(live.Body, "Warfield", UDim2.fromScale(0.36, 0.26), UDim2.fromScale(0.3, 0.08))
	local leaveQ =
		Paint.primaryButton(live.Body, "Leave Queue", UDim2.fromScale(0.68, 0.26), UDim2.fromScale(0.28, 0.08))
	queueEcho.MouseButton1Click:Connect(function()
		fire("PvP", "QueueEcho", {})
	end)
	queueBg.MouseButton1Click:Connect(function()
		fire("PvP", "QueueWarfield", {})
	end)
	leaveQ.MouseButton1Click:Connect(function()
		fire("PvP", "LeaveQueue", {})
	end)
	local gateBindBtn =
		Paint.primaryButton(live.Body, "GateBind", UDim2.fromScale(0.04, 0.35), UDim2.fromScale(0.92, 0.07))
	gateBindBtn.MouseButton1Click:Connect(function()
		if host.shift() then
			fire("Character", "SetGateBind", {})
		else
			fire("Character", "UseGateBind", {})
		end
	end)
	local lootPane = Paint.parchment(live.Body, "Loot", UDim2.fromScale(0.04, 0.44), UDim2.fromScale(0.92, 0.52))
	local boardPane = Paint.parchment(live.Body, "Board", UDim2.fromScale(0.04, 0.44), UDim2.fromScale(0.92, 0.52))
	lootPane.Visible = false
	boardPane.Visible = false
	local lootLab = Paint.text(
		lootPane,
		"Lockouts",
		UDim2.fromScale(0.06, 0.04),
		UDim2.fromScale(0.88, 0.12),
		Enum.TextXAlignment.Left
	)
	lootLab.TextColor3 = Paint.Gold
	local lootBody = Paint.scroll(lootPane, "Rolls", UDim2.fromScale(0.04, 0.18), UDim2.fromScale(0.92, 0.78))
	local boardLab = Paint.text(
		boardPane,
		"Leaderboard",
		UDim2.fromScale(0.06, 0.04),
		UDim2.fromScale(0.88, 0.12),
		Enum.TextXAlignment.Left
	)
	boardLab.TextColor3 = Paint.Gold
	local boardList = Paint.scroll(boardPane, "Ranks", UDim2.fromScale(0.04, 0.18), UDim2.fromScale(0.92, 0.78))

	local handle: WindowHost.PanelHandle = {
		ids = { "Live" },
		refresh = function(ctx: WindowCtx)
			if not host.isOpen("Live") then
				return
			end
			gate.gate("Live", PvP.liveSig(ctx, liveTab), function()
				Paint.setFill(honorBar, math.clamp(ctx.honor / 500, 0, 1))
				Paint.setMeterText(honorBar, `Honor  {string.format("%.0f", ctx.honor)}`)
				Paint.setFill(conqBar, math.clamp(ctx.conquest / 200, 0, 1))
				Paint.setMeterText(conqBar, `Conquest  {string.format("%.0f", ctx.conquest)}`)
				pvpMeta.Text =
					`MMR {string.format("%.0f", ctx.mmr)}    {string.format("%.0f", ctx.pvpWins)}-{string.format(
						"%.0f",
						ctx.pvpLosses
					)}    {if ctx.pvpFlag then "FLAGGED" else "PvE"}    {if ctx.queuedPvp then "IN QUEUE" else ""}`
				gateBindBtn.Text =
					`Gate bind  {if ctx.bindZoneId ~= "" then ctx.bindZoneId else "Gate"}   RestXP {string.format(
						"%.0f",
						ctx.restXp
					)}   ·   Shift to set rest node`
				for name, btn in liveTabs do
					Paint.setTabActive(btn, name == liveTab)
				end
				local showQueue = liveTab == "Queue"
				queueEcho.Visible = showQueue
				queueBg.Visible = showQueue
				leaveQ.Visible = showQueue
				gateBindBtn.Visible = showQueue
				lootPane.Visible = liveTab == "Instances"
				boardPane.Visible = liveTab == "Ranked"
				lootLab.Text = "Dungeons, raids, lockouts"
				boardLab.Text = "Echo ladder"
				Paint.clearFrame(lootBody)
				local ly = 4
				if ctx.deserter > 0 then
					Paint.text(
						lootBody,
						`Deserter  {Paint.formatDuration(ctx.deserter)}`,
						UDim2.fromOffset(4, ly),
						UDim2.new(1, -8, 0, 20),
						Enum.TextXAlignment.Left
					).TextColor3 =
						Color3.fromRGB(255, 120, 100)
					ly += 22
				end
				for _, def in DungeonCatalog.all() do
					local dungeonId = def.Id
					local btn =
						Paint.primaryButton(lootBody, def.Name, UDim2.fromOffset(4, ly), UDim2.new(1, -8, 0, 26))
					btn.MouseButton1Click:Connect(function()
						fire("Dungeon", "StartDungeon", { dungeonId = dungeonId })
					end)
					ly += 30
				end
				for _, def in RaidCatalog.all() do
					local raidId = def.Id
					local btn =
						Paint.primaryButton(lootBody, def.Name, UDim2.fromOffset(4, ly), UDim2.new(1, -8, 0, 26))
					btn.MouseButton1Click:Connect(function()
						fire("Dungeon", "StartRaid", { raidId = raidId })
					end)
					ly += 30
				end
				if #ctx.lockouts == 0 then
					Paint.text(
						lootBody,
						"No instance lockouts.",
						UDim2.fromOffset(4, ly),
						UDim2.new(1, -8, 0, 22),
						Enum.TextXAlignment.Left
					)
				end
				for _, row in ctx.lockouts do
					Paint.text(
						lootBody,
						`Lockout  {row.id}  {string.format("%.0f", row.remaining / 3600)}h`,
						UDim2.fromOffset(4, ly),
						UDim2.new(1, -8, 0, 22),
						Enum.TextXAlignment.Left
					).TextColor3 =
						Color3.fromRGB(255, 160, 160)
					ly += 24
				end
				Paint.clearFrame(boardList)
				if #ctx.board == 0 then
					SystemHints.emptyHint(boardList, "No ladder rows yet. Queue Echo to climb.")
				end
				for i, row in ctx.board do
					StatWidgets.statLine(
						boardList,
						(i - 1) * 24,
						row.name,
						`{string.format("%.0f", row.score)}   {string.format("%.0f", row.mmr)}`
					)
				end
			end)
		end,
	}
	host.register(handle)
	return handle
end

return PvP
