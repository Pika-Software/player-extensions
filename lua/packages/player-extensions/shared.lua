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

        local player_GetByUniqueID2 = player.GetByUniqueID2

        function ENTITY:GetCreator()
            local uid = self:GetNW2String( "entity-owner" )
            if not uid then return end
            return player_GetByUniqueID2( uid )
        end

    end

end