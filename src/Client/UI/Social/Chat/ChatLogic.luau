--!strict

export type SlashParse = { channel: string, body: string, whisper: boolean }
export type WhisperCandidate = { userId: number, name: string }

local TIME_STAMP = "^%[%d%d:%d%d%]"

local ChatLogic = {}

function ChatLogic.stampLine(line: string, stamp: string): string
	if string.match(line, TIME_STAMP) then
		return line
	end
	return `[{stamp}] {line}`
end

function ChatLogic.parseSlash(body: string): SlashParse
	if string.sub(body, 1, 3) == "/p " then
		return { channel = "party", body = string.sub(body, 4), whisper = false }
	elseif string.sub(body, 1, 3) == "/g " then
		return { channel = "guild", body = string.sub(body, 4), whisper = false }
	elseif string.sub(body, 1, 3) == "/z " then
		return { channel = "zone", body = string.sub(body, 4), whisper = false }
	elseif string.sub(body, 1, 3) == "/w " then
		return { channel = "whisper", body = string.sub(body, 4), whisper = true }
	end
	return { channel = "say", body = body, whisper = false }
end

function ChatLogic.channelTab(channel: string): string
	if channel == "party" then
		return "Party"
	elseif channel == "guild" then
		return "Guild"
	elseif channel == "whisper" then
		return "Whisper"
	elseif channel == "zone" then
		return "Zone"
	elseif channel == "combat" then
		return "Combat"
	end
	return "Say"
end

function ChatLogic.resolveWhisper(
	targetName: string,
	nearby: { WhisperCandidate },
	party: { WhisperCandidate }
): WhisperCandidate?
	local needle = string.lower(targetName)
	if needle ~= "" and needle ~= "no target" then
		for _, row in party do
			if string.lower(row.name) == needle then
				return row
			end
		end
		for _, row in nearby do
			if string.lower(row.name) == needle then
				return row
			end
		end
	end
	if nearby[1] then
		return nearby[1]
	end
	if party[1] then
		return party[1]
	end
	return nil
end

function ChatLogic.inviteName(userId: number, nearby: { WhisperCandidate }, party: { WhisperCandidate }): string
	for _, row in nearby do
		if row.userId == userId then
			return row.name
		end
	end
	for _, row in party do
		if row.userId == userId then
			return row.name
		end
	end
	return `Player {string.format("%.0f", userId)}`
end

return ChatLogic
