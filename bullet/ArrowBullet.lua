
local OpenServerFile = OpenServerFile
local TrackBullet = OpenServerFile("TrackBullet")
local globalConf = OpenServerConfig("globalConf")

local ArrowBullet = class("ArrowBullet", TrackBullet) 

local EmpytIdle = "idle2"
local BlockIdle = "idle3"

function ArrowBullet:ctor(startFrame)
    ArrowBullet.super.ctor(self, startFrame)
    self.longRange = true
end

function ArrowBullet.create(startFrame)
    local arrowBullet = ArrowBullet.new(startFrame)
    return arrowBullet
end

function ArrowBullet:onPursue()
    local startTime = self.curFrame
    local targetLocation = self.pursueAttribute.destPoint
    local time = cc.pGetDistance(self.location, targetLocation) / self.pursueAttribute.speed / globalTicks
    self:recordBehavior(self.curFrame, BulletBehaviorType.start, {self.location.x, self.location.y, targetLocation.x, targetLocation.y, self.pursueAttribute.moveType, time, self.pursueAttribute.height})
    self.curFrame = self.curFrame + time
    self:startNow()
end

function ArrowBullet:onEnter()
    self:searchTarget()

    local specailAnim = nil
    for key, id in ipairs(self.targetIDList) do
        local unit = MapManager:getUnitByID(id)
        if unit then
            local state = self:onEnterForTarget(unit)
            if state == 1 then
                specailAnim = BlockIdle
            else
                specailAnim = nil
            end
        end
    end

    -- if specailAnim then
    --     self:recordBehavior(self.curFrame, BulletBehaviorType.playAnim, {specailAnim})
    --     self.curFrame = self.curFrame + 30
    -- end

    self:recordBehavior(self.curFrame, BulletBehaviorType.arrive, {id})

    self:shootEnterChild()
end

--1格挡  2闪避
function ArrowBullet:onEnterForTarget(target)
    local curFrame = self.curFrame + 15
    local state = 0
    local damageCount = self.damageAttribute.attack * self:getHitResult(target)
    if damageCount > 0 then
        local isCrit = self:getCriticalHitResult()
        if isCrit then
            damageCount = damageCount * (2 + self.damageAttribute.critDamage)
        end

        local isBlock = self:getBlockResult(target)
        if isBlock then
            damageCount = damageCount * (1 - globalConf[1].defenseProp)
            state = 1
        end

        local extraDamage = self:getExtraDamage(damageCount, target)
        
        local sender = self:getSender()
        local shareHurtPer = target:getShareHurt()
        if shareHurtPer > 0 then
            local shareUnitList = MapManager:getUnitsCanShareHurt(target:getFaction())
            local sharedHurt = damageCount * shareHurtPer / #shareUnitList
            local sharedExtra = extraDamage * shareHurtPer / #shareUnitList
            for i, shareUnit in ipairs(shareUnitList) do
                if shareUnit:getID() ~= target:getID() then
                    local reduce1, reduce2 = shareUnit:spread(sharedHurt + sharedExtra, self.bulletAttribute.senderInfo, self.bulletAttribute.senderType, curFrame, sender)
                    if sender then
                        sender:suckBlood(reduce2, curFrame)
                    end
                end
            end

            damageCount = damageCount * (1 - shareHurtPer) + sharedHurt
            extraDamage = extraDamage * (1 - shareHurtPer) + sharedExtra
            local reduceValue, realReduce = target:reduceHP(damageCount, extraDamage, self.bulletAttribute.senderInfo, self.bulletAttribute.senderType, isCrit, isBlock, curFrame, sender)
            if sender then
                sender:triggerBuff(target, curFrame)
                sender:suckBlood(reduceValue, curFrame)

                if isCrit then
                    sender:triggerChangeBuff(ChanceTypeCondition.AfterCritical, curFrame)
                end
                
                local hurt = target:getHurtBack(self.longRange)
                sender:hurtBack(realReduce * hurt, curFrame, target)
            end
        else
            local spreadUnits
            if self.bulletAttribute.spreadRange and self.bulletAttribute.spreadRatio then
                spreadUnits = MapManager:getUnitsAround(target:getFaction(), target:getLocation(), target:getLineLocation(), target:getID(), self.bulletAttribute.spreadRange)
            end

            local reduceValue, realReduce = target:reduceHP(damageCount, extraDamage, self.bulletAttribute.senderInfo, self.bulletAttribute.senderType, isCrit, isBlock, curFrame, sender)

            if sender then
                sender:triggerBuff(target, curFrame)
                sender:suckBlood(realReduce, curFrame)

                if isCrit then
                    sender:triggerChangeBuff(ChanceTypeCondition.AfterCritical, curFrame)
                end
                
                local hurt = target:getHurtBack(self.longRange)
                sender:hurtBack(realReduce * hurt, curFrame, target)
            end

            if spreadUnits and reduceValue > 0 then
                local spreadValue = reduceValue * self.bulletAttribute.spreadRatio
                for i, spreadUnit in ipairs(spreadUnits) do
                    local reduce1, reduce2 = spreadUnit:spread(spreadValue, self.bulletAttribute.senderInfo, self.bulletAttribute.senderType, curFrame, sender)
                    if sender then
                        sender:triggerBuff(spreadUnit, curFrame)
                        sender:suckBlood(reduce2, curFrame)
                    end
                end
            end
        end

        if isCrit then
            local behavior = {target:getFaction(), 3003}
            target:recordBehavior(curFrame, UnitBehaviorType.floatWord, behavior)
        end

        if isBlock then
            local behavior = {target:getFaction(), 3000}
            target:recordBehavior(curFrame, UnitBehaviorType.floatWord, behavior)
            target:triggerChangeBuff(ChanceTypeCondition.AfterBlock, curFrame)
        end

        if self.hitEffectAttribute.jsonName and self.hitEffectAttribute.jsonName ~= "" then
            local location = cc.pAdd(target:getHitLocation(curFrame), self.hitEffectAttribute.offsetLoc)
            if self.pursueAttribute ~= nil then
                location = cc.p(self.pursueAttribute.destPoint.x, self.pursueAttribute.destPoint.y)
            end

            local behavior = {
                j = self.hitEffectAttribute.jsonName,
                a = self.hitEffectAttribute.animName,
                l = self.hitEffectAttribute.loopCount,
                k = self.hitEffectAttribute.keepTimeLeft ~= nil and math.floor(self.hitEffectAttribute.keepTimeLeft * 10) / 10 or nil,
                X = self.bulletAttribute.senderFlipX and 1 or 0,
                lx = math.floor(location.x * 10) / 10,
                ly = math.floor(location.y * 10) / 10,
                fx = math.floor(self.hitEffectAttribute.offsetLoc.x * 10) / 10,
                fy = math.floor(self.hitEffectAttribute.offsetLoc.y * 10) / 10,
                h = 0
            }

            behavior.z = math.floor((self.hitEffectAttribute.zOrder + (location.y - target:getLocation().y)) * 10) / 10
            behavior.lI = self.bulletAttribute.lockID
            
            if self.hitEffectAttribute.followTarget then
                behavior.I = target:getID()
            end
            
            self:recordBehavior(curFrame, BulletBehaviorType.hitEffect, behavior)
        end
    else
        local behavior = {target:getFaction(), 3001}
        target:recordBehavior(curFrame, UnitBehaviorType.floatWord, behavior)
        state = 2
    end

    return state
end

return ArrowBullet
