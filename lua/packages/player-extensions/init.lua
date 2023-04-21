import( gpm.LuaPackageExists( "packages/glua-extensions" ) and "packages/glua-extensions" or "https://raw.githubusercontent.com/Pika-Software/glua-extensions/main/package.json" )
import( gpm.LuaPackageExists( "packages/nw3-vars" ) and "packages/nw3-vars" or "https://raw.githubusercontent.com/Pika-Software/nw3-vars/master/package.json" )

local packageName = gpm.Package:GetIdentifier()
local ArgAssert = ArgAssert
local IsValid = IsValid
local hook = hook

if CLIENT then

    local Player = Player
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

    local function init( ply )
        ply:SetNW3VarProxy( function( self, key, value )
            local func = actions[ key ]
            if not func then return end

            local ply = self:GetIdentifier()
            if not IsValid( ply ) then return end
            func( ply, value )
        end )
    end

    hook.Add( "PlayerInitialized", packageName, init )

    gameevent.Listen( "player_info" )

    hook.Add( "player_info", packageName, function( data )
        local ply = Player( data.userid )
        if not IsValid( ply ) then return end
        init( ply )
    end )

end

local PLAYER = FindMetaTable( "Player" )

-- Nickname
PLAYER.SourceNick = PLAYER.SourceNick or PLAYER.Nick

function PLAYER:Nick()
    return self:GetNW3Var( "name", PLAYER.SourceNick( self ) )
end

PLAYER.GetName = PLAYER.Nick
PLAYER.Name = PLAYER.Nick

if SERVER then

    local ENTITY = FindMetaTable( "Entity" )

    -- Nickname
    function PLAYER:SetNick( name )
        ArgAssert( name, 1, "string" )
        self:SetNW3Var( "name", name )
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
        self:SetNW3Var( "move-type", moveType )
        ENTITY.SetMoveType( self, moveType )
    end

    function PLAYER:SetMoveCollide( moveCollideType )
        self:SetNW3Var( "move-collide-type", moveCollideType )
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

        self:SetNW3Var( "duck-hull-mins", mins )
        self:SetNW3Var( "duck-hull-maxs", maxs )
    end

    function PLAYER:SetHull( mins, maxs, onlyServer )
        ArgAssert( mins, 1, "Vector" )
        ArgAssert( maxs, 2, "Vector" )

        PLAYER.__SetHull( self, mins, maxs )
        if onlyServer then return end

        self:SetNW3Var( "hull-mins", mins )
        self:SetNW3Var( "hull-maxs", maxs )
    end

end
