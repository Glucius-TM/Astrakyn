--!strict

-- Untrusted serialized data. Narrow to domain types only after Schema / ProfileValidator.

export type JsonPrimitive = nil | boolean | number | string

export type JsonValue = JsonPrimitive | JsonArray | JsonObject

export type JsonArray = { JsonValue }

export type JsonObject = { [string]: JsonValue }

export type JsonTable = { [string | number]: JsonValue }

export type LogContext = { [string]: string }

return {}
