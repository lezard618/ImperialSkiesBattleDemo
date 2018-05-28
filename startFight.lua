
local serverUsed = true
DEBUG = 1

--local logFile

function fprint(...)
    if serverUsed then
        -- if logFile then
        --     local time = os.time()
        --     local st = os.date("%c", time)
        --     local temp = ""--"[fightLog : " .. st .. "]"
        --     local args = {...}
        --     for k,v in ipairs(args) do
        --         temp = temp .. v
        --     end
        --     temp = temp .. "\n"
        --     logFile:write(temp)
        -- end
    else
        print(...)
    end
end

function log(tag, fmt, ...)
    local t = {
        "[",
        tostring(tag),
        "] ",
        string.format(tostring(fmt), ...)
    }
    if tag == "ERROR" then
        table.insert(t, debug.traceback("", 2))
    end
    fprint(table.concat(t))
end

function loge(fmt, ...)
    log("ERROR", fmt, ...)
end

function logd(fmt, ...)
    if DEBUG < 3 then return end
    log("DEBUG", fmt, ...)
end

function logi(fmt, ...)
    if DEBUG < 2 then return end
    log("INFO", fmt, ...)
end

function logw(fmt, ...)
    if DEBUG < 1 then return end
    log("WARN", fmt, ...)
end

function __G__TRACKBACK__(msg)
    local arr = {"\n"}

    table.insert(arr, "----------------------------------------")
    table.insert(arr, "LUA ERROR: " .. tostring(msg) .. "\n")
    table.insert(arr, debug.traceback())
    table.insert(arr, "----------------------------------------")

    return table.concat(arr, "\n")
end

local tinsert = table.insert
local srep = string.rep
local next = next
local tconcat = table.concat
function print_r(root)
    --print(debug.traceback())
    local cache = {  [root] = "." }
    local function _dump(t,space,name)
        local temp = {}
        for k,v in pairs(t) do
            local key = tostring(k)
            if cache[v] then
                tinsert(temp,"+" .. key .. " {" .. cache[v].."}")
            elseif type(v) == "table" then
                local new_key = name .. "." .. key
                cache[v] = new_key
                tinsert(temp,"+" .. key .. _dump(v,space .. (next(t,k) and "|" or " " ).. srep(" ",#key),new_key))
            else
                tinsert(temp,"+" .. key .. " [" .. tostring(v).."]")
            end
        end
        return tconcat(temp,"\n"..space)
    end
    fprint("\n------------------------------------------------------------------------\n" 
        .. _dump(root, " ","")
        .. "\n------------------------------------------------------------------------")
end

--[[--

计算表格包含的字段数量

Lua table 的 "#" 操作只对依次排序的数值下标数组有效，table.nums() 则计算 table 中所有不为 nil 的值的个数。

@param table t 要检查的表格

@return integer

]]
function table.nums(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

function class(classname, super)
    local superType = type(super)
    local cls

    if superType ~= "function" and superType ~= "table" then
        superType = nil
        super = nil
    end

    if superType == "function" or (super and super.__ctype == 1) then
        -- inherited from native C++ Object
        cls = {}

        if superType == "table" then
            -- copy fields from super
            for k,v in pairs(super) do cls[k] = v end
            cls.__create = super.__create
            cls.super    = super
        else
            cls.__create = super
            cls.ctor = function() end
        end

        cls.__cname = classname
        cls.__ctype = 1

        function cls.new(...)
            local instance = cls.__create(...)
            -- copy fields from class to native object
            for k,v in pairs(cls) do instance[k] = v end
            instance.class = cls
            instance:ctor(...)
            return instance
        end

    else
        -- inherited from Lua Object
        if super then
            cls = {}
            setmetatable(cls, {__index = super})
            cls.super = super
        else
            cls = {ctor = function() end}
        end

        cls.__cname = classname
        cls.__ctype = 2 -- lua
        cls.__index = cls

        function cls.new(...)
            local instance = setmetatable({}, cls)
            instance.class = cls
            instance:ctor(...)
            return instance
        end
    end

    return cls
end

function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function math.round(value)
    return math.floor(value + 0.5)
end


local fileList = {
--config
["globalConf"] = "calcbattle.config.globalConf",
["heroConf"] = "calcbattle.config.heroConf",
["monsterConf"] = "calcbattle.config.monsterConf",
["buffConf"] = "calcbattle.config.buffConf",
["levelConf"] = "calcbattle.config.levelConf",
["skillConf"] = "calcbattle.config.skillConf",
["starConf"] = "calcbattle.config.starConf",
["enhanceConf"] = "calcbattle.config.enhanceConf",
["botConf"] = "calcbattle.config.botConf",
["equipConf"] = "calcbattle.config.equipConf",
["topEnhanceConf"] = "calcbattle.config.topEnhanceConf",
["botAbilityConf"] = "calcbattle.config.botAbilityConf",
["skillActionTimeConf"] = "calcbattle.config.skillActionTimeConf",

--battle
["AnimationBullet"] = "calcbattle.bullet.AnimationBullet",
["Bullet"] = "calcbattle.bullet.Bullet",
["TrackBullet"] = "calcbattle.bullet.TrackBullet",
["LineBullet"] = "calcbattle.bullet.LineBullet",
["ArrowBullet"] = "calcbattle.bullet.ArrowBullet",

["calc"] = "calcbattle.global.calc",
["MyRandom"] = "calcbattle.global.MyRandom",
["json"] = "calcbattle.global.json",
["Type"] = "calcbattle.global.Type",
["FightLayer"] = "calcbattle.layer.FightLayer",
["LevelHandler"] = "calcbattle.level.LevelHandler",

--manager
["CameraManager"] = "calcbattle.manager.CameraManager",
["GameManager"] = "calcbattle.manager.GameManager",
["MapManager"] = "calcbattle.manager.MapManager",

--unit
["Archer"] = "calcbattle.unit.Archer",
["Cavalry"] = "calcbattle.unit.Cavalry",
["Gunner"] = "calcbattle.unit.Gunner",
["Infantry"] = "calcbattle.unit.Infantry",
["Summon"] = "calcbattle.unit.Summon",
["Replace"] = "calcbattle.unit.Replace",
["Unit"] = "calcbattle.unit.Unit",
["Boss"] = "calcbattle.unit.Boss",
["Boss2"] = "calcbattle.unit.Boss2",
["Monroe"] = "calcbattle.unit.Monroe",
["UnitFactory"] = "calcbattle.unit.UnitFactory",
["UnitSkill"] = "calcbattle.unit.UnitSkill",

--equip
["Equip"] = "calcbattle.equip.Equip",
["SoldierEquip"] = "calcbattle.equip.SoldierEquip",
["EquipFactory"] = "calcbattle.equip.EquipFactory",

["Cocos2d"] = "calcbattle.Cocos2d",
["AttributeCalculator"] = "calcbattle.AttributeCalculator",
["FightData"] = "calcbattle.FightData",
["AnimReplacer"] = "calcbattle.AnimReplacer",
}

local configList = {}

function OpenServerConfig(filename)
    local config = configList[filename]
    if not config then
        config = require (fileList[filename])
        configList[filename] = config
    end

    return config
end

function OpenServerFile(filename)
    local file = require (fileList[filename])
    return file
end

clientData = nil
fightResult = nil
attributeTable = nil --{}
arrayTable = nil --{{}, {}, {}}
arrayRecord = nil --{{}, {}}
roundTable = nil --{"{}", "{}", "{}", "{}", "{}"}
roundRecord = nil --{}
dataRecord = nil --{{}, {}}
maxFrame = 0
globalTicks = 1 / 30
globalInfantryTemp = globalTicks * 30 * 8

--输入   lua格式
-- alldata = {
--     leftTeam = {
--         [1] = {
--             userid = xxxx,
--             username = xxx,
--             userhead = xxx,
--             teamtype = 0, -- 1自己的防御部队，2己方的协防部队，3进攻部队
--             team = {
--                 infantry = {{id = 3100001, count = 10}, {id = 3100002, count = 13}},
--                 gunner = {{id = 3100301, count = 25}},
--                 archer = {{id = 3100201, count = 25}},
--                 cavalry = {{id = 3100101, count = 25}},
--                 heros = {
--                     {heroID = 3000004, uniqueID = 11000000, level = 31, strength = 1, skills = {}, enhance = 1, talent = {step=1,index=1}}, 
--                     {heroID = 3000010, uniqueID = 11000001, level = 31, strength = 1, skills = {}, enhance = 1, talent = {step=1,index=1}}
--                 },
--                 boss = {
--                     {bossID = 1111111, damage = 100} -- 总伤害
--                 },
--             },
--             equip = {
--                 {id = 3200001, level = 1, buff = {}}
--             },
--             buffList = {1001, 1002},
--         },
--     },
--     rightTeam = {
--         [1] = {
--             userid = xxxx,
--             username = xxx,
--             userhead = xxx,
--             teamtype = 0, -- 1自己的防御部队，2己方的协防部队，3进攻部队
--             team = {
--                 infantry = {{id = 3100001, count = 10}, {id = 3100002, count = 13}},
--                 gunner = {{id = 3100301, count = 25}},
--                 archer = {{id = 3100201, count = 25}},
--                 cavalry = {{id = 3100101, count = 25}},
--                 heros = {
--                     {heroID = 3000004, uniqueID = 11000000, level = 31, strength = 1, skills = {}, enhance = 1, talent = {step=1,index=1}}, 
--                     {heroID = 3000010, uniqueID = 11000001, level = 31, strength = 1, skills = {}, enhance = 1, talent = {step=1,index=1}}
--                 },
--                 boss = {
--                     {bossID = 1111111, damage = 100} -- 总伤害
--                 },
--             },
--             equip = {
--                 {id = 3200001, level = 1, buff = {}}
--             },
--             buffList = {1001, 1002},
--         },
--     },
-- }

--输出   json格式
-- fightResult = {
--     leftTeam = {
--         [1] = {
--             userid = xxxx,
--             team = {
--                 infantry = {{id = 3100001, dead = 10}, {id = 3100002, dead = 10}},
--                 gunner = {{id = 3100301, dead = 10}},
--                 archer = {{id = 3100201, dead = 10}},
--                 cavalry = {{id = 3100101, dead = 10}},
--                 heros = {
--                     {uniqueID = 11000000, dead = 1}, 
--                     {uniqueID = 11000001, dead = 0}
--                 },
--                 boss = {
--                     {bossID = 1111111, damage = 100} -- 当前伤害
--                 },
--             },
--         },
--     },
--     rightTeam = {
--         [1] = {
--             userid = xxxx,
--             team = {
--                 infantry = {{id = 3100001, dead = 25}},
--                 gunner = {{id = 3100301, dead = 25}},
--                 archer = {{id = 3100201, dead = 25}},
--                 cavalry = {{id = 3100101, dead = 25}},
--                 heros = {},
--                 boss = {
--                     {bossID = 1111111, damage = 100} -- 当前伤害
--                 },
--             },
--         },
--     },
--     result = {
--         [1] = {
--             left = left.userid, 
--             right = right.userid, 
--             result = true,
--         },
--     },
-- }

function dealWithDeadUnit(result, data, serverData)
    local dead = 0
    for i,v in ipairs(result) do
        for ii,vv in ipairs(data) do
            if v.id == vv.id then
                vv.count = vv.count - v.dead
                if vv.count <= 0 then
                    table.remove(data, ii)
                end
                break
            end
        end

        local isFind = false
        for ii,vv in ipairs(serverData) do
            if v.id == vv.id then
                vv.count = vv.count + v.count
                vv.dead = vv.dead + v.dead
                -- if vv.dead > 25 then
                --     vv.dead = 25
                -- end

                isFind = true
                break
            end
        end

        if not isFind then
            local temp = {id = v.id, dead = v.dead, count = v.count}
            table.insert(serverData, temp)
        end

        dead = dead + v.dead
    end

    return dead
end

function dealWithDeadHero(result, data, serverData)
    local dead = 0
    for i,v in ipairs(result) do
        for ii,vv in ipairs(data) do
            if v.uniqueID == vv.uniqueID and v.dead == 1 then
                table.remove(data, ii)
                break
            end
        end

        local isFind = false
        for ii,vv in ipairs(serverData) do
            if v.uniqueID == vv.uniqueID then
                if vv.dead == 0 then
                    vv.dead = v.dead
                end
                isFind = true
                break
            end
        end

        if not isFind then
            local temp = {uniqueID = v.uniqueID, dead = v.dead}
            table.insert(serverData, temp)
        end

        if v.dead > 0 then
            dead = dead + 1
        end
    end

    return dead
end

function dealWithBoss(result, data, serverData)
    local dead = 0
    for i,v in ipairs(result) do
        for ii,vv in ipairs(data) do
            if v.bossID == vv.bossID then
                vv.damage = v.damage + vv.damage
                break
            end
        end

        local isFind = false
        for ii,vv in ipairs(serverData) do
            if v.uniqueID == vv.uniqueID then
                vv.damage = v.damage + vv.damage
                isFind = true
                break
            end
        end

        if not isFind then
            table.insert(serverData, clone(v))
        end

        if v.dead > 0 then
            dead = dead + 1
        end
    end

    return dead
end

--team.param
-- TeamType = 1,       --队伍类型
-- StatueBuff = 2,     --是否享受遗迹buff，0享受，1不享受
-- MaxHeroNum = 3,     --最大上阵英雄数量
function dealStatueBuff(team)
    if not team.param then
        team.param = {}
    end

    if team.param[ExtraParamType.StatueBuff] then
        local text = team.param[ExtraParamType.StatueBuff]
        local temp = {}
        while text and string.len(text) > 0 do
            local x = string.sub(text, 1, 1)
            local y = 0
            if x == "1" then
                y = 1
            end
            table.insert(temp, y)
            text = string.sub(text, 2)
        end

        team.param[ExtraParamType.StatueBuff] = temp
    else
        team.param[ExtraParamType.StatueBuff] = {}
    end
end

-- elseif take == TakeEffectType.DeffenceTeam and FightData:getTeamType(self.faction) == "1" then 防御部队
-- elseif take == TakeEffectType.HelpeDeffence and FightData:getTeamType(self.faction) == "2" then 协助驻防部队
-- elseif take == TakeEffectType.AttackTeam and FightData:getTeamType(self.faction) == "3" then 出征攻击其他城堡部队（单独）
-- elseif take == TakeEffectType.AttackGroup and FightData:getTeamType(self.faction) == "4" then 集火攻击其他城堡部队
-- elseif take == TakeEffectType.MonsterAttack and FightData:getTeamType(self.faction) == "5" then 攻打野怪的部队
-- elseif take == TakeEffectType.BossAttack and FightData:getTeamType(self.faction) == "6" then 集火野外BOSS的部队
-- elseif take == TakeEffectType.AttackBomb and FightData:getTeamType(self.faction) == "7" then 攻击或者占领“粒子巨炮”的部队
-- elseif take == TakeEffectType.AttackCave and FightData:getTeamType(self.faction) == "8" then 攻击或者占领“巨龙洞穴”的部队
-- elseif take == TakeEffectType.AttackMilitary and FightData:getTeamType(self.faction) == "9" then 攻击或者占领“军事要塞”的部队
-- elseif take == TakeEffectType.AttackSource and FightData:getTeamType(self.faction) == "10" then 攻击或者占领“能源核心”的部队
function isAttackCastle()
    local result = false
    if alldata then
        for i,v in ipairs(alldata.rightTeam) do
            if v.param[ExtraParamType.TeamType] == "1" then
                result = true
                break
            end
        end
    end

    return result
end

function dealDefenceTeam(defenceTeam)
    local heroConf = OpenServerConfig("heroConf")
    local temp = clone(defenceTeam)
    local maxHeros = temp.param[ExtraParamType.MaxHeroNum] and tonumber(temp.param[ExtraParamType.MaxHeroNum]) or 10
    local heroList = {[1] = {}, [2] = {}, [3] = {}, [4] = {}}
    
    table.sort(temp.team.heros, function (a, b)
        local aInfo = heroConf[a.heroID]
        local bInfo = heroConf[b.heroID]
        local apoint = (aInfo and aInfo.quality or 1) + (a.level or 1) + (a.strength or 0) + (a.star or 0) + #(a.skills or {})
        local bpoint = (bInfo and bInfo.quality or 1) + (b.level or 1) + (b.strength or 0) + (b.star or 0) + #(b.skills or {})
        return apoint > bpoint
    end)

    for k,v in pairs(temp.team.heros) do
        if (#heroList[1] + #heroList[2] + #heroList[3] + #heroList[4]) >= maxHeros then
            break
        end

        local heroInfo = heroConf[v.heroID]
        if heroInfo then
            if #heroList[heroInfo.class] < 5 then
                table.insert(heroList[heroInfo.class], v)
            end
        end
    end

    temp.team.heros = {}
    for i,v in ipairs(heroList) do
        for ii,vv in ipairs(v) do
            table.insert(temp.team.heros, vv)
        end
    end

    local item = {["infantry"] = #heroList[1], ["gunner"] = #heroList[2], ["archer"] = #heroList[3], ["cavalry"] = #heroList[4]}
    for k,v in pairs(item) do
        local max = 25 - v
        local count = 0
        for ii, vv in ipairs(temp.team[k]) do
            if (count + vv.count) > max then
                vv.count = max - count
            else
                count = count + vv.count
            end
        end
    end

    return temp
end

function enterGame()
    local tempClientData = {} --每场战斗的回放数据
    local tempResult = {
        leftTeam = {},  --左边所有队伍的战斗结算数据，包含击杀数量和boss伤害
        rightTeam = {},  --右边所有队伍的战斗结算数据，包含击杀数量和boss伤害
        result = {}  --每场战斗的结果
    }
    print_r(alldata)

    for i, team in ipairs(alldata.leftTeam) do
        team.index = i
        dealStatueBuff(team)
    end

    for i, team in ipairs(alldata.rightTeam) do
        team.index = i
        dealStatueBuff(team)
    end

    local index = 1
    local isCastleFight = isAttackCastle()
    while #alldata.leftTeam > 0 and #alldata.rightTeam > 0 do

        allStartTime = os.time()
        attributeTable = {}
        arrayTable = {{}, {}, {}} --每一LevelState中一个兵种的战斗记录，分战斗准备阶段和执行阶段,{{unit},{bullet},{camera}}
        arrayRecord = {{}, {}} --每一个LevelState中的阵型记录，第三个字段代表当前LevelState的最大帧数,例如：{{LevelStateType.GUNNER_START的阵型},{LevelStateType.GUNNER_FIGHT的阵型},最大帧数}
        roundTable = {} --每一个LevelState的战斗记录
        roundRecord = {} -- 所有回合的战斗记录
        dataRecord = {{totalHeroDamage = 0, totalSoldierDamage = 0, totalHeal = 0, totalHurt = 0, damageList = {}}, --客户端显示战斗记录，伤害统计
                    {totalHeroDamage = 0, totalSoldierDamage = 0, totalHeal = 0, totalHurt = 0, damageList = {}}}

        local left = alldata.leftTeam[1]
        local right = alldata.rightTeam[1]
        local tempData = {
            leftTeam = left,
            rightTeam = right,
        }

        --如果被打的是城防的防守队伍，则需要拼接部队
        if right.param[ExtraParamType.TeamType] == "1" then
            tempData.rightTeam = dealDefenceTeam(right)
        end

        FightData:init(tempData)
        local data, result = GameManager:startGame()

        --如果被打的是城防的防守队伍，则需要每次都移除左边的部队
        if right.param[ExtraParamType.TeamType] == "1" then
            table.remove(alldata.leftTeam, 1)
        else
            if result.result then
                table.remove(alldata.rightTeam, 1)
            else
                table.remove(alldata.leftTeam, 1)
            end
        end

        local leftIndex
        local leftServerData
        if not isCastleFight then
            for i,v in ipairs(tempResult.leftTeam) do
                if v.userid == left.userid then
                    leftServerData = v
                    leftIndex = i
                    break
                end
            end
        end

        if not leftServerData then
            leftServerData = {
                userid = left.userid,
                team = {
                    infantry = {},
                    gunner = {},
                    archer = {},
                    cavalry = {},
                    heros = {},
                    boss = {},
                },
            }
        end

        local rightIndex
        local rightServerData
        if not isCastleFight then
            for i,v in ipairs(tempResult.rightTeam) do
                if v.userid == right.userid then
                    rightServerData = v
                    rightIndex = i
                    break
                end
            end
        end

        if not rightServerData then
            rightServerData = {
                userid = right.userid,
                team = {
                    infantry = {},
                    gunner = {},
                    archer = {},
                    cavalry = {},
                    heros = {},
                    boss = {},
                },
            }
        end

        local leftTotalDead = 0
        local rightTotalDead = 0
        local leftHeroDead = 0
        local rightHeroDead = 0
        local leftBossDead = 0
        local rightBossDead = 0

        leftTotalDead = leftTotalDead + dealWithDeadUnit(result.leftTeam.infantry, left.team.infantry, leftServerData.team.infantry)
        leftTotalDead = leftTotalDead + dealWithDeadUnit(result.leftTeam.gunner, left.team.gunner, leftServerData.team.gunner)
        leftTotalDead = leftTotalDead + dealWithDeadUnit(result.leftTeam.archer, left.team.archer, leftServerData.team.archer)
        leftTotalDead = leftTotalDead + dealWithDeadUnit(result.leftTeam.cavalry, left.team.cavalry, leftServerData.team.cavalry)
        leftHeroDead = dealWithDeadHero(result.leftTeam.heros, left.team.heros, leftServerData.team.heros)
        leftBossDead = result.leftTeam.boss and dealWithBoss(result.leftTeam.boss, left.team.boss, leftServerData.team.boss) or 0
        leftTotalDead = leftTotalDead + leftHeroDead + leftBossDead

        rightTotalDead = rightTotalDead + dealWithDeadUnit(result.rightTeam.infantry, right.team.infantry, rightServerData.team.infantry)
        rightTotalDead = rightTotalDead + dealWithDeadUnit(result.rightTeam.gunner, right.team.gunner, rightServerData.team.gunner)
        rightTotalDead = rightTotalDead + dealWithDeadUnit(result.rightTeam.archer, right.team.archer, rightServerData.team.archer)
        rightTotalDead = rightTotalDead + dealWithDeadUnit(result.rightTeam.cavalry, right.team.cavalry, rightServerData.team.cavalry)
        rightHeroDead = dealWithDeadHero(result.rightTeam.heros, right.team.heros, rightServerData.team.heros)
        rightBossDead = result.rightTeam.boss and dealWithBoss(result.rightTeam.boss, right.team.boss, rightServerData.team.boss) or 0
        rightTotalDead = rightTotalDead + rightHeroDead + rightBossDead

        leftServerData.damage = math.ceil(result.leftTeam.bossdamage or 0)
        rightServerData.damage = math.ceil(result.rightTeam.bossdamage or 0)
        leftServerData.killed = (leftServerData.killed or 0) + rightTotalDead
        rightServerData.killed = (rightServerData.killed or 0) + leftTotalDead
        leftServerData.killedHero = (leftServerData.killedHero or 0) + rightHeroDead
        rightServerData.killedHero = (rightServerData.killedHero or 0) + leftHeroDead

        local curResultData = {left = left.userid, right = right.userid, result = result.result, token = os.time() .. MyRandom:random(1000000, 9999999) .. index}
        if leftIndex then
            tempResult.leftTeam[leftIndex] = leftServerData
        else
            table.insert(tempResult.leftTeam, leftServerData)
        end

        if rightIndex then
            tempResult.rightTeam[rightIndex] = rightServerData
        else
            table.insert(tempResult.rightTeam, rightServerData)
        end

        table.insert(tempResult.result, curResultData)
        tempClientData[left.userid .. "-" .. right.userid .. "-" .. curResultData.token] = data
        index = index + 1
    end

    for i, team in ipairs(alldata.leftTeam) do
        local isFind = false
        for ii, v in ipairs(tempResult.leftTeam) do
            if team.userid == v.userid then
                isFind = true
                break
            end
        end

        if not isFind then
            table.insert(tempResult.leftTeam, {userid = team.userid, killed = 0})
        end
    end

    for i, team in ipairs(alldata.rightTeam) do
        local isFind = false
        for ii, v in ipairs(tempResult.rightTeam) do
            if team.userid == v.userid then
                isFind = true
                break
            end
        end

        if not isFind then
            table.insert(tempResult.rightTeam, {userid = team.userid, killed = 0})
        end
    end

    clientData = tempClientData
    fightResult = tempResult
    output = json.encode({clientData = clientData, fightResult = fightResult})

    alldata = nil

    collectgarbage("collect") --lua垃圾回收机制， 执行一次全垃圾收集循环
end

function StartBattle()
    -- if not logFile then
    --     logFile = io.open("fightLog.txt", "a+")
    -- end

    clientData = nil
    fightResult = nil
    output = nil

    OpenServerFile("Cocos2d")
    OpenServerFile("json")
    OpenServerFile("Type")

    calc = OpenServerFile("calc")
    FightData = OpenServerFile("FightData").new()
    MyRandom = OpenServerFile("MyRandom").new()
    GameManager = OpenServerFile("GameManager").new()
    MapManager = OpenServerFile("MapManager").new()
    CameraManager = OpenServerFile("CameraManager").new()
    AttributeCalculator = OpenServerFile("AttributeCalculator").new()

    --print("file == ", file)
    -- body
    local status, msg = xpcall(enterGame, __G__TRACKBACK__)
    if not status then
        error(msg .. FightData:getRandomSeed())
    end

    -- if logFile then
    --     io.close(logFile)
    --     logFile = nil
    -- end
end
