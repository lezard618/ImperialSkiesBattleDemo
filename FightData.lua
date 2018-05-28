
local FightData = class("FightData")

function FightData:ctor()
end

function FightData:init(data)
    self.data = data
    -- self.battleData = {randomSeed = 1, battleType = 1}--data.fightData
    -- self.data = {}--data.teamInfo
    self.data.randomSeed = os.time()
    --print("FightData:init : ", self.data.randomSeed)
end

function FightData:getRandomSeed()
    return self.data.randomSeed
end

function FightData:getGameType()
    return 1--self.battleData.battleType or 1
end

function FightData:getTeamInfo(faction)
    if faction == UnitFaction.LEFT then
        return self.data.leftTeam
    else
        return self.data.rightTeam
    end
end

function FightData:getTeamType(faction)
    if faction == UnitFaction.LEFT then
        return self.data.leftTeam.param[ExtraParamType.TeamType] or "0"
    else
        return self.data.rightTeam.param[ExtraParamType.TeamType] or "0"
    end
end

function FightData:canUseStatueBuff(faction)
    if faction == UnitFaction.LEFT then
        return (self.data.leftTeam.param[ExtraParamType.StatueBuff][self.data.rightTeam.index] or 0) == 0
    else
        return (self.data.rightTeam.param[ExtraParamType.StatueBuff][self.data.leftTeam.index] or 0) == 0
    end
end

function FightData:getEmbattle()
    --for k, player in pairs(self.data.leftPlayer) do
        --fprint("left player : ", player.heroID)
    --end
    --fprint("\r\n")

	return self.data.leftTeam.team, self.data.leftTeam.botid
end

function FightData:getMonsterTeam()
    --for k, player in pairs(self.data.rightPlayer) do
        --fprint("right player : ", player.heroID)
    --end
    --fprint("\r\n")

    return self.data.rightTeam.team, self.data.rightTeam.botid
end

function FightData:getUnitBattleInitAttri(faction, heroInfo)
    if heroInfo.botID then
        return AttributeCalculator:getBotTotalAttri(heroInfo)
    elseif heroInfo.isMonster then
        return AttributeCalculator:getMonsterTotalAttri(heroInfo)
    elseif heroInfo.isHero then
        return AttributeCalculator:getTotalAttri(heroInfo)
    else
        return AttributeCalculator:getMonsterTotalAttri(heroInfo)
    end
end

function FightData:getBuffList(faction)
    if faction == UnitFaction.RIGHT then 
        return self.data.rightTeam.buffList or {}
    else
        return self.data.leftTeam.buffList or {}
    end
end

function FightData:getEquipInitAttri(equipInfo)
    return AttributeCalculator:getEquipAttri(equipInfo)
end

return FightData
