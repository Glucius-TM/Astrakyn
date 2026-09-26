--!strict
-- WoW-style unified character sheet: tab bar + content frames shared across window modules.

local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)

export type TabId = "Character" | "Spellbook" | "Talents" | "Quests" | "Achievements" | "Collections" | "Masteries"

export type TabDef = {
	id: TabId,
	label: string,
}

export type SheetTabsApi = {
	activeTab: TabId,
	setTab: (tab: TabId) -> (),
	isTab: (tab: TabId) -> boolean,
	frame: (tab: TabId) -> Frame,
	tabBar: Frame,
	content: Frame,
	paintTabStates: () -> (),
}

local TAB_ORDER: { TabDef } = {
	{ id = "Character", label = "Character" },
	{ id = "Spellbook", label = "Spellbook" },
	{ id = "Talents", label = "Talents" },
	{ id = "Quests", label = "Quest Log" },
	{ id = "Achievements", label = "Achievements" },
	{ id = "Collections", label = "Collections" },
	{ id = "Masteries", label = "Masteries" },
}

local TAB_SET: { [string]: boolean } = {
	Character = true,
	Spellbook = true,
	Talents = true,
	Quests = true,
	Achievements = true,
	Collections = true,
	Masteries = true,
}

local Tabs = {}

local sharedFrames: { [string]: Frame } = {}

function Tabs.sharedFrame(tab: TabId): Frame?
	return sharedFrames[tab]
end

function Tabs.route(panelId: string): TabId?
	if TAB_SET[panelId] ~= true then
		return nil
	end
	return panelId :: TabId
end

export type PaperdollSlotRect = {
	pos: UDim2,
	size: UDim2,
}

export type PaperdollLayout = {
	slots: { [string]: PaperdollSlotRect },
	portrait: PaperdollSlotRect,
}

type GridCell = {
	col: number,
	row: number,
	weapon: boolean?,
}

local BODY_COLS = 3
local BODY_ROWS = 7
local WEAPON_COLS = 4
local SLOT_GAP = 4

-- WoW-style 3-column paperdoll; weapon row is 4 centered squares.
local PAPERDOLL_GRID: { [string]: GridCell } = {
	Shoulders = { col = 0, row = 0 },
	Head = { col = 1, row = 0 },
	Back = { col = 0, row = 1 },
	Neck = { col = 1, row = 1 },
	Tabard = { col = 2, row = 1 },
	Shirt = { col = 0, row = 2 },
	Chest = { col = 1, row = 2 },
	Wrist = { col = 0, row = 3 },
	Waist = { col = 1, row = 3 },
	Hands = { col = 2, row = 3 },
	Legs = { col = 1, row = 4 },
	Feet = { col = 1, row = 5 },
	Ring1 = { col = 0, row = 5 },
	Ring2 = { col = 2, row = 5 },
	Trinket1 = { col = 0, row = 6 },
	Trinket2 = { col = 2, row = 6 },
	MainHand = { col = 0, row = 7, weapon = true },
	OffHand = { col = 1, row = 7, weapon = true },
	Ranged = { col = 2, row = 7, weapon = true },
	Relic = { col = 3, row = 7, weapon = true },
}

local function offsetSquare(x: number, y: number, cell: number): PaperdollSlotRect
	return {
		pos = UDim2.fromOffset(x, y),
		size = UDim2.fromOffset(cell, cell),
	}
end

local function layoutWithPixels(paperW: number, paperH: number): PaperdollLayout
	local marginX = 6
	local marginY = 4
	local weaponBand = math.clamp(math.floor(paperH * 0.14), 36, 52)
	local bodyH = paperH - marginY * 2 - weaponBand - SLOT_GAP
	local bodyW = paperW - marginX * 2
	local cell = math.floor(math.min(bodyW / BODY_COLS, bodyH / BODY_ROWS) - SLOT_GAP)
	cell = math.clamp(cell, 28, 56)
	local gridW = BODY_COLS * cell + (BODY_COLS - 1) * SLOT_GAP
	local gridH = BODY_ROWS * cell + (BODY_ROWS - 1) * SLOT_GAP
	local startX = math.floor((paperW - gridW) / 2)
	local startY = marginY
	local weaponCell =
		math.clamp(math.floor(math.min((paperW - marginX * 2) / WEAPON_COLS, weaponBand) - SLOT_GAP), 28, 56)
	local weaponRowW = WEAPON_COLS * weaponCell + (WEAPON_COLS - 1) * SLOT_GAP
	local weaponX = math.floor((paperW - weaponRowW) / 2)
	local weaponY = startY + gridH + SLOT_GAP

	local slots: { [string]: PaperdollSlotRect } = {}
	for slotId, cellDef in PAPERDOLL_GRID do
		if cellDef.weapon == true then
			local x = weaponX + cellDef.col * (weaponCell + SLOT_GAP)
			slots[slotId] = offsetSquare(x, weaponY, weaponCell)
		else
			local x = startX + cellDef.col * (cell + SLOT_GAP)
			local y = startY + cellDef.row * (cell + SLOT_GAP)
			slots[slotId] = offsetSquare(x, y, cell)
		end
	end

	local portraitX = startX + cell + SLOT_GAP
	local portraitY = startY + 2 * (cell + SLOT_GAP)
	local portraitH = 3 * cell + 2 * SLOT_GAP
	return {
		slots = slots,
		portrait = {
			pos = UDim2.fromOffset(portraitX, portraitY),
			size = UDim2.fromOffset(cell, portraitH),
		},
	}
end

local function layoutWithScale(): PaperdollLayout
	local cell = 0.102
	local gap = 0.012
	local startX = 0.11
	local startY = 0.02
	local slots: { [string]: PaperdollSlotRect } = {}
	for slotId, cellDef in PAPERDOLL_GRID do
		if cellDef.weapon == true then
			local weaponStart = 0.06
			local weaponCell = 0.205
			local x = weaponStart + cellDef.col * (weaponCell + 0.01)
			slots[slotId] = {
				pos = UDim2.fromScale(x, 0.78),
				size = UDim2.fromScale(weaponCell, weaponCell),
			}
		else
			slots[slotId] = {
				pos = UDim2.fromScale(startX + cellDef.col * (cell + gap), startY + cellDef.row * (cell + gap)),
				size = UDim2.fromScale(cell, cell),
			}
		end
	end
	return {
		slots = slots,
		portrait = {
			pos = UDim2.fromScale(startX + cell + gap, startY + 2 * (cell + gap)),
			size = UDim2.fromScale(cell, 3 * cell + 2 * gap),
		},
	}
end

function Tabs.layoutPaperdoll(paper: Frame): PaperdollLayout
	local w = paper.AbsoluteSize.X
	local h = paper.AbsoluteSize.Y
	if w >= 40 and h >= 40 then
		return layoutWithPixels(w, h)
	end
	return layoutWithScale()
end

function Tabs.mount(body: Frame, initialTab: TabId, onTabChanged: (TabId) -> ()): SheetTabsApi
	local activeTab: TabId = initialTab
	local tabButtons: { [string]: TextButton } = {}
	local tabFrames: { [string]: Frame } = {}

	local tabBar = Paint.inset(body, "SheetTabs", UDim2.fromScale(0.008, 0.008), UDim2.fromScale(0.984, 0.065))
	local content = Paint.inset(body, "SheetContent", UDim2.fromScale(0.008, 0.078), UDim2.fromScale(0.984, 0.914))

	local tabCount = #TAB_ORDER
	local tabWidth = 1 / tabCount
	for i, def in TAB_ORDER do
		local btn = Paint.tabButton(
			tabBar,
			def.label,
			UDim2.fromScale((i - 1) * tabWidth + 0.002, 0.08),
			UDim2.fromScale(tabWidth - 0.004, 0.84)
		)
		btn.Name = `Tab{def.id}`
		tabButtons[def.id] = btn
		local frame = Instance.new("Frame")
		frame.Name = def.id
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		frame.Size = UDim2.fromScale(1, 1)
		frame.Visible = def.id == activeTab
		frame.Parent = content
		tabFrames[def.id] = frame
		sharedFrames[def.id] = frame
		local captured = def.id
		btn.MouseButton1Click:Connect(function()
			if
				captured == "Character"
				or captured == "Spellbook"
				or captured == "Talents"
				or captured == "Quests"
				or captured == "Achievements"
				or captured == "Collections"
				or captured == "Masteries"
			then
				activeTab = captured
				onTabChanged(activeTab)
			end
		end)
	end

	local function paintTabStates()
		for id, btn in tabButtons do
			Paint.setTabActive(btn, id == activeTab)
		end
		for id, frame in tabFrames do
			frame.Visible = id == activeTab
		end
	end

	local api: SheetTabsApi
	api = {
		activeTab = activeTab,
		setTab = function(tab: TabId)
			activeTab = tab
			api.activeTab = tab
			paintTabStates()
			onTabChanged(tab)
		end,
		isTab = function(tab: TabId): boolean
			return activeTab == tab
		end,
		frame = function(tab: TabId): Frame
			return tabFrames[tab]
		end,
		tabBar = tabBar,
		content = content,
		paintTabStates = paintTabStates,
	}

	paintTabStates()
	return api
end

function Tabs.syncTab(api: SheetTabsApi, tab: TabId)
	api.activeTab = tab
	api.paintTabStates()
end

return Tabs
