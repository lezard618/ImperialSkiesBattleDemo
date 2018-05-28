
local AnimReplacer = OpenServerFile("AnimReplacer")

local EffectManager = class("EffectManager")

function EffectManager:init()
    self.animList = {}
    self.freezingEffects = {}
end

function EffectManager:passWave()
    self.animList = {}
    self.freezingEffects = {}
end

function EffectManager:addAnimation(info)
    local jsonPath = ""
    if info.relativePath == nil then
        jsonPath = "spine/actors/"..info.jsonName
    else
        jsonPath = info.relativePath..info.jsonName
    end

    local anim = AnimReplacer.new(info.jsonName)

    if info.flipX then
        anim:setFlipX(info.flipX)
    end

    if info.location then
        anim:setPosition(ResolutionManager:scalePoint(info.location))
    end
    
    if info.lockID then
        anim:setTag(info.lockID)
    end
    
    -- if info.handler then
    --     anim:registerLuaHandler(info.handler)
    -- else
    --     anim:registerLuaHandler(function (name, tag, intValue, floatValue)
    --         local event = {name = name, tag = tag, intValue = intValue, floatValue = floatValue}
    --         GameManager:pushEvent(event)
    --     end)
    -- end
    
    if info.isFullScale then
        anim:setScaleX(ResolutionManager:getPhysicalSize().width / 1136 / 0.6)
        anim:setScaleY(ResolutionManager:getPhysicalSize().height / 640 / 0.6)
        --print("anim:setScaleX(", ResolutionManager:getPhysicalSize().width / 1136,ResolutionManager:getPhysicalSize().height / 640 )
    elseif info.scale then
        anim:setScale(info.scale)
    end
    
    local animInfo = {}--TabMg:createArrayTable(8)
    animInfo.jsonName = info.jsonName
    animInfo.anim = anim
    animInfo.zOrder = info.zOrder
    animInfo.hold = (info.hold and true) or false
    animInfo.ownerID = info.ownerID
    animInfo.offsetLoc = ResolutionManager:scalePoint((info.offsetLoc and info.offsetLoc) or cc.p(0,0))
    animInfo.keepTimeLeft = info.keepTimeLeft
    animInfo.boneName = info.boneName
    
    -- local followBone = false
    -- if animInfo.ownerID then
    --     local unit = MapManager:getUnitByID(animInfo.ownerID)
    --     if unit then
    --         if animInfo.boneName then
    --         	followBone = true
    --             unit.anim:addChildFollowBone(animInfo.boneName, animInfo.anim)
    --             animInfo.anim:setPosition(animInfo.offsetLoc)
    --         else
    --             animInfo.anim:setPosition(cc.pAdd(cc.p(unit:getPosition()), animInfo.offsetLoc))
    --         end
    --     end
    -- end
    
    --self.animList = calc.listPushFront(self.animList, animInfo)
    self.animList[anim] = animInfo
    
    if not followBone then
        local autoScale = nil

        if info.isFullScale then
            autoScale = false
        end
    end
    
    if info.animName then
        anim:setAnimation(1, info.animName, true)
        if info.keepEnding then
            anim:update(999)
        end
    end
    
    return anim
end

function EffectManager:setAnimationHold(anim, hold)
    local animInfo = self.animList[anim]

    if animInfo then
        animInfo.hold = hold
    end
end

function EffectManager:removeAnimation(anim)
    local animInfo = self.animList[anim]

    if animInfo then
        self.animList[anim].anim:removeFromParent()
        self.animList[anim] = nil
    end
end

function EffectManager:update()
    --local listIter = self.animList
    --while listIter do
    for k, v in pairs(self.animList) do
        local animInfo = v--listIter.value

        if not self.freezingEffects[k] then--self.freezingEffects[animInfo] then
            if animInfo.ownerID and animInfo.boneName and MapManager:getUnitByID(animInfo.ownerID) == nil then
                --self.animList, listIter = calc.listRemove(self.animList, listIter)
                self.animList[k] = nil
            else
                --if animInfo.ownerID and MapManager:getUnitByID(animInfo.ownerID) ~= nil then 
                   -- print("EffectManager:getOwnerName", MapManager:getUnitByID(animInfo.ownerID):getHeroName())
                --end

                --print("EffectManager:update()", animInfo.jsonName)
                local animTicks = GameManager:getTicks(animInfo.anim:getTag())
                animInfo.anim:update(animTicks)

                local complete = animInfo.anim:isComplete()

                if animInfo.keepTimeLeft then
                    animInfo.keepTimeLeft = animInfo.keepTimeLeft - animTicks
                    complete = animInfo.keepTimeLeft <= 0
                end

                -- if animInfo.ownerID then
                --     local unit = MapManager:getUnitByID(animInfo.ownerID)
                --     if unit then
                --         if animInfo.boneName == nil then
                --             animInfo.anim:setPosition(cc.pAdd(cc.p(unit:getPosition()), animInfo.offsetLoc))
                --         end
                --     else
                --         complete = true
                --         animInfo.hold = false
                --     end
                -- end

                UIManager.getInstance():updateNodeZOrder(animInfo.anim, animInfo.zOrder)

                if complete and (not animInfo.hold) then
                    animInfo.anim:removeFromParent()
                    self.animList[k] = nil
                end
            end
        end
    end
end


return EffectManager