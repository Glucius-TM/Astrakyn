--!strict
-- Death, loot, invite, toast, and error overlays.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IconWidgets = require(script:FindFirstAncestor("Client").UI.Inventory.ItemTip.IconWidgets)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local LootLogic = require(script:FindFirstAncestor("Client").UI.Inventory.Loot.LootLogic)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local TooltipLayer = require(script:FindFirstAncestor("Client").Runtime.Windows.TooltipLayer)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowRefresh = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowRefresh)

type LootOffer = UiTypes.LootOffer
type TooltipApi = TooltipLayer.TooltipApi

export type ModalsDeps = {
	onLootRoll: (offerId: string, choice: string) -> (),
	onInviteAccept: () -> (),
	onInviteDecline: () -> (),
	onRespawn: () -> (),
}

export type ChromeShared = {
	tooltip: TooltipApi,
	gate: WindowRefresh.RefreshGate,
}

export type ModalsApi = {
	setLoot: (offer: LootOffer) -> (),
	setInvite: (text: string, visible: boolean) -> (),
	setDeath: (visible: boolean) -> (),
	notifyToast: (message: string) -> (),
	notifyError: (message: string) -> (),
	tick: () -> (),
}

local TOAST_LINES = 4
local TOAST_LIFE = 5
local ERROR_LIFE = 3.5
local LOOT_CHOICES = { "Need", "Greed", "Pass" }

local Modals = {}

function Modals.lootSig(offer: LootOffer): string
	return table.concat({
		offer.offerId,
		offer.itemId,
		string.format("%.0f", offer.expires),
		if offer.canNeed then "1" else "0",
	}, "|")
end

function Modals.inviteSig(text: string, visible: boolean): string
	return `{text}|{if visible then "1" else "0"}`
end

function Modals.deathSig(visible: boolean): string
	return if visible then "1" else "0"
end

function Modals.mount(root: Frame, deps: ModalsDeps, shared: ChromeShared): ModalsApi
	local gate = shared.gate

	local errorText =
		Paint.text(root, "", UDim2.fromScale(0.3, 0.62), UDim2.fromScale(0.4, 0.04), Enum.TextXAlignment.Center)
	errorText.Name = "Error"
	errorText.TextSize = Paint.TextSizeSection
	errorText.TextColor3 = Paint.theme().Tokens.TextDanger
	errorText.TextStrokeTransparency = 0.3
	errorText.Font = Paint.FontBold

	local toast =
		Paint.text(root, "", UDim2.fromScale(0.32, 0.2), UDim2.fromScale(0.36, 0.1), Enum.TextXAlignment.Center)
	toast.Name = "Toast"
	toast.TextYAlignment = Enum.TextYAlignment.Top
	toast.TextWrapped = true
	toast.TextSize = Paint.TextSizeBody
	toast.TextColor3 = Paint.TextColorBody
	toast.TextStrokeTransparency = 0.35

	local death =
		Paint.panel(root, "Death", UDim2.fromScale(0.32, 0.36), UDim2.fromScale(0.36, 0.22), Color3.fromRGB(24, 8, 8))
	death.Visible = false
	death.ZIndex = 20

	local deathTitle = Paint.text(
		death,
		"You have died.",
		UDim2.fromScale(0.06, 0.08),
		UDim2.fromScale(0.88, 0.2),
		Enum.TextXAlignment.Center
	)
	deathTitle.Font = Paint.FontTitle
	deathTitle.TextSize = Paint.TextSizeTitle
	deathTitle.TextColor3 = Paint.TextColorAccent

	local deathHint = Paint.text(
		death,
		"Release returns you to your bind.",
		UDim2.fromScale(0.06, 0.3),
		UDim2.fromScale(0.88, 0.28),
		Enum.TextXAlignment.Center
	)
	deathHint.TextWrapped = true
	deathHint.TextSize = Paint.TextSizeBody
	deathHint.TextColor3 = Paint.TextColorBody

	local releaseBtn =
		Paint.primaryButton(death, "Release Spirit  (R)", UDim2.fromScale(0.2, 0.64), UDim2.fromScale(0.6, 0.26))

	local lootModal = Paint.panel(root, "Loot", UDim2.fromScale(0.35, 0.34), UDim2.fromScale(0.3, 0.28), Paint.Wood)
	lootModal.Visible = false
	lootModal.ZIndex = 22

	local lootTitle = Paint.text(
		lootModal,
		"Need / Greed",
		UDim2.fromScale(0.06, 0.06),
		UDim2.fromScale(0.88, 0.18),
		Enum.TextXAlignment.Center
	)
	lootTitle.Font = Paint.FontTitle
	lootTitle.TextSize = Paint.TextSizeTitle
	lootTitle.TextColor3 = Paint.TextColorAccent

	local lootItem =
		Paint.text(lootModal, "", UDim2.fromScale(0.06, 0.26), UDim2.fromScale(0.88, 0.22), Enum.TextXAlignment.Center)
	lootItem.TextWrapped = true
	lootItem.TextSize = Paint.TextSizeBody

	local lootTimer =
		Paint.text(lootModal, "", UDim2.fromScale(0.06, 0.46), UDim2.fromScale(0.88, 0.1), Enum.TextXAlignment.Center)
	lootTimer.TextSize = Paint.TextSizeCaption
	lootTimer.TextColor3 = Paint.TextColorSecondary

	local invite = Paint.panel(root, "Invite", UDim2.fromScale(0.35, 0.08), UDim2.fromScale(0.3, 0.12), Paint.Wood)
	invite.Visible = false
	invite.ZIndex = 21

	local inviteText =
		Paint.text(invite, "", UDim2.fromScale(0.04, 0.08), UDim2.fromScale(0.92, 0.4), Enum.TextXAlignment.Center)
	inviteText.TextWrapped = true
	inviteText.TextSize = Paint.TextSizeBody

	local inviteYes =
		Paint.primaryButton(invite, "Accept  (Y)", UDim2.fromScale(0.08, 0.55), UDim2.fromScale(0.4, 0.36))
	local inviteNo =
		Paint.primaryButton(invite, "Decline  (X)", UDim2.fromScale(0.52, 0.55), UDim2.fromScale(0.4, 0.36))

	local toastLines: { string } = {}
	local toastAt = 0
	local errorAt = 0
	local lootOffer: LootOffer = { offerId = "", itemId = "", expires = 0, canNeed = false }
	local lootChoiceButtons: { [string]: TextButton? } = {}

	local function notifyToast(message: string)
		if message == "" then
			return
		end
		table.insert(toastLines, 1, message)
		while #toastLines > TOAST_LINES do
			table.remove(toastLines)
		end
		toast.Text = table.concat(toastLines, "\n")
		toastAt = os.clock()
	end

	local function notifyError(message: string)
		errorText.Text = message
		errorAt = if message ~= "" then os.clock() else 0
	end

	local function paintLoot(offer: LootOffer)
		lootOffer = offer
		local visible = offer.offerId ~= ""
		lootModal.Visible = visible
		if not visible then
			lootTimer.Text = ""
			return
		end
		local needButton = lootChoiceButtons.Need
		if needButton ~= nil then
			needButton.Visible = offer.canNeed
		end
		local item = ItemCatalog.get(offer.itemId)
		lootItem.Text = if item then item.Name else offer.itemId
		lootItem.TextColor3 = if item then Paint.qualityColor(item.Quality) else Paint.TextColorBody
		if item then
			IconWidgets.setQualityStroke(lootModal, item.Quality)
		end
	end

	local function setLoot(offer: LootOffer)
		gate.gate("loot", Modals.lootSig(offer), function()
			paintLoot(offer)
		end)
	end

	local function setInvite(text: string, visible: boolean)
		gate.gate("invite", Modals.inviteSig(text, visible), function()
			invite.Visible = visible
			inviteText.Text = text
		end)
	end

	local function setDeath(visible: boolean)
		gate.gate("death", Modals.deathSig(visible), function()
			death.Visible = visible
		end)
	end

	local function tick()
		local now = os.clock()
		if toastAt > 0 and now - toastAt > TOAST_LIFE then
			table.clear(toastLines)
			toast.Text = ""
			toastAt = 0
		end
		if errorAt > 0 and now - errorAt > ERROR_LIFE then
			errorText.Text = ""
			errorAt = 0
		end
		if lootModal.Visible and lootOffer.expires > 0 then
			local remain = LootLogic.remain(lootOffer.expires, workspace:GetServerTimeNow())
			lootTimer.Text = `Expires in {Paint.formatDuration(remain)}s`
			lootTitle.TextColor3 = if remain < 5 then Color3.fromRGB(255, 140, 96) else Paint.TextColorAccent
			if remain <= 0 then
				lootModal.Visible = false
				lootOffer = { offerId = "", itemId = "", expires = 0, canNeed = false }
				lootTimer.Text = ""
				gate.clear("loot")
			end
		end
	end

	releaseBtn.MouseButton1Click:Connect(function()
		deps.onRespawn()
	end)

	for i, choice in LOOT_CHOICES do
		local btn = Paint.primaryButton(
			lootModal,
			choice,
			UDim2.fromScale(0.06 + (i - 1) * 0.31, 0.6),
			UDim2.fromScale(0.28, 0.26)
		)
		lootChoiceButtons[choice] = btn
		local picked = choice
		btn.MouseButton1Click:Connect(function()
			if lootOffer.offerId ~= "" then
				deps.onLootRoll(lootOffer.offerId, picked)
			end
		end)
	end

	inviteYes.MouseButton1Click:Connect(function()
		deps.onInviteAccept()
	end)
	inviteNo.MouseButton1Click:Connect(function()
		deps.onInviteDecline()
	end)

	return {
		setLoot = setLoot,
		setInvite = setInvite,
		setDeath = setDeath,
		notifyToast = notifyToast,
		notifyError = notifyError,
		tick = tick,
	}
end

return Modals
