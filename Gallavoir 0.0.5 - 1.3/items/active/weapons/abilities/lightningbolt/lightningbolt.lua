require "/scripts/interp.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"

LightningBolt = WeaponAbility:new()

function LightningBolt:init()
  self.damageConfig.baseDamage = self.baseDps * self.fireTime

  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime
  self.discharge = 0.15
  self.impactSoundTimer = 0
  
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

  local ded = false
  while self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not world.lineTileCollision(mcontroller.position(), self:firePosition())
    and status.overConsumeResource("energy", (self.energyUsage or 0) * self.dt / 4)
    do
    animator.setAnimationState("firing", "fire", true)
    
    local target = self:findTargets()
    
    if target then
      ded = self:hitTarget(target)
    else
      ded = self:shortCircuit()
    end
    
    if ded then status.overConsumeResource("energy", (self.energyUsage or 0) * self.dt * 3 / 4) end
    
    self:drawBeams(ded and self.color or self.weakColor)
    ded = false
    coroutine.yield()
  end

  self:reset()
  animator.playSound("fireEnd")

  self.cooldownTimer = self.fireTime - self.discharge
  self:setState(self.cooldown)
end

function LightningBolt:shortCircuit()
  local collidePoint = world.lineCollision(self:rotateWorldPos({0, 0}), self:rotateWorldPos({3, 0}))
  if collidePoint then
    self:drawBeam(self:rotateWorldPos({0, 0}), collidePoint)
    return true
  else
    self:drawBeam(self:rotateWorldPos({0, 0}), self:rotateWorldPos({1.5, 0}))
    
    collidePoint = world.lineCollision(self:rotateWorldPos({3, 3}), self:rotateWorldPos({3, -3}))
    if collidePoint then
      self:drawBeam(self:rotateWorldPos({1.5, 0}), collidePoint)
      return true
    else
      return false
    end
  end
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
      local collidePoint = world.lineCollision(self:rotateWorldPos(currentPos), world.entityPosition(target))
      if collidePoint then
        self:drawBeam(self:rotateWorldPos(currentPos), collidePoint)
      else
        self:drawBeam(self:rotateWorldPos(currentPos), world.entityPosition(target))
      end
      return true
    end
    
    beamShift = beamShift * self.targetScanExponent
    
    local angle = util.angleDiff(vec2.angle(self:rotate(vec2.add(currentPos, vector))),vec2.angle(targetCoords))
    local beamAngle = vec2.angle({vector[1], beamShift})
    
    local oldPos = currentPos
    
    angle = util.clamp(angle, -beamAngle, beamAngle)
    vector = vec2.rotate(vector, angle * aimDirection)    
    currentPos = vec2.add(currentPos, vector)
    
    
    local collidePoint = world.lineCollision(self:rotateWorldPos(oldPos), self:rotateWorldPos(currentPos))
    if collidePoint then
      self:drawBeam(self:rotateWorldPos(oldPos), collidePoint)
      return true
    end
    
    world.debugText("%s", string.format("%.1f:%.1f",oldPos[1],oldPos[2]), self:worldPos({currentPos[1] * aimDirection, 1}), "blue")
    world.debugText("%s", string.format("%.1f:%.1f",currentPos[1],currentPos[2]), self:worldPos({currentPos[1] * aimDirection, 2}), "green")
    
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

--also does damage cause wynaut
function LightningBolt:drawBeams(color)
  local areas = {}
  local lightning = {}
  
  for _, beam in pairs(self.beams) do
    local area = {self:unfuckPos(beam.beamStart), self:unfuckPos(beam.beamEnd)}
    table.insert(areas, area)
    
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
  self.weapon:setDamageAreas(self.damageConfig, areas, self.fireTime)
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
  return activeItem.handPosition(vec2.add(vector, self.weapon.muzzleOffset))
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

function LightningBolt:itemPos(vector)
  return vec2.add(vector, self.weapon.muzzleOffset)
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
  local range = 1
  local target = nil
  while (target == nil) and (range < self.targetMaxDistance) do
    target = self:findTarget(self:itemPos({range, 0}), range)
    range = range * self.targetScanExponent
    --sb.logInfo("%s:%s", target, range)
  end
  return target
end


function LightningBolt:findTarget(pos, range)
  self:debugQuery(pos, range)
  local nearEntities = world.entityQuery(self:rotateWorldPos(pos), range, {
    includedTypes = {"npc", "monster", "player"},
    order = "nearest"
  })
  nearEntities = util.filter(nearEntities, function(entityId)
    -- sb.logInfo("%s",world.entityTypeName(entityId))
    if not world.entityCanDamage(activeItem.ownerEntityId(), entityId) then
      return false
    end

    if (world.entityDamageTeam(entityId).type == "passive") and (world.entityTypeName(entityId) ~= "punchy") then
      return false
    end

    return true
  end)
  return nearEntities[1]
end


function LightningBolt:debugQuery(pos, range)
  world.debugPoly({
    vec2.add(self:rotateWorldPos(pos), {0,-range}),
    vec2.add(self:rotateWorldPos(pos), {range,0}),
    vec2.add(self:rotateWorldPos(pos), {0,range}),
    vec2.add(self:rotateWorldPos(pos), {-range,0})
  }, {255,0,0})
end