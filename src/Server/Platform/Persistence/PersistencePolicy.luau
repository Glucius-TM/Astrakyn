--!strict

-- ASTRAKYN persistence policy. These values define our safety cadence; they are not Roblox quota formulas.
-- Renew and autosave remain well inside expiry, and per-user jitter is applied by DataService.
local PersistencePolicy = {
	LEASE_SECONDS = 180,
	LEASE_RENEW_SECONDS = 60,
	AUTOSAVE_SECONDS = 45,
	MAINTENANCE_TICK_SECONDS = 5,
	RETRY_ATTEMPTS = 3,
	READ_BACKOFF_SECONDS = 0.35,
	WRITE_BACKOFF_SECONDS = 0.4,
	FLUSH_WAIT_SECONDS = 8,
}

assert(
	PersistencePolicy.LEASE_RENEW_SECONDS < PersistencePolicy.LEASE_SECONDS,
	"lease renew cadence must be shorter than lease duration"
)
assert(
	PersistencePolicy.AUTOSAVE_SECONDS < PersistencePolicy.LEASE_SECONDS,
	"autosave cadence must be shorter than lease duration"
)
assert(
	PersistencePolicy.MAINTENANCE_TICK_SECONDS < PersistencePolicy.LEASE_RENEW_SECONDS,
	"maintenance tick must be shorter than lease renew cadence"
)

return table.freeze(PersistencePolicy)
