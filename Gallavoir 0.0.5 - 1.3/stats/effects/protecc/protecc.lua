function init()
  self.unlockStats = config.getParameter("unlockStats", {})
  
  self.statLockTime = config.getParameter("statLockTime", 1)
  self.statLockTimer = 0
  self.statsLocked = false
  
  local emitter = config.getParameter("emitter", false)
  
  if emitter then 
    animator.setParticleEmitterOffsetRegion(emitter, mcontroller.boundBox())
    animator.setParticleEmitterActive(emitter, true)
    effect.setParentDirectives("fade="..config.getParameter("fade", "AAAAAAAF").."=0.25")
  end
  
  local stats = config.getParameter("stats", false)
  if not stats then 
    local base = config.getParameter("base", false)
    
    if base then effect.addStatModifierGroup({{stat = config.getParameter("stat", "maxHealth"), amount = config.getParameter(config.getParameter("stat", "maxHealth"), 0)}})
    else effect.addStatModifierGroup({{stat = config.getParameter("stat", "maxHealth"), effectiveMultiplier = config.getParameter(config.getParameter("stat", "maxHealth"), 1)}}) end
  else
    local statStorage = {}
    for _, theStat in pairs(stats) do
      if theStat.amount then table.insert(statStorage, {stat = theStat.stat, amount = theStat.amount})
      else table.insert(statStorage, {stat = theStat.stat, effectiveMultiplier = theStat.mult}) end
    end
    effect.addStatModifierGroup(statStorage)
  end
end

function update(dt)
  if self.unlockStats then
    self.statLockTimer = math.max(self.statLockTimer - dt, 0)
    
    if not self.statsLocked then
      for _, theStat in pairs(self.unlockStats) do
        if status.resourceLocked(theStat) then
          self.statLockTimer = self.statLockTime
          self.statsLocked = true
        end
      end
    elseif self.statLockTimer <= 0 then
      self.statsLocked = false
      for _, theStat in pairs(self.unlockStats) do
        status.setResourceLocked(theStat, false)
      end
    end
  end
end