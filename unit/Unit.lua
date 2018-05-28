
local OpenServerConfig = OpenServerConfig
local heroConf = OpenServerConfig("heroConf")
local monsterConf = OpenServerConfig("monsterConf")
local buffConf = OpenServerConfig("buffConf")
local skillConf = OpenServerConfig("skillConf")
local globalConf = OpenServerConfig("globalConf")
local skillActionTimeConf = OpenServerConfig("skillActionTimeConf")

local OpenServerFile = OpenServerFile
local AnimReplacer = OpenServerFile("AnimReplacer")
local UnitSkill = OpenServerFile("UnitSkill")

local UnitAttribute = class("UnitAttribute")

local nameList = {
    "infantry",
    "gunner",
    "archer",
    "cavalry",
    "bossdragon",
}

function UnitAttribute.create()
    local attribute = UnitAttribute.new()
    return attribute
end

function UnitAttribute:ctor()
    self.rate = 1                       --攻击速度
    self.speed = 400                    --移动速度
    self.speedFactor = 1                --移动速度系数
    self.maxRange = 60                  --攻击距离
    self.hp = 150                       --生命
    self.attack = 80                    --攻击
    self.offset = 1                     --格挡
    self.dodge = 0                      --闪避
    self.crit = 5                       --暴击
    self.hurtAll = 0                    --对所有人额外伤害
    self.hurtInfantry = 0               --对步兵额外伤害
    self.hurtGunner = 0                 --对枪兵额外伤害
    self.hurtArcher = 0                 --对弓兵额外伤害
    self.hurtCavalry = 0                --对骑兵额外伤害
    self.hurtHero = 0                   --对英雄额外伤害
    self.sufferAll = 0                  --受到所有人的额外伤害
    self.sufferInfantry = 0             --受到步兵的额外伤害
    self.sufferGunner = 0               --受到枪兵的额外伤害
    self.sufferArcher = 0               --受到弓兵的额外伤害
    self.sufferCavalry = 0              --受到骑兵的额外伤害
    self.sufferHero = 0                 --受到英雄的额外伤害
    self.critDamage = 0                 --暴击伤害加成
    self.resistanceInfantry = 0         --受到步兵的最终伤害
    self.resistanceGunner = 0           --受到枪兵的最终伤害
    self.resistanceArcher = 0           --受到弓兵的最终伤害
    self.resistanceCavalry = 0          --受到骑兵的最终伤害
end

local Unit = class("Unit")

function Unit:ctor(id)
    self.uid = id or UnitInfo:seed()
    self.anim = nil
    self.ticks = 0
    self.lockID = 0
    
    self.location = {x = 0, y = 0}
    self.targetLocation = {x = 0, y = 0}
    self.lineLocation = {x = 0, y = 0}
    
    self.faction = UnitFaction.LEFT
    self.type = UnitType.INFANTRY
    self.heroInfo = {}
    self.equipList = {}
    self.buffList = {}
    self.killBuffList = {}
    self.hitBuffList = {}
    self.changeBuffList = {}
    
    self.autoCleanup = false

    self.attribute = UnitAttribute.create()
    self.orgAttribute = UnitAttribute.create()
    self.addAttribute = UnitAttribute.create()
    
    self.attackElapsed = self.attribute.rate
    self.isInGuard = false
    self.curFrame = 0

    self.eventsVec = {}

    self.stateAnimName = {}
    self.stateAnimName[UnitState.DIE] = "die"
    self.stateAnimName[UnitState.STAND] = "idle"
    self.stateAnimName[UnitState.WALK] = "move"
    self.stateAnimName[UnitState.ATTACK] = "atk"
    self.stateAnimName[UnitState.WINER] = "win"
    self.stateAnimName[UnitState.WAIT] = "idle"
    self.stateAnimName[-1] = "hit"

    self.curStateSoundID = -1 --角色当前的动作声音的id
    self.curStateSoundIsPlay = false

    self.indexInMatrix = 0
    self.isComplete = false
    self.finishInit = false
    self.hpIndex = 0
    self.revived = false

    self.attackTimes = 0
    self.addSkillOdds = 0
    self.dieHeroCount = 0

    self:initFlag()
end

function Unit:initFlag()
    self.state = UnitState.STAND
    self.nextState = UnitState.NONE
    self.targetID = 0
    self.targetPtr = nil
    self.hide = false
end

function Unit:init(heroInfo, faction, owner)
    self:setFaction(faction)

    self.heroInfo = heroInfo
    
    if owner then 
        self:initSummon(owner)
    end

    self:initSkill()

    local damageData
    if heroInfo.isHero then
        damageData = {info = heroInfo, heroDamage = 0, soldierDamage = 0, heal = 0, hurt = 0}
        table.insert(dataRecord[faction].damageList, damageData)
    else
        for i, v in ipairs(dataRecord[faction].damageList) do
            if v.info.heroID == heroInfo.heroID then
                damageData = dataRecord[faction].damageList[i]
                break
            end
        end

        if not damageData then
            damageData = {info = heroInfo, heroDamage = 0, soldierDamage = 0, heal = 0, hurt = 0}
            table.insert(dataRecord[faction].damageList, damageData)
        end

        self.equipList = MapManager:getEquipsByType(faction, self.type)
    end
    self.damageData = damageData
end

function Unit:initSummon(owner)
    self:setSummon(true)
    self:setOwnerID(owner:getID())
    self.ownerHeroID = owner:getHeroID()
    self:initAttribute()
    self:initBaseBuff()
    self:saveBaseAttr()

    local addHp = owner.addAttribute.hp * self.heroInfo.inherit
    local addAttack = owner.addAttribute.attack * self.heroInfo.inherit

    self.baseAttriTab[AttributeType.life] = self.baseAttriTab[AttributeType.life] + addHp
    self.baseAttriTab[AttributeType.attack] = self.baseAttriTab[AttributeType.attack] + addAttack

    self.orgAttribute.hp = self.orgAttribute.hp + addHp
    self.orgAttribute.attack = self.orgAttribute.attack + addAttack

    self.attribute.hp = self.orgAttribute.hp
    self.attribute.attack = self.orgAttribute.attack

    local attriTab = attributeTable[tostring(self:getID())]
    attriTab[AttributeType.life] = self.attribute.hp
    attriTab[AttributeType.attack] = self.attribute.attack
end

function Unit:placeUI()
    MapManager:addUnit(self)
    self:createHeroAnimation()
end

function Unit:placeInBattle()
    self:initFlag()
    
    local hp = self.attribute.hp
    self.attribute = calc.tableShallowCopy(self.orgAttribute)
    self.attribute.hp = hp
    
    self:placeUI()
end

function Unit:getInitAttribute()
    local attriTab, buff = FightData:getUnitBattleInitAttri(self.faction, self.heroInfo)
    return attriTab, buff
end

function Unit:initAttribute()
    local attriTab, selfBuff = self:getInitAttribute()
    self.baseAttriTab = clone(attriTab)
    self.baseBuff = selfBuff

    for k, buff in pairs(self.baseBuff) do
        self:addBuff(buff, self.uid, false, 0, LevelStateType.END_ROUND)
    end
    self.isNeedResetBuff = true

    attriTab = self:skillBuff(attriTab) or attriTab
    
    self.attribute.hp = attriTab[AttributeType.life]
    self.attribute.attack = attriTab[AttributeType.attack]
    self.attribute.offset = attriTab[AttributeType.offset]
    self.attribute.dodge = attriTab[AttributeType.dodge]
    self.attribute.crit = attriTab[AttributeType.crit]
    self.attribute.hurtInfantry = attriTab[AttributeType.hurtInfantry]
    self.attribute.hurtCavalry = attriTab[AttributeType.hurtCavalry]
    self.attribute.hurtArcher = attriTab[AttributeType.hurtArcher]
    self.attribute.hurtGunner = attriTab[AttributeType.hurtGunner]
    self.attribute.hurtHero = attriTab[AttributeType.hurtHero]
    self.attribute.hurtAll = attriTab[AttributeType.hurtAll]
    self.attribute.sufferInfantry = attriTab[AttributeType.sufferInfantry]
    self.attribute.sufferCavalry = attriTab[AttributeType.sufferCavalry]
    self.attribute.sufferArcher = attriTab[AttributeType.sufferArcher]
    self.attribute.sufferGunner = attriTab[AttributeType.sufferGunner]
    self.attribute.sufferHero = attriTab[AttributeType.sufferHero]
    self.attribute.sufferAll = attriTab[AttributeType.sufferAll]
    self.attribute.critDamage = attriTab[AttributeType.critDamage]
    
    self.addAttribute = calc.tableShallowCopy(self.attribute)
    self.orgAttribute = calc.tableShallowCopy(self.attribute)
end

function Unit:initBaseBuff()
    local buffList = FightData:getBuffList(self.faction)
    local attriTab = clone(self.baseAttriTab)

    self.finishInit = true
    for k, buff in pairs(buffList) do
        self:addBuff(buff, nil, false, 0, LevelStateType.END_ROUND)
    end

    self.isNeedResetBuff = true

    attriTab = self:skillBuff(attriTab) or attriTab
    
    self.attribute.hp = attriTab[AttributeType.life]
    self.attribute.attack = attriTab[AttributeType.attack]
    self.attribute.offset = attriTab[AttributeType.offset]
    self.attribute.dodge = attriTab[AttributeType.dodge]
    self.attribute.crit = attriTab[AttributeType.crit]
    self.attribute.hurtInfantry = attriTab[AttributeType.hurtInfantry]
    self.attribute.hurtCavalry = attriTab[AttributeType.hurtCavalry]
    self.attribute.hurtArcher = attriTab[AttributeType.hurtArcher]
    self.attribute.hurtGunner = attriTab[AttributeType.hurtGunner]
    self.attribute.hurtHero = attriTab[AttributeType.hurtHero]
    self.attribute.hurtAll = attriTab[AttributeType.hurtAll]
    self.attribute.sufferInfantry = attriTab[AttributeType.sufferInfantry]
    self.attribute.sufferCavalry = attriTab[AttributeType.sufferCavalry]
    self.attribute.sufferArcher = attriTab[AttributeType.sufferArcher]
    self.attribute.sufferGunner = attriTab[AttributeType.sufferGunner]
    self.attribute.sufferHero = attriTab[AttributeType.sufferHero]
    self.attribute.sufferAll = attriTab[AttributeType.sufferAll]
    self.attribute.critDamage = attriTab[AttributeType.critDamage]

    self.orgAttribute = calc.tableShallowCopy(self.attribute)
end

function Unit:saveBaseAttr()
    local attriTab = {}
    attriTab[AttributeType.life] = self.orgAttribute.hp
    attriTab[AttributeType.attack] = self.orgAttribute.attack
    attriTab[AttributeType.offset] = self.orgAttribute.offset
    attriTab[AttributeType.dodge] = self.orgAttribute.dodge
    attriTab[AttributeType.crit] = self.orgAttribute.crit
    attriTab[AttributeType.hurtInfantry] = self.orgAttribute.hurtInfantry
    attriTab[AttributeType.hurtCavalry] = self.orgAttribute.hurtCavalry
    attriTab[AttributeType.hurtArcher] = self.orgAttribute.hurtArcher
    attriTab[AttributeType.hurtGunner] = self.orgAttribute.hurtGunner
    attriTab[AttributeType.hurtHero] = self.orgAttribute.hurtHero
    attriTab[AttributeType.hurtAll] = self.orgAttribute.hurtAll
    attriTab[AttributeType.sufferInfantry] = self.orgAttribute.sufferInfantry
    attriTab[AttributeType.sufferCavalry] = self.orgAttribute.sufferCavalry
    attriTab[AttributeType.sufferArcher] = self.orgAttribute.sufferArcher
    attriTab[AttributeType.sufferGunner] = self.orgAttribute.sufferGunner
    attriTab[AttributeType.sufferHero] = self.orgAttribute.sufferHero
    attriTab[AttributeType.sufferAll] = self.orgAttribute.sufferAll
    attriTab[AttributeType.critDamage] = self.orgAttribute.critDamage
    
    attributeTable[tostring(self:getID())] = clone(attriTab)
end

function Unit:getAbilityByType(atype)
    local abi = 0
    if atype == AttributeType.life then
        abi = self.addAttribute.hp
    elseif atype == AttributeType.attack then
        abi = self.addAttribute.attack
    elseif atype == AttributeType.offset then
        abi = self.addAttribute.offset
    elseif atype == AttributeType.dodge then
        abi = self.addAttribute.dodge
    elseif atype == AttributeType.crit then
        abi = self.addAttribute.crit
    end

    return abi
end

function Unit:activeAura()
    self.skill:usePassiveSkill()
end

function Unit:usePassiveSkillToUnit(unit)
    self.skill:usePassiveSkillToUnit(unit)
end

function Unit:useActiveSkill()
    if self:checkCanUseSkill() then
        return self.skill:useActiveSkill()
    end
end

function Unit:useAddSkill()
    if self:checkCanUseSkill() then
        return self.skill:useAdditiveSkill()
    end
end

function Unit:addBuff(buff, senderID, isAura, skillId, levelState)
    local buffData = buffConf[buff]
    if buffData then
        if buffData.class == BuffClass.Equip then
            return
        end

        local sender
        if senderID then
            sender = MapManager:getUnitByID(senderID)
            if not sender then
                sender = MapManager:getDeadUnitByID(senderID)
            end
        end

        if buffData.addMore then
            local isNeedAdd = true
            local curCount = 0
            for ii, info in pairs(self.buffList) do
                local temp = info.buff
                if temp.Id == buff then
                    curCount = curCount + 1
                    if buffData.addMore <= curCount then
                        isNeedAdd = false
                        break
                    end
                end
            end

            if isNeedAdd then
                local temp = calc.tableShallowCopy(buffData)
                table.insert(self.buffList, {buff = temp, sender = sender, isActived = false, isAura = isAura, skillId = skillId,
                    endRound = (temp.round or 99), levelState = levelState})
                self.isNeedResetBuff = true
            end
        elseif buffData.replaceGroup and buffData.replaceLevel then
            local isHighest = true
            local key = 0
            for ii, info in pairs(self.buffList) do
                local temp = info.buff
                if temp and temp.replaceGroup and temp.replaceLevel then
                    if temp.replaceGroup == buffData.replaceGroup then
                        if temp.replaceLevel >= buffData.replaceLevel then
                            isHighest = false
                        end
                        
                        key = ii
                        break
                    end
                end
            end

            if isHighest then
                local temp = calc.tableShallowCopy(buffData)
                if key == 0 then
                    table.insert(self.buffList, {buff = temp, sender = sender, isActived = false, isAura = isAura, skillId = skillId, 
                        endRound = (temp.round or 99), levelState = levelState})
                else
                    self.buffList[key] = {buff = temp, sender = sender, isActived = false, isAura = isAura, skillId = skillId, 
                        endRound = (temp.round or 99), levelState = levelState}
                end
                self.isNeedResetBuff = true
            end
        else
            local key = 0
            for ii, info in pairs(self.buffList) do
                local temp = info.buff
                if temp.Id == buff then
                    key = ii
                    break
                end
            end

            local temp = calc.tableShallowCopy(buffData)
            if key == 0 then
                table.insert(self.buffList, {buff = temp, sender = sender, isActived = false, isAura = isAura, skillId = skillId, 
                    endRound = (temp.round or 99), levelState = levelState})
            else
                self.buffList[key] = {buff = temp, sender = sender, isActived = false, isAura = isAura, skillId = skillId, 
                    endRound = (temp.round or 99), levelState = levelState}
            end
            self.isNeedResetBuff = true
        end
    end
end

function Unit:removeAuraBySender(sender)
    for k, buff in pairs(self.buffList) do
        if buff.isAura and buff.sender and buff.sender:getID() == sender:getID() then
            self.buffList[k] = nil
            self.isNeedResetBuff = true
        end
    end
end

function Unit:skillBuff(_attriTab, _frame)
    if self.isNeedResetBuff then
        local orgHp = 1
        local frame = _frame or self.curFrame
        local attriTab = {}
        if _attriTab then
            attriTab = _attriTab
            orgHp = attriTab[AttributeType.life]
        else
            attriTab = clone(self.baseAttriTab)
            orgHp = self.orgAttribute.hp
        end
        
        local haveRevive = false
        local addSkillOdds = 0
        local immune = false
        local addHpList = {}
        local baseBuffTab = {}
        local baseBuffRatio = {}
        local buffTab = {}
        local buffRatio = {}
        local skillBuffTab = {}
        local skillBuffRatio = {}
        local extraBuffRatio = {}
        local finalBuffRatio = {}
        local addBuffList = {}
        local isForbidden = false
        for k, info in pairs(self.buffList) do
            local buffInfo = info.buff
            if not info.isActived then
                if buffInfo.addBuff then
                    if buffInfo.addBuffTarget then
                        local curLevelState = GameManager.levelHandler.curState
                        if buffInfo.addBuffTarget == 0 then
                            table.insert(addBuffList, {id = buffInfo.addBuff, sender = info.sender})
                        elseif buffInfo.addBuffTarget == 1 then
                            local units = MapManager:getAllUnit(self.faction)
                            for k, unit in pairs(units) do
                                unit:addBuff(buffInfo.addBuff, info.sender:getID(), false, info.skillId, curLevelState)
                            end
                        elseif buffInfo.addBuffTarget == 2 then
                            local units = MapManager:getAllUnit(self:getReverseFaction())
                            for k, unit in pairs(units) do
                                unit:addBuff(buffInfo.addBuff, info.sender:getID(), false, info.skillId, curLevelState)
                            end
                        end
                    else
                        table.insert(addBuffList, {id = buffInfo.addBuff, sender = info.sender})
                    end
                end
            else
                if buffInfo.specialEffect then
                    if buffInfo.specialEffect == SpecialEffectType.Immune then
                        immune = true
                    elseif buffInfo.specialEffect == SpecialEffectType.ForbiddenSkill or buffInfo.specialEffect == SpecialEffectType.ForbiddenAttack then
                        isForbidden = true
                    end
                end
            end
        end

        if immune then
            isForbidden = false
            local deleteList = {}
            for k, info in pairs(self.buffList) do
                local buffInfo = info.buff
                if buffInfo.specialEffect == SpecialEffectType.ForbiddenSkill or buffInfo.specialEffect == SpecialEffectType.ForbiddenAttack
                    or buffInfo.causeHurtRatioMax or buffInfo.causeHurtRatioNow then
                    table.insert(deleteList, k)
                end
            end

            for i,v in ipairs(deleteList) do
                self:recordBehavior(0, UnitBehaviorType.removeBuff, self.buffList[v].buff.Id)
                self.buffList[v] = nil
            end
        end

        if #addBuffList > 0 then
            local curLevelState = GameManager.levelHandler.curState
            for i, info in ipairs(addBuffList) do
                self:addBuff(info.id, info.sender:getID(), false, info.skillId, curLevelState)
            end
        end

        for k, info in pairs(self.buffList) do
            local buffInfo = info.buff
            local enable = true

            if FightData:getTeamType(self.faction) == "-1" then --竞技场
                if buffInfo.arena and buffInfo.arena == 1 then
                    enable = true
                else
                    enable = false
                end
            end

            if enable then
                if buffInfo.takeEffect then
                    for i, take in ipairs(buffInfo.takeEffect) do
                        if take == TakeEffectType.None then
                            enable = true
                            break
                        elseif take == TakeEffectType.Infantry and self.type == UnitType.INFANTRY then
                            enable = true
                            break
                        elseif take == TakeEffectType.Gunner and self.type == UnitType.GUNNER then
                            enable = true
                            break
                        elseif take == TakeEffectType.Archer and self.type == UnitType.ARCHER then
                            enable = true
                            break
                        elseif take == TakeEffectType.Cavalry and self.type == UnitType.CAVALRY then
                            enable = true
                            break
                        elseif take == TakeEffectType.InfantrySoldier and self.type == UnitType.INFANTRY and not self.heroInfo.isHero then
                            enable = true
                            break
                        elseif take == TakeEffectType.GunnerSoldier and self.type == UnitType.GUNNER and not self.heroInfo.isHero then
                            enable = true
                            break
                        elseif take == TakeEffectType.ArcherSoldier and self.type == UnitType.ARCHER and not self.heroInfo.isHero then
                            enable = true
                            break
                        elseif take == TakeEffectType.CavalrySoldier and self.type == UnitType.CAVALRY and not self.heroInfo.isHero then
                            enable = true
                            break
                        elseif take == TakeEffectType.InfantryHero and self.type == UnitType.INFANTRY and self.heroInfo.isHero then
                            enable = true
                            break
                        elseif take == TakeEffectType.GunnerHero and self.type == UnitType.GUNNER and self.heroInfo.isHero then
                            enable = true
                            break
                        elseif take == TakeEffectType.ArcherHero and self.type == UnitType.ARCHER and self.heroInfo.isHero then
                            enable = true
                            break
                        elseif take == TakeEffectType.CavalryHero and self.type == UnitType.CAVALRY and self.heroInfo.isHero then
                            enable = true
                            break
                        elseif take == TakeEffectType.Hero and self.heroInfo.isHero then
                            enable = true
                            break
                        elseif take == TakeEffectType.DeffenceTeam and FightData:getTeamType(self.faction) == "1" then
                            enable = true
                            break
                        elseif take == TakeEffectType.HelpeDeffence and FightData:getTeamType(self.faction) == "2" then
                            enable = true
                            break
                        elseif take == TakeEffectType.AttackTeam and FightData:getTeamType(self.faction) == "3" then
                            enable = true
                            break
                        elseif take == TakeEffectType.AttackGroup and FightData:getTeamType(self.faction) == "4" then
                            enable = true
                            break
                        elseif take == TakeEffectType.MonsterAttack and FightData:getTeamType(self.faction) == "5" then
                            enable = true
                            break
                        elseif take == TakeEffectType.BossAttack and FightData:getTeamType(self.faction) == "6" then
                            enable = true
                            break
                        elseif take == TakeEffectType.AttackBomb and FightData:getTeamType(self.faction) == "7" then
                            enable = true
                            break
                        elseif take == TakeEffectType.AttackCave and FightData:getTeamType(self.faction) == "8" then
                            enable = true
                            break
                        elseif take == TakeEffectType.AttackMilitary and FightData:getTeamType(self.faction) == "9" then
                            enable = true
                            break
                        elseif take == TakeEffectType.AttackSource and FightData:getTeamType(self.faction) == "10" then
                            enable = true
                            break
                        elseif take == TakeEffectType.Forbiddened and isForbidden then
                            enable = true
                            break
                        else
                            enable = false
                        end
                    end
                else
                    enable = true
                end

                if buffInfo.statueBuff and buffInfo.statueBuff == 1 and not FightData:canUseStatueBuff(self.faction) then
                    enable = false
                end
            end

            if buffInfo.specialEffect then
                if buffInfo.specialEffect == SpecialEffectType.ForbiddenSkill or buffInfo.specialEffect == SpecialEffectType.ForbiddenAttack then
                    if immune then
                        enable = false
                    end
                end
            end

            if buffInfo.causeHurtRatioMax or buffInfo.causeHurtRatioNow then
                if immune then
                    enable = false
                end
            end

            if buffInfo.class == BuffClass.Battle and not self.finishInit then
                enable = false
            end

            if enable then
                if not info.isActived then
                    self.buffList[k].isActived = true
                    if (buffInfo.addHpExtra or buffInfo.addTargetHpExtraRatio or buffInfo.addSelfHpExtraRatio) and not buffInfo.hp then
                        if buffInfo.addHpExtra then
                            buffInfo.hp = buffInfo.addHpExtra
                        elseif buffInfo.addTargetHpExtraRatio then
                            buffInfo.hp = math.floor(self.orgAttribute.hp * buffInfo.addTargetHpExtraRatio)
                        elseif buffInfo.addSelfHpExtraRatio and info.sender then
                            buffInfo.hp = math.floor(info.sender.orgAttribute.hp * buffInfo.addSelfHpExtraRatio)
                        end

                        if info.sender then
                            info.sender:addHealData(buffInfo.hp)
                        end
                    elseif buffInfo.beginTime == 0 and buffInfo.addHp or buffInfo.addSelfHpRatio or buffInfo.addTargetHpRatio then
                        local treatRatio = 0
                        if info.sender then
                            treatRatio = info.sender:getTreatRatio()
                        end
                        if buffInfo.addHp then
                            table.insert(addHpList, {sender = info.sender, addHp = buffInfo.addHp * (1 + treatRatio)})
                        elseif buffInfo.addTargetHpRatio then
                            table.insert(addHpList, {sender = info.sender, addHp = math.floor(self.orgAttribute.hp * buffInfo.addTargetHpRatio * (1 + treatRatio))})
                        elseif buffInfo.addSelfHpRatio and info.sender then
                            table.insert(addHpList, {sender = info.sender, addHp = math.floor(info.sender.orgAttribute.hp * buffInfo.addSelfHpRatio * (1 + treatRatio))})
                        end
                        buffInfo.beginTime = 1
                    elseif buffInfo.hitBuff and buffInfo.hitBuffRange and buffInfo.hitBuffOdds then
                        for iii, vvv in ipairs(buffInfo.hitBuff) do
                            self:addHitBuff({hitBuff = vvv, hitBuffRange = buffInfo.hitBuffRange[iii], hitBuffOdds = buffInfo.hitBuffOdds, skillId = info.skillId, comeFromBuff = true})
                        end
                    elseif buffInfo.revive and not self:isAlive() then
                        self:setAutoCleanup(false)
                        self.heroInfo.index = 1
                        self:setSummon(true)
                        self.state = UnitState.WAIT

                        self.revived = true
                        self.attribute.hp = 1
                        GameManager.levelHandler:reviveUnit(self)
                        self:doReviveBuff()

                        attriTab = self:skillBuff(_attriTab, _frame)

                        self.attribute.hp = self.orgAttribute.hp
                        attriTab[AttributeType.life] = self.orgAttribute.hp * buffInfo.revive

                        info.endRound = 0
                        haveRevive = true

                        if info.sender then
                            info.sender:addHealData(attriTab[AttributeType.life])
                        end
                    end

                    if buffInfo.remove then
                        self.buffList[k].lastCount = buffInfo.remove
                    end

                    if frame == 0 then
                        self:recordBehavior(0, UnitBehaviorType.activeBuff, {id = buffInfo.Id, sender = (info.sender and info.sender:getID())})
                    else
                        self:recordBehavior(frame, UnitBehaviorType.conditionBuff, {id = buffInfo.Id, sender = (info.sender and info.sender:getID())})
                    end

                    if haveRevive then
                        break
                    end
                end

                if buffInfo.addAbility then
                    if buffInfo.addAbility < 6 then
                        if info.skillId and info.skillId > 0 then
                            if not skillBuffTab[buffInfo.addAbility] then
                                skillBuffTab[buffInfo.addAbility] = 0
                            end

                            if not skillBuffRatio[buffInfo.addAbility] then
                                skillBuffRatio[buffInfo.addAbility] = 0
                            end

                            if not finalBuffRatio[buffInfo.addAbility] then
                                finalBuffRatio[buffInfo.addAbility] = 0
                            end

                            skillBuffTab[buffInfo.addAbility] = skillBuffTab[buffInfo.addAbility] + (buffInfo.addAbilityAbs or 0)
                            if buffInfo.addSelfAbilityRatio and info.sender then
                                skillBuffTab[buffInfo.addAbility] = skillBuffTab[buffInfo.addAbility] + info.sender:getAbilityByType(buffInfo.addAbility) * buffInfo.addSelfAbilityRatio
                            end

                            if buffInfo.addTargetAbilityRatioNow then
                                finalBuffRatio[buffInfo.addAbility] = finalBuffRatio[buffInfo.addAbility] + buffInfo.addTargetAbilityRatioNow
                            end

                            skillBuffRatio[buffInfo.addAbility] = skillBuffRatio[buffInfo.addAbility] + (buffInfo.addTargetAbilityRatio or 0)
                        else
                            if not buffTab[buffInfo.addAbility] then
                                buffTab[buffInfo.addAbility] = 0
                            end

                            if not buffRatio[buffInfo.addAbility] then
                                buffRatio[buffInfo.addAbility] = 0
                            end

                            if not finalBuffRatio[buffInfo.addAbility] then
                                finalBuffRatio[buffInfo.addAbility] = 0
                            end

                            buffTab[buffInfo.addAbility] = buffTab[buffInfo.addAbility] + (buffInfo.addAbilityAbs or 0)
                            if buffInfo.addSelfAbilityRatio and info.sender then
                                buffTab[buffInfo.addAbility] = buffTab[buffInfo.addAbility] + info.sender:getAbilityByType(buffInfo.addAbility) * buffInfo.addSelfAbilityRatio
                            end

                            if buffInfo.addTargetAbilityRatioNow then
                                finalBuffRatio[buffInfo.addAbility] = finalBuffRatio[buffInfo.addAbility] + buffInfo.addTargetAbilityRatioNow
                            end

                            buffRatio[buffInfo.addAbility] = buffRatio[buffInfo.addAbility] + (buffInfo.addTargetAbilityRatio or 0)
                        end
                    elseif buffInfo.addAbility > 100 then
                        local addAbility = buffInfo.addAbility % 100
                        if not baseBuffTab[addAbility] then
                            baseBuffTab[addAbility] = 0
                        end

                        if not baseBuffRatio[addAbility] then
                            baseBuffRatio[addAbility] = 0
                        end

                        baseBuffTab[addAbility] = baseBuffTab[addAbility] + (buffInfo.addAbilityAbs or 0)
                        if buffInfo.addSelfAbilityRatio and info.sender then
                            baseBuffTab[addAbility] = baseBuffTab[addAbility] + info.sender:getAbilityByType(addAbility) * buffInfo.addSelfAbilityRatio
                        end
                        baseBuffRatio[addAbility] = baseBuffRatio[addAbility] + (buffInfo.addTargetAbilityRatio or 0)
                    else
                        if not extraBuffRatio[buffInfo.addAbility] then
                            extraBuffRatio[buffInfo.addAbility] = 0
                        end

                        extraBuffRatio[buffInfo.addAbility] = extraBuffRatio[buffInfo.addAbility] + (buffInfo.addTargetAbilityRatio or 0)
                    end
                elseif buffInfo.specialEffect and buffInfo.specialEffect == SpecialEffectType.AddSkillOdds then
                    addSkillOdds = addSkillOdds + buffInfo.specialEffectValue
                end
            else
                if info.isActived then
                    info.isActived = false
                end
            end
        end

        if (skillBuffTab[AttributeType.attack] or 0) < -0.9 then
            skillBuffTab[AttributeType.attack] = -0.9
        end

        --buff属性加成分成3类
        --自身基础属性加成
        --科技等外来属性加成
        --技能属性加成
        --依次计算这三种属性加成
        for k,v in pairs(AttributeType) do
            attriTab[v] = (attriTab[v] or 0) * ((baseBuffRatio[v] or 0) + 1) + (baseBuffTab[v] or 0) -- 基础
            attriTab[v] = (attriTab[v] or 0) * ((buffRatio[v] or 0) + 1) + (buffTab[v] or 0) -- 加成
            attriTab[v] = (attriTab[v] or 0) * ((skillBuffRatio[v] or 0) + 1) + (skillBuffTab[v] or 0) -- 技能加成
        end

        --最后的加成
        for k,v in pairs(AttributeType) do
            attriTab[v] = (attriTab[v] or 0) * ((finalBuffRatio[v] or 0) + 1)
        end

        for k,v in pairs(AttributeType) do
            attriTab[v] = (attriTab[v] or 0) + (extraBuffRatio[v] or 0)
        end

        --增加装备的属性
        if self.finishInit then
            for i,v in ipairs(self.equipList) do
                local equipAttr = v:getAttr()
                for k,v in pairs(AttributeType) do
                    attriTab[v] = (attriTab[v] or 0) + (equipAttr[v] or 0)
                end
            end
        end

        if attriTab[AttributeType.dodge] > 90 then
            attriTab[AttributeType.dodge] = 90
        end

        self.attribute.hp = self.attribute.hp * attriTab[AttributeType.life] / orgHp
        self.attribute.attack = attriTab[AttributeType.attack]
        self.attribute.offset = attriTab[AttributeType.offset]
        self.attribute.dodge = attriTab[AttributeType.dodge]
        self.attribute.crit = attriTab[AttributeType.crit]
        self.attribute.hurtAll = attriTab[AttributeType.hurtAll]
        self.attribute.hurtInfantry = attriTab[AttributeType.hurtInfantry]
        self.attribute.hurtGunner = attriTab[AttributeType.hurtGunner]
        self.attribute.hurtArcher = attriTab[AttributeType.hurtArcher]
        self.attribute.hurtCavalry = attriTab[AttributeType.hurtCavalry]
        self.attribute.hurtHero = attriTab[AttributeType.hurtHero]
        self.attribute.sufferAll = attriTab[AttributeType.sufferAll]
        self.attribute.sufferInfantry = attriTab[AttributeType.sufferInfantry]
        self.attribute.sufferGunner = attriTab[AttributeType.sufferGunner]
        self.attribute.sufferArcher = attriTab[AttributeType.sufferArcher]
        self.attribute.sufferCavalry = attriTab[AttributeType.sufferCavalry]
        self.attribute.sufferHero = attriTab[AttributeType.sufferHero]
        self.attribute.critDamage = attriTab[AttributeType.critDamage]
        self.attribute.resistanceInfantry = attriTab[AttributeType.resistanceInfantry]
        self.attribute.resistanceGunner = attriTab[AttributeType.resistanceGunner]
        self.attribute.resistanceArcher = attriTab[AttributeType.resistanceArcher]
        self.attribute.resistanceCavalry = attriTab[AttributeType.resistanceCavalry]

        for i,v in ipairs(addHpList) do
            local lasthp = self.attribute.hp
            self.attribute.hp = v.addHp + self.attribute.hp
            if self.attribute.hp > self.orgAttribute.hp then
                self.attribute.hp = self.orgAttribute.hp
            elseif self.attribute.hp < 1 then
                self.attribute.hp = 1
            end

            local heal = self.attribute.hp - lasthp
            if v.sender and heal > 0 then
                v.sender:addHealData(heal)
            end
        end

        if self.attribute.hp > self.orgAttribute.hp then
            self.attribute.hp = self.orgAttribute.hp
        elseif self.attribute.hp < 1 then
            self.attribute.hp = 1
        end

        self.addSkillOdds = addSkillOdds

        if haveRevive then
            self:recordBehavior(0, UnitBehaviorType.revive, self.attribute.hp)
        end

        self.isNeedResetBuff = false

        return attriTab
    end
end

function Unit:doReviveBuff()
    self:activeAura()

    local units = MapManager:getUnitMap()
    for k, unit in pairs(units) do
        if unit:getID() ~= self:getID() then
            unit:usePassiveSkillToUnit(self)
        end
    end

    for k, buff in pairs(self.baseBuff) do
        self:addBuff(buff, self.uid)
    end

    local buffList = FightData:getBuffList(self.faction)
    for k, buff in pairs(buffList) do
        self:addBuff(buff, self.uid)
    end

    for k, unit in pairs(units) do
        if unit:getID() ~= self:getID() then
            unit:skillBuff()
        end
    end
end

function Unit:updateDot()
    for k, info in pairs(self.buffList) do
        if info.isActived then
            local buff = info.buff
            if buff.causeHurtAbs or buff.causeHurtRatioMax or buff.causeHurtRatioNow then
                local damageCount = 0
                if buff.causeHurtAbs then
                    damageCount = buff.causeHurtAbs
                elseif buff.causeHurtRatioMax then
                    damageCount = buff.causeHurtRatioMax * self:getMaxHp()
                elseif buff.causeHurtRatioNow then
                    damageCount = buff.causeHurtRatioNow * self:getHp()
                end

                damageCount = math.floor(damageCount)

                if damageCount > 0 then
                    local lasthp = self:getHp()
                    local curHp = lasthp - damageCount

                    if curHp <= 0 then
                        curHp = 0
                    end
                    
                    self:setHpValue(curHp, 1)

                    local realDamage = lasthp - curHp
                    if realDamage > 0 then
                        if info.sender then
                            info.sender:addDamageData(realDamage, self:isHero())
                        end

                        self:addHurtData(realDamage)
                    end

                    local behavior = {damageCount, 0, 0}
                    self:recordBehavior(1, UnitBehaviorType.reduceHp, behavior)
                    
                    if curHp <= 0 then
                        self:transformNormalState(UnitState.DIE, 1)
                        return
                    end
                end
            elseif buff.addHp or buff.addSelfHpRatio or buff.addTargetHpRatio then
                if (not buff.beginTime) or buff.beginTime == 0 then
                    local treatRatio = 0
                    if info.sender then
                        treatRatio = info.sender:getTreatRatio()
                    end
                    local addHp = 0
                    if buff.addHp then
                        addHp = addHp + buff.addHp * (1 + treatRatio)
                    elseif buff.addTargetHpRatio then
                        addHp = addHp + math.floor(self.orgAttribute.hp * (buff.addTargetHpRatio + treatRatio))
                    elseif buff.addSelfHpRatio and info.sender then
                        addHp = addHp + math.floor(info.sender.orgAttribute.hp * (buff.addSelfHpRatio + treatRatio))
                    end

                    if addHp > 0 then
                        local lasthp = self:getHp()
                        local curHp = lasthp + addHp
                        if curHp > self.orgAttribute.hp then
                            curHp = self.orgAttribute.hp
                        end
                        self:setHpValue(curHp, 1)

                        local heal = curHp - lasthp
                        if info.sender and heal > 0 then
                            info.sender:addHealData(heal)
                        end

                        local behavior = {addHp * -1, 0, 0}
                        self:recordBehavior(1, UnitBehaviorType.reduceHp, behavior)
                    end
                else
                    buff.beginTime = buff.beginTime - 1
                end
            end
        end
    end
end

function Unit:updateAddRoundBuff()
    local curLevelState = GameManager.levelHandler.curState
    for k, info in pairs(self.buffList) do
        if info.endRound > 0 and info.isActived then
            local buff = info.buff
            if buff.addBuffRound then
                if buff.addBuffTarget then
                    if buff.addBuffTarget == 0 then
                        self:addBuff(buff.addBuffRound, info.sender and info.sender:getID(), false, info.skillId, curLevelState)
                    elseif buff.addBuffTarget == 1 then
                        local units = MapManager:getAllUnit(self.faction)
                        for k, unit in pairs(units) do
                            unit:addBuff(buff.addBuffRound, info.sender and info.sender:getID(), false, info.skillId, curLevelState)
                        end
                    elseif buff.addBuffTarget == 2 then
                        local units = MapManager:getAllUnit(self:getReverseFaction())
                        for k, unit in pairs(units) do
                            unit:addBuff(buff.addBuffRound, info.sender and info.sender:getID(), false, info.skillId, curLevelState)
                        end
                    end
                else
                    self:addBuff(buff.addBuffRound, info.sender and info.sender:getID(), false, info.skillId, curLevelState)
                end
            end
        end
    end
end

function Unit:updateActiveBuff(levelState)
    local deleteList = {}
    for k, info in pairs(self.buffList) do
        if info.levelState and info.levelState == levelState then
            info.endRound = info.endRound - 1
            if info.endRound <= 0 then
                local buff = info.buff
                if buff.extraHpId then
                    for i, info in ipairs(self.extraHp) do
                        if info.id == buff.extraHpId then
                            table.remove(self.extraHp, i)
                            break
                        end
                    end
                end
                table.insert(deleteList, k)
                self.isNeedResetBuff = true
            end
        end
    end

    for i,v in ipairs(deleteList) do
        self:recordBehavior(0, UnitBehaviorType.removeBuff, self.buffList[v].buff.Id)
        self.buffList[v] = nil
    end
end

function Unit:reduceBuffLastCount(frame)
    local deleteList = {}
    for k, info in pairs(self.buffList) do
        if info.lastCount then
            if info.lastCount == -1 then
            else
                info.lastCount = info.lastCount - 1
                if info.lastCount <= 0 then
                    table.insert(deleteList, k)
                    self.isNeedResetBuff = true
                end
            end
        end
    end

    for i,v in ipairs(deleteList) do
        self:recordBehavior(frame or self.curFrame or 0, UnitBehaviorType.removeBuff, self.buffList[v].buff.Id)
        self.buffList[v] = nil
    end

    self:skillBuff()
end

function Unit:removeLastCountBuff(frame)
    local deleteList = {}
    for k, info in pairs(self.buffList) do
        if info.lastCount then
            if info.lastCount == -1 then
                table.insert(deleteList, k)
                self.isNeedResetBuff = true
            end
        end
    end

    for i,v in ipairs(deleteList) do
        self:recordBehavior(frame or self.curFrame or 0, UnitBehaviorType.removeBuff, self.buffList[v].buff.Id)
        self.buffList[v] = nil
    end

    self:skillBuff()
end

function Unit:useConditionSkill()
    return self.skill:useConditionSkill()
end

function Unit:addHitBuff(info)
    table.insert(self.hitBuffList, info)
end

function Unit:addKillBuff(info)
    table.insert(self.killBuffList, info)
end

function Unit:addChangeBuff(info)
    table.insert(self.changeBuffList, info)
end

function Unit:triggerChangeBuff(changeType, frame)
    if self:isAlive() then
        for i, info in ipairs(self.changeBuffList) do
            if changeType == info.changeType then
                if MyRandom:random(1, 1000) <= (info.changeBuffOdds * 1000) then
                    local curLevelState = GameManager.levelHandler.curState
                    local unitList = MapManager:getUnitsByRange(self, info.changeBuffRange)
                    for i,unit in ipairs(unitList) do
                        unit:addBuff(info.changeBuff, self:getID(), false, info.skillId, curLevelState)
                        unit:skillBuff(nil, frame)
                    end
                end
            end
        end
    end
end

function Unit:triggerBuff(target, frame)
    if target and self:isAlive() then
        local curLevelState = GameManager.levelHandler.curState
        if target:isAlive() then
            for i = #self.hitBuffList, 1, -1 do
                local info = self.hitBuffList[i]
                if info.hitBuffRange <= 0 then
                    if MyRandom:random(1, 1000) <= (info.hitBuffOdds * 1000) then
                        target:addBuff(info.hitBuff, self.uid, false, info.skillId, curLevelState)
                        target:skillBuff(nil, frame)
                    end
                elseif info.hitBuffRange > 0 then
                    if MyRandom:random(1, 1000) <= (info.hitBuffOdds * 1000) then
                        target:addBuff(info.hitBuff, self.uid, false, info.skillId, curLevelState)
                        target:skillBuff(nil, frame)
                        info.hitBuffRange = info.hitBuffRange - 1
                        if info.hitBuffRange <= 0 then
                            table.remove(self.hitBuffList, i)
                        end
                    end
                end
            end
        else
            for i, info in ipairs(self.killBuffList) do
                if MyRandom:random(1, 1000) <= (info.killBuffOdds * 1000) then
                    local unitList = MapManager:getUnitsByRange(self, info.killBuffRange)
                    for ii, unit in ipairs(unitList) do
                        unit:addBuff(info.killBuff, self.uid, false, info.skillId, curLevelState)
                        unit:skillBuff(nil, frame)
                        self:recordBehavior(frame, UnitBehaviorType.removeBuff, info.killBuff)
                        self.buffList[info.killBuff] = nil
                    end
                end
            end
        end
    end
end

function Unit:triggerHackedBuff(target, frame)
    if target and target:isAlive() and self:isAlive() then
        local curLevelState = GameManager.levelHandler.curState
        for i,info in pairs(self.buffList) do
            if info.isActived and info.buff.hackedBuff then
                target:addBuff(info.buff.hackedBuff, self.uid, false, info.skillId, curLevelState)
                target:skillBuff(nil, frame)
            end
        end
    end
end

function Unit:resetHitBuff()
    local count = #self.hitBuffList
    for i = count, 1, -1 do
        local info = self.hitBuffList[i]
        if info.comeFromBuff then
        else
            table.remove(self.hitBuffList, i)
        end
    end
end

function Unit:getAddSkillOdds()
    return self.addSkillOdds * 1000
end

function Unit:checkCanUseSkill()
    local canUse = true
    local seal = false
    local unseal = false
    local immune = false
    for i, info in pairs(self.buffList) do
        if info.isActived then
            if info.buff.specialEffect == SpecialEffectType.Seal then
                seal = true
            elseif info.buff.specialEffect == SpecialEffectType.Unseal then
                unseal = true
            elseif info.buff.specialEffect == SpecialEffectType.Immune then
                immune = true
            end
        end
    end

    if immune then
        return canUse
    end

    if unseal or not seal then
        for i, info in pairs(self.buffList) do
            if info.isActived and (info.buff.specialEffect == SpecialEffectType.ForbiddenSkill 
                or info.buff.specialEffect == SpecialEffectType.ForbiddenAttack) then
                canUse = false
                break
            end
        end
    else
        canUse = false
    end

    return canUse
end

function Unit:checkCanAttack()
    local canUse = true
    local immune = false
    for i, info in pairs(self.buffList) do
        if info.isActived and info.buff.specialEffect == SpecialEffectType.Immune then
            immune = true
        end
    end

    if immune then
        return canUse
    end

    for i,info in pairs(self.buffList) do
        if info.isActived and info.buff.specialEffect == SpecialEffectType.ForbiddenAttack then
            canUse = false
            break
        end
    end

    return canUse
end

function Unit:getExtraHit()
    local extra = 0
    for i,info in pairs(self.buffList) do
        if info.isActived and info.buff.specialEffect == SpecialEffectType.Hit then
            extra = extra + 1000
        end
    end

    return extra
end

function Unit:getExtraNoBlock()
    local extra = 0
    for i,info in pairs(self.buffList) do
        if info.isActived and info.buff.specialEffect == SpecialEffectType.NoBlock then
            extra = extra + 1000
        end
    end

    return extra
end

function Unit:getHurtBack(isLongRange)
    local extra = 0
    for i,info in pairs(self.buffList) do
        if info.isActived and info.buff.preHurtBack and info.buff.preHurtBack ~= 0 then
            if isLongRange and info.buff.preHurtBack == 2 then
                extra = extra + info.buff.hurtBackRatio
            elseif not isLongRange and info.buff.preHurtBack == 1 then
                extra = extra + info.buff.hurtBackRatio
            end
        end
    end

    return extra
end

function Unit:suckBlood(damage, frame)
    for i, info in pairs(self.buffList) do
        if info.isActived and info.buff.hurtRenewTarget and info.buff.hurtRenewTargetRatio then
            local targetList = MapManager:getUnitsByRange(self, info.buff.hurtRenewTarget)
            for i, unit in ipairs(targetList) do
                unit:healHP(damage * info.buff.hurtRenewTargetRatio, frame, self)
            end
        end
    end
end

function Unit:getTreatRatio()
    local treatRatio = 0
    for i, info in pairs(self.buffList) do
        if info.isActived and info.buff.treatRatio then
            treatRatio = treatRatio + info.buff.treatRatio
        end
    end

    return treatRatio
end

function Unit:getShareHurt()
    for i, info in pairs(self.buffList) do
        if info.isActived and info.buff.shareHurt and info.buff.shareHurt > 0 then
            return info.buff.shareHurt
        end
    end

    return 0
end

function Unit:additionalAttribute(owner)
end

function Unit:initSkill()
    self.skill = UnitSkill.create(self)
end

function Unit:setSummon(summon)
    self.summon = summon
end

function Unit:isSummon()
    return self.summon
end

function Unit:setOwnerID(uid)
    self.ownerID = uid
end

function Unit:getOwnerID()
    return self.ownerID
end

function Unit:isHero()
    return self.heroInfo.isHero
end

function Unit:isReplaced()
    return self.heroInfo.isReplaced
end

function Unit:isRevived()
    return self.revived
end

function Unit:getID()
    return self.uid
end

function Unit:getTargetID()
    return self.targetID
end

function Unit:getType()
    return self.type
end

function Unit:setHide(hide)
    self.hide = hide
end

function Unit:isHide()
    return self.hide == true
end

function Unit:cleanup()
    self:setVisible(false)
    self:setVisible(false, true)
    self:setFrame(0)
end

function Unit:needCleanup()
    return self.autoCleanup
end

function Unit:setAutoCleanup(autoCleanup)
    self.autoCleanup = autoCleanup
end

function Unit:getTypeName()
    return nameList[self.type]
end

function Unit:getHeroName()
    if self.heroInfo.isMonster then
        return monsterConf[self.heroInfo.heroID].picture
    elseif self.heroInfo.isHero then
        return heroConf[self.heroInfo.heroID].picture
    else
        return monsterConf[self.heroInfo.heroID].picture
    end
end

function Unit:createHeroAnimation()
    -- local path = "spine/actors/" .. self:getHeroName()
    if skillActionTimeConf[self:getHeroName()] then
        self.anim = AnimReplacer.new(self:getHeroName(), self)
    else
        self.anim = AnimReplacer.new(self:getTypeName(), self)
    end
    self:registerEventHandler(self.anim)
    self:playAnimation("idle", true)
end

function Unit:playAnimation(name, loop)
    if loop == nil then
        loop = false
    end

    if name == nil then
        name = "atk"
    end

    self.anim:clearTracks()

    self.anim:setAnimation(0, name, loop)

    self.isComplete = false
end

function Unit:getTargetPtr()
    if self.targetPtr and self.targetPtr.state ~= UnitState.DIE then
        return self.targetPtr
    end

    self.targetPtr = nil
    self.targetID = 0
    return nil
end

function Unit:setLocation(location, frame)
    if self.location and self.location.x == location.x and self.location.y == location.y then
        return
    end

    local frame = frame or 0
    self.location.x = location.x
    self.location.y = location.y

    self:recordBehavior(frame, UnitBehaviorType.location, {math.floor(self.location.x * 10) / 10, math.floor(self.location.y * 10) / 10, self.indexInMatrix})
end

function Unit:getLocation()
    if not self.curLocation then
        self.curLocation = cc.p(self.location.x, self.location.y)
    else
        if self.curLocation.x ~= self.location.x then
            self.curLocation.x = self.location.x
        end
        if self.curLocation.y ~= self.location.y then
            self.curLocation.y = self.location.y
        end
    end

    return self.curLocation
end

function Unit:setLineLocation(location)
    self.lineLocation.x = location.x
    self.lineLocation.y = location.y
end

function Unit:getLineLocation()
    return self.lineLocation
end

function Unit:getContentSize()
    local pos = self:getLocation()
    return cc.rect(pos.x - 50, pos.y - 50, 150, 150)
end

function Unit:getHeadLocation()
    local offsetLoc = self.anim:getBonePosition("hp_point")

    return {x = offsetLoc.x + self.location.x, y = offsetLoc.y + self.location.y}
end

function Unit:getHitLocation()
    local offsetLoc = self.anim:getBonePosition("hit_point")

	return {x = offsetLoc.x + self.location.x, y = offsetLoc.y + self.location.y}-- {x = self.location.x, y = self.location.y + 60}
end

function Unit:getBulletLocation()
    local offsetLoc = self.anim:getBonePosition("bullet")
    if not offsetLoc then
        offsetLoc = self.anim:getBonePosition("hit_point")
    end

    return {x = offsetLoc.x + self.location.x, y = offsetLoc.y + self.location.y}-- {x = self.location.x, y = self.location.y + 60}
end

function Unit:getPosition()
	return self.location.x, self.location.y
end

function Unit:setVisible(isVisible, isRight)
end

function Unit:setFront(front)
    self.front = front

    if front then
        front.behind = self
    end
end

function Unit:isAlive()
    return self.state ~= UnitState.DIE and self.attribute.hp > 0
end

function Unit:isFinish()
    return self.state ~= UnitState.ATTACK and self.state ~= UnitState.PRE_ATTACK and self.isComplete
end

function Unit:isHitEnabled()
    return true
end

function Unit:setFaction(faction)
	self.faction = faction
end

function Unit:getFaction()
	return self.faction
end

function Unit:getHeroInfo()
    return self.heroInfo
end

function Unit:getHeroID()
    return self.heroInfo.heroID or 0
end

function Unit:getHeroQuality()
    if self.heroInfo.isMonster then
        return monsterConf[self.heroInfo.heroID].quality
    elseif self.heroInfo.isHero then
        return heroConf[self.heroInfo.heroID].quality
    else
        return 0
    end
end

function Unit:setIndexInMatrix(index)
    self.indexInMatrix = index
    self.realIndexInMatrix = self.indexInMatrix
end

function Unit:getIndexInMatrix()
    return self.indexInMatrix
end

function Unit:getRealIndexInMatrix()
    return self.realIndexInMatrix
end

function Unit:getLineIndex()
    local index = self.indexInMatrix % MaxUnitInLine
    if index == 0 then
        index = 5
    end

    return index
end

function Unit:getRowIndex()
    local index = math.ceil(self.indexInMatrix / MaxUnitInLine)
    if index == 0 then
        index = 5
    end

    return index
end

function Unit:getRealLineIndex()
    local index = self.realIndexInMatrix % MaxUnitInLine
    if index == 0 then
        index = 5
    end

    return index
end

function Unit:getReverseFaction()
    return MapManager:getReverseFaction(self:getFaction())
end

function Unit:startFight(frame)
    if not self:isAlive() then
        return
    end
    
    self.isInGuard = false
end

function Unit:closeFighting(frame)
    if self:getType() == UnitType.CAVALRY then
        self:playAnimation("atk")
    elseif self:getType() == UnitType.BOSS then
        self:playAnimation("atknear")
    else
        self:playAnimation("atk2")
    end

    self:setFrame(frame)
    self:recordBehavior(frame, UnitBehaviorType.state, UnitState.ATTACK)
end

function Unit:startWait(frame)
    self:setFrame(frame)
    self.curSkillData = nil
    self.isInGuard = false
    self.isComplete = true
    self.attackTimes = 0
    self.targetPtr = nil
    self.targetID = 0
end

function Unit:startGuard()
    self.isInGuard = true
end

function Unit:changeTarget(target)
    self.targetPtr = target
    self.targetID = target:getID()
end

function Unit:useSkillEnabled(skillID)
    if not self.skill:useEnabled(skillID) then
        return false
    end
    return true
end

function Unit:useSkill(skillID)
    local skillData = skillConf[skillID]
    if skillData then
        self.skill:useSkill(skillID)
        self:playAnimation(skillData.act)
        self:recordBehavior(self.curFrame, UnitBehaviorType.useSkill, skillID)
        self.curSkillData = skillData
    end
end

function Unit:checkAttackCD()
	return self.attackElapsed >= self.attribute.rate
end

function Unit:resetAttackCD()
    self.attackElapsed = 0
end

function Unit:onEventComplete(event)
    self.isComplete = true
end

function Unit:registerEventHandler(anim)
-- "event" table[5]    
--     ["animation"]   "attack"    
--     ["eventData"]   table[4]    
--         ["floatValue"]  0   
--         ["intValue"]    1   
--         ["name"]    "trigger"   
--         ["stringValue"] ""  
--     ["loopCount"]   0   
--     ["trackIndex"]  1   
--     ["type"]    "event" 

    anim:registerSpineEventHandler(function (event)
        self:onEventComplete(event)
    end, cc.SP_ANIMATION_COMPLETE)

    anim:registerSpineEventHandler(function (event)
        table.insert(self.eventsVec, event)
    end, cc.SP_ANIMATION_EVENT)
end

function Unit:handleEvent(event)
    if string.sub(event.name,1,7) == "trigger" then--and (not GameManager:isInPVP()) then
        if self.curSkillData then
            self:doUseSkill(event, self.skill:getCurrentSkillIndex())
        else
            self:doAttack(event)
        end
    else
        event.faction = self:getFaction()
        event.uid = self:getID()
        GameManager:pushEvent(event)
    end
end

function Unit:doAttack(event)
    local bullet = Bullet.create()
    self:setBulletAttribute(bullet, event)
end

function Unit:doUseSkill(event, skillIndex)
end

function Unit:doSkillEffect(event, skillIndex)
    
end

function Unit:updateEvents()
	local eventsVec = self.eventsVec
    self.eventsVec = {}
    while table.nums(eventsVec) > 0 do
        for key, var in ipairs(eventsVec) do
            self:handleEvent(var)
		end
        eventsVec = self.eventsVec
	end
end

function Unit:updateSkillElapsed(outerTick)
    local skillTicks = outerTick or self.ticks
    self.skill:update(skillTicks)
end

function Unit:updateAttackElapsed(outerTick)
    if self.state == UnitState.STAND or self.state == UnitState.WALK  or self.state == UnitState.CLOSE_TO  then
        local attackTicks = self.ticks
        self.attackElapsed = outerTick and (self:checkAttackCD() and self.attribute.rate or self.attackElapsed) + outerTick or self.attackElapsed + attackTicks
    end
end

function Unit:searchTarget()
    if self.state ~= UnitState.DIE then
        local location = {x = self.location.x, y = self.location.y}
        if self.faction == UnitFaction.LEFT then
            location.x = location.x + 1
        else
            location.x = location.x - 1
        end
        local target = MapManager:getUnitAt(location, self:getReverseFaction())
        if target then
            self:changeTarget(target)
            self.state = UnitState.ATTACK
        else
            local front = MapManager:getUnitAt(location, self.faction)
            if not front then
                self.targetLocation.x = location.x
                self.targetLocation.y = location.y
                self.state = UnitState.WALK
            else
                self.state = UnitState.STAND
            end
        end
    end
end

function Unit:update()
    self.anim:update()
    self:updateEvents()
    if self:needCleanup() or self.state == UnitState.WAIT then
    	return
    end

	if self.state == UnitState.WALK then
        self:handleWalk()
    elseif self.state == UnitState.ATTACK then
        self:handleAttack()
    elseif self.state == UnitState.USE_SKILL then
        self:handleUseSkill()
    elseif self.state == UnitState.DIE then
        self:handleDie()
	end
end

function Unit:handleWalk()
    self:setLocation(self.targetLocation)
end

function Unit:handleAttack()
    local event = {floatValue = 0, intValue = 1, name = "trigger", stringValue = ""}
    local bullet = Bullet.create()
    self:setBulletAttribute(bullet, event)
end

function Unit:handleUseSkill()
    local event = {floatValue = 0, intValue = 1, name = "trigger", stringValue = ""}
    local bullet = Bullet.create()
    self:setBulletAttribute(bullet, event)
end

function Unit:handleDie()
    self:setAutoCleanup(true)
end

function Unit:setFlipX(flipX)
	self.anim:setFlipX(flipX)
end

function Unit:isFlipX()
	return self.anim:isFlipX()
end

function Unit:getSignX()
	return (self:isFlipX() and true) or false
end

function Unit:getRectType()
    return (self:isFlipX() and RangeType.RECT_LEFT) or RangeType.RECT_RIGHT
end

function Unit:transformNormalState(newState, frame)
    if newState == self.state and newState ~= UnitState.USE_SKILL then
    	return
    end

    self.state = newState
    self:recordBehavior(frame, UnitBehaviorType.state, newState)
    
    if self.state == UnitState.DIE then
        self:toDie(frame)
    elseif self.state == UnitState.STAND then
        self:toStand()
    elseif self.state == UnitState.WALK then
        self:toWalk()
    elseif self.state == UnitState.ATTACK then--and (not GameManager:isInPVP()) then
        self:toAttack()
    elseif self.state == UnitState.USE_SKILL then--and (not GameManager:isInPVP()) then
        --self:newLockID()
        --self.anim:setTag(self:getLockID())
        self:toUseSkill()
    elseif self.state == UnitState.WINER then
        self:toWiner()
    elseif self.state == UnitState.WAIT then
        self:toWait()
    end
end

function Unit:getStateAnimationName()
    return self.stateAnimName[self.state]
end

function Unit:toBirth()    
    self:setHide(true)
end

function Unit:toDie(frame)
    self:clearShader()
    --self:clearAllCoexistState()
    -- self:playCurSound("die")

    self.targetPtr = nil
    self.targetID = 0
    self.buffList = {}
    self.killBuffList = {}
    self.hitBuffList = {}
    self.changeBuffList = {}
    self:skillBuff()
    self:cleanDieHeroCount()
    
    GameManager:handleUnitDead(self, frame)
    
    if self.behind then
        if self.isGuard then
            self.behind.realIndexInMatrix = self.indexInMatrix
        end
        self.behind.front = nil
        self.behind = nil
    end
end

function Unit:toStand()
    self:playAnimation(self:getStateAnimationName(), true)
end

function Unit:toWalk()
    self:playAnimation(self:getStateAnimationName(), true)
end

function Unit:toAttack()
    self:playAnimation(self:getStateAnimationName())
end

function Unit:toPreAttack()
    if self.targetPtr then
    	if self:needPursue() then
            self:transformNormalState(UnitState.CLOSE_TO)
    	elseif self:checkAttackCD() and not self.front then
            self:resetAttackCD()
            self:transformNormalState(UnitState.ATTACK)
        else
            self:transformNormalState(UnitState.STAND)
    	end
    else
        self:transformNormalState(UnitState.STAND);
    end
end

function Unit:toUseSkill()
    self:playAnimation(self.skill:getCurrentSkillAnimName())
    self:playCurSound(self.skill:getCurrentSkillSound())
    self:clearHeroActEffectAnim()
    --local index = 0
    local skillMark = string.sub(self.skill:getCurrentSkillAnimName(), -1)

   -- while true do 
    local sourceName = self:getHeroName() .. "_" .. skillMark .. "_anim"

    --print("Unit:toUseSkill()", sourceName, ResMgr.spinePath[sourceName])
    if ResMgr.spinePath[sourceName] then
    --print("Unit:toUseSkill()") 
        self:createHeroActEffectAnim(sourceName)
    end
   --end
   self:createUseSkillEffect()

   if self.contraller then
        self.contraller:notifyAttack()
    end
end

function Unit:toWiner()
    self:playAnimation(self:getStateAnimationName(), true)
end

function Unit:toWait()
    self:playAnimation(self:getStateAnimationName(), true)
end

function Unit:toWaveEnter()
end

function Unit:needPursue()
    if not self.targetPtr then
        return false
    end

    local selfPos = self:getLocation()
    local targetLocationX = self.targetPtr:getLocation().x
    if self.front then
        targetLocationX = self.front:getLocation().x
    end

    if math.abs(selfPos.x - targetLocationX) <= UnitSpace then
        return false
    end

    local fact = 1
    if selfPos.x < targetLocationX then
        fact = -1
    end

    self.targetLocation = cc.p(targetLocationX + UnitSpace * fact, selfPos.y)

    return true
end

function Unit:skillNeedPursue()
    if not self.targetPtr then 
        return true
    end

    local attribute = self.attribute
    local targetLocation = self.targetPtr.location
    local rangeY = 1000
    if targetLocation.x < self.location.x then
        self.skillUseRect.x = targetLocation.x
        --rect = cc.rect(targetLocation.x,targetLocation.y - rangeY, self.attribute.maxRange - self.attribute.minRange,rangeY + rangeY)
    else
        self.skillUseRect.x = targetLocation.x - attribute.maxRange
        --rect = cc.rect(targetLocation.x - self.attribute.maxRange + self.attribute.minRange,targetLocation.y - rangeY, self.attribute.maxRange - self.attribute.minRange,rangeY + rangeY)
    end

    self.skillUseRect.y = targetLocation.y - rangeY
    self.skillUseRect.width = attribute.maxRange
    self.skillUseRect.height = rangeY + rangeY
    
    if cc.rectContainsPoint(self.skillUseRect, self.location) then
        return false
    end

    return true
end

function Unit:reduceHP(damageCount, extraDamage, senderInfo, senderType, isCrit, isGuard, frame, sender)
    if self:isAlive() then
        local reduce = 0
        local frame = frame or 0
        local randValue = MyRandom:random(-100, 100) * globalConf[1].hurtRandom / 10000 + 1 --GameManager:isInPVP() and 1 or

        damageCount = (damageCount + extraDamage + self:getExtraDamage(damageCount, senderInfo, senderType)) * randValue
        if damageCount > 0 then
            damageCount = self:onReduceHp(damageCount, frame, sender)
        end

        -- print("Unit:reduceHP :", self:getID(), damageCount)
        if damageCount > 0 then
            damageCount = damageCount + self:resistanceDamage(damageCount, senderType)
            damageCount = math.floor(damageCount)
            local lasthp = self:getHp()
            local curHp = lasthp - damageCount

            if curHp <= 0 then
                curHp = 0
            end

            reduce = lasthp - curHp
            if reduce > 0 then
                if sender then
                    sender:addDamageData(reduce, self:isHero())
                end

                self:addHurtData(reduce)
            end

            -- print("Unit:reduceHP :", self:getID(), curHp)
            self:triggerHackedBuff(sender, frame)
            self:setHpValue(curHp, frame)

            if curHp <= 0 then
                self:transformNormalState(UnitState.DIE, frame)
            end

            local behavior = {damageCount, isCrit and 1 or 0, isGuard and 1 or 0}
            self:recordBehavior(frame, UnitBehaviorType.reduceHp, behavior)
        end
        
        return damageCount, reduce
    end
	
	return 0, 0
end

function Unit:spread(damageCount, senderInfo, senderType, frame, sender)
    if self:isAlive() then
        local reduce = 0
        local frame = frame or 0

        damageCount = (damageCount + self:getExtraDamage(damageCount, senderInfo, senderType))
        if damageCount > 0 then
            damageCount = self:onReduceHp(damageCount, frame, sender)
        end

        if damageCount > 0 then
            damageCount = math.floor(damageCount)
            local lasthp = self:getHp()
            local curHp = lasthp - damageCount

            if curHp <= 0 then
                curHp = 0
            end
            reduce = lasthp - curHp
            if reduce > 0 then
                if sender then
                    sender:addDamageData(reduce, self:isHero())
                end

                self:addHurtData(reduce)
            end

            -- print("Unit:reduceHP :", self:getID(), curHp)
            self:setHpValue(curHp, frame)

            if curHp <= 0 then
                self:transformNormalState(UnitState.DIE, frame)
            end

            local behavior = {damageCount, 0, 0}
            self:recordBehavior(frame, UnitBehaviorType.reduceHp, behavior)
        end
        
        return damageCount, reduce
    end
    
    return 0, 0
end

function Unit:hurtBack(damageCount, frame, sender)
    if self:isAlive() then
        local reduce = 0
        local frame = frame or 0

        if damageCount > 0 then
            damageCount = self:onReduceHp(damageCount, frame, sender)
        end
        
        if damageCount > 0 then
            damageCount = math.floor(damageCount)
            local lasthp = self:getHp()
            local curHp = lasthp - damageCount

            if curHp <= 0 then
                curHp = 0
            end
            reduce = lasthp - curHp
            if reduce > 0 then
                if sender then
                    sender:addDamageData(reduce, self:isHero())
                end

                self:addHurtData(reduce)
            end

            -- print("Unit:reduceHP :", self:getID(), curHp)
            self:setHpValue(curHp, frame)

            if curHp <= 0 then
                self:transformNormalState(UnitState.DIE, frame)
            end

            local behavior = {damageCount, 0, 0}
            self:recordBehavior(frame, UnitBehaviorType.reduceHp, behavior)
        end
        
        return damageCount, reduce
    end
    
    return 0, 0
end

function Unit:getExtraDamage(damage, senderInfo, senderType)
    local extraDamagePer = 0

    if senderType == UnitType.INFANTRY then
        extraDamagePer = extraDamagePer + self.attribute.sufferInfantry
    elseif senderType == UnitType.GUNNER then
        extraDamagePer = extraDamagePer + self.attribute.sufferGunner
    elseif senderType == UnitType.ARCHER then
        extraDamagePer = extraDamagePer + self.attribute.sufferArcher
    elseif senderType == UnitType.CAVALRY then
        extraDamagePer = extraDamagePer + self.attribute.sufferCavalry
    end

    if senderInfo.isHero then
        extraDamagePer = extraDamagePer + self.attribute.sufferHero
    end
    
    extraDamagePer = extraDamagePer + self.attribute.sufferAll

    if extraDamagePer < -0.9 then
        extraDamagePer = -0.9
    end

    return extraDamagePer * damage
end

function Unit:onReduceHp(damage, frame, sender)
    for k, info in pairs(self.buffList) do
        local buff = info.buff
        if buff.hp and buff.hp > 0 then
            if buff.hp > damage then
                buff.hp = buff.hp - damage
                local behavior = {self:getFaction(), 3002}
                self:recordBehavior(frame, UnitBehaviorType.floatWord, behavior)

                self:addHurtData(damage)
                if sender then
                    sender:addDamageData(damage, self:isHero())
                end

                return 0
            else
                damage = damage - buff.hp
                self:recordBehavior(frame, UnitBehaviorType.removeBuff, self.buffList[k].buff.Id)
                self.buffList[k] = nil

                self:addHurtData(buff.hp)
                if sender then
                    sender:addDamageData(buff.hp, self:isHero())
                end
            end
        end
    end
    
    return damage
end

function Unit:resistanceDamage(damage, senderType)
    local extraDamage = 0

    if senderType == UnitType.INFANTRY then
        extraDamage = extraDamage + damage * self.attribute.resistanceInfantry
    elseif senderType == UnitType.GUNNER then
        extraDamage = extraDamage + damage * self.attribute.resistanceGunner
    elseif senderType == UnitType.ARCHER then
        extraDamage = extraDamage + damage * self.attribute.resistanceArcher
    elseif senderType == UnitType.CAVALRY then
        extraDamage = extraDamage + damage * self.attribute.resistanceCavalry
    end

    return extraDamage
end

function Unit:healHP(healingBonus, frame, sender)
	if self:isAlive() then
        local lasthp = self:getHp()
        local curHp = self:getHp() + healingBonus
        if curHp > self.orgAttribute.hp then
            curHp = self.orgAttribute.hp 
        end

        if sender then
            sender:addHealData(curHp - lasthp)
        end

        self:recordBehavior(frame, UnitBehaviorType.healHp, math.ceil(healingBonus))
        self:setHpValue(curHp, frame)
        return healingBonus
    end
end

function Unit.getHitInterval()
    return 0.9
end

function Unit:updateHitInterval()
end

function Unit:addHitAction(reduceValue)
    if reduceValue <= 0 then
    	return
    end
    
    local level = self:getHp() * 0.06
    if reduceValue <= level and math.random() < 1 - reduceValue / level * 0.8 then
    	return
    end
end

function Unit:setBulletAttribute(bullet, event)
    if self.curSkillData then
        --print("setBulletAttribute : ", self.skill:getCurrentSkillIndex())
        self:setSkillBulletAttribute(bullet, self.skill:getCurrentSkillIndex(), event.intValue)
    else
        self:setSkillBulletAttribute(bullet, self.skill:getAttackSkillIndex(), event.intValue)
    end
end

function Unit:setSkillBulletAttribute(bullet, skillID, stage)
    self.skill:setBulletAttribute(bullet, skillID, stage)
end

function Unit:hitTest()
	return true
end

function Unit:getHp()
    return self.attribute.hp
end

function Unit:getHpRatio()
	return self.attribute.hp / self.orgAttribute.hp
end

function Unit:getMaxHp()
    return self.orgAttribute.hp
end

function Unit.getMaxPower()
    return globalConf.energyLimit
end

function Unit:setComplete(complete)
    -- if complete then 
    --     if self:isSummon() then
    --         self:transformNormalState(UnitState.DIE)
    --         self.completeFlag = complete
    --     else
    --         self:showBattleFloatWord(choiceBattleFloatWordOption(self:getFaction() == UnitFaction.LEFT, 3019))
            
    --         if math.floor(self.attribute.energyPerRound) > 0 then
    --             self:addPowerValue(self.attribute.energyPerRound)
    --         end

    --         if math.floor(self.attribute.lifePerRound) > 0 then
    --             self:healHP(self.attribute.lifePerRound, DamageType.INSTANT)
    --         end

    --         self.attribute.speedFactor = self.attribute.speedFactor * 1.5
    --         self.completeFlag = complete
    --         self:clearShader()
    --         -- self:clearAllCoexistState()
    --         -- self:setInvincible(true)
    --     end
    -- end
end

function Unit:onComplete()
    return self.completeFlag
end

function Unit:setHpValue(hp, frame)
    local frame = frame or 0
    self.attribute.hp = hp

    self.hpIndex = self.hpIndex + 1
    self:recordBehavior(frame, UnitBehaviorType.recordHp, {math.floor(self.attribute.hp), self.hpIndex})
    
    -- self.hpLine:setPercentage(self:getHpRatio() * 100)
end

function Unit:clearShader()
end

function Unit:setAnimEventList(name)
    self.animEventList = clone(self.anim:getAnimEventList(name)) or {}
end

function Unit:addDieHeroCount()
    self.dieHeroCount = self.dieHeroCount + 1
end

function Unit:cleanDieHeroCount()
    self.dieHeroCount = 0
end

function Unit:getDieHeroCount()
    return self.dieHeroCount
end

function Unit:setFrame(frame)
    if not frame then
        fprint("Unit:setFrame nil : ", debug.traceback())
    end
    self.curFrame = frame or 0
end

function Unit:addDamageData(damage, isHero)
    if isHero then
        self.damageData.heroDamage = self.damageData.heroDamage + damage
        dataRecord[self.faction].totalHeroDamage = dataRecord[self.faction].totalHeroDamage + damage
    else
        self.damageData.soldierDamage = self.damageData.soldierDamage + damage
        dataRecord[self.faction].totalSoldierDamage = dataRecord[self.faction].totalSoldierDamage + damage
    end
end

function Unit:addHealData(heal)
    self.damageData.heal = self.damageData.heal + heal
    dataRecord[self.faction].totalHeal = dataRecord[self.faction].totalHeal + heal
end

function Unit:addHurtData(hurt)
    self.damageData.hurt = self.damageData.hurt + hurt
    dataRecord[self.faction].totalHurt = dataRecord[self.faction].totalHurt + hurt
end

function Unit:recordBehavior(frame, type, record)
    local key = tostring(type)
    local id = tostring(self:getID())
    local framestr = tostring(math.floor(frame))

    if frame > maxFrame then
        maxFrame = frame
    end

    if not arrayTable[1][framestr] then
        arrayTable[1][framestr] = {}
    end

    if not arrayTable[1][framestr][id] then
        arrayTable[1][framestr][id] = {}
    end

    if type == UnitBehaviorType.location then
        arrayTable[1][framestr][id][key] = record
    else
        if arrayTable[1][framestr][id][key] then
            table.insert(arrayTable[1][framestr][id][key], record)
        else
            arrayTable[1][framestr][id][key] = {}
            table.insert(arrayTable[1][framestr][id][key], record)
        end
    end
end


return Unit

