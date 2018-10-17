function activate(fireMode, shiftHeld)
  if fireMode == "primary" and shiftHeld == true then
  
    --debug
    --local item = player.consumeItem(player.primaryHandItem(), false, true)
    --player.giveItem(util.mergeTable(item, {parameters={altAbilityType="risingslash"}}))
    
    activeItem.interact(config.getParameter("interactAction"), config.getParameter("interactData"));
  end
end