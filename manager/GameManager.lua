if DEBUG > 1 then
mySocket = require("socket")
end

local LevelHandler = OpenServerFile("LevelHandler")

local GameManager = class("GameManager")

function GameManager:init()
    self:initFlag()

    MapManager:init()
    
    UnitInfo:reset()
    BulletInfo:reset()

    self:initLevelHandler()
end

function GameManager:initFlag()
    self.stateType = GameStateType.PLAYING

    self.eventsVec = {}
    self.ticks = 0
end

function GameManager:initLevelHandler()
    self.levelHandler = LevelHandler.create()

    self.levelHandler:onGameInit()
end

function GameManager:startGame()
    self:init()
    return self:onStartGame()
end

function GameManager:onStartGame()
    local startTime = FightData:getRandomSeed()
    MyRandom:randomseed(startTime)

if DEBUG > 1 then
    local beginTime = mySocket:gettime()
    local n = 0
    local tickTime = 0 
    local totalTime = 0

    local b = mySocket:gettime() - beginTime
    print("ceshi update ==",b)

    local beginTime = mySocket:gettime()
    local tickTime = 0 
    local totalTime = 0
    local n = 0
    print("start calc")
    local frame = 0

    while self.stateType == GameStateType.PLAYING do
        self:updateGame(1)
        n = n + 1
        tickTime = mySocket:gettime() - beginTime
        -- print("update  time: ", frame, tickTime, self.levelHandler.curState)
        totalTime = totalTime + tickTime
        beginTime = mySocket:gettime()
        frame = frame + 1
    end
else
    while self.stateType == GameStateType.PLAYING do
        if os.time() - allStartTime > 15 then
            print(xxxxx.xxxxx)
        end
        self:updateGame(1)
    end
end


    local result = true
    if self.stateType == GameStateType.COMPLETE then
        result = true
    else
        result = false
    end

    local leftTeam = {}
    leftTeam.team = clone(FightData:getEmbattle())
    local leftInfo = FightData:getTeamInfo(UnitFaction.LEFT)
    leftTeam.userid = leftInfo.userid
    leftTeam.username = leftInfo.username
    leftTeam.userhead = leftInfo.userhead
    leftTeam.monstername = leftInfo.monstername
    leftTeam.buffList = leftInfo.buffList
    
    local rightTeam = {}
    rightTeam.team = clone(FightData:getMonsterTeam())
    local rightInfo = FightData:getTeamInfo(UnitFaction.RIGHT)
    rightTeam.userid = rightInfo.userid
    rightTeam.username = rightInfo.username
    rightTeam.userhead = rightInfo.userhead
    rightTeam.monstername = rightInfo.monstername
    rightTeam.buffList = rightInfo.buffList

    local fightResult = {
        result = result,
        leftTeam = {
            infantry = clone(leftTeam.team.infantry),
            gunner = clone(leftTeam.team.gunner),
            archer = clone(leftTeam.team.archer),
            cavalry = clone(leftTeam.team.cavalry),
            heros = {},
            boss = {},
        },
        rightTeam = {
            infantry = clone(rightTeam.team.infantry),
            gunner = clone(rightTeam.team.gunner),
            archer = clone(rightTeam.team.archer),
            cavalry = clone(rightTeam.team.cavalry),
            heros = {},
            boss = {},
        },
    }

    for i, hero in ipairs(leftTeam.team.heros) do
        table.insert(fightResult.leftTeam.heros, {uniqueID = hero.uniqueID, dead = 1})
    end

    for i, hero in ipairs(rightTeam.team.heros) do
        table.insert(fightResult.rightTeam.heros, {uniqueID = hero.uniqueID, dead = 1})
    end

    if leftTeam.team.boss then
        for i, boss in ipairs(leftTeam.team.boss) do
            table.insert(fightResult.leftTeam.boss, {bossID = boss.bossID, damage = 0, dead = 1})
        end
    end

    if rightTeam.team.boss then
        for i, boss in ipairs(rightTeam.team.boss) do
            table.insert(fightResult.rightTeam.boss, {bossID = boss.bossID, damage = 0, dead = 1})
        end
    end

    local function dealAliveUnit(matrix, soldiers, heros, bosses)
        for i,v in ipairs(soldiers) do
            v.dead = v.count
        end

        for i, unit in ipairs(matrix) do
            local unitInfo = unit:getHeroInfo()
            if unitInfo.isHero then
                for i, hero in ipairs(heros) do
                    if hero.uniqueID == unitInfo.uniqueID then
                        hero.dead = 0
                        break
                    end
                end
            elseif unitInfo.isBoss then
                for i, boss in ipairs(bosses) do
                    if boss.bossID == unitInfo.heroID then
                        boss.damage = math.ceil(unit:getStartHp() - unit:getHp())
                        boss.dead = 0
                        break
                    end
                end
            else
                for i, soldier in ipairs(soldiers) do
                    if soldier.id == unitInfo.heroID then
                        soldier.dead = soldier.dead - 1
                        break
                    end
                end
            end
        end
    end

    local function getBossDamage(faction)
        if faction == UnitFaction.LEFT then
            faction = UnitFaction.RIGHT
        else
            faction = UnitFaction.LEFT
        end
        local damage = 0
        local boss = MapManager:getUnitList(faction)[UnitType.BOSS]
        if #boss <= 0 then
            local temp = MapManager:getDeadUnit(faction)
            for k,v in pairs(temp) do
                if v:getHeroInfo().isBoss then
                    boss = {v}
                    break
                end
            end
        end

        for k,v in pairs(boss) do
            damage = v:getStartHp() - v:getHp()
            break
        end

        return damage
    end

    local unitList = MapManager:getUnitList(UnitFaction.LEFT)
    dealAliveUnit(unitList[UnitType.INFANTRY], fightResult.leftTeam.infantry, fightResult.leftTeam.heros, fightResult.leftTeam.boss)
    dealAliveUnit(unitList[UnitType.GUNNER], fightResult.leftTeam.gunner, fightResult.leftTeam.heros, fightResult.leftTeam.boss)
    dealAliveUnit(unitList[UnitType.ARCHER], fightResult.leftTeam.archer, fightResult.leftTeam.heros, fightResult.leftTeam.boss)
    dealAliveUnit(unitList[UnitType.CAVALRY], fightResult.leftTeam.cavalry, fightResult.leftTeam.heros, fightResult.leftTeam.boss)
    dealAliveUnit(unitList[UnitType.BOSS], {}, {}, fightResult.leftTeam.boss)
    fightResult.leftTeam.bossdamage = getBossDamage(UnitFaction.LEFT)

    local unitList = MapManager:getUnitList(UnitFaction.RIGHT)
    dealAliveUnit(unitList[UnitType.INFANTRY], fightResult.rightTeam.infantry, fightResult.rightTeam.heros, fightResult.rightTeam.boss)
    dealAliveUnit(unitList[UnitType.GUNNER], fightResult.rightTeam.gunner, fightResult.rightTeam.heros, fightResult.rightTeam.boss)
    dealAliveUnit(unitList[UnitType.ARCHER], fightResult.rightTeam.archer, fightResult.rightTeam.heros, fightResult.rightTeam.boss)
    dealAliveUnit(unitList[UnitType.CAVALRY], fightResult.rightTeam.cavalry, fightResult.rightTeam.heros, fightResult.rightTeam.boss)
    dealAliveUnit(unitList[UnitType.BOSS], {}, {}, fightResult.rightTeam.boss)
    fightResult.rightTeam.bossdamage = getBossDamage(UnitFaction.RIGHT)

    local record = {
        fightResult = fightResult,
        endRound = self.levelHandler.curRound,
        result = result,
        ticks = globalTicks,
        randomseed = startTime,
    }

    local tempResultRecord = json.encode(record)
    local videoTable = {}
    videoTable.attributeTable = attributeTable
    videoTable.roundRecord = roundRecord
    videoTable.resultRecord = tempResultRecord
    videoTable.dataRecord = dataRecord
    local videostr = calc.serialize(videoTable)

    -- fprint("finish time :", mySocket:gettime() - beginTime)

    --存回放文件
    local writeStr = "return " .. calc.serialize({leftTeam = leftTeam, rightTeam = rightTeam}) .. ", " .. videostr

    return writeStr, fightResult
end

function GameManager:pauseGame()
    self.oldStateType = self.stateType
    self.stateType = GameStateType.PAUSE 
    pauseAllEffects()
end

function GameManager:continueGame()
    self.stateType = self.oldStateType
    resumeAllEffects()
end

function GameManager:endGame()
    self.stateType = GameStateType.EXIT
end

function GameManager:onPlaying()
    if self.levelHandler:isGameOver() then
        self.stateType = GameStateType.OVER
    elseif self.levelHandler:isGameComplete() then
        self.stateType = GameStateType.COMPLETE
    end
end

function GameManager:onResult()
    self.levelHandler:onGameComplete()
    self:endGame()
end

function GameManager:onOver()
    if self.levelHandler:onGameOver() then
        self:onResult()
    end
end

function GameManager:onComplete()
    if self.levelHandler:onGameComplete() then
        self:onResult()
    end
end

function GameManager:updateGame(ticks)
    self:doUpdate(ticks)
end

function GameManager:doUpdate(ticks)
    self.ticks = ticks

    MapManager:update()

    self.levelHandler:onGameUpdate(ticks)

    if self.stateType == GameStateType.PLAYING then
        self:onPlaying()
    elseif self.stateType == GameStateType.COMPLETE then
        self:onComplete() 
    elseif self.stateType == GameStateType.OVER then
        self:onOver()
    end

    self:updateEvent()
end

function GameManager:pushEvent(event)
    table.insert(self.eventsVec,event)
end

function GameManager:updateEvent()
    for key, var in ipairs(self.eventsVec) do
        self:handleEvent(var)
    end

    self.eventsVec = {}
end

function GameManager:getFreeFaction()
    return self.freeFaction
end

function GameManager:handleEvent(event)
end

function GameManager:getAbsTicks()
	return self.ticks
end

function GameManager:getTicks(lockID)
    if lockID == nil then
    	return self.ticks
    end

	return self.ticks
end

function GameManager:getCurRound()
    return self.levelHandler.curRound
end

function GameManager:isComplete()
    return self.stateType == GameStateType.COMPLETE
end

function GameManager:isBossFight()
    return self.levelHandler.isBossFight
end

function GameManager:handleUnitDead(sender, frame)
    self.levelHandler:handleUnitDead(sender, frame)
end

return GameManager