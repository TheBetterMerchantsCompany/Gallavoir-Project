require "/scripts/interp.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"

--cut up version of LightningBolt
LightningBolt = WeaponAbility:new()

function LightningBolt:init()
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime
  self.impactSoundTimer = 0
  self.healTimer = 0
  
  self.range = config.getParameter("range", 2)
  self.targetMaxDistance = config.getParameter("targetMaxDistance", 32)
  self.targetScanExponent = config.getParameter("targetScanExponent", 2) --not really an exponent (more like a base) but w/e
  
  self.beamLength = config.getParameter("beamLength", 4)
  self.beamShift = config.getParameter("beamShift", 0.25)
    
  self.beams = {}

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
  self.healTimer = math.max(0, self.healTimer - self.dt)

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and not world.lineTileCollision(mcontroller.position(), self:firePosition())
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy") then

    self:setState(self.fire)
  end
end

function LightningBolt:fire()
  self.weapon:setStance(self.stances.fire)

  animator.playSound("fireStart")
  animator.playSound("fireLoop", -1)
  
  local target = nil
  local hit = false
  
  while self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not world.lineTileCollision(mcontroller.position(), self:firePosition())
    and status.overConsumeResource("energy", (self.energyUsage or 0) * self.dt / 4)
    do
    animator.setAnimationState("firing", "fire", true)
    
    if target ~= nil and (not world.entityExists(target) or (world.magnitude(world.entityPosition(target), mcontroller.position()) > self.targetMaxDistance)) then target = nil end
    
    if target == nil then target = self:findTargets() end
    
    if target then
      hit = self:hitTarget(target)
    end
    
    if hit then
      status.overConsumeResource("energy", (self.energyUsage or 0) * self.dt * 3 / 4)
      if self.healTimer == 0 then
        world.sendEntityMessage(target, "applyStatusEffect", self.healingEffect, self.fireTime, activeItem.ownerEntityId())
        self.healTimer = self.fireTime
      end
    else
      target = nil
      self.beams = {}
    end
    
    self:drawBeams(self.color)
    hit = false
    coroutine.yield()
  end

  self:reset()
  animator.playSound("fireEnd")

  self.cooldownTimer = self.fireTime - self.stances.cooldown.duration
  self:setState(self.cooldown)
end

function LightningBolt:hitTarget(target)
  local vector = {self.beamLength, 0}
  local currentPos = {0, 0}
  local targetCoords = self:localPos(world.entityPosition(target))
  local beamShift = self.beamShift
  
  local _, aimDirection = activeItem.aimAngleAndDirection(self.weapon.aimOffset, activeItem.ownerAimPosition())
  
  local ctr = self.targetMaxDistance / self.beamLength
  
  world.debugPoint(self:worldPos(targetCoords), "blue")
  
  while ctr >= 0 do    
    if vec2.mag(vec2.sub(self:rotate(currentPos), targetCoords)) <= self.beamLength then
      self:drawBeam(self:rotateWorldPos(currentPos), world.entityPosition(target))
      return true
    end
    
    beamShift = beamShift * self.targetScanExponent
    
    local angle = util.angleDiff(vec2.angle(self:rotate(vec2.add(currentPos, vector))),vec2.angle(targetCoords))
    local beamAngle = vec2.angle({vector[1], beamShift})
    
    local oldPos = currentPos
    
    angle = util.clamp(angle, -beamAngle, beamAngle)
    vector = vec2.rotate(vector, angle * aimDirection)    
    currentPos = vec2.add(currentPos, vector)
    
    world.debugText("%s", beamShift, self:worldPos({currentPos[1] * aimDirection, 1}), "blue")
    
    self:drawBeam(self:rotateWorldPos(oldPos), self:rotateWorldPos(currentPos))
    
    ctr = ctr - 1
  end
  return false
end

function LightningBolt:drawBeam(beamStart, beamEnd)
  local beam = {
    beamStart = beamStart,
    beamEnd = beamEnd
  }
  table.insert(self.beams, beam)
end

function LightningBolt:drawBeams(color)
  local lightning = {}
  
  for _, beam in pairs(self.beams) do
    
    for i = 1, self.amount do
      local bolt = {
        minDisplacement = 0.125,
        forks = self.forks,
        forkAngleRange = 0.75,
        width = self.width,
        color = color or self.color
      }
      bolt.worldStartPosition = beam.beamStart
      bolt.worldEndPosition = beam.beamEnd
      bolt.displacement = math.min(1.75, world.magnitude(bolt.worldEndPosition, bolt.worldStartPosition) / 8)
      table.insert(lightning, bolt)
    end
  end
  
  self.beams = {}
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

function LightningBolt:rotate(vector)
  return activeItem.handPosition(vec2.add(self.weapon.muzzleOffset, vector))
end

function LightningBolt:rotateRelative(vector)
  return vec2.rotate(vector, self.weapon.relativeWeaponRotation)
end

function LightningBolt:rotateWorldPos(vector)
  return vec2.add(mcontroller.position(), activeItem.handPosition(vec2.add(self.weapon.muzzleOffset, vector)))
end

function LightningBolt:worldPos(vector)
  return vec2.add(mcontroller.position(), vector)
end

function LightningBolt:localPos(vector)
  return world.distance(vector, mcontroller.position())
end

function LightningBolt:itemPos(point)
  return vec2.add(point, self.weapon.muzzleOffset)
end
    
function LightningBolt:unfuckPos(vector)
  local aimAngle, aimDirection = activeItem.aimAngleAndDirection(self.weapon.aimOffset, activeItem.ownerAimPosition())
--local endPoint = world.distance(vector, mcontroller.position())
--endPoint = vec2.sub(endPoint, activeItem.handPosition())
--endPoint = vec2.rotate(endPoint, -aimAngle*aimDirection)
  local endPoint = vec2.rotate(vec2.sub(world.distance(vector, mcontroller.position()), activeItem.handPosition()), -aimAngle*aimDirection)
  endPoint[1] = endPoint[1]*aimDirection
  return endPoint
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

function LightningBolt:findTargets()
  if world.magnitude(activeItem.ownerAimPosition(), mcontroller.position()) < self.targetMaxDistance then
    return self:findTarget(activeItem.ownerAimPosition(), self.range)
  end
  return nil
end


function LightningBolt:findTarget(pos, range)
  self:debugQuery(pos, range)
  local nearEntities = world.entityQuery(pos, range, {
    includedTypes = {"npc", "monster", "player"},
    order = "nearest"
  })
  nearEntities = util.filter(nearEntities, function(entityId)
    if not world.entityCanDamage(activeItem.ownerEntityId(), entityId) then
      return true
    end

    if (world.entityDamageTeam(entityId).type == "passive") then
      return true
    end

    return false
  end)
  return nearEntities[1]
end


function LightningBolt:debugQuery(pos, range)
  world.debugPoly({
    vec2.add(pos, {0,-range}),
    vec2.add(pos, {range,0}),
    vec2.add(pos, {0,range}),
    vec2.add(pos, {-range,0})
  }, {255,0,0})
end