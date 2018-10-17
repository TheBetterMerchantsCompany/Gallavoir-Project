Attackflash = WeaponAbility:new()

function Attackflash:init()
  self.weapon:setStance(self.stances.idle)
  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
  self.muzzle = vec2.add(self.weapon.muzzleOffset, self.muzzleOffset or {0,0})
  self.weapon:addTransformationGroup("flash", self.muzzleOffset or {0,0}, 0)
  self.active = config.getParameter("active")
  self:reset()
end

function Attackflash:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and self.lastFireMode ~= (self.activatingFireMode or self.abilitySlot)
    and not status.resourceLocked("energy") then

    self.active = not self.active
    animator.setLightActive("flashlight", self.active)
    animator.setLightActive("flashlightBeam", self.active)
    animator.setLightActive("flashlightSpread", self.active)
    animator.playSound("flashlight")
  end
  
  if self.active and status.overConsumeResource("energy", (self.energyUsage or 0) * self.dt) then
    animator.setAnimationState("flash", "on", true)

    local beamStart = self:firePosition()
    local beamEnd = vec2.add(beamStart, vec2.mul(vec2.norm(self:aimVector(0)), self.beamLength))
    local beamLength = self.beamLength

    local collidePoint = world.lineCollision(beamStart, beamEnd)
    if collidePoint then
      beamEnd = collidePoint
      beamLength = world.magnitude(beamStart, beamEnd)
    end

    self.weapon:setDamage(self.damageConfig, {self.muzzle, {self.muzzle[1] + beamLength, self.muzzle[2] - self.beamWidth * beamLength / self.beamLength}, {self.muzzle[1] + beamLength, self.muzzle[2] + self.beamWidth * beamLength / self.beamLength}}, self.fireTime)
  end
  
  if status.resourceLocked("energy") then 
    self.active = false
    self:reset()
  end

  self.lastFireMode = fireMode
end

function Attackflash:reset()
  animator.setLightActive("flashlight", self.active)
  animator.setLightActive("flashlightBeam", self.active)
  animator.setLightActive("flashlightSpread", self.active)
end

function Attackflash:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.muzzle))
end

function Attackflash:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function Attackflash:uninit()
  activeItem.setInstanceValue("active", self.active)
  self:reset()
end
