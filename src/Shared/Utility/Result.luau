--!strict

local Result = {}

export type OkResult<T> = {
	Ok: true,
	Value: T,
	Error: nil,
}

export type ErrResult = {
	Ok: false,
	Value: nil,
	Error: string,
}

export type Result<T> = OkResult<T> | ErrResult

function Result.ok<T>(value: T): Result<T>
	return { Ok = true, Value = value, Error = nil }
end

function Result.err(message: string): ErrResult
	return { Ok = false, Value = nil, Error = message }
end

-- New solver loses ErrResult when returning a narrowed `Result<T>` (`Ok == false` intersection).
function Result.errOf<T>(result: Result<T>): ErrResult
	local message = result.Error
	if typeof(message) == "string" then
		return Result.err(message)
	end
	return Result.err("failed")
end

return Result
