
install( "packages/sql-tables", "https://github.com/Pika-Software/sql-tables" )

local packageName = gpm.Package:GetIdentifier()
local player_GetHumans = player.GetHumans
local ArgAssert = ArgAssert
local ipairs = ipairs
local sqlt = sqlt
local hook = hook

local PLAYER = FindMetaTable( "Player" )
local ENTITY = FindMetaTable( "Entity" )

function ENTITY:SetCreator( ply )
    ArgAssert( ply, 1, "Entity" )
    if not ply:IsPlayer() or ply:IsBot() then
        self:SetNW2String( "entity-owner", "e" .. ent:EntIndex() )
        return
    end

    self:SetNW2String( "entity-owner", ply:SteamID() )
end

-- Nickname
function PLAYER:SetNick( nickname )
    ArgAssert( nickname, 1, "string" )
    self:SetNW2String( "nickname", nickname )
end

-- Map Name
PLAYER.GetMapName = ENTITY.GetName

-- Player Model
do

    local util_IsValidModel = util.IsValidModel
    local assert = assert

    function PLAYER:SetModel( model )
        ArgAssert( model, 1, "string" )
        assert( util_IsValidModel( model ), "Model must be valid!" )

        local result = hook.Run( "OnPlayerModelChange", self, model )
        if result == false then
            model = self:GetModel()
        elseif type( result ) == "string" then
            model = result
        end

        ENTITY.SetModel( self, model )
        hook.Run( "PlayerModelChanged", self, model )
    end

end

-- Player Move
function PLAYER:SetMoveType( moveType )
    self:SetNW2Int( "move-type", moveType )
    ENTITY.SetMoveType( self, moveType )
end

function PLAYER:SetMoveCollide( moveCollideType )
    self:SetNW2Int( "move-collide-type", moveCollideType )
    ENTITY.SetMoveCollide( self, moveCollideType )
end

-- Players Hulls
PLAYER.SetHullDuckOnServer = PLAYER.SetHullDuckOnServer or PLAYER.SetHullDuck
PLAYER.SetHullOnServer = PLAYER.SetHullOnServer or PLAYER.SetHull

function PLAYER:SetHullDuck( mins, maxs, onlyServer )
    ArgAssert( mins, 1, "Vector" )
    ArgAssert( maxs, 2, "Vector" )

    PLAYER.SetHullDuckOnServer( self, mins, maxs )
    if onlyServer then return end

    self:SetNW2Vector( "duck-hull-mins", mins )
    self:SetNW2Vector( "duck-hull-maxs", maxs )
end

function PLAYER:SetHull( mins, maxs, onlyServer )
    ArgAssert( mins, 1, "Vector" )
    ArgAssert( maxs, 2, "Vector" )

    PLAYER.SetHullOnServer( self, mins, maxs )
    if onlyServer then return end

    self:SetNW2Vector( "hull-mins", mins )
    self:SetNW2Vector( "hull-maxs", maxs )
end

local db = sqlt.Create( "time-played" )

function PLAYER:SetTimePlayed( float )
    self:SetNW3Var( "time-played", float )
    if self:IsBot() then return end
    db:Set( self:SteamID(), float )
end

hook.Add( "PlayerInitialSpawn", packageName, function( ply )
    ply:SetNW3Var( "time-connected", SysTime() )
    if ply:IsBot() then return end
    ply:SetNW3Var( "time-played", db:Get( ply:SteamID(), 0 ) )
end )

hook.Add( "PlayerInitialized", packageName, function( ply )
    ply:SetNW3Var( "time-connected", SysTime() )
end )

local shutdown = false

hook.Add( "ShutDown", packageName, function()
    for _, ply in ipairs( player_GetHumans() ) do
        db:Set( ply:SteamID(), ply:TimePlayed(), true )
    end

    shutdown = true
end )

hook.Add( "PlayerDisconnected", packageName, function( ply )
    if shutdown or ply:IsBot() then return end
    db:Set( ply:SteamID(), ply:TimePlayed(), true )
end )
