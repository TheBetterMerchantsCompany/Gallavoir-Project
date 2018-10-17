function init()
  seed = entity.position()[1]*100
  self.chanceToFail = config.getParameter("chanceToFail",0.8)
  self.chance = sb.staticRandomDouble(seed)
end

function update(dt)
  if self.chance < self.chanceToFail then effect.expire() end
  mcontroller.controlModifiers({
      speedModifier = -1.0
    })
end

function uninit()

end
