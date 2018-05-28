
local _MyRandom = class("_MyRandom")

function _MyRandom:ctor()
    self.seed = 0
    self.A = 16807
    self.M = 2^31 - 1
end

function _MyRandom:randomseed(userSeed) --期望传入整形
    --print("_MyRandom",userSeed)
    self.seed = userSeed
    self:random()
    self:random()
    self:random()
    self:random()
end

function _MyRandom:newrandomseed()
    local ok, socket = pcall(function()
        return require("socket")
    end)

    if ok then
        -- 如果集成了 socket 模块，则使用 socket.gettime() 获取随机数种子
        self:randomseed(socket.gettime() * 1000)
    else
        self:randomseed(os.time())
    end
end

function _MyRandom:random(starts, ends) --期望传入整形
    self.seed = math.floor((self.seed * self.A) % self.M + 0.5)
    -- fprint("_MyRandom:random( self.seed ", self.seed)
    -- fprint("_MyRandom:random( starts ", starts)
    -- fprint("_MyRandom:random( ends ", ends)
    --local re
    if starts then 
        if ends then
            return math.floor(self.seed / self.M * (ends - starts + 1)) + starts 
            -- fprint("_MyRandom:random( rand ends ", re)
            -- return re
        else
            return math.floor(self.seed /self.M  * starts) + 1
            -- fprint("_MyRandom:random( rand starts ", re)
            -- return re
        end
    else
        return self.seed / self.M
        -- fprint("_MyRandom:random( rand", re)
        -- return re
    end
end

return _MyRandom
