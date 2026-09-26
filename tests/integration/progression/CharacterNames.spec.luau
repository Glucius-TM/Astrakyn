--!strict

-- Character name door.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterNameRules = require(ReplicatedStorage.Shared.Utility.CharacterNameRules)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)

type Harness = HarnessApi.Harness

local CharacterNameRulesSpec = {}

function CharacterNameRulesSpec.run(Harness: Harness)
	local function errOf(name: string): string
		local err = CharacterNameRules.errorOf(name)
		return if err ~= nil then err else ""
	end

	Harness.assertEqual(errOf(""), "invalid name", "empty name")
	Harness.assertEqual(errOf(""), "invalid name", "whitespace name")
	Harness.assertEqual(errOf("A"), "invalid name", "single letter")
	Harness.assertEqual(errOf("!!"), "invalid name", "punctuation only")
	Harness.assertEqual(errOf("12"), "invalid name", "digits without a letter")
	Harness.assertEqual(errOf("Nyx<>"), "invalid name", "forbidden glyphs")
	Harness.assertEqual(errOf("Nyx"), "", "short valid name")
	Harness.assertEqual(errOf("Warden One"), "", "spaced name")
	Harness.assertEqual(errOf("Player1"), "", "alphanumeric DisplayName")
	Harness.assertEqual(errOf("O'Kyn"), "", "apostrophe")
	Harness.assertEqual(errOf("Gate-born"), "", "hyphen")
	Harness.assertEqual(errOf("Nyx"), "", "trims before validate")
	Harness.assertEqual(CharacterNameRules.trim("Nyx"), "Nyx", "trim")
	Harness.assertEqual(CharacterNameRules.trim(string.rep("A", 30)), string.rep("A", 24), "trim caps at 24")
end

return CharacterNameRulesSpec
