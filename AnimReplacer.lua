
local skillActionTimeConf = OpenServerConfig("skillActionTimeConf")

local AnimReplacer = class("AnimReplacer")

function AnimReplacer:ctor(key, unit)
    self.unit = unit
    self.fileName = key
    self.animlist = {}
    self.bonePointList = {} 
    self:parseAnimData(key)
    self.flipX = false
    self.pos = {x = 0, y = 0}
    self.tag = 0
    self.isloop = false -- 是否循环播放
    self.rotation = 0
    self.isAnimComplete = false -- 是否播放完成
    self.curPlayAnimName = "" -- 当前播放的动画名称
    self.curPlayAnimFrame = 0 -- 当前播放的动画的帧数
    self.localscale = 1

    self.callback = {}
end

function AnimReplacer:parseAnimData(key)
    local skillInfo = skillActionTimeConf[key]
    if skillInfo then
        for key, info in pairs(skillInfo) do
            if key ~= "bone" then 
                self.animlist[key] = {}

                for _, event in ipairs(info) do
                    if event[1] == "trigger" or event[1] == "trigger1" or event[1] == "duang" then 
                        for i = 2, #event, 2 do
                            local data = {}
                            data.name = event[1]
                            data.intValue = event[i + 1]
                            local curFrame = math.floor(event[i] * 1 / 30 / globalTicks)

                            -- 步兵普通攻击速度加快2倍
                            if (self.unit:getType() == UnitType.INFANTRY) and (key == "atk") then
                                curFrame = math.floor(event[i] / 2 / 30 / globalTicks)
                            end

                            if curFrame % 2 == 1 then
                                curFrame = curFrame + 1
                            end
                            self.animlist[key][curFrame] = self.animlist[key][curFrame] or {}
                            table.insert(self.animlist[key][curFrame], data)
                        end
                    end

                    if event[1] == "end" then 
                        local data = {}
                        data.name = event[1]
                        local curFrame = math.floor(event[2] * 1 / 30 / globalTicks)

                        -- 步兵普通攻击速度加快2倍
                        if (self.unit:getType() == UnitType.INFANTRY) and (key == "atk") then
                            curFrame = math.floor(event[2] / 2 / 30 / globalTicks)
                        end

                        if curFrame % 2 == 1 then
                            curFrame = curFrame + 1
                        end
                        self.animlist[key][curFrame] = self.animlist[key][curFrame] or {}
                        table.insert(self.animlist[key][curFrame], data)
                    end
                end
            else
                for _, bone in ipairs(info) do
                    local p = {x = bone[2], y = bone[3]}
                    self.bonePointList[bone[1]] = p
                end
            end
        end

        self.animlist["hit_high"] = {}
        self.animlist["hit_high"][20] = {{["name"] = "end"}}
        self.animlist["hit_high_BS"] = {}
        self.animlist["hit_high_BS"][20] = {{["name"] = "end"}}
    end
end

function AnimReplacer:registerSpineEventHandler(callback, event)
    if event then
        self.callback[event] = callback
    end
end

function AnimReplacer:setAnimation(index, name, isloop)
    self.isloop = isloop
    self.curPlayAnimName = name
    self.curPlayAnimFrame = 0
    self.isAnimComplete = false

    if self.animlist[name] then 
        self:handleAnimEvent(0)
    else
        self.isAnimComplete = true
        self.isloop = false
    end
end

function AnimReplacer:handleAnimEvent(frame)
    if self.animlist[self.curPlayAnimName] then
        local events = self.animlist[self.curPlayAnimName][frame]
        if events and self.callback then 
            for _, event in ipairs(events) do
                if event.name ~= "end" then 
                    if self.callback[cc.SP_ANIMATION_EVENT] then
                        local temp = {
                            name = event.name,
                            stringValue = "",
                            intValue = event.intValue or 0,
                            floatValue = event.floatValue or 0,
                            frame = self.curPlayAnimFrame,
                        }
                        self.callback[cc.SP_ANIMATION_EVENT](temp)
                    end
                else
                    if self.callback[cc.SP_ANIMATION_COMPLETE] then
                        local temp = {
                            name = event.name,
                            stringValue = "",
                            intValue = event.intValue or 0,
                            floatValue = event.floatValue or 0,
                            frame = self.curPlayAnimFrame,
                        }
                        self.callback[cc.SP_ANIMATION_COMPLETE](temp)
                    end
                    self.isAnimComplete = true
                end
            end
        end
    end
end

function AnimReplacer:findNextKeyFrame(start)
    if self.animlist[self.curPlayAnimName] then
        local min = 99999
        for k, v in pairs(self.animlist[self.curPlayAnimName]) do
            if k < min and k > start then
                min = k
            end
        end

        return min
    end
end

function AnimReplacer:update()
    if not self.isloop then
        self.curPlayAnimFrame = self:findNextKeyFrame(self.curPlayAnimFrame)
        self:handleAnimEvent(self.curPlayAnimFrame)
    elseif self.isloop and self.animlist[self.curPlayAnimName] then 
        self.curPlayAnimFrame = self:findNextKeyFrame(self.curPlayAnimFrame)
        self:handleAnimEvent(self.curPlayAnimFrame)
        if self.isAnimComplete then 
            self.curPlayAnimFrame = 0
            self.isAnimComplete = false
        end
    end
end

function AnimReplacer:setFrameTime(time)
    self.curPlayAnimFrame = time
end

function AnimReplacer:getFrameTime()
    return self.curPlayAnimFrame
end

function AnimReplacer:getAnimationName()
    return self.curPlayAnimName
end

function AnimReplacer:getBonePosition(boneName)
    if self.bonePointList[boneName] then
        local signMark = self.flipX and -1 or 1
        return {x = self.bonePointList[boneName].x * self.localscale * signMark, y = self.bonePointList[boneName].y * self.localscale}
    end
end

function AnimReplacer:isComplete()
    return self.isAnimComplete
end

function AnimReplacer:setFlipX(flipX)
    self.flipX = flipX
end

function AnimReplacer:isFlipX()
	return self.flipX
end

function AnimReplacer:setPosition(pos)
	self.pos = pos
end

function AnimReplacer:getPosition()
    return self.pos
end

function AnimReplacer:setRotation(rotation)
    self.rotation = rotation
end

function AnimReplacer:getRotation()
    return self.rotation
end

function AnimReplacer:setTag(tag)
    self.tag = tag
end

function AnimReplacer:getTag()
    return self.tag
end

function AnimReplacer:setScale(scale)
    self.localscale = scale
end

function AnimReplacer:setVisible(visible)
end

function AnimReplacer:clearTracks()
end

return AnimReplacer