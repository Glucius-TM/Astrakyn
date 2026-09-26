--!strict

-- Shared collapsible stat sheet list for Character and Inspect.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtraPoolCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.ExtraPoolCatalog)
local ExtraPools = require(script.Parent.Parent.ExtraPools.ExtraPools)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local StatWidgets = require(script.Parent.StatWidgets)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)

type InspectorRow = UiTypes.InspectorRow
type InspectorStageRow = UiTypes.InspectorStageRow
type StatEdgeRow = UiTypes.StatEdgeRow
type ExtraPoolBar = UiTypes.ExtraPoolBar

export type CollapseState = { [string]: boolean }

export type PaintArgs = {
	parent: Instance,
	inspector: { InspectorRow },
	statEdges: { StatEdgeRow }?,
	statEdgesTruncated: boolean?,
	statEdgesTotal: number?,
	extraPools: { ExtraPoolBar }?,
	collapse: CollapseState,
	tipOn: ((GuiObject, string) -> ())?,
	onCollapseChanged: (() -> ())?,
}

local GRAPH_DISPLAY_LIMIT = 48
local HEADER_HEIGHT = 26
local ROW_HEIGHT = 24

local KNOWN_GROUPS: { [string]: boolean } = {}
for _, group in Paint.SheetGroups do
	KNOWN_GROUPS[group] = true
end

local StatSheet = {}

local function isCollapsed(collapse: CollapseState, group: string): boolean
	local value = collapse[group]
	if value == nil then
		return group ~= "Overview"
	end
	return value
end

local function resolveGroup(group: string): string
	if KNOWN_GROUPS[group] == true then
		return group
	end
	return "Advanced"
end

local function graphSectionLabel(edgeCount: number): string
	if edgeCount <= 0 then
		return "Graph"
	end
	return `Graph ({edgeCount})`
end

local function groupStatEdges(edges: { StatEdgeRow }): { { from: string, targets: { string } } }
	local order: { string } = {}
	local grouped: { [string]: { string } } = {}
	for _, edge in edges do
		local bucket = grouped[edge.from]
		if bucket == nil then
			bucket = {}
			grouped[edge.from] = bucket
			table.insert(order, edge.from)
		end
		local seen = false
		for _, toId in bucket do
			if toId == edge.to then
				seen = true
				break
			end
		end
		if not seen then
			table.insert(bucket, edge.to)
		end
	end
	local rows: { { from: string, targets: { string } } } = {}
	for _, fromId in order do
		local targets = grouped[fromId]
		if targets ~= nil then
			table.insert(rows, { from = fromId, targets = targets })
		end
	end
	return rows
end

local function formatInspectorValue(entry: InspectorRow, extraPools: { ExtraPoolBar }): string
	local shownRaw = if entry.asPercent
		then string.format("%." .. tostring(math.max(0, entry.precision)) .. "f%%", entry.final * 100)
		else string.format("%." .. tostring(math.max(0, entry.precision)) .. "f", entry.final)
	if ExtraPoolCatalog.isExtraPool(entry.statId) then
		return ExtraPools.sheetValue(entry.statId, extraPools, shownRaw)
	end
	return shownRaw
end

local function inspectorTipBody(entry: InspectorRow, extraPools: { ExtraPoolBar }, shownRaw: string): string
	local bits: { string } = {}
	for _, src in entry.lines do
		table.insert(bits, `{src.source} {src.op} {string.format("%.2f", src.value)}`)
	end
	local stages = entry.stages
	if stages ~= nil then
		for _, stage in stages do
			table.insert(bits, `{stage.kind} {stage.label} {string.format("%.2f", stage.value)}`)
		end
	end
	local tipBody = `{entry.name}\n{table.concat(bits, "\n")}`
	if ExtraPoolCatalog.isExtraPool(entry.statId) then
		for _, bar in extraPools do
			if bar.statId == entry.statId then
				tipBody = `{ExtraPools.tip(bar)}\nMax stat  {shownRaw}`
				break
			end
		end
	end
	return tipBody
end

local function paintGroupHeader(
	parent: Instance,
	y: number,
	label: string,
	collapsed: boolean,
	onToggle: () -> ()
): number
	local header = Instance.new("TextButton")
	header.Size = UDim2.new(1, -10, 0, HEADER_HEIGHT)
	header.Position = UDim2.fromOffset(5, y)
	header.BackgroundColor3 = Paint.WoodInner
	header.BackgroundTransparency = 0.15
	header.BorderSizePixel = 0
	header.AutoButtonColor = false
	header.Text = ""
	header.Parent = parent
	Paint.corner(header, 3)
	Paint.trim(header, Paint.Bronze, 1).Transparency = 0.45
	local chevron = if collapsed then "▸" else "▾"
	local left = Paint.text(
		header,
		chevron,
		UDim2.fromOffset(8, 0),
		UDim2.fromOffset(16, HEADER_HEIGHT),
		Enum.TextXAlignment.Left
	)
	left.TextColor3 = Paint.Gold
	left.Font = Paint.FontBold
	local title = Paint.text(header, label, UDim2.fromOffset(24, 0), UDim2.new(1, -32, 1, 0), Enum.TextXAlignment.Left)
	title.TextColor3 = Paint.Gold
	title.Font = Paint.FontTitle
	title.TextSize = Paint.TextSizeSection
	Paint.wireHover(header)
	header.MouseButton1Click:Connect(onToggle)
	return y + HEADER_HEIGHT
end

local function paintInspectorRows(
	parent: Instance,
	entries: { InspectorRow },
	startY: number,
	extraPools: { ExtraPoolBar },
	tipOn: ((GuiObject, string) -> ())?
): number
	if #entries == 0 then
		local empty = Paint.text(
			parent,
			"No stats in this group.",
			UDim2.fromOffset(8, startY),
			UDim2.new(1, -16, 0, ROW_HEIGHT),
			Enum.TextXAlignment.Left
		)
		empty.TextColor3 = Paint.TextColorSecondary
		empty.TextSize = Paint.TextSizeCaption
		return startY + ROW_HEIGHT
	end

	local n = 0
	for _, entry in entries do
		n += 1
		local shownRaw = if entry.asPercent
			then string.format("%." .. tostring(math.max(0, entry.precision)) .. "f%%", entry.final * 100)
			else string.format("%." .. tostring(math.max(0, entry.precision)) .. "f", entry.final)
		local shown = formatInspectorValue(entry, extraPools)
		local col = (n - 1) % 2
		local gridRow = math.floor((n - 1) / 2)
		local line = StatWidgets.statLine(parent, startY + gridRow * ROW_HEIGHT, entry.name, shown, col)
		if tipOn ~= nil then
			tipOn(line, inspectorTipBody(entry, extraPools, shownRaw))
		end
	end
	return startY + math.ceil(n / 2) * ROW_HEIGHT
end

local function paintGraphSection(
	parent: Instance,
	startY: number,
	statEdges: { StatEdgeRow },
	statEdgesTruncated: boolean?,
	statEdgesTotal: number?,
	tipOn: ((GuiObject, string) -> ())?
): number
	local grouped = groupStatEdges(statEdges)
	local totalGroups = #grouped
	local shownGroups = math.min(totalGroups, GRAPH_DISPLAY_LIMIT)
	local n = 0
	for i = 1, shownGroups do
		local row = grouped[i]
		n += 1
		local col = (n - 1) % 2
		local gridRow = math.floor((n - 1) / 2)
		local targets = table.concat(row.targets, ", ")
		local line = StatWidgets.statLine(parent, startY + gridRow * ROW_HEIGHT, row.from, `→ {targets}`, col)
		if tipOn ~= nil then
			tipOn(line, `{row.from}\nFeeds: {targets}`)
		end
	end
	if n == 0 then
		local empty = Paint.text(
			parent,
			"No stat dependencies yet.\nEquip gear or advance talents — edges arrive from the live catalog via CharacterSheet.",
			UDim2.fromOffset(8, startY),
			UDim2.new(1, -16, 0, 48),
			Enum.TextXAlignment.Left
		)
		empty.TextColor3 = Paint.TextColorSecondary
		empty.TextSize = Paint.TextSizeCaption
		empty.TextWrapped = true
		return startY + 52
	end
	local bottomY = startY + math.ceil(n / 2) * ROW_HEIGHT
	if totalGroups > shownGroups or statEdgesTruncated == true then
		local edgeTotal = statEdgesTotal or #statEdges
		local footer = Paint.text(
			parent,
			`Showing {shownGroups} of {totalGroups} sources ({#statEdges} / {edgeTotal} edges).`,
			UDim2.fromOffset(8, bottomY + 4),
			UDim2.new(1, -16, 0, 20),
			Enum.TextXAlignment.Left
		)
		footer.TextColor3 = Paint.TextColorSecondary
		footer.TextSize = Paint.TextSizeCaption
		return bottomY + 24
	end
	return bottomY
end

function StatSheet.ensureDefaults(collapse: CollapseState)
	for _, group in Paint.SheetGroups do
		if collapse[group] == nil then
			collapse[group] = group ~= "Overview"
		end
	end
end

function StatSheet.groupOrder(): { string }
	return Paint.SheetGroups
end

function StatSheet.rowsByGroup(inspector: { InspectorRow }): { [string]: { InspectorRow } }
	local byGroup: { [string]: { InspectorRow } } = {}
	for _, entry in inspector do
		local bucket = resolveGroup(entry.group)
		local rows = byGroup[bucket]
		if rows == nil then
			rows = {}
			byGroup[bucket] = rows
		end
		table.insert(rows, entry)
	end
	return byGroup
end

function StatSheet.contentSig(
	inspector: { InspectorRow },
	collapse: CollapseState,
	edgeCount: number,
	edgeTotal: number,
	truncated: boolean
): string
	local bits: { string } = {}
	for _, group in StatSheet.groupOrder() do
		table.insert(bits, if isCollapsed(collapse, group) then "1" else "0")
	end
	for _, entry in inspector do
		table.insert(bits, `{entry.statId}:{string.format("%.6f", entry.final)}:{entry.group}`)
	end
	table.insert(bits, tostring(edgeCount))
	table.insert(bits, tostring(edgeTotal))
	table.insert(bits, if truncated then "1" else "0")
	return table.concat(bits, "|")
end

function StatSheet.paint(args: PaintArgs)
	local parent = args.parent
	local collapse = args.collapse
	local extraPools = args.extraPools or {}
	local statEdges = args.statEdges or {}
	local tipOn = args.tipOn

	StatSheet.ensureDefaults(collapse)
	Paint.clearFrame(parent)

	local byGroup = StatSheet.rowsByGroup(args.inspector)
	local y = 0

	for _, group in StatSheet.groupOrder() do
		local collapsed = isCollapsed(collapse, group)
		local label = if group == "Graph" then graphSectionLabel(#statEdges) else group
		y = paintGroupHeader(parent, y, label, collapsed, function()
			collapse[group] = not isCollapsed(collapse, group)
			if args.onCollapseChanged ~= nil then
				args.onCollapseChanged()
			end
		end)

		if not collapsed then
			if group == "Graph" then
				y = paintGraphSection(parent, y, statEdges, args.statEdgesTruncated, args.statEdgesTotal, tipOn)
			else
				y = paintInspectorRows(parent, byGroup[group] or {}, y, extraPools, tipOn)
			end
			y += 4
		end
	end
end

return StatSheet
