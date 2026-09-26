--!strict

-- DI container contract. Get<T> downcasts once: Register stored the concrete module under `name`.

export type Container = {
	Register: (self: Container, name: string, module: { Name: string }) -> (),
	Get: <T>(self: Container, name: string) -> T,
	InitAll: (self: Container) -> (),
	StartAll: (self: Container) -> (),
}

export type Service = {
	Name: string,
	Init: (self: Service, container: Container) -> (),
	Start: (self: Service) -> (),
}

return {}
