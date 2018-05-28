
local Unit = OpenServerFile("Unit")
local monsterConf = OpenServerConfig("monsterConf")

local Replace = class("Replace", Unit)

function Replace:ctor(id)
    Replace.super.ctor(self, id)
    self.type = 0
    self.hero = nil
    self.soldier = nil
    self.sender = nil
end

function Replace:setReplaceHeroAndSoldier(hero, soldier, sender)
    self.hero = hero
    self.soldier = soldier
    self.sender = sender
end

function Replace:skillBuff()
    local levelHandler = GameManager.levelHandler
    for k, info in pairs(self.buffList) do
        local buffInfo = info.buff
        if not info.isActived then
            if buffInfo.specialEffect and buffInfo.specialEffect == SpecialEffectType.Replace and self.hero and self.soldier then
                self.soldier.heroInfo = calc.tableShallowCopy(self.hero.heroInfo)
                self.soldier.buffList = calc.tableShallowCopy(self.hero.buffList)
                self.soldier.killBuffList = calc.tableShallowCopy(self.hero.killBuffList)
                self.soldier.hitBuffList = calc.tableShallowCopy(self.hero.hitBuffList)
                self.soldier.changeBuffList = calc.tableShallowCopy(self.hero.changeBuffList)
                self.soldier.attribute = calc.tableShallowCopy(self.hero.attribute)
                self.soldier.orgAttribute = calc.tableShallowCopy(self.hero.orgAttribute)
                self.soldier.addAttribute = calc.tableShallowCopy(self.hero.addAttribute)
                self.soldier.baseAttriTab = calc.tableShallowCopy(self.hero.baseAttriTab)
                self.soldier.baseBuff = calc.tableShallowCopy(self.hero.baseBuff)
                self.soldier.skill:init(self.soldier)
                self.soldier.anim = nil
                self.soldier:createHeroAnimation()
                self.soldier:setFlipX(self.hero:isFlipX())
                self.soldier.isComplete = true
                self.soldier.heroInfo.isReplaced = true

                for k,v in pairs(self.buffList) do
                    local buffInfo = info.buff
                    self.soldier:addBuff(buffInfo.Id, self.sender and self.sender:getID() or 0)
                end
                self.soldier:skillBuff()

                self.soldier:recordBehavior(0, UnitBehaviorType.switch, {self.hero:getID(), self.soldier.attribute.hp})

                local units = MapManager:getUnitMap()
                for k, unit in pairs(units) do
                    unit:triggerChangeBuff(ChanceTypeCondition.AfterReplace, 0)
                end
            end
        end
    end

    MapManager:removeFromDead(self.uid)
end

return Replace