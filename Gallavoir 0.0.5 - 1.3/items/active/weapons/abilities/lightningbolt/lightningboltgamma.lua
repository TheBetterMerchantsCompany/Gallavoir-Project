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
  
  self.beams = {}

  self.weapon.onLeaveAbility = function()
    self.weapon:setDamage()
    activeItem.setScriptedAnimationParameter("lightning", {})
    animator.stopAllSounds("fireLoop")
    self.weapon:setStance(self.stances.idle)
  end
  self.targetPoints = self.targetPoints or {{0,0},{2,0},{4,0},{8,0},{16,0},{32,0}}
  
  for id, point in pairs(self.targetPoints) do
    point = vec2.add(point, {-0.25, -0.0625}) -- muzzle offset. Fuck if i know why.
    self.targetPoints[id] = vec2.add(point, self.weapon.muzzleOffset)
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
  while self.fireMode == (self.activatingFireMode or self.abilitySlot) and status.overConsumeResource("energy", (self.energyUsage or 0) * self.dt / 4) do
    animator.setAnimationState("firing", "fire", true)
    if self:shoot(1) then ded = true
    elseif self:shoot(2) then ded = true
    elseif self:shoot(3) then ded = true
    elseif self:shoot(4) then ded = true 
    elseif self:shoot(5) then ded = true end
    
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


function LightningBolt:shoot(i)
  local beamStart = self:rotateWorldPos(self.targetPoints[i])
  local beamEnd = self:findTarget(self.targetPoints[i], self.targetPoints[i][1])
  local target = false
  
  --Target acquired, lightning is discharged
  if beamEnd then
    target = true
  end
  
  --Oh noes, we got grounded
  local collidePoint = world.lineCollision(beamStart, beamEnd or self:rotateWorldPos(self.targetPoints[i+1]))
  if collidePoint then
    beamEnd = collidePoint
    target = true
  end
  
  if target then
    self:drawBeam(vec2.rotate(self.targetPoints[i], self.weapon.relativeWeaponRotation), beamEnd)
    return true
  end
  
  --False alarm, keep searching
  beamEnd = self:rotateWorldPos(self.targetPoints[i+1])
  self:drawBeam(vec2.rotate(self.targetPoints[i], self.weapon.relativeWeaponRotation), beamEnd)
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
    local area = {beam.beamStart, self:unfuckPos(beam.beamEnd)}
    table.insert(areas, area)
    
    for i = 1, self.amount do
      local bolt = {
        minDisplacement = 0.125,
        forks = self.forks,
        forkAngleRange = 0.75,
        width = self.width,
        color = color or self.color
      }
      bolt.itemStartPosition = beam.beamStart
      bolt.worldEndPosition = beam.beamEnd
      bolt.displacement = math.min(1.75, vec2.mag(world.distance(bolt.worldEndPosition, self:firePosition())) / 8)
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
  return activeItem.handPosition(vec2.add(self.weapon.muzzleOffset, vector))
end

function LightningBolt:rotateWorldPos(vector)
  return vec2.add(mcontroller.position(), activeItem.handPosition(vector))
end

function LightningBolt:worldPos(vector)
  return vec2.add(mcontroller.position(), vector)
end

function LightningBolt:localPos(vector)
  return world.distance(vector, mcontroller.position())
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
  local targetId = nearEntities[1]
  if targetId then return world.entityPosition(targetId) else return nil end
end

function LightningBolt:debugQuery(pos, range)
  world.debugPoly({
    vec2.add(self:rotateWorldPos(pos), {0,-range}),
    vec2.add(self:rotateWorldPos(pos), {range,0}),
    vec2.add(self:rotateWorldPos(pos), {0,range}),
    vec2.add(self:rotateWorldPos(pos), {-range,0})
  }, {255,0,0})
end