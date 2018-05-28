
local OpenServerFile = OpenServerFile
local Boss = OpenServerFile("Boss")
local Bullet = OpenServerFile("Bullet")
local LineBullet = OpenServerFile("LineBullet")
local skillConf = OpenServerConfig("skillConf")


local Boss2 = class("Boss2", Boss)

function Boss2:ctor(id)
    Boss2.super.ctor(self, id)
end

function Boss2:getLastLocation()
    local x = 789
    if self.faction == UnitFaction.LEFT then
        x = 6061
    end

    local lastEnemy = MapManager:getLastUnit(self:getReverseFaction())
    if lastEnemy then
        if self.faction == UnitFaction.LEFT then
            x = lastEnemy:getLocation().x + 150
        else
            x = lastEnemy:getLocation().x - 150
        end
    end

    return x
end

function Boss2:doUseSkill(event, skillIndex)
    if self.curSkillData then
        if self.curSkillData.damage and table.nums(self.curSkillData.damage) > 0 then
            local curFrame = self.curFrame + event.frame
            for i, damage in ipairs(self.curSkillData.damage) do
                local line = self:getLineIndex()
                local bullet = LineBullet.create(curFrame)
                self:setBulletAttribute(bullet, event)
                bullet.pursueAttribute.moveType = BulletMoveType.LINE
                bullet.animAttribute.jsonName = self.curSkillData.effectFly or "arrow"
                bullet.animAttribute.loopCount = -1
                bullet.animAttribute.scale = LineScale[line] * DefaultValue.HERO_SPINE_SCALE
                bullet.hitEffectAttribute.jsonName = self.curSkillData.effectSuffer or "ty_shouji"
                bullet.damageAttribute.attack = bullet.damageAttribute.attack * damage
                bullet.pursueAttribute.speed = 1200

                --枪兵的技能无视range，按照普通攻击处理
                -- local targetList1 = MapManager:getUnitsByRange(self, self.curSkillData.range)
                local targetList = MapManager:getUnitInLine(line, self:getReverseFaction())
                local target = targetList[1]
                if target then
                    local hitPos = target:getHitLocation()
                    bullet.bulletAttribute.tid = target:getID()
                    bullet.pursueAttribute.destPoint.x = hitPos.x
                    bullet.pursueAttribute.destPoint.y = bullet.location.y
                    for i = 2, #targetList do
                        table.insert(bullet.pursueAttribute.targetList, targetList[i]:getID())
                    end
                else
                    bullet.pursueAttribute.destPoint.x = self:getLastLocation()
                    bullet.pursueAttribute.destPoint.y = bullet.location.y
                end

                if target then
                    if self.curSkillData.throughNumber then
                        local startLocation = bullet.pursueAttribute.destPoint.x
                        local startLineLocaion = clone(target:getLineLocation())
                        local startValue = 100
                        local startDamage = bullet.damageAttribute.attack
                        local lasttime = cc.pGetDistance(bullet.location, bullet.pursueAttribute.destPoint) / bullet.pursueAttribute.speed / globalTicks
                        for i = 1, self.curSkillData.throughNumber do
                            startLineLocaion.x = startLineLocaion.x + 1
                            startDamage = startDamage * (1 + self.curSkillData.throughAdd)
                            if startDamage <= 0 then
                                break
                            end

                            local nextbullet = LineBullet.create(curFrame + lasttime)
                            self:setBulletAttribute(nextbullet, event)
                            nextbullet.pursueAttribute.moveType = BulletMoveType.LINE
                            nextbullet.animAttribute.jsonName = self.curSkillData.effectFly or "bullet"
                            nextbullet.animAttribute.loopCount = -1
                            nextbullet.animAttribute.scale = LineScale[line] * DefaultValue.HERO_SPINE_SCALE
                            nextbullet.hitEffectAttribute.jsonName = self.curSkillData.effectSuffer or "ty_shouji"
                            nextbullet.location.x = startLocation
                            nextbullet.damageAttribute.attack = startDamage
                            nextbullet.pursueAttribute.speed = 1200

                            local nextTargetList = MapManager:getUnitAfter(startLineLocaion, target:getFaction())
                            if nextTargetList[1] then
                                local hitPos = nextTargetList[1]:getHitLocation()
                                nextbullet.bulletAttribute.tid = nextTargetList[1]:getID()
                                nextbullet.pursueAttribute.destPoint.x = hitPos.x
                                nextbullet.pursueAttribute.destPoint.y = nextbullet.location.y
                                for i = 2, #nextTargetList do
                                    table.insert(nextbullet.pursueAttribute.targetList, nextTargetList[i]:getID())
                                end
                            else
                                nextbullet.pursueAttribute.destPoint.x = self:getLastLocation()
                                nextbullet.pursueAttribute.destPoint.y = nextbullet.location.y

                                break
                            end

                            lasttime = lasttime + cc.pGetDistance(nextbullet.location, nextbullet.pursueAttribute.destPoint) / nextbullet.pursueAttribute.speed / globalTicks
                            startLocation = nextbullet.pursueAttribute.destPoint.x
                        end
                    end
                end

                if self.curSkillData.spread and self.curSkillData.spread == 1 then
                    bullet.bulletAttribute.spreadRange = self.curSkillData.spreadRange
                    bullet.bulletAttribute.spreadRatio = self.curSkillData.spreadRatio
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

return Boss2