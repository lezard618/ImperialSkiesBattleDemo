
local OpenServerFile = OpenServerFile
local Summon = OpenServerFile("Summon")
local Replace = OpenServerFile("Replace")

local MapManager = class("MapManager")

function MapManager:init()
    self.unitList = {{{}, {}, {}, {}, {}}, {{}, {}, {}, {}, {}}}
    self.unitMap = {}
    self.bulletMap = {}
    self.heroCount = 0
    self.monsterCount = 0
    self.deadHeroUnitList = {}
    self.deadMonsterUnitList = {}
    self.equipList = {{}, {}}
end

function MapManager:changeUnitCount(faction, value)
	if faction == UnitFaction.LEFT then
        self.heroCount = self.heroCount + value
    else
        self.monsterCount = self.monsterCount + value
	end
end

function MapManager:getUnitCount(faction)
    if faction == UnitFaction.LEFT then
        return self.heroCount
    else
        return self.monsterCount
    end
end

function MapManager:addUnit(unit)
    local faction = unit:getFaction()
    if unit:isSummon() then
        table.insert(self.unitList[faction][unit:getType()], unit.heroInfo.index, unit)
    else
        table.insert(self.unitList[faction][unit:getType()], unit)
    end
    self.unitMap[unit:getID()] = unit
    self:changeUnitCount(faction, 1)
end

function MapManager:addBullet(bullet)
    --print("MapManager:addBullet == ",bullet, bullet:getID() , bullet.bid)
    self.bulletMap[bullet:getID()] = bullet
end

function MapManager:addEquip(equip, faction)
    table.insert(self.equipList[faction], equip)
end

function MapManager:removeUnit(unit)
    self:removeUnitByID(unit:getID())
end

function MapManager:removeUnitInAllFactionByID(uid)
    for k, factionList in ipairs(self.unitList) do
        for kk, typeList in ipairs(factionList) do
            for kkk, unit in ipairs(typeList) do
                if unit:getID() == uid then
                    table.remove(self.unitList[k][kk], kkk)
                    return
                end
            end
        end
    end
end

function MapManager:removeUnitByID(uid)
    if self.unitMap[uid] then
        self.unitMap[uid] = nil
        self:changeUnitCount(v:getFaction(), -1)
    end

    for k, factionList in ipairs(self.unitList) do
        for kk, typeList in ipairs(factionList) do
            for kkk, unit in ipairs(typeList) do
                if unit:getID() == uid then
                    self:changeUnitCount(unit:getFaction(), -1)
                    table.remove(self.unitList[k][kk], kkk)
                    return
                end
            end
        end
    end
end

function MapManager:removeBullet(bullet)
    self:removeBulletByID(bullet:getID())
end

function MapManager:removeBulletByID(bid)
    self.bulletMap[bid] = nil
end

function MapManager:clearAllBullet()
    for k, v in pairs(self.bulletMap) do
        v:setAutoCleanup(true)
    end
end

function MapManager:update()
    self:updateUnit()
    self:updateBullet()
end

function MapManager:updateUnit()

    for k, factionList in ipairs(self.unitList) do
        for kk, typeList in ipairs(factionList) do
            local removeList = {}
            for kkk, unit in ipairs(typeList) do
                unit:update()

                if unit:needCleanup() then
                    local uid = unit:getID()
                    -- unit:writeRecord()
                    self:changeUnitCount(unit:getFaction(), -1)
                    unit:cleanup()
                    self.unitMap[uid] = nil
                    table.insert(removeList, uid)

                    if unit:getFaction() == UnitFaction.LEFT then
                        self.deadHeroUnitList[uid] = unit
                    else
                        self.deadMonsterUnitList[uid] = unit
                    end
                end
            end

            for i, uid in ipairs(removeList) do
                self:removeUnitInAllFactionByID(uid)
            end
        end
    end

    -- for k, unit in ipairs(self.unitMap) do
    -- end
end

function MapManager:updateBullet()
    for k, bullet in pairs(self.bulletMap) do
        bullet:update()
        
        if bullet:needCleanup() then
            bullet:cleanup()
            self.bulletMap[k] = nil
        end
    end
end

function MapManager:recordAllUnit()
    for k, unit in pairs(self.unitMap) do
        unit:writeRecord()
    end
end

function MapManager:recordAllBullet()
    for k, bullet in pairs(self.bulletMap) do
        bullet:writeRecord()
    end
end

function MapManager:removeFromDead(id)
    local find = false
    for i, unit in pairs(self.deadHeroUnitList) do
        if unit:getID() == id then
            find = true
            self.deadHeroUnitList[i] = nil
            break
        end
    end

    if not find then
        for i, unit in pairs(self.deadMonsterUnitList) do
            if unit:getID() == id then
                self.deadMonsterUnitList[i] = nil
                break
            end
        end
    end
end

function MapManager:getEquipsByType(faction, utype)
    local equips = {}
    if self.equipList[faction] then
        for i,v in ipairs(self.equipList[faction]) do
            if v:isType(utype) then
                table.insert(equips, v)
            end
        end
    end

    return equips
end

function MapManager:getEquips(faction)
    return self.equipList[faction]
end

function MapManager:getUnitMap()
    return self.unitMap
end

function MapManager:getUnitList(faction)
    return self.unitList[faction]
end

function MapManager:getAllUnit(faction)
    local units = {}
    for k, factionList in ipairs(self.unitList) do
        if faction == k then
            for kk, typeList in pairs(factionList) do
                for kkk, unit in pairs(typeList) do
                    if unit:isAlive() then
                        table.insert(units, unit)
                    end
                end
            end
        end
    end

    return units
end

function MapManager:getUnitByID(id)
    local unit = self.unitMap[id]
    if unit and unit:isAlive() then
        return unit
    end

    return nil
end

function MapManager:getDeadUnitByID(id)
    local unit = self.deadHeroUnitList[id]
    if unit then
        return unit
    end

    unit = self.deadMonsterUnitList[id]
    if unit then
        return unit
    end

    return nil
end

function MapManager:getBulletByID(id)
    local bullet = self.bulletMap[id]
    return bullet
end

function MapManager:getFirstUnit(faction, _utype)
    local utype = _utype or 0
    local unit

    local factionList = self.unitList[faction]
    if faction == UnitFaction.LEFT then
        local pos = 0
        for kk, typeList in ipairs(factionList) do
            if utype == 0 or kk == utype then
                for kkk, v in ipairs(typeList) do
                    if v:isAlive() and v:getLocation().x > pos then
                        pos = v:getLocation().x
                        unit = v
                    end
                end
            end
        end
    else
        local pos = 999999
        for kk, typeList in ipairs(factionList) do
            if utype == 0 or kk == utype then
                for kkk, v in ipairs(typeList) do
                    if v:isAlive() and v:getLocation().x < pos then
                        pos = v:getLocation().x
                        unit = v
                    end
                end
            end
        end
    end

    return unit
end

function MapManager:getUnitsInFirstRow(faction, baseLine)
    local units = {}
    local firstRow = 0
    local firstType = 0
    for k, factionList in ipairs(self.unitList) do
        if faction == k then
            for kk, typeList in ipairs(factionList) do
                for kkk, unit in ipairs(typeList) do
                    if firstRow == 0 then
                        firstType = unit:getType()
                        firstRow = math.ceil(unit:getIndexInMatrix() / MaxUnitInLine)
                        table.insert(units, unit)
                    elseif firstRow == math.ceil(unit:getIndexInMatrix() / MaxUnitInLine) and firstType == unit:getType() then
                        table.insert(units, unit)
                    end
                end
            end
        end
    end

    if baseLine then
        table.sort(units, function (a, b)
            return math.abs(a:getLineIndex() - baseLine) < math.abs(b:getLineIndex() -baseLine)
        end)
    end

    return units
end

function MapManager:getUnitsInRowAndLine(faction, utype, targLocation)
    local units = {}
    if self.unitList[faction] and self.unitList[faction][utype] then
        for k, unit in ipairs(self.unitList[faction][utype]) do
            local location = unit:getLineLocation()
            if location.x == targLocation.x or location.y == targLocation.y then
                table.insert(units, unit)
            end
        end
    end

    return units
end

function MapManager:getLastUnit(faction, _utype)
    local unit
    local utype = _utype or 0
    local factionList = self.unitList[faction]

    if faction == UnitFaction.LEFT then
        local pos = 999999
        for kk, typeList in ipairs(factionList) do
            if kk ~= utype then
                for kkk, v in ipairs(typeList) do
                    if v:isAlive() and v:getLocation().x < pos then
                        pos = v:getLocation().x
                        unit = v
                    end
                end
            end
        end
    else
        local pos = 0
        for kk, typeList in ipairs(factionList) do
            if kk ~= utype then
                for kkk, v in ipairs(typeList) do
                    if v:isAlive() and v:getLocation().x > pos then
                        pos = v:getLocation().x
                        unit = v
                    end
                end
            end
        end
    end

    return unit
end

function MapManager:getUnitsAround(faction, pos, center, uid, _range)
    local range = _range or 1
    local units = {}
    for k, factionList in ipairs(self.unitList) do
        if faction == k then
            for kk, typeList in ipairs(factionList) do
                for kkk, unit in ipairs(typeList) do
                    local location = unit:getLineLocation()
                    if unit:isAlive() and unit:getID() ~= uid and cc.pGetDistance(location, center) <= range and cc.pGetDistance(unit:getLocation(), pos) <= (range + 1) * UnitSpace then
                        table.insert(units, unit)
                    end
                end
            end
        end
    end

    return units
end

function MapManager:getUnitInLine(line, faction, _utype, noBoss)
    local noBoss = noBoss or false
    local utype = _utype or 0
    local units = {}
    for k, factionList in ipairs(self.unitList) do
        if faction == k then
            for kk, typeList in ipairs(factionList) do
                if kk == UnitType.BOSS and not noBoss then
                    for kkk, unit in ipairs(typeList) do
                        table.insert(units, unit)
                    end
                elseif utype == 0 or kk == utype then
                    for kkk, unit in ipairs(typeList) do
                        if unit:isAlive() and unit:getLineIndex() == line then
                            table.insert(units, unit)
                        end
                    end
                end
            end
        end
    end

    table.sort(units, function (a, b)
        if faction == UnitFaction.LEFT then
            return a:getLocation().x > b:getLocation().x
        else
            return a:getLocation().x < b:getLocation().x
        end
    end)

    return units
end

function MapManager:getUnitAt(location, faction)
    for k, factionList in ipairs(self.unitList) do
        if faction == k then
            for kk, typeList in ipairs(factionList) do
                for kkk, unit in ipairs(typeList) do
                    local temp = unit:getLineLocation()
                    if unit:isAlive() and temp.x == location.x and temp.y == location.y then
                        return unit
                    end
                end
            end
        end
    end
end

function MapManager:getUnitAfter(location, faction)
    local units = {}
    for k, factionList in ipairs(self.unitList) do
        if faction == k then
            for kk, typeList in ipairs(factionList) do
                for kkk, unit in ipairs(typeList) do
                    local temp = unit:getLineLocation()
                    if unit:isAlive() and temp.x >= location.x and temp.y == location.y then
                        table.insert(units, unit)
                    end
                end
            end
        end
    end

    table.sort( units, function (a, b)
        return a:getLineLocation().x < b:getLineLocation().x
    end )

    return units
end

function MapManager:getUnitByType(faction, utype)
    local units = {}
    for k,v in pairs(self.unitList[faction][utype]) do
        table.insert(units, v)
    end
    return units
end

function MapManager:getSoldierByType(faction, _utype)
    local utype = _utype or 0
    local units = {}
    for k, factionList in ipairs(self.unitList) do
        if faction == k then
            for kk, typeList in ipairs(factionList) do
                if utype == 0 or kk == utype then
                    for kkk, unit in ipairs(typeList) do
                        if unit:isAlive() and not unit:isHero() then
                            table.insert(units, unit)
                        end
                    end
                end
            end
        end
    end

    return units
end

function MapManager:getHeroByType(faction, utype)
    local units = {}
    for k, factionList in ipairs(self.unitList) do
        if faction == k then
            for kk, typeList in ipairs(factionList) do
                if kk == utype then
                    for kkk, unit in ipairs(typeList) do
                        if unit:isAlive() and unit:isHero() then
                            table.insert(units, unit)
                        end
                    end
                end
            end
        end
    end

    return units
end

function MapManager:getAllHero(faction)
    local units = {}
    for k, factionList in ipairs(self.unitList) do
        if faction == k then
            for kk, typeList in ipairs(factionList) do
                for kkk, unit in ipairs(typeList) do
                    if unit:isAlive() and unit:isHero() then
                        table.insert(units, unit)
                    end
                end
            end
        end
    end

    return units
end

function MapManager:getFrontUnits(faction, number, baseLine, needHero)
    local units = {}
    local firstRow = 0
    local firstType = 0
    for k, factionList in ipairs(self.unitList) do
        if faction == k then
            for kk, typeList in ipairs(factionList) do
                if firstType == 0 or firstType == kk then
                    for kkk, unit in ipairs(typeList) do
                        if firstRow == 0 and ((not needHero) or (needHero and unit:isHero())) then
                            firstType = unit:getType()
                            firstRow = math.ceil(unit:getRealIndexInMatrix() / MaxUnitInLine)
                            table.insert(units, unit)
                        elseif firstRow == math.ceil(unit:getRealIndexInMatrix() / MaxUnitInLine) and ((not needHero) or (needHero and unit:isHero())) then
                            table.insert(units, unit)
                        end
                    end
                end
            end
        end
    end

    if baseLine then
        table.sort(units, function (a, b)
            return math.abs(a:getLineIndex() - baseLine) < math.abs(b:getLineIndex() -baseLine)
        end)

        while #units > number do
            table.remove(units, #units)
        end
    else
        while #units > number do
            table.remove(units, MyRandom:random(1, #units))
        end
    end

    return units
end

function MapManager:getDeadUnitInMatrix(faction, _utype, _isHero)
    local utype = _utype or 0
    local isHero = _isHero or false
    local units = {}
    if faction == UnitFaction.LEFT then
        for i, unit in pairs(self.deadHeroUnitList) do
            if (utype == 0 or unit:getType() == utype) and unit:isHero() == isHero then
                table.insert(units, unit)
            end
        end
    else
        for i, unit in pairs(self.deadMonsterUnitList) do
            if (utype == 0 or unit:getType() == utype) and unit:isHero() == isHero then
                table.insert(units, unit)
            end
        end
    end

    return units
end

function MapManager:getUnitsNotMaxHp(faction, _utype, isHero)
    local utype = _utype or 0
    local units = {}
    for k, factionList in ipairs(self.unitList) do
        if faction == k then
            for kk, typeList in ipairs(factionList) do
                if utype == 0 or kk == utype then
                    for kkk, unit in ipairs(typeList) do
                        if unit:isAlive() and unit:getHpRatio() < 1 then
                            if isHero then
                                if unit:isHero() then
                                    table.insert(units, unit)
                                end
                            else
                                table.insert(units, unit)
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(units, function (a, b)
        return a:getHpRatio() < b:getHpRatio()
    end)

    return units
end

function MapManager:getLeastHpHero(faction)
    local minQuality = 10
    local minHp = 9999999999
    local heros = {}
    local target = nil
    for k, factionList in ipairs(self.unitList) do
        if faction == k then
            for kk, typeList in ipairs(factionList) do
                for kkk, unit in ipairs(typeList) do
                    local heroQuality = unit:getHeroQuality()
                    if unit:isHero() and unit:isAlive() then
                        if heroQuality < minQuality then
                            minQuality = heroQuality
                            heros = {unit}
                        elseif heroQuality == minQuality then
                            table.insert(heros, unit)
                        end
                    end
                end
            end
        end
    end

    for i,v in ipairs(heros) do
        if v:getHp() < minHp then
            minHp = v:getHp()
            target = v
        end
    end

    return target
end

function MapManager:getUnitsCanShareHurt(faction)
    local list = {}
    for k, factionList in ipairs(self.unitList) do
        if faction == k then
            for kk, typeList in ipairs(factionList) do
                for kkk, unit in ipairs(typeList) do
                    if unit:getShareHurt() > 0 then
                        table.insert(list, unit)
                    end
                end
            end
        end
    end

    return list
end

function MapManager:getMostSameNameHeros(faction)
    local list = {}
    for k, factionList in ipairs(self.unitList) do
        if faction == k then
            for kk, typeList in ipairs(factionList) do
                for kkk, unit in ipairs(typeList) do
                    if unit:isHero() then
                        local name = unit:getHeroName()
                        if not list[name] then
                            list[name] = {}
                        end

                        table.insert(list[name], unit)
                    end
                end
            end
        end
    end

    local mostNum = 0
    local result = {}
    for k,v in pairs(list) do
        if #v > mostNum then
            mostNum = #v
            result = v
        end
    end

    return result
end

function MapManager:getRevivedHeros(faction)
    local list = {}
    for k, factionList in ipairs(self.unitList) do
        if faction == k then
            for kk, typeList in ipairs(factionList) do
                for kkk, unit in ipairs(typeList) do
                    if unit:isRevived() then
                        table.insert(list, unit)
                    end
                end
            end
        end
    end

    return list
end

function MapManager:getUnitsByRange(unit, rangeType)
    local units = {}
    if rangeType == RangeType.NewUnit then
        local temp = Summon.new()
        temp:setFaction(unit:getFaction())
        temp.owner = unit
        table.insert(units, temp)
        if unit:getFaction() == UnitFaction.LEFT then
            self.deadHeroUnitList[temp:getID()] = temp
        else
            self.deadMonsterUnitList[temp:getID()] = temp
        end
    elseif rangeType == RangeType.Self then
        table.insert(units, unit)
    elseif rangeType == RangeType.SelfMatrixHero then
        units = self:getHeroByType(unit:getFaction(), unit:getType())
    elseif rangeType == RangeType.SelfMatrixAll then
        units = self:getUnitByType(unit:getFaction(), unit:getType())
    elseif rangeType == RangeType.SelfAllHero then
        units = self:getAllHero(unit:getFaction())
    elseif rangeType == RangeType.SelfAll then
        units = self:getAllUnit(unit:getFaction())
    elseif rangeType == RangeType.EnemyMatrixAll then
        units = self:getUnitByType(unit:getReverseFaction(), unit:getType())
    elseif rangeType == RangeType.EnemyAll then
        units = self:getAllUnit(unit:getReverseFaction())
    elseif rangeType == RangeType.EnemyMatrixAllHero then
        units = self:getHeroByType(unit:getReverseFaction(), unit:getType())
    elseif rangeType == RangeType.EnemyAllHero then
        units = self:getAllHero(unit:getReverseFaction())
    elseif rangeType == RangeType.EnemyMatrixFrontSingle then
        local target = unit:getTargetPtr()
        if target then
            table.insert(units, target)
        else
            local temp = self:getUnitInLine(unit:getLineIndex(), unit:getReverseFaction())
            table.insert(units, temp[1])
        end
    elseif rangeType == RangeType.EnemyMatrixFrontRow then
        units = self:getFrontUnits(unit:getReverseFaction(), 5, unit:getRowIndex())
    elseif rangeType == RangeType.EnemyMatrixFrontLine then
        local target = unit:getTargetPtr()
        if target then
            units = self:getUnitInLine(target:getLineIndex(), target:getFaction(), target:getType())
        else
            units = self:getUnitInLine(unit:getLineIndex(), unit:getReverseFaction(), unit:getType())
        end
    elseif rangeType == RangeType.EnemyMatrixFrontTwo then
        units = self:getFrontUnits(unit:getReverseFaction(), 2, unit:getLineIndex())
    elseif rangeType == RangeType.EnemyMatrixFrontThree then
        units = self:getFrontUnits(unit:getReverseFaction(), 3, unit:getLineIndex())
    elseif rangeType == RangeType.EnemyMatrixFrontFour then
        units = self:getFrontUnits(unit:getReverseFaction(), 4, unit:getLineIndex())
    elseif rangeType == RangeType.EnemyMatrixFrontRowAndLine then
        local target = unit:getTargetPtr()
        if target then
            table.insert(units, target)
        else
            local temp = self:getUnitInLine(unit:getLineIndex(), unit:getReverseFaction())
            target = temp[1]
        end

        if target then
            units = self:getUnitsInRowAndLine(target:getFaction(), target:getType(), target:getLineLocation())
        end
    elseif rangeType == RangeType.EnemyMatrixFrontRandom then
        units = self:getFrontUnits(unit:getReverseFaction(), 1)
    elseif rangeType == RangeType.EnemyMatrixRandom then
        table.insert(units, self:getUnitByRandom(unit:getReverseFaction(), unit:getType()))
    elseif rangeType == RangeType.SelfMatrixRow then
    elseif rangeType == RangeType.SelfMatrixLine then
    elseif rangeType == RangeType.SelfMatrixRowAndLine then
    elseif rangeType == RangeType.SelfMatrixRandom then
        local temp = self:getSoldierByType(unit:getFaction(), unit:getType())
        table.insert(units, temp[MyRandom:random(1, #temp)])
    elseif rangeType == RangeType.SelfMatrixRandomTwo then
        local temp = self:getSoldierByType(unit:getFaction(), unit:getType())
        local count = 2
        while #temp > 0 and count > 0 do
            local index = MyRandom:random(1, #temp)
            table.insert(units, temp[index])
            table.remove(temp, index)
            count = count - 1
        end
    elseif rangeType == RangeType.SelfMatrixRandomThree then
        local temp = self:getSoldierByType(unit:getFaction(), unit:getType())
        local count = 3
        while #temp > 0 and count > 0 do
            local index = MyRandom:random(1, #temp)
            table.insert(units, temp[index])
            table.remove(temp, index)
            count = count - 1
        end
    elseif rangeType == RangeType.SelfAroundRandom then
        local temp = self:getUnitsAround(unit:getReverseFaction(), unit:getLineLocation(), unit:getID(), 1)
        table.insert(units, temp[MyRandom:random(1, #temp)])
    elseif rangeType == RangeType.SelfAroundRandomThree then
    elseif rangeType == RangeType.SelfMatrixHeroRandom then
        local temp = self:getHeroByType(unit:getFaction(), unit:getType())
        table.insert(units, temp[MyRandom:random(1, #temp)])
    elseif rangeType == RangeType.SelfAroundAll then
        units = self:getUnitsAround(unit:getReverseFaction(), unit:getLineLocation(), unit:getID(), 1)
    elseif rangeType == RangeType.SelfMatrixNotMaxHp then
        local temp = self:getUnitsNotMaxHp(unit:getFaction(), unit:getType())
        table.insert(units, temp[1])
    elseif rangeType == RangeType.SelfMatrixNotMaxHpTwo then
        local temp = self:getUnitsNotMaxHp(unit:getFaction(), unit:getType())
        table.insert(units, temp[1])
        table.insert(units, temp[2])
    elseif rangeType == RangeType.SelfMatrixNotMaxHpThree then
        local temp = self:getUnitsNotMaxHp(unit:getFaction(), unit:getType())
        table.insert(units, temp[1])
        table.insert(units, temp[2])
        table.insert(units, temp[3])
    elseif rangeType == RangeType.SelfMatrixDeadUnitOne then
        local temp = self:getDeadUnitInMatrix(unit:getFaction(), unit:getType(), false)
        table.insert(units, temp[MyRandom:random(1, #temp)])
    elseif rangeType == RangeType.EnemyMatrixHeroRandom then
    elseif rangeType == RangeType.EnemyHeroRandom then
        local temp = self:getAllHero(unit:getReverseFaction())
        if #temp > 0 then
            table.insert(units, temp[MyRandom:random(1, #temp)])
        else
            table.insert(units, self:getUnitByRandom(unit:getReverseFaction()))
        end
    elseif rangeType == RangeType.SelfMatrixDeadUnitTwo then
        local temp = self:getDeadUnitInMatrix(unit:getFaction(), unit:getType(), false)
        local count = 2
        while #temp > 0 and count > 0 do
            local index = MyRandom:random(1, #temp)
            table.insert(units, temp[index])
            table.remove(temp, index)
            count = count - 1
        end
    elseif rangeType == RangeType.SelfMatrixDeadUnitThree then
        local temp = self:getDeadUnitInMatrix(unit:getFaction(), unit:getType(), false)
        local count = 3
        while #temp > 0 and count > 0 do
            local index = MyRandom:random(1, #temp)
            table.insert(units, temp[index])
            table.remove(temp, index)
            count = count - 1
        end
    elseif rangeType == RangeType.SelfMatrixDeadUnitFour then
        local temp = self:getDeadUnitInMatrix(unit:getFaction(), unit:getType(), false)
        local count = 4
        while #temp > 0 and count > 0 do
            local index = MyRandom:random(1, #temp)
            table.insert(units, temp[index])
            table.remove(temp, index)
            count = count - 1
        end
    elseif rangeType == RangeType.SelfDeadHeroOne then
        local temp = self:getDeadUnitInMatrix(unit:getFaction(), nil, true)
        table.insert(units, temp[MyRandom:random(1, #temp)])
    elseif rangeType == RangeType.SelfRandomMatrix then
        local utype = MyRandom:random(UnitType.INFANTRY, UnitType.CAVALRY)
        units = self:getUnitByType(unit:getFaction(), utype)
        if #units <= 0 then
            for i = UnitType.INFANTRY, UnitType.CAVALRY do
                if i ~= utype then
                    units = self:getUnitByType(unit:getFaction(), i)
                    if #units > 0 then
                        break
                    end
                end
            end
        end
    elseif rangeType == RangeType.SelfInfantryMatrix then
        units = self:getUnitByType(unit:getFaction(), UnitType.INFANTRY)
        if #units <= 0 then
            for i = UnitType.GUNNER, UnitType.CAVALRY do
                units = self:getUnitByType(unit:getFaction(), i)
                if #units > 0 then
                    break
                end
            end
        end
    elseif rangeType == RangeType.EnemyRandom then
        table.insert(units, self:getUnitByRandom(unit:getReverseFaction()))
    elseif rangeType == RangeType.SelfLeastHpHero then
        local temp = self:getUnitsNotMaxHp(unit:getFaction(), nil, true)
        table.insert(units, temp[1])
    elseif rangeType == RangeType.SelfMatrixSoldier then
        units = self:getSoldierByType(unit:getFaction(), unit:getType())
    elseif rangeType == RangeType.SelfInfantryMatrixSoldier then
        units = self:getSoldierByType(unit:getFaction(), UnitType.INFANTRY)
        if #units <= 0 then
            for i = UnitType.GUNNER, UnitType.CAVALRY do
                units = self:getSoldierByType(unit:getFaction(), i)
                if #units > 0 then
                    break
                end
            end
        end
    elseif rangeType == RangeType.SelfRandomMatrixSoldier then
        local utype = MyRandom:random(UnitType.INFANTRY, UnitType.CAVALRY)
        units = self:getSoldierByType(unit:getFaction(), utype)
        if #units <= 0 then
            for i = UnitType.INFANTRY, UnitType.CAVALRY do
                if i ~= utype then
                    units = self:getSoldierByType(unit:getFaction(), i)
                    if #units > 0 then
                        break
                    end
                end
            end
        end
    elseif rangeType == RangeType.SelfAllSoldier then
        units = self:getSoldierByType(unit:getFaction())
    elseif rangeType == RangeType.EnemyFrontHero then
        local temp = self:getFrontUnits(unit:getReverseFaction(), 5, unit:getRowIndex(), true)
        local x = 10
        local target = nil
        for i, v in ipairs(temp) do
            local y = math.abs(v:getRowIndex() - unit:getRowIndex())
            if y < x then
                x = y
                target = v
            end
        end

        if not target then
            target = unit:getTargetPtr()
        end

        table.insert(units, target)
    elseif rangeType == RangeType.SelfFrontHero then
        local temp = self:getFrontUnits(unit:getFaction(), 5, unit:getRowIndex(), true)
        local x = 10
        local target = nil
        for i, v in ipairs(temp) do
            local y = math.abs(v:getRowIndex() - unit:getRowIndex())
            if y < x then
                x = y
                target = v
            end
        end

        if not target then
            local temp = self:getFrontUnits(unit:getFaction(), 5, nil, true)
            table.insert(units, temp[MyRandom:random(1, #temp)])
        else
            table.insert(units, target)
        end
    elseif rangeType == RangeType.EnemyRandomHeroThree then
        local temp = self:getAllHero(unit:getReverseFaction())
        local count = 3
        while #temp > 0 and count > 0 and #temp > 0 do
            local index = MyRandom:random(1, #temp)
            table.insert(units, temp[index])
            table.remove(temp, index)
            count = count - 1
        end

        if #units < 3 then
            local allunits = self:getAllUnit(unit:getReverseFaction())
            while #units < 3 and #allunits > 0 do
                local index = MyRandom:random(1, #allunits)
                table.insert(units, allunits[index])
                table.remove(allunits, index)
            end
        end
    elseif rangeType == RangeType.SelfCavalrySoldier then
        units = self:getSoldierByType(unit:getFaction(), UnitType.CAVALRY)
        if #units <= 0 then
            units = self:getSoldierByType(unit:getFaction(), unit:getType())
        end
    elseif rangeType == RangeType.SelfCavalry then
        units = self:getUnitByType(unit:getFaction(), UnitType.CAVALRY)
        if #units <= 0 then
            units = self:getUnitByType(unit:getFaction(), unit:getType())
        end
    elseif rangeType == RangeType.SelfDeadInfantrySoldier then
        local temp = self:getDeadUnitInMatrix(unit:getFaction(), UnitType.INFANTRY, false)
        local count = 4
        while #temp > 0 and count > 0 do
            local index = MyRandom:random(1, #temp)
            table.insert(units, temp[index])
            table.remove(temp, index)
            count = count - 1
        end
    elseif rangeType == RangeType.EnemyLeastHpHero then
        table.insert(units, self:getLeastHpHero(unit:getReverseFaction()))
    elseif rangeType == RangeType.EnemySameNameHero then
        units = self:getMostSameNameHeros(unit:getReverseFaction())
    elseif rangeType == RangeType.SelfDeadMatrixSoldierSix then
        local temp = self:getDeadUnitInMatrix(unit:getFaction(), unit:getType(), false)
        local count = 6
        while #temp > 0 and count > 0 do
            local index = MyRandom:random(1, #temp)
            table.insert(units, temp[index])
            table.remove(temp, index)
            count = count - 1
        end
    elseif rangeType == RangeType.SelfRevivedHero then
        units = self:getRevivedHeros(unit:getFaction())
    elseif rangeType == RangeType.EnemyRevivedHero then
        units = self:getRevivedHeros(unit:getReverseFaction())
    elseif rangeType == RangeType.SelfDeadZhaoshanhe then
        local temp = self:getDeadUnit(unit:getFaction())
        for k, v in pairs(temp) do
            if v:isHero() and v.heroInfo.heroID == 3000135 then
                table.insert(units, v)
            end
        end
    elseif rangeType == RangeType.SelfCanReplace then
        local unitList = self:getUnitList(unit:getFaction())
        local unitTypeList = {UnitType.INFANTRY, UnitType.GUNNER, UnitType.ARCHER, UnitType.CAVALRY}
        while #unitTypeList > 0 do
            local index = MyRandom:random(1, #unitTypeList)
            local curType = unitTypeList[index]
            local typeList = unitList[curType]
            if typeList and #typeList > 0 then
                local findHero = nil
                local findSoldier = nil
                for kk, v in ipairs(typeList) do
                    if not findSoldier and v:isAlive() and not v:isHero() then
                        findSoldier = v
                    elseif not findHero and not v:isReplaced() and v:isAlive() and v:isHero() and v:getHeroID() ~= unit:getHeroID() then
                        findHero = v
                    end

                    if findHero and findSoldier then
                        break
                    end
                end

                if findHero and findSoldier then
                    local temp = Replace.new()
                    temp:setReplaceHeroAndSoldier(findHero, findSoldier, unit)
                    temp:setFaction(unit:getFaction())
                    table.insert(units, temp)
                    if unit:getFaction() == UnitFaction.LEFT then
                        self.deadHeroUnitList[temp:getID()] = temp
                    else
                        self.deadMonsterUnitList[temp:getID()] = temp
                    end
                    break
                end
            end

            table.remove(unitTypeList, index)
        end
    elseif rangeType == RangeType.SelfReplaced then
        local temp = self:getAllUnit(unit:getFaction())
        for k, v in pairs(temp) do
            if v:isReplaced() then
                table.insert(units, v)
            end
        end
    end

    return units
end

function MapManager:getBulletByID(id)
    local bullet = self.bulletMap[id]
    return bullet
end

function MapManager:getReverseFaction(faction)
    return (faction == UnitFaction.LEFT and UnitFaction.RIGHT) or UnitFaction.LEFT
end

function MapManager:getUnitByRandom(faction, _utype)
    local utype = utype or 0
    local units = {}--TabMg:createArrayTable(self:getUnitCount(faction))
    local unitList
    for k, factionList in ipairs(self.unitList) do
        if faction == k then
            for kk, typeList in ipairs(factionList) do
                if utype == 0 or kk == utype then
                    for kkk, unit in ipairs(typeList) do
                        if unit:isAlive() then
                            table.insert(units, unit)
                        end
                    end
                end
            end
        end
    end

    return calc.tableRandom(units)
end

function MapManager:getDeadUnit(faction)
    if faction == UnitFaction.LEFT then
        return self.deadHeroUnitList
    else
        return self.deadMonsterUnitList
    end
end

function MapManager:getLiveUnitCountInMatrix(faction, utype)
    for k, factionList in ipairs(self.unitList) do
        if faction == k then
            for kk, typeList in ipairs(factionList) do
                if kk == utype then
                    return table.nums(typeList)
                end
            end
        end
    end

    return 0
end

function MapManager:getLiveUnitCount(faction)
    return self:getUnitCount(faction)
end

function MapManager:isAllFinish()
    for k, factionList in ipairs(self.unitList) do
        for kk, typeList in ipairs(factionList) do
            for kkk, unit in ipairs(typeList) do
                if not unit:isFinish() then
                    return false
                end
            end
        end
    end

    if table.nums(self.bulletMap) > 0 then
        return false
    end

    return true
end

return MapManager