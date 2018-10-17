require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/ranged/hiddenweapon.lua"

function init()
  activeItem.setCursor("/cursors/reticle0.cursor")
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))

  self.weapon = HiddenWeapon:new()

  self.weapon:addTransformationGroup("weapon", {0,0}, 0)
  self.weapon:addTransformationGroup("muzzle", self.weapon.muzzleOffset, 0)

  local primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(primaryAbility)

  local secondaryAbility = getAltAbility(self.weapon.elementalType)
  if secondaryAbility then
    self.weapon:addAbility(secondaryAbility)
  end

  self.weapon:init()

  self.activeTime = config.getParameter("activeTime", 0.5)
  self.yelledTime = config.getParameter("yelledTime", 1/60)
  self.activeTimer = 0
  self.yelledTimer = 0
  activeItem.setHoldingItem(false)
end

function update(dt, fireMode, shiftHeld)
  world.debugText("[%s]", fireMode, vec2.add(mcontroller.position(), {0, 5}), "cyan")
  
  local nowActive = fireMode ~= "none"
  self.yelledTimer = math.max(0, self.yelledTimer - dt)
  
  if nowActive then
    if self.activeTimer == 0 then
      activeItem.setHoldingItem(true)
      self.yelledTimer = self.yelledTime
    end
    self.activeTimer = self.activeTime
  elseif self.activeTimer > 0 then
    self.activeTimer = math.max(0, self.activeTimer - dt)

    if self.activeTimer == 0 then
      activeItem.setHoldingItem(false)
    end
  end
  
  self.weapon:update(dt, fireMode, shiftHeld, self.yelledTimer)
end

function uninit()
  self.weapon:uninit()
end
