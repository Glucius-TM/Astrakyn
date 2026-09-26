--!strict
-- Presentation boundary for published atlas slices. Source PNGs are authoring assets, not runtime Instances.

local IconAtlasContent = {}

function IconAtlasContent.applySlice(
	imageLabel: ImageLabel,
	assetId: string,
	rectX: number,
	rectY: number,
	cellSize: number
): boolean
	if assetId == "" then
		return false
	end
	imageLabel.Image = assetId
	imageLabel.ImageRectOffset = Vector2.new(rectX, rectY)
	imageLabel.ImageRectSize = Vector2.new(cellSize, cellSize)
	imageLabel.ScaleType = Enum.ScaleType.Fit
	return true
end

return IconAtlasContent
