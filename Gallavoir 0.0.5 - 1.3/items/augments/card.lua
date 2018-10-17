require "/scripts/augments/item.lua"

function applyCard(output, cardConfig)
  output:setInstanceValue("currentCard", cardConfig)

  local tooltipFields = output:instanceValue("tooltipFields", {})
  tooltipFields.cardNameLabel = cardConfig.displayName
  tooltipFields.cardIconImage = cardConfig.displayIcon
  tooltipFields.noCardLabel = ""
  output:setInstanceValue("tooltipFields", tooltipFields)

  return output:descriptor(), 1
end

function apply(input)
  local output = Item.new(input)
  if not output:instanceValue("podUuid") then
    return nil
  end

  local cardConfig = config.getParameter("card")
  local randomCards = config.getParameter("randomCards")

  if cardConfig then
    local currentCard = output:instanceValue("currentCard")
    if currentCard then
      if currentCard.name == cardConfig.name then
        return nil
      end
    end

    return applyCard(output, cardConfig)
  elseif randomCards then
    cardConfig = randomCards[math.random(#randomCards)]
    return applyCard(output, cardConfig)
  end
end
