require "/scripts/vec2.lua"

function init()
  self.speed = vec2.mag(mcontroller.velocity())
  self.power = projectile.getParameter("power")
  self.maxPowerMult = 4
end

function update(dt)
  local cSpeed = vec2.mag(mcontroller.velocity())
  local powerMult = math.min( cSpeed / (self.speed or 1), self.maxPowerMult)
  projectile.setPower(self.power * powerMult)
end
