install( "packages/nw3-vars.lua", "https://raw.githubusercontent.com/Pika-Software/nw3-vars/main/lua/packages/nw3-vars.lua" )
install( "packages/glua-extensions", "https://github.com/Pika-Software/glua-extensions" )

local ENTITY = FindMetaTable( "Entity" )

do

    local PLAYER = FindMetaTable( "Player" )

    -- Nickname
    PLAYER.SourceNick = PLAYER.SourceNick or PLAYER.Nick

    function PLAYER:Nick()
        local sourceNick = PLAYER.SourceNick( self )
        return ENTITY.GetNW2Var( self, "nickname", #sourceNick == 0 and "unknown player" or sourceNick )
    end

    PLAYER.GetName = PLAYER.Nick
    PLAYER.Name = PLAYER.Nick

    -- Player:TimeConnected()
    do

        local SysTime = SysTime

        function PLAYER:TimeConnected()
            local time = SysTime()
            return time - ENTITY.GetNW3Var( self, "time-connected", time )
        end

    end

    -- Player:TimePlayed()
    function PLAYER:TimePlayed()
        return PLAYER.TimeConnected( self ) + ENTITY.GetNW3Var( self, "time-played", 0 )
    end

end

-- Entity:GetPlayerColor()
do
    local defaultColor = Vector( 0.25, 0.35, 0.4 )
    function ENTITY:GetPlayerColor()
        return ENTITY.GetNW2Var( self, "player-color", defaultColor )
    end
end

-- Entity:SetPlayerColor( vector )
function ENTITY:SetPlayerColor( vector )
    ENTITY.SetNW2Var( self, "player-color", vector )
end

-- Entity:GetCreator()
do

    local player_GetByUniqueID2 = player.GetByUniqueID2
    local NULL = NULL

    function ENTITY:GetCreator()
        local uid = ENTITY.GetNW2Var( self, "entity-owner" )
        if not uid then return NULL end

        local ply = player_GetByUniqueID2( uid )
        if not ply then return NULL end
        return ply
    end

end