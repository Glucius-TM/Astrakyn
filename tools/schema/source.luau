--!strict

local Common = require("./common")

local Source = {}

local function skipQuoted(text: string, index: number, quote: string): number
	index += 1
	while index <= #text do
		local char = string.sub(text, index, index)
		if char == "\\" then
			index += 2
		elseif char == quote then
			return index + 1
		else
			index += 1
		end
	end
	return index
end

local function skipInterpolated(text: string, index: number): number
	return skipQuoted(text, index, "`")
end

local function skipLongBracket(text: string, index: number): number?
	local eqs = string.match(string.sub(text, index), "^%[(=*)%[")
	if eqs == nil then
		return nil
	end
	local close = "]" .. eqs .. "]"
	local _, finish = string.find(text, close, index + 2 + #eqs, true)
	if finish == nil then
		return #text + 1
	end
	return finish + 1
end

local function skipTriviaToken(text: string, index: number): number?
	local char = string.sub(text, index, index)
	if char == '"' or char == "'" then
		return skipQuoted(text, index, char)
	elseif char == "`" then
		return skipInterpolated(text, index)
	end
	local longEnd = skipLongBracket(text, index)
	if longEnd ~= nil then
		return longEnd
	end
	if string.sub(text, index, index + 1) == "--" then
		local blockEnd = skipLongBracket(text, index + 2)
		if blockEnd ~= nil then
			return blockEnd
		end
		local newline = string.find(text, "\n", index + 2, true)
		return if newline == nil then #text + 1 else newline + 1
	end
	return nil
end

local function findCodePattern(text: string, pattern: string, cursor: number): (number?, number?)
	local searchFrom = cursor
	while searchFrom <= #text do
		local startPos, endPos = string.find(text, pattern, searchFrom)
		if startPos == nil or endPos == nil then
			return nil, nil
		end

		local index = searchFrom
		local insideTrivia = false
		while index < startPos do
			local skipped = skipTriviaToken(text, index)
			if skipped ~= nil then
				if skipped > startPos then
					searchFrom = skipped
					insideTrivia = true
					break
				end
				index = skipped
			else
				index += 1
			end
		end
		if not insideTrivia then
			return startPos, endPos
		end
	end
	return nil, nil
end

local function scanBalanced(text: string, openIndex: number, openChar: string, closeChar: string): (string?, number?)
	local depth = 1
	local index = openIndex + 1
	while index <= #text do
		local skipped = skipTriviaToken(text, index)
		if skipped ~= nil then
			index = skipped
			continue
		end
		local char = string.sub(text, index, index)
		if char == openChar then
			depth += 1
		elseif char == closeChar then
			depth -= 1
			if depth == 0 then
				return string.sub(text, openIndex + 1, index - 1), index
			end
		end
		index += 1
	end
	return nil, nil
end

local function splitTopLevel(text: string): { string }
	local parts = {}
	local startIndex = 1
	local round = 0
	local square = 0
	local curly = 0
	local index = 1
	while index <= #text do
		local skipped = skipTriviaToken(text, index)
		if skipped ~= nil then
			index = skipped
			continue
		end
		local char = string.sub(text, index, index)
		if char == "(" then
			round += 1
		elseif char == ")" then
			round -= 1
		elseif char == "[" then
			square += 1
		elseif char == "]" then
			square -= 1
		elseif char == "{" then
			curly += 1
		elseif char == "}" then
			curly -= 1
		elseif char == "," and round == 0 and square == 0 and curly == 0 then
			table.insert(parts, Common.trim(string.sub(text, startIndex, index - 1)))
			startIndex = index + 1
		end
		index += 1
	end
	local tail = Common.trim(string.sub(text, startIndex))
	if tail ~= "" then
		table.insert(parts, tail)
	end
	return parts
end

function Source.calls(text: string, name: string): { { string } }
	local calls = {}
	local cursor = 1
	local pattern = "%f[%w_]" .. name .. "%f[^%w_]%s*%("
	while cursor <= #text do
		local startPos, endPos = findCodePattern(text, pattern, cursor)
		if startPos == nil or endPos == nil then
			break
		end
		local openIndex = string.find(text, "(", startPos, true)
		if openIndex == nil then
			break
		end
		local body, closeIndex = scanBalanced(text, openIndex, "(", ")")
		if body == nil or closeIndex == nil then
			break
		end
		table.insert(calls, splitTopLevel(body))
		cursor = closeIndex + 1
	end
	return calls
end

function Source.stringLiteral(value: string?): string?
	if value == nil then
		return nil
	end
	local trimmed = Common.trim(value)
	local doubleQuoted = string.match(trimmed, '^"([^"\\]*)"$')
	if doubleQuoted ~= nil then
		return doubleQuoted
	end
	return string.match(trimmed, "^'([^'\\]*)'$")
end

function Source.callStringArgs(text: string, name: string): { { string? } }
	local out = {}
	for _, args in Source.calls(text, name) do
		local row = {}
		for index, arg in args do
			row[index] = Source.stringLiteral(arg)
		end
		table.insert(out, row)
	end
	return out
end

function Source.firstStringArgs(text: string, name: string): { string }
	local out = {}
	for _, args in Source.calls(text, name) do
		local value = Source.stringLiteral(args[1])
		if value ~= nil then
			table.insert(out, value)
		end
	end
	return out
end

function Source.fieldStrings(text: string, key: string): { string }
	local out = {}
	local cursor = 1
	local pattern = "%f[%w_]" .. key .. '%f[^%w_]%s*=%s*"'
	while cursor <= #text do
		local startPos, endPos = findCodePattern(text, pattern, cursor)
		if startPos == nil or endPos == nil then
			break
		end
		local quoteIndex = string.find(text, '"', startPos, true)
		if quoteIndex == nil then
			break
		end
		local afterQuote = skipQuoted(text, quoteIndex, '"')
		local value = Source.stringLiteral(string.sub(text, quoteIndex, afterQuote - 1))
		if value ~= nil then
			table.insert(out, value)
		end
		cursor = math.max(endPos + 1, afterQuote)
	end
	return out
end

function Source.quotedStrings(text: string): { string }
	local out = {}
	local index = 1
	while index <= #text do
		local char = string.sub(text, index, index)
		if char == '"' then
			local afterQuote = skipQuoted(text, index, '"')
			local value = Source.stringLiteral(string.sub(text, index, afterQuote - 1))
			if value ~= nil then
				table.insert(out, value)
			end
			index = afterQuote
		elseif char == "'" or char == "`" or string.sub(text, index, index + 1) == "--" then
			local skipped = skipTriviaToken(text, index)
			index = skipped or (index + 1)
		else
			local longEnd = skipLongBracket(text, index)
			index = longEnd or (index + 1)
		end
	end
	return out
end

function Source.namedTableBlocks(text: string, key: string): { string }
	local blocks = {}
	local cursor = 1
	local pattern = "%f[%w_]" .. key .. "%f[^%w_]%s*=%s*{"
	while cursor <= #text do
		local startPos = findCodePattern(text, pattern, cursor)
		if startPos == nil then
			break
		end
		local openIndex = string.find(text, "{", startPos, true)
		if openIndex == nil then
			break
		end
		local body, closeIndex = scanBalanced(text, openIndex, "{", "}")
		if body == nil or closeIndex == nil then
			break
		end
		table.insert(blocks, body)
		cursor = closeIndex + 1
	end
	return blocks
end

function Source.lineKeys(text: string, valuePattern: string): { string }
	local out = {}
	for line in string.gmatch(text .. "\n", "([^\n]*)\n") do
		local value = string.match(line, valuePattern)
		if value ~= nil then
			table.insert(out, value)
		end
	end
	return out
end

function Source.identifierLines(text: string, name: string): { number }
	local lines = {}
	local index = 1
	local line = 1
	while index <= #text do
		local skipped = skipTriviaToken(text, index)
		if skipped ~= nil then
			local trivia = string.sub(text, index, skipped - 1)
			local _, newlineCount = string.gsub(trivia, "\n", "")
			line += newlineCount
			index = skipped
			continue
		end

		local char = string.sub(text, index, index)
		if string.match(char, "[%a_]") ~= nil then
			local finish = index + 1
			while finish <= #text and string.match(string.sub(text, finish, finish), "[%w_]") ~= nil do
				finish += 1
			end
			if string.sub(text, index, finish - 1) == name then
				table.insert(lines, line)
			end
			index = finish
		else
			if char == "\n" then
				line += 1
			end
			index += 1
		end
	end
	return lines
end

return Source
