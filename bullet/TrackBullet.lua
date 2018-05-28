
local OpenServerFile = OpenServerFile
local AnimationBullet = OpenServerFile("AnimationBullet")

local TrackBullet = class("TrackBullet", AnimationBullet) 

function TrackBullet:ctor(startFrame)
    TrackBullet.super.ctor(self, startFrame)
    self.longRange = true

    self.pursueAttribute = {}--TabMg:createArrayTable(8)
    self.pursueAttribute.type = BulletPursueType.DESTINATION
    self.pursueAttribute.moveType = BulletMoveType.PARABOLA
    self.pursueAttribute.speed = 800
    self.pursueAttribute.isReverseDirection = false
    self.pursueAttribute.accelerate = 0 --只是简单的加速度 没有考虑加速度的方向
    self.pursueAttribute.destPoint = {x = 0, y = 0}
    self.pursueAttribute.rotateEnabled = true
    self.pursueAttribute.height = 200
    
    self.anim = nil
end

function TrackBullet.create(startFrame)
    local trackBullet = TrackBullet.new(startFrame)
    return trackBullet
end

function TrackBullet:onPursue()
    local startTime = self.curFrame
    local targetLocation = self.pursueAttribute.destPoint
    local time = cc.pGetDistance(self.location, targetLocation) / self.pursueAttribute.speed / globalTicks
    self:recordBehavior(self.curFrame, BulletBehaviorType.start, {self.location.x, self.location.y, targetLocation.x, targetLocation.y, self.pursueAttribute.moveType, time, self.pursueAttribute.height})
    self.curFrame = self.curFrame + time
    self:startNow()

    CameraManager:run(self:getFaction(), nil, targetLocation.x, startTime, self.pursueAttribute.speed)
end

function TrackBullet:onInit()
    TrackBullet.super.onInit(self)
    self:createAnim(true)
end

return TrackBullet
