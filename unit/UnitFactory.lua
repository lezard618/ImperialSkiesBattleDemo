local OpenServerFile = OpenServerFile
local OpenServerConfig = OpenServerConfig
local Unit = OpenServerFile("Unit")
local Infantry = OpenServerFile("Infantry")
local Archer = OpenServerFile("Archer")
local Gunner = OpenServerFile("Gunner")
local Cavalry = OpenServerFile("Cavalry")
local Boss = OpenServerFile("Boss")
local Boss2 = OpenServerFile("Boss2")
local Monroe = OpenServerFile("Monroe")

local heroConf = OpenServerConfig("heroConf")
local monsterConf = OpenServerConfig("monsterConf")

local UnitFactory = class("UnitFactory")

function UnitFactory.createUnit(heroInfo, faction, owner)
	local unit = nil
    local heroName = UnitFactory.getHeroName(heroInfo)

    if heroName == "monroe" then
        unit = Monroe.new()
    elseif heroInfo.class == UnitType.INFANTRY then
        unit = Infantry.new()
    elseif heroInfo.class == UnitType.GUNNER then
        unit = Gunner.new()
    elseif heroInfo.class == UnitType.ARCHER then
        unit = Archer.new()
    elseif heroInfo.class == UnitType.CAVALRY then
        unit = Cavalry.new()
    elseif heroInfo.class == UnitType.BOSS then
        if monsterConf[heroInfo.heroID].ifBoss == 2 then
            unit = Boss2.new()
        else
            unit = Boss.new()
        end
    else
        unit = Unit.new()
    end
    
    unit:init(heroInfo, faction, owner)
    unit:placeInBattle()
    
	return unit
end

function UnitFactory.getHeroName(heroInfo)
    if heroInfo.isMonster then
        return monsterConf[heroInfo.heroID].picture
    elseif heroInfo.isHero then
        return heroConf[heroInfo.heroID].picture
    else
        return monsterConf[heroInfo.heroID].picture
    end
end

return UnitFactory