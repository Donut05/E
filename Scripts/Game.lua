dofile "$CONTENT_DATA/Scripts/SurvivalGame.lua"

Game = class( SurvivalGame )

function Game.server_onCreate( self )
    SurvivalGame.server_onCreate( self )
	print("Game.server_onCreate")
end
