require "/scripts/vec2.lua"
require "/scripts/util.lua"

KinesisShock = WeaponAbility:new()

function KinesisShock:init()
  storage.projectiles = storage.projectiles or {}

  self.elementalType = self.elementalType or self.weapon.elementalType
  self.stances = config.getParameter("stances")
  
  self.cooldownTimer = self.stances.shock.duration
  
  self.baseDamageFactor = config.getParameter("baseDamageFactor", 1.0)

  activeItem.setCursor("/cursors/reticle0.cursor")
  self.weapon:setStance(self.stances.idle)

  self.weapon.onLeaveAbility = function()
    self:reset()
  end
end

function KinesisShock:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)
  
  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  if (self.weapon.stance == self.stances.shock) and (self.cooldownTimer == 0) then 
    if self.fireMode == ("primary" or "alt") then
      self.weapon:setStance(self.stances.fire)
    else
      self.weapon:setStance(self.stances.cooldown)
    end
  end
  
  if self.fireMode == ("primary" or "alt")
    and shiftHeld
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy") then
  
    self.weapon:setStance(self.stances.shock)
    self.weapon:updateAim()
    
    if self:targetValid(activeItem.ownerAimPosition()) and status.overConsumeResource("energy", self.energyCost * self.baseDamageFactor) then
      animator.playSound("shock")
      self:createProjectiles()
    end
    
    self.cooldownTimer = self.stances.shock.duration
  end
end

function KinesisShock:targetValid(aimPos)
  local focusPos = self:focusPosition()
  return world.magnitude(focusPos, aimPos) <= self.maxCastRange
end

function KinesisShock:createProjectiles()
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

    pOffset = vec2.rotate(pOffset, (2 * math.pi) / pCount)
  end
end

function KinesisShock:focusPosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("stone", "focalPoint")))
end

function KinesisShock:reset()
  self.weapon:setStance(self.stances.idle)
  animator.setAnimationState("charge", "idle")
  animator.setParticleEmitterActive(self.elementalType .. "charge", false)
  activeItem.setCursor("/cursors/reticle0.cursor")
end

function KinesisShock:uninit(weaponUninit)
  self:reset()
end
