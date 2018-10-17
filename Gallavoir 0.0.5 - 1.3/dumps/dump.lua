function init()
  self.delayTimer = false
end

function update(dt)
  if self.delayTimer  then
    sb.logInfo("%s", _ENV) 
    self.delayTimer = true
  end
end