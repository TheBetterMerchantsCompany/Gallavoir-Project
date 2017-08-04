require "/scripts/util.lua"
require "/scripts/versioningutils.lua"
require "/scripts/interp.lua"

 -- Under LGPL 3. Created by Princess, aka laz2727, aka revwing, nitro allen...

function init()
  self.damageList = "damageScrollArea.itemList"
  self.projList = "projScrollArea.itemList"
  self.altList = "altScrollArea.itemList"

  self.upgradeableDamageTypes = {"physical", "fire", "ice", "electric", "poison"}
  self.upgradeableProjectiles = {"none"}
  self.upgradeableAltAbilities = {"none"}
  
  self.upgradeableDamageTypesName = {"Physical", "Fire", "Ice", "Electric", "Poison"}
  
  self.selectedDamage = nil
  self.selectedProjectile = nil
  self.selectedAltAbility = nil
  
  populateItemList()
end

function update(dt)
  populateItemList()
end

function populateItemList(forceRepop)
  local weapon = player.primaryHandItem()
  if not weapon then pane.dismiss() end
  
  local rootWeaponConfig = root.itemConfig(weapon)
  local weaponConfig = rootWeaponConfig.config
  
  if not hasValue(weaponConfig.itemTags,"modifiableWeapon") then pane.dismiss() end
  
  local upgradeableProjectiles = weaponConfig.projectileTypes or {}
  local upgradeableAltAbilities = weaponConfig.altAbilities or {}

  if forceRepop or not compare(upgradeableProjectiles, self.upgradeableProjectiles) or not compare(upgradeableAltAbilities, self.upgradeableAltAbilities) then
  
    self.upgradeableProjectiles = upgradeableProjectiles
    self.upgradeableAltAbilities = upgradeableAltAbilities
    
    widget.clearListItems(self.damageList)
    widget.clearListItems(self.projList)
    widget.clearListItems(self.altList)
    widget.setButtonEnabled("btnUpgrade", false)

    for i, item in pairs(self.upgradeableDamageTypesName) do
      local selectedItem = widget.addListItem(self.damageList)
      local listItem = string.format("%s.%s", self.damageList, selectedItem)

      widget.setText(string.format("%s.itemName", listItem), item)
      widget.setData(listItem,
        {
          index = i
        })
      
      if self.upgradeableDamageTypes[i] == weapon.parameters.elementalType then widget.setListSelected(self.damageList, selectedItem)
      else if self.upgradeableDamageTypes[i] == weaponConfig.elementalType then widget.setListSelected(self.damageList, selectedItem) end end
      
      widget.setVisible(string.format("%s.unavailableoverlay", listItem), false)
    end
    
    for i, item in pairs(weaponConfig.projectileTypesName or {"None"}) do
      local selectedItem = widget.addListItem(self.projList)
      local listItem = string.format("%s.%s", self.projList, selectedItem)

      widget.setText(string.format("%s.itemName", listItem), item)
      widget.setData(listItem,
        {
          index = i
        })
      
      if weaponConfig.projectileTypes then
        if weapon.parameters.rangedIndex == i then widget.setListSelected(self.projList, selectedItem) end
      else widget.setListSelected(self.projList, selectedItem) end
      
      widget.setVisible(string.format("%s.unavailableoverlay", listItem), not weaponConfig.projectileTypesName)
    end
    
    for i, item in pairs(weaponConfig.altAbilitiesName or {"None"}) do
      local selectedItem = widget.addListItem(self.altList)
      local listItem = string.format("%s.%s", self.altList, selectedItem)

      widget.setText(string.format("%s.itemName", listItem), item)
      widget.setData(listItem,
        {
          index = i
        })
      
      if weaponConfig.altAbilities then if weaponConfig.altAbilities[i] == weapon.parameters.altAbilityType then widget.setListSelected(self.altList, selectedItem) end
      else widget.setListSelected(self.altList, selectedItem) end
      
      widget.setVisible(string.format("%s.unavailableoverlay", listItem), not weaponConfig.altAbilitiesName)
    end

    self.selectedDamage = nil
    self.selectedProjectile = nil
    self.selectedAltAbility = nil
    
    widget.setButtonEnabled("btnUpgrade", false)
    
    itemSelected()
  end
end

function itemSelected()
  local listItem = widget.getListSelected(self.damageList)
  self.selectedDamage = listItem
  local listItem2 = widget.getListSelected(self.projList)
  self.selectedProjectile = listItem2
  local listItem3 = widget.getListSelected(self.altList)
  self.selectedAltAbility = listItem3
  
  if self.selectedDamage and self.selectedProjectile and self.selectedAltAbility then widget.setButtonEnabled("btnUpgrade", true) end
end

function doUpgrade()
  if self.selectedDamage and self.selectedProjectile and self.selectedAltAbility then
    local widgetData1 = widget.getData(string.format("%s.%s", self.damageList, self.selectedDamage))
    local widgetData2 = widget.getData(string.format("%s.%s", self.projList, self.selectedProjectile))
    local widgetData3 = widget.getData(string.format("%s.%s", self.altList, self.selectedAltAbility))
    
    local selectedDamageData = self.upgradeableDamageTypes[widgetData1.index]
    local selectedProjectileData = self.upgradeableProjectiles[widgetData2.index] or ""
    local selectedAltAbilityData = self.upgradeableAltAbilities[widgetData3.index] or ""
    
    local selectedBulletDamageData = selectedDamageData
    if selectedBulletDamageData == "physical" then selectedBulletDamageData = "" end
    local upgradeItem = player.primaryHandItem()
    
    if upgradeItem then
      local consumedItem = player.consumeItem(upgradeItem, false, true)
      if consumedItem then
        local upgradedItem = copy(consumedItem)
        local data = config.getParameter("upgradeData")
        
        replacePatternInData(data, nil, "<elementalType>", selectedDamageData)
        
        util.mergeTable(upgradedItem.parameters, data)
        
        if next(self.upgradeableProjectiles) ~= nil then 
          local rangeddata = config.getParameter("rangedUpgradeData")
          
          replacePatternInData(rangeddata, nil, "<projectileType>", selectedProjectileData)
          replacePatternInData(rangeddata, nil, "<elementalBulletType>", selectedBulletDamageData)
          
          replacePatternInData(rangeddata, nil, "<fireType>", root.itemConfig(upgradedItem).config.projectileTypesFireType[widgetData2.index])
          
          rangeddata.primaryAbility.fireTime        = root.itemConfig(upgradedItem).config.projectileTypesFireTime[widgetData2.index]
          rangeddata.primaryAbility.projectileCount = root.itemConfig(upgradedItem).config.projectileTypesProjectileCount[widgetData2.index]
          rangeddata.primaryAbility.inaccuracy      = root.itemConfig(upgradedItem).config.projectileTypesInaccuracy[widgetData2.index]
          rangeddata.primaryAbility.burstCount      = root.itemConfig(upgradedItem).config.projectileTypesBurstCount[widgetData2.index]
          rangeddata.primaryAbility.burstTime       = root.itemConfig(upgradedItem).config.projectileTypesBurstTime[widgetData2.index]
          
          local name = root.itemConfig(upgradedItem).config.shortdescription
          local projName = root.itemConfig(upgradedItem).config.projectileTypesName[widgetData2.index]
          
          replacePatternInData(rangeddata, nil, "<shortDescription>", name)
          replacePatternInData(rangeddata, nil, "<projectileTypeName>", projName)
          
          rangeddata.rangedIndex = widgetData2.index
          
          util.mergeTable(upgradedItem.parameters, rangeddata)
        else
          local meleedata = config.getParameter("meleeUpgradeData")
          
          local meleeType = root.itemConfig(upgradedItem).config.primaryAbility.damageConfig.damageSourceKind
          
          replacePatternInData(meleedata, nil, "<elementalBulletType>", selectedBulletDamageData)
          replacePatternInData(meleedata, nil, "<meleeType>", meleeType)
          
          util.mergeTable(upgradedItem.parameters, meleedata)
        end
        
        if next(self.upgradeableAltAbilities) ~= nil then 
          local altdata = config.getParameter("altUpgradeData")
          replacePatternInData(altdata, nil, "<altAbilityType>", selectedAltAbilityData)
          util.mergeTable(upgradedItem.parameters, altdata)
        end
        
        sb.logInfo("%s",upgradedItem)
        player.giveItem(upgradedItem)
      end
    end
    pane.dismiss()
  end
end

function hasValue(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end
