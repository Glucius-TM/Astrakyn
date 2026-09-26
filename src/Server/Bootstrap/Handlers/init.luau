--!strict

local BootstrapContext = require(script.Parent.BootstrapContext)

local CharacterHandlers = require(script.CharacterHandlers)
local CombatHandlers = require(script.CombatHandlers)
local GuildHandlers = require(script.GuildHandlers)
local InstanceHandlers = require(script.InstanceHandlers)
local ItemHandlers = require(script.ItemHandlers)
local ProgressionHandlers = require(script.ProgressionHandlers)
local PvPHandlers = require(script.PvPHandlers)
local SocialHandlers = require(script.SocialHandlers)
local WorldHandlers = require(script.WorldHandlers)

type Context = BootstrapContext.Context

local Handlers = {}

function Handlers.registerAll(ctx: Context)
	CharacterHandlers.register(ctx)
	CombatHandlers.register(ctx)
	GuildHandlers.register(ctx)
	InstanceHandlers.register(ctx)
	ItemHandlers.register(ctx)
	ProgressionHandlers.register(ctx)
	PvPHandlers.register(ctx)
	SocialHandlers.register(ctx)
	WorldHandlers.register(ctx)
end

return Handlers
