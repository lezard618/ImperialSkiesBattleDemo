local CameraManager = class("CameraManager")

local TEMPMAX = 999999
local CavalrySpeed = 600

function CameraManager:ctor()
	self:init()
end

function CameraManager:init()
	self.leftlocation = 0
	self.rightlocation = TEMPMAX
	self.leftTargetLocation = 0
	self.rightTargetLocation = TEMPMAX
	self.leftStartTime = TEMPMAX
	self.rightStartTime = TEMPMAX
end

function CameraManager:setLocation(faction, location, time)
	if faction == UnitFaction.LEFT then
		self:recordBehavior(time, CameraBehaviorType.location, true, location)
		self.leftlocation = location
		self.leftTargetLocation = 0
	else
		self:recordBehavior(time, CameraBehaviorType.location, false, location)
		self.rightlocation = location
		self.rightTargetLocation = TEMPMAX
	end
end

function CameraManager:reset(faction, start, location, startTime, speed)
	if faction == UnitFaction.LEFT then
		self.leftTargetLocation = location

		if self.leftStartTime >= startTime then
			self.leftStartTime = startTime
		end

		if start and self.leftlocation > start then
			self.leftlocation = start
		end

		if speed then
			self.leftSpeed = speed
		end
	else
		self.rightTargetLocation = location

		if self.rightStartTime >= startTime then
			self.rightStartTime = startTime
		end
		
		if start and self.rightlocation < start then
			self.rightlocation = start
		end

		if speed then
			self.rightSpeed = speed
		end
	end
end

--匀速直线运动
function CameraManager:run(faction, start, location, startTime, speed)
	if faction == UnitFaction.LEFT then
		if self.leftTargetLocation < location then
			self.leftTargetLocation = location
		end

		if self.leftStartTime >= startTime then
			self.leftStartTime = startTime
		end

		if start and self.leftlocation > start then
			self.leftlocation = start
		end

		if speed then
			self.leftSpeed = speed
		end
	else
		if self.rightTargetLocation > location then
			self.rightTargetLocation = location
		end

		if self.rightStartTime >= startTime then
			self.rightStartTime = startTime
		end
		
		if start and self.rightlocation < start then
			self.rightlocation = start
		end

		if speed then
			self.rightSpeed = speed
		end
	end
end

function CameraManager:recordRun()
	if self.leftStartTime ~= TEMPMAX then
		self:recordBehavior(self.leftStartTime, CameraBehaviorType.move, true, {self.leftTargetLocation, math.abs(self.leftTargetLocation - self.leftlocation) / (self.leftSpeed or CavalrySpeed) / globalTicks})
	elseif self.leftlocation and self.rightStartTime ~= TEMPMAX then
		self.leftTargetLocation = MaxBackgroundCount * BackgroundSingleWidth / 2 + UnitStartLocationBlanking
		self:recordBehavior(self.rightStartTime, CameraBehaviorType.move, true, {self.leftTargetLocation, math.abs(self.leftTargetLocation - self.leftlocation) / (self.rightSpeed or CavalrySpeed) / globalTicks})
	end

	if self.rightStartTime ~= TEMPMAX then
		self:recordBehavior(self.rightStartTime, CameraBehaviorType.move, false, {self.rightTargetLocation, math.abs(self.rightTargetLocation - self.rightlocation) / (self.rightSpeed or CavalrySpeed) / globalTicks})
	elseif self.rightlocation and self.leftStartTime ~= TEMPMAX then
		self.rightTargetLocation = MaxBackgroundCount * BackgroundSingleWidth / 2 - UnitStartLocationBlanking
		self:recordBehavior(self.leftStartTime, CameraBehaviorType.move, false, {self.rightTargetLocation, math.abs(self.rightTargetLocation - self.rightlocation) / (self.leftSpeed or CavalrySpeed) / globalTicks})
	end

	self.leftSpeed = nil
	self.leftStartTime = TEMPMAX
	self.rightSpeed = nil
	self.rightStartTime = TEMPMAX
end

--移动到某个位置
function CameraManager:goForward(faction, location, startTime, cost, start)
	if faction == UnitFaction.LEFT then
		if self.leftTargetLocation < location then
			self:recordBehavior(startTime, CameraBehaviorType.move, true, {location, cost, start})
			self.leftTargetLocation = location
		end
	else
		if self.rightTargetLocation > location then
			self:recordBehavior(startTime, CameraBehaviorType.move, false, {location, cost, start})
			self.rightTargetLocation = location
		end
	end
end

--加速运动
function CameraManager:rush(faction, location, startTime)
	if faction == UnitFaction.LEFT then
		if self.leftTargetLocation < location then
			self:recordBehavior(startTime, CameraBehaviorType.rush, true, {self.leftlocation, location, math.abs(location - self.leftlocation) / (CavalrySpeed / 1.8) / globalTicks})
			self.leftTargetLocation = location
		end
	else
		if self.rightTargetLocation > location then
			self:recordBehavior(startTime, CameraBehaviorType.rush, false, {self.rightlocation, location, math.abs(location - self.rightlocation) / (CavalrySpeed / 1.8) / globalTicks})
			self.rightTargetLocation = location
		end
	end
end

function CameraManager:findMiddle(list)
    local min = TEMPMAX
    local max = 0

    for k, v in pairs(list) do
        local x = v:getLocation().x
        if x > max then
            max = x
        end

        if x < min then
            min = x
        end
    end

    return (min + max) / 2
end

function CameraManager:recordLocation(leftList, rightList)
    local leftCamera = -1
    local rightCamera = -1
    if #leftList > 0 then
        leftCamera = self:findMiddle(leftList)
        self.leftlocation = leftCamera
    	self:recordBehavior(0, CameraBehaviorType.location, true, leftCamera)
		self.leftTargetLocation = 0
		self.leftStartTime = TEMPMAX
		self.leftCost = nil
    end

    if #rightList > 0 then
        rightCamera = self:findMiddle(rightList)
        self.rightlocation = rightCamera
    	self:recordBehavior(0, CameraBehaviorType.location, false, rightCamera)
		self.rightTargetLocation = TEMPMAX
		self.rightStartTime = TEMPMAX
		self.rightCost = nil
    end
end

function CameraManager:recordBehavior(frame, type, isLeft, record)
    local key = tostring(type)
    local id = tostring(isLeft and 1 or 2)
    local framestr = tostring(math.floor(frame))

    if frame > maxFrame then
        maxFrame = frame
    end

    if not arrayTable[3][framestr] then
        arrayTable[3][framestr] = {}
    end

    if not arrayTable[3][framestr][key] then
        arrayTable[3][framestr][key] = {}
    end

    arrayTable[3][framestr][key][id] = record
end


return CameraManager