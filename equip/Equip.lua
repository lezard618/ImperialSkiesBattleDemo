local Equip = class("Equip")
local equipConf = OpenServerConfig("equipConf")
local buffConf = OpenServerConfig("buffConf")

function Equip:ctor()
	self.baseInfo = {}
	self.baseAttriTab = {}
	self.attriTab = {}
	self.buffList = {}
	self.unitBuffList = {}
	self.isNeedResetBuff = false
end

function Equip:init(data)
	self.data = data
	self.baseInfo = equipConf[data.id]

	local attriTab = FightData:getEquipInitAttri(data)
	self.attriTab = attriTab
    self.baseAttriTab = self.attriTab

	for i,v in ipairs(data.buff) do
		self:addBuff(v)
	end

	self.attriTab = self:skillBuff() or self.attriTab
end

function Equip:isType(utype)
    return self.baseInfo.class == utype
end

function Equip:addBuff(buff, levelState)
    local buffData = buffConf[buff]
    if buffData then
        if buffData.class ~= BuffClass.Equip then
        	table.insert(self.unitBuffList, buff)
            return
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
                table.insert(self.buffList, {buff = temp, isActived = false, endRound = (temp.round or 99), levelState = levelState})
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
                    table.insert(self.buffList, {buff = temp, isActived = false, endRound = (temp.round or 99), levelState = levelState})
                else
                    self.buffList[key] = {buff = temp, isActived = false, endRound = (temp.round or 99), levelState = levelState}
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
                table.insert(self.buffList, {buff = temp, isActived = false, endRound = (temp.round or 99), levelState = levelState})
            else
                self.buffList[key] = {buff = temp, isActived = false, endRound = (temp.round or 99), levelState = levelState}
            end
            self.isNeedResetBuff = true
        end
    end
end

function Equip:skillBuff(_attriTab, _frame)
    if self.isNeedResetBuff then
        local frame = _frame or 0
        local attriTab = {}
        if _attriTab then
            attriTab = _attriTab
        else
            attriTab = clone(self.baseAttriTab)
        end
        
        local immune = false
        local baseBuffTab = {}
        local baseBuffRatio = {}
        local buffTab = {}
        local buffRatio = {}
        local skillBuffTab = {}
        local skillBuffRatio = {}
        local extraBuffRatio = {}

        for k, info in pairs(self.buffList) do
            local buffInfo = info.buff
            local enable = true

            if enable then
                if not info.isActived then
                    self.buffList[k].isActived = true
                end

                if buffInfo.addEquipBase then
                    if not buffRatio[AttributeType.life] then
                        buffRatio[AttributeType.life] = 0
                    end

                    buffRatio[AttributeType.life] = buffRatio[AttributeType.life] + (buffInfo.addEquipBase or 0)

                    if not buffRatio[AttributeType.attack] then
                        buffRatio[AttributeType.attack] = 0
                    end
                    
                    buffRatio[AttributeType.attack] = buffRatio[AttributeType.attack] + (buffInfo.addEquipBase or 0)
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

                            skillBuffTab[buffInfo.addAbility] = skillBuffTab[buffInfo.addAbility] + (buffInfo.addAbilityAbs or 0)
                            if buffInfo.addSelfAbilityRatio and info.sender then
                                skillBuffTab[buffInfo.addAbility] = skillBuffTab[buffInfo.addAbility] + info.sender:getAbilityByType(buffInfo.addAbility) * buffInfo.addSelfAbilityRatio
                            end
                            skillBuffRatio[buffInfo.addAbility] = skillBuffRatio[buffInfo.addAbility] + (buffInfo.addTargetAbilityRatio or 0)
                        else
                            if not buffTab[buffInfo.addAbility] then
                                buffTab[buffInfo.addAbility] = 0
                            end

                            if not buffRatio[buffInfo.addAbility] then
                                buffRatio[buffInfo.addAbility] = 0
                            end

                            buffTab[buffInfo.addAbility] = buffTab[buffInfo.addAbility] + (buffInfo.addAbilityAbs or 0)
                            if buffInfo.addSelfAbilityRatio and info.sender then
                                buffTab[buffInfo.addAbility] = buffTab[buffInfo.addAbility] + info.sender:getAbilityByType(buffInfo.addAbility) * buffInfo.addSelfAbilityRatio
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
                end
            end
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

        for k,v in pairs(AttributeType) do
            attriTab[v] = (attriTab[v] or 0) + (extraBuffRatio[v] or 0)
        end

        self.isNeedResetBuff = false

        return attriTab
    end
end

function Equip:getAttr()
	return self.attriTab
end

function Equip:getUnitBuff()
	return self.unitBuffList
end

return Equip