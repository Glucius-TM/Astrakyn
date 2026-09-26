--!strict

export type RemoteDirection = "ClientToServer" | "ServerToClient" | "Bidirectional"

export type ErrorPolicy = "Silent" | "Reject" | "Kick" | "Flag"

export type RemoteDefinition = {
	Id: string,
	Folder: string,
	Direction: RemoteDirection,
	RateLimitPerSecond: number,
	Permissions: string,
	Logging: boolean,
	ErrorPolicy: ErrorPolicy,
	PayloadKeys: { string },
	ForbiddenKeys: { string },
	Deferred: boolean,
}

return {}
