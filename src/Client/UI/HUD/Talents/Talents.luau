--!strict
-- WoW-style talent tree renderer (3 trees, 7 tiers, connector lines).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClassTalentCatalog = require(ReplicatedStorage.Definitions.Characters.ClassTalentCatalog)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local Tabs = require(script.Parent.Parent.Tabs.Tabs)
local TalentTreeCatalog = require(ReplicatedStorage.Definitions.Characters.TalentTreeCatalog)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowHost = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowHost)

type JsonObject = JsonTypes.JsonObject
type WindowCtx = UiTypes.WindowCtx

export type TalentPaintDeps = {
	tipOn: (guiObject: GuiObject, text: string, titleColor: Color3?) -> (),
	onLearn: (talentId: string) -> (),
}

local TIER_COUNT = 7
local COL_COUNT = 3

local Talents = {}

function Talents.sig(classId: string, treeIndex: number, talents: { string }, points: number): string
	return `{classId}|{treeIndex}|{table.concat(talents, ",")}|{string.format("%.0f", points)}`
end

local function treePointsSpent(tree: TalentTreeCatalog.TalentTreeDefinition, known: { [string]: boolean }): number
	local spent = 0
	for _, node in tree.Nodes do
		if known[node.TalentId] then
			spent += 1
		end
	end
	return spent
end

local function nodeUnlocked(
	node: TalentTreeCatalog.TalentTreeNode,
	spentInTree: number,
	known: { [string]: boolean }
): boolean
	if known[node.TalentId] then
		return true
	end
	return spentInTree >= node.RequiresTreePoints
end

function Talents.paintTree(
	canvas: Frame,
	classId: string,
	treeIndex: number,
	known: { [string]: boolean },
	talentPoints: number,
	deps: TalentPaintDeps
)
	Paint.clearFrame(canvas)
	local trees = TalentTreeCatalog.forClass(classId)
	local tree = trees[treeIndex]
	if tree == nil then
		Paint.text(
			canvas,
			"No talent tree for this class.",
			UDim2.fromOffset(12, 12),
			UDim2.new(1, -24, 0, 28),
			Enum.TextXAlignment.Left
		)
		return
	end
	local spentInTree = treePointsSpent(tree, known)
	local tierHeight = 0.11
	local colWidth = 0.28
	local leftPad = 0.08
	local topPad = 0.04

	for tier = 1, TIER_COUNT - 1 do
		for col = 1, COL_COUNT do
			local x = leftPad + (col - 1) * colWidth + colWidth * 0.35
			local y0 = topPad + (tier - 1) * tierHeight + tierHeight * 0.55
			local y1 = topPad + tier * tierHeight + tierHeight * 0.15
			local line = Instance.new("Frame")
			line.Name = `Link_T{tier}_C{col}`
			line.AnchorPoint = Vector2.new(0.5, 0)
			line.BackgroundColor3 = Paint.Bronze
			line.BackgroundTransparency = 0.35
			line.BorderSizePixel = 0
			line.Position = UDim2.fromScale(x, y0)
			line.Size = UDim2.new(0, 2, y1 - y0, 0)
			line.ZIndex = 1
			line.Parent = canvas
		end
		local tierLab = Paint.text(
			canvas,
			`Tier {tier}`,
			UDim2.fromScale(0.01, topPad + (tier - 1) * tierHeight),
			UDim2.fromScale(0.06, tierHeight * 0.9),
			Enum.TextXAlignment.Left
		)
		tierLab.TextColor3 = Paint.TextColorSecondary
		tierLab.TextSize = Paint.TextSizeCaption
		tierLab.ZIndex = 2
	end

	for _, node in tree.Nodes do
		local talent = ClassTalentCatalog.get(node.TalentId)
		if talent == nil then
			continue
		end
		local learned = known[node.TalentId] == true
		local unlocked = nodeUnlocked(node, spentInTree, known)
		local x = leftPad + (node.Column - 1) * colWidth + colWidth * 0.08
		local y = topPad + (node.Tier - 1) * tierHeight + tierHeight * 0.12
		local btn = Paint.primaryButton(
			canvas,
			if learned then "●" else "○",
			UDim2.fromScale(x, y),
			UDim2.fromScale(colWidth * 0.72, tierHeight * 0.72)
		)
		btn.TextSize = 22
		btn.ZIndex = 3
		if learned then
			btn.TextColor3 = Paint.Gold
			Paint.gradient(btn, Color3.fromRGB(118, 84, 28), Color3.fromRGB(56, 38, 12), 90)
		elseif unlocked and talentPoints > 0 then
			btn.TextColor3 = Paint.Parchment
		else
			btn.TextColor3 = Paint.Muted
			btn.BackgroundTransparency = 0.35
		end
		local caption = Paint.text(
			canvas,
			talent.Name,
			UDim2.fromScale(x - 0.02, y + tierHeight * 0.62),
			UDim2.fromScale(colWidth * 0.9, tierHeight * 0.35),
			Enum.TextXAlignment.Center
		)
		caption.TextSize = Paint.TextSizeCaption
		caption.TextWrapped = true
		caption.TextColor3 = if learned then Paint.Gold else Paint.TextColorBody
		caption.ZIndex = 3
		local canLearn = unlocked and not learned and talentPoints > 0
		local tip = `{talent.Name}\n{talent.Op} {talent.StatId} {string.format("%.2f", talent.Value)}`
		if learned then
			tip ..= "\nKnown"
		elseif not unlocked then
			tip ..= `\nRequires {node.RequiresTreePoints} points in this tree`
		elseif talentPoints <= 0 then
			tip ..= "\nNo talent points"
		else
			tip ..= "\nClick to learn"
		end
		deps.tipOn(btn, tip, if learned then Paint.Gold else nil)
		if canLearn then
			local talentId = node.TalentId
			btn.MouseButton1Click:Connect(function()
				deps.onLearn(talentId)
			end)
		end
	end
end

function Talents.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	local gate = host.getGate()
	local talentTreeIndex = 1

	local function fire(folder: string, name: string, payload: JsonObject)
		host.fire(folder, name, payload)
	end

	local function tipOn(guiObject: GuiObject, text: string, titleColor: Color3?)
		host.tipOn(guiObject, text, titleColor)
	end

	local talentsFrame = Tabs.sharedFrame("Talents")
	assert(talentsFrame, "Talents tab frame missing")
	local talentShell = Paint.parchment(talentsFrame, "Shell", UDim2.fromScale(0.01, 0.01), UDim2.fromScale(0.98, 0.98))
	local talentTitle = Paint.text(
		talentShell,
		"Talents",
		UDim2.fromScale(0.03, 0.02),
		UDim2.fromScale(0.5, 0.06),
		Enum.TextXAlignment.Left
	)
	talentTitle.Font = Paint.FontTitle
	talentTitle.TextColor3 = Paint.Gold
	talentTitle.TextSize = Paint.TextSizeTitle
	local talentHeader =
		Paint.text(talentShell, "", UDim2.fromScale(0.03, 0.08), UDim2.fromScale(0.55, 0.05), Enum.TextXAlignment.Left)
	talentHeader.TextColor3 = Paint.Cast
	talentHeader.TextSize = Paint.TextSizeCaption
	local respecBtn =
		Paint.primaryButton(talentShell, "Respec", UDim2.fromScale(0.72, 0.02), UDim2.fromScale(0.24, 0.08))
	respecBtn.MouseButton1Click:Connect(function()
		fire("Character", "RespecTalents", {})
	end)
	local talentTreeBar = Paint.inset(talentShell, "Trees", UDim2.fromScale(0.02, 0.14), UDim2.fromScale(0.96, 0.08))
	local talentGrid =
		Paint.parchment(talentShell, "TreeCanvas", UDim2.fromScale(0.02, 0.24), UDim2.fromScale(0.96, 0.72))

	local handle: WindowHost.PanelHandle = {
		ids = { "Talents" },
		refresh = function(ctx: WindowCtx)
			if not host.isSheetTab("Talents") then
				return
			end
			gate.gate(
				"Talents",
				Talents.sig(ctx.classId, talentTreeIndex, ctx.talents, ctx.talentPoints),
				function()
					local archLabel = TalentTreeCatalog.classLabel(ctx.classId)
					talentHeader.Text = `{archLabel}   ·   {string.format("%.0f", ctx.talentPoints)} points available`
					Paint.clearFrame(talentTreeBar)
					local trees = TalentTreeCatalog.forClass(ctx.classId)
					local treeW = 0.99 / math.max(1, #trees)
					for i, tree in trees do
						local btn = Paint.tabButton(
							talentTreeBar,
							tree.Name,
							UDim2.fromScale(0.005 + (i - 1) * treeW, 0.12),
							UDim2.fromScale(treeW - 0.006, 0.76)
						)
						Paint.setTabActive(btn, i == talentTreeIndex)
						local captured = i
						btn.MouseButton1Click:Connect(function()
							talentTreeIndex = captured
							host.requestRefresh()
						end)
					end
					local known: { [string]: boolean } = {}
					for _, id in ctx.talents do
						known[id] = true
					end
					Talents.paintTree(talentGrid, ctx.classId, talentTreeIndex, known, ctx.talentPoints, {
						tipOn = tipOn,
						onLearn = function(talentId: string)
							fire("Character", "LearnTalent", { talentId = talentId })
						end,
					})
				end
			)
		end,
	}
	host.register(handle)
	return handle
end

return Talents
