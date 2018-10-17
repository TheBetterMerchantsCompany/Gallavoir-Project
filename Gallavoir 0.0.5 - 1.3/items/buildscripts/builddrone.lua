require "/scripts/util.lua"
require "/scripts/staticrandom.lua"

function build(directory, config, parameters, level, seed)
  local configParameter = function(keyName, defaultValue)
    if parameters[keyName] ~= nil then
      return parameters[keyName]
    elseif config[keyName] ~= nil then
      return config[keyName]
    else
      return defaultValue
    end
  end
  
	local statsLabel = "^red;%d HP^reset;  ^gray;%.1f DEF^reset;\n^orange;%.1f ATK^reset;  ^magenta;%.2f AMP^reset;"
	
	--load base stats
	
  local minionBase = configParameter("minion", {})
  local minionType = minionBase[1].config.type
  local minion = root.monsterParameters(minionType)
  
  local hp  = minion.statusSettings.stats.maxHealth.baseValue
  local atk = minion.touchDamage.damage
  local def = minion.statusSettings.stats.protection.baseValue
  local spa = minion.statusSettings.stats.powerMultiplier.baseValue
  
  --sb.logInfo("%s:%s:%s:%s", hp, atk, def, spa)
    
  config.tooltipFields = configParameter("tooltipFields", {})
  
  config.tooltipFields.cntLabel = string.format("%s", configParameter("minionAmount", 0))
  config.tooltipFields.statsLabel = string.format(statsLabel, hp, def, atk, spa)

  return config, parameters
end
