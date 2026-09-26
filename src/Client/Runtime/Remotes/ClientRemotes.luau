--!strict
-- Cached RemoteEvent access. Waits for server-published Remotes without blind infinite yields.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local READY_ATTR = "AstrakynRemotesReady"

local ClientRemotes = {}

local root: Folder? = nil
local cache: { [string]: RemoteEvent } = {}

local function resolveRoot(): Folder?
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing and existing:IsA("Folder") then
		return existing
	end
	return nil
end

function ClientRemotes.waitReady(): Folder
	local hit = root
	if hit then
		return hit
	end
	local found = resolveRoot()
	if found ~= nil then
		root = found
		return found
	end

	local ready = false
	local attrConn: RBXScriptConnection? = nil
	local childConn: RBXScriptConnection? = nil

	local function tryFinish(): boolean
		local remotes = resolveRoot()
		if remotes ~= nil then
			root = remotes
			ready = true
			return true
		end
		return false
	end

	if ReplicatedStorage:GetAttribute(READY_ATTR) == true then
		tryFinish()
	end

	if not ready then
		attrConn = ReplicatedStorage:GetAttributeChangedSignal(READY_ATTR):Connect(function()
			if ReplicatedStorage:GetAttribute(READY_ATTR) == true then
				tryFinish()
			end
		end)
		childConn = ReplicatedStorage.ChildAdded:Connect(function(child: Instance)
			if child.Name == "Remotes" and child:IsA("Folder") then
				tryFinish()
			end
		end)
		while not ready do
			if tryFinish() then
				break
			end
			task.wait()
		end
		if attrConn then
			attrConn:Disconnect()
		end
		if childConn then
			childConn:Disconnect()
		end
	end

	return root :: Folder
end

function ClientRemotes.get(folder: string, name: string): RemoteEvent
	local key = `{folder}/{name}`
	local hit = cache[key]
	if hit then
		return hit
	end
	local remotes = ClientRemotes.waitReady()
	local folderInst = remotes:WaitForChild(folder) :: Instance
	local event = folderInst:WaitForChild(name) :: RemoteEvent
	cache[key] = event
	return event
end

return ClientRemotes
