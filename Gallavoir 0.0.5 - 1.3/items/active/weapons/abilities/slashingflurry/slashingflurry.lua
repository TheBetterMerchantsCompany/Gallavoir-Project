require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

SlashingFlurry = WeaponAbility:new()

function SlashingFlurry:init()
  self.cooldownTimer = self.cooldownTime
  self:reset()
end

function SlashingFlurry:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.weapon.currentAbility == nil
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
    and self.fireMode == "alt" then

    self:setState(self.fire)
  end
end

function SlashingFlurry:fire()
  local cooldownTime = self.maxCooldownTime
  local currentRotationOffset = 1
  local currentSwoosh = 1

  while self.fireMode == "alt" do
    if not status.overConsumeResource("energy", self.energyUsage) then break end

    self.weapon:setStance(self.stances.fire)
    self.weapon.relativeWeaponRotation = util.toRadians(self.stances.fire.weaponRotation + self.cycleRotationOffsets[currentRotationOffset])
    self.weapon.relativeArmRotation = util.toRadians(self.stances.fire.armRotation + self.cycleRotationOffsets[currentRotationOffset])
    self.weapon:updateAim()

    currentSwoosh = currentSwoosh + 1
    if currentSwoosh > 2 then
      currentSwoosh = 1
    end
    if currentSwoosh < 2 then
      animator.setAnimationState("swoosh", "fire")
      animator.playSound("fire")
      util.wait(self.stances.fire.duration, function(dt)
        local damageArea = partDamageArea("swoosh")
        self.weapon:setDamage(self.damageConfig, damageArea)
      end)
    end
    if currentSwoosh > 1 then
      animator.setAnimationState("swoosh", "fire2")
      animator.playSound("fire")
      util.wait(self.stances.fire.duration, function(dt)
        local damageArea = partDamageArea("swoosh")
        self.weapon:setDamage(self.damageConfig, damageArea)
      end)
    end

    -- allow changing aim during cooldown
    self.weapon:setStance(self.stances.idle)
    util.wait(cooldownTime - self.stances.fire.duration, function(dt)
      return self.fireMode ~= "alt"
    end)

    cooldownTime = math.max(self.minCooldownTime, cooldownTime - self.cooldownSwingReduction)

    currentRotationOffset = currentRotationOffset + 1
    if currentRotationOffset > #self.cycleRotationOffsets then
      currentRotationOffset = 1
    end
  end
  self.cooldownTimer = self.cooldownTime
end

function SlashingFlurry:reset()
end

function SlashingFlurry:uninit()
  self:reset()
end
