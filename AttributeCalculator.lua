
local OpenServerConfig = OpenServerConfig
local heroConf = OpenServerConfig("heroConf")
local monsterConf = OpenServerConfig("monsterConf")
local buffConf = OpenServerConfig("buffConf")
local levelConf = OpenServerConfig("levelConf")
local starConf = OpenServerConfig("starConf")
local enhanceConf = OpenServerConfig("enhanceConf")
local botAbilityConf = OpenServerConfig("botAbilityConf")
local equipConf = OpenServerConfig("equipConf")
local topEnhanceConf = OpenServerConfig("topEnhanceConf")

local AttributeCalculator = class("AttributeCalculator")

function AttributeCalculator:ctor()
	
end

function AttributeCalculator:getInitHeroAttri(heroID)
	local heroInfo = heroConf[heroID]
	local attriTab = {}

	if not heroInfo then
		return 
	end

	attriTab[AttributeType.life] = heroInfo.life
	attriTab[AttributeType.attack] = heroInfo.attack
	attriTab[AttributeType.offset] = heroInfo.offset
	attriTab[AttributeType.dodge] = heroInfo.dodge
	attriTab[AttributeType.crit] = heroInfo.crit

	return attriTab
end

function AttributeCalculator:getHeroLevelAttri(heroID, level)
	local heroInfo = heroConf[heroID]

	if not heroInfo then
		return 
	end

	local attriTab = {}
	level = level - 1

	attriTab[AttributeType.life] = heroInfo.lifeGrow * level
	attriTab[AttributeType.attack] = heroInfo.attackGrow * level

	return attriTab
end

function AttributeCalculator:getHeroStarBuff(heroID, star)
	local heroInfo = heroConf[heroID]
	local buffList = {}

	if not heroInfo then
		return buffList
	end

	for k, info in pairs(starConf) do
		if info and info.getBuff and info.class == heroInfo.class and info.level <= star then
			for k,v in pairs(info.getBuff) do
				table.insert(buffList, v)
			end
		end
	end

	return buffList
end

function AttributeCalculator:getHeroBattleBuff(heroID, battle)
	local heroInfo = heroConf[heroID]
	local buffList = {}

	if not heroInfo then
		return buffList
	end

	if not heroInfo.battleBuff then
		return buffList
	end

	if not heroInfo.battleBuff[battle] then
		return buffList
	end

	for i = 1, battle do
		table.insert(buffList, heroInfo.battleBuff[i])
	end

	return buffList
end

function AttributeCalculator:getHeroReviveBuff(heroID, revive)
	local heroInfo = heroConf[heroID]
	local buffList = {}

	if not heroInfo then
		return buffList
	end

	if not heroInfo.revive[revive] then
		return buffList
	end

	table.insert(buffList, heroInfo.revive[revive].attackPara)
	table.insert(buffList, heroInfo.revive[revive].lifePara)

	return buffList
end

function AttributeCalculator:getHeroStrenthBuff(strength)
	local enhanceInfo = enhanceConf[strength]
	local buffList = {}

	if not enhanceInfo then
		return buffList
	end

	table.insert(buffList, enhanceInfo.life)
	table.insert(buffList, enhanceInfo.attack)
	table.insert(buffList, enhanceInfo.attackRatio)
	table.insert(buffList, enhanceInfo.lifeRatio)

	return buffList
end

function AttributeCalculator:getHeroEnhanceBuff(heroID,enhance,talent)
	local heroInfo = heroConf[heroID]
	local lcGroup = nil
	local talentBf = {}
	local buffList = {}

	for k,v in pairs(topEnhanceConf) do
		if v.group == heroInfo.topEnhance then
			for m,n in pairs(talent or {}) do
				if v.maxLevel == n.step then
					table.insert(talentBf,v.talentBuff[n.index])
				end
			end

			if enhance == v.level then
				lcGroup = v
			end
		end
	end

	if not lcGroup then
		return buffList
	end

	for k,v in pairs(lcGroup.getBuff) do
		table.insert(buffList, v)
	end

	for k,v in pairs(talentBf) do
		table.insert(buffList, v)
	end

	return buffList
end

function AttributeCalculator:getInitMonsterAttri(heroID)
	local monsterInfo = monsterConf[heroID]
	local attriTab = {}

	if not monsterInfo then
		return 
	end

	attriTab[AttributeType.life] = monsterInfo.life
	attriTab[AttributeType.attack] = monsterInfo.attack
	attriTab[AttributeType.offset] = monsterInfo.offset
	attriTab[AttributeType.dodge] = monsterInfo.dodge
	attriTab[AttributeType.crit] = monsterInfo.crit

	return attriTab
end

function AttributeCalculator:getBuffTab(buffList)
	local attriTab = {}
	local attriRatio = {}
	for k,v in pairs(buffList) do
		local buffInfo = buffConf[v]
		if buffInfo and buffInfo.class == 1 and buffInfo.addAbility and buffInfo.addAbility < 6 then
			if not attriTab[buffInfo.addAbility] then
				attriTab[buffInfo.addAbility] = 0
			end

			if not attriRatio[buffInfo.addAbility] then
				attriRatio[buffInfo.addAbility] = 0
			end

			attriTab[buffInfo.addAbility] = attriTab[buffInfo.addAbility] + (buffInfo.addAbilityAbs or 0)
			attriRatio[buffInfo.addAbility] = attriRatio[buffInfo.addAbility] + (buffInfo.addTargetAbilityRatio or 0)
		end
	end

	return attriTab, attriRatio
end

function AttributeCalculator:getBuffRatio(buffList)
	local attriRatio = {}
	for k,v in pairs(buffList) do
		local buffInfo = buffConf[v]
		if buffInfo and buffInfo.class == 1 and buffInfo.addAbility and buffInfo.addAbility >= 6 then
			if not attriRatio[buffInfo.addAbility] then
				attriRatio[buffInfo.addAbility] = 0
			end

			attriRatio[buffInfo.addAbility] = attriRatio[buffInfo.addAbility] + (buffInfo.addTargetAbilityRatio or 0)
		end
	end

	return attriRatio
end

--获取英雄晋升次数
function AttributeCalculator:getPromoteCnt(level)
    return levelConf[level].keyLevel or 0
end

--获取英雄真实星级
function AttributeCalculator:getStarCntByStar(heroID, star)
	local heroInfo = heroConf[heroID]

	if not heroInfo then
		return 0
	end

    for k,v in pairs(starConf) do
        if heroInfo.class == v.class and star == v.level then
            return v.keyLevel
        end
    end
    
    return 0
end

function AttributeCalculator:getTotalAttri(heroInfo)
	local heroID = heroInfo.heroID or heroInfo.templetID or 0
	local level = heroInfo.level or 1
	local strength = heroInfo.strength or 0
	local skills = heroInfo.skills or {}
	local buff = {}
	local star = heroInfo.star or 0
	local battle = self:getStarCntByStar(heroID, star)
	local revive = self:getPromoteCnt(level)
	local enhance = heroInfo.enhance or 0
	local talent = heroInfo.talent or {}

	local initAttriTab = self:getInitHeroAttri(heroID)					--初始属性
	local heroLevelTab = self:getHeroLevelAttri(heroID, level)			--等级属性
	local heroStarBuff = self:getHeroStarBuff(heroID, star)				--星级BUFF
	local heroBattleBuff = self:getHeroBattleBuff(heroID, battle)		--升星BUFF
	local heroReviveBuff = self:getHeroReviveBuff(heroID, revive)		--转生BUFF
	local strengthBuff = self:getHeroStrenthBuff(strength)				--强化BUFF
	local enhanceBuff = self:getHeroEnhanceBuff(heroID,enhance,talent)	--巅峰强化BUFF

	for i,v in ipairs(heroStarBuff) do
		table.insert(buff, v)
	end

	for i,v in ipairs(heroBattleBuff) do
		table.insert(buff, v)
	end

	for i,v in ipairs(heroReviveBuff) do
		table.insert(buff, v)
	end

	for i,v in ipairs(strengthBuff) do
		table.insert(buff, v)
	end

	for i,v in ipairs(enhanceBuff) do
		table.insert(buff, v)
	end

	for i,v in ipairs(skills) do
		table.insert(buff, v)
	end

	local totalAttriTab = {}
	for k,v in pairs(AttributeType) do
		totalAttriTab[v] = (initAttriTab[v] or 0) + (heroLevelTab[v] or 0)
	end

	return totalAttriTab, buff
end

function AttributeCalculator:getMonsterTotalAttri(heroInfo)
	local heroID = heroInfo.heroID or 0
	local buff = {}

	local initAttriTab = self:getInitMonsterAttri(heroID)

	local totalAttriTab = {}
	for k,v in pairs(AttributeType) do
		totalAttriTab[v] = (initAttriTab[v] or 0)
	end

	return totalAttriTab, buff
end

function AttributeCalculator:getInitEquipAttri(equipID)
	local equipInfo = equipConf[equipID]
	local attriTab = {}

	if not equipInfo then
		return 
	end

	attriTab[AttributeType.life] = equipInfo.life
	attriTab[AttributeType.attack] = equipInfo.attack

	return attriTab
end

function AttributeCalculator:getEquipLevelAttri(equipID, level)
	local equipInfo = equipConf[equipID]

	if not equipInfo then
		return 
	end

	local attriTab = {}
	attriTab[AttributeType.life] = (equipInfo.lifeGrow or 0) * level
	attriTab[AttributeType.attack] = (equipInfo.attackGrow or 0) * level

	return attriTab
end

function AttributeCalculator:getEquipAttri(info)
	local equipId = info.id or info.equipId or 0
	local level = info.level or info.equipLvl or 1

	local initTab = self:getInitEquipAttri(equipId)					--初始属性
	local levelTab = self:getEquipLevelAttri(equipId, level)			--等级属性

	local totalAttriTab = {}
	for k,v in pairs(AttributeType) do
		totalAttriTab[v] = (initTab[v] or 0) + (levelTab[v] or 0)
	end

	return totalAttriTab
end

function AttributeCalculator:getInitBotHeroAttri(heroID, botID)
	local heroInfo = heroConf[heroID]
	local botInfo = botAbilityConf[botID]
	local attriTab = {}

	if (not heroInfo) or (not botInfo) then
		return 
	end

	attriTab[AttributeType.life] = botInfo["life" .. heroInfo.quality]
	attriTab[AttributeType.attack] = botInfo["attack" .. heroInfo.quality]
	attriTab[AttributeType.offset] = botInfo.offset
	attriTab[AttributeType.dodge] = botInfo.dodge
	attriTab[AttributeType.crit] = botInfo.crit

	return attriTab
end

function AttributeCalculator:getInitBotMonsterAttri(botID)
	local botInfo = botAbilityConf[botID]
	local attriTab = {}

	if not botInfo then
		return 
	end

	attriTab[AttributeType.life] = botInfo.life1
	attriTab[AttributeType.attack] = botInfo.attack1
	attriTab[AttributeType.offset] = botInfo.offset
	attriTab[AttributeType.dodge] = botInfo.dodge
	attriTab[AttributeType.crit] = botInfo.crit

	return attriTab
end

function AttributeCalculator:getBotTotalAttri(heroInfo)
	local heroID = heroInfo.heroID or 0
	local botID = heroInfo.botID or 0
	local buff = {}

	local initAttriTab
	if heroInfo.isHero then
		initAttriTab = self:getInitBotHeroAttri(heroID, botID)
	else
		initAttriTab = self:getInitBotMonsterAttri(botID)
	end

	local totalAttriTab = {}
	for k,v in pairs(AttributeType) do
		totalAttriTab[v] = (initAttriTab[v] or 0)
	end

	return totalAttriTab, buff
end

return AttributeCalculator