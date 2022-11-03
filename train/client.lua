local trains = {}
local train_carriages = {}
local AreYouHost = false
local loaded = false

Citizen.CreateThread(function()
    LoadTrainModels()
    Citizen.Wait(10000)
    SetTrainsForceDoorsOpen(false)
    loaded = true
end)

RegisterNetEvent("SpawnTrain", function(coords)
    while not loaded do
        Citizen.Wait(1500)
    end
    SpawnTrain(coords)
    AreYouHost = true
end)

RegisterNetEvent("ClientSyncTrain", function(netId--[[,location]])
    --print('client sync train: '..netId)
    local train = NetToVeh(netId)
    table.insert(trains, train)
    SetEntityAlwaysPrerender(train, true)
    SetEntityCanBeTargetedWithoutLos(train, true)
    SetVehicleLodMultiplier(train, 9999.9)
    --print(train)
    train_carriages = {}
    for i = 0, 3 do
        local train_carriage = GetTrainCarriage(train, i)
        if DoesEntityExist(train_carriage) then
            print('carriage: '..i)
            --print(train_carriage)
            SetEntityAlwaysPrerender(train_carriage, true)
            SetEntityCanBeTargetedWithoutLos(train_carriage, true)
            SetVehicleLodMultiplier(train_carriage, 9999.9)
            table.insert(train_carriages, train_carriage)
        end
    end
    local client_coords = GetEntityCoords(train)
    --local coords = vector3(location.x, location.y, location.z)
    --train_location_server = coords
    --[[
    if not DoesEntityExist(train) then return end
    
    
    local dist = #(client_coords - coords)
    if dist >= 15.0 then
        SetEntityCoords(train, coords.x, coords.y, coords.z, true, false, false, true)
        SetEntityHeading(train, location.w)
        SetEntityAlpha(train, 50, false)
        SetEntityDrawOutline(train, true)
    end
    
    ]]
end)

RegisterNetEvent("SetHost", function(toggle, netId)
    --print('setting host')
    --print('netId: '..netId)

    AreYouHost = toggle
    
    local timeout = 1

    if NetworkDoesEntityExistWithNetworkId(netId) then
        NetworkRequestControlOfNetworkId(netId)
        while not NetworkHasControlOfNetworkId(netId) or timeout == 5 do
            print('netId request')
            NetworkRequestControlOfNetworkId(netId)
            Citizen.Wait(500)
            timeout = timeout + 1
        end
        if timeout == 5 then
            print('netId request timed out')
        end
        timeout = 0
        local entity = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(entity) or timeout == 15 then
            NetworkRequestControlOfEntity(entity)
            while not NetworkHasControlOfEntity(entity) or timeout == 15 do
                NetworkRequestControlOfEntity(entity)
                print('entity request')
                Citizen.Wait(500)
                timeout = timeout + 1
            end
            if timeout == 15 then
                print('entity request timed out')
            end
            for i, v in ipairs(train_carriages) do
                local train_carriage = v
                if DoesEntityExist(train_carriage) then
                    timeout = 1
                    local trainc_netId = VehToNet(train_carriage)
                    NetworkRequestControlOfNetworkId(trainc_netId)
                    while not NetworkHasControlOfNetworkId(trainc_netId) or timeout == 15 do
                        print('trainc netId request')
                        NetworkRequestControlOfNetworkId(trainc_netId)
                        Citizen.Wait(500)
                        timeout = timeout + 1
                    end
                    if timeout == 15 then
                        print('trainc netId request timed out')
                    end
                    timeout = 1
                    NetworkRequestControlOfEntity(train_carriage)
                    while not NetworkHasControlOfEntity(train_carriage) or timeout == 15 do
                        NetworkRequestControlOfEntity(train_carriage)
                        print('trainc entity request')
                        Citizen.Wait(500)
                        timeout = timeout + 1
                    end
                    if timeout == 15 then
                        print('trainc entity request timed out')
                    end
                end
            end
        end
    end
end)

function SpawnTrain(coords)
    print('spawning train')
    print(coords)
    Citizen.CreateThread(function()
        --DeleteAllTrains()
        --DeleteMissionTrain(train)
        --train = 0
        --Citizen.Wait(1000)
        local train = CreateMissionTrain(25, coords.x, coords.y, coords.z, true)
        while not DoesEntityExist(train) do 
            Citizen.Wait(0)
        end
        table.insert(trains, train)
        Citizen.Wait(500)
        local netId = VehToNet(train)
        SetNetworkIdExistsOnAllMachines(netId, true)
        SetNetworkIdCanMigrate(netId, true)
        SetEntityAlwaysPrerender(train, true)
        SetEntityCanBeTargetedWithoutLos(train, true)
        SetVehicleLodMultiplier(train, 9999.9)
        TriggerServerEvent("SpawnedTrain", netId, a)
        for i = 0, 3 do
            local train_carriage = GetTrainCarriage(train, i)
            if DoesEntityExist(train_carriage) then
                print('carriage: '..i)
                local netId = VehToNet(train_carriage)
                SetNetworkIdExistsOnAllMachines(netId, true)
                SetNetworkIdCanMigrate(netId, true)
                SetEntityAlwaysPrerender(train_carriage, true)
                SetEntityCanBeTargetedWithoutLos(train_carriage, true)
                SetVehicleLodMultiplier(train_carriage, 9999.9)
                table.insert(train_carriages, train_carriage)
            end
        end
    end)
end

function getClosestTrain()
    return 0
end

RegisterCommand('starttrain', function(source, args, RawCommand)
    local train = getClosestTrain()
    TriggerServerEvent("setTrainServer", train, true, args[1])
end)

RegisterCommand('stoptrain', function(source, args, RawCommand)
    local train = getClosestTrain()
    TriggerServerEvent("setTrainServer", train, false, args[1])
end)

RegisterCommand('warpintotrain', function(source, args, RawCommand)
    local train = getClosestTrain()
    TaskWarpPedIntoVehicle(PlayerPedId(), train, -1)
end)

RegisterCommand('tptotrain', function(source, args, RawCommand)
    local train = getClosestTrain()
    local train_coords = GetEntityCoords(train)
    SetEntityCoords(PlayerPedId(), train_coords.x, train_coords.y, train_coords.z + 1.0, false, false, false, true)
end)

RegisterNetEvent("setTrain", function(netId, toggle, speed)
    local train = NetworkGetEntityFromNetworkId(netId)
    if toggle then
        if not speed or speed == nil then
            speed = 15.0
        else
            speed = tonumber(speed)
        end
    else
        speed = 0.0
    end
    print('speed: '..speed)
    if toggle and DoesEntityExist(train) then
        StartVehicleHorn(train, 10000, 0, false)
        local doorCount = GetTrainDoorCount(train)
        for doorIndex = -1, doorCount - 1 do
            Citizen.CreateThread(function()
                for i = 100, 0, -1 do
                    Citizen.Wait(0)
                    --print((i / 100))
                    SetTrainDoorOpenRatio(train, doorIndex, (i / 100))
                end
            end)
        end
        for i = 1, 3 do
            local trainc = GetTrainCarriage(train, i)
            if DoesEntityExist(trainc) then
                local doorCount = GetTrainDoorCount(trainc)
                for doorIndex = -1, doorCount - 1 do
                    Citizen.CreateThread(function()
                        for i = 100, 0, -1 do
                            Citizen.Wait(0)
                            --print((i / 100))
                            SetTrainDoorOpenRatio(trainc, doorIndex, (i / 100))
                        end
                    end)
                end
            end
        end
        print('closed doors')
        Citizen.Wait(1500)
        SetTrainCruiseSpeed(train, speed)
        SetTrainSpeed(train, speed)
        SetCanAutoVaultOnEntity(train, not toggle)
        SetCanClimbOnEntity(train, not toggle)
    else
        SetTrainCruiseSpeed(train, speed)
        SetTrainSpeed(train, speed)
        SetCanAutoVaultOnEntity(train, not toggle)
        SetCanClimbOnEntity(train, not toggle)
        StartVehicleHorn(train, 10000, 0, false)
        --SetEntityProofs(train, true, true, true, true, true, false, false, false)
        Citizen.Wait(1500)
        local doorCount = GetTrainDoorCount(train)
        for doorIndex = -1, doorCount - 1 do
            Citizen.CreateThread(function()
                for i = 0, 100 do
                    Citizen.Wait(0)
                    --print((i / 100))
                    SetTrainDoorOpenRatio(train, doorIndex, (i / 100))
                end
            end)
        end
        for i = 1, 3 do
            local trainc = GetTrainCarriage(train, i)
            if DoesEntityExist(trainc) then
                local doorCount = GetTrainDoorCount(trainc)
                for doorIndex = -1, doorCount - 1 do
                    Citizen.CreateThread(function()
                        for i = 0, 100 do
                            Citizen.Wait(0)
                            --print((i / 100))
                            SetTrainDoorOpenRatio(trainc, doorIndex, (i / 100))
                        end
                    end)
                end
            end
        end
        print('opened doors')
    end
end)

function getOppositeDegree(d)
    return (d + 180) % 360
end

RegisterCommand('opphead', function(source, args, RawCommand)
    SetEntityHeading(PlayerPedId(), getOppositeDegree(GetEntityHeading(PlayerPedId())))
end)

function LoadTrainModels()
    local tempmodel
    tempmodel = GetHashKey("freight")
    RequestModel(tempmodel)
    while not HasModelLoaded(tempmodel) do
        RequestModel(tempmodel)
        Citizen.Wait(0)
    end
    tempmodel = GetHashKey("metrotrain")
    RequestModel(tempmodel)
    while not HasModelLoaded(tempmodel) do
        RequestModel(tempmodel)
        Citizen.Wait(0)
    end
    tempmodel = GetHashKey("s_m_m_lsmetro_01")
    RequestModel(tempmodel)
    while not HasModelLoaded(tempmodel) do
        RequestModel(tempmodel)
        Citizen.Wait(0)
    end
end

function getup()
    ClearPedTasks(playerPed)
	sitting = false
	FreezeEntityPosition(playerPed, false)
    DetachEntity(PlayerPedId(), true, true)
	currentScenario = nil
end

local sitting = false
--[[
    local seatoffsets = {
    [1] = {
        position = vector3(-0.800000, -4.320000, 1.100000),
        rotation = vector4(0.000000, 0.000000, 0.707107, -0.707107)
    },
    [2] = {
        position = vector3(-0.800000, -1.130000, 1.100000),
        rotation = vector4(0.000000, 0.000000, 0.707107, -0.707107)
    },
    [3] = {
        position = vector3(-0.800000, 0.490000, 1.100000),
        rotation = vector4(0.000000, 0.000000, 0.707107, -0.707107)
    },
    [4] = {
        position = vector3(-0.800000, 2.110000, 1.100000),
        rotation = vector4(0.000000, 0.000000, 0.707107, -0.707107)
    },
    [5] = {
        position = vector3(0.800000, -4.080000, 1.100000),
        rotation = vector4(0.000000, 0.000000, 0.707107, -0.707107)
    },
    [6] = {
        position = vector3(0.800000, -1.130000, 1.100000),
        rotation = vector4(0.000000, 0.000000, 0.707107, -0.707107)
    },
    [7] = {
        position = vector3(0.800000, 0.490000, 1.100000),
        rotation = vector4(0.000000, 0.000000, 0.707107, -0.707107)
    },
    [8] = {
        position = vector3(0.800000, 2.110000, 1.100000),
        rotation = vector4(0.000000, 0.000000, 0.707107, 0.707107)
    }
}
]]

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        for i, train in ipairs(trains) do
            train_location = GetEntityCoords(train)
            if i == 1 then
                ScaleformUI.Notifications:DrawText(0.3, 0.9, "First Train Client: "..train_location)
            elseif i == 2 then
                ScaleformUI.Notifications:DrawText(0.3, 0.925, "Second Train Client: "..train_location)
            end
            
        end
        
        --ScaleformUI.Notifications:DrawText(0.3, 0.925, "Train Server: "..train_location_server)
        --ScaleformUI.Notifications:DrawText(0.3, 0.95, "Are You Host: "..tostring(AreYouHost))

        --if sitting and not IsPedUsingScenario(playerPed, currentScenario) then
		--	wakeup()
		--end
        
        --[[
        local AreYouOnCarriage = false

        local seatbones = {
            --'seat_dside_f',
            'seat_dside_r',
            'seat_dside_r1',
            'seat_dside_r2',
            'seat_dside_r3',
            'seat_dside_r4',
            'seat_dside_r5',
            'seat_dside_r6',
            'seat_dside_r7',
            'seat_pside_f',
            'seat_pside_r',
            'seat_pside_r1',
            'seat_pside_r2',
            'seat_pside_r3',
            'seat_pside_r4',
            'seat_pside_r5',
            'seat_pside_r6',
            'seat_pside_r7',
        }
        local seatIndex
        local BonePos
        for i, v in ipairs(seatbones) do
            seatIndex = GetEntityBoneIndexByName(train, v)
            BonePos = GetWorldPositionOfEntityBone(train, seatIndex)
            local playerCoords = GetEntityCoords(PlayerPedId())
            DrawLine(playerCoords.x, playerCoords.y, playerCoords.z, BonePos.x, BonePos.y, BonePos.z, 250, 5, 50, 255)
        end
        for i, v in ipairs(seatbones) do
            for ix, e in ipairs(train_carriages) do
                seatIndex = GetEntityBoneIndexByName(e, v)
                BonePos = GetWorldPositionOfEntityBone(e, seatIndex)
                local playerCoords = GetEntityCoords(PlayerPedId())
                DrawLine(playerCoords.x, playerCoords.y, playerCoords.z, BonePos.x, BonePos.y, BonePos.z, 250, 5, 50, 255)
            end
        end
        local seats = {}
        for i, v in ipairs(seatoffsets) do
            local pos = GetOffsetFromEntityInWorldCoords(train, v.position.x, v.position.y, v.position.z)
            seats[i] = {offset = v.position, position = pos, rotation = v.rotation}
        end
        for i, v in ipairs(seats) do
            local playerCoords = GetEntityCoords(PlayerPedId())
            DrawLine(playerCoords.x, playerCoords.y, playerCoords.z, v.position.x, v.position.y, v.position.z, 50, 0, 200, 255)
        end

        --print(tostring(IsPedInAnyTrain(PlayerPedId())))
        if (GetLastInputMethod(2) and IsControlJustPressed(0, 38)) and IsPedInAnyTrain(PlayerPedId()) == 1 then
            if sitting then
                ClearPedTasks(PlayerPedId())
                Citizen.Wait(500)
				DetachEntity(PlayerPedId(), true, true)
                print('detached from train')
                sitting = false
			else
                local playerCoords = GetEntityCoords(PlayerPedId())
                local playerHeading = GetEntityHeading(PlayerPedId())
                
                --PlayEntityAnim(PlayerPedId(), "amb@prop_human_seat_chair_mp@female@proper@enter", "enter_fwd", 1, false, true, true)
                --TaskGoStraightToCoord(PlayerPedId(), playerCoords.x, playerCoords.y + 0.5, playerCoords.z, 1.0, -1, getOppositeDegree(playerHeading), 1.0)
                Citizen.Wait(1000)
                --GET CLOSEST SEAT
                local closestSeatdist = 100.0
                local closestSeatWorldCoords = vector3(0, 0, 0)
                local closestSeatRotation = vector3(0, 0, 0)
                local closestSeatOffset = vector3(0, 0, 0)
                for i, v in ipairs(seats) do
                    local playerCoords = GetEntityCoords(PlayerPedId())
                    local seatCoords = v.position
                    local seatRotation = v.rotation
                    local distance = #(playerCoords - seatCoords)
                    if distance < closestSeatdist then
                        closestSeatdist = distance
                        closestSeatOffset = v.offset
                        closestSeatWorldCoords = seatCoords
                        closestSeatRotation = seatRotation
                    end
                end
                print(closestSeatRotation)
                --GET CLOSEST SEAT BONE
                local closestBonedist = 100.0
                local closestBone = -1
                for i, v in ipairs(seatbones) do
                    seatIndex = GetEntityBoneIndexByName(train, v)
                    BonePos = GetWorldPositionOfEntityBone(train, seatIndex)
                    local distance = #(closestSeatWorldCoords - BonePos)
                    if distance < closestBonedist then
                        closestBonedist = distance
                        closestBone = seatIndex
                    end
                end
                for i, v in ipairs(seatbones) do
                    for ix, e in ipairs(train_carriages) do
                        seatIndex = GetEntityBoneIndexByName(e, v)
                        BonePos = GetWorldPositionOfEntityBone(e, seatIndex)
                        local distance = #(closestSeatWorldCoords - BonePos)
                        if distance < closestBonedist then
                            closestBonedist = distance
                            closestBone = seatIndex
                            AreYouOnCarriage = true
                        else
                            AreYouOnCarriage = false
                        end
                    end
                end
                local traintoattach = 0
                if AreYouOnCarriage then
                    print('you are on the carriage')
                    traintoattach = train_carriages[1]
                    
                else
                    traintoattach = train
                end
                TaskStartScenarioAtPosition(PlayerPedId(), "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER", closestSeatWorldCoords.x, closestSeatWorldCoords.y, closestSeatWorldCoords.z, getOppositeDegree(playerHeading), -1, true, false)
                --TaskStartScenarioInPlace(PlayerPedId(), "PROP_HUMAN_SEAT_TRAIN", -1, true)
                --PlayEntityAnim(entity, animName, animDict, p3, loop, stayInAnim, p6, delta, bitset)
                Citizen.Wait(5000)
                --local rotation = GetEntityRotation(PlayerPedId(), 2)
                
                --SetEntityHeading(PlayerPedId(), (playerHeading + 20.0))
                print('closest bone: '..closestBone)
                print('closestSeatOffset: '..closestSeatOffset)
                print('traintoattach: '..traintoattach)

                local xPos2 = vector3(0, 0, 0)
                --SetEntityHeading(PlayerPedId(), closestSeatRotation.w)
                --closestSeatRotation = vector4(0, 0, 0, 0)
                AttachEntityToEntity(PlayerPedId(), traintoattach, closestBone, closestSeatOffset.x--[[x]]--, closestSeatOffset.y--[[y]], closestSeatOffset.z--[[z]], closestSeatRotation.x--[[xRot]], closestSeatRotation.y--[[yRot]], closestSeatRotation.z--[[zRot]], 1, false, true, true, 0, false)
                --AttachEntityToEntity(entity1, entity2, boneIndex, xPos, yPos, zPos, xRot, yRot, zRot, p9, useSoftPinning, collision, isPed, vertexIndex, fixedRot)
                --AttachEntityToEntityPhysically(PlayerPedId(), traintoattach, -1, closestBone, closestSeatOffset.x--[[x]], closestSeatOffset.y--[[y]], closestSeatOffset.z--[[z]], xPos2.x--[[xPos2]], xPos2.y--[[yPos2]], xPos2.z--[[zPos2]], closestSeatRotation.x--[[xRot]], closestSeatRotation.y--[[yRot]], closestSeatRotation.z--[[zRot]], -1, true, 1, false, false, 2)
                --AttachEntityBoneToEntityBone(PlayerPedId(), traintoattach, closestBone, closestBone, true, true)
                --SetEntityRotation(PlayerPedId(), closestSeatRotation.x, closestSeatRotation.y, closestSeatRotation.z, 0, true)
                --AttachEntityToEntityPhysically(entity1, entity2, boneIndex1, boneIndex2, xPos1, yPos1, zPos1, xPos2, yPos2, zPos2, xRot, yRot, zRot, breakForce, fixedRot, p15, collision, teleport, p18)

                --print('attached to train')
                --print(GetEntityCoords(PlayerPedId()))
                --sitting = true
			--end
        --end
        --]]
        
        --local playerHeading = GetEntityHeading(PlayerPedId())

        for i, v in ipairs(trains) do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local trainCoords = GetEntityCoords(v)
            DrawLine(playerCoords.x, playerCoords.y, playerCoords.z, trainCoords.x, trainCoords.y, trainCoords.z, 0, 50, 250, 255)
        end

        if (GetLastInputMethod(2) and IsControlJustPressed(0, 38)) and IsPedInAnyTrain(PlayerPedId()) == 1 then
            local playerCoords = GetEntityCoords(PlayerPedId())
            print('1')
            if sitting then
                print('2')
                ClearPedTasks(PlayerPedId())
                SetPedConfigFlag(PlayerPedId(), 414, false)
                print('cleared tasks')
                sitting = false
            else
                print('3')
                if DoesScenarioExistInArea(playerCoords.x, playerCoords.y, playerCoords.z, 3.5, true) then
                    print('4')
                    SetPedConfigFlag(PlayerPedId(), 414, true)
                    TaskUseNearestScenarioToCoordWarp(PlayerPedId(), playerCoords.x, playerCoords.y, playerCoords.z, 2.5, -1)
                    print('used nearest scenario')
                    sitting = true
                end
            end
            print('5')
        end
        --[[
        if sitting then
            print('sitting')
            SetEntityNoCollisionEntity(PlayerPedId(), train, true)
            for i, entity in ipairs(train_carriages) do
                SetEntityNoCollisionEntity(PlayerPedId(), entity, true)
            end
        end
        ]]
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    for i, train in ipairs(trains) do
        if DoesEntityExist(train) then
            
            DeleteMissionTrain(train)
            DeleteEntity(train)
            DeleteAllTrains()
        end
    end
    for i, trainc in ipairs(train_carriages) do
        --print(i)
        --print(trainc)
        if DoesEntityExist(trainc) then
            
            DeleteMissionTrain(trainc)
            DeleteEntity(trainc)
            DeleteAllTrains()
        end
    end
    ClearPedTasks(PlayerPedId())
    DeleteAllTrains()
end)



--[[
local scene
RegisterCommand('func_340', function(source, args, RawCommand)
    if not IsSynchronizedSceneRunning(scene) then
        RequestAnimDict("dead")
        while not HasAnimDictLoaded("dead") do
            Citizen.Wait(0)
        end
        if not IsSynchronizedSceneRunning(scene) then
            scene = CreateSynchronizedScene(3258.899, -4574.09, 115.35, 173.88, 51.48, 5.04, 0)
            TaskSynchronizedScene(PlayerPedId(), scene, "dead", "dead_g", 1000, -1000, 4, 145, 1000, 0)
            ForcePedAiAndAnimationUpdate(PlayerPedId(), false, false)
            StopPedSpeaking(PlayerPedId(), true)
            SetEntityInvincible(PlayerPedId(), true)
            SetBlockingOfNonTemporaryEvents(PlayerPedId(), true)
        end
    else
        SetPedRagdollBlockingFlags(PlayerPedId(), 4)
        SetPedRagdollBlockingFlags(PlayerPedId(), 128)
        SetPedRagdollBlockingFlags(PlayerPedId(), 32)
        SetPedRagdollBlockingFlags(PlayerPedId(), 8192)
        SetPedRagdollBlockingFlags(PlayerPedId(), 1)
        SetPedRagdollBlockingFlags(PlayerPedId(), 16)
        SetPedRagdollBlockingFlags(PlayerPedId(), 64)
    end
end)
]]
