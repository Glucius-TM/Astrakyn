--!strict
-- Social panels facade: Roster, Mail, Trade, Inspect.

local Inspect = require(script.Parent.Inspect.Inspect)
local Mail = require(script.Parent.Mail.Mail)
local Roster = require(script.Parent.Roster.Roster)
local Trade = require(script.Parent.Trade.Trade)
local WindowHost = require(script.Parent.Parent.Parent.Runtime.Windows.WindowHost)

local Social = {
	socialSig = Roster.sig,
	mailSig = Mail.sig,
	sendMailPayload = Mail.sendMailPayload,
	inspectIdentityLines = Inspect.identityLines,
	inspectSig = Inspect.sig,
	tradeSig = Trade.sig,
}

function Social.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	return WindowHost.combine({
		Roster.mount(host),
		Mail.mount(host),
		Trade.mount(host),
		Inspect.mount(host),
	})
end

return Social
