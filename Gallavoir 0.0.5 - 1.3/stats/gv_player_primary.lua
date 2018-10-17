local storage_update = update

--local lol = true

function update(dt)
  storage_update(dt)
  --[[ debug logger
  if lol then
    sb.logInfo("%s", mcontroller.baseParameters()) 
    lol = false
  end
  ]]
end