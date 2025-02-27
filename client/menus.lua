local QBCore = exports['qb-core']:GetCoreObject()

-- Main Insurance Menu
function OpenInsuranceMenu()
    local insuranceMenu = {
        {
            header = Lang:t('menu.insurance_services'),
            isMenuHeader = true
        },
        {
            header = Lang:t('menu.vehicle_insurance'),
            txt = "Purchase or manage vehicle insurance",
            params = {
                event = "insurance:client:VehicleInsuranceMenu",
            }
        },
        {
            header = Lang:t('menu.property_insurance'),
            txt = "Purchase or manage property insurance",
            params = {
                event = "insurance:client:PropertyInsuranceMenu",
            }
        },
        {
            header = Lang:t('menu.health_insurance'),
            txt = "Purchase or manage health insurance",
            params = {
                event = "insurance:client:HealthInsuranceMenu",
            }
        },
        {
            header = Lang:t('menu.file_claim'),
            txt = "File an insurance claim",
            params = {
                event = "insurance:client:FileClaimMenu",
            }
        },
        {
            header = Lang:t('menu.view_policies'),
            txt = "View your active insurance policies",
            params = {
                event = "insurance:client:ViewPoliciesMenu",
            }
        },
        {
            header = "Close Menu",
            txt = "",
            params = {
                event = "m5-menu:client:closeMenu",
            }
        },
    }
    
    -- Add insurance job options if player is an insurance employee
    if QBCore.Functions.GetPlayerData().job.name == Config.InsuranceJob then
        table.insert(insuranceMenu, #insuranceMenu, {
            header = "إجراءات عمل التأمين",
            txt = "Access employee functions",
            params = {
                event = "insurance:client:JobMenu",
            }
        })
    end
    
    exports['m5-menu']:openMenu(insuranceMenu)
end

-- Vehicle Insurance Menu
RegisterNetEvent('insurance:client:VehicleInsuranceMenu', function()
    local vehicleInsuranceMenu = {
        {
            header = "Vehicle Insurance",
            isMenuHeader = true
        }
    }
    
    for k, v in pairs(Config.VehicleInsurance) do
        table.insert(vehicleInsuranceMenu, {
            header = v.label,
            txt = v.description .. " - $" .. v.price .. " (Monthly: $" .. v.monthlyFee .. ")",
            params = {
                event = "insurance:client:PurchaseVehicleInsurance",
                args = {
                    type = k
                }
            }
        })
    end
    
    table.insert(vehicleInsuranceMenu, {
        header = "Back",
        txt = "",
        params = {
            event = "insurance:client:OpenMenu",
        }
    })
    
    exports['m5-menu']:openMenu(vehicleInsuranceMenu)
end)

-- Property Insurance Menu
RegisterNetEvent('insurance:client:PropertyInsuranceMenu', function()
    local propertyInsuranceMenu = {
        {
            header = "Property Insurance",
            isMenuHeader = true
        }
    }
    
    for k, v in pairs(Config.PropertyInsurance) do
        table.insert(propertyInsuranceMenu, {
            header = v.label,
            txt = v.description .. " - $" .. v.price .. " (Monthly: $" .. v.monthlyFee .. ")",
            params = {
                event = "insurance:client:PurchasePropertyInsurance",
                args = {
                    type = k
                }
            }
        })
    end
    
    table.insert(propertyInsuranceMenu, {
        header = "Back",
        txt = "",
        params = {
            event = "insurance:client:OpenMenu",
        }
    })
    
    exports['m5-menu']:openMenu(propertyInsuranceMenu)
end)

-- Health Insurance Menu
RegisterNetEvent('insurance:client:HealthInsuranceMenu', function()
    local healthInsuranceMenu = {
        {
            header = "Health Insurance",
            isMenuHeader = true
        }
    }
    
    for k, v in pairs(Config.HealthInsurance) do
        table.insert(healthInsuranceMenu, {
            header = v.label,
            txt = v.description .. " - $" .. v.price .. " (Monthly: $" .. v.monthlyFee .. ")",
            params = {
                event = "insurance:client:PurchaseHealthInsurance",
                args = {
                    type = k
                }
            }
        })
    end
    
    table.insert(healthInsuranceMenu, {
        header = "Back",
        txt = "",
        params = {
            event = "insurance:client:OpenMenu",
        }
    })
    
    exports['m5-menu']:openMenu(healthInsuranceMenu)
end)

-- File Claim Menu
RegisterNetEvent('insurance:client:FileClaimMenu', function()
    local claimMenu = {
        {
            header = "تقديم مطالبة تأمين",
            isMenuHeader = true
        },
        {
            header = "Vehicle Claim",
            txt = "File a claim for vehicle damage or theft",
            params = {
                event = "insurance:client:FileVehicleClaim",
            }
        },
        {
            header = "Property Claim",
            txt = "File a claim for property damage or theft",
            params = {
                event = "insurance:client:FilePropertyClaim",
            }
        },
        {
            header = "Health Claim",
            txt = "File a claim for medical expenses",
            params = {
                event = "insurance:client:FileHealthClaim",
            }
        },
        {
            header = "Back",
            txt = "",
            params = {
                event = "insurance:client:OpenMenu",
            }
        }
    }
    
    exports['m5-menu']:openMenu(claimMenu)
end)

-- View Policies Menu
RegisterNetEvent('insurance:client:ViewPoliciesMenu', function()
    QBCore.Functions.TriggerCallback('insurance:server:GetPlayerPolicies', function(policies)
        local policiesMenu = {
            {
                header = "Your Insurance Policies",
                isMenuHeader = true
            }
        }
        
        if policies and next(policies) then
            for _, policy in ipairs(policies) do
                local expiryDate = "Never"
                if policy.expiry then
                    expiryDate = os.date("%Y-%m-%d", policy.expiry)
                end
                
                table.insert(policiesMenu, {
                    header = policy.label,
                    txt = "Type: " .. policy.type .. " | Coverage: " .. (policy.coverage * 100) .. "% | Expires: " .. expiryDate,
                    params = {
                        event = "insurance:client:PolicyDetailsMenu",
                        args = {
                            policyId = policy.id
                        }
                    }
                })
            end
        else
            table.insert(policiesMenu, {
                header = "No Active Policies",
                txt = "You don't have any active insurance policies",
                isMenuHeader = true
            })
        end
        
        table.insert(policiesMenu, {
            header = "Back",
            txt = "",
            params = {
                event = "insurance:client:OpenMenu",
            }
        })
        
        exports['m5-menu']:openMenu(policiesMenu)
    end)
end)

-- Policy Details Menu
RegisterNetEvent('insurance:client:PolicyDetailsMenu', function(data)
    QBCore.Functions.TriggerCallback('insurance:server:GetPolicyDetails', function(policy)
        if not policy then
            QBCore.Functions.Notify("Policy not found", "error")
            TriggerEvent("insurance:client:ViewPoliciesMenu")
            return
        end
        
        local policyMenu = {
            {
                header = policy.label,
                isMenuHeader = true
            },
            {
                header = "Policy Details",
                txt = "Type: " .. policy.type .. 
                      "\nCoverage: " .. (policy.coverage * 100) .. "%" ..
                      "\nMonthly Fee: $" .. policy.monthlyFee ..
                      "\nExpires: " .. (policy.expiry and os.date("%Y-%m-%d", policy.expiry) or "Never"),
                isMenuHeader = true
            },
            {
                header = "إلغاء بوليصة التأمين",
                txt = "Cancel this insurance policy",
                params = {
                    event = "insurance:client:CancelPolicy",
                    args = {
                        policyId = policy.id
                    }
                }
            },
            {
                header = "Back",
                txt = "",
                params = {
                    event = "insurance:client:ViewPoliciesMenu",
                }
            }
        }
        
        exports['m5-menu']:openMenu(policyMenu)
    end, data.policyId)
end)

-- Insurance Job Menu
RegisterNetEvent('insurance:client:JobMenu', function()
    local jobMenu = {
        {
            header = "إجراءات عمل التأمين",
            isMenuHeader = true
        },
        {
            header = "Review Claims",
            txt = "Review pending insurance claims",
            params = {
                event = "insurance:client:ReviewClaimsMenu",
            }
        },
        {
            header = "قاعدة بيانات العملاء",
            txt = "Access customer policy information",
            params = {
                event = "insurance:client:CustomerDatabaseMenu",
            }
        }
    }
    
    -- Add management options for bosses
    if QBCore.Functions.GetPlayerData().job.grade.level >= 4 then
        table.insert(jobMenu, {
            header = "Management",
            txt = "Access management functions",
            params = {
                event = "qb-bossmenu:client:openMenu",
            }
        })
    end
    
    table.insert(jobMenu, {
        header = "Back",
        txt = "",
        params = {
            event = "insurance:client:OpenMenu",
        }
    })
    
    exports['m5-menu']:openMenu(jobMenu)
end)

-- Review Claims Menu
RegisterNetEvent('insurance:client:ReviewClaimsMenu', function()
    QBCore.Functions.TriggerCallback('insurance:server:GetPendingClaims', function(claims)
        local claimsMenu = {
            {
                header = "Pending Insurance Claims",
                isMenuHeader = true
            }
        }
        
        if claims and next(claims) then
            for _, claim in ipairs(claims) do
                table.insert(claimsMenu, {
                    header = "Claim #" .. claim.id,
                    txt = "Type: " .. claim.type .. " | Amount: $" .. claim.amount .. " | Date: " .. os.date("%Y-%m-%d", claim.date),
                    params = {
                        event = "insurance:client:ClaimDetailsMenu",
                        args = {
                            claimId = claim.id
                        }
                    }
                })
            end
        else
            table.insert(claimsMenu, {
                header = "No Pending Claims",
                txt = "There are no pending insurance claims",
                isMenuHeader = true
            })
        end
        
        table.insert(claimsMenu, {
            header = "Back",
            txt = "",
            params = {
                event = "insurance:client:JobMenu",
            }
        })
        
        exports['m5-menu']:openMenu(claimsMenu)
    end)
end)

-- Claim Details Menu
RegisterNetEvent('insurance:client:ClaimDetailsMenu', function(data)
    QBCore.Functions.TriggerCallback('insurance:server:GetClaimDetails', function(claim)
        if not claim then
            QBCore.Functions.Notify("Claim not found", "error")
            TriggerEvent("insurance:client:ReviewClaimsMenu")
            return
        end
        
        local claimMenu = {
            {
                header = "Claim #" .. claim.id,
                isMenuHeader = true
            },
            {
                header = "Claim Details",
                txt = "Type: " .. claim.type .. 
                      "\nAmount: $" .. claim.amount ..
                      "\nDate: " .. os.date("%Y-%m-%d", claim.date) ..
                      "\nDescription: " .. claim.description,
                isMenuHeader = true
            },
            {
                header = "Approve Claim",
                txt = "Approve this insurance claim",
                params = {
                    event = "insurance:client:ProcessClaim",
                    args = {
                        claimId = claim.id,
                        action = "approve"
                    }
                }
            },
            {
                header = "Reject Claim",
                txt = "Reject this insurance claim",
                params = {
                    event = "insurance:client:ProcessClaim",
                    args = {
                        claimId = claim.id,
                        action = "reject"
                    }
                }
            },
            {
                header = "Investigate Fraud",
                txt = "Flag this claim for fraud investigation",
                params = {
                    event = "insurance:client:ProcessClaim",
                    args = {
                        claimId = claim.id,
                        action = "fraud"
                    }
                }
            },
            {
                header = "Back",
                txt = "",
                params = {
                    event = "insurance:client:ReviewClaimsMenu",
                }
            }
        }
        
        exports['m5-menu']:openMenu(claimMenu)
    end, data.claimId)
end)

-- Customer Database Menu
RegisterNetEvent('insurance:client:CustomerDatabaseMenu', function()
    QBCore.Functions.TriggerCallback('insurance:server:GetAllCustomers', function(customers)
        local customerMenu = {
            {
                header = "قاعدة بيانات العملاء",
                isMenuHeader = true
            }
        }
        
        if customers and next(customers) then
            for _, customer in ipairs(customers) do
                table.insert(customerMenu, {
                    header = customer.name,
                    txt = "Citizen ID: " .. customer.citizenid .. " | Policies: " .. customer.policyCount,
                    params = {
                        event = "insurance:client:CustomerDetailsMenu",
                        args = {
                            citizenid = customer.citizenid
                        }
                    }
                })
            end
        else
            table.insert(customerMenu, {
                header = "No Customers",
                txt = "There are no customers in the database",
                isMenuHeader = true
            })
        end
        
        table.insert(customerMenu, {
            header = "Back",
            txt = "",
            params = {
                event = "insurance:client:JobMenu",
            }
        })
        
        exports['m5-menu']:openMenu(customerMenu)
    end)
end)

-- Purchase Insurance Events
RegisterNetEvent('insurance:client:PurchaseVehicleInsurance', function(data)
    local vehicle, distance = GetClosestVehicle()
    
    if not vehicle or distance > 5.0 then
        QBCore.Functions.Notify(Lang:t('error.no_vehicle_nearby'), 'error')
        return
    end
    
    local plate = QBCore.Functions.GetPlate(vehicle)
    
    QBCore.Functions.TriggerCallback('insurance:server:CheckVehicleOwnership', function(isOwner)
        if isOwner then
            TriggerServerEvent('insurance:server:PurchaseInsurance', 'vehicle', data.type, plate)
        else
            QBCore.Functions.Notify(Lang:t('error.not_owner'), 'error')
        end
    end, plate)
end)

RegisterNetEvent('insurance:client:PurchasePropertyInsurance', function(data)
    -- Get player's properties
    QBCore.Functions.TriggerCallback('insurance:server:GetPlayerProperties', function(properties)
        if not properties or #properties == 0 then
            QBCore.Functions.Notify("You don't own any properties", "error")
            return
        end
        
        local propertyMenu = {
            {
                header = "Select Property to Insure",
                isMenuHeader = true
            }
        }
        
        for _, property in ipairs(properties) do
            table.insert(propertyMenu, {
                header = property.label,
                txt = property.address,
                params = {
                    event = "insurance:client:ConfirmPropertyInsurance",
                    args = {
                        propertyId = property.id,
                        insuranceType = data.type
                    }
                }
            })
        end
        
        table.insert(propertyMenu, {
            header = "Back",
            txt = "",
            params = {
                event = "insurance:client:PropertyInsuranceMenu",
            }
        })
        
        exports['m5-menu']:openMenu(propertyMenu)
    end)
end)

RegisterNetEvent('insurance:client:ConfirmPropertyInsurance', function(data)
    TriggerServerEvent('insurance:server:PurchaseInsurance', 'property', data.insuranceType, data.propertyId)
end)

RegisterNetEvent('insurance:client:PurchaseHealthInsurance', function(data)
    TriggerServerEvent('insurance:server:PurchaseInsurance', 'health', data.type)
end)

-- File Claim Events
RegisterNetEvent('insurance:client:FileVehicleClaim', function()
    local vehicle, distance = GetClosestVehicle()
    
    if not vehicle or distance > 5.0 then
        QBCore.Functions.Notify(Lang:t('error.no_vehicle_nearby'), 'error')
        return
    end
    
    local plate = QBCore.Functions.GetPlate(vehicle)
    local vehicleHealth = GetVehicleBodyHealth(vehicle)
    local damageAmount = math.floor((1000 - vehicleHealth) * 10) -- Calculate damage cost based on vehicle health
    
    local dialog = exports['qb-input']:ShowInput({
        header = "Vehicle Insurance Claim",
        submitText = "Submit Claim",
        inputs = {
            {
                text = "Damage Description",
                name = "description",
                type = "text",
                isRequired = true
            },
            {
                text = "Claim Amount ($)",
                name = "amount",
                type = "number",
                isRequired = true,
                default = damageAmount
            }
        }
    })
    
    if dialog then
        if not dialog.description or not dialog.amount then
            QBCore.Functions.Notify("يرجى ملء جميع الحقول", "error")
            return
        end
        
        TriggerServerEvent('insurance:server:FileClaim', 'vehicle', plate, dialog.description, tonumber(dialog.amount))
    end
end)

RegisterNetEvent('insurance:client:FilePropertyClaim', function()
    -- Get player's insured properties
    QBCore.Functions.TriggerCallback('insurance:server:GetInsuredProperties', function(properties)
        if not properties or #properties == 0 then
            QBCore.Functions.Notify("You don't have any insured properties", "error")
            return
        end
        
        local propertyMenu = {
            {
                header = "Select Property for Claim",
                isMenuHeader = true
            }
        }
        
        for _, property in ipairs(properties) do
            table.insert(propertyMenu, {
                header = property.label,
                txt = property.address,
                params = {
                    event = "insurance:client:PropertyClaimDetails",
                    args = {
                        propertyId = property.id,
                        policyId = property.policyId
                    }
                }
            })
        end
        
        table.insert(propertyMenu, {
            header = "Back",
            txt = "",
            params = {
                event = "insurance:client:FileClaimMenu",
            }
        })
        
        exports['m5-menu']:openMenu(propertyMenu)
    end)
end)

RegisterNetEvent('insurance:client:PropertyClaimDetails', function(data)
    local dialog = exports['qb-input']:ShowInput({
        header = "Property Insurance Claim",
        submitText = "Submit Claim",
        inputs = {
            {
                text = "Damage Description",
                name = "description",
                type = "text",
                isRequired = true
            },
            {
                text = "Claim Amount ($)",
                name = "amount",
                type = "number",
                isRequired = true
            }
        }
    })
    
    if dialog then
        if not dialog.description or not dialog.amount then
            QBCore.Functions.Notify("يرجى ملء جميع الحقول", "error")
            return
        end
        
        TriggerServerEvent('insurance:server:FileClaim', 'property', data.propertyId, dialog.description, tonumber(dialog.amount), data.policyId)
    end
end)

RegisterNetEvent('insurance:client:FileHealthClaim', function()
    local dialog = exports['qb-input']:ShowInput({
        header = "Health Insurance Claim",
        submitText = "Submit Claim",
        inputs = {
            {
                text = "Medical Description",
                name = "description",
                type = "text",
                isRequired = true
            },
            {
                text = "Claim Amount ($)",
                name = "amount",
                type = "number",
                isRequired = true
            }
        }
    })
    
    if dialog then
        if not dialog.description or not dialog.amount then
            QBCore.Functions.Notify("يرجى ملء جميع الحقول", "error")
            return
        end
        
        TriggerServerEvent('insurance:server:FileClaim', 'health', nil, dialog.description, tonumber(dialog.amount))
    end
end)

-- Cancel Policy Event
RegisterNetEvent('insurance:client:CancelPolicy', function(data)
    local dialog = exports['qb-input']:ShowInput({
        header = "إلغاء بوليصة التأمين",
        submitText = "تأكيد الإلغاء",
        inputs = {
            {
                text = "اكتب 'CONFIRM' لإلغاء البوليصة",
                name = "confirm",
                type = "text",
                isRequired = true
            }
        }
    })
    
    if dialog then
        if dialog.confirm == "CONFIRM" then
            TriggerServerEvent('insurance:server:CancelPolicy', data.policyId)
        else
            QBCore.Functions.Notify("تم إلغاء إلغاء البوليصة", "error")
        end
    end
end)

-- Process Claim Event
RegisterNetEvent('insurance:client:ProcessClaim', function(data)
    TriggerServerEvent('insurance:server:ProcessClaim', data.claimId, data.action)
end)