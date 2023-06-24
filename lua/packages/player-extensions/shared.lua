install( "packages/glua-extensions", "https://github.com/Pika-Software/glua-extensions" )
install( "packages/nw3-vars", "https://github.com/Pika-Software/nw3-vars" )

do

    local PLAYER = FindMetaTable( "Player" )

    -- Nickname
    PLAYER.SourceNick = PLAYER.SourceNick or PLAYER.Nick

    function PLAYER:Nick()
        local sourceNick = PLAYER.SourceNick( self )
        return self:GetNW2String( "nickname", #sourceNick == 0 and "unknown player" or sourceNick )
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

end

do

    local ENTITY = FindMetaTable( "Entity" )

    -- Entity:GetPlayerColor()
    function ENTITY:GetPlayerColor()
        return self:GetNW2Vector( "player-color" )
    end

    -- Entity:SetPlayerColor( vector )
    function ENTITY:SetPlayerColor( vector )
        self:SetNW2Vector( "player-color", vector )
    end

    -- Entity:GetCreator()
    do

        local player_GetBySteamID64 = player.GetBySteamID64
        local string_sub = string.sub
        local tonumber = tonumber
        local Entity = Entity
        local NULL = NULL

        function ENTITY:GetCreator()
            local id = self:GetNW2String( "entity-owner", false )
            if not id then
                return NULL
            end

            if string_sub( id, 1, 1 ) == "e" then
                local index = tonumber( string_sub( id, 2, #id ) )
                if not index then
                    return NULL
                end

                return Entity( index )
            end

            return player_GetBySteamID64( id )
        end

    end

end