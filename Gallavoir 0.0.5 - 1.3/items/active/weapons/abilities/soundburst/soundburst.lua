require "/scripts/interp.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"

SoundBurst = WeaponAbility:new()

function SoundBurst:init()
  self.damageConfig.baseDamage = self.baseDps * self.fireTime
  
  self.pitch = {
    261.63,
    277.18,
    293.66,
    311.13,
    329.63,
    349.23,
    369.99,
    392.00,
    415.30,
    440.00,
    466.16,
    493.88 
  }
  for i, wave in ipairs(self.pitch) do
    self.pitch[i] = wave / 440.00
  end
  
  sb.logInfo("%s", self.pitch)
  
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime

  self.weapon.onLeaveAbility = function()
    self.weapon:setDamage()
    activeItem.setScriptedAnimationParameter("chains", {})
    self.weapon:setStance(self.stances.idle)
  end
end

function SoundBurst:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy") then

    self:setState(self.fire)
  end
end

function SoundBurst:fire()
  self.weapon:setStance(self.stances.fire)
  
  if self.stances.fire.charge then
    animator.playSound("charge")
    util.wait(self.stances.fire.charge)
  end
  
  animator.stopAllSounds("charge")
  self:playFireSound()
  
  status.overConsumeResource("energy", (self.energyUsage or 0) * self.fireTime)

  local wasColliding = false
  
  util.wait(self.stances.fire.duration, function()
    local beamStart = self:firePosition()
    local beamEnd = vec2.add(beamStart, vec2.mul(vec2.norm(self:aimVector(0)), self.beamLength))
  
    self:setDamage(self.damageConfig, {self.weapon.muzzleOffset, {self.weapon.muzzleOffset[1] + self.beamLength, self.weapon.muzzleOffset[2] - self.beamWidth}, {self.weapon.muzzleOffset[1] + self.beamLength, self.weapon.muzzleOffset[2] + self.beamWidth}}, self.fireTime)
  
    self:drawBeam(beamEnd, self.beamLength)
  end)
  
  self:reset()

  animator.setSoundVolume("fireMale", 0, self.stances.fire.cooldown)
  animator.setSoundVolume("fireFemale", 0, self.stances.fire.cooldown)
  
  util.wait(self.stances.fire.cooldown, function()
    local beamStart = self:firePosition()
    local beamEnd = vec2.add(beamStart, vec2.mul(vec2.norm(self:aimVector(0)), self.beamLength))
    
    self:drawWeakBeam(beamEnd, self.beamLength)
  end)
  
  animator.stopAllSounds("fireMale")
  animator.stopAllSounds("fireFemale")
  
  self:reset()
  
  self.cooldownTimer = self.fireTime - self.stances.fire.duration - self.stances.fire.cooldown
  self:setState(self.cooldown)
end

function SoundBurst:playFireSound()
  if player.gender() == "male" then
    animator.setSoundVolume("fireMale", self.volume, 0)
    animator.setSoundPitch("fireMale", self.pitch[math.random(12)], 0)
    animator.playSound("fireMale")
  else
    animator.setSoundVolume("fireFemale", self.volume, 0)
    animator.setSoundPitch("fireFemale", self.pitch[math.random(12)], 0)
    animator.playSound("fireFemale")
  end
end

function SoundBurst:drawBeam(endPos, beamLength)
  local newChain = copy(self.chain)
  newChain.startOffset = self.weapon.muzzleOffset
  newChain.endPosition = endPos
  newChain.length = beamLength
  newChain.maxLength = self.beamLength
  newChain.maxWidth = self.beamWidth

  activeItem.setScriptedAnimationParameter("chains", {newChain})
end

function SoundBurst:drawWeakBeam(endPos, beamLength)
  local newChain = copy(self.chainWeak)
  newChain.startOffset = self.weapon.muzzleOffset
  newChain.endPosition = endPos
  newChain.length = beamLength
  newChain.maxLength = self.beamLength
  newChain.maxWidth = self.beamWidth

  activeItem.setScriptedAnimationParameter("chains", {newChain})
end

function SoundBurst:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()

  util.wait(self.stances.cooldown.duration, function()

  end)
end

function SoundBurst:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function SoundBurst:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function SoundBurst:setDamage(damageConfig, damageArea, damageTimeout)
  self.weapon.damageWasSet = true
  self.weapon.damageCleared = false
  activeItem.setItemDamageSources({ self:damageSource(damageConfig, damageArea, damageTimeout) })
end

function SoundBurst:damageSource(damageConfig, damageArea, damageTimeout)
  if damageArea then
    local knockback = damageConfig.knockback
    if knockback and damageConfig.knockbackDirectional ~= false then
      knockback = knockbackMomentum(damageConfig.knockback, damageConfig.knockbackMode, self.weapon.aimAngle, self.weapon.aimDirection)
    end
    local damage = damageConfig.baseDamage * self.weapon.damageLevelMultiplier * activeItem.ownerPowerMultiplier()

    local damageLine, damagePoly
    if #damageArea == 2 then
      damageLine = damageArea
    else
      damagePoly = damageArea
    end

    return {
      poly = damagePoly,
      line = damageLine,
      damage = damage,
      trackSourceEntity = damageConfig.trackSourceEntity,
      sourceEntity = activeItem.ownerEntityId(),
      team = activeItem.ownerTeam(),
      damageSourceKind = damageConfig.damageSourceKind,
      statusEffects = damageConfig.statusEffects,
      knockback = knockback or 0,
      rayCheck = damageConfig.rayCheck,
      damageRepeatGroup = damageRepeatGroup(damageConfig.timeoutGroup),
      damageRepeatTimeout = damageTimeout or damageConfig.timeout
    }
  end
end

function SoundBurst:uninit()
  self:reset()
end

function SoundBurst:reset()
  self.weapon:setDamage()
  activeItem.setScriptedAnimationParameter("chains", {})
end
