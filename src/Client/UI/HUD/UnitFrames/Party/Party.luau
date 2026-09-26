--!strict
-- Party unit frames.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtraPools = require(script.Parent.Parent.Parent.ExtraPools.ExtraPools)
local FrameFactory = require(script.Parent.Parent.FrameFactory)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local IdentityPaint = require(script:FindFirstAncestor("Client").Domains.Session.IdentityPaint)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local Types = require(script.Parent.Parent.Types.Types)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local VitalsLogic = require(script.Parent.Parent.Parent.VitalsLogic)

type PartyRow = UiTypes.PartyRow
type UnitFrameParts = FrameFactory.UnitFrameParts
type ChromeShared = Types.ChromeShared
type UnitFramesDeps = Types.UnitFramesDeps

export type PartyApi = {
	setParty: (rows: { PartyRow }, localUserId: number) -> (),
	setExtraPoolHud: (visible: boolean) -> (),
}

local PARTY_ROWS = 4

local Party = {}

function Party.partySig(rows: { PartyRow }, localUserId: number): string
	local bits = { string.format("%.0f", localUserId) }
	for _, member in rows do
		table.insert(
			bits,
			`{string.format("%.0f", member.userId)}:{member.name}:{if member.leader then "1" else "0"}:{string.format(
				"%.0f",
				member.hp
			)}:{string.format("%.0f", member.maxHp)}:{string.format("%.0f", member.energy)}:{string.format(
				"%.0f",
				member.maxEnergy
			)}:{member.raceId}:{member.originId}:{member.archetypeId}:{member.specializationId}:{member.racialAbilityId}:{ExtraPools.sig(
				member.extraPools
			)}`
		)
	end
	return table.concat(bits, "|")
end

function Party.mount(root: Frame, deps: UnitFramesDeps, shared: ChromeShared): PartyApi
	local tooltip = shared.tooltip
	local gate = shared.gate

	local partyRoot = Instance.new("Frame")
	partyRoot.Name = "Party"
	partyRoot.BackgroundTransparency = 1
	partyRoot.BorderSizePixel = 0
	partyRoot.Position = UDim2.fromScale(0.015, 0.218)
	partyRoot.Size = UDim2.fromScale(0.2, 0.28)
	partyRoot.Active = false
	partyRoot.Parent = root

	local partyFrames: { UnitFrameParts } = {}
	local partyExtraMeters: { { Frame } } = {}
	for i = 1, PARTY_ROWS do
		local frame = FrameFactory.unitFrame(
			partyRoot,
			`Party{i}`,
			UDim2.fromScale(0, (i - 1) * 0.26),
			UDim2.fromScale(1, 0.24),
			false
		)
		frame.Root.Visible = false
		frame.Root.Active = true
		frame.Root:SetAttribute("HudBlock", true)
		frame.Root:SetAttribute("UserId", 0)
		local poolRow = Instance.new("Frame")
		poolRow.Name = "ExtraPools"
		poolRow.BackgroundTransparency = 1
		poolRow.BorderSizePixel = 0
		poolRow.Position = UDim2.fromScale(0.02, 0.88)
		poolRow.Size = UDim2.fromScale(0.96, 0.1)
		poolRow.Visible = false
		poolRow.Parent = frame.Root
		local meters: { Frame } = {}
		for j = 1, 7 do
			local meter = Paint.labeledMeter(
				poolRow,
				UDim2.fromScale((j - 1) * 0.14, 0),
				UDim2.fromScale(0.13, 1),
				Color3.fromRGB(120, 120, 120)
			)
			meter.Visible = false
			table.insert(meters, meter)
		end
		table.insert(partyExtraMeters, meters)
		table.insert(partyFrames, frame)
	end

	local lastPartyRows: { PartyRow } = {}
	local lastPartyUserId = 0
	local showExtraPools = true

	local function fireTarget(targetId: string)
		if targetId == "" then
			return
		end
		deps.remote("Combat", "TargetUnit"):FireServer({ targetId = targetId })
	end

	local function paintParty(rows: { PartyRow }, localUserId: number)
		local others: { PartyRow } = {}
		for _, member in rows do
			if member.userId ~= localUserId then
				table.insert(others, member)
			end
		end
		for i, frame in partyFrames do
			local member = others[i]
			if member == nil then
				frame.Root.Visible = false
				frame.Root:SetAttribute("UserId", 0)
				continue
			end
			frame.Root.Visible = true
			frame.Root:SetAttribute("UserId", member.userId)
			frame.Name.Text = member.name
			frame.Level.Text = if member.leader then "Lead" else ""
			local maxHp = math.max(1, member.maxHp)
			Paint.setFill(frame.Health, member.hp / maxHp)
			Paint.setFill(frame.Power, VitalsLogic.partyPowerRatio(member.energy, member.maxEnergy))
			frame.HealthText.Text = `{string.format("%.0f", member.hp)} / {string.format("%.0f", maxHp)}`
			frame.PowerText.Text = string.format("%.0f", member.energy)
			frame.PortraitText.Text = string.sub(member.name, 1, 1)
			local identity =
				IdentityPaint.identityLine(member.raceId, member.originId, member.archetypeId, member.specializationId)
			frame.Class.Text = if identity ~= "" then identity elseif member.leader then "Leader" else "Party"
			frame.Class.TextTruncate = Enum.TextTruncate.AtEnd
			frame.Pvp.Text = ""
			local poolMeters = partyExtraMeters[i]
			if poolMeters ~= nil then
				local poolRow = poolMeters[1] and poolMeters[1].Parent
				if poolRow and poolRow:IsA("Frame") then
					poolRow.Visible = showExtraPools and #member.extraPools > 0
				end
				ExtraPools.paintMeters(poolMeters, member.extraPools, showExtraPools)
			end
		end
	end

	local function setParty(rows: { PartyRow }, localUserId: number)
		lastPartyRows = rows
		lastPartyUserId = localUserId
		gate.gate("party", Party.partySig(rows, localUserId), function()
			paintParty(rows, localUserId)
		end)
	end

	local function setExtraPoolHud(visible: boolean)
		showExtraPools = visible
		if #lastPartyRows > 0 then
			paintParty(lastPartyRows, lastPartyUserId)
		end
	end

	for _, frame in partyFrames do
		frame.Root.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
			local userId = frame.Root:GetAttribute("UserId")
			if typeof(userId) == "number" and userId > 0 then
				fireTarget(Id.player(userId))
			end
		end)
		frame.Root.MouseEnter:Connect(function()
			if frame.Root.Visible then
				tooltip.show(`{frame.Name.Text}\n{frame.Class.Text}  ·  click to target`)
			end
		end)
		frame.Root.MouseLeave:Connect(function()
			tooltip.hide()
		end)
	end

	return {
		setParty = setParty,
		setExtraPoolHud = setExtraPoolHud,
	}
end

return Party
