
local OpenServerFile = OpenServerFile
local Unit = OpenServerFile("Unit")
local Archer = OpenServerFile("Archer")
local Bullet = OpenServerFile("Bullet")
local TrackBullet = OpenServerFile("TrackBullet")
local LineBullet = OpenServerFile("LineBullet")
local ArrowBullet = OpenServerFile("ArrowBullet")

local heroConf = OpenServerConfig("heroConf")
local monsterConf = OpenServerConfig("monsterConf")

local Monroe = class("Monroe", Archer)

function Monroe:ctor(id)
    Monroe.super.ctor(self, id)
end

function Monroe:doUseSkill(event, skillIndex)
    if self.curSkillData then
        if self.curSkillData.damage and table.nums(self.curSkillData.damage) > 0 then
            local curFrame = self.curFrame + event.frame
            local reverseFaction = self:getReverseFaction()
            local targetList = MapManager:getUnitsByRange(self, self.curSkillData.range)
            local damage = self.curSkillData.damage[1]
            for i, target in ipairs(targetList) do
                local line = self:getLineIndex()
                local bullet = ArrowBullet.create(curFrame)
                self:setBulletAttribute(bullet, event)
                bullet.animAttribute.jsonName = self.curSkillData.effectFly or "arrow"
                bullet.animAttribute.loopCount = -1
                bullet.animAttribute.scale = LineScale[line] * DefaultValue.HERO_SPINE_SCALE
                bullet.hitEffectAttribute.jsonName = self.curSkillData.effectSuffer or "ty_shouji"
                bullet.damageAttribute.attack = bullet.damageAttribute.attack * damage

                if target then
                    local hitPos = target:getHitLocation()
                    bullet.bulletAttribute.tid = target:getID()
                    bullet.pursueAttribute.destPoint.x = hitPos.x
                    bullet.pursueAttribute.destPoint.y = hitPos.y

                    local beginLocation = MaxBackgroundCount * BackgroundSingleWidth / 2
                    if target:getFaction() == UnitFaction.LEFT then
                        beginLocation = beginLocation - UnitStartLocationBlanking
                    else
                        beginLocation = beginLocation + UnitStartLocationBlanking
                    end

                    local time1 = 40 + 32 + MyRandom:random(0, 15)
                    local time2 = math.abs(hitPos.x - beginLocation) / 16
                    bullet.pursueAttribute.speed = math.abs(hitPos.x - self.location.x) / (time1 + time2) / globalTicks
                end
                
                if self.curSkillData.spread and self.curSkillData.spread == 1 then
                    bullet.bulletAttribute.spreadRange = self.curSkillData.spreadRange
                    bullet.bulletAttribute.spreadRatio = self.curSkillData.spreadRatio
                end
            end

            for i = 2, 3 do
                local line = self:getLineIndex()
                local bullet = ArrowBullet.create(self.curFrame + event.frame + 16 * (i - 1))
                self:setBulletAttribute(bullet, event)
                bullet.damageAttribute.attack = bullet.damageAttribute.attack / 3
                bullet.animAttribute.jsonName = self:getBullet()
                bullet.animAttribute.loopCount = -1
                bullet.animAttribute.scale = LineScale[line] * DefaultValue.HERO_SPINE_SCALE
                bullet.hitEffectAttribute.jsonName = "ty_shouji"

                local reverseFaction = self:getReverseFaction()
                local target = MapManager:getUnitByRandom(reverseFaction)

                if target then
                    local hitPos = target:getHitLocation()
                    bullet.bulletAttribute.tid = target:getID()
                    bullet.pursueAttribute.destPoint.x = hitPos.x
                    bullet.pursueAttribute.destPoint.y = hitPos.y

                    local beginLocation = MaxBackgroundCount * BackgroundSingleWidth / 2
                    if target:getFaction() == UnitFaction.LEFT then
                        beginLocation = beginLocation - UnitStartLocationBlanking
                    else
                        beginLocation = beginLocation + UnitStartLocationBlanking
                    end

                    local time1 = 40 + (3 - i) * 16 + MyRandom:random(0, 15)
                    local time2 = math.abs(hitPos.x - beginLocation) / 16
                    bullet.pursueAttribute.speed = math.abs(hitPos.x - self.location.x) / (time1 + time2) / globalTicks
                end
            end

            self.fightCount = self.fightCount + 3
            self.curSkillData = nil
        else
            self.curSkillData = nil
            self:doAttack(event)
        end
    else
        self:doAttack(event)
    end
end

return Monroe