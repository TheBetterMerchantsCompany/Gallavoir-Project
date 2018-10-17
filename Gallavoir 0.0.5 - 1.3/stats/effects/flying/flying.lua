function init()
  self.jetPower = config.getParameter("jetPower",4)
  self.online = false
  --sb.logInfo("%s",_ENV)
end

function update(dt)
  if self.online then
    mcontroller.addMomentum({0,self.jetPower})
    if mcontroller.jumping() then self.online = false end
  else
    if mcontroller.jumping() then self.online = true end
  end
end

function uninit()

end
