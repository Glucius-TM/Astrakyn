--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MacroParser = require(script.Parent.MacroParser)
local MacroTypes = require(ReplicatedStorage.Shared.Types.MacroTypes)
local MacroValidator = require(script.Parent.MacroValidator)
local Result = require(ReplicatedStorage.Shared.Utility.Result)

type MacroDefinition = MacroTypes.MacroDefinition
type CompileResult<T> = Result.Result<T>

local MacroCompiler = {}

function MacroCompiler.compile(id: string, name: string, source: string): CompileResult<MacroDefinition>
	local parsed = MacroParser.parse(source)
	if parsed.Ok == false then
		return Result.errOf(parsed)
	end
	local ast = parsed.Value
	if ast == nil then
		return Result.err("parse failed")
	end
	local valid = MacroValidator.validate(ast)
	if valid.Ok == false then
		return Result.errOf(valid)
	end
	return Result.ok({
		Id = id,
		Name = name,
		Source = source,
		Ast = ast,
	})
end

return MacroCompiler
