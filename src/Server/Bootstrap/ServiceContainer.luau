--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local Logger = require(script.Parent.Parent.Platform.Observability.Logger)

type Container = ContainerTypes.Container
type Service = ContainerTypes.Service

type Impl = {
	_services: { [string]: Service },
	_order: { string },
	Register: (self: Impl, name: string, module: { Name: string }) -> (),
	Get: <T>(self: Impl, name: string) -> T,
	InitAll: (self: Impl) -> (),
	StartAll: (self: Impl) -> (),
}

local ServiceContainer = {}
ServiceContainer._services = {} :: { [string]: Service }
ServiceContainer._order = {} :: { string }

function ServiceContainer.Register(self: Impl, name: string, module: { Name: string })
	if name ~= module.Name then
		error(`service name mismatch '{name}' vs '{module.Name}'`)
	end
	if self._services[name] then
		error(`duplicate service '{name}'`)
	end
	-- Register door: caller hands a named module; Init/Start are invoked by this container only.
	self._services[name] = module :: Service
	table.insert(self._order, name)
end

function ServiceContainer.Get<T>(self: Impl, name: string): T
	local service = self._services[name]
	if service == nil then
		error(`unknown service '{name}'`)
	end
	-- Register stored this module under `name`; callers request that module's type.
	return (service :: unknown) :: T
end

function ServiceContainer.InitAll(self: Impl)
	for _, name in self._order do
		local service = self._services[name]
		if service then
			service:Init(self :: Container)
		end
	end
end

function ServiceContainer.StartAll(self: Impl)
	for _, name in self._order do
		local service = self._services[name]
		if service then
			local ok, err = pcall(function()
				service:Start()
			end)
			if not ok then
				Logger.error(`Start {name} failed`, { err = tostring(err) })
			end
		end
	end
end

return ServiceContainer
