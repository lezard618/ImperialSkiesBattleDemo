
local globalConf = OpenServerConfig("globalConf")

local BulletAttribute = class("BulletAttribute")

function BulletAttribute:ctor()
    self.sid = 0
    self.tid = 0
    self.skillID = 0
    self.skillStage = 0
    self.senderHeroID = 0
    self.senderFaction = UnitFaction.LEFT
    self.senderInfo = {}
    self.senderType = UnitType.INFANTRY
    self.longRange = false
end

function BulletAttribute.create()
    local bulletAttr = BulletAttribute.new()
    return bulletAttr
end

local BulletDamageAttribute = class("BulletDamageAttribute")

function BulletDamageAttribute:ctor()
    self.attack = 80                    --攻击
    self.hurtInfantry = 0               --对步兵额外伤害
    self.hurtCavalry = 0                --对骑兵额外伤害
    self.hurtArcher = 0                 --对弓兵额外伤害
    self.hurtGunner = 0                 --对枪兵额外伤害
    self.hurtHero = 0                   --对英雄额外伤害
    self.extraDamage = 0                --对所有人额外伤害
    self.critDamage = 0                 --暴击的额外伤害
end

function BulletDamageAttribute.create()
    local bulletDamageAttr = BulletDamageAttribute.new()
    return bulletDamageAttr
end

local ConfigHitLocationType = {HEAD = "HitLocationType.Head", CHEST = "HitLocationType.Chest", FOOT = "HitLocationType.Foot"}

local BulletHitEffectAttribute = class("BulletHitEffectAttribute")

function BulletHitEffectAttribute:ctor()
    self.jsonName = ""
    self.animName = "idle"
    self.zOrder = NodeZorder.UPPER
    self.followTarget = false
    self.offsetLoc = cc.p(0,0)
    self.locationType = ConfigHitLocationType.CHEST
end

function BulletHitEffectAttribute.create()
    local bulletHitEffectAttr = BulletHitEffectAttribute.new()
    return bulletHitEffectAttr
end

local BulletEnterEffectAttribute = class("BulletEnterEffectAttribute")

function BulletEnterEffectAttribute:ctor()
    self.jsonName = ""
    self.animName = "idle"
    self.zOrder = NodeZorder.UPPER
    self.offsetLoc = cc.p(0,0)
end

function BulletEnterEffectAttribute.create()
    local bulletEnterEffectAttr = BulletEnterEffectAttribute.new()
    return bulletEnterEffectAttr
end

local Bullet = class("Bullet")

function Bullet:ctor(startFrame)
    self.bid = BulletInfo:seed()
    self.location = {x = 0, y = 0}
    self.firstTimeFlag = true
    self.startFlag = false
    self.autoCleanup = false
    self.line = 0
    self.targetIDList = {}
    self.preBuffFactor = {}
    self.curFrame = startFrame
    
    self.enterChildVec = {}
    self.exitChildVec = {}
    self.stateChildVec = {}
    self.followChildIDs = {}

    self.bulletAttribute = BulletAttribute.create()
    
    self.damageAttribute = BulletDamageAttribute.create()
    
    self.hitEffectAttribute = BulletHitEffectAttribute.create()
    
    self.enterEffectAttribute = BulletEnterEffectAttribute.create()

    MapManager:addBullet(self)
end

function Bullet:getID()
    return self.bid
end

function Bullet:getFaction()
    return self.bulletAttribute.faction
end

function Bullet:setLineIndex(line)
    self.line = line
end

function Bullet:getLineIndex()
    return self.line
end

function Bullet:setLocation(locatoin)
    self.location.x = locatoin.x
    self.location.y = locatoin.y
end

function Bullet:getLocation()
    if not self.curLocation then
        self.curLocation = cc.p(self.location.x, self.location.y)
    else
        if self.curLocation.x ~= self.location.x then
            self.curLocation.x = self.location.x
        end
        if self.curLocation.y ~= self.location.y then
            self.curLocation.y = self.location.y
        end
    end

    return self.curLocation
end

function Bullet:getContentSize()
    local pos = self:getLocation()
    return cc.rect(pos.x - 50, pos.y - 50, 100, 100)
end

function Bullet:setVisible(isVisible, isRight)

end

function Bullet.create(startFrame)
	local bullet = Bullet.new(startFrame)
    return bullet
end

function Bullet:needCleanup()
    return self.autoCleanup
end

function Bullet:setAutoCleanup(autoCleanup)
    self.autoCleanup = autoCleanup
end

function Bullet:cleanup()
	self:onExit()
	self:onCleanup()

    for k, v in pairs(self.followChildIDs) do
        local bullet = MapManager:getBulletByID(k)

        if bullet and bullet:isCleanupByFollower() then
            bullet:setAutoCleanup(true)
        end
    end
end

function Bullet:onCleanup()
    for k, v in pairs(self.followChildIDs) do
        local bullet = MapManager:getBulletByID(k)

        if bullet then 
            bullet:setLocation(self:getLocation())
        else
            self.followChildIDs[k] = nil
        end
    end
end

function Bullet:update(ticks)
    if self:needCleanup() then
    	return
    end
    
    self.curFrame = self.curFrame + 2
    self.ticks = GameManager:getTicks(self.bulletAttribute.lockID)

    if self:isFailure() then
        self:setAutoCleanup(true)
        return
    end
    
    if self.firstTimeFlag then
        self.firstTimeFlag = false
		self.ticks = 0
		self:onInit()
	end

    local firstTimeHitting = false
	if not self:isStart() then
		self:onPursue()
		
        if self:isStart() then --//first time hit
			self:onEnter()
            
            firstTimeHitting = true
		end
	end
	
    if self:isStart() then
	    if self:isOver() then
	    	self:setAutoCleanup(true)
	    	return
	    end
	       
        self:onHitting(firstTimeHitting)
	end

    for k, v in pairs(self.followChildIDs) do
        local bullet = MapManager:getBulletByID(k)

        if bullet then 
            bullet:setLocation(self:getLocation())
        else
            self.followChildIDs[k] = nil
        end
    end
end

function Bullet:copyAttribute(other)
    self.location.x = other.location.x
    self.location.y = other.location.y
    
    self.bulletAttribute = calc.tableShallowCopy(other.bulletAttribute)
    self.damageAttribute = calc.tableShallowCopy(other.damageAttribute)
    self.hitEffectAttribute = calc.tableShallowCopy(other.hitEffectAttribute)
    self.enterEffectAttribute = calc.tableShallowCopy(other.enterEffectAttribute)
    --TODO OTHER COPY
end

function Bullet:multipleAttribute(factor)
    calc.tableMultipleNumber(self.damageAttribute, factor)
end

function Bullet:onInit()
end

function Bullet:onMove()
end

function Bullet:isFailure()
	return false
end

function Bullet:startNow()
    self.startFlag = true
end

function Bullet:isStart()
	return self.startFlag
end

function Bullet:onPursue()
    self:startNow()
end

function Bullet:shootEnterChild()
    for _, childBullet in ipairs(self.enterChildVec) do
        MapManager:addBullet(childBullet)
    end

    self.enterChildVec = {}
end

function Bullet:shootStateChild(state)
    local remainVec = {}
    for _, info in ipairs(self.stateChildVec) do
        if info.state == state then
            MapManager:addBullet(info.bullet)
        else
            table.insert(remainVec, info)
        end
    end
    self.stateChildVec = remainVec
end

function Bullet:onEnter()
    self:searchTarget()

    for key, id in ipairs(self.targetIDList) do
        local unit = MapManager:getUnitByID(id)
        if unit then
            self:onEnterForTarget(unit)
            self:recordBehavior(self.curFrame, BulletBehaviorType.arrive, {id})
        end
    end

    self:shootEnterChild()
end

function Bullet:onEnterForTarget(target)
    local damageCount = self.damageAttribute.attack * self:getHitResult(target)
    if damageCount > 0 then
        local isCrit = self:getCriticalHitResult()
        if isCrit then
            damageCount = damageCount * (2 + self.damageAttribute.critDamage)
        end

        local isBlock = self:getBlockResult(target)
        if isBlock then
            damageCount = damageCount * (1 - globalConf[1].defenseProp)
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
                    local reduce1, reduce2 = shareUnit:spread(sharedHurt + sharedExtra, self.bulletAttribute.senderInfo, self.bulletAttribute.senderType, self.curFrame, sender)
                    if sender then
                        sender:suckBlood(reduce2, self.curFrame)
                    end
                end
            end

            damageCount = damageCount * (1 - shareHurtPer) + sharedHurt
            extraDamage = extraDamage * (1 - shareHurtPer) + sharedExtra
            local reduceValue, realReduce = target:reduceHP(damageCount, extraDamage, self.bulletAttribute.senderInfo, self.bulletAttribute.senderType, isCrit, isBlock, self.curFrame, sender)
            if sender then
                sender:triggerBuff(target, self.curFrame)
                sender:suckBlood(reduceValue, self.curFrame)

                if isCrit then
                    sender:triggerChangeBuff(ChanceTypeCondition.AfterCritical, self.curFrame)
                end
                
                local hurt = target:getHurtBack(self.longRange)
                sender:hurtBack(realReduce * hurt, self.curFrame, target)
            end
        else
            local spreadUnits
            if self.bulletAttribute.spreadRange and self.bulletAttribute.spreadRatio then
                spreadUnits = MapManager:getUnitsAround(target:getFaction(), target:getLocation(), target:getLineLocation(), target:getID(), self.bulletAttribute.spreadRange)
            end

            local reduceValue, realReduce = target:reduceHP(damageCount, extraDamage, self.bulletAttribute.senderInfo, self.bulletAttribute.senderType, isCrit, isBlock, self.curFrame, sender)

            if sender then
                sender:triggerBuff(target, self.curFrame)
                sender:suckBlood(realReduce, self.curFrame)

                if isCrit then
                    sender:triggerChangeBuff(ChanceTypeCondition.AfterCritical, self.curFrame)
                end
                
                local hurt = target:getHurtBack(self.longRange)
                sender:hurtBack(realReduce * hurt, self.curFrame, target)
            end

            if spreadUnits and reduceValue > 0 then
                local spreadValue = reduceValue * self.bulletAttribute.spreadRatio
                for i, spreadUnit in ipairs(spreadUnits) do
                    local reduce1, reduce2 = spreadUnit:spread(spreadValue, self.bulletAttribute.senderInfo, self.bulletAttribute.senderType, self.curFrame, sender)
                    if sender then
                        sender:triggerBuff(spreadUnit, self.curFrame)
                        sender:suckBlood(reduce2, self.curFrame)
                    end
                end
            end
        end

        if isCrit then
            local behavior = {target:getFaction(), 3003}
            target:recordBehavior(self.curFrame, UnitBehaviorType.floatWord, behavior)
        end

        if isBlock then
            local behavior = {target:getFaction(), 3000}
            target:recordBehavior(self.curFrame, UnitBehaviorType.floatWord, behavior)
            target:triggerChangeBuff(ChanceTypeCondition.AfterBlock, self.curFrame)
        end

        if self.hitEffectAttribute.jsonName and self.hitEffectAttribute.jsonName ~= "" then
            local location = cc.pAdd(target:getHitLocation(self.curFrame), self.hitEffectAttribute.offsetLoc)
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
            
            self:recordBehavior(self.curFrame, BulletBehaviorType.hitEffect, behavior)
        end
    else
        local behavior = {target:getFaction(), 3001}
        target:recordBehavior(self.curFrame, UnitBehaviorType.floatWord, behavior)
    end
end

function Bullet:onHitting(firstTime)
end

function Bullet:shootExitChild()
    for _, childBullet in ipairs(self.exitChildVec) do
        MapManager:addBullet(childBullet)
    end
    self.exitChildVec = {}
end

function Bullet:onExit()
    for key, id in ipairs(self.targetIDList) do
        local unit = MapManager:getUnitByID(id)
        if unit then
            self:onExitForTarget(unit)
        end
    end

    self:shootExitChild()
end

function Bullet:onExitForTarget(target)
end

function Bullet:isOver()
    return true
end

function Bullet:getSender()
    return MapManager:getUnitByID(self.bulletAttribute.sid)
end

function Bullet:getTarget()
    return MapManager:getUnitByID(self.bulletAttribute.tid)
end

function Bullet:searchTarget()
    -- if self.bulletAttribute.range > 0 then
    --     self.targetIDList = MapManager:getUnitIdInRange(self.bulletAttribute.rangeType, self.bulletAttribute.faction,self.location,self.bulletAttribute.range)
    --     -- local targetList = MapManager:getUnitInRange(self.bulletAttribute.rangeType, self.bulletAttribute.faction,self.location,self.bulletAttribute.range)
    --     -- self.targetIDList = {}--TabMg:createArrayTable(#targetList)
    --     -- for key, unit in ipairs(targetList) do
    --     --     table.insert(self.targetIDList, unit:getID())
    --     -- end
    -- else
        self.targetIDList = {self.bulletAttribute.tid}
    -- end
end

function Bullet:getHitResult(target)
    local extra = 0
    local sender = self:getSender()
    if sender then
        extra = sender:getExtraHit()
    end

    if MyRandom:random(1, 100) + extra > target.attribute.dodge then
        return 1
    else
        return 0
    end
end

function Bullet:getCriticalHitResult()
    return MyRandom:random(1, 100) <= self.bulletAttribute.senderCriticalHit
end

function Bullet:getBlockResult(target)
    local extra = 0
    local sender = self:getSender()
    if sender then
        extra = sender:getExtraNoBlock()
    end

    return (MyRandom:random(1, 100) + extra) <= target.attribute.offset
end

function Bullet:getExtraDamage(damage, target)
    local extraDamage = 0
    if target:getType() == UnitType.INFANTRY then
        extraDamage = extraDamage + damage * self.damageAttribute.hurtInfantry
    elseif target:getType() == UnitType.GUNNER then
        extraDamage = extraDamage + damage * self.damageAttribute.hurtGunner
    elseif target:getType() == UnitType.ARCHER then
        extraDamage = extraDamage + damage * self.damageAttribute.hurtArcher
    elseif target:getType() == UnitType.CAVALRY then
        extraDamage = extraDamage + damage * self.damageAttribute.hurtCavalry
    end

    if target:isHero() then
        extraDamage = extraDamage + damage * self.damageAttribute.hurtHero
    end
    
    extraDamage = extraDamage + damage * self.damageAttribute.hurtAll

    return extraDamage
end

function Bullet:addChild(bullet)--for enter
	MapManager:removeBullet(bullet)
    table.insert(self.enterChildVec, bullet)
end

function Bullet:addExitChild(bullet)
	MapManager:removeBullet(bullet)
    table.insert(self.exitChildVec, bullet)
end

function Bullet:addStateChild(bullet, state)
    MapManager:removeBullet(bullet)
    
    local info = {bullet = bullet, state = state}
    table.insert(self.stateChildVec, info)
end

function Bullet:addFollowBulletByID(id)
    self.followChildIDs[id] = true
end

function Bullet:removeFollowBulletID(id)
    self.followChildIDs[id] = nil
end

function Bullet:setCleanupByFollower(val)
    self.cleanupByFollower = val
end

function Bullet:isCleanupByFollower()
    return self.cleanupByFollower 
end

function Bullet:setBuffFloatWord(target)
end

function Bullet:setBulletInfo(info)
    --print("Bullet:setBulletInfo")
    calc.tableShallowAdditional(self, info)
end

function Bullet:recordBehavior(frame, type, record)
    local key = tostring(type)
    local id = tostring(self:getID())
    local framestr = tostring(math.floor(frame))

    if frame > maxFrame then
        maxFrame = frame
    end

    if not arrayTable[2][framestr] then
        arrayTable[2][framestr] = {}
    end

    if not arrayTable[2][framestr][id] then
        arrayTable[2][framestr][id] = {}
    end

    if arrayTable[2][framestr][id][key] then 
        table.insert(arrayTable[2][framestr][id][key], record)
    else
        arrayTable[2][framestr][id][key] = {}
        table.insert(arrayTable[2][framestr][id][key], record)
    end
end

return Bullet
