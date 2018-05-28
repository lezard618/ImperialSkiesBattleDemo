
local OpenServerFile = OpenServerFile
local Archer = OpenServerFile("Archer")
local Bullet = OpenServerFile("Bullet")
local LineBullet = OpenServerFile("LineBullet")

local heroConf = OpenServerConfig("heroConf")
local monsterConf = OpenServerConfig("monsterConf")

local Gunner = class("Gunner", Archer)

function Gunner:ctor(id)
    Gunner.super.ctor(self, id)
    self.type = UnitType.GUNNER
    self.fightState = ArcherNone
end

function Gunner:startFight(frame)
    if not self:isAlive() then
        return
    end
    
    self.fightState = ArcherFarShoot
    self.isInGuard = false
    self:setFrame(frame)
    local skillID = self:useActiveSkill()
    if skillID then
        self:useSkill(skillID)
    elseif self:checkCanAttack() then
        self:playAnimation("atk")
        self:recordBehavior(self.curFrame, UnitBehaviorType.state, UnitState.ATTACK)
    end
end

function Gunner:getLastLocation()
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

function Gunner:getBullet()
    if self.heroInfo.isMonster then
        return monsterConf[self.heroInfo.heroID].bullet or "bullet"
    elseif self.heroInfo.isHero then
        return heroConf[self.heroInfo.heroID].commonBullet or "bullet"
    else
        return monsterConf[self.heroInfo.heroID].bullet or "bullet"
    end
end

function Gunner:doAttack(event)
    if self.fightState == ArcherFarShoot then
        local line = self:getLineIndex()
        local bullet = LineBullet.create(self.curFrame + event.frame)
        self:setBulletAttribute(bullet, event)
        bullet.pursueAttribute.moveType = BulletMoveType.LINE
        bullet.animAttribute.jsonName = self:getBullet()
        bullet.animAttribute.loopCount = -1
        bullet.animAttribute.scale = LineScale[line] * DefaultValue.HERO_SPINE_SCALE
        bullet.hitEffectAttribute.jsonName = "ty_shouji"
        bullet.pursueAttribute.speed = 1200
        local line = self:getLineIndex()
        local targetList = MapManager:getUnitInLine(line, self:getReverseFaction())
        if targetList[1] then
            local hitPos = targetList[1]:getHitLocation()
            bullet.bulletAttribute.tid = targetList[1]:getID()
            bullet.pursueAttribute.destPoint.x = hitPos.x
            bullet.pursueAttribute.destPoint.y = bullet.location.y
            for i = 2, #targetList do
                table.insert(bullet.pursueAttribute.targetList, targetList[i]:getID())
            end
        else
            bullet.pursueAttribute.destPoint.x = self:getLastLocation()
            bullet.pursueAttribute.destPoint.y = bullet.location.y
        end
    elseif self.fightState == ArcherOutFightDis then
        local line = self:getLineIndex()
        local bullet = LineBullet.create(self.curFrame + event.frame)
        self:setBulletAttribute(bullet, event)
        bullet.pursueAttribute.moveType = BulletMoveType.LINE
        bullet.animAttribute.jsonName = self:getBullet()
        bullet.animAttribute.loopCount = -1
        bullet.animAttribute.scale = LineScale[line] * DefaultValue.HERO_SPINE_SCALE
        bullet.hitEffectAttribute.jsonName = "ty_shouji"
        bullet.pursueAttribute.speed = 1200
        bullet.bulletAttribute.tid = self.fightBackId
        bullet.pursueAttribute.destPoint.x = self.fightBackLocation.x
        bullet.pursueAttribute.destPoint.y = self.fightBackLocation.y

        self.fightState = ArcherInFightDis
    elseif self.targetPtr then
        local bullet = Bullet.create(self.curFrame + event.frame)
        self:setBulletAttribute(bullet, event)
        bullet.bulletAttribute.tid = self.targetPtr:getID()
        bullet.hitEffectAttribute.jsonName = "ty_shouji"
    end
end

function Gunner:doUseSkill(event, skillIndex)
    if self.curSkillData then
        if self.curSkillData.damage and table.nums(self.curSkillData.damage) > 0 then
            local curFrame = self.curFrame + event.frame
            for i, damage in ipairs(self.curSkillData.damage) do
                local line = self:getLineIndex()
                local bullet = LineBullet.create(curFrame)
                self:setBulletAttribute(bullet, event)
                bullet.pursueAttribute.moveType = BulletMoveType.LINE
                bullet.animAttribute.jsonName = self.curSkillData.effectFly or "bullet"
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

            self.curSkillData = nil
        else
            self.curSkillData = nil
        end
    end
end

function Gunner:isFinish()
    return self.state ~= UnitState.ATTACK and self.state ~= UnitState.PRE_ATTACK and self.isComplete
end

return Gunner