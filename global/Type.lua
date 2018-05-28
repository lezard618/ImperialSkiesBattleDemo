
AttributeType = {
	life = 1,  --生命
	attack = 2, --攻击
	offset = 3, --格挡
	dodge = 4, --回避
	crit = 5, --暴击
	hurtAll = 6,
	hurtInfantry = 7,
	hurtGunner = 8,
	hurtArcher = 9,
	hurtCavalry = 10,
	hurtHero = 11,
	sufferAll = 12,
	sufferInfantry = 13,
	sufferGunner = 14,
	sufferArcher = 15,
	sufferCavalry = 16,
	sufferHero = 17,
	critDamage = 18,
	resistanceInfantry = 19,
	resistanceGunner = 20,
	resistanceArcher = 21,
	resistanceCavalry = 22,
}

UnitInfo = {uid = 0, lockID = 0}

function UnitInfo:reset()
    self.uid = 0
    self.lockID = 0
end

function UnitInfo:seed()
    self.uid = self.uid + 1
    return self.uid
end

BulletInfo = {bid = 0}

function BulletInfo:reset()
    self.bid = 0
end

function BulletInfo:seed()
    self.bid = self.bid + 1
    return self.bid
end

function BulletInfo.isForever(duration)
    return duration >= 9999
end

GameStateType = {}
GameStateType.PLAYING = 0
GameStateType.PAUSE = 1
GameStateType.COMPLETE = 2
GameStateType.EXIT = 3

BulletPursueType = {}
BulletPursueType.FOLLOW = 0
BulletPursueType.DESTINATION = 1

BulletMoveType = {}
BulletMoveType.LINE = 0
BulletMoveType.PARABOLA = 1

BuffClass = {}
BuffClass.Battle = 0
BuffClass.BattleAssist = 1
BuffClass.SelfAssist = 2
BuffClass.World = 3
BuffClass.Equip = 11


CavalryStateNone = 0
CavalryStateRush = 1
CavalryStateRun = 2
CavalryStateSlowDown = 3
CavalryStateGoBack = 4

ArcherNone = 0
ArcherInFightDis = 1
ArcherOutFightDis = 2
ArcherFarShoot = 3

ConfigSkillType = {}
ConfigSkillType.NORMAL = "SkillType.Normal"
ConfigSkillType.POWER = "SkillType.PowerMax"
ConfigSkillType.ACTIVE = "SkillType.Special"
ConfigSkillType.PASSIVE = "SkillType.Passive"
ConfigSkillType.ENTERING = "SkillType.Entering"

SkillClassType = {}
SkillClassType.ACTIVE = 1           --主动技能:替换攻击
SkillClassType.ADDITIVE = 2         --附加技能:自己的回合前释放
SkillClassType.PASSIVE = 3          --被动技能
SkillClassType.CONDITION = 4        --条件技能

SkillCondition = {}
SkillCondition.SelfHpUp = 1         	-- 1.自身血量高于（百分比）
SkillCondition.SelfHpDown = 2       	-- 2.自身血量低于（百分比）
SkillCondition.TargetHpUp = 3       	-- 3.对手血量高于（百分比）
SkillCondition.TargetHpDown = 4     	-- 4.对手血量低于（百分比）
SkillCondition.SelfMatrixDown = 5   	-- 5.己阵数量低于（百分比）
SkillCondition.SelfDead = 6         	-- 6.自身死亡
SkillCondition.SelfInfantryDown = 7 	-- 7.己方步兵数量低于（百分比）
SkillCondition.SelfHeroDead = 8     	-- 8.己方有英雄死亡
SkillCondition.SelfSpecialDead = 9  	-- 9.固定目标英雄死亡
SkillCondition.SelfCanReplace = 10 		-- 10.场上至少有1个同兵种的士兵和1个英雄存在

BeforeChanceTypeCondition = {}
BeforeChanceTypeCondition.Level = 1        -- 1.升20级
BeforeChanceTypeCondition.Strenth = 2      -- 2.强化10级
BeforeChanceTypeCondition.SameName = 3     -- 3.拥有同名英雄（英雄A有3个，就生效2次；英雄B再有2个，就再多生效1次，总共3次，以此类推）

ChanceTypeCondition = {}
ChanceTypeCondition.AfterCritical = 1 		-- 1.暴击后
ChanceTypeCondition.AfterBlock = 2 			-- 2.格挡后
ChanceTypeCondition.AfterReplace = 3 		-- 3.替换后
ChanceTypeCondition.SelfDead = 4 			-- 4.己方死亡后
ChanceTypeCondition.EnemyDead = 5 			-- 5.敌方死亡后


UnitFaction = {}
UnitFaction.LEFT = 1
UnitFaction.RIGHT = 2

UnitState = {}
UnitState.NONE = 0
UnitState.BIRTH = 1
UnitState.DIE = 2
UnitState.STAND = 3
UnitState.WALK = 4
UnitState.CLOSE_TO = 5
UnitState.ATTACK = 6
UnitState.PRE_ATTACK = 7
UnitState.USE_SKILL = 8
UnitState.WINER = 9
UnitState.WAVE_ENTER = 10
UnitState.WAIT = 11
UnitState.BEATBACK = 99    --击退，只作为类型判断
UnitState.AB_STATE = 100
UnitState.STUN = 101                --晕眩
UnitState.TWINE = 102               --缠绕
UnitState.EDDY = 103                --漩涡
UnitState.BREAK = 104               --打断
UnitState.FLY = 105                 --击飞
UnitState.FLY_STUN = 106            --击飞后晕眩
UnitState.PALSY = 107               --麻痹
UnitState.STONE = 108               --石化
UnitState.SUPPRESS = 109            --陷落
UnitState.SILENCE = 110             --沉默
UnitState.TAUNT = 111               --嘲讽
UnitState.STONE_PREV = 112          --石化前置阶段
UnitState.BONDAGE_STAND = 113       --沙之束缚
UnitState.BONDAGE_STAND_PREV = 114  --沙之束缚前置阶段
UnitState.CHARM = 115 				--魅惑
UnitState.SLEEP = 116				--睡眠
UnitState.IMMUNE = 117              --免疫异常状态！
UnitState.INVINCIBIE = 118          --无敌 --蛋疼的状态
UnitState.SKILLSTAND = 119          --boss技能stand

CoexistStateOptLevel = {}
CoexistStateGroup = {}

UnitType = {}
UnitType.NONE = 0
UnitType.INFANTRY = 1
UnitType.GUNNER = 2
UnitType.ARCHER = 3
UnitType.CAVALRY = 4
UnitType.BOSS = 5

UnitStance = {}
UnitStance.FRONT = 1
UnitStance.MIDDLE = 2
UnitStance.BACK = 3

DamageType = {}
DamageType.INSTANT = 1      --瞬间伤害
DamageType.DOT = 2          --持续伤害
DamageType.REFELECT = 3     --反弹伤害
DamageType.CLEAVE = 4       --分裂伤害

SpecialEffectType = {}
SpecialEffectType.ForbiddenSkill = 1 		--禁止释放技能
SpecialEffectType.ForbiddenAttack = 2 		--禁止攻击
SpecialEffectType.SuckBlood = 3 			--吸血
SpecialEffectType.AddThroughEnergy = 4 		--增加骑兵贯穿值
SpecialEffectType.AddSkillOdds = 5 			--增加技能释放几率
SpecialEffectType.Immune = 6 				--免疫异常状态(缴械、沉默、中毒)
SpecialEffectType.Hit = 7 					--必中
SpecialEffectType.Replace = 8 				--复制英雄
SpecialEffectType.Seal = 9 					--封印技能
SpecialEffectType.Unseal = 10 				--解封技能
SpecialEffectType.NoBlock = 11 				--不会被格挡
SpecialEffectType.Shapeshift = 12			--变身

NodeZorder = {}
NodeZorder.UI = 999999
NodeZorder.SKY = 99999
NodeZorder.GROUND = -99999
NodeZorder.UPPER = 10
NodeZorder.LOWER = -10
NodeZorder.TRACK_BULLET = 70
NodeZorder.NORMAL = 0
NodeZorder.BG = -999999

RangeType = {}
RangeType.NewUnit = 0									-- 0.新增一个单位
RangeType.EnemyMatrixFrontSingle = 1					-- 1.敌阵面前单体
RangeType.EnemyMatrixFrontRow = 2						-- 2.敌阵面前列
RangeType.EnemyMatrixFrontLine = 3						-- 3.敌阵面前行
RangeType.EnemyMatrixFrontTwo = 4						-- 4.敌阵面前2个
RangeType.EnemyMatrixFrontThree = 5						-- 5.敌阵面前3个
RangeType.EnemyMatrixFrontFour = 6						-- 6.敌阵面前4个
RangeType.EnemyMatrixFrontRowAndLine = 7				-- 7.敌阵面前列+行
RangeType.EnemyMatrixFrontRandom = 8					-- 8.敌阵面前行随机
RangeType.EnemyMatrixRandom = 9							-- 9.敌阵中随机
RangeType.EnemyMatrixAll = 10							-- 10.敌阵全体
RangeType.EnemyAll = 11									-- 11.敌军全体
RangeType.Self = 12										-- 12.自己
RangeType.SelfMatrixHero = 13							-- 13.己阵所有英雄
RangeType.SelfMatrixRow = 14							-- 14.己阵所在列
RangeType.SelfMatrixLine = 15							-- 15.己阵所在行
RangeType.SelfMatrixRowAndLine = 16						-- 16.己阵所在行+列
RangeType.SelfMatrixRandom = 17							-- 17.己阵随机目标（不包括英雄）
RangeType.SelfMatrixRandomTwo = 18						-- 18.己阵随机目标2个（不包括英雄）
RangeType.SelfMatrixRandomThree = 19					-- 19.己阵随机目标3个（不包括英雄）
RangeType.SelfAroundRandom = 20							-- 20.自己周围随机
RangeType.SelfAroundRandomThree = 21					-- 21.自己周围随机3个
RangeType.SelfMatrixHeroRandom = 22						-- 22.己阵随机英雄
RangeType.SelfAroundAll = 23							-- 23.自己周围全部
RangeType.SelfMatrixAll = 24							-- 24.己阵全体
RangeType.SelfAllHero = 25								-- 25.己军所有英雄
RangeType.SelfAll = 26									-- 26.己军所有目标
RangeType.SelfMatrixNotMaxHp = 27						-- 27.血量不满的目标(本阵)
RangeType.SelfMatrixNotMaxHpTwo = 28					-- 28.血量不满的2个目标(本阵)
RangeType.SelfMatrixNotMaxHpThree = 29					-- 29.血量不满的3个目标(本阵)
RangeType.SelfMatrixDeadUnitOne = 30					-- 30.1个死亡士兵(本阵)
RangeType.EnemyMatrixHeroRandom = 31					-- 31.敌阵随机英雄
RangeType.EnemyMatrixAllHero = 32						-- 32.敌阵全部英雄
RangeType.EnemyHeroRandom = 33							-- 33.敌方随机英雄
RangeType.EnemyAllHero = 34								-- 34.敌方全部英雄
RangeType.SelfMatrixDeadUnitTwo = 35					-- 35.2个死亡士兵(本阵)
RangeType.SelfMatrixDeadUnitThree = 36					-- 36.3个死亡士兵(本阵)
RangeType.SelfMatrixDeadUnitFour = 37					-- 37.4个死亡士兵(本阵)
RangeType.SelfDeadHeroOne = 38							-- 38.1个死亡英雄
RangeType.SelfRandomMatrix = 39							-- 39.己方随机兵种
RangeType.SelfInfantryMatrix = 40						-- 40.己方所有步兵
RangeType.EnemyRandom = 41								-- 41.敌方随机
RangeType.SelfLeastHpHero = 42							-- 42.己军中血量最少的英雄
RangeType.SelfMatrixSoldier = 43						-- 43.己阵所有士兵（不包括英雄）
RangeType.SelfInfantryMatrixSoldier = 44				-- 44.步兵阵所有士兵（不包括英雄）（最靠前方阵）
RangeType.SelfRandomMatrixSoldier = 45					-- 45.随机阵所有士兵（不包括英雄）
RangeType.SelfAllSoldier = 46							-- 46.我军全体（不包括英雄）
RangeType.EnemyFrontHero = 47							-- 47.敌军最前排英雄
RangeType.SelfFrontHero = 48							-- 48.我军最前排英雄
RangeType.EnemyRandomHeroThree = 49						-- 49.敌军随机3个英雄
RangeType.SelfCavalrySoldier = 50						-- 50.己方骑兵阵所有士兵（不包括英雄）（没有骑兵则释放给本方阵）
RangeType.SelfCavalry = 51								-- 51.己方骑兵方阵（没有骑兵则释放给本方阵）
RangeType.SelfDeadInfantrySoldier = 52					-- 52.己方死亡步兵士兵
RangeType.EnemyLeastHpHero = 53							-- 53.敌方血量最少的英雄
RangeType.EnemySameNameHero = 54						-- 54.敌方同名数量最多的英雄
RangeType.SelfDeadMatrixSoldierSix = 55					-- 55.6个死亡的本阵士兵
RangeType.SelfRevivedHero = 56							-- 56.己方被复活过的英雄
RangeType.EnemyRevivedHero = 57							-- 57.敌方被复活过的英雄
RangeType.SelfDeadZhaoshanhe = 100						-- 100.己方死亡的赵山河
RangeType.SelfCanReplace = 101							-- 101.满足条件的置换的目标
RangeType.SelfReplaced = 102							-- 102.被置换的目标

UnitFightState = {}
UnitFightState.NoTarget = 1
UnitFightState.CloseToTarget = 2
UnitFightState.WaitForFight = 3
UnitFightState.Fighting = 4
UnitFightState.FinishFight = 5

DefaultValue = {}
DefaultValue.HERO_SPINE_SCALE = 1

LevelModeType = {}
LevelModeType.NORMAL = 0

MaxUnitInMatrix = 25
MaxUnitInLine = 5
UnitSpace = 90
UnitYSpace = 25

UnitStartLocationY = -290
UnitStartLocationBlanking = 1420

LeftLineAdjust = {{x = 0, y = 0}, {x = -20, y = -25}, {x = 20, y = 25}, {x = -40, y = -50}, {x = 40, y = 50}}
RightLineAdjust = {{x = 0, y = 0}, {x = 20, y = -25}, {x = -20, y = 25}, {x = 40, y = -50}, {x = -40, y = 50}}
LineScale = {0.9, 0.95, 0.85, 1, 0.8}

CavalryMaxEnergy = 100
MaxBackgroundCount = 6
BackgroundSingleWidth = 1175

MaxRound = 50

ExtraParamType = {
	TeamType = 1,		--队伍类型
	StatueBuff = 2,		--是否享受遗迹buff，0享受，1不享受
	MaxHeroNum = 3,		--最大上阵英雄数量
}


-- 0.BUFF拥有者（默认）
-- 1.步兵(包含职业为步兵的英雄)
-- 2.火枪(包含职业为火枪的英雄)
-- 3.弓箭(包含职业为弓箭的英雄)
-- 4.骑兵(包含职业为骑兵的英雄)
-- 5.英雄
-- 6.防御部队
-- 7.协助驻防部队
-- 8.出征攻击其他城堡部队（单独）
-- 9.攻打野怪的部队
-- 10.集火野外BOSS的部队
-- 11.步兵士兵(不包含职业为步兵的英雄)
-- 12.火枪士兵(不包含职业为火枪的英雄)
-- 13.弓箭士兵(不包含职业为弓箭的英雄)
-- 14.骑兵士兵(不包含职业为骑兵的英雄)
-- 15.集火攻击其他城堡部队
-- 16.攻击或者占领“粒子巨炮”的部队
-- 17.攻击或者占领“军事要塞”的部队
-- 18.攻击或者占领“能源核心”的部队
-- 19.攻击或者占领“巨龙洞穴”的部队
-- 21.职业为步兵的英雄
-- 22.职业为火枪的英雄
-- 23.职业为弓箭的英雄
-- 24.职业为骑兵的英雄
-- 99.身上带有异常状态(缴械、沉默)
TakeEffectType = {
	None = 0,
	Infantry = 1,
	Gunner = 2,
	Archer = 3,
	Cavalry = 4,
	Hero = 5,
	DeffenceTeam = 6,
	HelpeDeffence = 7,
	AttackTeam = 8,
	MonsterAttack = 9,
	BossAttack = 10,
	InfantrySoldier = 11,
	GunnerSoldier = 12,
	ArcherSoldier = 13,
	CavalrySoldier = 14,
	AttackGroup = 15,
	AttackBomb = 16,
	AttackMilitary = 17,
	AttackSource = 18,
	AttackCave = 19,
	InfantryHero = 21,
	GunnerHero = 22,
	ArcherHero = 23,
	CavalryHero = 24,
	Forbiddened = 99,
}


BulletBehaviorType = {
	createAnim = 1,
	start = 2,
	arrive = 3,
	hitEffect = 4,
	playAnim = 5,
}

UnitBehaviorType = {
	state = 1,
	location = 2,
	useSkill = 3,
	recordHp = 4,
	handleEvent = 5,
	floatWord = 6,
	beatback = 7,
	reduceHp = 8,
	healHp = 9,
	walk = 10,
	additiveSkill = 11,
	activeBuff = 12,
	removeBuff = 13,
	conditionSkill = 14,
	summon = 15,
	revive = 16,
	conditionBuff = 17,
	switch = 18,
}

CameraBehaviorType = {
	location = 1,
	move = 2,
	rush = 3,
}

LevelStateType = {
	INIT = 0,
	SHOW = 1,
	START_ROUND = 2,
	GUNNER_START = 3,
	GUNNER_FIGHT = 4,
	ARCHER_START = 5,
	ARCHER_FIGHT = 6,
	INFANTRY_START = 7,
	INFANTRY_FIGHT = 8,
	CAVALRY_START = 9,
	CAVALRY_FIGHT = 10,
	INTERVAL = 11,
	END_ROUND = 12,
	EXIT = 13,
	BOSS_START_AFTER_GUNNER = 14,
	BOSS_FIGHT_AFTER_GUNNER = 15,
	BOSS_START_AFTER_ARCHER = 16,
	BOSS_FIGHT_AFTER_ARCHER = 17,
}