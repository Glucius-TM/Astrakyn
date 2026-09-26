--!strict

-- HD presentation for all Kynfall zones. MeshId must be a real rbxassetid from Studio MCP — never invent.
-- Art bar: adult photorealistic PBR (no cartoon/toy); max triangles = PerformanceBudgets.MeshPresentationMaxTriangles.

export type MeshSlotZone =
	"Zone_Gate"
	| "Zone_Ember"
	| "Zone_Pale"
	| "Zone_Void"
	| "Zone_Threshold"
	| "Zone_Tide"
	| "Zone_Thorn"
	| "Zone_Sky"
	| "Zone_Echo"

export type MeshPresentationDefinition = {
	Id: string,
	ZoneId: MeshSlotZone,
	Slot: string,
	DisplayName: string,
	MeshId: string,
	-- Optional AI/baked TextureID. MeshId alone is geometry; without TextureId or MaterialVariant the mesh looks flat.
	TextureId: string?,
	MaxTriangles: number,
	MaterialVariant: string?,
	BaseMaterial: string?,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)

local function def(
	id: string,
	zoneId: MeshSlotZone,
	slot: string,
	displayName: string,
	meshId: string,
	materialVariant: string?,
	baseMaterial: string?,
	textureId: string?
): MeshPresentationDefinition
	return {
		Id = id,
		ZoneId = zoneId,
		Slot = slot,
		DisplayName = displayName,
		MeshId = meshId,
		TextureId = textureId,
		MaxTriangles = PerformanceBudgets.MeshPresentationMaxTriangles,
		MaterialVariant = materialVariant,
		BaseMaterial = baseMaterial,
	}
end

-- MeshIds filled by Studio MCP generate_mesh. Empty = incomplete (backlog HD).
local entries: { MeshPresentationDefinition } = {
	-- Zone_Gate
	def(
		"Mesh_Gate_SpawnPad",
		"Zone_Gate",
		"SpawnPad",
		"Gate Plaza Pad",
		"rbxassetid://119526056745717",
		nil,
		nil,
		"rbxassetid://135357107192008"
	),
	def(
		"Mesh_Gate_Keep",
		"Zone_Gate",
		"Keep",
		"Gate Keep",
		"rbxassetid://127401398808580",
		nil,
		nil,
		"rbxassetid://118414759441469"
	),
	def(
		"Mesh_Gate_Barracks",
		"Zone_Gate",
		"Barracks",
		"Plaza Barracks",
		"rbxassetid://82297447458875",
		nil,
		nil,
		"rbxassetid://94444093499239"
	),
	def(
		"Mesh_Gate_GateHall",
		"Zone_Gate",
		"GateHall",
		"Gate Hall",
		"rbxassetid://79564625191142",
		nil,
		nil,
		"rbxassetid://115252963742114"
	),
	def(
		"Mesh_Gate_PlazaRing",
		"Zone_Gate",
		"PlazaRing",
		"Astral Plaza Ring",
		"rbxassetid://122252442090401",
		"HubAstralPavement",
		"Pavement",
		"rbxassetid://117564943287602"
	),
	def(
		"Mesh_Gate_Lamp",
		"Zone_Gate",
		"Lamp",
		"Gate Lamp",
		"rbxassetid://116046370291870",
		nil,
		nil,
		"rbxassetid://119322673101845"
	),
	def(
		"Mesh_Gate_Stall",
		"Zone_Gate",
		"Stall",
		"Broker Stall",
		"rbxassetid://110421771516143",
		nil,
		nil,
		"rbxassetid://74548588544633"
	),
	def(
		"Mesh_Gate_Basin",
		"Zone_Gate",
		"Basin",
		"Mender Basin",
		"rbxassetid://117266303469344",
		nil,
		nil,
		"rbxassetid://113125222355204"
	),
	def(
		"Mesh_Gate_Plinth",
		"Zone_Gate",
		"Plinth",
		"Plaza Plinth",
		"rbxassetid://98009198661512",
		nil,
		nil,
		"rbxassetid://96467050998235"
	),
	def(
		"Mesh_Gate_QuestBoard",
		"Zone_Gate",
		"QuestBoard",
		"Quest Board",
		"rbxassetid://71612383766974",
		nil,
		nil,
		"rbxassetid://89518790782520"
	),
	def(
		"Mesh_Gate_Gather",
		"Zone_Gate",
		"Gather",
		"Plaza Vein Marker",
		"rbxassetid://118189176481173",
		nil,
		nil,
		"rbxassetid://124582763154259"
	),
	-- Zone_Ember
	def(
		"Mesh_Ember_SpawnPad",
		"Zone_Ember",
		"SpawnPad",
		"Cinder Square Pad",
		"rbxassetid://95337842528542",
		nil,
		nil,
		"rbxassetid://121212026753343"
	),
	def(
		"Mesh_Ember_CinderHall",
		"Zone_Ember",
		"CinderHall",
		"Cinder Hall",
		"rbxassetid://72658767580214",
		nil,
		nil,
		"rbxassetid://124573835713305"
	),
	def(
		"Mesh_Ember_LavaTrim",
		"Zone_Ember",
		"LavaTrim",
		"Ember Lava Trim",
		"rbxassetid://118486385166600",
		"EmberHeatGround",
		"CrackedLava",
		"rbxassetid://139432713813014"
	),
	def(
		"Mesh_Ember_Lamp",
		"Zone_Ember",
		"Lamp",
		"Cinder Lamp",
		"rbxassetid://74666021107429",
		nil,
		nil,
		"rbxassetid://83982940300468"
	),
	def(
		"Mesh_Ember_Forge",
		"Zone_Ember",
		"Forge",
		"Cinder Forge",
		"rbxassetid://119171350630801",
		nil,
		nil,
		"rbxassetid://101195364806946"
	),
	def(
		"Mesh_Ember_Portal",
		"Zone_Ember",
		"Portal",
		"Cinder Vault Portal",
		"rbxassetid://76425046617548",
		nil,
		nil,
		"rbxassetid://125631292224440"
	),
	def(
		"Mesh_Ember_Basin",
		"Zone_Ember",
		"Basin",
		"Cinder Basin",
		"rbxassetid://88739074715633",
		nil,
		nil,
		"rbxassetid://88727344341867"
	),
	def(
		"Mesh_Ember_Plinth",
		"Zone_Ember",
		"Plinth",
		"Cinder Plinth",
		"rbxassetid://73454318621789",
		nil,
		nil,
		"rbxassetid://137939495708231"
	),
	def(
		"Mesh_Ember_Gather",
		"Zone_Ember",
		"Gather",
		"Cinder Vein Marker",
		"rbxassetid://118047176585328",
		nil,
		nil,
		"rbxassetid://82615977709738"
	),
	-- Zone_Pale (MeshIds filled by Studio MCP generate_mesh)
	def(
		"Mesh_Pale_SpawnPad",
		"Zone_Pale",
		"SpawnPad",
		"Frostwell Court Pad",
		"rbxassetid://119526056745717",
		nil,
		nil,
		"rbxassetid://135357107192008"
	),
	def(
		"Mesh_Pale_Hall",
		"Zone_Pale",
		"PaleHall",
		"Palehaven Hall",
		"rbxassetid://82521176049903",
		nil,
		nil,
		"rbxassetid://98896145282857"
	),
	def(
		"Mesh_Pale_IceSpire",
		"Zone_Pale",
		"IceSpire",
		"Frostwell Ice Spire",
		"rbxassetid://125260863443879",
		"PaleFrostGround",
		"Glacier",
		"rbxassetid://128121821648467"
	),
	def(
		"Mesh_Pale_Lamp",
		"Zone_Pale",
		"Lamp",
		"Cold Lamp",
		"rbxassetid://77333729678524",
		nil,
		nil,
		"rbxassetid://103294874090773"
	),
	def(
		"Mesh_Pale_Plinth",
		"Zone_Pale",
		"Plinth",
		"Frostwell Plinth",
		"rbxassetid://103379996705754",
		nil,
		nil,
		"rbxassetid://79047069361493"
	),
	def(
		"Mesh_Pale_Gather",
		"Zone_Pale",
		"Gather",
		"Cold Vein Marker",
		"rbxassetid://85544031027680",
		nil,
		nil,
		"rbxassetid://98515068160758"
	),
	def(
		"Mesh_Pale_Basin",
		"Zone_Pale",
		"Basin",
		"Pale Mender Basin",
		"rbxassetid://115902436085837",
		nil,
		nil,
		"rbxassetid://94740648581038"
	),
	-- Zone_Void (MeshIds filled by Studio MCP generate_mesh)
	def(
		"Mesh_Void_SpawnPad",
		"Zone_Void",
		"SpawnPad",
		"Voidmarch Camp Pad",
		"rbxassetid://85411572733566",
		nil,
		nil,
		"rbxassetid://136795878153211"
	),
	def(
		"Mesh_Void_Rock",
		"Zone_Void",
		"VoidRock",
		"Voidmarch Ash Rock",
		"rbxassetid://71482429285987",
		"VoidAshGround",
		"Basalt",
		"rbxassetid://131065073792334"
	),
	def(
		"Mesh_Void_Lamp",
		"Zone_Void",
		"Lamp",
		"Rift Lamp",
		"rbxassetid://85552479829825",
		nil,
		nil,
		"rbxassetid://106662288248279"
	),
	def(
		"Mesh_Void_Plinth",
		"Zone_Void",
		"Plinth",
		"March Plinth",
		"rbxassetid://122141216020610",
		nil,
		nil,
		"rbxassetid://77244488854056"
	),
	def(
		"Mesh_Void_Gather",
		"Zone_Void",
		"Gather",
		"Rift Vein Marker",
		"rbxassetid://71860732239616",
		nil,
		nil,
		"rbxassetid://91585361665079"
	),
	-- Zone_Threshold Astral Threshold (HD mesh — MeshIds filled by Studio MCP generate_mesh)
	def(
		"Mesh_Threshold_SpawnPad",
		"Zone_Threshold",
		"SpawnPad",
		"Threshold Gate Pad",
		"rbxassetid://86639054461363",
		nil,
		nil,
		"rbxassetid://112172785060461"
	),
	def(
		"Mesh_Threshold_Lamp",
		"Zone_Threshold",
		"Lamp",
		"Astral Pulse Lamp",
		"rbxassetid://126230441385185",
		nil,
		nil,
		"rbxassetid://90684050809983"
	),
	def(
		"Mesh_Threshold_Plinth",
		"Zone_Threshold",
		"Plinth",
		"Pulse Instructor Plinth",
		"rbxassetid://96098251510498",
		nil,
		nil,
		"rbxassetid://121757638947808"
	),
	def(
		"Mesh_Threshold_Basin",
		"Zone_Threshold",
		"Basin",
		"Threshold Mender Basin",
		"rbxassetid://121706489924081",
		nil,
		nil,
		"rbxassetid://123598590454060"
	),
	def(
		"Mesh_Threshold_Gather",
		"Zone_Threshold",
		"Gather",
		"Pulse Vein Marker",
		"rbxassetid://131908713403878",
		nil,
		nil,
		"rbxassetid://105983224342997"
	),
	def(
		"Mesh_Threshold_QuestBoard",
		"Zone_Threshold",
		"QuestBoard",
		"Threshold Quest Board",
		"rbxassetid://73378660604842",
		nil,
		nil,
		"rbxassetid://112113294428834"
	),
	def(
		"Mesh_Threshold_Dummy",
		"Zone_Threshold",
		"Dummy",
		"Training Echo Marker",
		"rbxassetid://95973836668036",
		nil,
		nil,
		"rbxassetid://97308868366986"
	),
	def(
		"Mesh_Threshold_GateTrim",
		"Zone_Threshold",
		"GateTrim",
		"Threshold Gate Trim",
		"rbxassetid://135358474565547",
		"ThresholdAstralGround",
		"Rock",
		"rbxassetid://98795586154161"
	),
	-- Zone_Tide (Tidehaven — photorealistic PBR HD via Studio MCP generate_mesh)
	def(
		"Mesh_Tide_SpawnPad",
		"Zone_Tide",
		"SpawnPad",
		"Tide Square Pad",
		"rbxassetid://139680526466383",
		nil,
		nil,
		"rbxassetid://95008857865547"
	),
	def(
		"Mesh_Tide_Hall",
		"Zone_Tide",
		"TideHall",
		"Tidehaven Hall",
		"rbxassetid://122984027075451",
		nil,
		nil,
		"rbxassetid://76902580067652"
	),
	def(
		"Mesh_Tide_Trim",
		"Zone_Tide",
		"TideTrim",
		"Tide Coast Trim",
		"rbxassetid://70499456567836",
		"TideCoastGround",
		"Sandstone",
		"rbxassetid://90252579043825"
	),
	def(
		"Mesh_Tide_Lamp",
		"Zone_Tide",
		"Lamp",
		"Tide Lamp",
		"rbxassetid://134705946589286",
		nil,
		nil,
		"rbxassetid://126441349595434"
	),
	def(
		"Mesh_Tide_Portal",
		"Zone_Tide",
		"Portal",
		"Tidehold Portal",
		"rbxassetid://71739848797309",
		nil,
		nil,
		"rbxassetid://125491124016463"
	),
	def(
		"Mesh_Tide_Basin",
		"Zone_Tide",
		"Basin",
		"Tide Mender Basin",
		"rbxassetid://98468393505050",
		nil,
		nil,
		"rbxassetid://72663629507017"
	),
	def(
		"Mesh_Tide_Plinth",
		"Zone_Tide",
		"Plinth",
		"Tide Plinth",
		"rbxassetid://81502221242922",
		nil,
		nil,
		"rbxassetid://78488674470427"
	),
	def(
		"Mesh_Tide_Gather",
		"Zone_Tide",
		"Gather",
		"Tide Vein Marker",
		"rbxassetid://84857286912879",
		nil,
		nil,
		"rbxassetid://119882960237600"
	),
	def(
		"Mesh_Tide_Dummy",
		"Zone_Tide",
		"Dummy",
		"Tide Echo Marker",
		"rbxassetid://131761654791099",
		nil,
		nil,
		"rbxassetid://89415501606745"
	),
	-- Zone_Thorn (Thornwood — photorealistic PBR HD via Studio MCP generate_mesh)
	def(
		"Mesh_Thorn_SpawnPad",
		"Zone_Thorn",
		"SpawnPad",
		"Briar Court Pad",
		"rbxassetid://85236665319237",
		nil,
		nil,
		"rbxassetid://131984076562132"
	),
	def(
		"Mesh_Thorn_Hall",
		"Zone_Thorn",
		"ThornHall",
		"Thornwood Hall",
		"rbxassetid://78947228314213",
		nil,
		nil,
		"rbxassetid://104041539207221"
	),
	def(
		"Mesh_Thorn_Trim",
		"Zone_Thorn",
		"ThornTrim",
		"Thorn Briar Trim",
		"rbxassetid://95238580226702",
		"ThornBriarGround",
		"Grass",
		"rbxassetid://117448219411707"
	),
	def(
		"Mesh_Thorn_Lamp",
		"Zone_Thorn",
		"Lamp",
		"Thorn Lamp",
		"rbxassetid://99295355724872",
		nil,
		nil,
		"rbxassetid://106342859022470"
	),
	def(
		"Mesh_Thorn_Portal",
		"Zone_Thorn",
		"Portal",
		"Thornroot Portal",
		"rbxassetid://113063450302164",
		nil,
		nil,
		"rbxassetid://107089908179649"
	),
	def(
		"Mesh_Thorn_Basin",
		"Zone_Thorn",
		"Basin",
		"Thorn Mender Basin",
		"rbxassetid://121776184660389",
		nil,
		nil,
		"rbxassetid://70633658604345"
	),
	def(
		"Mesh_Thorn_Plinth",
		"Zone_Thorn",
		"Plinth",
		"Thorn Plinth",
		"rbxassetid://98289800626625",
		nil,
		nil,
		"rbxassetid://87527019132312"
	),
	def(
		"Mesh_Thorn_Gather",
		"Zone_Thorn",
		"Gather",
		"Thorn Vein Marker",
		"rbxassetid://134146119144318",
		nil,
		nil,
		"rbxassetid://90249068483054"
	),
	def(
		"Mesh_Thorn_Dummy",
		"Zone_Thorn",
		"Dummy",
		"Thorn Echo Marker",
		"rbxassetid://90161173732401",
		nil,
		nil,
		"rbxassetid://118892433794054"
	),
	-- Zone_Sky (Skyreach — photorealistic PBR HD via Studio MCP generate_mesh)
	def(
		"Mesh_Sky_SpawnPad",
		"Zone_Sky",
		"SpawnPad",
		"Peak Plaza Pad",
		"rbxassetid://138147101770727",
		nil,
		nil,
		"rbxassetid://137449240725587"
	),
	def(
		"Mesh_Sky_Hall",
		"Zone_Sky",
		"SkyHall",
		"Skyreach Hall",
		"rbxassetid://139435789437968",
		nil,
		nil,
		"rbxassetid://75257244159328"
	),
	def(
		"Mesh_Sky_Trim",
		"Zone_Sky",
		"SkyTrim",
		"Sky Peak Trim",
		"rbxassetid://126520553352530",
		"SkyPeakGround",
		"Rock",
		"rbxassetid://106475606104238"
	),
	def(
		"Mesh_Sky_Lamp",
		"Zone_Sky",
		"Lamp",
		"Sky Lamp",
		"rbxassetid://101048568413902",
		nil,
		nil,
		"rbxassetid://73032224211043"
	),
	def(
		"Mesh_Sky_Portal",
		"Zone_Sky",
		"Portal",
		"Windspire Portal",
		"rbxassetid://131978109863895",
		nil,
		nil,
		"rbxassetid://133093862511842"
	),
	def(
		"Mesh_Sky_Basin",
		"Zone_Sky",
		"Basin",
		"Sky Mender Basin",
		"rbxassetid://121073785520531",
		nil,
		nil,
		"rbxassetid://75720544329229"
	),
	def(
		"Mesh_Sky_Plinth",
		"Zone_Sky",
		"Plinth",
		"Sky Plinth",
		"rbxassetid://118387177791639",
		nil,
		nil,
		"rbxassetid://137350576297121"
	),
	def(
		"Mesh_Sky_Gather",
		"Zone_Sky",
		"Gather",
		"Sky Vein Marker",
		"rbxassetid://74223176186996",
		nil,
		nil,
		"rbxassetid://86456254581742"
	),
	def(
		"Mesh_Sky_Dummy",
		"Zone_Sky",
		"Dummy",
		"Sky Echo Marker",
		"rbxassetid://140018465691973",
		nil,
		nil,
		"rbxassetid://136097260140479"
	),
	-- Zone_Echo (Echo Yard — photorealistic PBR HD via Studio MCP generate_mesh)
	def(
		"Mesh_Echo_SpawnPad",
		"Zone_Echo",
		"SpawnPad",
		"Echo Pit Pad",
		"rbxassetid://91884003677343",
		nil,
		nil,
		"rbxassetid://76819901601500"
	),
	def(
		"Mesh_Echo_ArenaPit",
		"Zone_Echo",
		"ArenaPit",
		"Echo Arena Floor",
		"rbxassetid://81185256894503",
		"EchoWarGround",
		"Basalt",
		"rbxassetid://77559206703596"
	),
	def(
		"Mesh_Echo_WarStand",
		"Zone_Echo",
		"WarStand",
		"Echo Spectator Stand",
		"rbxassetid://116700733682943",
		nil,
		nil,
		"rbxassetid://71735170688432"
	),
	def(
		"Mesh_Echo_WarBanner",
		"Zone_Echo",
		"WarBanner",
		"Echo War Banner",
		"rbxassetid://96259015407594",
		nil,
		nil,
		"rbxassetid://89009120238515"
	),
	def(
		"Mesh_Echo_Lamp",
		"Zone_Echo",
		"Lamp",
		"Echo Yard Lamp",
		"rbxassetid://134530049768035",
		nil,
		nil,
		"rbxassetid://81495232975447"
	),
	def(
		"Mesh_Echo_Basin",
		"Zone_Echo",
		"Basin",
		"Echo Mender Basin",
		"rbxassetid://135282257585957",
		nil,
		nil,
		"rbxassetid://100938376476306"
	),
	def(
		"Mesh_Echo_Plinth",
		"Zone_Echo",
		"Plinth",
		"Echo Plinth",
		"rbxassetid://129364029435433",
		nil,
		nil,
		"rbxassetid://112431385199741"
	),
	def(
		"Mesh_Echo_Gather",
		"Zone_Echo",
		"Gather",
		"Echo Vein Marker",
		"rbxassetid://111230122333237",
		nil,
		nil,
		"rbxassetid://106668385162538"
	),
	def(
		"Mesh_Echo_Dummy",
		"Zone_Echo",
		"Dummy",
		"Echo Spar Marker",
		"rbxassetid://117432945682719",
		nil,
		nil,
		"rbxassetid://75121885555049"
	),
}

local byZoneSlot: { [string]: MeshPresentationDefinition } = {}
for _, row in entries do
	byZoneSlot[`{row.ZoneId}:{row.Slot}`] = row
end

local MeshPresentationCatalog = {}

function MeshPresentationCatalog.getSlot(zoneId: string, slot: string): MeshPresentationDefinition?
	return byZoneSlot[`{zoneId}:{slot}`]
end

function MeshPresentationCatalog.forZone(zoneId: string): { MeshPresentationDefinition }
	local out: { MeshPresentationDefinition } = {}
	for _, row in entries do
		if row.ZoneId == zoneId then
			table.insert(out, row)
		end
	end
	return out
end

function MeshPresentationCatalog.count(): number
	return #entries
end

function MeshPresentationCatalog.incomplete(): { string }
	local missing: { string } = {}
	for _, row in entries do
		if row.MeshId == "" then
			table.insert(missing, row.Id)
		end
	end
	return missing
end

function MeshPresentationCatalog.isComplete(): boolean
	return #MeshPresentationCatalog.incomplete() == 0
end

function MeshPresentationCatalog.isCompleteFor(zoneId: string): boolean
	for _, row in entries do
		if row.ZoneId == zoneId and row.MeshId == "" then
			return false
		end
	end
	return MeshPresentationCatalog.forZone(zoneId)[1] ~= nil
end

return MeshPresentationCatalog
