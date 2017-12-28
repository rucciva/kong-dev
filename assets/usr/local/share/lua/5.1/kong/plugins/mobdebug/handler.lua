package.path = package.path .. ";" .. os.getenv("MOBDEBUG_ADD_LUA_PATH")
package.cpath = package.cpath .. ";" .. os.getenv("MOBDEBUG_ADD_LUA_CPATH")
local debug_server = os.getenv("MOBDEBUG_SERVER")
local debug_context = os.getenv("MOBDEBUG_CONTEXT")

local BasePlugin = require "kong.plugins.base_plugin"

function startDebugIfContextMatch(ctxCur)
    local ctx = debug_context
    local serv = debug_server
    if ctx == nil or ctx == "" then
        ctx = "access"
    end
    if ctx == ctxCur then
        require('mobdebug').start(serv)
    end
end

local MobdebugPlugin = BasePlugin:extend()

function MobdebugPlugin:new()
    MobdebugPlugin.super.new(self, "mobdebug")
    startDebugIfContextMatch("new")
end

function MobdebugPlugin:init_worker(conf)
    MobdebugPlugin.super.init_worker(self)
    startDebugIfContextMatch("init_worker")
end

function MobdebugPlugin:certificate(conf)
    MobdebugPlugin.super.certificate(self)
    startDebugIfContextMatch("certificate")
end

function MobdebugPlugin:rewrite(conf)
    MobdebugPlugin.super.rewrite(self)
    startDebugIfContextMatch("rewrite")
end

function MobdebugPlugin:access(conf)
    MobdebugPlugin.super.access(self)
    startDebugIfContextMatch("access")
end

function MobdebugPlugin:header_filter(conf)
    MobdebugPlugin.super.header_filter(self)
    startDebugIfContextMatch("header_filter")
end

function MobdebugPlugin:body_filter(conf)
    MobdebugPlugin.super.body_filter(self)
    startDebugIfContextMatch("body_filter")
end

function MobdebugPlugin:log(conf)
    MobdebugPlugin.super.log(self)
    startDebugIfContextMatch("log")
end

MobdebugPlugin.PRIORITY = 100000

return MobdebugPlugin