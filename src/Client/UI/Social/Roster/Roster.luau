--!strict
-- Social window (party / guild / nearby / friends).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuildResearchCatalog = require(ReplicatedStorage.Definitions.Social.GuildResearchCatalog)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local StatWidgets = require(script:FindFirstAncestor("Client").UI.HUD.StatSheet.StatWidgets)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowHost = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowHost)

type JsonObject = JsonTypes.JsonObject
type WindowCtx = UiTypes.WindowCtx

local Roster = {}

function Roster.sig(ctx: WindowCtx, socialTab: string): string
	local bits = {
		socialTab,
		ctx.guildName,
		ctx.guildRank,
		string.format("%.0f", ctx.guildBank),
		ctx.guildMotd,
		ctx.pendingGuild,
		ctx.lootMethod,
		string.format("%.0f", #ctx.guildMembers),
		string.format("%.0f", #ctx.guildStructureRows),
		string.format("%.0f", #ctx.guildResearch),
		string.format("%.0f", #ctx.blocked),
		string.format("%.0f", ctx.settlementScore),
		string.format("%.0f", ctx.pendingParty),
		string.format("%.0f", ctx.pendingTradeFrom),
		string.format("%.0f", ctx.pendingDuel),
	}
	for _, member in ctx.party do
		table.insert(
			bits,
			`{member.userId}:{member.name}:{if member.leader then "1" else "0"}:{string.format("%.0f", member.hp)}:{string.format(
				"%.0f",
				member.maxHp
			)}`
		)
	end
	for _, near in ctx.nearby do
		table.insert(bits, `{near.userId}:{near.name}`)
	end
	for _, friendId in ctx.friends do
		table.insert(bits, tostring(friendId))
	end
	return table.concat(bits, "|")
end

function Roster.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	local deps = host.getDeps()
	local gate = host.getGate()
	local lastCtx: WindowCtx? = nil
	local socialTab = "Party"

	local function fire(folder: string, name: string, payload: JsonObject)
		host.fire(folder, name, payload)
	end

	local function tipOn(guiObject: GuiObject, text: string, titleColor: Color3?)
		host.tipOn(guiObject, text, titleColor)
	end

	-- Social
	local social = host.make("Social", UDim2.fromScale(0.2, 0.12), UDim2.fromScale(0.56, 0.66), "Social")
	local socialTabs: { [string]: TextButton } = {}
	for i, name in { "Party", "Guild", "Nearby", "Friends" } do
		local btn = Paint.tabButton(
			social.Body,
			name,
			UDim2.fromScale(0.02 + (i - 1) * 0.24, 0.02),
			UDim2.fromScale(0.23, 0.07)
		)
		local captured = name
		btn.MouseButton1Click:Connect(function()
			socialTab = captured
			host.requestRefresh()
		end)
		socialTabs[name] = btn
	end
	local socialPane = Paint.parchment(social.Body, "Pane", UDim2.fromScale(0.02, 0.12), UDim2.fromScale(0.96, 0.84))
	local socialBody = Paint.scroll(socialPane, "List", UDim2.fromScale(0.01, 0.02), UDim2.fromScale(0.98, 0.96))

	local function refreshNow(ctx: WindowCtx)
		lastCtx = ctx
		if host.isOpen("Social") then
			gate.gate("Social", Roster.sig(ctx, socialTab), function()
				for name, btn in socialTabs do
					Paint.setTabActive(btn, name == socialTab)
				end
				Paint.clearFrame(socialBody)
				if socialTab == "Party" then
					local y = 8
					local ready = Paint.primaryButton(
						socialBody,
						`Ready Check   ·   loot {ctx.lootMethod}`,
						UDim2.fromOffset(12, y),
						UDim2.new(1, -24, 0, 36)
					)
					ready.MouseButton1Click:Connect(function()
						if host.shift() then
							fire("Social", "SetLootMethod", {
								method = if ctx.lootMethod == "Personal" then "NeedGreed" else "Personal",
							})
						else
							fire("Social", "ReadyCheck", {})
						end
					end)
					y += 44
					local respond = Paint.primaryButton(
						socialBody,
						"Ready  /  Shift not ready",
						UDim2.fromOffset(12, y),
						UDim2.new(1, -24, 0, 32)
					)
					respond.MouseButton1Click:Connect(function()
						fire("Social", "ReadyRespond", { ready = not host.shift() })
					end)
					y += 40
					local leave = Paint.primaryButton(
						socialBody,
						"Leave Party",
						UDim2.fromOffset(12, y),
						UDim2.new(1, -24, 0, 32)
					)
					leave.MouseButton1Click:Connect(function()
						fire("Social", "PartyLeave", {})
					end)
					y += 44
					if ctx.pendingParty > 0 then
						local leaderId = ctx.pendingParty
						local acc = Paint.primaryButton(
							socialBody,
							"Accept invite  (Y)",
							UDim2.fromOffset(12, y),
							UDim2.new(0.46, 0, 0, 32)
						)
						acc.MouseButton1Click:Connect(function()
							fire("Social", "PartyAccept", { userId = leaderId })
						end)
						local dec = Paint.primaryButton(
							socialBody,
							"Decline  (X)",
							UDim2.fromOffset(12 + 200, y),
							UDim2.new(0.4, 0, 0, 32)
						)
						dec.MouseButton1Click:Connect(function()
							fire("Social", "PartyDecline", {})
						end)
						y += 40
					end
					for _, member in ctx.party do
						local card =
							Paint.parchment(socialBody, member.name, UDim2.fromOffset(12, y), UDim2.new(1, -24, 0, 64))
						Paint.text(
							card,
							`{member.name}{if member.leader then "   ·   Leader" else ""}`,
							UDim2.fromScale(0.04, 0.08),
							UDim2.fromScale(0.5, 0.36),
							Enum.TextXAlignment.Left
						).TextColor3 =
							Paint.Gold
						local hp = Paint.labeledMeter(
							card,
							UDim2.fromScale(0.04, 0.5),
							UDim2.fromScale(0.48, 0.36),
							Paint.Health
						)
						Paint.setFill(hp, member.hp / math.max(1, member.maxHp))
						Paint.setMeterText(
							hp,
							`{string.format("%.0f", member.hp)} / {string.format("%.0f", member.maxHp)}`
						)
						local memberId = member.userId
						local kick =
							Paint.primaryButton(card, "Kick", UDim2.fromScale(0.56, 0.22), UDim2.fromScale(0.2, 0.56))
						kick.MouseButton1Click:Connect(function()
							fire("Social", "PartyKick", { userId = memberId })
						end)
						local promo =
							Paint.primaryButton(card, "Lead", UDim2.fromScale(0.78, 0.22), UDim2.fromScale(0.18, 0.56))
						promo.MouseButton1Click:Connect(function()
							fire("Social", "PartyPromote", { userId = memberId })
						end)
						y += 72
					end
					if ctx.pendingTradeFrom > 0 then
						local fromId = ctx.pendingTradeFrom
						local acc = Paint.primaryButton(
							socialBody,
							"Accept trade",
							UDim2.fromOffset(12, y),
							UDim2.new(1, -24, 0, 32)
						)
						acc.MouseButton1Click:Connect(function()
							fire("Social", "TradeAccept", { userId = fromId })
						end)
					end
					if ctx.pendingDuel > 0 then
						local fromId = ctx.pendingDuel
						local acc = Paint.primaryButton(
							socialBody,
							"Accept duel",
							UDim2.fromOffset(12, y + 36),
							UDim2.new(1, -24, 0, 32)
						)
						acc.MouseButton1Click:Connect(function()
							fire("PvP", "DuelAccept", { userId = fromId })
						end)
					end
				elseif socialTab == "Guild" then
					local banner = Paint.text(
						socialBody,
						if ctx.guildName ~= "" then ctx.guildName else "No guild",
						UDim2.fromScale(0.04, 0.04),
						UDim2.fromScale(0.92, 0.1),
						Enum.TextXAlignment.Left
					)
					banner.Font = Paint.FontTitle
					banner.TextSize = Paint.TextSizeTitle
					banner.TextColor3 = Paint.Gold
					Paint.text(
						socialBody,
						`{ctx.guildRank}    bank {string.format("%.0f", ctx.guildBank)} Astral`,
						UDim2.fromScale(0.04, 0.14),
						UDim2.fromScale(0.92, 0.06),
						Enum.TextXAlignment.Left
					)
					local motd = Paint.text(
						socialBody,
						`MOTD  {if ctx.guildMotd ~= "" then ctx.guildMotd else "—"}`,
						UDim2.fromScale(0.04, 0.2),
						UDim2.fromScale(0.92, 0.1),
						Enum.TextXAlignment.Left
					)
					motd.TextWrapped = true
					local dep = Paint.primaryButton(
						socialBody,
						"Deposit 10",
						UDim2.fromScale(0.04, 0.32),
						UDim2.fromScale(0.3, 0.08)
					)
					dep.MouseButton1Click:Connect(function()
						fire("Social", "GuildDeposit", { amount = 10 })
					end)
					local wd = Paint.primaryButton(
						socialBody,
						"Withdraw 10",
						UDim2.fromScale(0.36, 0.32),
						UDim2.fromScale(0.3, 0.08)
					)
					wd.MouseButton1Click:Connect(function()
						fire("Social", "GuildWithdraw", { amount = 10 })
					end)
					local motdBtn = Paint.primaryButton(
						socialBody,
						"Set MOTD",
						UDim2.fromScale(0.68, 0.32),
						UDim2.fromScale(0.28, 0.08)
					)
					motdBtn.MouseButton1Click:Connect(function()
						fire("Social", "GuildMotd", { text = "Hold the Gate." })
					end)
					local leaveG = Paint.primaryButton(
						socialBody,
						"Leave Guild",
						UDim2.fromScale(0.04, 0.42),
						UDim2.fromScale(0.44, 0.08)
					)
					leaveG.MouseButton1Click:Connect(function()
						fire("Social", "GuildLeave", {})
					end)
					local placeBanner = Paint.primaryButton(
						socialBody,
						"Place Banner",
						UDim2.fromScale(0.52, 0.42),
						UDim2.fromScale(0.44, 0.08)
					)
					placeBanner.MouseButton1Click:Connect(function()
						fire("Social", "GuildPlaceStructure", { templateId = "GuildBanner", cx = 0, cy = 0, cz = 0 })
					end)
					if ctx.pendingGuild ~= "" then
						local acc = Paint.primaryButton(
							socialBody,
							"Accept guild invite",
							UDim2.fromScale(0.04, 0.52),
							UDim2.fromScale(0.92, 0.08)
						)
						acc.MouseButton1Click:Connect(function()
							fire("Social", "GuildAccept", {})
						end)
					elseif ctx.guildName == "" then
						local createG = Paint.primaryButton(
							socialBody,
							"Create Guild",
							UDim2.fromScale(0.04, 0.52),
							UDim2.fromScale(0.92, 0.08)
						)
						createG.MouseButton1Click:Connect(function()
							fire("Social", "CreateGuild", { name = `{deps.player.DisplayName} Kyn` })
						end)
					else
						local guildScroll = Paint.scroll(
							socialBody,
							"GuildDetails",
							UDim2.fromScale(0.04, 0.52),
							UDim2.fromScale(0.92, 0.44)
						)
						local gy = 4
						StatWidgets.sectionHeader(
							guildScroll,
							"Members",
							UDim2.fromOffset(4, gy),
							UDim2.new(1, -8, 0, 20)
						)
						gy += 24
						for _, member in ctx.guildMembers do
							local row = Paint.parchment(
								guildScroll,
								member.name,
								UDim2.fromOffset(4, gy),
								UDim2.new(1, -8, 0, 40)
							)
							local label = if member.isLeader then `★ {member.name}` else member.name
							Paint.text(
								row,
								label,
								UDim2.fromScale(0.04, 0.2),
								UDim2.fromScale(0.56, 0.6),
								Enum.TextXAlignment.Left
							)
							if ctx.guildRank == "Leader" and not member.isLeader then
								local kickBtn = Paint.primaryButton(
									row,
									"Kick",
									UDim2.fromScale(0.64, 0.15),
									UDim2.fromScale(0.3, 0.7)
								)
								local userId = member.userId
								kickBtn.MouseButton1Click:Connect(function()
									fire("Social", "GuildKick", { userId = userId })
								end)
							end
							gy += 44
						end
						StatWidgets.sectionHeader(
							guildScroll,
							"Structures",
							UDim2.fromOffset(4, gy),
							UDim2.new(1, -8, 0, 20)
						)
						gy += 24
						for _, structure in ctx.guildStructureRows do
							local row = Paint.parchment(
								guildScroll,
								structure.templateId,
								UDim2.fromOffset(4, gy),
								UDim2.new(1, -8, 0, 40)
							)
							Paint.text(
								row,
								`{structure.templateId}  ({string.format("%.0f", structure.cx)}, {string.format(
									"%.0f",
									structure.cy
								)}, {string.format("%.0f", structure.cz)})`,
								UDim2.fromScale(0.04, 0.2),
								UDim2.fromScale(0.56, 0.6),
								Enum.TextXAlignment.Left
							)
							if ctx.guildRank == "Leader" then
								local removeBtn = Paint.primaryButton(
									row,
									"Remove",
									UDim2.fromScale(0.64, 0.15),
									UDim2.fromScale(0.3, 0.7)
								)
								local structureId = structure.id
								removeBtn.MouseButton1Click:Connect(function()
									fire("Social", "GuildRemoveStructure", { structureId = structureId })
								end)
							end
							gy += 44
						end
						StatWidgets.sectionHeader(
							guildScroll,
							"Research",
							UDim2.fromOffset(4, gy),
							UDim2.new(1, -8, 0, 20)
						)
						gy += 24
						local researched: { [string]: boolean } = {}
						for _, id in ctx.guildResearch do
							researched[id] = true
						end
						for _, node in GuildResearchCatalog.all() do
							local row =
								Paint.parchment(guildScroll, node.Id, UDim2.fromOffset(4, gy), UDim2.new(1, -8, 0, 40))
							local owned = researched[node.Id] == true
							Paint.text(
								row,
								if owned then `✓ {node.DisplayName}` else node.DisplayName,
								UDim2.fromScale(0.04, 0.2),
								UDim2.fromScale(0.56, 0.6),
								Enum.TextXAlignment.Left
							)
							if ctx.guildRank == "Leader" and not owned then
								local researchBtn = Paint.primaryButton(
									row,
									"Unlock",
									UDim2.fromScale(0.64, 0.15),
									UDim2.fromScale(0.3, 0.7)
								)
								local researchId = node.Id
								researchBtn.MouseButton1Click:Connect(function()
									fire("Social", "GuildResearch", { researchId = researchId })
								end)
							end
							gy += 44
						end
					end
				elseif socialTab == "Nearby" then
					local y = 8
					if #ctx.nearby == 0 then
						Paint.text(
							socialBody,
							"No one nearby.",
							UDim2.fromOffset(16, 16),
							UDim2.new(1, -32, 0, 28),
							Enum.TextXAlignment.Left
						)
					end
					for _, near in ctx.nearby do
						local card =
							Paint.parchment(socialBody, near.name, UDim2.fromOffset(12, y), UDim2.new(1, -24, 0, 72))
						Paint.text(
							card,
							near.name,
							UDim2.fromScale(0.04, 0.08),
							UDim2.fromScale(0.5, 0.36),
							Enum.TextXAlignment.Left
						).TextColor3 =
							Paint.Gold
						local userId = near.userId
						local inv =
							Paint.primaryButton(card, "Invite", UDim2.fromScale(0.04, 0.5), UDim2.fromScale(0.18, 0.4))
						inv.MouseButton1Click:Connect(function()
							fire("Social", "PartyInvite", { userId = userId })
						end)
						local g =
							Paint.primaryButton(card, "Guild", UDim2.fromScale(0.24, 0.5), UDim2.fromScale(0.18, 0.4))
						g.MouseButton1Click:Connect(function()
							fire("Social", "GuildInvite", { userId = userId })
						end)
						local w =
							Paint.primaryButton(card, "Whisper", UDim2.fromScale(0.44, 0.5), UDim2.fromScale(0.18, 0.4))
						w.MouseButton1Click:Connect(function()
							fire("Social", "WhisperChannelRequest", { userId = userId })
						end)
						local ins =
							Paint.primaryButton(card, "Inspect", UDim2.fromScale(0.64, 0.5), UDim2.fromScale(0.16, 0.4))
						ins.MouseButton1Click:Connect(function()
							fire("Social", "InspectPlayer", { userId = userId })
						end)
						local du =
							Paint.primaryButton(card, "Duel", UDim2.fromScale(0.82, 0.5), UDim2.fromScale(0.14, 0.4))
						du.MouseButton1Click:Connect(function()
							fire("PvP", "DuelChallenge", { userId = userId })
						end)
						local tr =
							Paint.primaryButton(card, "Trade", UDim2.fromScale(0.56, 0.08), UDim2.fromScale(0.14, 0.32))
						tr.MouseButton1Click:Connect(function()
							local inst = if lastCtx and lastCtx.inventory[1]
								then lastCtx.inventory[1].instanceId
								else ""
							fire("Social", "TradeRequest", { userId = userId, instanceId = inst, astral = 0 })
						end)
						local blk =
							Paint.primaryButton(card, "Blk", UDim2.fromScale(0.72, 0.08), UDim2.fromScale(0.12, 0.32))
						blk.MouseButton1Click:Connect(function()
							fire("Social", "BlockPlayer", { userId = userId })
						end)
						tipOn(blk, "Block player")
						local fr =
							Paint.primaryButton(card, "+", UDim2.fromScale(0.88, 0.08), UDim2.fromScale(0.08, 0.32))
						fr.MouseButton1Click:Connect(function()
							fire("Social", "FriendAdd", { userId = userId })
						end)
						tipOn(fr, "Add friend")
						y += 80
					end
				else
					local names: { [number]: string } = {}
					for _, near in ctx.nearby do
						names[near.userId] = near.name
					end
					for _, member in ctx.party do
						names[member.userId] = member.name
					end
					Paint.text(
						socialBody,
						`Friends on file  {#ctx.friends}`,
						UDim2.fromScale(0.04, 0.03),
						UDim2.fromScale(0.92, 0.08),
						Enum.TextXAlignment.Left
					).TextColor3 =
						Paint.Gold
					local y = 48
					if #ctx.friends == 0 then
						Paint.text(
							socialBody,
							"Add friends from Nearby (+).",
							UDim2.fromOffset(16, y),
							UDim2.new(1, -32, 0, 28),
							Enum.TextXAlignment.Left
						)
					end
					for _, id in ctx.friends do
						local friendId = id
						local shown = names[friendId] or `Friend  {friendId}`
						local card = Paint.parchment(
							socialBody,
							tostring(friendId),
							UDim2.fromOffset(12, y),
							UDim2.new(1, -24, 0, 48)
						)
						Paint.text(
							card,
							shown,
							UDim2.fromScale(0.04, 0.15),
							UDim2.fromScale(0.56, 0.7),
							Enum.TextXAlignment.Left
						).TextColor3 =
							Paint.Gold
						local drop = Paint.primaryButton(
							card,
							"Remove",
							UDim2.fromScale(0.64, 0.18),
							UDim2.fromScale(0.32, 0.64)
						)
						drop.MouseButton1Click:Connect(function()
							fire("Social", "FriendRemove", { userId = friendId })
						end)
						y += 56
					end
					if #ctx.blocked > 0 then
						Paint.text(
							socialBody,
							"Blocked",
							UDim2.fromOffset(16, y + 8),
							UDim2.new(1, -32, 0, 24),
							Enum.TextXAlignment.Left
						).TextColor3 =
							Paint.Muted
						y += 36
						for _, blocked in ctx.blocked do
							local blockedId = blocked.userId
							local card = Paint.parchment(
								socialBody,
								blocked.name,
								UDim2.fromOffset(12, y),
								UDim2.new(1, -24, 0, 48)
							)
							Paint.text(
								card,
								blocked.name,
								UDim2.fromScale(0.04, 0.15),
								UDim2.fromScale(0.56, 0.7),
								Enum.TextXAlignment.Left
							).TextColor3 =
								Paint.Muted
							local unblock = Paint.primaryButton(
								card,
								"Unblock",
								UDim2.fromScale(0.64, 0.18),
								UDim2.fromScale(0.32, 0.64)
							)
							unblock.MouseButton1Click:Connect(function()
								fire("Social", "UnblockPlayer", { userId = blockedId })
							end)
							y += 56
						end
					end
				end
			end)
		end
	end

	local handle: WindowHost.PanelHandle = {
		ids = { "Social" },
		refresh = refreshNow,
	}
	host.register(handle)
	return handle
end

return Roster
