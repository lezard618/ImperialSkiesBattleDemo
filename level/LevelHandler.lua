

local OpenServerConfig = OpenServerConfig
local OpenServerFile = OpenServerFile
local UnitFactory = OpenServerFile("UnitFactory")
local EquipFactory = OpenServerFile("EquipFactory")
local TrackBullet = OpenServerFile("TrackBullet")
local heroConf = OpenServerConfig("heroConf")
local botConf = OpenServerConfig("botConf")
local monsterConf = OpenServerConfig("monsterConf")
local globalConf = OpenServerConfig("globalConf")

local LevelHandler = class("LevelHandler")

function LevelHandler:ctor()
    self.curState = LevelStateType.INIT
    self.nextState = nil
    self.curRound = 0
    self.ticks = 0
    self.isBossFight = false

    self.curFrame = 0
    self.infantryFightTime = 0
end

function LevelHandler.create()
    local handler = LevelHandler.new()
    return handler
end

function LevelHandler:onGameInit()
    self:createLeft()
    self:createRight()
    self:initAttribute()
end

function LevelHandler:initAttribute()
    local units = MapManager:getUnitMap()
    for k, unit in pairs(units) do
        unit:activeAura()
    end

    for k, unit in pairs(units) do
        unit:initAttribute()
    end
    
    for k, unit in pairs(units) do
        unit:initBaseBuff()
    end

    for k, unit in pairs(units) do
        unit:saveBaseAttr()
    end

    local equipList = MapManager:getEquips(UnitFaction.LEFT)
    local unitList = MapManager:getAllUnit(UnitFaction.LEFT)
    for i,v in ipairs(equipList) do
        local equipBuff = v:getUnitBuff()
        for k, buff in pairs(equipBuff) do
            for ii,unit in ipairs(unitList) do
                unit:addBuff(buff, nil, false, 0, LevelStateType.END_ROUND)
            end
        end
    end

    local equipList = MapManager:getEquips(UnitFaction.RIGHT)
    local unitList = MapManager:getAllUnit(UnitFaction.RIGHT)
    for i,v in ipairs(equipList) do
        local equipBuff = v:getUnitBuff()
        for k, buff in pairs(equipBuff) do
            for ii,unit in ipairs(unitList) do
                unit:addBuff(buff, nil, false, 0, LevelStateType.END_ROUND)
            end
        end
    end

    for k, unit in pairs(units) do
        unit:skillBuff()
    end
end

function LevelHandler:onGameStart()

end

function LevelHandler:onGameEnd()

end

function LevelHandler:setNextState(state)
    if (not self.nextState) or self.nextState ~= state then
        self.nextState = state
    end
end

function LevelHandler:doChangeState()
    if self.nextState == LevelStateType.SHOW then
        self:preShow()
    elseif self.nextState == LevelStateType.START_ROUND then
        self:preStartRound()
    elseif self.nextState == LevelStateType.GUNNER_START then
        self:preStartGunner()
    elseif self.nextState == LevelStateType.BOSS_START_AFTER_GUNNER or self.nextState == LevelStateType.BOSS_START_AFTER_ARCHER then
        self:preStartBoss()
    elseif self.nextState == LevelStateType.ARCHER_START then
        self:preStartArcher()
    elseif self.nextState == LevelStateType.BOSS_FIGHT_AFTER_GUNNER or self.nextState == LevelStateType.BOSS_FIGHT_AFTER_ARCHER then
        self:preBossFight()
    elseif self.nextState == LevelStateType.INFANTRY_START then
        self:preStartInfantry()
    elseif self.nextState == LevelStateType.CAVALRY_START then
        self:preStartCavalry()
    elseif self.nextState == LevelStateType.GUNNER_FIGHT then
        self:preGunnerFight()
    elseif self.nextState == LevelStateType.ARCHER_FIGHT then
        self:preArcherFight()
    elseif self.nextState == LevelStateType.INFANTRY_FIGHT then
        self:preInfantryFight()
    elseif self.nextState == LevelStateType.CAVALRY_FIGHT then
        self:preCavalryFight()
    end 

    self.curState = self.nextState
    self.nextState = nil
    self:updateActiveBuff(self.curState)
end

function LevelHandler:preShow()
    arrayRecord[1] = arrayTable
    arrayRecord[3] = maxFrame
    maxFrame = 0
    arrayTable = {{}, {}, {}}
    roundTable[LevelStateType.SHOW] = json.encode(arrayRecord)
    arrayRecord = {{}, {}}
end

function LevelHandler:preStartRound()
end

function LevelHandler:preStartGunner()
end

function LevelHandler:preStartArcher()
end

function LevelHandler:preStartInfantry()
end

function LevelHandler:preStartCavalry()
end

function LevelHandler:preStartBoss()
end

function LevelHandler:preGunnerFight()
    self:startGuard()
    self.curFrame = 0
    self:startFight(UnitType.GUNNER, self.curFrame)
end

function LevelHandler:preArcherFight()
    self:startGuard()
    self.curFrame = 0
    self:startFight(UnitType.ARCHER, self.curFrame)
end

function LevelHandler:preInfantryFight()
    self:startGuard()
    self.curFrame = 0
    self:resetFightBack()
    self:startFight(UnitType.INFANTRY, self.curFrame)

    self.baseLen = nil
    local unitList = MapManager:getUnitByType(UnitFaction.LEFT, UnitType.INFANTRY)
    for i, unit in ipairs(unitList) do
        unit:calcSpeedFact()
    end

    self.baseLen = nil
    unitList = MapManager:getUnitByType(UnitFaction.RIGHT, UnitType.INFANTRY)
    for i, unit in ipairs(unitList) do
        unit:calcSpeedFact()
    end
end

function LevelHandler:preCavalryFight()
    self:startGuard()
    self.curFrame = 0
    self.cavalryIndex = 1
    self:resetFightBack()
    self:startFight(UnitType.CAVALRY, self.curFrame)

    -- speed
    self.baseLen = nil
    local leftCavalry = MapManager:getUnitByType(UnitFaction.LEFT, UnitType.CAVALRY)
    for i, unit in ipairs(leftCavalry) do
        unit:calcSpeedFact()
    end

    self.baseLen = nil
    local rightCavalry = MapManager:getUnitByType(UnitFaction.RIGHT, UnitType.CAVALRY)
    for i, unit in ipairs(rightCavalry) do
        unit:calcSpeedFact()
    end

    -- calc fight
    for _, unit in ipairs(leftCavalry) do
        unit:calcFight()
    end

    for _, unit in ipairs(rightCavalry) do
        unit:calcFight()
    end

end

function LevelHandler:canFightBack(faction, utype, lineindex)
    if self.curState == LevelStateType.INFANTRY_FIGHT or self.curState == LevelStateType.CAVALRY_FIGHT then
        if table.nums(self.fightBack[faction]) <= 0 then
            return true
        elseif self.fightBack[faction][utype] and not self.fightBack[faction][utype][lineindex] then
            return true
        end
    end

    return false
end

function LevelHandler:resetFightBack()
    self.fightBack = {[UnitFaction.LEFT] = {}, [UnitFaction.RIGHT] = {}}
end

function LevelHandler:setFightBack(faction, utype, lineindex)
    if not self.fightBack[faction][utype] then
        self.fightBack[faction][utype] = {}
    end
    self.fightBack[faction][utype][lineindex] = true
end

function LevelHandler:preBossFight()
    self:startGuard()
    self.curFrame = 0
    self:startFight(UnitType.BOSS, self.curFrame)
end

function LevelHandler:onGameUpdate(ticks)
    self.ticks = ticks
    if self.curState == LevelStateType.INIT then
        self:doInit()
    elseif self.curState == LevelStateType.SHOW then
        self:doShow(ticks)
    elseif self.curState == LevelStateType.START_ROUND then
        self:doStartRound()
    elseif self.curState == LevelStateType.GUNNER_START then
        self:doStartGunner()
    elseif self.curState == LevelStateType.GUNNER_FIGHT then
        self:doGunnerFight()
    elseif self.curState == LevelStateType.ARCHER_START then
        self:doStartArcher()
    elseif self.curState == LevelStateType.ARCHER_FIGHT then
        self:doArcherFight()
    elseif self.curState == LevelStateType.INFANTRY_START then
        self:doStartInfantry()
    elseif self.curState == LevelStateType.INFANTRY_FIGHT then
        self:doInfantryFight()
    elseif self.curState == LevelStateType.CAVALRY_START then
        self:doStartCavalry()
    elseif self.curState == LevelStateType.CAVALRY_FIGHT then
        self:doCavalryFight()
    elseif self.curState == LevelStateType.BOSS_START_AFTER_GUNNER or self.curState == LevelStateType.BOSS_START_AFTER_ARCHER then
        self:doStartBoss()
    elseif self.curState == LevelStateType.BOSS_FIGHT_AFTER_GUNNER or self.curState == LevelStateType.BOSS_FIGHT_AFTER_ARCHER then
        self:doBossFight()
    elseif self.curState == LevelStateType.INTERVAL then
        self:doInterval()
    elseif self.curState == LevelStateType.END_ROUND then
        self:doEndRound()
    end

    if self.nextState then
        self:doChangeState()
    end
end

function LevelHandler:doInit()
    self:setNextState(LevelStateType.SHOW)
end

function LevelHandler:doShow(ticks)
    self:setNextState(LevelStateType.START_ROUND)
end

function LevelHandler:doStartRound()
    self.curRound = self.curRound + 1
    self:restoreLeftArray()
    self:restoreRightArray()
    self:resetAll()
    if self.curRound > 1 then
        self:updateAddRoundBuff()
    end
    self:setNextState(LevelStateType.GUNNER_START)
end

function LevelHandler:doStartGunner()
    local unitListLeft = MapManager:getUnitByType(UnitFaction.LEFT, UnitType.GUNNER)
    local unitListRight = MapManager:getUnitByType(UnitFaction.RIGHT, UnitType.GUNNER)
    if (#unitListLeft + #unitListRight) <= 0 or self:isFinish() then
        roundTable[LevelStateType.GUNNER_START] = "{}"
        self:setNextState(LevelStateType.BOSS_START_AFTER_GUNNER)
        return
    end

    self:useConditionSkill()
    self:startAddSkill(UnitType.GUNNER)
    self:updateDot(UnitType.GUNNER)
    self:restoreLeftArray()
    self:restoreRightArray()
    CameraManager:recordLocation(unitListLeft, unitListRight)
    self:setNextState(LevelStateType.GUNNER_FIGHT)
    -- MapManager:recordAllUnit()
    arrayRecord[1] = arrayTable
    arrayTable = {{}, {}, {}}
end

function LevelHandler:doGunnerFight()
    if (MapManager:isAllFinish() or self:isFinish()) then
        -- MapManager:recordAllUnit()
        -- MapManager:recordAllBullet()
        self:removeLastCountBuff(maxFrame)
        CameraManager:recordRun()
        arrayRecord[2] = arrayTable
        arrayRecord[3] = maxFrame
        maxFrame = 0
        arrayTable = {{}, {}, {}}
        roundTable[LevelStateType.GUNNER_START] = json.encode(arrayRecord)
        arrayRecord = {{}, {}}
        self:resetAll()
        self:setNextState(LevelStateType.BOSS_START_AFTER_GUNNER)
        self:resetHitBuff()
    end

    self.curFrame = self.curFrame + 2
end

function LevelHandler:doStartArcher()
    local unitListLeft = MapManager:getUnitByType(UnitFaction.LEFT, UnitType.ARCHER)
    local unitListRight = MapManager:getUnitByType(UnitFaction.RIGHT, UnitType.ARCHER)
    if (#unitListLeft + #unitListRight) <= 0 or self:isFinish() then
        roundTable[LevelStateType.ARCHER_START] = "{}"
        self:setNextState(LevelStateType.BOSS_START_AFTER_ARCHER)
        return
    end

    self:useConditionSkill()
    self:startAddSkill(UnitType.ARCHER)
    self:updateDot(UnitType.ARCHER)
    self:restoreLeftArray()
    self:restoreRightArray()
    CameraManager:recordLocation(unitListLeft, unitListRight)
    self:setNextState(LevelStateType.ARCHER_FIGHT)
    -- MapManager:recordAllUnit()
    arrayRecord[1] = arrayTable
    arrayTable = {{}, {}, {}}
end

function LevelHandler:doArcherFight()
    if (MapManager:isAllFinish() or self:isFinish()) then
        -- MapManager:recordAllUnit()
        -- MapManager:recordAllBullet()
        self:removeLastCountBuff(maxFrame)
        CameraManager:recordRun()
        arrayRecord[2] = arrayTable
        arrayRecord[3] = maxFrame
        maxFrame = 0
        arrayTable = {{}, {}, {}}
        roundTable[LevelStateType.ARCHER_START] = json.encode(arrayRecord)
        arrayRecord = {{}, {}}
        self:resetAll()
        self:setNextState(LevelStateType.BOSS_START_AFTER_ARCHER)
        self:resetHitBuff()
    end

    self.curFrame = self.curFrame + 2
end

function LevelHandler:doStartInfantry()
    local unitListLeft = MapManager:getUnitByType(UnitFaction.LEFT, UnitType.INFANTRY)
    local unitListRight = MapManager:getUnitByType(UnitFaction.RIGHT, UnitType.INFANTRY)
    if (#unitListLeft + #unitListRight) <= 0 or self:isFinish() then
        roundTable[LevelStateType.INFANTRY_START] = "{}"
        self:setNextState(LevelStateType.CAVALRY_START)
        return
    end

    self:useConditionSkill()
    self:startAddSkill(UnitType.INFANTRY)
    self:updateDot(UnitType.INFANTRY)
    self:restoreLeftArray()
    self:restoreRightArray()
    CameraManager:recordLocation(unitListLeft, unitListRight)
    self:setNextState(LevelStateType.INFANTRY_FIGHT)

    -- MapManager:recordAllUnit()
    arrayRecord[1] = arrayTable
    arrayTable = {{}, {}, {}}
    self.infantryFightTime = globalConf[1].footRound
    self.infantryFightState = nil
end

function LevelHandler:doInfantryFight()
    local unitListLeft = MapManager:getUnitByType(UnitFaction.LEFT, UnitType.INFANTRY)
    local unitListRight = MapManager:getUnitByType(UnitFaction.RIGHT, UnitType.INFANTRY)
    local allInfantryState = {0, 0, 0, 0, 0}
    for i, unit in ipairs(unitListLeft) do
        allInfantryState[unit:attackState()] = allInfantryState[unit:attackState()] + 1
    end

    for i, unit in ipairs(unitListRight) do
        allInfantryState[unit:attackState()] = allInfantryState[unit:attackState()] + 1
    end

    if allInfantryState[UnitFightState.WaitForFight] > 0 and allInfantryState[UnitFightState.WaitForFight] + allInfantryState[UnitFightState.NoTarget] == #unitListLeft + #unitListRight then
        self.infantryFightState = "doFight" -- 步兵正在攻击
        for i, unit in ipairs(unitListLeft) do
            unit:setFrame(maxFrame)
            unit:doFight()
        end

        for i, unit in ipairs(unitListRight) do
            unit:setFrame(maxFrame)
            unit:doFight()
        end
    elseif allInfantryState[UnitFightState.FinishFight] + allInfantryState[UnitFightState.NoTarget] == #unitListLeft + #unitListRight then
        self.infantryFightTime = self.infantryFightTime - 1
        self.infantryFightState = "startFight" -- 步兵正在前进或搜索敌人
        if self.infantryFightTime > 0 then
            maxFrame = maxFrame + globalInfantryTemp
            self:startFight(UnitType.INFANTRY, maxFrame, true)
        end
    end

    -- MapManager:recordAllBullet()
    if (MapManager:isAllFinish() or self:isFinish()) then
        -- MapManager:recordAllUnit()
        self:removeLastCountBuff(maxFrame)
        self.infantryFightTime = 0
        self.infantryFightState = nil
        arrayRecord[2] = arrayTable
        arrayRecord[3] = maxFrame
        maxFrame = 0
        arrayTable = {{}, {}, {}}
        roundTable[LevelStateType.INFANTRY_START] = json.encode(arrayRecord)
        arrayRecord = {{}, {}}
        self:resetAll()
        self:setNextState(LevelStateType.CAVALRY_START)
        self:resetHitBuff()
    end
end

function LevelHandler:doStartCavalry()
    local unitListLeft = MapManager:getUnitByType(UnitFaction.LEFT, UnitType.CAVALRY)
    local unitListRight = MapManager:getUnitByType(UnitFaction.RIGHT, UnitType.CAVALRY)
    if (#unitListLeft + #unitListRight) <= 0 or self:isFinish() then
        roundTable[LevelStateType.CAVALRY_START] = "{}"
        self:setNextState(LevelStateType.END_ROUND)
        return
    end

    self:useConditionSkill()
    self:startAddSkill(UnitType.CAVALRY)
    self:updateDot(UnitType.CAVALRY)
    self:restoreLeftArray()
    self:restoreRightArray()
    CameraManager:recordLocation(unitListLeft, unitListRight)
    self:setNextState(LevelStateType.CAVALRY_FIGHT)
    -- MapManager:recordAllUnit()
    arrayRecord[1] = arrayTable
    arrayTable = {{}, {}, {}}
end

function LevelHandler:doStartBoss()
    local unitListLeft = MapManager:getUnitByType(UnitFaction.LEFT, UnitType.BOSS)
    local unitListRight = MapManager:getUnitByType(UnitFaction.RIGHT, UnitType.BOSS)
    if (#unitListLeft + #unitListRight) <= 0 or self:isFinish() then
        roundTable[self.curState] = "{}"

        if self.curState == LevelStateType.BOSS_START_AFTER_GUNNER then
            self:setNextState(LevelStateType.ARCHER_START)
        elseif self.curState == LevelStateType.BOSS_START_AFTER_ARCHER then
            self:setNextState(LevelStateType.INFANTRY_START)
        end

        return
    end

    if self.curState == LevelStateType.BOSS_START_AFTER_GUNNER and #MapManager:getUnitByType(UnitFaction.LEFT, UnitType.GUNNER) <= 0 then
        roundTable[self.curState] = "{}"
        self:setNextState(LevelStateType.ARCHER_START)
        return
    end

    if self.curState == LevelStateType.BOSS_START_AFTER_ARCHER and #MapManager:getUnitByType(UnitFaction.LEFT, UnitType.ARCHER) <= 0 then
        roundTable[self.curState] = "{}"
        self:setNextState(LevelStateType.INFANTRY_START)
        return
    end

    self:updateDot(UnitType.BOSS)
    self:restoreLeftArray()
    self:restoreRightArray()
    CameraManager:recordLocation(unitListLeft, unitListRight)

    if self.curState == LevelStateType.BOSS_START_AFTER_GUNNER then
        self:setNextState(LevelStateType.BOSS_FIGHT_AFTER_GUNNER)
    elseif self.curState == LevelStateType.BOSS_START_AFTER_ARCHER then
        self:setNextState(LevelStateType.BOSS_FIGHT_AFTER_ARCHER)
    end

    -- MapManager:recordAllUnit()
    arrayRecord[1] = arrayTable
    arrayTable = {{}, {}, {}}
end

function LevelHandler:doCavalryFight()
    local function startCavalryFight(index)
        local unitListLeft = MapManager:getUnitByType(UnitFaction.LEFT, UnitType.CAVALRY)

        for i, unit in ipairs(unitListLeft) do
            unit:doFight(index)
        end

        local unitListRight = MapManager:getUnitByType(UnitFaction.RIGHT, UnitType.CAVALRY)
        for i, unit in ipairs(unitListRight) do
            unit:doFight(index)
        end 
    end

    local function startCavalryBeatBack(index)
        local unitListLeft = MapManager:getUnitByType(UnitFaction.LEFT, UnitType.CAVALRY)

        for i, unit in ipairs(unitListLeft) do
            unit:doBeatBack(index)
        end

        local unitListRight = MapManager:getUnitByType(UnitFaction.RIGHT, UnitType.CAVALRY)
        for i, unit in ipairs(unitListRight) do
            unit:doBeatBack(index)
        end 
    end

    if self.cavalryIndex % 2 == 1 then
        startCavalryBeatBack(math.ceil(self.cavalryIndex / 2))
    else
        startCavalryFight(self.cavalryIndex / 2)
    end

    self.cavalryIndex = self.cavalryIndex + 1

    -- MapManager:recordAllBullet()
    if MapManager:isAllFinish() then
        -- MapManager:recordAllUnit()
        self:removeLastCountBuff(maxFrame)
        CameraManager:recordRun()
        arrayRecord[2] = arrayTable
        arrayRecord[3] = maxFrame
        maxFrame = 0
        arrayTable = {{}, {}, {}}
        roundTable[LevelStateType.CAVALRY_START] = json.encode(arrayRecord)
        arrayRecord = {{}, {}}
        self:setNextState(LevelStateType.END_ROUND)
        self:resetAll()
        self:resetHitBuff()
    end
end

function LevelHandler:doBossFight()
    if MapManager:isAllFinish() then
        CameraManager:recordRun()
        arrayRecord[2] = arrayTable
        arrayRecord[3] = maxFrame
        maxFrame = 0
        arrayTable = {{}, {}, {}}

        if self.curState == LevelStateType.BOSS_FIGHT_AFTER_GUNNER then
            roundTable[LevelStateType.BOSS_START_AFTER_GUNNER] = json.encode(arrayRecord)
        elseif self.curState == LevelStateType.BOSS_FIGHT_AFTER_ARCHER then
            roundTable[LevelStateType.BOSS_START_AFTER_ARCHER] = json.encode(arrayRecord)
        end
        
        arrayRecord = {{}, {}}

        if self.curState == LevelStateType.BOSS_FIGHT_AFTER_GUNNER then
            self:setNextState(LevelStateType.ARCHER_START)
        elseif self.curState == LevelStateType.BOSS_FIGHT_AFTER_ARCHER then
            self:setNextState(LevelStateType.INFANTRY_START)
        end

        self:resetAll()
        self:resetHitBuff()
    end
end

function LevelHandler:doEndRound()
    self:useConditionSkill()
    self:setNextState(LevelStateType.START_ROUND)
    arrayRecord[1] = arrayTable
    arrayRecord[3] = 0
    maxFrame = 0
    arrayTable = {{}, {}, {}}
    roundTable[LevelStateType.END_ROUND] = json.encode(arrayRecord)
    arrayRecord = {{}, {}}
    table.insert(roundRecord, roundTable)
    roundTable = {"{}", "{}", "{}", "{}", "{}", "{}"}
end

function LevelHandler:isFinish()
    return MapManager:getLiveUnitCount(UnitFaction.LEFT) <= 0 or MapManager:getLiveUnitCount(UnitFaction.RIGHT) <= 0
end

function LevelHandler:isGameOver()
    return self.curState == LevelStateType.START_ROUND and (MapManager:getLiveUnitCount(UnitFaction.LEFT) <= 0 or self.curRound >= MaxRound)
end

function LevelHandler:isGameComplete()
    return self.curState == LevelStateType.START_ROUND and MapManager:getLiveUnitCount(UnitFaction.RIGHT) <= 0
end

function LevelHandler:onGameOver()
    return true
end

function LevelHandler:onGameComplete()
    return false
end

function LevelHandler:onTouch(touch, event)
    if self.curState == LevelStateType.SHOW then
        self:setNextState(LevelStateType.START_ROUND)
    end
end

function LevelHandler:useConditionSkill()
    local used
    local units = MapManager:getUnitMap()
    for k, unit in pairs(units) do
        used = unit:useConditionSkill() or used
    end

    units = MapManager:getDeadUnit(UnitFaction.LEFT)
    for i,unit in pairs(units) do
        used = unit:useConditionSkill() or used
    end

    units = MapManager:getDeadUnit(UnitFaction.RIGHT)
    for i,unit in pairs(units) do
        used = unit:useConditionSkill() or used
    end

    self:activeAddSkill()

    if used then
        self:restoreLeftArray()
        self:restoreRightArray()
    end
end

function LevelHandler:startAddSkill(army)
    local unitListLeft = MapManager:getUnitByType(UnitFaction.LEFT, army)
    local unitListRight = MapManager:getUnitByType(UnitFaction.RIGHT, army)
    for k, unit in pairs(unitListLeft) do
        if unit:useAddSkill() then
            self:activeAddSkill()
        end
    end

    for k, unit in pairs(unitListRight) do
        if unit:useAddSkill() then
            self:activeAddSkill()
        end
    end
end

function LevelHandler:activeAddSkill()
    local units = MapManager:getUnitMap()
    for k, unit in pairs(units) do
        unit:skillBuff()
    end

    local index = 1
    units = MapManager:getDeadUnit(UnitFaction.LEFT)
    for i,unit in pairs(units) do
        if unit.setSummonIndex then
            unit:setSummonIndex(index)
            index = index + 1
        end

        unit:skillBuff()
    end

    index = 1
    units = MapManager:getDeadUnit(UnitFaction.RIGHT)
    for i,unit in pairs(units) do
        if unit.setSummonIndex then
            unit:setSummonIndex(index)
            index = index + 1
        end

        unit:skillBuff()
    end
end

function LevelHandler:updateDot(utype)
    local units = MapManager:getUnitByType(UnitFaction.LEFT, utype)
    for k, unit in pairs(units) do
        unit:updateDot()
    end

    units = MapManager:getUnitByType(UnitFaction.RIGHT, utype)
    for k, unit in pairs(units) do
        unit:updateDot()
    end
end

function LevelHandler:updateAddRoundBuff()
    local units = MapManager:getUnitMap()
    for k, unit in pairs(units) do
        unit:updateAddRoundBuff()
        unit:skillBuff()
    end
end

function LevelHandler:updateActiveBuff()
    local units = MapManager:getUnitMap()
    for k, unit in pairs(units) do
        unit:updateActiveBuff(self.curState)
        unit:skillBuff()
    end
end

function LevelHandler:resetHitBuff()
    local units = MapManager:getUnitMap()
    for k, unit in pairs(units) do
        unit:resetHitBuff()
    end
end

function LevelHandler:startGuard()
    local units = MapManager:getUnitMap()
    for k, unit in pairs(units) do
        unit:startGuard()
    end
end

function LevelHandler:removeLastCountBuff(frame)
    local units = MapManager:getUnitMap()
    for k, unit in pairs(units) do
        unit:removeLastCountBuff(frame)
    end
end

function LevelHandler:indexList(list, startLine)
    for i = 1, #list do
        local index = i % MaxUnitInLine

        --每一行的纵坐标转换成从下到上的纵坐标
        if index == 1 then
            index = 3
        elseif index == 2 then
            index = 2
        elseif index == 3 then
            index = 4
        elseif index == 4 then
            index = 1
        elseif index == 0 then
            index = 5
        end

        local hero = list[i]
        hero:setLineLocation(cc.p(startLine + math.floor((i - 1) / MaxUnitInLine), index))
    end

    local lastLine = math.floor(#list / MaxUnitInLine)

    return startLine + lastLine
end

function LevelHandler:startFight(army, frame, notRelist)
    local unitListLeft = MapManager:getUnitByType(UnitFaction.LEFT, army)
    local unitListRight = MapManager:getUnitByType(UnitFaction.RIGHT, army)
    for k, unit in pairs(unitListLeft) do
        unit:startFight(frame)
    end

    for k, unit in pairs(unitListRight) do
        unit:startFight(frame)
    end

    if not notRelist then
        local unitList = MapManager:getUnitList(UnitFaction.LEFT)
        local startLine = 0
        startLine = self:indexList(unitList[UnitType.INFANTRY], startLine)
        startLine = self:indexList(unitList[UnitType.GUNNER], startLine)
        startLine = self:indexList(unitList[UnitType.ARCHER], startLine)
        startLine = self:indexList(unitList[UnitType.CAVALRY], startLine)

        unitList = MapManager:getUnitList(UnitFaction.RIGHT)
        startLine = 0
        startLine = self:indexList(unitList[UnitType.INFANTRY], startLine)
        startLine = self:indexList(unitList[UnitType.GUNNER], startLine)
        startLine = self:indexList(unitList[UnitType.ARCHER], startLine)
        startLine = self:indexList(unitList[UnitType.CAVALRY], startLine)
    end
end

function LevelHandler:resetAll()
    local units = MapManager:getUnitMap()
    for k, unit in pairs(units) do
        unit:startWait(0)
    end
end

function LevelHandler:arrayList(list, faction, adjust, startLocation, frontUnits)
    local posAdjust = adjust or LineAdjust
    local front = frontUnits or {nil, nil, nil, nil, nil}
    local fact = 1
    if faction == UnitFaction.RIGHT then
        fact = -1
    end

    local curLocation = startLocation or 2000
    for i = 1, #list do
        local index = i % MaxUnitInLine
        if i ~= 1 and index == 1 then
            curLocation = curLocation - UnitSpace * fact
        end

        if index == 0 then
            index = 5
        end

        local hero = list[i]
        local pos = cc.p(curLocation + posAdjust[index].x, UnitStartLocationY + posAdjust[index].y)
        hero:setFront(front[index])
        hero:setIndexInMatrix(i)
        hero:setLocation(pos)
        hero.behind = nil
        front[index] = hero
    end

    if #list > 0 then
        curLocation = curLocation - UnitSpace * fact
    end
    
    local lastLine = #list % MaxUnitInLine
    if lastLine == 0 then
        lastLine = 5
    end

    for i,v in ipairs(front) do
        if i > lastLine then
            front[i] = nil
        end
    end

    return curLocation, front
end

function LevelHandler:listMatrix(soldiers, heros, utype, botSoldierId, botHeroId, _isMonster)
    local isMonster = _isMonster or false
    local heroInType = {}
    for i, info in ipairs(heros) do
        if isMonster then
            local heroInfo = monsterConf[info.heroID]
            if heroInfo.class == utype then
                info.class = heroInfo.class
                info.stance = heroInfo.stance
                info.botID = botHeroId
                info.isHero = true
                info.isMonster = isMonster
                table.insert(heroInType, info)
            end
        else
            local heroInfo = heroConf[info.heroID]
            if heroInfo.class == utype then
                info.class = heroInfo.class
                info.stance = heroInfo.stance
                info.botID = botHeroId
                info.isHero = true
                table.insert(heroInType, info)
            end
        end
    end

    table.sort(heroInType, function (a, b)
        return a.stance < b.stance
    end)

    local matrix = {}
    for i,v in ipairs(soldiers) do
        for i = 1, v.count do
            local info = {heroID = v.id, isHero = false, class = utype, botID = botSoldierId}
            table.insert(matrix, info)
        end
    end

    for i, heroInfo in ipairs(heroInType) do
        if heroInfo.stance == UnitStance.FRONT then
            table.insert(matrix, 1, heroInfo)
        elseif heroInfo.stance == UnitStance.MIDDLE then
            table.insert(matrix, math.min(11, #matrix + 1), heroInfo)
        elseif heroInfo.stance == UnitStance.BACK then
            table.insert(matrix, math.min(21, #matrix + 1), heroInfo)
        end
    end

    local result = {}
    for i = 1, 25 do
        local hero = matrix[i]
        if hero then
            table.insert(result, hero)
        end
    end

    return result
end

function LevelHandler:getLeftTeam()
    return FightData:getEmbattle()
end

function LevelHandler:createLeft()
    local botid = 0
    local botInfo
    self.leftTeam, botid = self:getLeftTeam()
    if botid and botid > 0 then
        botInfo = botConf[botid]
    end

    local leftInfo = FightData:getTeamInfo(UnitFaction.LEFT)
    local isMonster = false
    if leftInfo.monstername and leftInfo.monstername ~= 0 then
        isMonster = true
    end

    for i,v in ipairs(leftInfo.equip) do
        EquipFactory.createEquip(v, UnitFaction.LEFT)
    end

    local infantry = self:listMatrix(self.leftTeam.infantry, self.leftTeam.heros, UnitType.INFANTRY, botInfo and botInfo.footman, botInfo and botInfo.footmanHero,isMonster)
    local gunner = self:listMatrix(self.leftTeam.gunner, self.leftTeam.heros, UnitType.GUNNER, botInfo and botInfo.gunman, botInfo and botInfo.gunmanHero,isMonster)
    local archer = self:listMatrix(self.leftTeam.archer, self.leftTeam.heros, UnitType.ARCHER, botInfo and botInfo.archer, botInfo and botInfo.archerHero,isMonster)
    local cavalry = self:listMatrix(self.leftTeam.cavalry, self.leftTeam.heros, UnitType.CAVALRY, botInfo and botInfo.rider, botInfo and botInfo.riderHero,isMonster)

    --创建步兵
    for i, info in ipairs(infantry) do
        local hero = UnitFactory.createUnit(info, UnitFaction.LEFT)
        hero:setFlipX(true)
    end

    --创建枪兵
    for i, info in ipairs(gunner) do
        local hero = UnitFactory.createUnit(info, UnitFaction.LEFT)
        hero:setFlipX(true)
    end

    --创建弓兵
    for i, info in ipairs(archer) do
        local hero = UnitFactory.createUnit(info, UnitFaction.LEFT)
        hero:setFlipX(true)
    end

    --创建骑兵
    for i, info in ipairs(cavalry) do
        local hero = UnitFactory.createUnit(info, UnitFaction.LEFT)
        hero:setFlipX(true)
    end

    self:createBoss(self.leftTeam.boss, UnitFaction.LEFT)
    self:restoreLeftArray()
end

function LevelHandler:restoreLeftArray()
    local unitList = MapManager:getUnitList(UnitFaction.LEFT)
    local curLocation, front = self:arrayList(unitList[UnitType.INFANTRY], UnitFaction.LEFT, LeftLineAdjust, MaxBackgroundCount * BackgroundSingleWidth / 2 - UnitStartLocationBlanking)
    curLocation, front = self:arrayList(unitList[UnitType.GUNNER], UnitFaction.LEFT, LeftLineAdjust, curLocation, front)
    curLocation, front = self:arrayList(unitList[UnitType.ARCHER], UnitFaction.LEFT, LeftLineAdjust, curLocation, front)
    curLocation, front = self:arrayList(unitList[UnitType.CAVALRY], UnitFaction.LEFT, LeftLineAdjust, curLocation, front)
    curLocation, front = self:arrayList(unitList[UnitType.BOSS], UnitFaction.LEFT, LeftLineAdjust, curLocation, front)
end

function LevelHandler:createBoss(boss, faction)
    -- 暂时只支持一条龙
    if boss == nil or boss[1] == nil then
        return
    end

    local damage = boss[1].damage or 0
    local info = {heroID = boss[1].bossID, isHero = false, isBoss = true, class = UnitType.BOSS}
    local boss = UnitFactory.createUnit(info, faction)
    if faction == UnitFaction.LEFT then
        boss:setFlipX(true)
        boss:setLocation(cc.p(MaxBackgroundCount * BackgroundSingleWidth / 2 - UnitStartLocationBlanking, UnitStartLocationY))
    else
        boss:setLocation(cc.p(MaxBackgroundCount * BackgroundSingleWidth / 2 + UnitStartLocationBlanking, UnitStartLocationY))
    end

    boss:setBossDamage(damage)

    self.isBossFight = true
end

function LevelHandler:getRightTeam()
    return FightData:getMonsterTeam()
end

function LevelHandler:createRight()
    local botid = 0
    local botInfo
    self.rightTeam, botid = self:getRightTeam()
    if botid and botid > 0 then
        botInfo = botConf[botid]
    end

    local rightInfo = FightData:getTeamInfo(UnitFaction.RIGHT)
    local isMonster = false
    if rightInfo.monstername and rightInfo.monstername ~= 0 then
        isMonster = true
    end
    
    for i,v in ipairs(rightInfo.equip) do
        EquipFactory.createEquip(v, UnitFaction.RIGHT)
    end

    local infantry = self:listMatrix(self.rightTeam.infantry, self.rightTeam.heros, UnitType.INFANTRY, botInfo and botInfo.footman, botInfo and botInfo.footmanHero, isMonster)
    local gunner = self:listMatrix(self.rightTeam.gunner, self.rightTeam.heros, UnitType.GUNNER, botInfo and botInfo.gunman, botInfo and botInfo.gunmanHero, isMonster)
    local archer = self:listMatrix(self.rightTeam.archer, self.rightTeam.heros, UnitType.ARCHER, botInfo and botInfo.archer, botInfo and botInfo.archerHero, isMonster)
    local cavalry = self:listMatrix(self.rightTeam.cavalry, self.rightTeam.heros, UnitType.CAVALRY, botInfo and botInfo.rider, botInfo and botInfo.riderHero, isMonster)

    --创建步兵
    for i, info in ipairs(infantry) do
        local hero = UnitFactory.createUnit(info, UnitFaction.RIGHT)
    end

    --创建枪兵
    for i, info in ipairs(gunner) do
        local hero = UnitFactory.createUnit(info, UnitFaction.RIGHT)
    end

    --创建弓兵
    for i, info in ipairs(archer) do
        local hero = UnitFactory.createUnit(info, UnitFaction.RIGHT)
    end

    --创建骑兵
    for i, info in ipairs(cavalry) do
        local hero = UnitFactory.createUnit(info, UnitFaction.RIGHT)
    end

    self:createBoss(self.rightTeam.boss, UnitFaction.RIGHT)

    self:restoreRightArray()
end

function LevelHandler:restoreRightArray()
    local unitList = MapManager:getUnitList(UnitFaction.RIGHT)
    local curLocation, front = self:arrayList(unitList[UnitType.INFANTRY], UnitFaction.RIGHT, RightLineAdjust, MaxBackgroundCount * BackgroundSingleWidth / 2 + UnitStartLocationBlanking)
    curLocation, front = self:arrayList(unitList[UnitType.GUNNER], UnitFaction.RIGHT, RightLineAdjust, curLocation, front)
    curLocation, front = self:arrayList(unitList[UnitType.ARCHER], UnitFaction.RIGHT, RightLineAdjust, curLocation, front)
    curLocation, front = self:arrayList(unitList[UnitType.CAVALRY], UnitFaction.RIGHT, RightLineAdjust, curLocation, front)
    curLocation, front = self:arrayList(unitList[UnitType.BOSS], UnitFaction.RIGHT, RightLineAdjust, curLocation, front)
end

function LevelHandler:reviveUnit(hero)
    MapManager:addUnit(hero)
    MapManager:removeFromDead(hero:getID())

    if hero:getFaction() == UnitFaction.LEFT then
        self:restoreLeftArray()
    else
        self:restoreRightArray()
    end
end

function LevelHandler:summonUnit(info, faction, owner)
    local hero = UnitFactory.createUnit(info, faction, owner)
    hero:doReviveBuff()
    hero:skillBuff()

    if faction == UnitFaction.LEFT then
        self:restoreLeftArray()
    else
        self:restoreRightArray()
    end
    hero:startWait(0)

    return hero
end

function LevelHandler:handleUnitDead(unit, frame)
    local units = MapManager:getUnitMap()
    for k, v in pairs(units) do
        if v:isAlive() then
            v:removeAuraBySender(unit)
            if unit:getFaction() == v:getFaction() then
                if unit:isHero() then
                    v:addDieHeroCount()
                end
                
                v:triggerChangeBuff(ChanceTypeCondition.SelfDead, frame)
            else
                v:triggerChangeBuff(ChanceTypeCondition.EnemyDead, frame)
            end
        end
    end
end

return LevelHandler