require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/activeitem/stances.lua"
require "/scripts/companions/util.lua"


function callPetsSystem(message, ...)
  local owner = activeItem.ownerEntityId()
  local promise = world.sendEntityMessage(owner, message, ...)

  -- Message is sent only locally, so the promise should be fulfilled
  -- immediately.
  assert(promise:finished())

  if promise:succeeded() then
    return promise:result()
  else
    sb.logInfo("Error messaging pet system %s with %s: %s", owner, message, promise:error())
    return nil
  end
end

function init()
  initStances()

  self.minions = config.getParameter("minions") or buildMinions()
  assert(self.minions ~= nil)
  self.currentMinion = config.getParameter("currentMinion") or 1

  self.collar = config.getParameter("currentCollar")
  self.card = config.getParameter("currentCard")

  self.firstUpdate = true

  self.projectileId = nil
  self.returnProjectileId = nil
  setStance("idle")
end

function finishInit()
  activeItem.setInstanceValue("minions", self.minions)
  
  --takeout fakeout
  local visibleCollar = mergeCollars(self.collar, self.card)
  
  --sb.logInfo("SI:%s", visibleCollar)
  
  for id, minion in pairs(self.minions) do 
    minion[1].podUuid = id
    callPetsSystem("minions.setPodPets", id, minion)
    callPetsSystem("pets.setPodCollar", id, visibleCollar)
  end
  activeItem.setInstanceValue("visibleCollar", visibleCollar)
end

function update(dt, fireMode, shiftHeld)
  if self.firstUpdate then
    finishInit()
    self.firstUpdate = false
  end

  checkProjectiles()

  updateStance(dt)

  activeItem.setOutsideOfHand(isFrontHand())

  if fireMode ~= "primary" then
    self.fired = false
  end

  if self.stanceName == "idle" then
    if fireMode == "primary" and not self.fired then
      self.fired = true
      setStance("windup")
    elseif fireMode == "alt" and not self.fired then
      self.fired = true
      setStance("dead")
    end
  end

  if self.stanceName == "throw" then
    if not self.projectileId and not self.returnProjectileId then
      setStance("catch")
    end
  end
  
  updateAim()
end

function uninit()
  activeItem.setInstanceValue("currentMinion", self.currentMinion)
end

function showEnergyBall()
  animator.burstParticleEmitter("energyball")
end

function checkProjectiles()
  if self.projectileId then
    if not world.entityExists(self.projectileId) then
      self.projectileId = nil
      setStance("podTeleportCatch")
      showEnergyBall()
    elseif world.callScriptedEntity(self.projectileId, "monstersReleased") then
      self.returnProjectileId = self.projectileId
      self.projectileId = nil
    end
  elseif self.returnProjectileId then
    if not world.entityExists(self.returnProjectileId) then
      self.returnProjectileId = nil
    end
  end
end

function fire()
  if self.minions and not self.projectileId and not self.returnProjectileId then
    if callPetsSystem("minions.slotsLeft") > 0 then
      throwProjectile()
      setStance("throw")
    else setStance("idle") end
  end
end

function throwProjectile()
  local position = firePosition()

  local params = config.getParameter("projectileParameters")
  
  local keys = util.keys(self.minions, false)
  self.currentMinion = self.currentMinion % #keys + 1

  params.podUuid = keys[self.currentMinion]
  callPetsSystem("minions.activatePod", params.podUuid)

  local collisionPoly = nil
  for _, pet in pairs(self.minions) do
    if not pet[1].collisionPoly then
      local movementSettings = root.monsterMovementSettings(pet[1].config.type)
      collisionPoly = movementSettings.standingPoly or movementSettings.crouchingPoly or movementSettings.collisionPoly
      position = findCompanionSpawnPosition(position, collisionPoly)
      break
    else
      collisionPoly = pet[1].collisionPoly
      position = findCompanionSpawnPosition(position, collisionPoly)
      break
    end
  end

  params.movementSettings = {
      collisionPoly = collisionPoly
    }

  params.ownerAimPosition = activeItem.ownerAimPosition()
  if self.aimDirection < 0 then params.processing = "?flipx" end

  self.projectileId = world.spawnProjectile(
      config.getParameter("projectileType"),
      position,
      activeItem.ownerEntityId(),
      aimVector(),
      false,
      params
    )
  animator.playSound("throw")
end

function kill()
  local keys = util.keys(self.minions, false)
  for _, key in pairs(keys) do
    callPetsSystem("minions.deactivatePod",key)
  end
  setStance("idle")
end


function buildMinions()
  local minions = {}
  local minion = config.getParameter("minion")
  local minionId = config.getParameter("minionId")
  local j = ""
  for i = 1, config.getParameter("minionAmount") do
    j = string.len(i) == 1 and "0" or ""
    minions[minionId .. j .. i] = minion
  end
  return minions
end

--collar has priority.
function mergeCollars(collar, card)
  if collar and card then   
    local newCollar = {name = collar.name .. card.name}
    
    if collar.parameters or card.parameters then
      newCollar.parameters = util.mergeTable(card.parameters or {}, collar.parameters or {})
    end
    
    if collar.effects or card.effects then
      newCollar.effects = util.mergeLists(collar.effects or {}, card.effects or {})
    end
    
    if collar.damageTeam then newCollar.damageTeam = collar.damageTeam
    elseif card.damageTeam then newCollar.damageTeam = card.damageTeam end
    
    return newCollar
  elseif collar then return collar
  elseif card then return card
  end
  return {}
end


function isFrontHand()
  return (activeItem.hand() == "primary") == (self.aimDirection < 0)
end