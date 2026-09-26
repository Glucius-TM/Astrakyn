--!strict

export type RefreshGate = {
	gate: (key: string, sig: string, paint: () -> ()) -> (),
	clear: (key: string?) -> (),
}

local WindowRefresh = {}

function WindowRefresh.new(): RefreshGate
	local last: { [string]: string } = {}
	return {
		gate = function(key: string, sig: string, paint: () -> ())
			if last[key] == sig then
				return
			end
			paint()
			last[key] = sig
		end,
		clear = function(key: string?)
			if key == nil then
				table.clear(last)
			else
				last[key] = nil
			end
		end,
	}
end

return WindowRefresh
