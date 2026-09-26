--!strict

-- Shared assert surface for domain specs. Bootstrap builds the live table.

export type Harness = {
	assert: (cond: unknown, message: string) -> (),
	assertEqual: <T>(actual: T, expected: T, message: string) -> (),
	assertClose: (actual: number, expected: number, epsilon: number, message: string) -> (),
}

return {}
