--!strict
-- Macros panel.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local MacroCatalog = require(ReplicatedStorage.Definitions.Combat.Macros.MacroCatalog)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowHost = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowHost)

type JsonObject = JsonTypes.JsonObject
type WindowCtx = UiTypes.WindowCtx

local Macros = {}

function Macros.macroRosterIds(ctx: WindowCtx): { string }
	if #ctx.macros > 0 then
		local owned: { string } = {}
		for _, id in ctx.macros do
			table.insert(owned, id)
		end
		return owned
	end
	local ids: { string } = {}
	for id in MacroCatalog.all() do
		table.insert(ids, id)
	end
	table.sort(ids)
	return ids
end

function Macros.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	local deps = host.getDeps()
	local gate = host.getGate()
	local selectedMacro = ""
	local shownMacro = ""

	local function fire(folder: string, name: string, payload: JsonObject)
		host.fire(folder, name, payload)
	end

	local function firstEmptySlot(): number
		local binds = deps.getBinds()
		for i = 1, GameConstants.ACTION_BAR_SLOTS do
			local bind = binds[i]
			if bind == nil or bind.id == "" then
				return i
			end
		end
		return 1
	end

	local function bindKind(kind: string, id: string)
		deps.bindBar(firstEmptySlot(), kind, id)
	end

	-- Macros: separate window (K / micro menu only)
	local macros = host.make("Macros", UDim2.fromScale(0.16, 0.14), UDim2.fromScale(0.68, 0.64), "Macros")
	local macroRoster = Paint.scroll(macros.Body, "Roster", UDim2.fromScale(0.02, 0.04), UDim2.fromScale(0.34, 0.92))
	local macroEditor = Paint.parchment(macros.Body, "Editor", UDim2.fromScale(0.38, 0.04), UDim2.fromScale(0.6, 0.92))
	local macroTitle = Paint.text(
		macroEditor,
		"Select a macro",
		UDim2.fromScale(0.05, 0.04),
		UDim2.fromScale(0.9, 0.1),
		Enum.TextXAlignment.Left
	)
	macroTitle.Font = Paint.FontTitle
	macroTitle.TextColor3 = Paint.Gold
	macroTitle.TextSize = Paint.TextSizeTitle
	local macroBox = Instance.new("TextBox")
	macroBox.Size = UDim2.fromScale(0.9, 0.52)
	macroBox.Position = UDim2.fromScale(0.05, 0.16)
	macroBox.BackgroundColor3 = Paint.WoodInner
	macroBox.TextColor3 = Paint.TextColorBody
	macroBox.Font = Paint.FontBody
	macroBox.TextSize = Paint.TextSizeBody
	macroBox.PlaceholderColor3 = Paint.TextColorSecondary
	macroBox.Text = ""
	macroBox.PlaceholderText = "Closed DSL. The server re-validates every save and run."
	macroBox.TextXAlignment = Enum.TextXAlignment.Left
	macroBox.TextYAlignment = Enum.TextYAlignment.Top
	macroBox.TextWrapped = true
	macroBox.ClearTextOnFocus = false
	macroBox.MultiLine = true
	macroBox.Parent = macroEditor
	Paint.corner(macroBox, 2)
	Paint.trim(macroBox, Paint.Bronze, 1)
	local runMacro = Paint.primaryButton(macroEditor, "Run", UDim2.fromScale(0.05, 0.74), UDim2.fromScale(0.28, 0.1))
	local bindMacro = Paint.primaryButton(macroEditor, "Bind", UDim2.fromScale(0.36, 0.74), UDim2.fromScale(0.28, 0.1))
	local saveMacro = Paint.primaryButton(macroEditor, "Save", UDim2.fromScale(0.67, 0.74), UDim2.fromScale(0.28, 0.1))
	local stopMacro =
		Paint.primaryButton(macroEditor, "Stop  (Q)", UDim2.fromScale(0.05, 0.86), UDim2.fromScale(0.9, 0.1))
	stopMacro.MouseButton1Click:Connect(function()
		fire("Macro", "StopMacro", { macroId = "" })
	end)
	runMacro.MouseButton1Click:Connect(function()
		if selectedMacro ~= "" then
			deps.onUseMacro(selectedMacro)
		end
	end)
	bindMacro.MouseButton1Click:Connect(function()
		if selectedMacro ~= "" then
			bindKind("Macro", selectedMacro)
		end
	end)
	saveMacro.MouseButton1Click:Connect(function()
		if selectedMacro == "" then
			return
		end
		fire("Macro", "SaveMacro", { macroId = selectedMacro, source = macroBox.Text })
	end)

	local function refreshNow(ctx: WindowCtx)
		if host.isOpen("Macros") then
			local rosterIds = Macros.macroRosterIds(ctx)
			gate.gate("Macros", `{table.concat(rosterIds, ",")}|{selectedMacro}`, function()
				Paint.clearFrame(macroRoster)
				local y = 4
				for _, macroId in rosterIds do
					local entry = MacroCatalog.get(macroId)
					local label = if entry then entry.Name else macroId
					local btn = Paint.primaryButton(macroRoster, label, UDim2.fromOffset(4, y), UDim2.new(1, -8, 0, 36))
					if macroId == selectedMacro then
						Paint.gradient(btn, Color3.fromRGB(118, 84, 28), Color3.fromRGB(56, 38, 12), 90)
					end
					local captured = macroId
					btn.MouseButton1Click:Connect(function()
						selectedMacro = captured
						host.requestRefresh()
					end)
					y += 42
				end
				local selected = if selectedMacro ~= "" then MacroCatalog.get(selectedMacro) else nil
				if selected then
					macroTitle.Text = `{selected.Name}   ·   {selected.BarProfile}`
					if shownMacro ~= selected.Id then
						shownMacro = selected.Id
						macroBox.Text = selected.Source
					end
				else
					macroTitle.Text = "Select a macro"
					shownMacro = ""
					if not macroBox:IsFocused() then
						macroBox.Text = ""
					end
				end
			end)
		end
	end

	local handle: WindowHost.PanelHandle = {
		ids = { "Macros" },
		refresh = refreshNow,
	}
	host.register(handle)
	return handle
end

return Macros
