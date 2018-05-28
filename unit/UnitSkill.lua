
local OpenServerConfig = OpenServerConfig
local heroConf = OpenServerConfig("heroConf")
local monsterConf = OpenServerConfig("monsterConf")
local skillConf = OpenServerConfig("skillConf")
local buffConf = OpenServerConfig("buffConf")

local UnitSkill = class("UnitSkill")

function UnitSkill.create(target)
    local skill = UnitSkill.new()
	skill:init(target)
	return skill
end

function UnitSkill:ctor()
    self.attackSkill = {}
    self.activeSkill = {}       --主动技能
    self.additiveSkill = {}     --附加技能
    self.passiveSkill = {}      --被动技能
    self.conditionSkill = {}    --条件技能
    self.currentSkillID = 0
    self.skillDatas = {}
    self.usedSkill = {}
end

function UnitSkill:init(target)
    self.target = target
    --print("heroConf[target:getHeroID()].skills",target:getHeroID(), heroConf[target:getHeroID()], heroConf[target:getHeroID()] and heroConf[target:getHeroID()].skills)
    local heroInfo = {}
    if target:getHeroInfo().isMonster then
        heroInfo = monsterConf[target:getHeroID()]
    elseif target:isHero() then
        heroInfo = heroConf[target:getHeroID()]
    else
        heroInfo = monsterConf[target:getHeroID()]
    end

    if heroInfo.commonSkill then
        local skillData = skillConf[heroInfo.commonSkill]
        if skillData then
            table.insert(self.attackSkill, heroInfo.commonSkill)
            self.skillDatas[heroInfo.commonSkill] = skillData
        end
    end

    local skillList = {}
    if heroInfo.skill1 then
        table.insert(skillList, heroInfo.skill1)
    end

    if heroInfo.skill2 then
        table.insert(skillList, heroInfo.skill2)
    end

    if heroInfo.skill3 then
        table.insert(skillList, heroInfo.skill3)
    end

    if heroInfo.backSkill then
        self.backSkill = skillConf[heroInfo.backSkill]
    end

    -- if heroInfo.skillLot1 and target:isSkillLot1Active() then
    --     table.insert(skillList, heroInfo.skillLot1)
    -- end

    -- if heroInfo.skillLot2 and target:isSkillLot2Active() then
    --     table.insert(skillList, heroInfo.skillLot2)
    -- end

    -- if heroInfo.skillAwaken then
    --     for i = 1, target:getAwaken() do
    --         table.insert(skillList, heroInfo.skillAwaken[i])
    --     end
    -- end

    for i, skillID in ipairs(skillList) do
        local skillData = skillConf[skillID]
        if skillData then
            self.skillDatas[skillID] = skillData
            if skillData.class == SkillClassType.ACTIVE then
                self.activeSkill[skillID] = skillData
            elseif skillData.class == SkillClassType.ADDITIVE then
                self.additiveSkill[skillID] = skillData
            elseif skillData.class == SkillClassType.PASSIVE then
                self.passiveSkill[skillID] = skillData
            elseif skillData.class == SkillClassType.CONDITION then
                self.conditionSkill[skillID] = skillData
            end
        end
    end
end

function UnitSkill:useSkill(skillIndex)
    self.currentSkillID = skillIndex
end

function UnitSkill:getCurrentSkillIndex()
    return self.currentSkillID
end

function UnitSkill:getSkillAnimName(id)
    return self.skillDatas[id].skillAnim
end

function UnitSkill:getCurrentSkillAnimName()
    return self:getSkillAnimName(self.currentSkillID)
end

function UnitSkill:doBeforeChanceTypeCondition(condition)
    local useCount = 0
    local target = self.target
    if target then
        if condition == BeforeChanceTypeCondition.Level then
            if target:isAlive() and (target:getHeroInfo().level or 0) > 20 then
                useCount = math.floor(target:getHeroInfo().level / 20)
            end
        elseif condition == BeforeChanceTypeCondition.Strenth then
            if target:isAlive() and (target:getHeroInfo().strength or 0) >= 10 then
                useCount = math.floor(target:getHeroInfo().strength / 10)
            end
        elseif condition == BeforeChanceTypeCondition.SameName then
            local list = {}
            local unitList = MapManager:getUnitList(target:getReverseFaction())
            for k, typeList in pairs(unitList) do
                for kk, unit in ipairs(typeList) do
                    if unit:isHero() then
                        local name = unit:getHeroName()
                        if not list[name] then
                            list[name] = 1
                        else
                            list[name] = list[name] + 1
                        end
                    end
                end
            end

            for k, v in pairs(list) do
                useCount = useCount + v - 1
            end
        end
    end

    return useCount
end

function UnitSkill:doCondition(condition, conditionValue, useTimes)
    local conditionValue = conditionValue or 0
    local useTimes = useTimes or 0
    local useCount = 0
    local target = self.target
    if target then
        if condition == SkillCondition.SelfHpUp then
            if target:isAlive() and target:getHpRatio() > conditionValue then
                useCount = 1
            end
        elseif condition == SkillCondition.SelfHpDown then
            if target:isAlive() and target:getHpRatio() < conditionValue then
                useCount = 1
            end
        elseif condition == SkillCondition.TargetHpUp then
            local targetPtr = target:getTargetPtr()
            if targetPtr then
                if targetPtr:isAlive() and targetPtr:getHpRatio() > conditionValue then
                    useCount = 1
                end
            end
        elseif condition == SkillCondition.TargetHpDown then
            local targetPtr = target:getTargetPtr()
            if targetPtr then
                if targetPtr:isAlive() and targetPtr:getHpRatio() < conditionValue then
                    useCount = 1
                end
            end
        elseif condition == SkillCondition.SelfMatrixDown then
            local count = MapManager:getLiveUnitCountInMatrix(target.faction, target.type)
            if (count / MaxUnitInMatrix) < conditionValue and target:isAlive() then
                useCount = 1
            end
        elseif condition == SkillCondition.SelfDead then
            if not target:isAlive() then
                useCount = 1
            end
        elseif condition == SkillCondition.SelfInfantryDown then
            local count = MapManager:getLiveUnitCountInMatrix(target.faction, UnitType.INFANTRY)
            if (count / MaxUnitInMatrix) < conditionValue and target:isAlive() then
                useCount = 1
            end
        elseif condition == SkillCondition.SelfHeroDead then
            if target:getDieHeroCount() > conditionValue then
                if useTimes == 0 then
                    useCount = 1
                elseif useTimes == -1 then
                    useCount = target:getDieHeroCount()
                elseif useTimes == 1 then
                    useCount = target:getDieHeroCount()
                    target:cleanDieHeroCount()
                end
            end
        elseif condition == SkillCondition.SelfSpecialDead then
            if target:isAlive() then
                local units = MapManager:getDeadUnit(target.faction)
                for k, unit in pairs(units) do
                    if unit:isHero() and not unit:isReplaced() and unit.heroInfo.heroID == conditionValue then
                        useCount = 1
                        break
                    end
                end
            end
        elseif condition == SkillCondition.SelfCanReplace then
            if target:isAlive() then
                local unitList = MapManager:getUnitList(target.faction)
                for k, typeList in pairs(unitList) do
                    local findHero = false
                    local findSoldier = false
                    for kk, unit in ipairs(typeList) do
                        if unit:isAlive() and not unit:isHero() then
                            findSoldier = true
                        elseif not unit:isReplaced() and unit:isAlive() and unit:isHero() and unit:getHeroID() ~= target:getHeroID() then
                            findHero = true
                        end

                        if findHero and findSoldier then
                            break
                        end
                    end

                    if findHero and findSoldier then
                        useCount = 1
                        break
                    end
                end
            end
        end
    end

    return useCount
end

--被动技能
function UnitSkill:usePassiveSkill()
    for i, skill in pairs(self.passiveSkill) do
        if skill.frontBuff and skill.frontBuffRange and skill.frontBuffOdds then
            if MyRandom:random(1, 1000) <= (skill.frontBuffOdds * 1000) then
                for iii, buff in ipairs(skill.frontBuff) do
                    local rangeType = skill.frontBuffRange[iii]
                    local unitList = MapManager:getUnitsByRange(self.target, rangeType)
                    for i,unit in ipairs(unitList) do
                        unit:addBuff(buff, self.target:getID(), true, skill.Id, LevelStateType.END_ROUND)
                    end
                end
            end
        end

        if skill.afterBuff and skill.afterBuffRange and skill.afterBuffOdds then
            if MyRandom:random(1, 1000) <= (skill.afterBuffOdds * 1000) then
                for iii, buff in ipairs(skill.afterBuff) do
                    local rangeType = skill.afterBuffRange[iii]
                    local unitList = MapManager:getUnitsByRange(self.target, rangeType)
                    for i,unit in ipairs(unitList) do
                        unit:addBuff(buff, self.target:getID(), true, skill.Id, LevelStateType.END_ROUND)
                    end
                end
            end
        end

        if skill.killBuff and skill.killBuffRange and skill.killBuffOdds then
            for iii, buff in ipairs(skill.killBuff) do
                self.target:addKillBuff({killBuff = buff, killBuffRange = skill.killBuffRange[iii], killBuffOdds = skill.killBuffOdds})
            end
        end


        if skill.chanceBuff and skill.chanceBuffRange and skill.chanceBuffOdds then
            if skill.beforeChanceType then
                if MyRandom:random(1, 1000) <= (skill.chanceBuffOdds * 1000) then
                    for ii, condition in ipairs(skill.beforeChanceType) do
                        local buff = skill.chanceBuff[ii]
                        local rangeType = skill.chanceBuffRange[ii]
                        local unitList = MapManager:getUnitsByRange(self.target, rangeType)
                        local count = self:doBeforeChanceTypeCondition(condition)
                        for iii = 1, count do
                            for i, unit in ipairs(unitList) do
                                unit:addBuff(buff, self.target:getID(), true, skill.Id, LevelStateType.END_ROUND)
                            end
                        end
                    end
                end
            end

            if skill.chanceType then
                for iii, condition in ipairs(skill.chanceType) do
                    self.target:addChangeBuff({changeType = condition, changeBuff = skill.chanceBuff[iii], 
                        changeBuffRange = skill.chanceBuffRange[iii], changeBuffOdds = skill.chanceBuffOdds, skillId = skill.Id})
                end
            end
        end
    end
end

--补齐自己需要的光环
function UnitSkill:usePassiveSkillToUnit(unit)
    for i, skill in pairs(self.passiveSkill) do
        if skill.frontBuff and skill.frontBuffRange and skill.frontBuffOdds then
            if MyRandom:random(1, 1000) <= (skill.frontBuffOdds * 1000) then
                for iii, buff in ipairs(skill.frontBuff) do
                    local rangeType = skill.frontBuffRange[iii]
                    local unitList = MapManager:getUnitsByRange(self.target, rangeType)
                    for i,v in ipairs(unitList) do
                        if v:getID() == unit:getID() then
                            unit:addBuff(buff, self.target:getID(), true, skill.Id, LevelStateType.END_ROUND)
                            break
                        end
                    end
                end
            end
        end

        if skill.afterBuff and skill.afterBuffRange and skill.afterBuffOdds then
            if MyRandom:random(1, 1000) <= (skill.afterBuffOdds * 1000) then
                for iii, buff in ipairs(skill.afterBuff) do
                    local rangeType = skill.afterBuffRange[iii]
                    local unitList = MapManager:getUnitsByRange(self.target, rangeType)
                    for i,v in ipairs(unitList) do
                        if v:getID() == unit:getID() then
                            unit:addBuff(buff, self.target:getID(), true, skill.Id, LevelStateType.END_ROUND)
                            break
                        end
                    end
                end
            end
        end

        if skill.chanceBuff and skill.chanceBuffRange and skill.chanceBuffOdds then
            if skill.beforeChanceType then
                if MyRandom:random(1, 1000) <= (skill.chanceBuffOdds * 1000) then
                    for ii, condition in ipairs(skill.beforeChanceType) do
                        local buff = skill.chanceBuff[ii]
                        local rangeType = skill.chanceBuffRange[ii]
                        local unitList = MapManager:getUnitsByRange(self.target, rangeType)
                        local count = self:doBeforeChanceTypeCondition(condition)
                        for iii = 1, count do
                            for i, v in ipairs(unitList) do
                                if v:getID() == unit:getID() then
                                    unit:addBuff(buff, self.target:getID(), true, skill.Id, LevelStateType.END_ROUND)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

--战前技能
function UnitSkill:useAdditiveSkill()
    local curRound = GameManager:getCurRound()
    local curLevelState = GameManager.levelHandler.curState
    for k, skill in pairs(self.additiveSkill) do
        local coolDown = true
        if self.usedSkill[skill.Id] and skill.cooldown then
            local coolTurn = self.usedSkill[skill.Id].round + skill.cooldown[1].turn
            if (curRound - coolTurn) > 1 then
            elseif (curRound - coolTurn) == 1 and self.usedSkill[skill.Id].state <= curLevelState then
            else
                coolDown = false
            end
        end

        if coolDown and skill.odds then
            local odd = 0
            if curRound == 1 then
                odd = skill.odds[1].first
            else
                odd = skill.odds[1].normal
            end

            local useCount = 1
            if skill.condition then
                useCount = self:doCondition(skill.condition, skill.conditionValue, skill.useTimes)
            end

            if useCount > 0 and (MyRandom:random(1, 1000) - self.target:getAddSkillOdds()) <= (odd * 1000) then
                self.usedSkill[skill.Id] = {round = curRound, state = curLevelState}
                self.target:recordBehavior(0, UnitBehaviorType.additiveSkill, skill.Id)

                for ii = 1, useCount do
                    if skill.frontBuff and skill.frontBuffRange and skill.frontBuffOdds then
                        if MyRandom:random(1, 1000) <= (skill.frontBuffOdds * 1000) then
                            for iii, buff in ipairs(skill.frontBuff) do
                                local rangeType = skill.frontBuffRange[iii]
                                local unitList = MapManager:getUnitsByRange(self.target, rangeType)
                                for i,unit in ipairs(unitList) do
                                    unit:addBuff(buff, self.target:getID(), false, skill.Id, curLevelState)
                                end
                            end
                        end
                    end

                    if skill.afterBuff and skill.afterBuffRange and skill.afterBuffOdds then
                        if MyRandom:random(1, 1000) <= (skill.afterBuffOdds * 1000) then
                            for iii, buff in ipairs(skill.afterBuff) do
                                local rangeType = skill.afterBuffRange[iii]
                                local unitList = MapManager:getUnitsByRange(self.target, rangeType)
                                for i, unit in ipairs(unitList) do
                                    unit:addBuff(buff, self.target:getID(), false, skill.Id, curLevelState)
                                end
                            end
                        end
                    end

                    if skill.hitBuff and skill.hitBuffRange and skill.hitBuffOdds then
                        for iii, buff in ipairs(skill.hitBuff) do
                            self.target:addHitBuff({hitBuff = buff, hitBuffRange = skill.hitBuffRange[iii], hitBuffOdds = skill.hitBuffOdds, skillId = skill.Id})
                        end
                    end
                end

                return skill.Id
            end
        end
    end
end

--主动技能
function UnitSkill:useActiveSkill()
    local curRound = GameManager:getCurRound()
    local curLevelState = GameManager.levelHandler.curState
    for k, skill in pairs(self.activeSkill) do
        local coolDown = true
        if self.usedSkill[skill.Id] and skill.cooldown then
            local coolTurn = self.usedSkill[skill.Id].round + skill.cooldown[1].turn
            if (curRound - coolTurn) > 1 then
            elseif (curRound - coolTurn) == 1 and self.usedSkill[skill.Id].state <= curLevelState then
            elseif self.target.attackTimes >= skill.cooldown[1].time then
            else
                coolDown = false
            end
        end

        if coolDown and skill.odds then
            local odd = 0
            if curRound == 1 then
                odd = skill.odds[1].first   
            else
                odd = skill.odds[1].normal
            end

            local useCount = 1
            if skill.condition then
                useCount = self:doCondition(skill.condition, skill.conditionValue, skill.useTimes)
            end

            if useCount and (MyRandom:random(1, 1000) - self.target:getAddSkillOdds()) <= (odd * 1000) then
                self.usedSkill[skill.Id] = {round = curRound, state = curLevelState}
                self.target.attackTimes = 0
                
                for ii = 1, useCount do
                    local allUnits = {}
                    if skill.frontBuff and skill.frontBuffRange and skill.frontBuffOdds then
                        if MyRandom:random(1, 1000) <= (skill.frontBuffOdds * 1000) then
                            for iii, buff in ipairs(skill.frontBuff) do
                                local rangeType = skill.frontBuffRange[iii]
                                local unitList = MapManager:getUnitsByRange(self.target, rangeType)
                                for i,unit in ipairs(unitList) do
                                    unit:addBuff(buff, self.target:getID(), false, skill.Id, curLevelState)
                                    if not unit:isAlive() then
                                        unit:initAttribute()
                                        unit:initBaseBuff()
                                    end
                                    table.insert(allUnits, unit)
                                end
                            end
                        end
                    end

                    if skill.afterBuff and skill.afterBuffRange and skill.afterBuffOdds then
                        if MyRandom:random(1, 1000) <= (skill.afterBuffOdds * 1000) then
                            for iii, buff in ipairs(skill.afterBuff) do
                                local rangeType = skill.afterBuffRange[iii]
                                local unitList = MapManager:getUnitsByRange(self.target, rangeType)
                                for i,unit in ipairs(unitList) do
                                    unit:addBuff(buff, self.target:getID(), false, skill.Id, curLevelState)
                                    if not unit:isAlive() then
                                        unit:initAttribute()
                                        unit:initBaseBuff()
                                    end
                                    table.insert(allUnits, unit)
                                end
                            end
                        end
                    end

                    if skill.hitBuff and skill.hitBuffRange and skill.hitBuffOdds then
                        for iii, buff in ipairs(skill.hitBuff) do
                            self.target:addHitBuff({hitBuff = buff, hitBuffRange = skill.hitBuffRange[iii], hitBuffOdds = skill.hitBuffOdds, skillId = skill.Id})
                        end
                    end

                    for i, unit in ipairs(allUnits) do
                        unit:skillBuff()
                    end
                end

                return skill.Id
            end
        end
    end
end

--条件技能
function UnitSkill:useConditionSkill()
    local curRound = GameManager:getCurRound()
    local curLevelState = GameManager.levelHandler.curState
    for k, skill in pairs(self.conditionSkill) do
        local coolDown = true
        if self.usedSkill[skill.Id] and skill.cooldown then
            local coolTurn = self.usedSkill[skill.Id].round + skill.cooldown[1].turn
            if (curRound - coolTurn) > 1 then
            elseif (curRound - coolTurn) == 1 and self.usedSkill[skill.Id].state <= curLevelState then
            else
                coolDown = false
            end
        end

        if coolDown and skill.odds then
            local odd = 0
            if curRound == 1 then
                odd = skill.odds[1].first
            else
                odd = skill.odds[1].normal
            end

            local useCount = 1
            if skill.condition then
                useCount = self:doCondition(skill.condition, skill.conditionValue, skill.useTimes)
            end

            if useCount > 0 and (MyRandom:random(1, 1000) - self.target:getAddSkillOdds()) <= (odd * 1000) then
                self.usedSkill[skill.Id] = {round = curRound, state = curLevelState}

                for ii = 1, useCount do
                    if skill.frontBuff and skill.frontBuffRange and skill.frontBuffOdds then
                        if MyRandom:random(1, 1000) <= (skill.frontBuffOdds * 1000) then
                            for iii, buff in ipairs(skill.frontBuff) do
                                local rangeType = skill.frontBuffRange[iii]
                                local unitList = MapManager:getUnitsByRange(self.target, rangeType)
                                for i,unit in ipairs(unitList) do
                                    unit:addBuff(buff, self.target:getID(), false, skill.Id, curLevelState)
                                end
                            end
                        end
                    end

                    if skill.afterBuff and skill.afterBuffRange and skill.afterBuffOdds then
                        if MyRandom:random(1, 1000) <= (skill.afterBuffOdds * 1000) then
                            for iii, buff in ipairs(skill.afterBuff) do
                                local rangeType = skill.afterBuffRange[iii]
                                local unitList = MapManager:getUnitsByRange(self.target, rangeType)
                                for i,unit in ipairs(unitList) do
                                    unit:addBuff(buff, self.target:getID(), false, skill.Id, curLevelState)
                                end
                            end
                        end
                    end

                end

                self.target:recordBehavior(self.target.curFrame, UnitBehaviorType.conditionSkill, skill.Id)

                return skill.Id
            end
        end
    end
end

--反击技能
function UnitSkill:useBackSkill()
    local curRound = GameManager:getCurRound()
    local curLevelState = GameManager.levelHandler.curState
    if self.backSkill then
        local skill = self.backSkill
        local coolDown = true
        if self.usedSkill[skill.Id] and skill.cooldown then
            local coolTurn = self.usedSkill[skill.Id].round + skill.cooldown[1].turn
            if (curRound - coolTurn) > 1 then
            elseif (curRound - coolTurn) == 1 and self.usedSkill[skill.Id].state <= curLevelState then
            elseif self.target.attackTimes >= skill.cooldown[1].time then
            else
                coolDown = false
            end
        end

        if coolDown and skill.odds then
            local odd = 0
            if curRound == 1 then
                odd = skill.odds[1].first   
            else
                odd = skill.odds[1].normal
            end

            local useCount = 1
            if skill.condition then
                useCount = self:doCondition(skill.condition, skill.conditionValue, skill.useTimes)
            end

            if useCount and (MyRandom:random(1, 1000) - self.target:getAddSkillOdds()) <= (odd * 1000) then
                self.usedSkill[skill.Id] = {round = curRound, state = curLevelState}
                self.target.attackTimes = 0
                
                for ii = 1, useCount do
                    local allUnits = {}
                    if skill.frontBuff and skill.frontBuffRange and skill.frontBuffOdds then
                        if MyRandom:random(1, 1000) <= (skill.frontBuffOdds * 1000) then
                            for iii, buff in ipairs(skill.frontBuff) do
                                local rangeType = skill.frontBuffRange[iii]
                                local unitList = MapManager:getUnitsByRange(self.target, rangeType)
                                for i,unit in ipairs(unitList) do
                                    unit:addBuff(buff, self.target:getID(), false, skill.Id, curLevelState)
                                    if not unit:isAlive() then
                                        unit:initAttribute()
                                        unit:initBaseBuff()
                                    end
                                    table.insert(allUnits, unit)
                                end
                            end
                        end
                    end

                    if skill.afterBuff and skill.afterBuffRange and skill.afterBuffOdds then
                        if MyRandom:random(1, 1000) <= (skill.afterBuffOdds * 1000) then
                            for iii, buff in ipairs(skill.afterBuff) do
                                local rangeType = skill.afterBuffRange[iii]
                                local unitList = MapManager:getUnitsByRange(self.target, rangeType)
                                for i,unit in ipairs(unitList) do
                                    unit:addBuff(buff, self.target:getID(), false, skill.Id, curLevelState)
                                    if not unit:isAlive() then
                                        unit:initAttribute()
                                        unit:initBaseBuff()
                                    end
                                    table.insert(allUnits, unit)
                                end
                            end
                        end
                    end

                    if skill.hitBuff and skill.hitBuffRange and skill.hitBuffOdds then
                        for iii, buff in ipairs(skill.hitBuff) do
                            self.target:addHitBuff({hitBuff = buff, hitBuffRange = skill.hitBuffRange[iii], hitBuffOdds = skill.hitBuffOdds, skillId = skill.Id})
                        end
                    end

                    for i, unit in ipairs(allUnits) do
                        unit:skillBuff()
                    end
                end

                return skill
            end
        end
    end
end

--[[function UnitSkill:getCurrentSkillSound()
    return self:getSKillSound(self.currentSkillID)
end]]

function UnitSkill:getCurrentSkillSound()
    return self:getSKillSound(self.currentSkillID)
end

function UnitSkill:getAttackSound()
    return self:getSKillSound(self:getAttackSkillIndex())
end

function UnitSkill:getSKillSound(id)
    local skillConf = self.skillDatas[id] or skillConf[id]
    local soundList = skillConf.launchSound

    if not soundList or math.random(1, 100) < 50 then 
        return skillConf.skillAnim
    else
        local soundName = soundList[math.random(1, #soundList)]
        return soundName
    end
end

function UnitSkill:getAttackSkillIndex()
	return self.attackSkill[1]
end

function UnitSkill:getCurrentSkillConf(stage)
    return self:getSkillConfByIndex(self:getCurrentSkillIndex(), stage)
end

function UnitSkill:getSkillConfByIndex(skillIndex, stage)
    local skillConf = self.skillDatas[skillIndex] or skillConf[skillIndex]
    return skillConf.triggers[stage]
end

function UnitSkill:getSkillConf(skillIndex)
    return self.skillDatas[skillIndex] or skillConf[skillIndex]
end

function UnitSkill:setBulletAttribute(bullet, skillID)
    --print("UnitSkill:setBulletAttribute(bullet, skillID, stage)", skillID, stage)
    local skillConf = self.skillDatas[skillID] or skillConf[skillID]

    --[[if skillConf.skillReleaseSound then
        bullet.skillReleaseSound = skillConf.skillReleaseSound
    end]]
    
    local fact = 1
    if self.faction == UnitFaction.RIGHT then
        fact = -1
    end

    local hitPos = self.target:getBulletLocation()
    -- local location = self.target:getLocation()
    bullet.location.x = hitPos.x
    bullet.location.y = hitPos.y
    bullet.bulletAttribute.lockID = self.target:getID()--:getLockID()
    bullet.bulletAttribute.sid = self.target:getID()
    bullet.bulletAttribute.skillID = skillID
    bullet.bulletAttribute.skillStage = stage
    bullet.bulletAttribute.faction = self.target:getFaction()
    bullet:setLineIndex(self.target:getLineIndex())
    -- if GameManager:isInPVP() then
    --     bullet:setTargetList(GameManager:getBullettTargetListByID(bullet.bid))
    -- end
    
    local attribute = self.target.attribute
    
    bullet.bulletAttribute.senderCriticalHit = attribute.crit
    bullet.bulletAttribute.senderHeroID = self.target:isSummon() and self.target.ownerHeroID or self.target:getHeroID()
    bullet.bulletAttribute.senderFaction = self.target:getFaction()
    bullet.bulletAttribute.senderFlipX = self.target:isFlipX()
    bullet.bulletAttribute.senderInfo = self.target:getHeroInfo()
    bullet.bulletAttribute.senderType = self.target:getType()
    bullet.bulletAttribute.tid = self.target:getTargetID()

    local attribute = nil
    local orgAttribute = nil
    if self == nil then
        attribute = {attack = 0, hurtInfantry = 0, hurtCavalry = 0, hurtArcher = 0, hurtGunner = 0, hurtHero = 0, hurtAll = 0}
        orgAttribute = {hp = 0}
    else
        attribute = self.target.attribute
        orgAttribute = self.target.orgAttribute 
    end

    bullet.damageAttribute.attack = attribute.attack
    bullet.damageAttribute.hurtInfantry = attribute.hurtInfantry
    bullet.damageAttribute.hurtCavalry = attribute.hurtCavalry
    bullet.damageAttribute.hurtArcher = attribute.hurtArcher
    bullet.damageAttribute.hurtGunner = attribute.hurtGunner
    bullet.damageAttribute.hurtHero = attribute.hurtHero
    bullet.damageAttribute.hurtAll = attribute.hurtAll
    bullet.damageAttribute.critDamage = attribute.critDamage

    if skillConf.effectSuffer then
        bullet.hitEffectAttribute.jsonName = skillConf.effectSuffer
    end

    if skillConf.hitAnimName then
        bullet.hitEffectAttribute.animName = skillConf.hitAnimName
    end

    if skillConf.hitLoopCount then
        bullet.hitEffectAttribute.loopCount = skillConf.hitLoopCount
    end

    if skillConf.hitFollowTarget then
        bullet.hitEffectAttribute.followTarget = skillConf.hitFollowTarget
    end

    if skillConf.hitOffsetLocX then
        bullet.hitEffectAttribute.offsetLoc.x = skillConf.hitOffsetLocX
    end

    if skillConf.hitOffsetLocY then
        bullet.hitEffectAttribute.offsetLoc.y = skillConf.hitOffsetLocY
    end

    if skillConf.hitZOrder then
        bullet.hitEffectAttribute.zOrder = skillConf.hitZOrder
    end
end

function UnitSkill:getEnteringSkillIndex()
    return self.enteringSkill[1]
end

function UnitSkill:isEnteringSkillEnabled()
	return #self.enteringSkill > 0
end

function UnitSkill:useEnabled(index)
    if index == nil then 
        return false
    end

    local skillData = self.skillDatas[index]
    local targetPtr = self.target:getTargetPtr()

    if skillData.needPursue == true and self.target:skillNeedPursue() then--((targetPtr ~= nil and self.target:needPursue()) or targetPtr == nil)then
        return false
    end

    return true
end

return UnitSkill