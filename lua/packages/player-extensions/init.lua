
install( "packages/glua-extensions", "https://github.com/Pika-Software/glua-extensions" )
install( "packages/nw3-vars", "https://github.com/Pika-Software/nw3-vars" )

local packageName = gpm.Package:GetIdentifier()
local logger = gpm.Logger

if CLIENT then

    local select = select
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

    hook.Add( "EntityNetworkedVarChanged", packageName, function( ply, key, _, value )
        if not ply:IsPlayer() then return end

        local func = actions[ key ]
        if not func then return end
        func( ply, value )

        logger:Debug( "Key '%s' is synchronized with '%s (%s)'", key, ply:Nick(), ply:SteamID() )
    end )

end

local PLAYER = FindMetaTable( "Player" )

-- Nickname
PLAYER.SourceNick = PLAYER.SourceNick or PLAYER.Nick

function PLAYER:Nick()
    return self:GetNW2String( "name", PLAYER.SourceNick( self ) )
end

PLAYER.GetName = PLAYER.Nick
PLAYER.Name = PLAYER.Nick

-- Player:TimeConnected()
do

    local SysTime = SysTime

    function PLAYER:TimeConnected()
        local time = SysTime()
        return time - self:GetNW3Var( "time-connected", time )
    end

end

-- Player:TimePlayed()
function PLAYER:TimePlayed()
    return PLAYER.TimeConnected( self ) + self:GetNW3Var( "time-played", 0 )
end

local ENTITY = FindMetaTable( "Entity" )

-- Entity:GetPlayerColor()
function ENTITY:GetPlayerColor()
    return self:GetNW2Vector( "player-color" )
end

-- Entity:SetPlayerColor( vector )
function ENTITY:SetPlayerColor( vector )
    self:SetNW2Vector( "player-color", vector )
end

if SERVER then
    include( "server.lua" )
end
