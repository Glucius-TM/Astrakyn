--!strict

local ChatChannels = {}

ChatChannels.Say = "ASTRAKYN_Say"
ChatChannels.Party = "ASTRAKYN_Party"
ChatChannels.Guild = "ASTRAKYN_Guild"
ChatChannels.Zone = "ASTRAKYN_Zone"
ChatChannels.WhisperPrefix = "ASTRAKYN_Whisper_"

local KIND_TO_NAME: { [string]: string } = {
	say = ChatChannels.Say,
	party = ChatChannels.Party,
	guild = ChatChannels.Guild,
	zone = ChatChannels.Zone,
}

local NAME_TO_KIND: { [string]: string } = {
	[ChatChannels.Say] = "say",
	[ChatChannels.Party] = "party",
	[ChatChannels.Guild] = "guild",
	[ChatChannels.Zone] = "zone",
}

function ChatChannels.forKind(kind: string): string?
	return KIND_TO_NAME[string.lower(kind)]
end

function ChatChannels.kindFromName(name: string): string?
	local publicKind = NAME_TO_KIND[name]
	if publicKind ~= nil then
		return publicKind
	end
	if string.sub(name, 1, #ChatChannels.WhisperPrefix) == ChatChannels.WhisperPrefix then
		return "whisper"
	end
	return nil
end

function ChatChannels.whisperName(a: number, b: number): string
	local low = math.min(a, b)
	local high = math.max(a, b)
	return `{ChatChannels.WhisperPrefix}{low}_{high}`
end

function ChatChannels.isWhisperFor(name: string, userId: number): boolean
	local prefix = ChatChannels.WhisperPrefix
	if string.sub(name, 1, #prefix) ~= prefix then
		return false
	end
	local pair = string.sub(name, #prefix + 1)
	local separator = string.find(pair, "_", 1, true)
	if separator == nil then
		return false
	end
	local first = tonumber(string.sub(pair, 1, separator - 1))
	local second = tonumber(string.sub(pair, separator + 1))
	return first == userId or second == userId
end

return ChatChannels
