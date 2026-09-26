--!strict

-- MacroRuntime step, cancel, WAIT yield, and budget doors.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local MacroEngine = require(ServerScriptService.Domains.Macro.Engine)
local MacroTypes = require(ReplicatedStorage.Shared.Types.MacroTypes)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)

type Harness = HarnessApi.Harness
type MacroAstNode = MacroTypes.MacroAstNode
type MacroDefinition = MacroTypes.MacroDefinition

local RuntimeSpec = {}

local function node(op: MacroTypes.MacroOp, arg: string?): MacroAstNode
	return {
		Op = op,
		Args = if arg ~= nil then { arg } else {},
	}
end

local function definition(id: string, ast: { MacroAstNode }): MacroDefinition
	return {
		Id = id,
		Name = id,
		Source = "",
		Ast = ast,
	}
end

function RuntimeSpec.run(Harness: Harness)
	local mixed = definition("rt-mixed", {
		node("ABILITY", "Pulse"),
		node("WAIT", "0.1"),
		node("TARGET", "enemy"),
		node("CANCEL"),
		node("ABILITY", "Mend"),
	})
	local inst = MacroEngine.Runtime.create(7, mixed)
	Harness.assertEqual(inst.State, "Ready", "runtime starts Ready")
	Harness.assertEqual(inst.PlayerId, 7, "runtime keeps player")
	Harness.assertEqual(inst.CurrentNode, 1, "runtime starts at first node")

	local stepped = MacroEngine.Runtime.step(inst, mixed)
	Harness.assert(stepped.Ok, "mixed step ok")
	if stepped.Ok then
		Harness.assertEqual(#stepped.Value, 2, "WAIT>0 yields before TARGET/CANCEL")
		Harness.assertEqual(stepped.Value[1].Kind, "Ability", "ABILITY command")
		Harness.assertEqual(stepped.Value[1].AbilityId, "Pulse", "ABILITY id")
		Harness.assertEqual(stepped.Value[2].Kind, "Wait", "WAIT command")
		Harness.assertEqual(stepped.Value[2].Seconds, 0.1, "WAIT seconds")
	end
	Harness.assertEqual(inst.State, "Yield", "WAIT>0 leaves Yield")
	Harness.assertEqual(inst.CurrentNode, 3, "CurrentNode past WAIT")

	local resumed = MacroEngine.Runtime.step(inst, mixed)
	Harness.assert(resumed.Ok, "resume after WAIT ok")
	if resumed.Ok then
		Harness.assertEqual(#resumed.Value, 2, "resume runs TARGET then CANCEL")
		Harness.assertEqual(resumed.Value[1].Kind, "Target", "TARGET command")
		Harness.assertEqual(resumed.Value[2].Kind, "Cancel", "CANCEL command")
	end
	Harness.assertEqual(inst.State, "Yield", "CANCEL leaves Yield before Done")

	local waitOnly = definition("rt-wait-tail", {
		node("ABILITY", "Pulse"),
		node("WAIT", "1"),
	})
	local waitInst = MacroEngine.Runtime.create(1, waitOnly)
	local waitStep = MacroEngine.Runtime.step(waitInst, waitOnly)
	Harness.assert(waitStep.Ok, "trailing WAIT>0 ok")
	if waitStep.Ok then
		Harness.assertEqual(#waitStep.Value, 2, "ABILITY then WAIT")
	end
	Harness.assertEqual(waitInst.State, "Yield", "trailing WAIT>0 is Yield not Done")
	Harness.assert(waitInst.CurrentNode > #waitOnly.Ast, "CurrentNode past last WAIT")
	local afterWait = MacroEngine.Runtime.step(waitInst, waitOnly)
	Harness.assert(afterWait.Ok, "post-wait step ok")
	if afterWait.Ok then
		Harness.assertEqual(#afterWait.Value, 0, "nothing left after WAIT")
	end
	Harness.assertEqual(waitInst.State, "Done", "exhausted after WAIT resume is Done")

	local zeroWait = definition("rt-wait-zero", {
		node("ABILITY", "Pulse"),
		node("WAIT", "0"),
		node("ABILITY", "Mend"),
	})
	local zeroInst = MacroEngine.Runtime.create(1, zeroWait)
	local zeroStep = MacroEngine.Runtime.step(zeroInst, zeroWait)
	Harness.assert(zeroStep.Ok, "WAIT 0 continues same step")
	if zeroStep.Ok then
		Harness.assertEqual(#zeroStep.Value, 3, "WAIT 0 does not yield mid-step")
		Harness.assertEqual(zeroStep.Value[2].Kind, "Wait", "zero WAIT still emitted")
		Harness.assertEqual(zeroStep.Value[2].Seconds, 0, "zero seconds")
	end
	Harness.assertEqual(zeroInst.State, "Done", "WAIT 0 runs to Done")

	local attack = definition("rt-attack", { node("STARTATTACK"), node("STOPATTACK") })
	local attackInst = MacroEngine.Runtime.create(1, attack)
	local attackStep = MacroEngine.Runtime.step(attackInst, attack)
	Harness.assert(attackStep.Ok, "autoattack macro step ok")
	if attackStep.Ok then
		Harness.assertEqual(#attackStep.Value, 2, "autoattack macro emits start and stop")
		Harness.assertEqual(attackStep.Value[1].Kind, "StartAttack", "STARTATTACK command")
		Harness.assertEqual(attackStep.Value[2].Kind, "StopAttack", "STOPATTACK command")
	end

	local skip = definition("rt-skip", { node("SEQUENCE") })
	local skipInst = MacroEngine.Runtime.create(1, skip)
	local skipStep = MacroEngine.Runtime.step(skipInst, skip)
	Harness.assert(skipStep.Ok, "unknown op step ok")
	if skipStep.Ok then
		Harness.assertEqual(skipStep.Value[1].Kind, "Skip", "non-command op is Skip")
	end
	Harness.assertEqual(skipInst.State, "Done", "exhausted AST is Done")

	local waits: { MacroAstNode } = {}
	for _ = 1, PerformanceBudgets.MacroMaxCommands + 1 do
		table.insert(waits, node("WAIT", "0"))
	end
	local over = definition("rt-over", waits)
	local overInst = MacroEngine.Runtime.create(1, over)
	local overStep = MacroEngine.Runtime.step(overInst, over)
	Harness.assert(overStep.Ok == false, "MaxCommands exceeded")
	if overStep.Ok == false then
		Harness.assertEqual(overStep.Error, "MaxCommands exceeded", "MaxCommands names the door")
	end

	local activations: { MacroAstNode } = {}
	for _ = 1, PerformanceBudgets.MacroMaxActivations + 2 do
		table.insert(activations, node("ABILITY", "Pulse"))
	end
	local cap = definition("rt-cap", activations)
	local capInst = MacroEngine.Runtime.create(1, cap)
	local capStep = MacroEngine.Runtime.step(capInst, cap)
	Harness.assert(capStep.Ok, "activation cap yields instead of error")
	if capStep.Ok then
		Harness.assertEqual(#capStep.Value, PerformanceBudgets.MacroMaxActivations, "stops at MacroMaxActivations")
	end
	Harness.assertEqual(capInst.State, "Yield", "activation cap leaves Yield")
	local capResume = MacroEngine.Runtime.step(capInst, cap)
	Harness.assert(capResume.Ok, "activation multi-slice continues")
	if capResume.Ok then
		Harness.assertEqual(#capResume.Value, 2, "remaining activations on second step")
	end
	Harness.assertEqual(capInst.State, "Done", "activation multi-slice finishes Done")

	Harness.assertEqual(PerformanceBudgets.MacroMaxWaitSeconds, 2, "MacroMaxWaitSeconds budget")
end

return RuntimeSpec
