require "/scripts/poly.lua"
require "/scripts/interp.lua"

function init()
  -- Positions and angles
  self.baseOffset = config.getParameter("baseOffset")
  self.basePosition = vec2.add(object.position(), self.baseOffset)
  self.tipOffset = config.getParameter("tipOffset") --This is offset from BASE position, not object origin

  self.rotationSpeed = util.toRadians(config.getParameter("rotationSpeed"))
  self.offAngle = util.toRadians(config.getParameter("offAngle", -30))

  -- Targeting
  self.targetQueryRange = config.getParameter("targetQueryRange")
  self.targetMinRange = config.getParameter("targetMinRange")
  self.targetMaxRange = config.getParameter("targetMaxRange")
  self.targetAngleRange = util.toRadians(config.getParameter("targetAngleRange"))
  
  self.scanTime = config.getParameter("scanTime", 1.0)
  
  self.projectileType = config.getParameter("projectileType", "sgturretflak")
  self.inaccuracy = config.getParameter("inaccuracy")
  
  self.multiBarrel = config.getParameter("multiBarrel", false)
  self.firePoints = {}
  self.firePos = 0
  
  self.burst = config.getParameter("burst")
  
  self.forceBurst = false
  
  -- Energy
  self.regenBlockTimer = 0
  self.energyRegen = config.getParameter("energyRegen")
  self.maxEnergy = config.getParameter("maxEnergy")
  self.energyRegenBlock = config.getParameter("energyRegenBlock")
  
  storage.energy = storage.energy or self.maxEnergy

  self.energyBarOffset = config.getParameter("energyBarOffset")
  self.verticalScaling = config.getParameter("verticalScaling")
  animator.translateTransformationGroup("energy", self.energyBarOffset)

  -- Initialize turret
  if self.multiBarrel then
    if type(animator.partProperty("gun", "projectileSource")[1]) ~= "table" then
      local arraySize = config.getParameter("arraySize")
      local arrayOffset = config.getParameter("arrayOffset")
      
      for i = 1, arraySize[1] do
        for j = 1, arraySize[2] do
          self.firePoints[(i-1)*arraySize[2]+j] = {arrayOffset[1] * (i-1), arrayOffset[2] * (j-1)}
        end
      end
    end
  end
  
  object.setInteractive(false)

  self.state = FSM:new()
  self.state:set(offState)
end

function update(dt)
  self.state:update(dt)

  if self.multiBarrel then
    local firePos = firePosition(true)
    for i = 1, #firePos do
      world.debugPoint(firePos[i], "green")
    end
  else
    world.debugPoint(firePosition(true), "green")
  end

  if storage.energy == 0 then
    self.blockEnergyUsage = true
  elseif storage.energy == self.maxEnergy then
    self.blockEnergyUsage = false
  end

  if self.regenBlockTimer > 0 then
    self.regenBlockTimer = math.max(0, self.regenBlockTimer - script.updateDt())
  else
    storage.energy = math.min(self.maxEnergy, storage.energy + self.energyRegen * script.updateDt())
  end

  local ratio = storage.energy / self.maxEnergy
  local animationState = "full"

  if ratio <= 0.75 then animationState = "high" end
  if ratio <= 0.5 then animationState = "medium" end
  if ratio <= 0.25 then animationState = "low" end
  if ratio <= 0 then animationState = "none" end

  local scale = self.verticalScaling and {1, ratio * 11} or {ratio * 11, 1}

  animator.resetTransformationGroup("energy")
  animator.scaleTransformationGroup("energy", scale)
  animator.translateTransformationGroup("energy", self.energyBarOffset)

  animator.setAnimationState("energy", animationState)
end

----------------------------------------------------------------------------------------------------------
-- States

function offState()
  animator.setAnimationState("attack", "dead")
  animator.playSound("powerDown")
  object.setAllOutputNodes(false)

  while true do
    animator.rotateGroup("gun", self.offAngle)

    if active() then break end
    coroutine.yield()
  end

  animator.playSound("powerUp")

  self.state:set(scanState)
end

function scanState()
  animator.setAnimationState("attack", "idle")
  util.wait(0.5)
  animator.playSound("scan")
  object.setAllOutputNodes(false)

  local timer = 0

  local scanInterval = config.getParameter("scanInterval")
  local scanAngle = util.toRadians(config.getParameter("scanAngle"))

  local scan = coroutine.wrap(function()
    while true do
      local target = findTarget()
      if target then return self.state:set(fireState, target) end
      util.wait(1.0)
    end
  end)

  while true do
    timer = timer + script.updateDt() / scanInterval
    if timer > 1 then timer = 0 end
    animator.rotateGroup("gun", scanAngle * math.sin(timer * math.pi*2))

    scan()

    if not active() then break end
    coroutine.yield()
  end

  self.state:set(offState)
end

function fireState(targetId)
  animator.setAnimationState("attack", "attack")
  animator.playSound("foundTarget")
  object.setAllOutputNodes(true)

  local maxFireAngle = util.toRadians(config.getParameter("maxFireAngle"))
  local fire = self.burst and coroutine.wrap(burstFire) or coroutine.wrap(autoFire)

  while true do
    if not active() and not self.forceBurst then return self.state:set(offState) end

    if not world.entityExists(targetId) and not self.forceBurst then break end

    local targetPosition = world.entityPosition(targetId) or vec2.add(object.position(), {self.targetMaxRange * object.direction(), 0})
    local toTarget = world.distance(targetPosition, self.basePosition)
    local targetDistance = world.magnitude(toTarget)
    local targetAngle = math.atan(toTarget[2], object.direction() * toTarget[1])

    if (targetDistance > self.targetMaxRange or targetDistance < self.targetMinRange or world.lineTileCollision(self.basePosition, targetPosition)) and not self.forceBurst then break end
    if (math.abs(targetAngle) > self.targetAngleRange) and not self.forceBurst then break end
    targetAngle = util.clamp(targetAngle, -self.targetAngleRange, self.targetAngleRange)
    
    animator.rotateGroup("gun", targetAngle)

    local rotation = animator.currentRotationAngle("gun")
    if (math.abs(util.angleDiff(targetAngle, rotation)) < maxFireAngle) or self.forceBurst then
      fire()
    end
    coroutine.yield()
  end
  
  util.wait(1.0)

  self.state:set(scanState)
end

----------------------------------------------------------------------------------------------------------
-- Helping functions, not states

function consumeEnergy(amount)
  if storage.energy < amount or self.blockEnergyUsage then return false end
  storage.energy = storage.energy - amount
  self.regenBlockTimer = self.energyRegenBlock
  return true
end

function active()
  if object.isInputNodeConnected(0) then
    return object.getInputNodeLevel(0)
  end

  storage.active = storage.active ~= nil and storage.active or true
  return storage.active
end

function firePosition(simulate)
  local animationPosition = vec2.div(config.getParameter("animationPosition"), 8)
  local fireOffset = {0,0}
  
  if self.multiBarrel then
    if not simulate then
      local projectileSource = firePoints() or animator.partPoly("gun", "projectileSource")
      
      self.firePos = (self.firePos - 1) % #projectileSource
      
      --sb.logInfo("%s", self.firePos)
      
      local firePos = projectileSource[self.firePos+1]
      fireOffset = vec2.add(animationPosition, firePos)
    else return poly.translate(poly.translate(firePoints() or animator.partPoly("gun", "projectileSource"), object.position()), animationPosition)
    end
  else
    fireOffset = vec2.add(animationPosition, animator.partPoint("gun", "projectileSource"))
  end
  return vec2.add(object.position(), fireOffset)
end

function firePoints()
  --sb.logInfo("%s", self.firePoints)
  if next(self.firePoints) == nil then return nil end
  
  local firePoints = poly.scale(self.firePoints, {object.direction(), object.direction()})
  firePoints = poly.rotate(firePoints, animator.currentRotationAngle("gun"))
  firePoints = poly.scale(firePoints, {1, object.direction()})
  firePoints = poly.translate(firePoints, animator.partPoint("gun", "projectileSource"))
  
  return firePoints
end

-- Coroutine
function autoFire()
  local level = math.max(1.0, world.threatLevel())
  local power = config.getParameter("power", 2)
  power = root.evalFunction("monsterLevelPowerMultiplier", level) * power
  local fireTime = config.getParameter("fireTime", 0.1)
  local projectileParameters = config.getParameter("projectileParameters", {})
  local energyUsage = config.getParameter("energyUsage")
  projectileParameters.power = power

  while true do
    while not consumeEnergy(energyUsage) do coroutine.yield() end

    local rotation = animator.currentRotationAngle("gun")
    local aimVector = {object.direction() * math.cos(rotation), math.sin(rotation)}
    aimVector = vec2.rotate(aimVector, sb.nrand(self.inaccuracy, 0))
    
    world.spawnProjectile(self.projectileType, firePosition(false), entity.id(), aimVector, false, projectileParameters)
    animator.playSound("fire")
    util.wait(fireTime)
  end
end

-- Coroutine
function burstFire()
  local burstCount = config.getParameter("burstCount")
  if burstCount == nil then
    if self.multiBarrel then
      local arraySize = config.getParameter("arraySize")
      burstCount = arraySize[1] * arraySize[2]
    else
      burstCount = 4 --Chosen by a fair dice roll.
    end
  end
  
  local fireTime = config.getParameter("fireTime", 0.1)
  local burstTime = config.getParameter("burstTime", fireTime)
  local energyUsage = config.getParameter("energyUsage") * burstCount

  local level = math.max(1.0, world.threatLevel())
  local projectileParameters = config.getParameter("projectileParameters", {})
  local power = config.getParameter("power", 2)
  power = root.evalFunction("monsterLevelPowerMultiplier", level) * power
  projectileParameters.power = power

  while true do
    while not consumeEnergy(energyUsage) do coroutine.yield() end
    local shots = burstCount
    self.forceBurst = true
    
    while shots > 0 do
      shots = shots - 1
      
      local rotation = animator.currentRotationAngle("gun")
      local aimVector = {object.direction() * math.cos(rotation), math.sin(rotation)}
      aimVector = vec2.rotate(aimVector, sb.nrand(self.inaccuracy, 0))
      
      world.spawnProjectile(self.projectileType, firePosition(false), entity.id(), aimVector, false, projectileParameters)
      animator.playSound("fire")
      
      util.wait(burstTime)
    end
    
    self.forceBurst = false
    util.wait((fireTime - burstTime) * burstCount)
  end
end

-- Coroutine
function findTarget()
  local nearEntities = world.entityQuery(self.basePosition, self.targetQueryRange, { includedTypes = { "monster", "npc", "player" } })
  return util.find(nearEntities,  function(entityId)
    local targetPosition = world.entityPosition(entityId)
    if not entity.isValidTarget(entityId) or world.lineTileCollision(self.basePosition, targetPosition) then return false end

    local toTarget = world.distance(targetPosition, self.basePosition)
    local targetAngle = math.atan(toTarget[2], object.direction() * toTarget[1])
    return world.magnitude(toTarget) > self.targetMinRange and math.abs(targetAngle) < self.targetAngleRange
  end)
end
