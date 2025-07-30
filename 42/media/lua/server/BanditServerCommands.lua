local getBarricadeAble = function(x, y, z, index)
    local sq = getCell():getGridSquare(x, y, z)
    if sq and index >= 0 and index < sq:getObjects():size() then
        local o = sq:getObjects():get(index)
        if instanceof(o, 'BarricadeAble') then
            return o
        end
    end
    return nil
end

BanditServer = BanditServer or {}
BanditServer.Commands = {}

BanditServer.Commands.PostToggle = function(player, args)
    local gmd = GetBanditModData()
    if not (args.x and args.y and args.z) then return end

    local id = args.x .. "-" .. args.y .. "-" .. args.z
    
    if gmd.Posts[id] then
        gmd.Posts[id] = nil
    else
        gmd.Posts[id] = args
    end
end

BanditServer.Commands.PostUpdate = function(player, args)
    local gmd = GetBanditModData()
    if not (args.x and args.y and args.z) then return end

    local id = args.x .. "-" .. args.y .. "-" .. args.z
    gmd.Posts[id] = args
end

BanditServer.Commands.BaseUpdate = function(player, args)
    local gmd = GetBanditModData()
    if not (args.x and args.y) then return end

    local id = args.x .. "-" .. args.y
    gmd.Bases[id] = args
end

BanditServer.Commands.BanditRemove  = function(player, args)
    local gmd = GetBanditModData()
    local id = args.id
    if gmd.Queue[id] then
        gmd.Queue[id] = nil
        -- print ("[INFO] Bandit removed: " .. id)
    end
end

BanditServer.Commands.BanditFlush  = function(player, args)
    local gmd = GetBanditModData()
    gmd.Queue = {}
    gmd.VisitedBuildings = {}
    gmd.Posts = {}
    gmd.Bases = {}
    print ("[INFO] All bandits removed!!!")
end

BanditServer.Commands.BanditUpdatePart = function(player, args)
    local gmd = GetBanditModData()
    local id = args.id
    if id and gmd.Queue[id] then

        local brain = gmd.Queue[id]
        for k, v in pairs(args) do
            brain[k] = v
            -- print ("[INFO] Bandit sync id: " .. id .. " key: " .. k)
        end

        gmd.Queue[id] = brain

        sendServerCommand('Commands', 'UpdateBanditPart', args)
    end
end

BanditServer.Commands.Unbarricade = function(player, args)
    local object = getBarricadeAble(args.x, args.y, args.z, args.index)
    if object then
        local barricade = object:getBarricadeOnSameSquare()
        if not barricade then barricade = object:getBarricadeOnOppositeSquare() end
        if barricade then
            if barricade:isMetal() then
                local metal = barricade:removeMetal(nil)
            elseif barricade:isMetalBar() then
                local bar = barricade:removeMetalBar(nil)
            else
                local plank = barricade:removePlank(nil)
                if barricade:getNumPlanks() > 0 then
                    barricade:sendObjectChange('state')
                end
            end
        end
    end
end

BanditServer.Commands.Barricade = function(player, args)
    local object = getBarricadeAble(args.x, args.y, args.z, args.index)
    if object then
        local barricade = IsoBarricade.AddBarricadeToObject(object, player)
        if barricade then
            if not barricade:isMetal() and args.isMetal then
                local metal = BanditCompatibility.InstanceItem("Base.SheetMetal")
                metal:setCondition(args.condition)
                barricade:addMetal(nil, metal)
                barricade:transmitCompleteItemToClients()
            elseif not barricade:isMetalBar() and args.isMetalBar then
                local metal = BanditCompatibility.InstanceItem("Base.MetalBar")
                metal:setCondition(args.condition)
                barricade:addMetalBar(nil, metal)
                barricade:transmitCompleteItemToClients()
            elseif barricade:getNumPlanks() < 4 then
                local plank = BanditCompatibility.InstanceItem("Base.Plank")
                plank:setCondition(args.condition)
                barricade:addPlank(nil, plank)
                if barricade:getNumPlanks() == 1 then
                    barricade:transmitCompleteItemToClients()
                else
                    barricade:sendObjectChange('state')
                end
            end
        end
    else
        noise('expected BarricadeAble')
    end
end

BanditServer.Commands.OpenDoor = function(player, args)
    local sq = getCell():getGridSquare(args.x, args.y, args.z)
    if sq and args.index >= 0 and args.index < sq:getObjects():size() then
        local object = sq:getObjects():get(args.index)
        if instanceof(object, "IsoDoor") or (instanceof(object, 'IsoThumpable') and object:isDoor() == true) then
            if not object:IsOpen() then
                object:ToggleDoorSilent()
            end
        end
    end
end

BanditServer.Commands.CloseDoor = function(player, args)
    local sq = getCell():getGridSquare(args.x, args.y, args.z)
    if sq and args.index >= 0 and args.index < sq:getObjects():size() then
        local object = sq:getObjects():get(args.index)
        if instanceof(object, "IsoDoor") or (instanceof(object, 'IsoThumpable') and object:isDoor() == true) then
            if object:IsOpen() then
                object:ToggleDoorSilent()
            end
        end
    end
end

BanditServer.Commands.LockDoor = function(player, args)
    local sq = getCell():getGridSquare(args.x, args.y, args.z)
    if sq and args.index >= 0 and args.index < sq:getObjects():size() then
        local object = sq:getObjects():get(args.index)
        if instanceof(object, "IsoDoor") or (instanceof(object, 'IsoThumpable') and object:isDoor() == true) then
            if not object:isLockedByKey() then
                object:setLockedByKey(true)
            end
        end
    end
end

BanditServer.Commands.UnlockDoor = function(player, args)
    local sq = getCell():getGridSquare(args.x, args.y, args.z)
    if sq and args.index >= 0 and args.index < sq:getObjects():size() then
        local object = sq:getObjects():get(args.index)
        if instanceof(object, "IsoDoor") or (instanceof(object, 'IsoThumpable') and object:isDoor() == true) then
            if object:isLockedByKey() then
                object:setLockedByKey(false)
            end
        end
    end
end

BanditServer.Commands.VehiclePartRemove = function(player, args)
    local sq = getCell():getGridSquare(args.x, args.y, 0)
    if sq then
        local vehicle = sq:getVehicleContainer()
        if vehicle then
            local vehiclePart = vehicle:getPartById(args.id)
            if vehiclePart then
                vehiclePart:setInventoryItem(nil)
                vehicle:transmitPartItem(vehiclePart)
                vehicle:updatePartStats()
            end
        end
    end
end

BanditServer.Commands.VehiclePartDamage = function(player, args)
    local sq = getCell():getGridSquare(args.x, args.y, 0)
    if sq then
        local vehicle = sq:getVehicleContainer()
        if vehicle then
            local vehiclePart = vehicle:getPartById(args.id)
            if vehiclePart then
                vehiclePart:damage(args.dmg)

                if vehiclePart:getCondition() <= 0 then
                    vehiclePart:setInventoryItem(nil)
                    vehicle:transmitPartItem(vehiclePart)
                else
                    vehicle:transmitPartCondition(vehiclePart)
                end
                vehicle:updatePartStats()
            end
        end
    end
end

BanditServer.Commands.IncrementBanditKills = function(player, args)
    local gmd = GetBanditModData()
    local id = BanditUtils.GetCharacterID(player)
    if gmd.Kills[id] then
        gmd.Kills[id] = gmd.Kills[id] + 1
    else
        gmd.Kills[id] = 1
    end
end

BanditServer.Commands.ResetBanditKills = function(player, args)
    local gmd = GetBanditModData()
    local id = BanditUtils.GetCharacterID(player)
    if gmd.Kills[id] then
        gmd.Kills[id] = 0
    end
end

BanditServer.Commands.UpdateVisitedBuilding = function(player, args)
    local gmd = GetBanditModData()
    gmd.VisitedBuildings[args.bid] = args.wah 
end

local onClientCommand = function(module, command, player, args)
    if module == "Commands" and BanditServer[module] and BanditServer[module][command] then
        local argStr = ""
        for k, v in pairs(args) do
            argStr = argStr .. " " .. k .. "=" .. tostring(v)
        end
        -- print ("received " .. module .. "." .. command .. " "  .. argStr)
        BanditServer[module][command](player, args)

        TransmitBanditModData()
    end
end

Events.OnClientCommand.Add(onClientCommand)
