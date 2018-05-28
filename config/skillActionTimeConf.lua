--[[
	freestartint， movestart:每三位为一组表示帧数、intValue、floatValue
	duang ----
	trigger --- :每两位为一组表示帧数、intValue
	end：表示结尾帧数

	[bone] 表示骨骼名字，以及两个为一组的坐标，多个顺序表示atk，skill_a,skill_b, skill_c此骨骼的位置
]]

local skillActionTimeConf = {
------------------------------4个兵种------------------------------
	["infantry"] = {
		["atk"] = {
			{"trigger", 12, 1},
			{"end", 24},
		},
		["s01"] = {
			{"trigger", 12, 1},
			{"end", 24},
		},
		["s02"] = {
			{"trigger", 12, 1},
			{"end", 24},
		},
		["bone"] = {
			{"hit_point", 0.98, 29.47},
		},
	},
	["gunner"] = {
		["atk"] = {
			{"trigger", 30, 1},
			{"end", 40},
		},
		["atk2"] = {
			{"trigger", 12, 1},
			{"end", 24},
		},
		["s01"] = {
			{"trigger", 30, 1},
			{"end", 40},
		},
		["s02"] = {
			{"trigger", 12, 1},
			{"end", 24},
		},
		["bone"] = {
			{"hit_point", 0.98, 29.47},
		},
	},
	["archer"] = {
		["atk"] = {
			{"trigger", 30, 1},
			{"end", 72},
		},
		["atk2"] = {
			{"trigger", 12, 1},
			{"end", 24},
		},
		["s01"] = {
			{"trigger", 30, 1},
			{"end", 40},
		},
		["s02"] = {
			{"trigger", 12, 1},
			{"end", 24},
		},
		["bone"] = {
			{"hit_point", 0.98, 29.47},
		},
	},
	["cavalry"] = {
		["atk"] = {
			{"trigger", 12, 1},
			{"end", 24},
		},
		["s01"] = {
			{"trigger", 12, 1},
			{"end", 24},
		},
		["s02"] = {
			{"trigger", 12, 1},
			{"end", 24},
		},
		["bone"] = {
			{"hit_point", 0.98, 29.47},
		},
	},


------------------------------特殊英雄------------------------------
	["ashoka"] = {
		["atk"] = {
			{"trigger", 30, 1},
			{"end", 40},
		},
		["atk2"] = {
			{"trigger", 12, 1},
			{"end", 24},
		},
		["s01"] = {
			{"trigger", 12, 1},
			{"end", 24},
		},
		["s02"] = {
			{"trigger", 30, 1},
			{"end", 40},
		},
		["bone"] = {
			{"hit_point", 0.98, 29.47},
		},
	},

------------------------------Boss end------------------------------
	["bossdragon"] = {
		--zhongwen = "龙boss",
		["atk"] = {
			{"trigger", 14, 1},
			{"end", 30},
		},
		["atkfar"] = {
			{"trigger", 32, 1},
			{"end", 48},
		},
		["atknear"] = {
			{"trigger", 12, 1},
			{"end", 24},
		},
		["bone"] = {
			{"hit_point", -18.5, 171.0},
			{"bullet", -161.1, -18.4},
		},
	},
	["humanboss"] = {
		--zhongwen = "龙boss",
		["atk"] = {
			{"trigger", 14, 1},
			{"end", 30},
		},
		["atkfar"] = {
			{"trigger", 32, 1},
			{"end", 48},
		},
		["atknear"] = {
			{"trigger", 12, 1},
			{"end", 24},
		},
		["bone"] = {
			{"hit_point", -18.5, 71.0},
			{"bullet", -161.1, -18.4},
		},
	},
------------------------------Boss end------------------------------
}

return skillActionTimeConf