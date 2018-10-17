require "/scripts/util.lua"
require "/scripts/vec2.lua"

function update()
  if (world.farmableStage(entity.id()) == #config.getParameter("stages")-1) and (world.timeOfDay() > 0.5) then
    animator.setAnimationState("light", "on")
    object.setLightColor(config.getParameter("lightColor", {0, 0, 0}))
  else
    animator.setAnimationState("light", "off")
    object.setLightColor({0, 0, 0})
  end
end