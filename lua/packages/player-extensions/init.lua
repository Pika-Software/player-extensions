import( file.Exists( "packages/glua-extensions/package.lua", gpm.LuaRealm ) and "packages/glua-extensions" or "https://raw.githubusercontent.com/Pika-Software/glua-extensions/main/package.json" )
import( file.Exists( "packages/net-messager/package.lua", gpm.LuaRealm ) and "packages/net-messager" or "https://raw.githubusercontent.com/Pika-Software/net-messager/main/package.json" )

local packageName = gpm.Package:GetIdentifier()
local ArgAssert = ArgAssert
local IsValid = IsValid
local hook = hook

local playerData = net.Messager( "source-player" )

if CLIENT then

    gameevent.Listen( "player_info" )

    local actions = {
        ["duck-hull-mins"] = function( ply, mins )
            ply:SetHullDuck( mins, select( -1, ply:GetHullDuck() ) )
        end,
        ["duck-hull-maxs"] = function( ply, maxs )
            ply:SetHullDuck( ply:GetHullDuck(), maxs )
        end,
        ["hull-mins"] = function( ply, mins )
            ply:SetHull( mins, select( -1, ply:GetHull() ) )
        end,
        ["hull-maxs"] = function( ply, maxs )
            ply:SetHull( ply:GetHull(), maxs )
        end,
        ["move-type"] = function( ply, moveType )
            ply:SetMoveType( moveType )
        end,
        ["move-collide-type"] = function( ply, moveCollideType )
            ply:SetMoveCollide( moveCollideType )
        end
    }

    hook.Add( "player_info", packageName, function( data )
        local ply = Player( data.userid )
        if not IsValid( ply ) then return end

        local sync = playerData:CreateSync( ply )
        sync:AddCallback( function( self, key, value )
            local func = actions[ key ]
            if not func then return end

            local ply = self:GetIdentifier()
            if not IsValid( ply ) then return end
            func( ply, value )
        end )
    end )

    hook.Add( "PlayerInitialized", packageName, function( ply )
        local sync = playerData:CreateSync( ply )
        sync:AddCallback( function( self, key, value )
            local func = actions[ key ]
            if not func then return end

            local ply = self:GetIdentifier()
            if not IsValid( ply ) then return end
            func( ply, value )
        end )
    end )

end

local PLAYER = FindMetaTable( "Player" )

-- Nickname
PLAYER.SourceNick = PLAYER.SourceNick or PLAYER.Nick

function PLAYER:Nick()
    local realName = PLAYER.SourceNick( self )

    local sync = playerData:GetSync( self )
    if sync then return sync:Get( "name", realName ) end

    return realName
end

PLAYER.GetName = PLAYER.Nick
PLAYER.Name = PLAYER.Nick

if SERVER then

    local ENTITY = FindMetaTable( "Entity" )

    -- Nickname
    function PLAYER:SetNick( name )
        ArgAssert( name, 1, "string" )
        local sync = playerData:CreateSync( self )
        sync:Set( "name", name )
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

    hook.Add( "PlayerInitialized", packageName, function( ply )
        playerData:CreateSync( ply )
        playerData:Sync( ply )
    end )

    hook.Add( "PlayerDisconnected", packageName, function( ply )
        local sync = playerData:GetSync( ply )
        if not sync then return end
        sync:Destroy()
    end )

    -- Player Move
    function PLAYER:SetMoveType( moveType )
        local sync = playerData:CreateSync( self )
        if not sync then return end
        sync:Set( "move-type", moveType )
        ENTITY.SetMoveType( self, moveType )
    end

    function PLAYER:SetMoveCollide( moveCollideType )
        local sync = playerData:CreateSync( self )
        if not sync then return end
        sync:Set( "move-collide-type", moveCollideType )
        ENTITY.SetMoveCollide( self, moveCollideType )
    end

    -- Players Hulls
    PLAYER.__SetHullDuck = PLAYER.__SetHullDuck or PLAYER.SetHullDuck
    PLAYER.__SetHull = PLAYER.__SetHull or PLAYER.SetHull

    function PLAYER:SetHullDuck( mins, maxs, onlyServer )
        ArgAssert( mins, 1, "Vector" )
        ArgAssert( maxs, 2, "Vector" )

        PLAYER.__SetHullDuck( self, mins, maxs )
        if onlyServer then return end

        local sync = playerData:CreateSync( self )
        if not sync then return end

        sync:Set( "duck-hull-mins", mins )
        sync:Set( "duck-hull-maxs", maxs )
    end

    function PLAYER:SetHull( mins, maxs, onlyServer )
        ArgAssert( mins, 1, "Vector" )
        ArgAssert( maxs, 2, "Vector" )

        PLAYER.__SetHull( self, mins, maxs )
        if onlyServer then return end

        local sync = playerData:CreateSync( self )
        if not sync then return end

        sync:Set( "hull-mins", mins )
        sync:Set( "hull-maxs", maxs )
    end

end