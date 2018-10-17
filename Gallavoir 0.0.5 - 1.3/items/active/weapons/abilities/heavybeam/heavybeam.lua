require "/scripts/interp.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"

HeavyBeam = WeaponAbility:new()

function HeavyBeam:init()
  self.damageConfig.baseDamage = self.baseDps * self.fireTime

  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime
  self.impactSoundTimer = 0

  self.weapon.onLeaveAbility = function()
    self.weapon:setDamage()
    activeItem.setScriptedAnimationParameter("chains", {})
    animator.setParticleEmitterActive("beamCollision", false)
    animator.stopAllSounds("fireLoop")
    self.weapon:setStance(self.stances.idle)
  end
end

function HeavyBeam:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  self.impactSoundTimer = math.max(self.impactSoundTimer - self.dt, 0)

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and not world.lineTileCollision(mcontroller.position(), self:firePosition())
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy") then

    self:setState(self.fire)
  end
end

function HeavyBeam:fire()
  self.weapon:setStance(self.stances.fire)
  
  if self.stances.fire.charge then
    animator.playSound("charge")
    util.wait(self.stances.fire.charge)
  end
  
  animator.stopAllSounds("charge")
  animator.playSound("fire")
  
  status.overConsumeResource("energy", (self.energyUsage or 0) * self.fireTime)

  local wasColliding = false
  
  util.wait(self.stances.fire.duration, function()
    local beamStart = self:firePosition()
    local beamEnd = vec2.add(beamStart, vec2.mul(vec2.norm(self:aimVector(0)), self.beamLength))
    local beamLength = self.beamLength
    local collidePoint = world.lineCollision(beamStart, beamEnd)
    if collidePoint then
      beamEnd = collidePoint
  
      beamLength = world.magnitude(beamStart, beamEnd)
  
      animator.setParticleEmitterActive("beamCollision", true)
      animator.resetTransformationGroup("beamEnd")
      animator.translateTransformationGroup("beamEnd", {beamLength, 0})
  
      if self.impactSoundTimer == 0 then
        animator.setSoundPosition("beamImpact", {beamLength, 0})
        animator.playSound("beamImpact")
        self.impactSoundTimer = self.fireTime
      end
    else
      animator.setParticleEmitterActive("beamCollision", false)
    end
  
    self:setDamage(self.damageConfig, {self.weapon.muzzleOffset, {self.weapon.muzzleOffset[1] + beamLength, self.weapon.muzzleOffset[2]}}, self.fireTime)
  
    self:drawBeam(beamEnd, collidePoint)
  end)
  
  self:reset()

  util.wait(self.stances.fire.cooldown, function()
    local beamStart = self:firePosition()
    local beamEnd = vec2.add(beamStart, vec2.mul(vec2.norm(self:aimVector(0)), self.beamLength))
    local collidePoint = world.lineCollision(beamStart, beamEnd)
    if collidePoint then beamEnd = collidePoint end
    
    self:drawWeakBeam(beamEnd, collidePoint)
  end)
  
  self:reset()
  
  self.cooldownTimer = self.fireTime - self.stances.fire.cooldown - self.stances.fire.duration - (self.stances.fire.charge or 0)
  self:setState(self.cooldown)
end

function HeavyBeam:setDamage(damageConfig, damageArea, damageTimeout)
  self.weapon.damageWasSet = true
  self.weapon.damageCleared = false
  activeItem.setItemDamageSources({ self:damageSource(damageConfig, damageArea, damageTimeout) })
end

function HeavyBeam:damageSource(damageConfig, damageArea, damageTimeout)
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
      team = damageConfig.damageTeam or activeItem.ownerTeam(),
      damageSourceKind = damageConfig.damageSourceKind,
      statusEffects = damageConfig.statusEffects,
      knockback = knockback or 0,
      rayCheck = damageConfig.rayCheck,
      damageRepeatGroup = damageRepeatGroup(damageConfig.timeoutGroup),
      damageRepeatTimeout = damageTimeout or damageConfig.timeout
    }
  end
end

function HeavyBeam:drawBeam(endPos, didCollide)
  local newChain = copy(self.chain)
  newChain.startOffset = self.weapon.muzzleOffset
  newChain.endPosition = endPos

  if didCollide then
    newChain.endSegmentImage = nil
  end

  activeItem.setScriptedAnimationParameter("chains", {newChain})
end

function HeavyBeam:drawWeakBeam(endPos, didCollide)
  local newChain = copy(self.chainWeak)
  newChain.startOffset = self.weapon.muzzleOffset
  newChain.endPosition = endPos

  if didCollide then
    newChain.endSegmentImage = nil
  end

  activeItem.setScriptedAnimationParameter("chains", {newChain})
end
function HeavyBeam:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()

  util.wait(self.stances.cooldown.duration, function()

  end)
end

function HeavyBeam:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function HeavyBeam:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function HeavyBeam:uninit()
  self:reset()
end

function HeavyBeam:reset()
  self.weapon:setDamage()
  activeItem.setScriptedAnimationParameter("chains", {})
  animator.setParticleEmitterActive("beamCollision", false)
end
