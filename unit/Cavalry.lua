
local OpenServerFile = OpenServerFile
local Unit = OpenServerFile("Unit")
local Bullet = OpenServerFile("Bullet")

local globalConf = OpenServerConfig("globalConf")

local Cavalry = class("Cavalry", Unit)

function Cavalry:ctor(id)
    Cavalry.super.ctor(self, id)
    self.type = UnitType.CAVALRY
    self.fightState = CavalryStateNone
    self.finish = true
    self.targetList = {}
    self.energy = 0
    self.speedFact = 1
end

function Cavalry:startFight(frame)
    if not self:isAlive() then
        return
    end
    
	self.isInGuard = false
    local line = self:getLineIndex()
    local reverseFaction = self:getReverseFaction()
    local cavalryList = MapManager:getUnitInLine(line, reverseFaction, UnitType.CAVALRY, true)
    local infantryList = MapManager:getUnitInLine(line, reverseFaction, UnitType.INFANTRY, true)
    local gunnerList = MapManager:getUnitInLine(line, reverseFaction, UnitType.GUNNER, true)
    local archerList = MapManager:getUnitInLine(line, reverseFaction, UnitType.ARCHER, true)
    local bossList = MapManager:getUnitInLine(line, reverseFaction, UnitType.BOSS)
    local targetList = {}
    for i, unit in ipairs(cavalryList) do
    	table.insert(targetList, unit)
    end

    for i, unit in ipairs(infantryList) do
    	table.insert(targetList, unit)
    end

    for i, unit in ipairs(gunnerList) do
    	table.insert(targetList, unit)
    end

    for i, unit in ipairs(archerList) do
    	table.insert(targetList, unit)
    end

    for i, unit in ipairs(bossList) do
    	table.insert(targetList, unit)
    end

    self.targetList = targetList
    self.slowDownLocation = cc.p(0, 0)
    self.slowDownTime = 0
    self.energy = CavalryMaxEnergy + globalConf[1].riderStrengthen
    self.finish = false
	self:setFrame(frame)

    local fact = 1
    if self.faction == UnitFaction.RIGHT then
        fact = -1
    end

	self.lastLocation = cc.p(MaxBackgroundCount * BackgroundSingleWidth / 2 + UnitStartLocationBlanking * fact - math.floor((self.indexInMatrix - 1) / MaxUnitInLine) * UnitSpace * fact, self.location.y)

	local target = targetList[1] or MapManager:getLastUnit(self:getReverseFaction())
	if target then
		self.targetLocation = cc.p(target:getLocation().x, self.location.y)
	else
	    self.targetLocation = cc.p(self.lastLocation.x, self.location.y)
	end
end

function Cavalry:calcSpeedFact()
    if not self:isAlive() then
        return
    end
    
    local fact = 1
    if self.faction == UnitFaction.RIGHT then
        fact = -1
    end

	local levelHandler = GameManager.levelHandler
	if not levelHandler.baseLen then
		levelHandler.baseLen = math.abs(self.location.x - self.lastLocation.x)
		self.speedFact = 1
	else
		self.speedFact = math.abs(self.location.x - self.lastLocation.x) / levelHandler.baseLen
	end

	local startTime = self.curFrame
    local targetLocation = cc.p(self.location.x + 700 * fact, self.location.y)
    local time = cc.pGetDistance(self.location, targetLocation) / (300 * (self.speedFact + 1) / 2) / globalTicks
    self:recordBehavior(self.curFrame, UnitBehaviorType.walk, {self.location.x, self.location.y, targetLocation.x, targetLocation.y, time, CavalryStateRush})
    self.curFrame = self.curFrame + time
    self.location.x = targetLocation.x
    self.location.y = targetLocation.y

	CameraManager:rush(self.faction, targetLocation.x, startTime)

	local startTime = self.curFrame
	local target = MapManager:getLastUnit(self:getReverseFaction())
    local targetLocation = cc.p((target and target:getLocation().x) or (MaxBackgroundCount * BackgroundSingleWidth / 2 + UnitStartLocationBlanking * fact), self.location.y)
    local time = cc.pGetDistance(self.location, targetLocation) / (700 * self.speedFact) / globalTicks
    self:recordBehavior(self.curFrame, UnitBehaviorType.walk, {self.location.x, self.location.y, targetLocation.x, targetLocation.y, time, CavalryStateRun})
	CameraManager:run(self.faction, self.location.x, targetLocation.x, startTime)

    self.targetLocation.x = self.location.x
    self.targetLocation.y = self.location.y
end

function Cavalry:calcFight()
	self.fightList = {}
	local beatBackUnit = nil

	for _, target in ipairs(self.targetList) do
		local dist = target:getLocation().x
		if target:getType() == UnitType.CAVALRY then
			dist = self.location.x + (target:getLocation().x - self.location.x) / 2
		end
		local targetLocation = cc.p(dist, self.location.y)
		local time = cc.pGetDistance(self.location, targetLocation) / (700 * self.speedFact) / globalTicks

		-- find first beatback Unit
		if beatBackUnit == nil then
			if (target:getType() == UnitType.ARCHER or target:getType() == UnitType.GUNNER) then
				beatBackUnit = target

				local distance = 200
				local speed = (beatBackUnit:getType() == UnitType.GUNNER) and 1200 or 800

				local fightBackTime = 20 + distance / speed / globalTicks
				local fact = 1
			    if beatBackUnit.faction == UnitFaction.RIGHT then
			        fact = -1
			    end

			    local location = self:getHitLocation()
				location.x = location.x + (beatBackUnit:getLocation().x - self.location.x) + distance * fact

				local info = {
					fightType = "beatback",
					target = beatBackUnit,
					time = time - 2*fightBackTime,
					fightBackTime = fightBackTime,
					targetLocation = location,
				}
				table.insert(self.fightList, info)
			elseif target:getType() == UnitType.BOSS then
				beatBackUnit = target

				local distance = 200
				local triggerFrame = 14
				local frame = distance / 700 / globalTicks
				local location = self:getHitLocation()
				local info = {
					fightType = "beatback",
					target = beatBackUnit,
					time = time - triggerFrame * 2 - frame,
					targetLocation = location,
				}
				table.insert(self.fightList, info)
			end
		end

		local info = {
			fightType = "attack",
			target = target,
			time = time,
			targetLocation = targetLocation,
		}

		table.insert(self.fightList, info)
	end

	-- table.sort(self.fightList, function(a, b)
	-- 	return a.time < b.time
	-- end)
end

function Cavalry:slowDown()
	self.finish = true
	self.curFrame = self.curFrame + self.slowDownTime
	local location = self.slowDownLocation
	local fact = 1
    if self.faction == UnitFaction.RIGHT then
        fact = -1
    end

	local targetLocation = cc.p(location.x + 100 * fact, location.y)
    local time = cc.pGetDistance(location, targetLocation) / 200 / globalTicks
    self:recordBehavior(self.curFrame, UnitBehaviorType.walk, {location.x, location.y, targetLocation.x, targetLocation.y, time, CavalryStateSlowDown})
    self.curFrame = self.curFrame + time
    location.x = targetLocation.x
    location.y = targetLocation.y

    targetLocation = cc.p(location.x - 3000 * fact, location.y)
    time = cc.pGetDistance(location, targetLocation) / 100 / globalTicks
    self:recordBehavior(self.curFrame, UnitBehaviorType.walk, {location.x, location.y, targetLocation.x, targetLocation.y, time, CavalryStateGoBack})
    self.curFrame = self.curFrame + time
end

function Cavalry:runThrough()
	self.finish = true
	self.curFrame = self.curFrame + self.slowDownTime
	local location = self.slowDownLocation
	local fact = 1
    if self.faction == UnitFaction.RIGHT then
        fact = -1
    end

	local targetLocation = cc.p(location.x + 300 * fact, location.y)
	local time = cc.pGetDistance(location, targetLocation) / (700 * self.speedFact) / globalTicks
    self:recordBehavior(self.curFrame, UnitBehaviorType.walk, {location.x, location.y, targetLocation.x, targetLocation.y, time, CavalryStateRun})
    self.slowDownTime = time
    self.slowDownLocation = targetLocation
end

function Cavalry:doBeatBack(index)
	if self:getRowIndex() > index then
		return
	end

	if self:isAlive() and not self.finish then
		if #self.fightList > 0 then
			local info = self.fightList[1]
			if info.fightType == "beatback" then
				if GameManager.levelHandler:canFightBack(info.target:getFaction(), info.target:getType(), info.target:getLineIndex()) then
		        	GameManager.levelHandler:setFightBack(info.target:getFaction(), info.target:getType(), info.target:getLineIndex())
		        	info.target:fightBack(self.curFrame + info.time, self, info.targetLocation)
		        end

        		table.remove(self.fightList, 1)
		    end
		end
	end
end

function Cavalry:doFight(index)
	if self:getRowIndex() > index then
		return
	end

	if self:isAlive() and not self.finish then
		local fact = 1
	    if self.faction == UnitFaction.RIGHT then
	        fact = -1
	    end

	    if self.energy <= 0 then
        	self:slowDown()
        	return
        end

		if #self.fightList <= 0 then
			local target = MapManager:getLastUnit(self:getReverseFaction(), UnitType.CAVALRY)
			local targetLocation = cc.p((target and target:getLocation().x) or (MaxBackgroundCount * BackgroundSingleWidth / 2 + UnitStartLocationBlanking * fact), self.location.y)
			local time = cc.pGetDistance(self.location, targetLocation) / (700 * self.speedFact) / globalTicks
			self:recordBehavior(self.curFrame, UnitBehaviorType.walk, {self.location.x, self.location.y, targetLocation.x, targetLocation.y, time, CavalryStateRun})
			self.slowDownTime = time
			self.slowDownLocation = targetLocation
			if GameManager:isBossFight() then
				self:runThrough()
    			self:slowDown()
			else
				self:slowDown()
			end
		else
			local info = self.fightList[1]
			if info.fightType == "attack" then
				if info.target:isAlive() then
					if self:checkCanAttack() then
				        local event = {floatValue = 0, intValue = 1, name = "trigger", stringValue = ""}
				        local bullet = Bullet.create(self.curFrame + info.time)
				        self:setBulletAttribute(bullet, event)
				        bullet.damageAttribute.attack = bullet.damageAttribute.attack * self.energy / CavalryMaxEnergy
				        bullet.bulletAttribute.tid = info.target:getID()
						bullet.hitEffectAttribute.jsonName = "ty_shouji"
						bullet.pursueAttribute = {}
						bullet.pursueAttribute.destPoint = info.targetLocation
					end

			        self:reduceBuffLastCount(self.curFrame + info.time)
			        local reduce = (globalConf[1].riderThrough + self:getSkillEnergy()) + globalConf[1].riderThroughRandom * MyRandom:random(-100, 100) / 100
			        if reduce < 10 then
			        	reduce = 10
			        end
			        self.energy = self.energy - reduce

			        self.slowDownTime = info.time
			        self.slowDownLocation = info.targetLocation
			    end

        		table.remove(self.fightList, 1)
		    end
		end
	end
end

function Cavalry:doAttack(event)
	if self.targetPtr then
	    local bullet = Bullet.create(self.curFrame + event.frame)
	    self:setBulletAttribute(bullet, event)
	    bullet.bulletAttribute.tid = self.targetPtr:getID()
	    bullet.hitEffectAttribute.jsonName = "ty_shouji"
	end
end

function Cavalry:update()
    self.anim:update()
    self:updateEvents()
    if self:needCleanup() or self.state == UnitState.WAIT then
    	return
    end

	if self.state == UnitState.ATTACK then
        self:handleAttack()
    elseif self.state == UnitState.USE_SKILL then
        self:handleUseSkill()
    elseif self.state == UnitState.DIE then
        self:handleDie()
	end
end

function Cavalry:isFinish()
	return self.finish
end

function Cavalry:startWait(frame)
	Cavalry.super.startWait(self, frame)
	self.speedFact = 1
end

function Cavalry:isHitEnabled()
    return self.fightState == CavalryStateRush or self.isInGuard
end

function Cavalry:toWait()
	if self.faction == UnitFaction.LEFT then
		self.targetLocation.x = self.location.x + 1
	else
		self.targetLocation.x = self.location.x - 1
	end
	self:faceToDestination()
	Cavalry.super.toWait(self)
end

function Cavalry:getSkillEnergy()
    local energy = 0
    for i, info in pairs(self.buffList) do
        if info.buff.specialEffect == SpecialEffectType.AddThroughEnergy then
            energy = energy + info.buff.specialEffectValue
        end
    end

    return energy
end

function Cavalry:getHitLocation(frame)
	local pos = Cavalry.super.getHitLocation(self)
	if frame and
		GameManager.levelHandler.curState == LevelStateType.CAVALRY_FIGHT then
		local fact = 1
		if self.faction == UnitFaction.RIGHT then
			fact = -1
		end

		pos.x = pos.x + (frame - self.curFrame) * globalTicks * (700 * self.speedFact) * fact
	end
	return pos
end

return Cavalry