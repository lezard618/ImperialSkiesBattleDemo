
local OpenServerFile = OpenServerFile
local Unit = OpenServerFile("Unit")
local Bullet = OpenServerFile("Bullet")


local Infantry = class("Infantry", Unit)

function Infantry:ctor(id)
    Infantry.super.ctor(self, id)
    self.type = UnitType.INFANTRY
    self.speedFact = 1
end

function Infantry:startFight(frame)
	if not self:isAlive() then
		return
	end

	self.isInGuard = false
	self:setFrame(frame)
	self:transformNormalState(UnitState.STAND, self.curFrame)
	self.readyToAttack = UnitFightState.NoTarget
	self.isComplete = false
	self:searchTarget()

	if self:needPursue() then
		self:transformNormalState(UnitState.WALK, self.curFrame)
		self.readyToAttack = UnitFightState.CloseToTarget
	else
		if self.targetPtr then
			self.readyToAttack = UnitFightState.WaitForFight
		end
	end

	self.delayAttack = MyRandom:random(2, 8)
	self.beatBack = MyRandom:random(2, 8)
	self.beatBackFrame = self.curFrame
	local skillID = self:useActiveSkill()
	if skillID then
		self.delayAttack = 1
	end
	self.curSkillID = skillID
end

function Infantry:calcSpeedFact()
	local levelHandler = GameManager.levelHandler
	if not levelHandler.baseLen then
		levelHandler.baseLen = math.abs(self.location.x - self.targetLocation.x)
		self.speedFact = 1
	else
		self.speedFact = math.abs(self.location.x - self.targetLocation.x) / levelHandler.baseLen
	end
end

function Infantry:attackState()
	return self.readyToAttack
end

function Infantry:doFight()
	if self:isAlive() and self.readyToAttack == UnitFightState.WaitForFight then
		self.readyToAttack = UnitFightState.Fighting
	end
end

function Infantry:searchTarget()
	if self.targetPtr and ((not self.targetPtr:isAlive()) or self.front) then
		self.targetPtr = nil
	elseif self.targetPtr and self.targetPtr:getType() ~= UnitType.INFANTRY then
		if #MapManager:getUnitByType(self:getReverseFaction(), UnitType.INFANTRY) > 0 then
			self.targetPtr = nil
		elseif (self.targetPtr.targetPtr and not self.targetPtr.targetPtr:isAlive()) or not self.targetPtr.targetPtr then
			self.targetPtr.targetPtr = self
		end
	end

    if self.state ~= UnitState.DIE and (not self.front) and (not self.targetPtr) then
		local reverseFaction = self:getReverseFaction()
		local targets = MapManager:getUnitInLine(self:getLineIndex(), reverseFaction, UnitType.INFANTRY)
		if table.nums(targets) <= 0 then
			local target = MapManager:getFirstUnit(reverseFaction, UnitType.INFANTRY)
			if target then
				targets = {target}
			else
				local temp = MapManager:getUnitsInFirstRow(reverseFaction)
				targets = temp
				for i,v in ipairs(temp) do
					if self:getLineIndex() == v:getLineIndex() and v:isAlive() then
						targets = {v}
						break
					end
				end
			end
		end

		for i,v in ipairs(targets) do
			if v:isAlive() then
				self.targetPtr = v
				if v:getType() ~= UnitType.INFANTRY and ((v.targetPtr and not v.targetPtr:isAlive()) or not v.targetPtr) then
					v.targetPtr = self
				end

				break
			end
		end
    end
end

function Infantry:needPursue()
	local column = 0
	local front = self.front
	while front do
		column = column + 1
		front = front.front
	end

    local fact = 1
    if self.faction == UnitFaction.RIGHT then
        fact = -1
    end

    local selfPos = self:getLocation()
	local targetUnit = self.targetPtr
	local targetLocationX
	if self.front then
    	targetLocationX = self.front.targetLocation.x - UnitSpace * fact
    elseif (targetUnit and targetUnit:getType() == UnitType.INFANTRY) then
    	targetLocationX = MaxBackgroundCount * BackgroundSingleWidth / 2 - (column + 0.5) * UnitSpace * fact
    elseif targetUnit then
    	local temp = targetUnit:getLocation().x - (column + 1) * UnitSpace * fact
    	if (self.faction == UnitFaction.RIGHT and temp < selfPos.x) or (self.faction == UnitFaction.LEFT and temp > selfPos.x) then
	    	targetLocationX = temp
    	end
    end

    if not targetLocationX then
    	return false
    end

    if targetUnit and targetUnit:getType() ~= UnitType.INFANTRY then
    	if math.abs(selfPos.x - targetLocationX) < (UnitSpace / 4) then
	        return false
	    end
    elseif math.abs(selfPos.x - targetLocationX) < (UnitSpace / 2) then
        return false
    end

    self.targetLocation = cc.p(targetLocationX, selfPos.y)

    return true
end

function Infantry:handleWalk()
	local startTime = self.curFrame
	local time = self:onMove()

	if self.targetPtr and self.targetPtr:isAlive() and GameManager.levelHandler:canFightBack(self.targetPtr:getFaction(), self.targetPtr:getType(), self.targetPtr:getLineIndex()) then
		if ((self.targetPtr:getType() == UnitType.GUNNER or self.targetPtr:getType() == UnitType.ARCHER) and self.targetPtr:getLineIndex() == self:getLineIndex()) then
			GameManager.levelHandler:setFightBack(self.targetPtr:getFaction(), self.targetPtr:getType(), self.targetPtr:getLineIndex())

			local distance = 400
			local speed = (self.targetPtr:getType() == UnitType.GUNNER) and 1200 or 800
			local fightBackTime = 30 + distance / speed / globalTicks
			local frame = (time > 2*fightBackTime) and time - 2 * fightBackTime or 0
			frame = frame + self.curFrame
			local location = self:getHitLocation()
			if self.targetPtr:getFaction() == UnitFaction.LEFT then
				location.x = location.x + (self.targetLocation.x - self.location.x) + distance
			else
				location.x = location.x + (self.targetLocation.x - self.location.x) - distance
			end
			self.targetPtr:fightBack(frame, self, location)
		-- elseif self.targetPtr:getType() == UnitType.BOSS then--去掉步兵的boss反击
		-- 	GameManager.levelHandler:setFightBack(self.targetPtr:getFaction(), self.targetPtr:getType(), self.targetPtr:getLineIndex())
			
		-- 	local distance = 400
		-- 	local triggerFrame = 14
		-- 	local speed = self.attribute.speed * self.speedFact
		-- 	local frame = distance / speed / globalTicks
		-- 	frame = self.curFrame + time - triggerFrame * 2 - frame
		-- 	local location = self:getHitLocation()
		-- 	self.targetPtr:fightBack(frame, self, location)
		end
	end
	
	self.curFrame = self.curFrame + time
	self.beatBackFrame = self.curFrame
	CameraManager:goForward(self.faction, self.targetLocation.x, startTime, time, self.location.x)
    self:setLocation(self.targetLocation, self.curFrame)
	self:transformNormalState(UnitState.STAND, self.curFrame)
	if self.targetPtr then
		self.readyToAttack = UnitFightState.WaitForFight
	else
		self.readyToAttack = UnitFightState.NoTarget
	end
end

function Infantry:onMove()
    local targetLocation = self.targetLocation
    local time = cc.pGetDistance(self.location, targetLocation) / (self.attribute.speed * self.speedFact) / globalTicks
    self:recordBehavior(self.curFrame, UnitBehaviorType.walk, {self.location.x, self.location.y, targetLocation.x, targetLocation.y, time})
    return time
end

function Infantry:update()
    self.anim:update()
    self:updateEvents()
    if self:needCleanup() or self.state == UnitState.WAIT then
    	return
    end

    if self.state == UnitState.WALK then
        self:handleWalk()
	elseif self:isAlive() and self.readyToAttack == UnitFightState.Fighting and not self.front then
		local levelHandler = GameManager.levelHandler
		local curAttackTimes = levelHandler.infantryFightTime
		if curAttackTimes > 0 and self.targetPtr then
			self.delayAttack = self.delayAttack - 1
			if self.delayAttack == 0 then
			    if self.curSkillID then
			        self:useSkill(self.curSkillID)
			    elseif self:checkCanAttack() then
			        self:playAnimation("atk")
			        self:recordBehavior(self.curFrame, UnitBehaviorType.state, UnitState.ATTACK)
			    else
					self.isComplete = true
			    end
			elseif self.delayAttack > 0 then
				self.curFrame = self.curFrame + 2
			end

			if self.targetPtr.targetPtr == self and self.targetPtr:isAlive() and self.targetPtr:getType() ~= UnitType.INFANTRY then
				self.beatBack = self.beatBack - 1
				if self.targetPtr:checkCanAttack() then
					if self.beatBack == 0 then
						self.targetPtr:closeFighting(self.beatBackFrame)
					elseif self.beatBack > 0 then
						self.beatBackFrame = self.beatBackFrame + 2
					end
				end
			end

			if self.delayAttack <= 0 and self.isComplete and ((self.beatBack <= 0 and self.targetPtr.targetPtr == self and self.targetPtr.isComplete) or self.targetPtr.targetPtr ~= self or self.targetPtr:getType() == UnitType.INFANTRY or not self.targetPtr:isAlive()) then
				self.readyToAttack = UnitFightState.FinishFight
			end
		else
			self.readyToAttack = UnitFightState.FinishFight
		end
	elseif not self:isAlive() then
        self:handleDie()
	end
end

function Infantry:doAttack(event)
	if self.targetPtr then
	    local bullet = Bullet.create(self.curFrame + event.frame)
	    self:setBulletAttribute(bullet, event)
	    bullet.bulletAttribute.tid = self.targetPtr:getID()
	    bullet.hitEffectAttribute.jsonName = "ty_shouji"
	    self.attackTimes = self.attackTimes + 1
	    self:reduceBuffLastCount(self.curFrame + event.frame)
	end
	self.isComplete = true
end

function Infantry:doUseSkill(event, skillIndex)
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

	        self:reduceBuffLastCount(curFrame)
	        self.curSkillData = nil
        else
        	self.curSkillData = nil
        end
    end
	self.isComplete = true
end

function Infantry:startWait(frame)
	Infantry.super.startWait(self, frame)
	self.speedFact = 1
end

function Infantry:isFinish()
    return GameManager.levelHandler.infantryFightTime <= 0
end

function Infantry:toDie(frame)
	self.isComplete = true
	local behindUnits = {}

	local behind = self.behind
	local pos = self:getLocation()
	local curLineLocation = self.lineLocation
	local tempLocation 
	while behind do
		if behind:getType() == UnitType.INFANTRY then
			table.insert(behindUnits, behind)
		end
		
		tempLocation = clone(behind:getLineLocation())
		behind:setLineLocation(curLineLocation)
		behind = behind.behind
		curLineLocation = tempLocation
	end
	Infantry.super.toDie(self)

	-- 步兵补位
	if GameManager.levelHandler.curState == LevelStateType.INFANTRY_FIGHT 
		and GameManager.levelHandler.infantryFightState == "doFight" then

		local fact = 1
	    if self.faction == UnitFaction.RIGHT then
	        fact = -1
	    end

		for idx, behind in ipairs(behindUnits) do
			if behind:isAlive() then
				behind.isComplete = false
				local curFrame = (frame > behind.curFrame) and frame or behind.curFrame
				behind:setFrame(curFrame)
				behind.targetLocation.x = pos.x - UnitSpace * fact * (idx - 1)
				behind:transformNormalState(UnitState.WALK, curFrame)
				behind.readyToAttack = UnitFightState.CloseToTarget
			end
		end
	end
end


return Infantry