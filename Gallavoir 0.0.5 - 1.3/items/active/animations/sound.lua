require "/scripts/vec2.lua"
require "/scripts/util.lua"

function update()
  localAnimator.clearDrawables()

  self.chains = animationConfig.animationParameter("chains") or {}
  for _, chain in pairs(self.chains) do
    local startPosition = chain.startPosition or vec2.add(activeItemAnimation.ownerPosition(), activeItemAnimation.handPosition(chain.startOffset))
    local endPosition = chain.endPosition or vec2.add(activeItemAnimation.ownerPosition(), activeItemAnimation.handPosition(chain.endOffset))
    
    local length = chain.length or vec2.sub(endPosition, startPosition)
    
    local lineWidth = chain.lineWidth or 1
    local lineColor = chain.lineColor or {255, 255, 255, 255}
    local figureColor = chain.figureColor or {255, 255, 255, 128}
    
    local endPos, line
    
    --First beam
    endPos = vec2.rotate({length * activeItemAnimation.ownerFacingDirection(), chain.maxWidth * length / chain.maxLength}, activeItemAnimation.ownerArmAngle() * activeItemAnimation.ownerFacingDirection())
    line = {{0, 0}, endPos}
    localAnimator.addDrawable({line = line, width = lineWidth, color = lineColor, position = startPosition, fullbright = true}, chain.renderLayer)
    
    --Second beam
    endPos = vec2.rotate({length * activeItemAnimation.ownerFacingDirection(), -chain.maxWidth * length / chain.maxLength}, activeItemAnimation.ownerArmAngle() * activeItemAnimation.ownerFacingDirection())
    line = {{0, 0}, endPos}
    localAnimator.addDrawable({line = line, width = lineWidth, color = lineColor, position = startPosition, fullbright = true}, chain.renderLayer)
    
    yScale = chain.maxWidth / chain.maxLength
    if chain.figures then
      local rand = math.random() - 0.5
      for _, figure in pairs(chain.figures) do
        local figureScaled = figure
        for _, point in pairs(figureScaled) do
          local x = point[1]
          local y = point[2]
          
          point[1] = x * length * activeItemAnimation.ownerFacingDirection() + rand * x * chain.wiggle
          point[2] = y * length * yScale + rand * x * chain.wiggle
          
          point = rotate(point, activeItemAnimation.ownerArmAngle() * activeItemAnimation.ownerFacingDirection())
        end
        
        localAnimator.addDrawable({poly = figureScaled, color = figureColor, position = startPosition, fullbright = true}, chain.renderLayer)
      end
    end
  end
end

function rotate(point, angle)
  local x = point[1]
  local y = point[2]
  
  point[1] = x * math.cos(angle) - y * math.sin(angle)
  point[2] = y * math.cos(angle) + x * math.sin(angle)
  
  return point
end