local OpenServerFile = OpenServerFile
local Equip = OpenServerFile("Equip")
local SoldierEquip = OpenServerFile("SoldierEquip")

local EquipFactory = class("EquipFactory")

function EquipFactory.createEquip(equipInfo, faction)
	local equip = nil

    -- if equipInfo.class == UnitType.BOSS then
        equip = SoldierEquip.new()
    -- else
    --     equip = Equip.new()
    -- end
    
    equip:init(equipInfo)
    MapManager:addEquip(equip, faction)
    
	return equip
end

return EquipFactory