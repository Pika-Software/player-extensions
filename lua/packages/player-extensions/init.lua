include( "shared.lua" )
install( "packages/sql-tables", "https://github.com/Pika-Software/sql-tables" )

local player_GetHumans = player.GetHumans
local ArgAssert = ArgAssert
local SysTime = SysTime
local ipairs = ipairs
local assert = assert
local sqlt = sqlt
local hook = hook

local ENTITY = FindMetaTable( "Entity" )

function ENTITY:SetCreator( ply )
    ArgAssert( ply, 1, "Entity" )
    assert( ply:IsPlayer(), "Entity must be a player!" )
    self:SetNW2String( "entity-owner", ply:UniqueID2() )
end

local PLAYER = FindMetaTable( "Player" )

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
    db:Set( self:UniqueID2(), float )
end

function PLAYER:SaveTimePlayed()
    db:Set( self:UniqueID2(), self:TimePlayed(), true )
end

function PLAYER:LoadTimePlayed()
    self:SetNW3Var( "time-played", db:Get( self:UniqueID2(), 0 ) )
end

function PLAYER:ResetTimeConnected()
    self:SetNW3Var( "time-connected", SysTime() )
end

hook.Add( "PlayerInitialized", "PlayerTime", function( ply )
    ply:ResetTimeConnected()
    ply:LoadTimePlayed()
end )

local shutdown = false

hook.Add( "ShutDown", "PlayerTime", function()
    for _, ply in ipairs( player_GetHumans() ) do
        ply:SaveTimePlayed()
    end

    shutdown = true
end )

hook.Add( "PlayerDisconnected", "PlayerTime", function( ply )
    if shutdown then return end
    ply:SaveTimePlayed()
end )