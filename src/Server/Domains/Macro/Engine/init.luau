--!strict

local MacroAuthorizedQueries = require(script.MacroAuthorizedQueries)
local MacroCompiler = require(script.MacroCompiler)
local MacroConditionEvaluator = require(script.MacroConditionEvaluator)
local MacroLexer = require(script.MacroLexer)
local MacroParser = require(script.MacroParser)
local MacroRuntime = require(script.MacroRuntime)
local MacroValidator = require(script.MacroValidator)

local MacroEngine = {
	AuthorizedQueries = MacroAuthorizedQueries,
	Compiler = MacroCompiler,
	ConditionEvaluator = MacroConditionEvaluator,
	Lexer = MacroLexer,
	Parser = MacroParser,
	Runtime = MacroRuntime,
	Validator = MacroValidator,
}

return MacroEngine
