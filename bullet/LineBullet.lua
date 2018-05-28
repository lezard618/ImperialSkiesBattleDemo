
local OpenServerFile = OpenServerFile
local TrackBullet = OpenServerFile("TrackBullet")

local LineBullet = class("LineBullet", TrackBullet)

function LineBullet:ctor(startFrame)
    LineBullet.super.ctor(self, startFrame)
    self.longRange = true
    self.pursueAttribute.targetList = {}
end

function LineBullet.create(startFrame)
    local LineBullet = LineBullet.new(startFrame)
    return LineBullet
end

function LineBullet:onPursue()
	if self.bulletAttribute.tid and self.bulletAttribute.tid ~= 0 then
		local unit = MapManager:getUnitByID(self.bulletAttribute.tid)
		if unit and unit:isAlive() then
    	elseif #self.pursueAttribute.targetList > 0 then
    		for i, id in ipairs(self.pursueAttribute.targetList) do
    			local unit = MapManager:getUnitByID(id)
    			if unit and unit:isAlive() then
    				local hitPos = unit:getHitLocation()
		            self.bulletAttribute.tid = id
		            self.pursueAttribute.destPoint.x = hitPos.x
    				break
    			end
    		end
		end
	end

    LineBullet.super.onPursue(self)
end

return LineBullet