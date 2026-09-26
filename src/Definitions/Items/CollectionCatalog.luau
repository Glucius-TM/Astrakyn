--!strict

export type CollectionEntry = {
	Id: string,
	Name: string,
	TemplateId: string,
}

local entries: { CollectionEntry } = {
	{ Id = "Collection_WardenBlade", Name = "Warden Blade", TemplateId = "WardenBlade" },
	{ Id = "Collection_PulseFocus", Name = "Pulse Focus", TemplateId = "PulseFocus" },
	{ Id = "Collection_ThresholdMail", Name = "Threshold Mail", TemplateId = "ThresholdMail" },
	{ Id = "Collection_GuardianPlate", Name = "Guardian Plate", TemplateId = "GuardianPlate" },
	{ Id = "Collection_CinderEdge", Name = "Cinder Edge", TemplateId = "CinderEdge" },
	{ Id = "Collection_PaleStaff", Name = "Pale Staff", TemplateId = "PaleStaff" },
	{ Id = "Collection_SpireCrown", Name = "Spire Crown", TemplateId = "SpireCrown" },
	{ Id = "Collection_VoidmawFang", Name = "Voidmaw Fang", TemplateId = "VoidmawFang" },
	{ Id = "Collection_RiftEdge", Name = "Rift Edge", TemplateId = "RiftEdge" },
	{ Id = "Collection_VoidMail", Name = "Void Mail", TemplateId = "VoidMail" },
	{ Id = "Collection_ThornJerkin", Name = "Thorn Jerkin", TemplateId = "ThornMail" },
	{ Id = "Collection_ShadeVest", Name = "Shade Vest", TemplateId = "ShadeVest" },
	{ Id = "Collection_HideJerkin", Name = "Hide Jerkin", TemplateId = "HideJerkin" },
	{ Id = "Collection_EchoBand", Name = "Echo Band", TemplateId = "EchoBand" },
	{ Id = "Collection_AstralCrown", Name = "Astral Crown", TemplateId = "AstralCrown" },
}

local byTemplate: { [string]: CollectionEntry } = {}
local byId: { [string]: CollectionEntry } = {}
for _, row in entries do
	byTemplate[row.TemplateId] = row
	byId[row.Id] = row
end

local CollectionCatalog = {}

function CollectionCatalog.forTemplate(templateId: string): CollectionEntry?
	return byTemplate[templateId]
end

function CollectionCatalog.get(id: string): CollectionEntry?
	return byId[id]
end

return CollectionCatalog
