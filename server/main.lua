local QBCore = exports['qb-core']:GetCoreObject()

-- Initialize Database Tables
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS insurance_policies (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50) NOT NULL,
            type VARCHAR(20) NOT NULL,
            subtype VARCHAR(20) NOT NULL,
            target_id VARCHAR(50) NOT NULL,
            coverage FLOAT NOT NULL,
            monthly_fee INT NOT NULL,
            purchase_date INT NOT NULL,
            expiry_date INT NULL,
            active BOOLEAN DEFAULT 1
        )
    ]])
    
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS insurance_claims (
            id INT AUTO_INCREMENT PRIMARY KEY,
            policy_id INT NOT NULL,
            citizenid VARCHAR(50) NOT NULL,
            type VARCHAR(20) NOT NULL,
            target_id VARCHAR(50) NULL,
            description TEXT NOT NULL,
            amount INT NOT NULL,
            date INT NOT NULL,
            status VARCHAR(20) DEFAULT 'pending',
            processed_by VARCHAR(50) NULL,
            processed_date INT NULL
        )
    ]])
    
    -- Add insurance job to jobs table if it doesn't exist
    MySQL.query('SELECT name FROM jobs WHERE name = ?', {Config.InsuranceJob}, function(result)
        if result[1] == nil then
            MySQL.insert('INSERT INTO jobs (name, label) VALUES (?, ?)', {Config.InsuranceJob, 'Insurance'})
            
            -- Add job grades
            for grade, data in pairs(Config.JobGrades) do
                MySQL.insert('INSERT INTO job_grades (job_name, grade, name, label, salary, isboss) VALUES (?, ?, ?, ?, ?, ?)', 
                {Config.InsuranceJob, grade, data.name, data.label, data.payment, data.isboss or 0})
            end
        end
    end)
    
    -- Schedule monthly payments check
    SetTimeout(60000, CheckMonthlyPayments) -- Check every minute
end)

-- Helper Functions
function GetCurrentTimestamp()
    return os.time()
end

function CalculateExpiryDate(days)
    if not days then return nil end
    return GetCurrentTimestamp() + (days * 86400) -- 86400 seconds in a day
end

-- Insurance Purchase
RegisterNetEvent('insurance:server:PurchaseInsurance', function(insuranceType, subType, targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local insuranceConfig
    
    if insuranceType == 'vehicle' then
        insuranceConfig = Config.VehicleInsurance[subType]
        
        -- Check if vehicle is already insured
        MySQL.query('SELECT id FROM insurance_policies WHERE type = ? AND target_id = ? AND active = 1', 
        {insuranceType, targetId}, function(result)
            if result[1] then
                TriggerClientEvent('QBCore:Notify', src, Lang:t('error.already_insured'), 'error')
                return
            end
            
            -- Check if player owns the vehicle
            MySQL.query('SELECT plate FROM player_vehicles WHERE plate = ? AND citizenid = ?', 
            {targetId, citizenid}, function(vehicleResult)
                if not vehicleResult[1] then
                    TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_owner'), 'error')
                    return
                end
                
                ProcessInsurancePurchase(src, Player, insuranceType, subType, targetId, insuranceConfig)
            end)
        end)
    elseif insuranceType == 'property' then
        insuranceConfig = Config.PropertyInsurance[subType]
        
        -- Check if property is already insured
        MySQL.query('SELECT id FROM insurance_policies WHERE type = ? AND target_id = ? AND active = 1', 
        {insuranceType, targetId}, function(result)
            if result[1] then
                TriggerClientEvent('QBCore:Notify', src, Lang:t('error.already_insured'), 'error')
                return
            end
            
            -- Check if player owns the property (this would depend on your housing system)
            -- For this example, we'll assume the property ownership check is done client-side
            ProcessInsurancePurchase(src, Player, insuranceType, subType, targetId, insuranceConfig)
        end)
    elseif insuranceType == 'health' then
        insuranceConfig = Config.HealthInsurance[subType]
        
        -- Check if player already has health insurance
        MySQL.query('SELECT id FROM insurance_policies WHERE type = ? AND citizenid = ? AND active = 1', 
        {insuranceType, citizenid}, function(result)
            if result[1] then
                TriggerClientEvent('QBCore:Notify', src, Lang:t('error.already_insured'), 'error')
                return
            end
            
            ProcessInsurancePurchase(src, Player, insuranceType, subType, citizenid, insuranceConfig)
        end)
    end
end)

function ProcessInsurancePurchase(src, Player, insuranceType, subType, targetId, insuranceConfig)
    if not insuranceConfig then
        TriggerClientEvent('QBCore:Notify', src, "Invalid insurance type", 'error')
        return
    end
    
    local price = insuranceConfig.price
    
    if Player.Functions.RemoveMoney('bank', price, "insurance-purchase") then
        local currentTime = GetCurrentTimestamp()
        
        MySQL.insert('INSERT INTO insurance_policies (citizenid, type, subtype, target_id, coverage, monthly_fee, purchase_date, active) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        {
            Player.PlayerData.citizenid,
            insuranceType,
            subType,
            targetId,
            insuranceConfig.coverage,
            insuranceConfig.monthlyFee,
            currentTime,
            1
        })
        
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.insurance_purchased'), 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_enough_money'), 'error')
    end
end

-- File Insurance Claim
RegisterNetEvent('insurance:server:FileClaim', function(claimType, targetId, description, amount, policyId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Check if player has an active claim
    MySQL.query('SELECT id FROM insurance_claims WHERE citizenid = ? AND status = ?', 
    {citizenid, 'pending'}, function(result)
        if result[1] then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.claim_in_progress'), 'error')
            return
        end
        
        -- Find the appropriate policy
        local query
        local params
        
        if policyId then
            query = 'SELECT id, coverage FROM insurance_policies WHERE id = ? AND active = 1'
            params = {policyId}
        elseif claimType == 'vehicle' then
            query = 'SELECT id, coverage FROM insurance_policies WHERE type = ? AND target_id = ? AND citizenid = ? AND active = 1'
            params = {claimType, targetId, citizenid}
        elseif claimType == 'property' then
            query = 'SELECT id, coverage FROM insurance_policies WHERE type = ? AND target_id = ? AND citizenid = ? AND active = 1'
            params = {claimType, targetId, citizenid}
        elseif claimType == 'health' then
            query = 'SELECT id, coverage FROM insurance_policies WHERE type = ? AND citizenid = ? AND active = 1'
            params = {claimType, citizenid}
        end
        
        MySQL.query(query, params, function(policyResult)
            if not policyResult[1] then
                TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_insurance'), 'error')
                return
            end
            
            local policy = policyResult[1]
            local currentTime = GetCurrentTimestamp()
            
            -- Insert claim
            MySQL.insert('INSERT INTO insurance_claims (policy_id, citizenid, type, target_id, description, amount, date, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            {
                policy.id,
                citizenid,
                claimType,
                targetId or '',
                description,
                amount,
                currentTime,
                'pending'
            }, function(claimId)
                if claimId > 0 then
                    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.claim_submitted'), 'success')
                    
                    -- Start claim processing
                    TriggerClientEvent('insurance:client:StartClaimProcessing', src, claimId, claimType)
                    
                    -- If there are insurance employees online, notify them
                    local employees = QBCore.Functions.GetPlayersWithJob(Config.InsuranceJob)
                    for _, employee in pairs(employees) do
                        TriggerClientEvent('QBCore:Notify', employee.PlayerData.source, "New insurance claim submitted (#" .. claimId .. ")", 'primary')
                    end
                end
            end)
        end)
    end)
end)

-- Complete Claim Processing
RegisterNetEvent('insurance:server:CompleteClaim', function(claimId, claimType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Get claim details
    MySQL.query('SELECT c.*, p.coverage FROM insurance_claims c JOIN insurance_policies p ON c.policy_id = p.id WHERE c.id = ? AND c.status = ?', 
    {claimId, 'pending'}, function(result)
        if not result[1] then return end
        
        local claim = result[1]
        
        -- Check for potential fraud (random chance)
        if math.random() < Config.FraudChance then
            MySQL.update('UPDATE insurance_claims SET status = ? WHERE id = ?', {'fraud', claimId})
            TriggerClientEvent('insurance:client:NotifyClaimStatus', src, 'fraud')
            return
        end
        
        -- Calculate payout based on coverage
        local payoutAmount = math.floor(claim.amount * claim.coverage)
        
        -- Update claim status
        MySQL.update('UPDATE insurance_claims SET status = ?, processed_date = ? WHERE id = ?', 
        {'approved', GetCurrentTimestamp(), claimId})
        
        -- Pay the player
        Player.Functions.AddMoney('bank', payoutAmount, "insurance-claim")
        
        -- Notify player
        TriggerClientEvent('insurance:client:NotifyClaimStatus', src, 'approved', payoutAmount)
        
        -- If it's a vehicle claim, repair the vehicle
        if claimType == 'vehicle' and claim.target_id ~= '' then
            -- This would depend on your vehicle system
            -- For example, you might update the vehicle's damage state in the database
        end
    end)
end)

-- Process Claim (for insurance employees)
RegisterNetEvent('insurance:server:ProcessClaim', function(claimId, action)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player is an insurance employee
    if Player.PlayerData.job.name ~= Config.InsuranceJob then
        TriggerClientEvent('QBCore:Notify', src, "You are not authorized to process claims", 'error')
        return
    end
    
    -- Get claim details
    MySQL.query('SELECT c.*, p.citizenid as policy_owner FROM insurance_claims c JOIN insurance_policies p ON c.policy_id = p.id WHERE c.id = ? AND c.status = ?', 
    {claimId, 'pending'}, function(result)
        if not result[1] then
            TriggerClientEvent('QBCore:Notify', src, "Claim not found or already processed", 'error')
            return
        end
        
        local claim = result[1]
        local currentTime = GetCurrentTimestamp()
        
        if action == 'approve' then
            -- Calculate payout based on coverage
            MySQL.query('SELECT coverage FROM insurance_policies WHERE id = ?', {claim.policy_id}, function(policyResult)
                if not policyResult[1] then return end
                
                local coverage = policyResult[1].coverage
                local payoutAmount = math.floor(claim.amount * coverage)
                
                -- Update claim status
                MySQL.update('UPDATE insurance_claims SET status = ?, processed_by = ?, processed_date = ? WHERE id = ?', 
                {'approved', Player.PlayerData.citizenid, currentTime, claimId})
                
                -- Find the claim owner and pay them
                local claimOwner = QBCore.Functions.GetPlayerByCitizenId(claim.policy_owner)
                if claimOwner then
                    claimOwner.Functions.AddMoney('bank', payoutAmount, "insurance-claim-approved")
                    TriggerClientEvent('insurance:client:NotifyClaimStatus', claimOwner.PlayerData.source, 'approved', payoutAmount)
                else
                    -- If player is offline, add money to their account
                    MySQL.update('UPDATE players SET money = JSON_SET(money, "$.bank", JSON_EXTRACT(money, "$.bank") + ?) WHERE citizenid = ?',
                    {payoutAmount, claim.policy_owner})
                end
                
                TriggerClientEvent('QBCore:Notify', src, "Claim #" .. claimId .. " approved", 'success')
            end)
        elseif action == 'reject' then
            -- Update claim status
            MySQL.update('UPDATE insurance_claims SET status = ?, processed_by = ?, processed_date = ? WHERE id = ?', 
            {'rejected', Player.PlayerData.citizenid, currentTime, claimId})
            
            -- Notify the claim owner if they're online
            local claimOwner = QBCore.Functions.GetPlayerByCitizenId(claim.policy_owner)
            if claimOwner then
                TriggerClientEvent('insurance:client:NotifyClaimStatus', claimOwner.PlayerData.source, 'rejected')
            end
            
            TriggerClientEvent('QBCore:Notify', src, "Claim #" .. claimId .. " rejected", 'success')
        elseif action == 'fraud' then
            -- Update claim status
            MySQL.update('UPDATE insurance_claims SET status = ?, processed_by = ?, processed_date = ? WHERE id = ?', 
            {'fraud', Player.PlayerData.citizenid, currentTime, claimId})
            
            -- Notify the claim owner if they're online
            local claimOwner = QBCore.Functions.GetPlayerByCitizenId(claim.policy_owner)
            if claimOwner then
                TriggerClientEvent('insurance:client:NotifyClaimStatus', claimOwner.PlayerData.source, 'fraud')
            end
            
            TriggerClientEvent('QBCore:Notify', src, "Claim #" .. claimId .. " marked as fraud", 'success')
        end
    end)
end)

-- Cancel Policy
RegisterNetEvent('insurance:server:CancelPolicy', function(policyId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if policy exists and belongs to player
    MySQL.query('SELECT * FROM insurance_policies WHERE id = ? AND citizenid = ? AND active = 1', 
    {policyId, Player.PlayerData.citizenid}, function(result)
        if not result[1] then
            TriggerClientEvent('QBCore:Notify', src, "Policy not found or already cancelled", 'error')
            return
        end
        
        -- Cancel policy
        MySQL.update('UPDATE insurance_policies SET active = 0 WHERE id = ?', {policyId})
        
        TriggerClientEvent('QBCore:Notify', src, "Insurance policy cancelled", 'success')
    end)
end)

-- Check Monthly Payments
function CheckMonthlyPayments()
    local currentTime = GetCurrentTimestamp()
    
    -- Get all active policies
    MySQL.query('SELECT * FROM insurance_policies WHERE active = 1', {}, function(policies)
        for _, policy in ipairs(policies) do
            -- Check if it's time for monthly payment (30 days since purchase or last payment)
            local lastPaymentTime = policy.purchase_date
            local monthlyInterval = 30 * 86400 -- 30 days in seconds
            
            if (currentTime - lastPaymentTime) >= monthlyInterval then
                -- Get policy owner
                local Player = QBCore.Functions.GetPlayerByCitizenId(policy.citizenid)
                
                if Player then
                    -- Player is online, charge them directly
                    if Player.Functions.RemoveMoney('bank', policy.monthly_fee, "insurance-monthly-fee") then
                        -- Update purchase date to reset the timer
                        MySQL.update('UPDATE insurance_policies SET purchase_date = ? WHERE id = ?', 
                        {currentTime, policy.id})
                        
                        -- Notify player
                        TriggerClientEvent('insurance:client:MonthlyPayment', Player.PlayerData.source, policy.type, policy.monthly_fee)
                    else
                        -- Not enough money, cancel policy
                        MySQL.update('UPDATE insurance_policies SET active = 0 WHERE id = ?', {policy.id})
                        TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, Lang:t('info.insurance_expired'), 'error')
                    end
                else
                    -- Player is offline, check their bank balance
                    MySQL.query('SELECT money FROM players WHERE citizenid = ?', {policy.citizenid}, function(result)
                        if result[1] then
                            local money = json.decode(result[1].money)
                            
                            if money.bank >= policy.monthly_fee then
                                -- Deduct money and update policy
                                money.bank = money.bank - policy.monthly_fee
                                
                                MySQL.update('UPDATE players SET money = ? WHERE citizenid = ?', 
                                {json.encode(money), policy.citizenid})
                                
                                MySQL.update('UPDATE insurance_policies SET purchase_date = ? WHERE id = ?', 
                                {currentTime, policy.id})
                            else
                                -- Not enough money, cancel policy
                                MySQL.update('UPDATE insurance_policies SET active = 0 WHERE id = ?', {policy.id})
                            end
                        end
                    end)
                end
            end
        end
    end)
    
    -- Schedule next check
    SetTimeout(60000, CheckMonthlyPayments) -- Check every minute
end

-- Callbacks
QBCore.Functions.CreateCallback('insurance:server:GetPlayerPolicies', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then return cb({}) end
    
    MySQL.query('SELECT p.*, CASE WHEN p.type = "vehicle" THEN v.label WHEN p.type = "property" THEN "Property" ELSE "Health" END as label FROM insurance_policies p LEFT JOIN player_vehicles v ON p.target_id = v.plate WHERE p.citizenid = ? AND p.active = 1', 
    {Player.PlayerData.citizenid}, function(result)
        cb(result)
    end)
end)

QBCore.Functions.CreateCallback('insurance:server:GetPolicyDetails', function(source, cb, policyId)
    MySQL.query('SELECT p.*, CASE WHEN p.type = "vehicle" THEN v.label WHEN p.type = "property" THEN "Property" ELSE "Health" END as label FROM insurance_policies p LEFT JOIN player_vehicles v ON p.target_id = v.plate WHERE p.id = ?', 
    {policyId}, function(result)
        if result[1] then
            cb(result[1])
        else
            cb(nil)
        end
    end)
end)

QBCore.Functions.CreateCallback('insurance:server:GetPendingClaims', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player or Player.PlayerData.job.name ~= Config.InsuranceJob then
        return cb({})
    end
    
    MySQL.query('SELECT * FROM insurance_claims WHERE status = ? ORDER BY date DESC', {'pending'}, function(result)
        cb(result)
    end)
end)

QBCore.Functions.CreateCallback('insurance:server:GetClaimDetails', function(source, cb, claimId)
    MySQL.query('SELECT c.*, p.coverage FROM insurance_claims c JOIN insurance_policies p ON c.policy_id = p.id WHERE c.id = ?', 
    {claimId}, function(result)
        if result[1] then
            cb(result[1])
        else
            cb(nil)
        end
    end)
end)

QBCore.Functions.CreateCallback('insurance:server:GetAllCustomers', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player or Player.PlayerData.job.name ~= Config.InsuranceJob then
        return cb({})
    end
    
    MySQL.query('SELECT p.citizenid, CONCAT(c.firstname, " ", c.lastname) as name, COUNT(p.id) as policyCount FROM insurance_policies p JOIN players c ON p.citizenid = c.citizenid WHERE p.active = 1 GROUP BY p.citizenid', 
    {}, function(result)
        cb(result)
    end)
end)

QBCore.Functions.CreateCallback('insurance:server:CheckVehicleOwnership', function(source, cb, plate)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then return cb(false) end
    
    MySQL.query('SELECT plate FROM player_vehicles WHERE plate = ? AND citizenid = ?', 
    {plate, Player.PlayerData.citizenid}, function(result)
        cb(result[1] ~= nil)
    end)
end)

QBCore.Functions.CreateCallback('insurance:server:GetPlayerProperties', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then return cb({}) end
    
    -- This would depend on your housing system
    -- For this example, we'll return some dummy data
    local properties = {
        {
            id = "house1",
            label = "Vinewood Hills Mansion",
            address = "2045 North Conker Avenue"
        },
        {
            id = "house2",
            label = "Downtown Apartment",
            address = "Integrity Way, Apt 35"
        }
    }
    
    cb(properties)
end)

QBCore.Functions.CreateCallback('insurance:server:GetInsuredProperties', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then return cb({}) end
    
    MySQL.query('SELECT p.id as policyId, p.target_id as id, "Property" as label, p.target_id as address FROM insurance_policies p WHERE p.citizenid = ? AND p.type = ? AND p.active = 1', 
    {Player.PlayerData.citizenid, 'property'}, function(result)
        cb(result)
    end)
end)

-- Check policies on player load
RegisterNetEvent('insurance:server:CheckPolicies', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player has any expired policies
    local currentTime = GetCurrentTimestamp()
    
    MySQL.query('SELECT * FROM insurance_policies WHERE citizenid = ? AND active = 1 AND expiry_date IS NOT NULL AND expiry_date < ?', 
    {Player.PlayerData.citizenid, currentTime}, function(result)
        if result and #result > 0 then
            for _, policy in ipairs(result) do
                -- Expire policy
                MySQL.update('UPDATE insurance_policies SET active = 0 WHERE id = ?', {policy.id})
            end
            
            TriggerClientEvent('QBCore:Notify', src, Lang:t('info.insurance_expired'), 'error')
        end
    end)
end)

-- Hospital Integration
-- This event would be triggered when a player is treated at a hospital
RegisterNetEvent('hospital:server:ChargePlayer', function(playerId, amount)
    local Player = QBCore.Functions.GetPlayer(playerId)
    
    if not Player then return end
    
    -- Check if player has health insurance
    MySQL.query('SELECT * FROM insurance_policies WHERE citizenid = ? AND type = ? AND active = 1', 
    {Player.PlayerData.citizenid, 'health'}, function(result)
        if result[1] then
            local policy = result[1]
            local discountedAmount = math.floor(amount * (1 - policy.coverage))
            
            -- Charge the discounted amount
            Player.Functions.RemoveMoney('bank', discountedAmount, "hospital-bill-insured")
            
            -- Notify player about insurance coverage
            TriggerClientEvent('QBCore:Notify', playerId, "Your health insurance covered " .. math.floor(policy.coverage * 100) .. "% of your medical bill", 'success')
        else
            -- No insurance, charge full amount
            Player.Functions.RemoveMoney('bank', amount, "hospital-bill")
        end
    end)
end)

-- Vehicle Repair Integration
-- This event would be triggered when a vehicle is repaired
RegisterNetEvent('vehiclemod:server:RepairVehicle', function(plate, amount)
    -- Find the vehicle owner
    MySQL.query('SELECT citizenid FROM player_vehicles WHERE plate = ?', {plate}, function(result)
        if not result[1] then return end
        
        local citizenid = result[1].citizenid
        local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
        
        -- Check if vehicle has insurance
        MySQL.query('SELECT * FROM insurance_policies WHERE citizenid = ? AND type = ? AND target_id = ? AND active = 1', 
        {citizenid, 'vehicle', plate}, function(policyResult)
            if policyResult[1] then
                local policy = policyResult[1]
                local discountedAmount = math.floor(amount * (1 - policy.coverage))
                
                if Player then
                    -- Owner is online
                    Player.Functions.RemoveMoney('bank', discountedAmount, "vehicle-repair-insured")
                    
                    -- Notify player about insurance coverage
                    TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, "Your vehicle insurance covered " .. math.floor(policy.coverage * 100) .. "% of the repair cost", 'success')
                else
                    -- Owner is offline, deduct from their bank account
                    MySQL.query('SELECT money FROM players WHERE citizenid = ?', {citizenid}, function(moneyResult)
                        if moneyResult[1] then
                            local money = json.decode(moneyResult[1].money)
                            money.bank = money.bank - discountedAmount
                            
                            MySQL.update('UPDATE players SET money = ? WHERE citizenid = ?', 
                            {json.encode(money), citizenid})
                        end
                    end)
                end
            end
        end)
    end)
end)

-- Add command to create insurance office
QBCore.Commands.Add('createinsuranceoffice', 'Create an insurance office at your location (Admin Only)', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player.PlayerData.permission == "admin" or Player.PlayerData.permission == "god" then
        local coords = GetEntityCoords(GetPlayerPed(src))
        local coordsString = coords.x .. ", " .. coords.y .. ", " .. coords.z
        
        TriggerClientEvent('QBCore:Notify', src, "Insurance office created at " .. coordsString, 'success')
        TriggerClientEvent('QBCore:Notify', src, "Update your config.lua with these coordinates", 'primary')
    else
        TriggerClientEvent('QBCore:Notify', src, "You don't have permission to use this command", 'error')
    end
end, "admin")