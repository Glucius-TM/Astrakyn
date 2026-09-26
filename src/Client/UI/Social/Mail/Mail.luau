--!strict
-- Mail window.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local SystemHints = require(script:FindFirstAncestor("Client").UI.System.SystemHints)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowHost = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowHost)

type JsonObject = JsonTypes.JsonObject
type WindowCtx = UiTypes.WindowCtx

type MailAttachOpt = { instanceId: string, templateId: string, name: string }

local function mailAttachOpt(instanceId: string, templateId: string, name: string): MailAttachOpt
	return { instanceId = instanceId, templateId = templateId, name = name }
end

local Mail = {}

function Mail.sig(ctx: WindowCtx, selectedMail: string): string
	local bits = { selectedMail }
	for _, row in ctx.mail do
		table.insert(
			bits,
			`{row.id}:{row.from}:{row.body}:{string.format("%.0f", row.astral)}:{if row.read then "1" else "0"}:{row.itemTemplateId}`
		)
	end
	for _, near in ctx.nearby do
		table.insert(bits, `{near.userId}:{near.name}`)
	end
	for _, row in ctx.inventory do
		table.insert(bits, `{row.instanceId}:{row.templateId}`)
	end
	for _, row in ctx.gear do
		table.insert(bits, row.instanceId)
	end
	return table.concat(bits, "|")
end

function Mail.sendMailPayload(userId: number, body: string, astral: number, itemInstanceId: string): JsonObject
	return {
		userId = userId,
		body = body,
		astral = astral,
		itemInstanceId = itemInstanceId,
	}
end

function Mail.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	local gate = host.getGate()
	local lastCtx: WindowCtx? = nil
	local selectedMail = ""
	local mailTo = 0
	local mailAttach = ""

	local function fire(folder: string, name: string, payload: JsonObject)
		host.fire(folder, name, payload)
	end

	-- Mail
	local mail = host.make("Mail", UDim2.fromScale(0.2, 0.14), UDim2.fromScale(0.58, 0.62), "Mailbox")
	local mailLeft = Paint.scroll(mail.Body, "Inbox", UDim2.fromScale(0.02, 0.04), UDim2.fromScale(0.36, 0.92))
	local mailRight = Paint.parchment(mail.Body, "Letter", UDim2.fromScale(0.4, 0.04), UDim2.fromScale(0.58, 0.92))
	local mailFrom =
		Paint.text(mailRight, "", UDim2.fromScale(0.06, 0.02), UDim2.fromScale(0.88, 0.08), Enum.TextXAlignment.Left)
	mailFrom.Font = Paint.FontTitle
	mailFrom.TextColor3 = Paint.Gold
	local mailLetter = Paint.text(
		mailRight,
		"No letter selected.",
		UDim2.fromScale(0.06, 0.11),
		UDim2.fromScale(0.88, 0.2),
		Enum.TextXAlignment.Left
	)
	mailLetter.TextYAlignment = Enum.TextYAlignment.Top
	mailLetter.TextWrapped = true
	local takeMail = Paint.primaryButton(mailRight, "Take", UDim2.fromScale(0.08, 0.32), UDim2.fromScale(0.4, 0.08))
	local deleteMail = Paint.primaryButton(mailRight, "Delete", UDim2.fromScale(0.52, 0.32), UDim2.fromScale(0.4, 0.08))
	local mailCompose = Paint.text(
		mailRight,
		"Compose",
		UDim2.fromScale(0.06, 0.41),
		UDim2.fromScale(0.88, 0.05),
		Enum.TextXAlignment.Left
	)
	mailCompose.TextColor3 = Paint.Gold
	local mailToList = Paint.scroll(mailRight, "To", UDim2.fromScale(0.06, 0.46), UDim2.fromScale(0.88, 0.08))
	mailToList.AutomaticCanvasSize = Enum.AutomaticSize.X
	mailToList.ScrollingDirection = Enum.ScrollingDirection.X
	local mailAttachList = Paint.scroll(mailRight, "Attach", UDim2.fromScale(0.06, 0.55), UDim2.fromScale(0.88, 0.08))
	mailAttachList.AutomaticCanvasSize = Enum.AutomaticSize.X
	mailAttachList.ScrollingDirection = Enum.ScrollingDirection.X
	local mailSendBox = Instance.new("TextBox")
	mailSendBox.Size = UDim2.fromScale(0.88, 0.14)
	mailSendBox.Position = UDim2.fromScale(0.06, 0.64)
	mailSendBox.BackgroundColor3 = Paint.WoodInner
	mailSendBox.TextColor3 = Paint.TextColorBody
	mailSendBox.Font = Paint.FontBody
	mailSendBox.TextSize = Paint.TextSizeBody
	mailSendBox.PlaceholderColor3 = Paint.TextColorSecondary
	mailSendBox.Text = ""
	mailSendBox.PlaceholderText = "Field note  ·  pick a recipient above"
	mailSendBox.TextXAlignment = Enum.TextXAlignment.Left
	mailSendBox.TextYAlignment = Enum.TextYAlignment.Top
	mailSendBox.TextWrapped = true
	mailSendBox.ClearTextOnFocus = false
	mailSendBox.MultiLine = true
	mailSendBox.Parent = mailRight
	Paint.corner(mailSendBox, 2)
	Paint.trim(mailSendBox, Paint.Bronze, 1)
	local sendMailBtn =
		Paint.primaryButton(mailRight, "Send  5 A", UDim2.fromScale(0.2, 0.8), UDim2.fromScale(0.6, 0.16))
	sendMailBtn.MouseButton1Click:Connect(function()
		if lastCtx == nil then
			return
		end
		local userId = mailTo
		if userId <= 0 and lastCtx.nearby[1] then
			userId = lastCtx.nearby[1].userId
		end
		if userId <= 0 then
			return
		end
		local body = mailSendBox.Text
		if body == "" then
			body = "Field note from the Threshold"
		end
		fire("Social", "SendMail", Mail.sendMailPayload(userId, body, 5, mailAttach))
		mailSendBox.Text = ""
		mailAttach = ""
	end)
	takeMail.MouseButton1Click:Connect(function()
		if selectedMail ~= "" then
			fire("Social", "TakeMail", { mailId = selectedMail })
		end
	end)
	deleteMail.MouseButton1Click:Connect(function()
		if selectedMail ~= "" then
			fire("Social", "DeleteMail", { mailId = selectedMail })
		end
	end)

	local function refreshNow(ctx: WindowCtx)
		lastCtx = ctx
		if host.isOpen("Mail") then
			if selectedMail == "" and ctx.mail[1] then
				selectedMail = ctx.mail[1].id
			end
			if mailTo <= 0 and ctx.nearby[1] then
				mailTo = ctx.nearby[1].userId
			end
			gate.gate("Mail", `{Mail.sig(ctx, selectedMail)}|{mailTo}|{mailAttach}`, function()
				Paint.clearFrame(mailLeft)
				Paint.clearFrame(mailToList)
				Paint.clearFrame(mailAttachList)
				if #ctx.mail == 0 then
					SystemHints.emptyHint(mailLeft, "Inbox empty.")
				end
				local y = 4
				for _, row in ctx.mail do
					local btn = Paint.primaryButton(
						mailLeft,
						Paint.shortName(row.body, 22),
						UDim2.fromOffset(4, y),
						UDim2.new(1, -8, 0, 36)
					)
					btn.TextXAlignment = Enum.TextXAlignment.Left
					btn.Text = `{if row.read then "  " else "  ●  "}{Paint.shortName(row.body, 20)}`
					if row.id == selectedMail then
						Paint.gradient(btn, Color3.fromRGB(118, 84, 28), Color3.fromRGB(56, 38, 12), 90)
					end
					local mailId = row.id
					btn.MouseButton1Click:Connect(function()
						selectedMail = mailId
						host.requestRefresh()
					end)
					y += 42
				end
				local picked: UiTypes.MailRow? = nil
				for _, row in ctx.mail do
					if row.id == selectedMail then
						picked = row
						break
					end
				end
				if picked then
					mailFrom.Text = `From  {picked.from}`
					local attach = ItemCatalog.get(picked.itemTemplateId)
					mailLetter.Text =
						`{picked.body}\n\nAttached  {string.format("%.0f", picked.astral)} Astral{if attach
							then `\nItem  {attach.Name}`
							else if picked.itemTemplateId ~= "" then `\nItem  {picked.itemTemplateId}` else ""}`
				else
					mailFrom.Text = "Mailbox"
					mailLetter.Text = "Empty. Pick a nearby player below and send a field note."
				end
				if #ctx.nearby == 0 then
					SystemHints.emptyHint(mailToList, "No one nearby to write.")
				end
				for i, near in ctx.nearby do
					local btn = Paint.primaryButton(
						mailToList,
						near.name,
						UDim2.fromOffset((i - 1) * 118, 2),
						UDim2.fromOffset(110, 28)
					)
					if near.userId == mailTo then
						Paint.gradient(btn, Color3.fromRGB(118, 84, 28), Color3.fromRGB(56, 38, 12), 90)
					end
					local userId = near.userId
					btn.MouseButton1Click:Connect(function()
						mailTo = userId
						host.requestRefresh()
					end)
				end
				local equipped: { [string]: boolean } = {}
				for _, row in ctx.gear do
					if row.instanceId ~= "" then
						equipped[row.instanceId] = true
					end
				end
				local seen: { [string]: boolean } = {}
				local attachOpts: { MailAttachOpt } = {}
				for _, row in ctx.inventory do
					if row.instanceId ~= "" and not equipped[row.instanceId] and not seen[row.instanceId] then
						seen[row.instanceId] = true
						table.insert(attachOpts, mailAttachOpt(row.instanceId, row.templateId, row.name))
					end
				end
				if mailAttach ~= "" and seen[mailAttach] ~= true then
					mailAttach = ""
				end
				local noneBtn =
					Paint.primaryButton(mailAttachList, "None", UDim2.fromOffset(2, 2), UDim2.fromOffset(56, 28))
				if mailAttach == "" then
					Paint.gradient(noneBtn, Color3.fromRGB(118, 84, 28), Color3.fromRGB(56, 38, 12), 90)
				end
				noneBtn.MouseButton1Click:Connect(function()
					mailAttach = ""
					host.requestRefresh()
				end)
				for i, opt in attachOpts do
					local btn = Paint.primaryButton(
						mailAttachList,
						Paint.shortName(opt.name, 10),
						UDim2.fromOffset(62 + (i - 1) * 96, 2),
						UDim2.fromOffset(90, 28)
					)
					if opt.instanceId == mailAttach then
						Paint.gradient(btn, Color3.fromRGB(118, 84, 28), Color3.fromRGB(56, 38, 12), 90)
					end
					local instanceId = opt.instanceId
					btn.MouseButton1Click:Connect(function()
						mailAttach = if mailAttach == instanceId then "" else instanceId
						host.requestRefresh()
					end)
				end
				local toName = ""
				for _, near in ctx.nearby do
					if near.userId == mailTo then
						toName = near.name
						break
					end
				end
				local attachName = "none"
				if mailAttach ~= "" then
					for _, opt in attachOpts do
						if opt.instanceId == mailAttach then
							attachName = opt.name
							break
						end
					end
				end
				mailCompose.Text = if toName ~= ""
					then `To  {toName}  ·  attach  {attachName}`
					else `Compose  ·  attach  {attachName}`
			end)
		end
	end

	local handle: WindowHost.PanelHandle = {
		ids = { "Mail" },
		refresh = refreshNow,
	}
	host.register(handle)
	return handle
end

return Mail
