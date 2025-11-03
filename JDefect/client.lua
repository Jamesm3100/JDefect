local DEFECTIVE_FLAG = 14.23

local FIXED_FLAG = 0.0

local function ShowNotification(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentSubstringPlayerName(text)
    DrawNotification(false, true)
end

local function ShowHelpText(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function IsVehicleDefective(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return false
    end
    
    local dirtLevel = GetVehicleDirtLevel(vehicle)
    
    if math.abs(dirtLevel - DEFECTIVE_FLAG) < 0.01 then
        return true
    end
    
    return false
end

local function GetClosestVehicleInPool(radius)
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local closestVehicle = 0
    local closestDistance = radius + 1.0

    if IsPedInAnyVehicle(ped, false) then
        return GetVehiclePedIsIn(ped, false)
    end
    
    local allVehicles = GetGamePool('CVehicle')

    for _, veh in ipairs(allVehicles) do
        if DoesEntityExist(veh) and IsEntityAVehicle(veh) then
            local vehCoords = GetEntityCoords(veh)
            local distance = GetDistanceBetweenCoords(playerCoords.x, playerCoords.y, playerCoords.z, vehCoords.x, vehCoords.y, vehCoords.z, true)
            
            if distance < radius and distance < closestDistance then
                closestDistance = distance
                closestVehicle = veh
            end
        end
    end
    
    return closestVehicle
end

local function SetVehicleStatus(status)
    local ped = PlayerPedId()

    if not IsPedInAnyVehicle(ped, false) then
        ShowNotification("~r~Error:~w~ You must be inside a vehicle to use this command!")
        return
    end
    
    local veh = GetVehiclePedIsIn(ped, false)
    
    NetworkRequestControlOfEntity(veh)
    local timeout = 1000
    while not NetworkHasControlOfEntity(veh) and timeout > 0 do
        Citizen.Wait(10)
        timeout = timeout - 10
    end

    if NetworkHasControlOfEntity(veh) then
        if status == "defect" then
            SetVehicleDirtLevel(veh, DEFECTIVE_FLAG)
            ShowNotification("This vehicle has been marked as ~r~defective~w~.")
            SetEntityAsNoLongerNeeded(veh)
            
        elseif status == "fix" then
            
            FreezeEntityPosition(veh, true)
            
            SetVehicleDoorsLocked(veh, 2)
            SetVehicleOnGroundProperly(veh)
            SetVehicleEngineOn(veh, false, false, true)
            
            SetVehicleDoorOpen(veh, 4, false, false) 
            ShowNotification("~g~Repairing...~w~ Please wait 10 seconds.")
            
            Citizen.Wait(10000) 
            
            SetVehicleFixed(veh)
            SetVehicleEngineHealth(veh, 1000.0)
            SetVehicleBodyHealth(veh, 1000.0)
            SetVehicleDirtLevel(veh, FIXED_FLAG)
            
            SetVehicleDoorShut(veh, 4, true)
            SetVehicleDoorsLocked(veh, 0)
            
            FreezeEntityPosition(veh, false)
            SetEntityAsNoLongerNeeded(veh)

            ShowNotification("This vehicle has been ~g~fixed~w~.")
        end
        
    else
        ShowNotification("~r~Error:~w~ Could not gain network control of the vehicle.")
    end
end

RegisterCommand("defect", function()
    SetVehicleStatus("defect")
end, false)

RegisterCommand("fix", function()
    SetVehicleStatus("fix")
end, false)

RegisterCommand("checkdefect", function()           
    local nearbyVehicle = GetClosestVehicleInPool(5.0)

    if nearbyVehicle and nearbyVehicle ~= 0 then
        if IsVehicleDefective(nearbyVehicle) then
            ShowNotification("This vehicle ~r~is defective~w~.")
        else
            ShowNotification("This vehicle is ~g~not defective~w~.")
        end
    else
        ShowNotification("~r~Error:~w~ No nearby vehicle found.")
    end
end, false)

