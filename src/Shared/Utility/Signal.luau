--!strict

local Signal = {}

export type Connection = {
	Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Fire: (self: Signal<T...>, T...) -> (),
}

function Signal.new<T...>(): Signal<T...>
	local listeners: { (T...) -> () } = {}

	local signal = {} :: Signal<T...>

	function signal.Connect(_self: Signal<T...>, callback: (T...) -> ()): Connection
		table.insert(listeners, callback)
		return {
			Disconnect = function(_connection: Connection)
				local index = table.find(listeners, callback)
				if index then
					table.remove(listeners, index)
				end
			end,
		}
	end

	function signal.Fire(_self: Signal<T...>, ...: T...)
		for _, callback in listeners do
			callback(...)
		end
	end

	return signal
end

return Signal
