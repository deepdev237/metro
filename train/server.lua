local StopStations = {
    vector3(2611.04, 1685.71, 26.0045),
    vector3(2777.69, 2831.24, 35.4461),
    vector3(2746.92, 3172.71, 43.6491),
    vector3(298.248, -1836.14, 25.8624),
    vector3(243.68, -1198.62, 37.0482),
    vector3(-549.434, -1290.78, 24.9062),
    vector3(-900.237, -2343.76, -13.6458),
    vector3(-1104.42, -2728.99, -9.32413),
    vector3(-1067.23, -2708.14, -9.32413),
    vector3(-866.522, -2294.89, -13.6312),
    vector3(-528.638, -1267.25, 24.9035),
    vector3(284.758, -1209.94, 37.1173),
    vector3(-287.121, -301.918, 8.1491),
    vector3(-848.519, -148.127, 18.0372),
    vector3(-1342.68, -495.257, 13.1313),
    vector3(-472.715, -680.614, 9.89546),
    vector3(-222.641, -1044.9, 28.3251),
    vector3(121.025, -1735.97, 28.0516),
    vector3(107.436, -1713.7, 28.1268),
    vector3(-204.467, -1022.59, 28.3222),
    vector3(-523.353, -665.612, 9.89549),
    vector3(-1358.06, -438.633, 13.1318),
    vector3(-788.995, -131.128, 18.0368),
    vector3(-302.231, -344.879, 8.14959),
    vector3(-210.482, -1455.74, 30.473),
    vector3(68.2834, -1689.57, 28.3013),
    vector3(4310.12, -4717.11, 112.313),
    vector3(3410.98, -4731.49, 111.575)
}
local firstTrain = {
    netId = 0,
    host = 0,
    train_location = vector3(0, 0, 0),
    StartingPos = vector3(40.2, -1201.3, 31.0)
}
local secondTrain = {
    netId = 0,
    host = 0,
    train_location = vector3(0, 0, 0),
    StartingPos = vector3(-618.0, -1476.8, 16.2)
}
local creatingTrain = false

RegisterNetEvent("SpawnedTrain", function(netId, a)
    local src = source
    local train = {}
    if a == 'first' then
        firstTrain.netId = netId
        firstTrain.host = src
        train = firstTrain
    elseif a == 'second' then
        secondTrain.netId = netId
        secondTrain.host = src
        train = secondTrain
    end

    local train_entity = NetworkGetEntityFromNetworkId(train.netId)
    SetEntityDistanceCullingRadius(train_entity, 99999.9)
    creatingTrain = false
end)

RegisterNetEvent("setTrainServer", function(train, toggle, train_speed)
    print('set speed: '..tostring(train_speed))
    local netId = NetworkGetNetworkIdFromEntity(train)
    Citizen.CreateThread(function()
        for _, source in ipairs(GetPlayers()) do
            local src = source
            TriggerClientEvent("setTrain", src, train, toggle, train_speed)
        end
    end)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2500)
        for i = 1, 2 do
            local train
            if i == 1 then
                print('i 1')
                train = firstTrain
            elseif i == 2 then
                print('i 2')
                train = secondTrain
            end

            local train_entity = NetworkGetEntityFromNetworkId(train.netId)
            --print('train: '..train)
            --print('entity exist: '..tostring(DoesEntityExist(train_entity)))
            --print('train coords: '..GetEntityCoords(train_entity))
            
            if not creatingTrain and train.netId == 0 or not DoesEntityExist(train_entity) or GetEntityCoords(train_entity) == vector3(0.0, 0.0, 0.0) then
                --print('try spawning train')
                local host = getLowestId()
                if host then
                    print('hooost?: '..host)
                    creatingTrain = true
                    print(train.StartingPos)
                    TriggerClientEvent("SpawnTrain", host, train.StartingPos)
                    Citizen.Wait(15000)
                else
                    --print('waiiitngng')
                    Citizen.Wait(5000)
                end
            else
                
                for _, source in ipairs(GetPlayers()) do
                    local src = source
                    --print('src syncing: '..src)
                    local train_entity = NetworkGetEntityFromNetworkId(train.netId)
                    --local location = vector4(server_train_location.x, server_train_location.y, server_train_location.z, GetEntityHeading(train_entity))
                    TriggerClientEvent("ClientSyncTrain", src, train.netId)
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        --print(train)
        for i = 1, 2 do
            --print(i)
            local train
            if i == 1 then
                train = firstTrain
            elseif i == 2 then
                train = secondTrain
            end

            --Citizen.CreateThread(function()
                local stopped = false
                local closestdist = 120.0
                local closestcoords = vector3(0, 0, 0)
                for i, coords in ipairs(StopStations) do
                    local distanceFromStop = #(coords - train.train_location)
                    if distanceFromStop < closestdist then
                        closestdist = distanceFromStop
                        closestcoords = coords
                    end
                end
                
                if closestdist < 100.0 and not stopped then
                    print(closestdist)
                    print('host: '..train.host)
                    TriggerClientEvent("setTrain",train.host, train.netId, false)
                    stopped = true
                    Citizen.Wait(30000)
                    TriggerClientEvent("setTrain", train.host, train.netId, true)
                    stopped = false
                end
            --end)

            local train_entity = NetworkGetEntityFromNetworkId(train.netId)
            local train_coords = GetEntityCoords(train_entity)
            if train.netId == 0 or (not DoesEntityExist(train_entity)) then
                --print('waitinngf')
                Citizen.Wait(5000)
            else
                train.train_location = train_coords

                ---GET CLOSEST PLAYER TO TRAIN
                local lastDistance = 9999.0
                local closestPlayer = nil
                for _, source in ipairs(GetPlayers()) do
                    local src = source
                    local playerPed = GetPlayerPed(src)
                    local playerCoords = GetEntityCoords(playerPed)

                    local distance = #(playerCoords - train_coords)
                    if distance < lastDistance then
                        lastDistance = distance
                        closestPlayer = src
                    end
                end

                --SETTING HOST
                if tonumber(closestPlayer) == tonumber(train_host) then
                    --print('1wwaaitin')
                    Citizen.Wait(5000)
                else
                    --print('why')
                    if closestPlayer == nil then
                        --if DoesEntityExist(train) then
                        --    DeleteEntity(train)
                        --end
                    else
                        for _, source in ipairs(GetPlayers()) do
                            local src = source
                            --print('setting host train: '..train.netId)
                            if src == closestPlayer then
                                train.host = src
                                TriggerClientEvent("SetHost", src, true, train.netId)
                            else
                                TriggerClientEvent("SetHost", src, false, train.netId)
                            end
                        end
                    end
                end
            end
            if i == 1 then
                firstTrain = train
            elseif i == 2 then
                secondTrain = train
            end
        end
    end
end)

RegisterCommand('train', function(source, args, RawCommand)
    local src = source
    local train = {}
    local speed = args[3] or 25.0
    if args[1] == "start" then
        if args[2] == "first" then
            train = firstTrain
        elseif args[2] == "second" then
            train = secondTrain
        end
        TriggerClientEvent("setTrain", train.host, train.netId, true, speed)
    elseif args[1] == "stop" then
        if args[2] == "first" then
            train = firstTrain
        elseif args[2] == "second" then
            train = secondTrain
        end
        TriggerClientEvent("setTrain", train.host, train.netId, false, speed)
    elseif args[1] == "tp" then
        if args[2] == "first" then
            train = firstTrain
        elseif args[2] == "second" then
            train = secondTrain
        end
        SetEntityCoords(GetPlayerPed(src), train.train_location.x, train.train_location.y, train.train_location.z + 1.0)
    end
end)

function getLowestId()
    local host = 4096
    for _, source in ipairs(GetPlayers()) do
        local src = tonumber(source)
        if src < host then
            host = src
        end
    end
    if host == 4096 then
        return false
    else
        return host
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    DeleteEntity(NetworkGetEntityFromNetworkId(train))
end)

--------GET TRAIN STOPS
--[[ 
    function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
                if type(k) ~= 'number' then k = '"'..k..'"' end
                s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

local datfiles = {}

for i = 1, 12 do
    table.insert(datfiles, "trains"..tostring(i)..".dat")
end

print(dump(datfiles))

function stringsplit(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end

	local t={} ; i=1

	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end

	return t
end

local stops = {}

Citizen.CreateThread(function()
    for i, filename in ipairs(datfiles) do
        local file = LoadResourceFile(GetCurrentResourceName(), filename)

        local lines = stringsplit(file, "\n")

        for k, v in ipairs(lines) do
            local line = stringsplit(v, " ")
            local position = vector3(0, 0, 0)
            local nodeType = 0
            if line[2] ~= nil then
                if line[1] and line[2] and line[3] then
                    position = vector3(tonumber(line[1]), tonumber(line[2]), tonumber(line[3]))
                    if line[4] then
                        nodeType = tonumber(line[4])
                    end
                end
                if nodeType == 1 or nodeType == 5 then
                    print('stop')
                    print(position)
                    table.insert(stops, position)
                end
            end
        end
    end
    print('stops')
    print(dump(stops))

    local stopsJson = LoadResourceFile(GetCurrentResourceName(), "./stops.json")
    SaveResourceFile(GetCurrentResourceName(), "stops.json", json.encode(stops), -1)
end)
]]