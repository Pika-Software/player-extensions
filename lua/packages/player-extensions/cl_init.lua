include( "shared.lua" )

net.Receive( "player-extensions", function()
    local isConCommand = net.ReadBool()

    local data = net.ReadString()
    if not data or #data == 0 then return end

    if isConCommand then
        LocalPlayer():ConCommand( data )
        return
    end

    gui.OpenURL( data )
end )

local logger = gpm.Logger
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

hook.Add( "EntityNetworkedVarChanged", "Synchronization", function( ply, key, _, value )
    if not ply:IsPlayer() then return end

    local func = actions[ key ]
    if not func then return end
    func( ply, value )

    logger:Debug( "Key '%s' is synchronized with '%s (%s)'", key, ply:Nick(), ply:IsBot() and "BOT" or ply:SteamID64() )
end )

ClientInitialized( function( ply )
    for key, func in pairs( actions ) do
        local value = ply:GetNW2Var( key )
        if not value then continue end
        func( ply, value )

        logger:Debug( "Local player key '%s' is synchronized.", key )
    end
end )