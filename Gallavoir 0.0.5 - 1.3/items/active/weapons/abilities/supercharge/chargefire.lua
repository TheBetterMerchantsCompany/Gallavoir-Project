require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/interp.lua"

ChargeFire = WeaponAbility:new()

function ChargeFire:init()
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = 0
  self.chargeTimer = 0
  
  self.chargeLevel = {}
  self.chargeLevelPrev = {}
  local offset = config.getParameter("muzzleOffset")
  offset[1] = offset[1] + 0.5
  offset[2] = offset[2] - 0.125
  self.beams[1].offset = offset
  self.beams[2].offset = offset
  
  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

function ChargeFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and self.cooldownTimer == 0
    and not self.weapon.currentAbility
    and not world.lineTileCollision(mcontroller.position(), self:firePosition())
    and not status.resourceLocked("energy") then

    self:setState(self.charge)
  end
end

function ChargeFire:charge()
  self.weapon:setStance(self.stances.charge)

  animator.setAnimationState("firing", "charge")
  animator.playSound("charge")
  
  
  self.chargeTimer = 0
  self.chargeLevelPrev = self:currentChargeLevel()
  
  while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    self.chargeTimer = self.chargeTimer + self.dt
    
    --sb.logInfo("%s",self.beams)
    
    self.beams[1].angle = 0+(self:levelStat(self.chargeLevels[1].inaccuracy,self.chargeLevels[#self.chargeLevels].inaccuracy)*2)
    self.beams[2].angle = 0-(self:levelStat(self.chargeLevels[1].inaccuracy,self.chargeLevels[#self.chargeLevels].inaccuracy)*2)
    
    activeItem.setScriptedAnimationParameter("beams", self.beams)

    if self.chargeLevelPrev ~= self:currentChargeLevel() then
      self.chargeLevelPrev = self:currentChargeLevel()
      chargeLevelses = self.chargeLevels
      animator.playSound(self.chargeLevelPrev.chargedSound or "charged")
      if self.chargeLevelPrev == chargeLevelses[#chargeLevelses] then
        animator.stopAllSounds("charge")
      end
    end
    
    coroutine.yield()
  end
  animator.stopAllSounds("charge")
  
  activeItem.setScriptedAnimationParameter("beams", {})
  
  self.chargeLevel = self:currentChargeLevel()
  local energyCost = self:levelStat(self.chargeLevels[1].energyCost,self.chargeLevels[#self.chargeLevels].energyCost) or 0
  if self.chargeLevel and (energyCost == 0 or status.overConsumeResource("energy", energyCost)) then
    self:setState(self.fire)
  end
end

function ChargeFire:fire()
  if world.lineTileCollision(mcontroller.position(), self:firePosition()) then
    animator.setAnimationState("firing", "off")
    self.cooldownTimer = self.chargeLevel.cooldown or 0
    self:setState(self.cooldown, self.cooldownTimer)
    return
  end

  self.weapon:setStance(self.stances.fire)

  animator.setAnimationState("firing", self.chargeLevel.fireAnimationState or "fire")
  animator.playSound(self.chargeLevel.fireSound or "fire")

  self:fireProjectile()

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.chargeLevel.cooldown or 0

  self:setState(self.cooldown, self.cooldownTimer)
end

function ChargeFire:cooldown(duration)
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()

  local progress = 0
  util.wait(duration, function()
    local from = self.stances.cooldown.weaponOffset or {0,0}
    local to = self.stances.idle.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.weaponRotation, self.stances.idle.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.armRotation, self.stances.idle.armRotation))

    progress = math.min(1.0, progress + (self.dt / duration))
  end)
end

function ChargeFire:fireProjectile()
  local projectileCount = self:levelStat(self.chargeLevels[1].projectileCount or 1, self.chargeLevels[#self.chargeLevels].projectileCount or 1)

  local params = copy(self.chargeLevel.projectileParameters or config.getParameter("primaryAbility").projectileParameters)
  params.power = (self:levelStat(self.chargeLevels[1].baseDamage,self.chargeLevels[#self.chargeLevels].baseDamage) * config.getParameter("damageLevelMultiplier")) / projectileCount
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  
  --sb.logInfo("%s",self:levelStat(self.chargeLevels[1].inaccuracy,self.chargeLevels[#self.chargeLevels].inaccuracy))
  
  local spreadAngle = util.toRadians(self.chargeLevel.spreadAngle or 0)
  local totalSpread = spreadAngle * (projectileCount - 1)
  local currentAngle = totalSpread * -0.5
  for i = 1, projectileCount do
    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end

    world.spawnProjectile(
        config.getParameter("primaryAbility").projectileType or self.chargeLevel.projectileType,
        self:firePosition(),
        activeItem.ownerEntityId(),
        self:aimVector(currentAngle, self:levelStat(self.chargeLevels[1].inaccuracy,self.chargeLevels[#self.chargeLevels].inaccuracy) or 0),
        false,
        params
      )

    currentAngle = currentAngle + spreadAngle
  end
end

function ChargeFire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function ChargeFire:aimVector(angleAdjust, inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + angleAdjust + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function ChargeFire:currentChargeLevel()
  local bestChargeTime = 0
  local bestChargeLevel
  for _, chargeLevel in pairs(self.chargeLevels) do
    if self.chargeTimer >= chargeLevel.time and self.chargeTimer >= bestChargeTime then
      bestChargeTime = chargeLevel.time
      bestChargeLevel = chargeLevel
    end
  end
  return bestChargeLevel
end

function ChargeFire:levelStat(minstat, maxstat)
  local chargeTime = math.min(self.chargeTimer, self.chargeLevels[#self.chargeLevels].time)
  if minstat < maxstat then return ((maxstat - minstat) * (chargeTime / self.chargeLevels[#self.chargeLevels].time) + minstat)
  elseif minstat > maxstat then return ((minstat - maxstat) * (1 - (chargeTime / self.chargeLevels[#self.chargeLevels].time)) + maxstat)
  else return minstat end -- you nigga what  
end

function ChargeFire:drawLazors(minstat, maxstat)
  
end

function ChargeFire:uninit()

end
