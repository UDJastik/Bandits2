ZombieActions = ZombieActions or {}

ZombieActions.Shoot = {}
ZombieActions.Shoot.onStart = function(zombie, task)
    zombie:setBumpType(task.anim)
    return true
end

ZombieActions.Shoot.onWorking = function(zombie, task)
    local enemy = BanditZombie.Cache[task.eid] or BanditPlayer.GetPlayerById(task.eid)
    if not enemy then return true end
    zombie:faceLocationF(enemy:getX(), enemy:getY())

    if task.time <= 0 then
        return true
    end

    if zombie:getBumpType() ~= task.anim then 
        zombie:setBumpType(task.anim)
    end

    return false
end

ZombieActions.Shoot.onComplete = function(zombie, task)

    local bumpType = zombie:getBumpType()
    if bumpType ~= task.anim then return true end

    local shooter = zombie
    local sx, sy, sz, sd = shooter:getX(), shooter:getY(), shooter:getZ(), shooter:getDirectionAngle()
    local brainShooter = BanditBrain.Get(shooter)
    local weapon = brainShooter.weapons[task.slot]
    local weaponItem = BanditCompatibility.InstanceItem(weapon.name)
    if not weaponItem then return true end

    weaponItem = BanditUtils.ModifyWeapon(weaponItem, brainShooter)

    local enemy = BanditZombie.Cache[task.eid] or BanditPlayer.GetPlayerById(task.eid)
    if not enemy then return true end

    if not BanditUtils.IsFacing(sx, sy, sd, enemy:getX(), enemy:getY(), 5) then 
        return true
    end

    -- deplete round
    weapon.bulletsLeft = weapon.bulletsLeft - 1
    Bandit.UpdateItemsToSpawnAtDeath(shooter)

    -- handle flash and projectile
    BanditCompatibility.StartMuzzleFlash(shooter)
    local reloadType = weaponItem:getWeaponReloadType()
    local projectiles = BanditUtils.GetProjectileCount(reloadType)
    BanditProjectile.Add(brainShooter.id, sx, sy, sz, sd, projectiles)

    -- handle real and "world" sound 
    -- local emitter = getWorld():getFreeEmitter(sx, sy, sz)
    local emitter = zombie:getEmitter()
    local swingSound = weaponItem:getSwingSound()
    -- emitter:stopAll()
    local long = emitter:playSound(swingSound)
    -- emitter:setParameterValueByName(long, "CameraZoom", 1.0)

    --[[
    local wsm = getWorldSoundManager()
    local radius = weaponItem:getSoundRadius()
    local volume = weaponItem:getSoundVolume()
    wsm:addSound(zombie, math.floor(sx), math.floor(sy), math.floor(sz), radius, volume, false)]]

    local radius = weaponItem:getSoundRadius()
    local volume = weaponItem:getSoundVolume()
    local zombieList = BanditZombie.CacheLightZ
    for id, zombie in pairs(zombieList) do
        local dist = math.abs(sx - zombie.x) + math.abs(sy - zombie.y)
        if dist < radius then
            local zombie = BanditZombie.Cache[id]
            if zombie then
                zombie:pathToLocationF(sx, sy, sz)
            end
        end
    end

    -- manage line of fire damage to characters and objects
    if BanditUtils.LineClear(shooter, enemy) then
        BanditUtils.ManageLineOfFire(shooter, enemy, weaponItem)
    end

    -- handle post-shot things
    if not weaponItem:isManuallyRemoveSpentRounds() then
        shooter:playSound(weaponItem:getShellFallSound())
    end

    if weaponItem:isRackAfterShoot() then
        weapon.racked = false
    end

    return true
end