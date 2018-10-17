require "/scripts/vec2.lua"
require "/scripts/util.lua"

Kinesis = WeaponAbility:new()

function Kinesis:init()
  storage.projectiles = storage.projectiles or {}

  self.elementalType = self.elementalType or self.weapon.elementalType
  self.stances = config.getParameter("stances")
  self.baseDamageFactor = config.getParameter("baseDamageFactor", 1.0)

  activeItem.setCursor("/cursors/reticle0.cursor")
  self.weapon:setStance(self.stances.idle)

  self.weapon.onLeaveAbility = function()
    self:reset()
  end
end

function Kinesis:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self:updateProjectiles()

  world.debugPoint(self:focusPosition(), "blue")

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and not status.resourceLocked("energy") then

    self:setState(self.fire)
  end
end

function Kinesis:fire()
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()
  
  activeItem.setCursor("/cursors/chargeready.cursor")
  
  if self:targetValid(activeItem.ownerAimPosition()) and status.overConsumeResource("energy", self.energyCost * self.baseDamageFactor) then
    animator.playSound("activate")
    self:createProjectiles()
  else
    animator.playSound("discharge")
    self:setState(self.cooldown)
    return
  end
  
  while #storage.projectiles > 0 and self.fireMode == (self.activatingFireMode or self.abilitySlot) and status.overConsumeResource("energy", (self.energyCost or 0) * self.dt) do
    coroutine.yield()
  end
  
  self:killProjectiles()
      
  self:setState(self.cooldown)
end

function Kinesis:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon.aimAngle = 0
  
  animator.setAnimationState("charge", "discharge")
  animator.setParticleEmitterActive(self.elementalType .. "charge", false)
  activeItem.setCursor("/cursors/reticle0.cursor")

  util.wait(self.stances.cooldown.duration, function()

  end)
end

function Kinesis:targetValid(aimPos)
  local focusPos = self:focusPosition()
  return world.magnitude(focusPos, aimPos) <= self.maxCastRange
end

function Kinesis:createProjectiles()
  local aimPosition = activeItem.ownerAimPosition()
  local fireDirection = world.distance(aimPosition, self:focusPosition())[1] > 0 and 1 or -1
  local pOffset = {fireDirection * (self.projectileDistance or 0), 0}
  local basePos = activeItem.ownerAimPosition()

  local pCount = self.projectileCount or 1

  local pParams = copy(self.projectileParameters)
  pParams.power = self.baseDamageFactor * pParams.baseDamage * config.getParameter("damageLevelMultiplier") / pCount
  pParams.powerMultiplier = activeItem.ownerPowerMultiplier()

  for i = 1, pCount do
    local projectileId = world.spawnProjectile(
        self.projectileType,
        vec2.add(basePos, pOffset),
        activeItem.ownerEntityId(),
        pOffset,
        false,
        pParams
      )

    if projectileId then
      table.insert(storage.projectiles, projectileId)
      world.sendEntityMessage(projectileId, "updateProjectile", aimPosition)
    end

    pOffset = vec2.rotate(pOffset, (2 * math.pi) / pCount)
  end
end

function Kinesis:focusPosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("stone", "focalPoint")))
end

-- give all projectiles a new aim position and let those projectiles return one or
-- more entity ids for projectiles we should now be tracking
function Kinesis:updateProjectiles()
  local aimPosition = activeItem.ownerAimPosition()
  local newProjectiles = {}
  for _, projectileId in pairs(storage.projectiles) do
    if world.entityExists(projectileId) then
      local projectileResponse = world.sendEntityMessage(projectileId, "updateProjectile", aimPosition)
      if projectileResponse:finished() then
        local newIds = projectileResponse:result()
        if type(newIds) ~= "table" then
          newIds = {newIds}
        end
        for _, newId in pairs(newIds) do
          table.insert(newProjectiles, newId)
        end
      end
    end
  end
  storage.projectiles = newProjectiles
end

function Kinesis:killProjectiles()
  for _, projectileId in pairs(storage.projectiles) do
    if world.entityExists(projectileId) then
      world.sendEntityMessage(projectileId, "kill")
    end
  end
end

function Kinesis:reset()
  self.weapon:setStance(self.stances.idle)
  animator.stopAllSounds("chargedloop")
  animator.stopAllSounds("fullcharge")
  animator.setAnimationState("charge", "idle")
  animator.setParticleEmitterActive(self.elementalType .. "charge", false)
  activeItem.setCursor("/cursors/reticle0.cursor")
end

function Kinesis:uninit(weaponUninit)
  self:reset()
  if weaponUninit then
    self:killProjectiles()
  end
end
