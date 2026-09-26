--!strict
-- Resolves published icon atlas asset IDs from the single JSON manifest mapped by Rojo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IconAtlasAssets = require(ReplicatedStorage.ArtManifests.IconAtlasAssets)

export type AtlasKind = "Ability" | "Item" | "Slot"

local IconAssetRegistry = {}

local function assetIdFor(kind: AtlasKind): string
	if kind == "Ability" then
		return IconAtlasAssets.Ability
	elseif kind == "Item" then
		return IconAtlasAssets.Item
	end
	return IconAtlasAssets.Slot
end

function IconAssetRegistry.getAssetId(kind: AtlasKind): string
	return assetIdFor(kind)
end

function IconAssetRegistry.hasAtlas(kind: AtlasKind): boolean
	return assetIdFor(kind) ~= ""
end

return IconAssetRegistry
