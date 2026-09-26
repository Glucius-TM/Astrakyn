--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local Logger = require(script.Parent.Parent.Observability.Logger)
local RemoteCatalog = require(ReplicatedStorage.Shared.Protocols.RemoteCatalog)

local NetworkRegistry = {
	Name = "NetworkRegistry",
	_remotes = {} :: { [string]: RemoteEvent },
	_folders = {} :: { [string]: Folder },
	_ready = false,
}

function NetworkRegistry:Init(_container: ContainerTypes.Container)
	if self._ready then
		return
	end
	local rootInstance = ReplicatedStorage:FindFirstChild("Remotes")
	local root: Folder
	if rootInstance and rootInstance:IsA("Folder") then
		root = rootInstance :: Folder
	else
		root = Instance.new("Folder")
		root.Name = "Remotes"
		root.Parent = ReplicatedStorage
	end

	for _, definition in RemoteCatalog.all() do
		local folderInstance = root:FindFirstChild(definition.Folder)
		local folder: Folder
		if folderInstance and folderInstance:IsA("Folder") then
			folder = folderInstance :: Folder
		else
			folder = Instance.new("Folder")
			folder.Name = definition.Folder
			folder.Parent = root
		end
		self._folders[definition.Folder] = folder
		local existing = folder:FindFirstChild(definition.Id)
		if existing and existing:IsA("RemoteEvent") then
			self._remotes[definition.Id] = existing :: RemoteEvent
		else
			local remote = Instance.new("RemoteEvent")
			remote.Name = definition.Id
			remote.Parent = folder
			self._remotes[definition.Id] = remote
		end
	end

	self._ready = true
	ReplicatedStorage:SetAttribute("AstrakynRemotesReady", true)
	Logger.info("NetworkRegistry ready", { count = tostring(#RemoteCatalog.all()) })
end

function NetworkRegistry:Start() end

function NetworkRegistry:Get(id: string): RemoteEvent
	local remote = self._remotes[id]
	if remote == nil then
		error(`remote '{id}' is not in RemoteCatalog`)
	end
	return remote
end

return NetworkRegistry
