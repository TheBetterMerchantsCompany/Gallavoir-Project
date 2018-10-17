require "/items/active/weapons/weapon.lua"

HiddenWeapon = {}
for k, v in pairs(Weapon) do
  HiddenWeapon[k] = v
end
HiddenWeapon.__index = HiddenWeapon

function HiddenWeapon:new(weaponConfig)
  local newWeapon = weaponConfig or {}
  newWeapon.damageLevelMultiplier = config.getParameter("damageLevelMultiplier", root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1)))
  newWeapon.elementalType = config.getParameter("elementalType")
  newWeapon.muzzleOffset = config.getParameter("muzzleOffset") or {0,0}
  newWeapon.aimOffset = config.getParameter("aimOffset") or (newWeapon.muzzleOffset[2] - 0.25) -- Why is it off by 0.25? Only She knows.
  newWeapon.abilities = {}
  newWeapon.transformationGroups = {}
  newWeapon.handGrip = config.getParameter("handGrip", "inside")
  setmetatable(newWeapon, extend(self))
  return newWeapon
end

function HiddenWeapon:update(dt, fireMode, shiftHeld, yelled)
  self.attackTimer = math.max(0, self.attackTimer - dt)
  
  if yelled == 0 then
    for _,ability in pairs(self.abilities) do
      ability:update(dt, fireMode, shiftHeld)
    end
  else
    world.debugText("[HiddenWeapon]:update() skipped! Rerouting... [%s]", yelled*60, vec2.add(mcontroller.position(), {0, 4}), "green")
  end
  
  if self.currentState then
    if coroutine.status(self.stateThread) ~= "dead" then
      local status, result = coroutine.resume(self.stateThread)
      if not status then error(result) end
    else
      self.currentAbility:uninit()
      self.currentAbility = nil
      self.currentState = nil
      self.stateThread = nil
      if self.onLeaveAbility then
        self.onLeaveAbility()
      end
    end
  end

  if self.stance then
    self:updateAim()
    self.relativeArmRotation = self.relativeArmRotation + self.armAngularVelocity * dt
    self.relativeWeaponRotation = self.relativeWeaponRotation + self.weaponAngularVelocity * dt
  end

  if self.handGrip == "wrap" then
    activeItem.setOutsideOfHand(self:isFrontHand())
  elseif self.handGrip == "embed" then
    activeItem.setOutsideOfHand(not self:isFrontHand())
  elseif self.handGrip == "outside" then
    activeItem.setOutsideOfHand(true)
  elseif self.handGrip == "inside" then
    activeItem.setOutsideOfHand(false)
  end
  
  self:clearDamageSources()
end