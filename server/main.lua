ESX              = nil
local Categories = {}
local Vehicles   = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

TriggerEvent('esx_phone:registerNumber', 'ilegais', _U('dealer_customers'), false, false)
TriggerEvent('esx_society:registerSociety', 'ilegais', _U('car_dealer'), 'society_carrosilegais', 'society_carrosilegais', 'society_carrosilegais', {type = 'private'})

function RemoveOwnedVehicle(plate)
	MySQL.Async.execute('DELETE FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	})
end

MySQL.ready(function()
	Categories     = MySQL.Sync.fetchAll('SELECT * FROM ilegais_categories')
	local vehicles = MySQL.Sync.fetchAll('SELECT * FROM carrosilegais')

	for i=1, #vehicles, 1 do
		local vehicle = vehicles[i]

		for j=1, #Categories, 1 do
			if Categories[j].name == vehicle.category then
				vehicle.categoryLabel = Categories[j].label
				break
			end
		end

		table.insert(Vehicles, vehicle)
	end

	-- send information after db has loaded, making sure everyone gets vehicle information
	TriggerClientEvent('tapr_carrosilegais:sendCategories', -1, Categories)
	TriggerClientEvent('tapr_carrosilegais:sendVehicles', -1, Vehicles)
end)

RegisterServerEvent('tapr_carrosilegais:setVehicleOwned')
AddEventHandler('tapr_carrosilegais:setVehicleOwned', function (vehicleProps)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)',
	{
		['@owner']   = xPlayer.identifier,
		['@plate']   = vehicleProps.plate,
		['@vehicle'] = json.encode(vehicleProps)
	}, function (rowsChanged)
		TriggerClientEvent('esx:showNotification', _source, _U('vehicle_belongs', vehicleProps.plate))
	end)
end)

RegisterServerEvent('tapr_carrosilegais:setVehicleOwnedPlayerId')
AddEventHandler('tapr_carrosilegais:setVehicleOwnedPlayerId', function (playerId, vehicleProps)
	local xPlayer = ESX.GetPlayerFromId(playerId)

	MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)',
	{
		['@owner']   = xPlayer.identifier,
		['@plate']   = vehicleProps.plate,
		['@vehicle'] = json.encode(vehicleProps)
	}, function (rowsChanged)
		TriggerClientEvent('esx:showNotification', playerId, _U('vehicle_belongs', vehicleProps.plate))
	end) 
end)

RegisterServerEvent('tapr_carrosilegais:setVehicleOwnedSociety')
AddEventHandler('tapr_carrosilegais:setVehicleOwnedSociety', function (society, vehicleProps)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)',
	{
		['@owner']   = 'society:' .. society,
		['@plate']   = vehicleProps.plate,
		['@vehicle'] = json.encode(vehicleProps),
	}, function (rowsChanged)

	end)
end)

RegisterServerEvent('tapr_carrosilegais:sellVehicle')
AddEventHandler('tapr_carrosilegais:sellVehicle', function (vehicle)
	MySQL.Async.fetchAll('SELECT * FROM ilegais_vehicles WHERE vehicle = @vehicle LIMIT 1', {
		['@vehicle'] = vehicle
	}, function (result)
		local id = result[1].id

		MySQL.Async.execute('DELETE FROM ilegais_vehicles WHERE id = @id', {
			['@id'] = id
		})
	end)
end)

RegisterServerEvent('tapr_carrosilegais:addToList')
AddEventHandler('tapr_carrosilegais:addToList', function(target, model, plate)
	local xPlayer, xTarget = ESX.GetPlayerFromId(source), ESX.GetPlayerFromId(target)
	local dateNow = os.date('%Y-%m-%d %H:%M')

	if xPlayer.job.name ~= 'ilegais' then
		print(('tapr_carrosilegais: %s attempted to add a sold vehicle to list!'):format(xPlayer.identifier))
		return
	end

	MySQL.Async.execute('INSERT INTO vehicle_sold (client, model, plate, soldby, date) VALUES (@client, @model, @plate, @soldby, @date)', {
		['@client'] = xTarget.getName(),
		['@model'] = model,
		['@plate'] = plate,
		['@soldby'] = xPlayer.getName(),
		['@date'] = dateNow
	})
end)
	-- Edits by Chip W
ESX.RegisterServerCallback('tapr_carrosilegais:getSoldVehicles', function (source, cb)

	MySQL.Async.fetchAll('SELECT * FROM vehicle_sold', {}, function(result)
		cb(result)
	end)
end)

RegisterServerEvent('tapr_carrosilegais:rentVehicle')
AddEventHandler('tapr_carrosilegais:rentVehicle', function (vehicle, plate, playerName, basePrice, rentPrice, target)
	local xPlayer = ESX.GetPlayerFromId(target)

	MySQL.Async.fetchAll('SELECT * FROM ilegais_vehicles WHERE vehicle = @vehicle LIMIT 1', {
		['@vehicle'] = vehicle
	}, function (result)
		local id    = result[1].id
		local price = result[1].price
		local owner = xPlayer.identifier

		MySQL.Async.execute('DELETE FROM ilegais_vehicles WHERE id = @id', {
			['@id'] = id
		})

		MySQL.Async.execute('INSERT INTO ilegaisalugados_vehicles (vehicle, plate, player_name, base_price, rent_price, owner) VALUES (@vehicle, @plate, @player_name, @base_price, @rent_price, @owner)',
		{
			['@vehicle']     = vehicle,
			['@plate']       = plate,
			['@player_name'] = playerName,
			['@base_price']  = basePrice,
			['@rent_price']  = rentPrice,
			['@owner']       = owner
		})
	end)
end)

RegisterServerEvent('tapr_carrosilegais:getStockItem')
AddEventHandler('tapr_carrosilegais:getStockItem', function (itemName, count)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local sourceItem = xPlayer.getInventoryItem(itemName)

	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_carrosilegais', function (inventory)
		local item = inventory.getItem(itemName)

		-- is there enough in the society?
		if count > 0 and item.count >= count then
		
			-- can the player carry the said amount of x item?
			if sourceItem.limit ~= -1 and (sourceItem.count + count) > sourceItem.limit then
				TriggerClientEvent('esx:showNotification', _source, _U('player_cannot_hold'))
			else
				inventory.removeItem(itemName, count)
				xPlayer.addInventoryItem(itemName, count)
				TriggerClientEvent('esx:showNotification', _source, _U('have_withdrawn', count, item.label))
			end
		else
			TriggerClientEvent('esx:showNotification', _source, _U('not_enough_in_society'))
		end
	end)
end)

RegisterServerEvent('tapr_carrosilegais:putStockItems')
AddEventHandler('tapr_carrosilegais:putStockItems', function (itemName, count)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_carrosilegais', function (inventory)
		local item = inventory.getItem(itemName)

		if item.count >= 0 then
			xPlayer.removeInventoryItem(itemName, count)
			inventory.addItem(itemName, count)
			TriggerClientEvent('esx:showNotification', _source, _U('have_deposited', count, item.label))
		else
			TriggerClientEvent('esx:showNotification', _source, _U('invalid_amount'))
		end
	end)
end)

ESX.RegisterServerCallback('tapr_carrosilegais:getCategories', function (source, cb)
	cb(Categories)
end)

ESX.RegisterServerCallback('tapr_carrosilegais:getVehicles', function (source, cb)
	cb(Vehicles)
end)

ESX.RegisterServerCallback('tapr_carrosilegais:buyVehicle', function (source, cb, vehicleModel)
	local xPlayer     = ESX.GetPlayerFromId(source)
	local vehicleData = nil

	for i=1, #Vehicles, 1 do
		if Vehicles[i].model == vehicleModel then
			vehicleData = Vehicles[i]
			break
		end
	end

	if xPlayer.getMoney() >= vehicleData.price then
		xPlayer.removeMoney(vehicleData.price)
		cb(true)
	else
		cb(false)
	end
end)

ESX.RegisterServerCallback('tapr_carrosilegais:buyVehicleSociety', function (source, cb, society, vehicleModel)
	local vehicleData = nil

	for i=1, #Vehicles, 1 do
		if Vehicles[i].model == vehicleModel then
			vehicleData = Vehicles[i]
			break
		end
	end

	TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. society, function (account)
		if account.money >= vehicleData.price then
			account.removeMoney(vehicleData.price)

			MySQL.Async.execute('INSERT INTO ilegais_vehicles (vehicle, price) VALUES (@vehicle, @price)',
			{
				['@vehicle'] = vehicleData.model,
				['@price']   = vehicleData.price
			}, function(rowsChanged)
				cb(true)
			end)

		else
			cb(false)
		end
	end)
end)

ESX.RegisterServerCallback('tapr_carrosilegais:getCommercialVehicles', function (source, cb)
	MySQL.Async.fetchAll('SELECT * FROM ilegais_vehicles ORDER BY vehicle ASC', {}, function (result)
		local vehicles = {}

		for i=1, #result, 1 do
			table.insert(vehicles, {
				name  = result[i].vehicle,
				price = result[i].price
			})
		end

		cb(vehicles)
	end)
end)


RegisterServerEvent('tapr_carrosilegais:returnProvider')
AddEventHandler('tapr_carrosilegais:returnProvider', function(vehicleModel)
	local _source = source

	MySQL.Async.fetchAll('SELECT * FROM ilegais_vehicles WHERE vehicle = @vehicle LIMIT 1', {
		['@vehicle'] = vehicleModel
	}, function (result)

		if result[1] then
			local id    = result[1].id
			local price = ESX.Round(result[1].price * 0.75)

			TriggerEvent('esx_addonaccount:getSharedAccount', 'society_carrosilegais', function(account)
				account.addMoney(price)
			end)

			MySQL.Async.execute('DELETE FROM ilegais_vehicles WHERE id = @id', {
				['@id'] = id
			})

			TriggerClientEvent('esx:showNotification', _source, _U('vehicle_sold_for', vehicleModel, ESX.Math.GroupDigits(price)))
		else
			
			print(('tapr_carrosilegais: %s attempted selling an invalid vehicle!'):format(GetPlayerIdentifiers(_source)[1]))
		end

	end)
end)
	-- Edits by Chip W
ESX.RegisterServerCallback('tapr_carrosilegais:getRentedVehicles', function (source, cb)
	MySQL.Async.fetchAll('SELECT * FROM ilegaisalugados_vehicles ORDER BY player_name ASC', {}, function (result)
		local vehicles = {}

		for i=1, #result, 1 do
			table.insert(vehicles, {
				name       = result[i].vehicle,
				plate      = result[i].plate,
				playerName = result[i].player_name
			})
		end

		cb(vehicles)
	end)
end)

ESX.RegisterServerCallback('tapr_carrosilegais:giveBackVehicle', function (source, cb, plate)
	MySQL.Async.fetchAll('SELECT * FROM ilegaisalugados_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	}, function (result)
		if result[1] ~= nil then
			local vehicle   = result[1].vehicle
			local basePrice = result[1].base_price

			MySQL.Async.execute('INSERT INTO ilegais_vehicles (vehicle, price) VALUES (@vehicle, @price)',
			{
				['@vehicle'] = vehicle,
				['@price']   = basePrice
			})

			MySQL.Async.execute('DELETE FROM ilegaisalugados_vehicles WHERE plate = @plate', {
				['@plate'] = plate
			})

			RemoveOwnedVehicle(plate)
			cb(true)
		else
			cb(false)
		end
	end)
end)

ESX.RegisterServerCallback('tapr_carrosilegais:resellVehicle', function (source, cb, plate, model)
	local resellPrice

	-- calculate the resell price
	for i=1, #Vehicles, 1 do
		if Vehicles[i].model == model then
			resellPrice = ESX.Math.Round(Vehicles[i].price / 100 * Config.ResellPercentage)
			break
		end
	end

	MySQL.Async.fetchAll('SELECT * FROM ilegaisalugados_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	}, function (result)
		if result[1] then -- is it a rented vehicle?
			cb(false) -- it is, don't let the player sell it since he doesn't own it
		else
			local xPlayer = ESX.GetPlayerFromId(source)

			MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND @plate = plate', {
				['@owner'] = xPlayer.identifier,
				['@plate'] = plate
			}, function (result)

				if result[1] then -- does the owner match?

					local vehicle = json.decode(result[1].vehicle)

					if vehicle.model == GetHashKey(model) then
						if vehicle.plate == plate then
							xPlayer.addMoney(resellPrice)
							RemoveOwnedVehicle(plate)
							cb(true)
						else
							print(('tapr_carrosilegais: %s attempted to sell an vehicle with plate mismatch!'):format(xPlayer.identifier))
							cb(false)
						end
					else
						print(('tapr_carrosilegais: %s attempted to sell an vehicle with model mismatch!'):format(xPlayer.identifier))
						cb(false)
					end

				else

					if xPlayer.job.grade_name == 'boss' then
						MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND @plate = plate', {
							['@owner'] = 'society:' .. xPlayer.job.name,
							['@plate'] = plate
						}, function (result)

							if result[1] then

								local vehicle = json.decode(result[1].vehicle)

								if vehicle.model == GetHashKey(model) then
									if vehicle.plate == plate then
										xPlayer.addMoney(resellPrice)
										RemoveOwnedVehicle(plate)
										cb(true)
									else
										print(('tapr_carrosilegais: %s attempted to sell an vehicle with plate mismatch!'):format(xPlayer.identifier))
										cb(false)
									end
								else
									print(('tapr_carrosilegais: %s attempted to sell an vehicle with model mismatch!'):format(xPlayer.identifier))
									cb(false)
								end

							else
								cb(false)
							end

						end)
					else
						cb(false)
					end
				end

			end)
		end
	end)
end)


ESX.RegisterServerCallback('tapr_carrosilegais:getStockItems', function (source, cb)
	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_carrosilegais', function(inventory)
		cb(inventory.items)
	end)
end)

ESX.RegisterServerCallback('tapr_carrosilegais:getPlayerInventory', function (source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local items   = xPlayer.inventory

	cb({ items = items })
end)
	-- Edits by Chip W
ESX.RegisterServerCallback('tapr_carrosilegais:isPlateTaken', function (source, cb, plate)
	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE @plate = plate', {
		['@plate'] = plate
	}, function (result)
		cb(result[1] ~= nil)
	end)
end)

function PayRent(d, h, m)
	MySQL.Async.fetchAll('SELECT * FROM ilegaisalugados_vehicles', {}, function (result)
		for i=1, #result, 1 do
			local xPlayer = ESX.GetPlayerFromIdentifier(result[i].owner)

			-- message player if connected
			if xPlayer ~= nil then
				xPlayer.removeAccountMoney('bank', result[i].rent_price)
				TriggerClientEvent('esx:showNotification', xPlayer.source, _U('paid_rental', ESX.Math.GroupDigits(result[i].rent_price)))
			else -- pay rent either way
				MySQL.Sync.execute('UPDATE users SET bank = bank - @bank WHERE identifier = @identifier',
				{
					['@bank']       = result[i].rent_price,
					['@identifier'] = result[i].owner
				})
			end

			TriggerEvent('esx_addonaccount:getSharedAccount', 'society_carrosilegais', function(account)
				account.addMoney(result[i].rent_price)
			end)
		end
	end)
end

TriggerEvent('cron:runAt', 22, 00, PayRent)
