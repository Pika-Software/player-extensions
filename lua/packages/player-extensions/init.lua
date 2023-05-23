require( "packages/glua-extensions", "https://github.com/Pika-Software/glua-extensions" )

local packageName = gpm.Package:GetIdentifier()
local ArgAssert = ArgAssert
local logger = gpm.Logger
local hook = hook

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

    -- Nickname
    function PLAYER:SetNick( name )
        ArgAssert( name, 1, "string" )
        self:SetNW2String( "name", name )
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

end