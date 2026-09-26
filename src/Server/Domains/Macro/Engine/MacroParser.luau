--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MacroLexer = require(script.Parent.MacroLexer)
local MacroTypes = require(ReplicatedStorage.Shared.Types.MacroTypes)
local Result = require(ReplicatedStorage.Shared.Utility.Result)

type Token = MacroLexer.Token
type MacroAstNode = MacroTypes.MacroAstNode
type ParseResult<T> = Result.Result<T>

local MacroParser = {}

function MacroParser.parse(source: string): ParseResult<{ MacroAstNode }>
	local tokens = MacroLexer.tokenize(source)
	local nodes: { MacroAstNode } = {}
	local index = 1

	local function current(): Token
		return tokens[index]
	end

	while current().Kind ~= "EOF" do
		local token = current()
		if token.Kind ~= "Op" then
			return Result.err(`line {token.Line}: expected operation, got '{token.Value}'`)
		end
		index += 1
		local args: { string } = {}
		while current().Kind ~= "EOF" and current().Kind ~= "Op" do
			table.insert(args, current().Value)
			index += 1
		end
		table.insert(nodes, {
			Op = token.Value :: MacroTypes.MacroOp,
			Args = args,
			Children = nil,
			Condition = nil,
		})
	end

	return Result.ok(nodes)
end

return MacroParser
