local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local activeClaims = {}
local insuranceBlip = nil

-- Initialize
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    CreateInsuranceBlip()
    TriggerServerEvent('insurance:server:CheckPolicies')
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    RemoveInsuranceBlip()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

-- Create Insurance Office Blip
function CreateInsuranceBlip()
    if insuranceBlip then RemoveBlip(insuranceBlip) end
    
    insuranceBlip = AddBlipForCoord(Config.InsuranceOffice.x, Config.InsuranceOffice.y, Config.InsuranceOffice.z)
    SetBlipSprite(insuranceBlip, Config.InsuranceBlip.sprite)
    SetBlipDisplay(insuranceBlip, 4)
    SetBlipScale(insuranceBlip, Config.InsuranceBlip.scale)
    SetBlipColour(insuranceBlip, Config.InsuranceBlip.color)
    SetBlipAsShortRange(insuranceBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.InsuranceBlip.label)
    EndTextCommandSetBlipName(insuranceBlip)
end

function RemoveInsuranceBlip()
    if insuranceBlip then
        RemoveBlip(insuranceBlip)
        insuranceBlip = nil
    end
end

-- Insurance Office Interaction
CreateThread(function()
    while true do
        local sleep = 1000
        local pos = GetEntityCoords(PlayerPedId())
        local dist = #(pos - Config.InsuranceOffice)
        
        if dist < 15 then
            sleep = 0
            DrawMarker(2, Config.InsuranceOffice.x, Config.InsuranceOffice.y, Config.InsuranceOffice.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.2, 210, 50, 9, 255, false, false, false, true, false, false, false)
            
            if dist < 1.5 then
                DrawText3Ds(Config.InsuranceOffice.x, Config.InsuranceOffice.y, Config.InsuranceOffice.z + 0.3, '[E] - خدمات التأمين')
                if IsControlJustReleased(0, 38) then -- E key
                    OpenInsuranceMenu()
                end
            end
        end
        Wait(sleep)
    end
end)

-- Target Integration
if Config.UseTarget then
    CreateThread(function()
        exports['qb-target']:AddBoxZone("InsuranceOffice", Config.InsuranceOffice, 1.5, 1.5, {
            name = "InsuranceOffice",
            heading = 0,
            debugPoly = Config.Debug,
            minZ = Config.InsuranceOffice.z - 1,
            maxZ = Config.InsuranceOffice.z + 1,
        }, {
            options = {
                {
                    type = "client",
                    event = "insurance:client:OpenMenu",
                    icon = "fas fa-file-contract",
                    label = "خدمات التأمين",
                },
            },
            distance = 2.0
        })
    end)
end

-- Events
RegisterNetEvent('insurance:client:OpenMenu', function()
    OpenInsuranceMenu()
end)

RegisterNetEvent('insurance:client:NotifyClaimStatus', function(status, amount)
    if status == 'approved' then
        QBCore.Functions.Notify(Lang:t('success.claim_approved'), 'success')
        if amount then
            QBCore.Functions.Notify(Lang:t('success.payment_received', {amount = amount}), 'success')
        end
    elseif status == 'rejected' then
        QBCore.Functions.Notify(Lang:t('error.claim_rejected'), 'error') -- خطأ: تم رفض المطالبة
    elseif status == 'fraud' then
        QBCore.Functions.Notify(Lang:t('error.fraud_detected'), 'error') -- خطأ: تم اكتشاف احتيال
    end
end)

RegisterNetEvent('insurance:client:StartClaimProcessing', function(claimId, claimType)
    activeClaims[claimId] = true
    QBCore.Functions.Notify(Lang:t('info.processing_claim'), 'primary', 5000) -- جاري معالجة المطالبة
    
    -- Show progress bar for claim processing
    QBCore.Functions.Progressbar("processing_claim", "جاري معالجة مطالبة التأمين", Config.ClaimProcessingTime, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = false,
    }, {}, {}, {}, function() -- Done
        if activeClaims[claimId] then
            TriggerServerEvent('insurance:server:CompleteClaim', claimId, claimType)
            activeClaims[claimId] = nil
        end
    end, function() -- Cancel
        QBCore.Functions.Notify("تم إلغاء معالجة المطالبة", "error") -- تم إلغاء معالجة المطالبة
        activeClaims[claimId] = nil
    end)
end)

RegisterNetEvent('insurance:client:MonthlyPayment', function(insuranceType, cost)
    QBCore.Functions.Notify(Lang:t('info.monthly_fee', {amount = cost}), 'primary') -- الرسوم الشهرية: {amount}
end)

-- Helper Functions
function DrawText3Ds(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

function GetClosestVehicle()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local closestVehicle = nil
    local closestDistance = 5.0
    
    for vehicle in EnumerateVehicles() do
        local vehiclePos = GetEntityCoords(vehicle)
        local distance = #(pos - vehiclePos)
        
        if distance < closestDistance then
            closestVehicle = vehicle
            closestDistance = distance
        end
    end
    
    return closestVehicle, closestDistance
end

-- Vehicle enumeration function
local entityEnumerator = {
    __gc = function(enum)
        if enum.destructor and enum.handle then
            enum.destructor(enum.handle)
        end
        enum.destructor = nil
        enum.handle = nil
    end
}

function EnumerateEntities(initFunc, moveFunc, disposeFunc)
    return coroutine.wrap(function()
        local iter, id = initFunc()
        if not id or id == 0 then
            disposeFunc(iter)
            return
        end
        
        local enum = {handle = iter, destructor = disposeFunc}
        setmetatable(enum, entityEnumerator)
        
        local next = true
        repeat
            coroutine.yield(id)
            next, id = moveFunc(iter)
        until not next
        
        enum.destructor, enum.handle = nil, nil
        disposeFunc(iter)
    end)
end

function EnumerateVehicles()
    return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end