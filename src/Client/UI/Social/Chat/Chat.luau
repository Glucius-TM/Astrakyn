--!strict
-- Chat tabs, transcript, send, whisper, and rest fade.

local ChatLogic = require(script.Parent.ChatLogic)
local ChatPaint = require(script:FindFirstAncestor("Client").UI.Social.Chat.ChatPaint)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local TooltipLayer = require(script:FindFirstAncestor("Client").Runtime.Windows.TooltipLayer)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowRefresh = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowRefresh)

type NearbyRow = UiTypes.NearbyRow
type PartyRow = UiTypes.PartyRow
type TooltipApi = TooltipLayer.TooltipApi
type WhisperCandidate = ChatLogic.WhisperCandidate

export type ChatDeps = {
	onChatSend: (channel: string, body: string) -> (),
	onWhisper: (userId: number, body: string) -> (),
	notifyError: (message: string) -> (),
	getTargetName: () -> string,
}

export type ChromeShared = { tooltip: TooltipApi, gate: WindowRefresh.RefreshGate }

export type ChatApi = {
	pushChat: (tab: string, line: string, colorHint: string?) -> (),
	submitChat: (body: string, nearby: { NearbyRow }, party: { PartyRow }, targetName: string) -> (),
	focusChat: () -> (),
	setNearby: (rows: { NearbyRow }) -> (),
	setPartyRows: (rows: { PartyRow }) -> (),
	tick: () -> (),
}

local CHAT_TABS = { "All", "Say", "Party", "Guild", "Zone", "Combat", "Whisper" }
local CHAT_HISTORY = 24
local CHAT_REST_FADE = 0.15

local Chat = {}

local function chatColor(tab: string, colorHint: string?): Color3
	if colorHint == "combat" then
		return Paint.channelColor("Combat")
	elseif colorHint == "system" then
		return Paint.channelColor("System")
	end
	return Paint.channelColor(tab)
end

local function candidateList(rows: { NearbyRow }): { WhisperCandidate }
	local list: { WhisperCandidate } = {}
	for _, row in rows do
		table.insert(list, { userId = row.userId, name = row.name })
	end
	return list
end

local function partyCandidates(rows: { PartyRow }): { WhisperCandidate }
	local list: { WhisperCandidate } = {}
	for _, row in rows do
		table.insert(list, { userId = row.userId, name = row.name })
	end
	return list
end

function Chat.mount(root: Frame, deps: ChatDeps, _shared: ChromeShared): ChatApi
	local chatPanel = Paint.panel(root, "Chat", UDim2.fromScale(0.012, 0.58), UDim2.fromScale(0.3, 0.28), Paint.Ink)
	chatPanel.BackgroundTransparency = 0.06

	local chatTabs: { [string]: TextButton } = {}
	for i, name in CHAT_TABS do
		local btn = Paint.tabButton(
			chatPanel,
			name,
			UDim2.fromScale(0.012 + (i - 1) * 0.14, 0.02),
			UDim2.fromScale(0.132, 0.095)
		)
		btn.Name = `Tab{name}`
		chatTabs[name] = btn
	end

	local chatLog = ChatPaint.chatTranscript(chatPanel, UDim2.fromScale(0.03, 0.14), UDim2.fromScale(0.94, 0.6))

	local chatBox = Instance.new("TextBox")
	chatBox.Name = "ChatEntry"
	chatBox.Size = UDim2.fromScale(0.94, 0.17)
	chatBox.Position = UDim2.fromScale(0.03, 0.77)
	chatBox.BackgroundColor3 = Paint.WoodInner
	chatBox.TextColor3 = Paint.TextColorBody
	chatBox.Font = Paint.FontBody
	chatBox.TextSize = Paint.TextSizeBody
	chatBox.PlaceholderColor3 = Paint.TextColorSecondary
	chatBox.PlaceholderText = "Enter to chat   /p /g /z /w"
	chatBox.Text = ""
	chatBox.ClearTextOnFocus = false
	chatBox.Parent = chatPanel
	Paint.corner(chatBox, 2)
	Paint.trim(chatBox, Paint.Bronze, 1)
	Paint.markChrome(chatBox, "WoodInner", "Bronze", "Cream", nil)

	local chatAll: { { text: string, color: Color3 } } = {}
	local chatByTab: { [string]: { { text: string, color: Color3 } } } = {}
	for _, name in CHAT_TABS do
		chatByTab[name] = {}
	end
	local chatTab = "All"
	local chatFocused = false
	local chatFadeDirty = true
	local nearbyRows: { NearbyRow } = {}
	local partyRowsCache: { PartyRow } = {}

	local function paintChatFade()
		local transparency = if chatFocused then 0 else CHAT_REST_FADE
		for _, child in chatLog.Root:GetChildren() do
			if child:IsA("TextLabel") then
				child.TextTransparency = transparency
			end
		end
		chatFadeDirty = false
	end

	local function renderChatTab()
		for name, btn in chatTabs do
			Paint.setTabActive(btn, name == chatTab)
		end
		local source = if chatTab == "All" then chatAll else chatByTab[chatTab]
		chatLog.render(if source then source else {})
		chatFadeDirty = true
	end

	local function pushChat(tab: string, line: string, colorHint: string?)
		local bucketName = if chatByTab[tab] then tab else "Say"
		local row = { text = ChatLogic.stampLine(line, Paint.clockStamp()), color = chatColor(bucketName, colorHint) }
		local bucket = chatByTab[bucketName]
		if bucket then
			table.insert(bucket, row)
			while #bucket > CHAT_HISTORY do
				table.remove(bucket, 1)
			end
		end
		table.insert(chatAll, row)
		while #chatAll > CHAT_HISTORY do
			table.remove(chatAll, 1)
		end
		if chatTab == "All" or chatTab == bucketName then
			chatLog.push(row.text, row.color)
			chatFadeDirty = true
		end
	end

	local function submitChat(body: string, nearby: { NearbyRow }, party: { PartyRow }, targetName: string)
		if body == "" then
			return
		end
		local parsed = ChatLogic.parseSlash(body)
		if parsed.body == "" then
			return
		end
		if parsed.whisper then
			local pick = ChatLogic.resolveWhisper(targetName, candidateList(nearby), partyCandidates(party))
			if pick == nil then
				deps.notifyError("No one to whisper.")
				return
			end
			deps.onWhisper(pick.userId, parsed.body)
			return
		end
		deps.onChatSend(parsed.channel, parsed.body)
	end

	local function focusChat()
		chatBox:CaptureFocus()
	end

	local function setNearby(rows: { NearbyRow })
		nearbyRows = rows
	end

	local function setPartyRows(rows: { PartyRow })
		partyRowsCache = rows
	end

	local function tick()
		if chatFadeDirty then
			paintChatFade()
		end
	end

	for name, btn in chatTabs do
		local captured = name
		btn.MouseButton1Click:Connect(function()
			chatTab = captured
			renderChatTab()
		end)
	end

	chatBox.Focused:Connect(function()
		chatFocused = true
		chatFadeDirty = true
	end)
	chatBox.FocusLost:Connect(function(enterPressed)
		chatFocused = false
		chatFadeDirty = true
		if not enterPressed then
			return
		end
		local body = chatBox.Text
		chatBox.Text = ""
		submitChat(body, nearbyRows, partyRowsCache, deps.getTargetName())
	end)

	renderChatTab()

	return {
		pushChat = pushChat,
		submitChat = submitChat,
		focusChat = focusChat,
		setNearby = setNearby,
		setPartyRows = setPartyRows,
		tick = tick,
	}
end

return Chat
