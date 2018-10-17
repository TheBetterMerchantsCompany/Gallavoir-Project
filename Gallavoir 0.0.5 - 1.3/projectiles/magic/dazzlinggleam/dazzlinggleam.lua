require "/scripts/vec2.lua"

function init()
  self.controlForce = config.getParameter("controlForce")
  self.maxSpeed = config.getParameter("maxSpeed")
end

function update(dt)
  mcontroller.approachVelocity(vec2.mul(vec2.norm(mcontroller.velocity()), self.maxSpeed), self.controlForce)
end