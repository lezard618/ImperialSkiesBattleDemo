
local OpenServerFile = OpenServerFile
local Unit = OpenServerFile("Unit")
local Bullet = OpenServerFile("Bullet")
local TrackBullet = OpenServerFile("TrackBullet")
local LineBullet = OpenServerFile("LineBullet")
local ArrowBullet = OpenServerFile("ArrowBullet")

local heroConf = OpenServerConfig("heroConf")
local monsterConf = OpenServerConfig("monsterConf")

local Archer = class("Archer", Unit)

function Archer:ctor(id)
    Archer.super.ctor(self, id)
    self.type = UnitType.ARCHER
    self.fightState = ArcherNone
    self.fightCount = 3
end

function Archer:startFight(frame)
    if not self:isAlive() then
        return
    end

    self.fightCount = 0
    self.fightState = ArcherFarShoot
    self.isInGuard = false
    self:setFrame(frame)
    local skillID = self:useActiveSkill()
    if skillID then
        self:useSkill(skillID)
    elseif self:checkCanAttack() then
        self:playAnimation("atk")
        self:recordBehavior(self.curFrame, UnitBehaviorType.state, UnitState.ATTACK)
    else
        self.fightCount = self.fightCount + 3
    end
end

function Archer:fightBack(frame, target, location)
    if self:checkCanAttack() then
        self.fightState = ArcherOutFightDis
        self.fightBackId = target:getID()
        self.fightBackLocation = location
        self:setFrame(frame)
        self:playAnimation("atk")
        self:recordBehavior(self.curFrame, UnitBehaviorType.state, UnitState.ATTACK)
    end
end

function Archer:getBullet()
    if self.heroInfo.isMonster then
        return monsterConf[self.heroInfo.heroID].bullet or "arrow"
    elseif self.heroInfo.isHero then
        return heroConf[self.heroInfo.heroID].commonBullet or "arrow"
    else
        return monsterConf[self.heroInfo.heroID].bullet or "arrow"
    end
end

function Archer:doAttack(event)
    if self.fightState == ArcherFarShoot then
        for i = 1, 3 do
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
    elseif self.fightState == ArcherOutFightDis then
        local line = self:getLineIndex()
        local bullet = LineBullet.create(self.curFrame + event.frame)
        self:setBulletAttribute(bullet, event)
        bullet.pursueAttribute.moveType = BulletMoveType.LINE
        bullet.animAttribute.jsonName = self:getBullet()
        bullet.animAttribute.loopCount = -1
        bullet.animAttribute.scale = LineScale[line] * DefaultValue.HERO_SPINE_SCALE
        bullet.hitEffectAttribute.jsonName = "ty_shouji"
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

function Archer:doUseSkill(event, skillIndex)
    if self.curSkillData then
        if self.curSkillData.damage and table.nums(self.curSkillData.damage) > 0 then
            local curFrame = self.curFrame + event.frame
            for i, damage in ipairs(self.curSkillData.damage) do
                local line = self:getLineIndex()
                local bullet = ArrowBullet.create(curFrame)
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

function Archer:startWait(frame)
    Archer.super.startWait(self, frame)
    self.fightState = ArcherNone
end

function Archer:startGuard()
    Archer.super.startGuard(self)
    self.fightState = ArcherInFightDis
end

function Archer:isFinish()
    return self.fightState == ArcherNone or self.fightCount >= 3 or not self:checkCanAttack()
end

return Archer