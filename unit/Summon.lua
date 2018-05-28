
local Unit = OpenServerFile("Unit")
local monsterConf = OpenServerConfig("monsterConf")

local Summon = class("Summon", Unit)

function Summon:ctor(id)
    Summon.super.ctor(self, id)
    self.type = 0
    self.speedFact = 1
    self.index = 1
end

function Summon:setSummonIndex(index)
    self.index = index
end

function Summon:skillBuff()
    local levelHandler = GameManager.levelHandler
    for k, info in pairs(self.buffList) do
        local buffInfo = info.buff
        if not info.isActived then
            if buffInfo.summon then
                local heroID = buffInfo.summon[1].Id
                for i = 1, buffInfo.summon[1].Num do
                    local unitInfo = monsterConf[heroID]
                    local info = {
                        class = unitInfo.class,
                        isHero = false,
                        heroID = heroID,
                        inherit = buffInfo.inherit,
                        index = self.index,
                    }

                    local hero = levelHandler:summonUnit(info, self.faction, self.owner)
                    info.uid = hero:getID()
                    info.buffID = buffInfo.Id
                    info.faction = self.faction
                    info.ownerID = self.owner:getID()

                    local location = hero:getLocation()
                    info.x = location.x
                    info.y = location.y
                    self.owner:recordBehavior(0, UnitBehaviorType.summon, info)
                end
            end
        end
    end

    MapManager:removeFromDead(self.uid)
end

return Summon