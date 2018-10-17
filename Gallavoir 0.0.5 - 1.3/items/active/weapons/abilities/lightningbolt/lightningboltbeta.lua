require "/scripts/interp.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"

LightningBolt = WeaponAbility:new()

function LightningBolt:init()
  self.damageConfig.baseDamage = self.baseDps * self.fireTime

  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime
  self.impactSoundTimer = 0

  self.weapon.onLeaveAbility = function()
    self.weapon:setDamage()
    activeItem.setScriptedAnimationParameter("lightning", {})
    animator.stopAllSounds("fireLoop")
    self.weapon:setStance(self.stances.idle)
  end
end

function LightningBolt:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  self.impactSoundTimer = math.max(self.impactSoundTimer - self.dt, 0)

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and not world.lineTileCollision(mcontroller.position(), self:firePosition())
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
    and self:findTarget() then

    self:setState(self.fire)
  end
end

function LightningBolt:fire()
  self.weapon:setStance(self.stances.fire)

  animator.playSound("fireStart")
  animator.playSound("fireLoop", -1)

  local wasColliding = false
  while self.fireMode == (self.activatingFireMode or self.abilitySlot) and status.overConsumeResource("energy", (self.energyUsage or 0) * self.dt) do
    local beamStart = self:firePosition()
    local beamEnd = self:findTarget()
    local beamLength = self.beamLength

    if not beamEnd then break end
    
    local collidePoint = world.lineCollision(beamStart, beamEnd)
    if collidePoint then
      beamEnd = collidePoint
      beamLength = world.magnitude(beamStart, beamEnd)
    end
    
    local aimAngle, aimDirection = activeItem.aimAngleAndDirection(self.weapon.aimOffset, activeItem.ownerAimPosition())
    local endPoint = vec2.rotate(vec2.sub(beamEnd,mcontroller.position()), -aimAngle*aimDirection)
    endPoint[1] = endPoint[1]*aimDirection
    --endPoint[2] = endPoint[2]*aimDirection
    --sb.logInfo("%s",endPoint)
    --sb.logInfo("%s",aimDirection)

    self.weapon:setDamage(self.damageConfig, {self.weapon.muzzleOffset, endPoint}, self.fireTime)
    self:drawBeam(beamEnd)
    coroutine.yield()
  end

  self:reset()
  animator.playSound("fireEnd")

  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)
end

function LightningBolt:drawBeam(beamEnd)
  local lightning = {}
  for i = 1, self.amount do
    local bolt = {
      minDisplacement = 0.125,
      forks = self.forks,
      forkAngleRange = 0.75,
      width = self.width,
      color = self.color
    }
    bolt.itemStartPosition = vec2.rotate(self.weapon.muzzleOffset, self.weapon.relativeWeaponRotation)
    bolt.worldEndPosition = beamEnd
    bolt.displacement = math.min(1.75, vec2.mag(vec2.sub(bolt.worldEndPosition, self:firePosition())) / 8)
    table.insert(lightning, bolt)
  end
  activeItem.setScriptedAnimationParameter("lightning", lightning)
end

function LightningBolt:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()

  util.wait(self.stances.cooldown.duration, function()

  end)
end

function LightningBolt:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function LightningBolt:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function LightningBolt:uninit()
  self:reset()
end

function LightningBolt:reset()
  self.weapon:setDamage()
  activeItem.setScriptedAnimationParameter("lightning", {})
  animator.stopAllSounds("fireStart")
  animator.stopAllSounds("fireLoop")
end

function LightningBolt:findTarget()
  local nearEntities = world.entityQuery(activeItem.ownerAimPosition(), self.queryRange, {
    includedTypes = {"npc", "monster", "player"},
    order = "nearest"
  })
  nearEntities = util.filter(nearEntities, function(entityId)
    if world.lineTileCollision(self:firePosition(), world.entityPosition(entityId)) then
      return false
    end
    -- sb.logInfo("%s",world.entityTypeName(entityId))
    if not world.entityCanDamage(activeItem.ownerEntityId(), entityId) then
      return false
    end

    if (world.entityDamageTeam(entityId).type == "passive") and (world.entityTypeName(entityId) ~= "punchy") then
      return false
    end

    return true
  end)
  local targetId = nearEntities[1]
  if targetId then return world.entityPosition(targetId) else return nil end
end
