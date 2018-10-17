require "/scripts/vec2.lua"
require "/scripts/util.lua"

function update()
  localAnimator.clearDrawables()
  local rays = animationConfig.animationParameter("rays") or {}
  
  for _,beam in pairs(rays) do
    local startPosition = beam.pos[1]
    local endPosition = beam.pos[2]
    local beamPosition = activeItemAnimation.ownerPosition()
    local color = beam.color or {255,255,255,255}
    if #color == 3 then
      color[4] = 255
    end
    
    localAnimator.addDrawable({line = {startPosition, endPosition}, width = 1, color = color, position = beamPosition, fullbright = true})
  end
end
