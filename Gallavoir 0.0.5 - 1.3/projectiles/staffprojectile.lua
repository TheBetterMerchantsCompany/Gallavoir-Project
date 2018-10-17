require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self.controlMovement = config.getParameter("controlMovement")
  self.timedActions = config.getParameter("timedActions", {})
  self.queryRange = config.getParameter("queryRange")
  
  self.aimPosition = mcontroller.position()
  
  self.target = nil

  message.setHandler("updateProjectile", function(_, _, aimPosition)
      self.aimPosition = aimPosition
      return entity.id()
    end)

  message.setHandler("kill", function()
      projectile.die()
    end)
end

function update(dt)
  if self.aimPosition then
    if self.controlMovement then
      controlTo(self.aimPosition)
    end

    for _, action in pairs(self.timedActions) do
      processTimedAction(action, dt)
    end
  end
end

function controlTo(position)
  --sb.logInfo("%s:%s", vec2.mag(world.distance(position, mcontroller.position())), (self.controlMovement.maxSpeed / 60))
  if vec2.mag(world.distance(position, mcontroller.position())) > (self.controlMovement.maxSpeed / 60) then
    local offset = world.distance(position, mcontroller.position())
    mcontroller.approachVelocity(vec2.mul(vec2.norm(offset), self.controlMovement.maxSpeed), self.controlMovement.controlForce)
  else
    mcontroller.approachVelocity({0,0}, self.controlMovement.controlForce)
    mcontroller.setPosition(position)
  end
end

function processTimedAction(action, dt)
  if action.complete then
    return
  elseif action.delayTime then
    action.delayTime = action.delayTime - dt
    if action.delayTime <= 0 then
      action.delayTime = nil
    end
  elseif action.loopTime then
    action.loopTimer = action.loopTimer or 0
    action.loopTimer = math.max(0, action.loopTimer - dt)
    if action.loopTimer == 0 then
      projectile.processAction(action)
      action.loopTimer = action.loopTime
      if action.loopTimeVariance then
        action.loopTimer = action.loopTimer + (2 * math.random() - 1) * action.loopTimeVariance
      end
    end
  else
    projectile.processAction(action)
    action.complete = true
  end
end