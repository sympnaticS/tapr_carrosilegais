Config                            = {}
Config.DrawDistance               = 100.0
Config.MarkerColor                = { r = 120, g = 120, b = 240 }
Config.EnablePlayerManagement     = false -- ativa o trabalho com tag - esx_addonaccount necessario, esx_billing necessario e esx_society necessario
Config.EnableOwnedVehicles        = true
Config.EnableSocietyOwnedVehicles = false -- usem com EnablePlayerManagement desativado, ou então não vai fazer efeito
Config.ResellPercentage           = 65
Config.Locale                     = 'pt'

-- Do genero: 'LLL NNN'
-- O numero maxido matricula é 8 caracaters (incluindo espaços & simbolos), não passem disso!
Config.PlateLetters  = 4
Config.PlateNumbers  = 4
Config.PlateUseSpace = false

Config.Zones = {

	ShopEntering = { -- blip para comprar carros
		Pos   = { x = -1244.77, y = -3006.87, z = -43.89 },
		Size  = { x = 1.5, y = 1.5, z = 1.0 },
		Type  = 1,
	},

	ShopInside = { -- entrada blip para o sitio dos carros 
		Pos     = { x = -1267.0, y = -3013.28, z = -49.49 },
		Size    = { x = 1.5, y = 1.5, z = 1.0 },
		Heading = 355.0,
		Type    = -1,
	},

	ShopOutside = { -- spawn dos carros depois de comprar
		Pos     = { x = -1372.28, y = -3228.9, z = 12.33 },
		Size    = { x = 1.5, y = 1.5, z = 1.0 },
		Heading = 330.0,
		Type    = -1,
	},

	BossActions = { -- não funciona sem o " Config.EnablePlayerManagement " ativado.
		Pos   = { x = -31240.1, y = -3001.81, z = -43.87 },
		Size  = { x = 1.5, y = 1.5, z = 1.0 },
		Type  = -1,
	},

	GiveBackVehicle = {
		Pos   = { x = -1348.7, y = -3188.02, z = 12.33 },
		Size  = { x = 7.0, y = 7.0, z = 4.0 },
		Type  = (Config.EnablePlayerManagement and 1 or -1),
	},

	ResellVehicle = { -- vender veiculo metade do preço
		Pos   = { x = -1325.93, y = -3149.3, z = 12.33 },
		Size  = { x = 7.0, y = 7.0, z = 4.0 },
		Type  = 1,
	}

}
