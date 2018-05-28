
local OpenServerFile = OpenServerFile
local Bullet = OpenServerFile("Bullet")


local AnimationBullet = class("AnimationBullet",Bullet)

function AnimationBullet:ctor(startFrame)
    AnimationBullet.super.ctor(self, startFrame)
    
    self.animAttribute = {jsonName = nil, animName = "idle", loopCount = 1, zOrder = NodeZorder.UPPER}
end

function AnimationBullet.create(startFrame)
    local animBullet = AnimationBullet.new(startFrame)
    return animBullet
end

function AnimationBullet:copyAttribute(other)
    AnimationBullet.super.copyAttribute(self, other)
    
    --self.animAttribute = calc.tableShallowCopy(other.animAttribute or {})
    calc.tableShallowAdditional(self.animAttribute, other.animAttribute or {})
end

function AnimationBullet:createAnim(hold, handler)
    if self.animAttribute.jsonName == nil then
    	return nil
    end

    local info = {}
    info.jsonName = self.animAttribute.jsonName
    info.animName = self.animAttribute.animName
    info.loopCount = self.animAttribute.loopCount
    info.zOrder = self.animAttribute.zOrder
    info.flipX = self.bulletAttribute.senderFlipX
    info.ownerID = self.animAttribute.ownerID
    info.offsetLoc = self.animAttribute.offsetLoc
    info.boneName = self.animAttribute.boneName
    info.scale = self.animAttribute.scale
    info.isFullScale = self.animAttribute.isFullScale
    info.spineScale = self.animAttribute.spineScale
    
    info.location = self.location
    info.lockID = self.bulletAttribute.lockID
    
    info.hold = hold
    info.handler = handler
    info.relativePath = self.animAttribute.relativePath
    
    local behavior = {
        j = self.animAttribute.jsonName,
        a = self.animAttribute.animName,
        l = self.animAttribute.loopCount,
        z = math.floor(self.animAttribute.zOrder * 10) / 10,
        X = self.bulletAttribute.senderFlipX and 1 or 0,
        I = self.animAttribute.ownerID,
        b = self.animAttribute.boneName,
        sc = self.animAttribute.scale,
        
        lx =  math.floor(self.location.x * 10) / 10,
        ly =  math.floor(self.location.y * 10) / 10,
        lI = self.bulletAttribute.lockID,
        
        h = hold and 1 or 0,
        iF = self.animAttribute.isFullScale and 1 or 0,
        ssc = self.animAttribute.spineScale,
    }

    if self.animAttribute.offsetLoc then 
        behavior.fx = math.floor(self.animAttribute.offsetLoc.x * 10) / 10
        behavior.fy = math.floor(self.animAttribute.offsetLoc.y * 10) / 10
    end

    self:recordBehavior(self.curFrame, BulletBehaviorType.createAnim, {behavior, self.bulletAttribute.senderFaction})
end

return AnimationBullet