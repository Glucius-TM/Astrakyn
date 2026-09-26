--!strict

export type TokenKind = "Op" | "Ident" | "Number" | "Compare" | "EOF"

export type Token = {
	Kind: TokenKind,
	Value: string,
	Line: number,
}

local OPS = {
	ABILITY = true,
	TARGET = true,
	FOCUS = true,
	SELF = true,
	PARTY = true,
	CONDITION = true,
	SEQUENCE = true,
	PRIORITY = true,
	WAIT = true,
	CANCEL = true,
	STARTATTACK = true,
	STOPATTACK = true,
}

local MacroLexer = {}

function MacroLexer.tokenize(source: string): { Token }
	local tokens: { Token } = {}
	local lineNumber = 0
	for line in string.gmatch(source .. "\n", "([^\n]*)\n") do
		lineNumber += 1
		local trimmed = string.match(line, "^%s*(.-)%s*$") or ""
		if trimmed == "" or string.sub(trimmed, 1, 1) == "#" then
			continue
		end
		for word in string.gmatch(trimmed, "%S+") do
			local kind: TokenKind = "Ident"
			if OPS[word] then
				kind = "Op"
			elseif tonumber(word) ~= nil then
				kind = "Number"
			elseif word == "<" or word == ">" or word == "<=" or word == ">=" or word == "==" or word == "~=" then
				kind = "Compare"
			end
			local token: Token = { Kind = kind, Value = word, Line = lineNumber }
			table.insert(tokens, token)
		end
	end
	local eof: Token = { Kind = "EOF", Value = "", Line = lineNumber }
	table.insert(tokens, eof)
	return tokens
end

return MacroLexer
