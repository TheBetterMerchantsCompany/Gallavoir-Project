require "/scripts/vec2.lua"

function init()
  self.controlForce = config.getParameter("controlForce")
  self.maxSpeed = config.getParameter("maxSpeed")
  self.armTime = config.getParameter("armTime")
end

function update(dt)
  if self.armTime > 0 then
    self.armTime = math.max(self.armTime - dt, 0)
    return
  end
  
  if self.target and world.entityExists(self.target) then
    self.targetPosition = world.entityPosition(self.target)
  else
    setTarget(nil)
  end
  if self.targetPosition then
    mcontroller.applyParameters({
      gravityEnabled = false
    })
    local toTarget = world.distance(self.targetPosition, mcontroller.position())
    toTarget = vec2.norm(toTarget)
    mcontroller.approachVelocity(vec2.mul(toTarget, self.maxSpeed), self.controlForce)
  end
  mcontroller.setRotation(math.atan(mcontroller.velocity()[2], mcontroller.velocity()[1]))
end

function setTarget(targetId)
  self.target = targetId
  if self.target then
    self.targetPosition = world.entityPosition(targetId)
  else
    self.targetPosition = nil
  end
end
