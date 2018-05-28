
local OpenServerFile = OpenServerFile
local Archer = OpenServerFile("Archer")
local Bullet = OpenServerFile("Bullet")
local TrackBullet = OpenServerFile("TrackBullet")
local skillConf = OpenServerConfig("skillConf")
local monsterConf = OpenServerConfig("monsterConf")

local Boss = class("Boss", Archer)

function Boss:ctor(id)
    Boss.super.ctor(self, id)
    self.type = UnitType.BOSS
end

function Boss:getTypeName()
    if monsterConf[self.heroInfo.heroID].ifBoss == 2 or monsterConf[self.heroInfo.heroID].ifBoss == 3 then
        return "humanboss"
    end

    return Boss.super.getTypeName(self)
end

function Boss:setBossDamage(damage)
    self.bossDamage = damage
end

function Boss:initBaseBuff()
    Boss.super.initBaseBuff(self)

    self.attribute.hp = self.attribute.hp - self.bossDamage
    self:addStartHp(self.attribute.hp, self.orgAttribute.hp)
end

function Boss:updateActiveBuff(levelState)
    if levelState == LevelStateType.GUNNER_START or levelState == LevelStateType.ARCHER_START 
        or levelState == LevelStateType.INFANTRY_START or levelState == LevelStateType.CAVALRY_START then
        local deleteList = {}
        for k, info in pairs(self.buffList) do
            info.endRound = info.endRound - 1
            if info.endRound <= 0 then
                local buff = info.buff
                if buff.extraHpId then
                    for i, info in ipairs(self.extraHp) do
                        if info.id == buff.extraHpId then
                            table.remove(self.extraHp, i)
                            break
                        end
                    end
                end
                table.insert(deleteList, k)
                self.isNeedResetBuff = true
            end
        end

        for i,v in ipairs(deleteList) do
            self:recordBehavior(0, UnitBehaviorType.removeBuff, self.buffList[v].buff.Id)
            self.buffList[v] = nil
        end
    end
end

function Boss:getStartHp()
    return self.orgAttribute.hp - self.bossDamage
end

function Boss:getHitLocation()
    local offsetLoc = self.anim:getBonePosition("hit_point")

    return {x = offsetLoc.x + self.location.x + MyRandom:random(-50, 50), y = offsetLoc.y + self.location.y + MyRandom:random(-50, 50)}
end

function Boss:fightBack(frame, target, location)
    if self:checkCanAttack() then
        self.fightState = ArcherOutFightDis
        self.fightBackId = target:getID()
        self.fightBackLocation = location
        self:setFrame(frame)
        self:playAnimation("atk")
        self:recordBehavior(self.curFrame, UnitBehaviorType.state, UnitState.ATTACK)
    end
end

function Boss:doUseSkill(event, skillIndex)
    if self.curSkillData then
        if self.curSkillData.damage and table.nums(self.curSkillData.damage) > 0 then
            local curFrame = self.curFrame + event.frame
            for i, damage in ipairs(self.curSkillData.damage) do
                local line = self:getLineIndex()
                local bullet = TrackBullet.create(curFrame)
                self:setBulletAttribute(bullet, event)
                bullet.animAttribute.jsonName = self.curSkillData.effectFly or "arrow"
                bullet.animAttribute.loopCount = -1
                bullet.animAttribute.scale = LineScale[line] * DefaultValue.HERO_SPINE_SCALE
                bullet.hitEffectAttribute.jsonName = self.curSkillData.effectSuffer or "ty_shouji"
                bullet.damageAttribute.attack = bullet.damageAttribute.attack * damage

                local reverseFaction = self:getReverseFaction()
                local targetList = MapManager:getUnitsByRange(self, self.curSkillData.range)
                local target = targetList[1] or MapManager:getUnitByRandom(reverseFaction)

                if target then
                    local hitPos = target:getHitLocation()
                    bullet.bulletAttribute.tid = target:getID()
                    bullet.pursueAttribute.destPoint.x = hitPos.x
                    bullet.pursueAttribute.destPoint.y = hitPos.y
                end
                
                if self.curSkillData.spread and self.curSkillData.spread == 1 then
                    bullet.bulletAttribute.spreadRange = self.curSkillData.spreadRange
                    bullet.bulletAttribute.spreadRatio = self.curSkillData.spreadRatio
                end

                if skillIndex ~= self.skill.backSkill then
                    -- 子弹从龙的嘴上吐出
                    local offsetLoc = cc.p(-265.63, 96.92)
                    bullet:setLocation({x = offsetLoc.x + self.location.x, y = offsetLoc.y + self.location.y})
                    -- 子弹飞行高度控制
                    bullet.pursueAttribute.height = 100
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

function Boss:doAttack(event)
    if self.fightState == ArcherInFightDis then
        self.skill:useSkill(self.skill:getAttackSkillIndex())
        self.curSkillData = self.skill:getSkillConf(self.skill:getAttackSkillIndex())
        if self.curSkillData then
            if self.curSkillData.damage and table.nums(self.curSkillData.damage) > 0 then
                local curFrame = self.curFrame + event.frame
                for i, damage in ipairs(self.curSkillData.damage) do
                    local targets = MapManager:getUnitsByRange(self, self.curSkillData.range)
                    for i, target in ipairs(targets) do
                        local bullet = Bullet.create(curFrame)
                        self:setBulletAttribute(bullet, event)
                        bullet.bulletAttribute.tid = target:getID()
                        bullet.hitEffectAttribute.jsonName = self.curSkillData.effectSuffer or "ty_shouji"
                        bullet.damageAttribute.attack = bullet.damageAttribute.attack * damage

                        if self.curSkillData.spread and self.curSkillData.spread == 1 then
                            bullet.bulletAttribute.spreadRange = self.curSkillData.spreadRange
                            bullet.bulletAttribute.spreadRatio = self.curSkillData.spreadRatio
                        end
                    end
                end

                self.curSkillData = nil
            else
                self.curSkillData = nil
            end
        end

        self.fightState = ArcherInFightDis
    elseif self.fightState == ArcherOutFightDis then
        if self.skill.backSkill then
            self.skill:useSkill(self.skill.backSkill.Id)
            self.curSkillData = self.skill:useBackSkill()
        end

        if self.curSkillData then
            if self.curSkillData.damage and table.nums(self.curSkillData.damage) > 0 then
                local curFrame = self.curFrame + event.frame
                for i, damage in ipairs(self.curSkillData.damage) do
                    local utype = (GameManager.levelHandler.curState == LevelStateType.CAVALRY_FIGHT) and UnitType.CAVALRY or UnitType.INFANTRY
                    local targets = MapManager:getUnitByType(self:getReverseFaction(), utype)
                    for i, target in ipairs(targets) do
                        if target:isAlive() and (target.front == nil or target.front:getType() ~= utype) then
                            local bullet = Bullet.create(curFrame)
                            self:setBulletAttribute(bullet, event)
                            bullet.bulletAttribute.tid = target:getID()
                            bullet.hitEffectAttribute.jsonName = self.curSkillData.effectSuffer or "ty_shouji"
                            bullet.damageAttribute.attack = bullet.damageAttribute.attack * damage

                            if self.curSkillData.spread and self.curSkillData.spread == 1 then
                                bullet.bulletAttribute.spreadRange = self.curSkillData.spreadRange
                                bullet.bulletAttribute.spreadRatio = self.curSkillData.spreadRatio
                            end

                            if target then
                                if self.curSkillData.throughNumber then
                                    local startLineLocaion = clone(target:getLineLocation())
                                    local startDamage = bullet.damageAttribute.attack
                                    for i = 1, self.curSkillData.throughNumber do
                                        startLineLocaion.x = startLineLocaion.x + 1
                                        startDamage = startDamage * (1 + self.curSkillData.throughAdd)
                                        if startDamage <= 0 then
                                            break
                                        end

                                        local nextbullet = Bullet.create(curFrame)
                                        self:setBulletAttribute(nextbullet, event)
                                        nextbullet.bulletAttribute.tid = target:getID()
                                        nextbullet.hitEffectAttribute.jsonName = self.curSkillData.effectSuffer or "ty_shouji"
                                        nextbullet.damageAttribute.attack = startDamage
                                        local nextTargetList = MapManager:getUnitAfter(startLineLocaion, target:getFaction())
                                        if nextTargetList[1] then
                                            nextbullet.bulletAttribute.tid = nextTargetList[1]:getID()
                                        else
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                self.fightCount = self.fightCount + 3
                self.curSkillData = nil
            end
        end
        
        self.fightState = ArcherInFightDis
    end
end

function Boss:addStartHp(hp, total)
    self.damageData.startHp = hp
    self.damageData.total = total
end

return Boss