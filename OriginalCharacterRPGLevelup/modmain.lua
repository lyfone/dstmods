local assets = 
{
    Asset("ANIM", "anim/wilson.zip"),
	Asset("ANIM", "anim/beard.zip"),
}

local TUNING = GLOBAL.TUNING
local _G = GLOBAL
local TheNet = _G.TheNet
if not (TheNet and TheNet:GetIsServer()) then return end

--根据概率执行函数
local function randomDo(rate, func, inst)
	local num = math.random()
	-- 随等级的升级影响因子
	local levelRate = math.max(0.01, 0.5 - (inst.levels - inst.levels % 10) * 0.05) 
	-- 原始概率和等级因子相乘得到最终升级概率
	local levelUpRate = rate * levelRate 
	if num <= levelUpRate then
		func(inst)
	end
	-- func(inst)
end

--根据玩家id获取玩家对象
local function GetPlayerById(playerid)
	for _, v in ipairs(_G.AllPlayers) do
		if v ~= nil and v.userid and v.userid == playerid then
			return v
		end
	end
	return nil
end

--基于等级增加饥饿速度
local function addHungerRate(inst, val, baseVal)
	inst.components.hunger:SetRate(baseVal * (1 + inst.levels * val))
end

--基于已有数据增加饥饿速度
local function addHungerRateOnNowValue(inst, val)
	inst.components.hunger:SetRate(inst.components.hunger.hungerrate * (1 + val))
end

--基于等级提升攻击
local function enhanceAttack(inst, val, baseVal)
	inst.components.combat.damagemultiplier = baseVal + inst.levels * val
end

--基于已有数据提升攻击
local function enhanceAttackOnNowValue(inst, val)
	inst.components.combat.damagemultiplier = inst.components.combat.damagemultiplier + val
end

--基于等级提升饱食度上限
local function enhanceHunger(inst, val, baseVal)
	local hunger_percent = inst.components.hunger:GetPercent()
	inst.components.hunger.max = math.ceil (baseVal + inst.levels * val)
	inst.components.hunger:SetPercent(hunger_percent)
end

--基于已有数据提升饱食度上限
local function enhanceHungerOnNowValue(inst, val)
	local hunger_percent = inst.components.hunger:GetPercent()
	inst.components.hunger.max = math.ceil (inst.components.hunger.max + val)
	inst.components.hunger:SetPercent(hunger_percent)
end

--基于等级提升血量上限
local function enhanceHealth(inst, val, baseVal)
	local health_percent = inst.components.health:GetPercent()
	inst.components.health.maxhealth = math.ceil (baseVal + inst.levels * val)
	inst.components.health:SetPercent(health_percent)
end

--基于已有数据提升血量上限
local function enhanceHealthOnNowValue(inst, val)
	local health_percent = inst.components.health:GetPercent()
	inst.components.health.maxhealth = math.ceil (inst.components.health.maxhealth + val)
	inst.components.health:SetPercent(health_percent)
end

--基于等级提升san值上限
local function enhanceSanity(inst, val, baseVal)
	local sanity_percent = inst.components.sanity:GetPercent()
	inst.components.sanity.max = math.ceil (baseVal + inst.levels * val)
	inst.components.sanity:SetPercent(sanity_percent)
end

--基于已有数据提升san值上限
local function enhanceSanityOnNowValue(inst, val)
	local sanity_percent = inst.components.sanity:GetPercent()
	inst.components.sanity.max = math.ceil (inst.components.sanity.max + val)
	inst.components.sanity:SetPercent(sanity_percent)
end

--基于等级提升移动速度
local function enhanceSpeed(inst, val, baseWalkSpeed, baseRunSpeed)
	inst.components.locomotor.walkspeed = (baseWalkSpeed * (1 + inst.levels * val))
	inst.components.locomotor.runspeed = (baseRunSpeed * (1 + inst.levels * val))
	--限制移速上限
	if inst.components.locomotor.walkspeed >= baseWalkSpeed * 2 then
		inst.components.locomotor.walkspeed = baseWalkSpeed * 2;
	end
	if inst.components.locomotor.runspeed >= baseRunSpeed * 2 then
		inst.components.locomotor.runspeed = baseRunSpeed * 2
	end
end

--基于已有数据提升移动速度
local function enhanceSpeedOnNowValue(inst, val)
	inst.components.locomotor.walkspeed = inst.components.locomotor.walkspeed * (1 + val)
	inst.components.locomotor.runspeed = inst.components.locomotor.runspeed * (1 +  val)
	--限制移速上限
	if inst.components.locomotor.walkspeed >= 4 * 3 then
		inst.components.locomotor.walkspeed = 4 * 3;
	end
	if inst.components.locomotor.runspeed >= 6 * 3 then
		inst.components.locomotor.runspeed = 6 * 3
	end
end

--基于等级提升人物防御
local function enhanceAbsorb(inst, val, baseVal)
	-- inst.components.health:SetAbsorbAmount(baseVal + inst.levels * val)
	inst.components.health.absorb = baseVal + inst.levels * val
end

--基于已有数据提升人物防御
local function enhanceAbsorbOnNowValue(inst, val)
	inst.components.health:SetAbsorbAmount(inst.components.health.absorb +  val)
end

--回复三维属性
local function healProperty(inst, data)
	inst.components.health.currenthealth = inst.components.health.currenthealth + data.health
	if inst.components.health.currenthealth >= inst.components.health.maxhealth then
		inst.components.health.currenthealth = inst.components.health.maxhealth
	end
	inst.components.hunger.current = inst.components.hunger.current + data.hunger
	if inst.components.hunger.current >= inst.components.hunger.max then
		inst.components.hunger.current = inst.components.hunger.max
	end
	inst.components.sanity.current = inst.components.sanity.current + data.sanity
	if inst.components.sanity.current >= inst.components.sanity.max then
		inst.components.sanity.current = inst.components.sanity.max
	end
end

--人物增加经验
local function addExps(inst, Exp)
	if not inst.exps then
		inst.exps = 0
	end
	Exp = math.floor(Exp * 100) / 100
	inst.exps = inst.exps + Exp
	inst.components.talker:Say('exp+'..Exp.."\n\n\n ")
	if inst.exps <= 0 then
		inst.exps = 0
	end
end

--人物升级
local function addLevel(inst)
	if inst.levels >= 100 then
		inst.components.talker:Say('level max!'.."\n\n\n ")
		inst.exps = 0
	else
		inst.levels = inst.levels + 1
		inst.components.talker:Say('level up!\nLV:'..inst.levels.."\n\n\n ")
		inst.SoundEmitter:PlaySound("dontstarve/characters/wx78/levelup")
	end
end

--影响经验获取的等级因子,每10级一个
local expFactorByLevels = {1, 1.2, 1.2, 1.5, 1.5, 1.5, 2, 2, 2, 2.5}
for i,v in ipairs(expFactorByLevels) do
	if i > 1 then
		expFactorByLevels[i] = expFactorByLevels[i] * expFactorByLevels[i-1]
	end
end

--威尔逊胡子功能函数重构
local function updateWilsonBeard(inst, day, nums)
	inst.components.beard.callbacks = {}
	inst.components.beard:AddCallback(day[1], function()
        inst.AnimState:OverrideSymbol("beard", "beard", "beard_short")
        inst.components.beard.bits = nums[1]
    end)
    inst.components.beard:AddCallback(day[2], function()
        inst.AnimState:OverrideSymbol("beard", "beard", "beard_medium")
        inst.components.beard.bits = nums[2]
    end)   
    inst.components.beard:AddCallback(day[3], function()
        inst.AnimState:OverrideSymbol("beard", "beard", "beard_long")
        inst.components.beard.bits = nums[3]
    end)
end

--更新威尔逊升级强化数据
local function updateWilson(inst)
	enhanceAttack(inst, 0.007, 1)
	enhanceHunger(inst, 1.5, 150)
	enhanceSanity(inst, 1.5, 200)
	enhanceHealth(inst, 1.5, 150)
	enhanceSpeed(inst, 0.015, 4, 6)
	--根据等级强化胡子,缩短时间和增加数量
	if inst.levels >= 100 then
		updateWilsonBeard(inst, {3, 6, 12}, {3, 6, 15})
	elseif inst.levels >= 80 then
		updateWilsonBeard(inst, {3, 6, 12}, {2, 5, 12})
	elseif inst.levels >= 60 then
		updateWilsonBeard(inst, {3, 7, 14}, {2, 4, 11})
	elseif inst.levels >= 40 then
		updateWilsonBeard(inst, {3, 7, 15}, {2, 4, 10})
	elseif inst.levels >= 20 then
		updateWilsonBeard(inst, {4, 8, 16}, {2, 4, 10})
	--下面的是测试模块
	-- else
		-- updateWilsonBeard(inst, {1, 2, 3}, {5, 6, 7})
	end
end

--威尔逊经验
local function updateWilsonExp(inst)
	if inst.levels < 100 then
		-- local Exp = 100 --测试用数据
		local Exp = 2.5 / expFactorByLevels[(math.floor( inst.levels / 10) + 1)]
		-- if inst.levels < 10 then
			-- Exp = 2
		-- elseif inst.levels < 20 then
			-- Exp = 1.5
		-- elseif inst.levels < 30 then
			-- Exp = 1
		-- elseif inst.levels < 40 then
			-- Exp = 0.8
		-- elseif inst.levels < 50 then
			-- Exp = 0.6
		-- elseif inst.levels < 60 then
			-- Exp = 0.4
		-- elseif inst.levels < 70 then
			-- Exp = 0.2
		-- elseif inst.levels < 80 then
			-- Exp = 0.1
		-- elseif inst.levels < 90 then
			-- Exp = 0.05
		-- else 
			-- Exp = 0.01
		-- end
		print(inst.prefab.." gain exp:"..Exp)
		addExps(inst, Exp) 
		if inst.exps >= 100 then
			inst.exps = inst.exps - 100
			addLevel(inst)
			updateWilson(inst)
		end
	end
end

--威尔逊pick时获取经验
local function onPick(inst)
	if inst.components.pickable then
		local pOnPickedFn = inst.components.pickable.onpickedfn
		inst.components.pickable:SetOnPickedFn(function(inst, picker, loot)
			pOnPickedFn(inst, picker, loot)
			if picker.prefab == "wilson" then
				updateWilsonExp(picker)
			end
		end)
	end
end

--给能够pick的物品添加函数
AddPrefabPostInit("sapling", onPick)
AddPrefabPostInit("marsh_bush", onPick)
AddPrefabPostInit("reeds", onPick)
AddPrefabPostInit("grass", onPick)
AddPrefabPostInit("berrybush2", onPick)
AddPrefabPostInit("berrybush", onPick)
AddPrefabPostInit("flower_cave", onPick)
AddPrefabPostInit("flower_cave_double", onPick)
AddPrefabPostInit("flower_cave_triple", onPick)
AddPrefabPostInit("red_mushroom", onPick)
AddPrefabPostInit("green_mushroom", onPick)
AddPrefabPostInit("blue_mushroom", onPick)
AddPrefabPostInit("cactus", onPick)
AddPrefabPostInit("lichen", onPick)

--威尔逊work时获取经验
local function onWork(inst, data)
	if inst.prefab == "wilson" then
		updateWilsonExp(inst)
	end
end

--威尔逊build时获取经验
local function onBuild(inst, data)
	if inst.prefab == "wilson" then
		updateWilsonExp(inst)
	end
end

--更新维克波顿升级强化数据
local function updateWickerbottom(inst)
	enhanceAttack(inst, 0.005, 1)
	enhanceHunger(inst, 1, 150)
	enhanceSanity(inst, 1, 250)
	enhanceHealth(inst, 1, 150)
	enhanceSpeed(inst, 0.01, 4, 6)
	--根据等级增加科技
	if inst.levels >= 100 then
		inst.components.builder.science_bonus = 2
		inst.components.builder.magic_bonus = 3
		inst.components.builder.ancient_bonus = 4
	elseif inst.levels >= 80 then
		inst.components.builder.science_bonus = 2
		inst.components.builder.magic_bonus = 3
		inst.components.builder.ancient_bonus = 2
	elseif inst.levels >= 60 then
		inst.components.builder.science_bonus = 2
		inst.components.builder.magic_bonus = 3
		inst.components.builder.ancient_bonus = 0
	elseif inst.levels >= 40 then
		inst.components.builder.science_bonus = 2
		inst.components.builder.magic_bonus = 2
		inst.components.builder.ancient_bonus = 0
	elseif inst.levels >= 20 then
		inst.components.builder.science_bonus = 2
		inst.components.builder.magic_bonus = 1
		inst.components.builder.ancient_bonus = 0
	end
end

--增加维克波顿经验
local function updateWickerbottomExpByRead(reader)
	if inst.levels < 100 then
		local inst = reader
		local Exp = 30 / expFactorByLevels[(math.floor( inst.levels / 10) + 1)]
		-- if inst.levels < 10 then
			-- Exp = 20
		-- elseif inst.levels < 20 then
			-- Exp = 10
		-- elseif inst.levels < 30 then
			-- Exp = 5
		-- elseif inst.levels < 40 then
			-- Exp = 3
		-- elseif inst.levels < 50 then
			-- Exp = 2
		-- elseif inst.levels < 60 then
			-- Exp = 1
		-- elseif inst.levels < 70 then
			-- Exp = 0.75
		-- elseif inst.levels < 80 then
			-- Exp = 0.5
		-- elseif inst.levels < 90 then
			-- Exp = 0.25
		-- end
		addExps(inst, Exp) 
		print(inst.prefab.." gain exp:"..Exp)
		if inst.exps >= 100 then
			inst.exps = inst.exps - 100
			addLevel(inst)
			updateWickerbottom(inst)
		end
	end
end

-- 绑定函数到五类书本上
AddPrefabPostInit("book_sleep", function(inst)
	local readfn = inst.components.book.onread
	inst.components.book.onread = function(inst, reader)
		if reader.prefab == "wickerbottom" then
			updateWickerbottomExpByRead(reader)
		end
		local pUse = inst.components.finiteuses.current
		readfn(inst, reader)
		if pUse == inst.components.finiteuses:GetUses() then
			inst.components.finiteuses:Use()
		end
	end
end)
AddPrefabPostInit("book_gardening", function(inst)
	local readfn = inst.components.book.onread
	inst.components.book.onread = function(inst, reader)
		if reader.prefab == "wickerbottom" then
			updateWickerbottomExpByRead(reader)
		end
		local pUse = inst.components.finiteuses.current
		readfn(inst, reader)
		if pUse == inst.components.finiteuses:GetUses() then
			inst.components.finiteuses:Use()
		end
	end
end)
AddPrefabPostInit("book_brimstone", function(inst)
	local readfn = inst.components.book.onread
	inst.components.book.onread = function(inst, reader)
		if reader.prefab == "wickerbottom" then
			updateWickerbottomExpByRead(reader)
		end
		local pUse = inst.components.finiteuses.current
		readfn(inst, reader)
		if pUse == inst.components.finiteuses:GetUses() then
			inst.components.finiteuses:Use()
		end
	end
end)
AddPrefabPostInit("book_birds", function(inst)
	local readfn = inst.components.book.onread
	inst.components.book.onread = function(inst, reader)
		if reader.prefab == "wickerbottom" then
			updateWickerbottomExpByRead(reader)
		end
		local pUse = inst.components.finiteuses.current
		readfn(inst, reader)
		if pUse == inst.components.finiteuses:GetUses() then
			inst.components.finiteuses:Use()
		end
	end
end)
AddPrefabPostInit("book_tentacles", function(inst)
	local readfn = inst.components.book.onread
	inst.components.book.onread = function(inst, reader)
		if reader.prefab == "wickerbottom" then
			updateWickerbottomExpByRead(reader)
		end
		local pUse = inst.components.finiteuses.current
		readfn(inst, reader)
		if pUse == inst.components.finiteuses:GetUses() then
			inst.components.finiteuses:Use()
		end
	end
end)

local function updateWolfgang(inst)
	--增加基本属性
	-- enhanceHunger(inst, 1, 200)
	enhanceSanity(inst, 1, 200)
	-- enhanceHealth(inst, 1, 200)
	enhanceSpeed(inst, 0.01, 4, 6)
	
	--增加特性：通过改变血量和攻击倍率以及饥饿速率的关系
	TUNING.WOLFGANG_HUNGER = 300 + 1 * inst.levels
	TUNING.WOLFGANG_START_HUNGER = 200 + 0.66 * inst.levels
	TUNING.WOLFGANG_START_MIGHTY_THRESH = 225 + 0.75 * inst.levels
	TUNING.WOLFGANG_END_MIGHTY_THRESH = 220 + 0.73 * inst.levels
	TUNING.WOLFGANG_START_WIMPY_THRESH = 100 + 0.33 * inst.levels
	TUNING.WOLFGANG_END_WIMPY_THRESH = 105 + 0.35 * inst.levels
	
	TUNING.WOLFGANG_HEALTH_MIGHTY = 300 + 1 * inst.levels
	TUNING.WOLFGANG_HEALTH_NORMAL = 200 + 0.66 * inst.levels
	TUNING.WOLFGANG_HEALTH_WIMPY = 150 + 0.5 * inst.levels
		
	--饥饿速率随等级下降
	TUNING.WOLFGANG_HUNGER_RATE_MULT_MIGHTY = 3 - 0.01 * inst.levels
	TUNING.WOLFGANG_HUNGER_RATE_MULT_NORMAL = 1.5 - 0.005 * inst.levels
	TUNING.WOLFGANG_HUNGER_RATE_MULT_WIMPY = 1 - 0.003 * inst.levels
		
	--攻击增幅随等级改变
	TUNING.WOLFGANG_ATTACKMULT_MIGHTY_MAX = 2 + 0.015 * inst.levels		--最大值3.5
	TUNING.WOLFGANG_ATTACKMULT_MIGHTY_MIN = 1.25 + 0.01 * inst.levels 	--最大值2.25
	TUNING.WOLFGANG_ATTACKMULT_NORMAL = 1 + 0.005 * inst.levels			--最大值1.5
	TUNING.WOLFGANG_ATTACKMULT_WIMPY_MAX = .75 + 0.005 * inst.levels	--最大值1.25
	TUNING.WOLFGANG_ATTACKMULT_WIMPY_MIN = .5 + 0.0025 * inst.levels	--最大值0.75
	
	local percent = inst.components.hunger:GetPercent()
	inst.components.hunger:SetMax(TUNING.WOLFGANG_HUNGER)
	inst.components.hunger:SetPercent(percent)
	
end

local function updateWolfgangExpByEat(inst, food)
	if inst.levels < 100 then
		local Exp = 0
		if food then
			--怪物肉基础经验为-10
			if food.prefab == "monstermeat" or food.prefab == "cookedmonstermeat" then
				Exp = -10
			--怪物千层饼基础经验为-30
			elseif food.prefab == "monsterlasagna" then
				Exp = -30
			--软心糖豆基础经验为70
			elseif food.prefab == "jellybean" or food.prefab == "royal_jelly" then
				Exp = 70
			--鱼系列基础经验为30
			elseif food.prefab == "fishsticks" or food.prefab == "fishtacos" then
				Exp = 25
			--蛋系列基础经验为30
			elseif food.prefab == "baconeggs" or food.prefab == "perogies" or food.prefab == "tallbirdegg" or food.prefab == "tallbirdegg_cooked" then
				Exp = 30
			--蜂蜜系列基础经验为30
			elseif food.prefab == "honeyham" or food.prefab == "honeynuggets" or food.prefab == "taffy" then
				Exp = 35
			--蝴蝶黄油系列基础经验为60
			elseif food.prefab == "waffles" or food.prefab == "butter" or food.prefab == "goatmilk" then
				Exp = 60
			--BOSS掉落物基础经验为100
			elseif food.prefab == "deerclops_eyeball" or food.prefab == "minotaurhorn" then
				Exp = 100
			--其他食物10点经验
			else
				Exp = 10
			end
		end
		
		--根据等级降低经验数量,当经验为负数，即扣除经验时，不受等级因子影响
		if Exp > 0 then
			Exp = Exp / expFactorByLevels[(math.floor( inst.levels / 10) + 1)]
		-- if inst.levels < 10 then
			-- Exp = Exp
		-- elseif inst.levels < 20 then
			-- Exp = Exp / 1.5
		-- elseif inst.levels < 30 then
			-- Exp = Exp / 1.5
		-- elseif inst.levels < 40 then
			-- Exp = Exp / 2
		-- elseif inst.levels < 50 then
			-- Exp = Exp / 2
		-- elseif inst.levels < 60 then
			-- Exp = Exp / 2
		-- elseif inst.levels < 70 then
			-- Exp = Exp / 2.5
		-- elseif inst.levels < 80 then
			-- Exp = Exp / 2.5
		-- elseif inst.levels < 90 then
			-- Exp = Exp / 3
		-- end
		end
		
		--曼德拉系列直接升级
		if food.prefab == "mandrakesoup" or food.prefab == "mandrake" or food.prefab == "cookedmandrake" then
			Exp = 100
		end
		
		--测试代码
		-- Exp = 50
		print(inst.prefab.." gain exp:"..Exp)
		addExps(inst, Exp) 
		if inst.exps >= 100 then
			inst.exps = inst.exps - 100
			addLevel(inst)
			updateWolfgang(inst)
		end
	end
end

--重置buff时间，消除buff
local function resetWathgrithrBuffer(inst)
	inst.buffMaxTime = 0
	inst.buffTime = 0
	if inst.task then 
		inst.task:Cancel() 
		inst.task = nil 
	end
	inst.buffOn = false
	inst.components.talker:Say("buff end!")
end

--女武神攻击回血设置
local function turnOnOrOffHealByAttack(inst, data)
	if data.flag then
		inst.healHealthByAttack = true
		inst.healHealthNumberByAttack = data.value
	else
		inst.healHealthByAttack = false
		inst.healHealthNumberByAttack = 0
	end
end

--20级buff,period是触发周期
local function addBuff20ToWathgrithr(inst, period)
	inst.buffTime = inst.buffTime + period
	if inst.components.talker then
		inst.components.talker:Say("left time of buff : "..(inst.buffMaxTime - inst.buffTime).."\n\n\n ")
	end
	--[[
	触发效果:治愈模式
		1.周期性回复三维属性
	--]]
	healProperty(inst, {hunger = 1,health = 1, sanity = 1})
	
	if (inst.buffTime + period) > inst.buffMaxTime then
		resetWathgrithrBuffer(inst)
	end
end

--40级buff,period是触发周期
local function addBuff40ToWathgrithr(inst, period)
	inst.buffTime = inst.buffTime + period
	if inst.components.talker then
		inst.components.talker:Say("left time of buff : "..(inst.buffMaxTime - inst.buffTime).."\n\n\n ")
	end
	--[[
	触发效果:战神模式
		1.周期性回复三维属性
		2.临时强化攻击
	--]]	
	healProperty(inst, {hunger = 1.1,health = 1.1, sanity = 1.1})
	enhanceAttack(inst, 0.006, 1.25)
	
	if (inst.buffTime + period) > inst.buffMaxTime then
		resetWathgrithrBuffer(inst)
		--消除增益
		enhanceAttack(inst, 0.005, 1.25)
	end
end

--60级buff,period是触发周期
local function addBuff60ToWathgrithr(inst, period)
	inst.buffTime = inst.buffTime + period
	if inst.components.talker then
		inst.components.talker:Say("left time of buff : "..(inst.buffMaxTime - inst.buffTime).."\n\n\n ")
	end
	--[[
	触发效果:嗜血模式
		1.周期性回复三维属性
		2.临时强化攻击
		3.攻击回血
	--]]
	healProperty(inst, {hunger = 1.2,health = 1.2, sanity = 1.2})
	enhanceAttack(inst, 0.007, 1.25)
	turnOnOrOffHealByAttack(inst, {flag = true, value = 1})
	
	if (inst.buffTime + period) > inst.buffMaxTime then
		resetWathgrithrBuffer(inst)
		--消除增益
		enhanceAttack(inst, 0.005, 1.25)
		turnOnOrOffHealByAttack(inst, {flag = false})
	end
end

--80级buff,period是触发周期
local function addBuff80ToWathgrithr(inst, period)
	inst.buffTime = inst.buffTime + period
	if inst.components.talker then
		inst.components.talker:Say("left time of buff : "..(inst.buffMaxTime - inst.buffTime).."\n\n\n ")
	end
	--[[
	触发效果:狂暴模式
		1.周期性回复三维属性
		2.临时强化攻击
		3.攻击回血
		4.临时增加移速和攻速
	--]]
	healProperty(inst, {hunger = 1.3,health = 1.3, sanity = 1.3})
	enhanceAttack(inst, 0.008, 1.25)
	turnOnOrOffHealByAttack(inst, {flag = true, value = 1.25})
	inst.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD * 1.25)
	enhanceSpeedOnNowValue(inst, 0.25)
	
	if (inst.buffTime + period) > inst.buffMaxTime then
		resetWathgrithrBuffer(inst)
		--消除增益
		enhanceAttack(inst, 0.005, 1.25)
		turnOnOrOffHealByAttack(inst, {flag = false})
		inst.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD)
		enhanceSpeedOnNowValue(inst, -0.25)
	end
end

--100级buff,period是触发周期
local function addBuff100ToWathgrithr(inst, period)
	inst.buffTime = inst.buffTime + period
	if inst.components.talker then
		inst.components.talker:Say("left time of buff : "..(inst.buffMaxTime - inst.buffTime).."\n\n\n ")
	end
	--[[
	触发效果:天神模式
		1.周期性回复三维属性
		2.临时强化攻击
		3.攻击回血
		4.临时增加移速和攻速
		5.短暂无敌状态
	--]]
	healProperty(inst, {hunger = 1.5,health = 1.5, sanity = 1.5})
	enhanceAttack(inst, 0.01, 1.25)
	turnOnOrOffHealByAttack(inst, {flag = true, value = 1.5})
	inst.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD * 1.5)
	enhanceSpeedOnNowValue(inst, 0.5)
	inst.components.health.absorb = 1
	
	--前1/3时间是无敌的
	if (inst.buffTime / inst.buffMaxTime) >= 0.33 then
		enhanceAbsorb(inst, 0.0025, 0.25)
	end
		
	if (inst.buffTime + period) > inst.buffMaxTime then
		resetWathgrithrBuffer(inst)
		--消除增益
		enhanceAttack(inst, 0.005, 1.25)
		turnOnOrOffHealByAttack(inst, {flag = false})
		inst.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD)
		enhanceSpeedOnNowValue(inst, -0.5)
		enhanceAbsorb(inst, 0.0025, 0.25)
	end
end

--女武神升级获得特性
local function addWathgrithrCharacteristicsByLevels(inst)
	if inst.components.talker then
		inst.components.talker:Say("Gain a Buff!")
	end
	print("gain buff")
	inst.buffOn = true
	if inst.levels >= 100 then
		--触发20次，触发周期3秒
		local period = 3
		if inst.buffMaxTime == 0 and inst.buffTime == 0 then
			inst.buffMaxTime = 61
			inst.buffTime = 0
		end
		inst.task = inst:DoPeriodicTask(period, function() addBuff100ToWathgrithr(inst, period) end)
	elseif inst.levels >= 80 then
		--触发16次，触发周期4秒
		local period = 4
		if inst.buffMaxTime == 0 and inst.buffTime == 0 then
			inst.buffMaxTime = 64
			inst.buffTime = 0
		end
		inst.task = inst:DoPeriodicTask(period, function() addBuff80ToWathgrithr(inst, period) end)
	elseif inst.levels >= 60 then
		--触发14次，触发周期4秒
		local period = 4
		if inst.buffMaxTime == 0 and inst.buffTime == 0 then
			inst.buffMaxTime = 57
			inst.buffTime = 0
		end
		inst.task = inst:DoPeriodicTask(period, function() addBuff60ToWathgrithr(inst, period) end)
	elseif inst.levels >= 40 then
		--触发12次，触发周期5秒
		local period = 5
		if inst.buffMaxTime == 0 and inst.buffTime == 0 then
			inst.buffMaxTime = 61
			inst.buffTime = 0
		end
		inst.task = inst:DoPeriodicTask(period, function() addBuff40ToWathgrithr(inst, period) end)
	elseif inst.levels >= 20 then
		--触发10次，触发周期5秒
		local period = 5
		if inst.buffMaxTime == 0 and inst.buffTime == 0 then
			inst.buffMaxTime = 51
			inst.buffTime = 0
		end
		inst.task = inst:DoPeriodicTask(period, function() addBuff20ToWathgrithr(inst, period) end)
	end
end

--更新女武神升级强化数据
local function updateWathgrithr(inst)
	enhanceAttack(inst, 0.005, 1.25)
	enhanceHunger(inst, 1, 120)
	enhanceSanity(inst, 1, 120)
	enhanceHealth(inst, 1, 200)
	enhanceSpeed(inst, 0.01, 4 ,6)
	enhanceAbsorb(inst, 0.0025, 0.25)
end

--重置女武神击杀和伤害记录
local function resetWathgrithrHarmAndKillen(inst)
	inst.causeHarm = 0
	inst.killedNumber = 0
end

--记录女武神造成伤害
local function updateWathgrithrCauseHarm(inst, victim, damage)
	print("attacker : "..inst.prefab.."\nvictimer : "..victim.prefab.."\ndamage : "..damage)
	if inst and (not inst.buffOn) then
		inst.causeHarm  = inst.causeHarm + damage
	end
	if inst.causeHarm >= (2500 + math.floor(inst.levels / 5) * 200) then
		addWathgrithrCharacteristicsByLevels(inst)
		resetWathgrithrHarmAndKillen(inst)
	end
	if inst.healHealthByAttack == true then
		healProperty(inst, {hunger = 0, health = inst.healHealthNumberByAttack, sanity = 0})
	end
end

--记录女武神击杀
local function updateWathgrithrKilledNumber(inst)
	inst.killedNumber = inst.killedNumber + 1
	if inst.killedNumber >= (math.floor(inst.levels / 5) + 15) then
		addWathgrithrCharacteristicsByLevels(inst)
		resetWathgrithrHarmAndKillen(inst)
	end
end

--女武神击杀获取经验
local function updateWathgrithrExpByKill(inst, data)
	if inst.levels < 100 then
		local victim = data.victim
		local Exp = 0
		--发条生物系列基础经验为30
		if victim.prefab == "knight" or 
			victim.prefab == "bishop" or 
			victim.prefab == "rook" or
			victim.prefab == "knight_nightmare" or
			victim.prefab == "bishop_nightmare" or
			victim.prefab == "rook_nightmare"
		then
			Exp = 30
		--脚印系列生物基础经验为
		elseif victim.prefab == "koalefant_summer" or victim.prefab == "koalefant_winter" or victim.prefab == "walrus" or victim.prefab == "warg" or victim.prefab == "spat" then
			Exp = 50
		--牛、疯猪等基础经验为
		elseif victim.prefab == "deer" or victim.prefab == "beefalo" or victim.prefab == "werepig" or victim.prefab == "lightninggoat" or victim.prefab == "tallbird" then
			Exp = 40
		--其他怪物全部基础经验为
		elseif victim:HasTag("monster") then
			Exp = 10
		--击杀其他非怪物会减少经验
		else
			Exp = -10
		end
		--TODO 继续细分各种怪物的数值
		
		--根据等级降低经验数量,当经验为负数，即扣除经验时，不受等级因子影响
		if Exp >= 0 then
			Exp = Exp / expFactorByLevels[(math.floor( inst.levels / 10) + 1)]
			-- if inst.levels < 10 then
				-- Exp = Exp
			-- elseif inst.levels < 20 then
				-- Exp = Exp / 1.5
			-- elseif inst.levels < 30 then
				-- Exp = Exp / 1.5
			-- elseif inst.levels < 40 then
				-- Exp = Exp / 2
			-- elseif inst.levels < 50 then
				-- Exp = Exp / 2
			-- elseif inst.levels < 60 then
				-- Exp = Exp / 2
			-- elseif inst.levels < 70 then
				-- Exp = Exp / 2.5
			-- elseif inst.levels < 80 then
				-- Exp = Exp / 2.5
			-- elseif inst.levels < 90 then
				-- Exp = Exp / 3
			-- end
		end
		
		--特殊BOSS生物获取固定经验
		--三季BOSS每20级经验降低
		if victim.prefab == "deerclops" or victim.prefab == "bearger" or victim.prefab == "moose" then
			Exp = 100 / (math.floor(inst.levels / 20) + 1)
		--蜘蛛女王，树精，石虾每10级降低
		elseif victim.prefab == "leif" or victim.prefab == "spiderqueen" or victim.prefab == "rocky" then
			Exp = 50 / (math.floor(inst.levels / 10) + 1)
		--蚁狮,远古守护者，赃物包BOSS每30级降低
		elseif victim.prefab == "antlion" or victim.prefab == "minotaur" or victim.prefab == "klaus" then
			Exp = 300 / (math.floor(inst.levels / 30) + 1)
		--龙蝇和蜂后每40级降低
		elseif victim.prefab == "dragonfly" or victim.prefab == "beequeen" then
			Exp = 600 / (math.floor(inst.levels / 40) + 1)
		--召唤之骨每25级降低
		elseif victim.prefab == "stalker" or victim.prefab == "stalker_forest" then
			Exp = 150 / (math.floor(inst.levels / 25) + 1)
		--远古暗影编织者每35级降低
		elseif victim.prefab == "stalker_atrium" then
			Exp = 400 / (math.floor(inst.levels / 35) + 1)
		--毒菌蟾蜍每50级降低
		elseif victim.prefab == "toadstool" then
			Exp = 700 / (math.floor(inst.levels / 50) + 1)
		--悲苦蟾蜍每60级降低
		elseif victim.prefab == "toadstool_dark" then
			Exp = 1000 / (math.floor(inst.levels / 60) + 1)
		end
		
		--测试代码
		-- Exp = 100
		
		--限制最多只能连升五级
		if Exp >= 500 then
			Exp = 500
		end
		
		--记录击杀数量和造成伤害
		if not inst.buffOn then
			updateWathgrithrKilledNumber(inst)
		end
		
		addExps(inst, Exp) 
		print(inst.prefab.." gain exp:"..Exp)
		if inst.exps >= 100 then
			local levels = math.floor(inst.exps / 100)
			inst.exps = inst.exps - levels * 100
			-- inst.exps = inst.exps - 100
			for i = 1, levels do
				addLevel(inst)
			end
			-- addLevel(inst)
			updateWathgrithr(inst)
		end
	end
end

--更新玩家属性函数数组
local UpdatePlayerPropertyFns = {
	["wilson"] = updateWilson,
	["wickerbottom"] = updateWickerbottom,
	["wathgrithr"] = updateWathgrithr,
	["wolfgang"] = updateWolfgang,
}

--更新玩家属性数据
local function UpdatePlayerProperty(inst)
	UpdatePlayerPropertyFns[inst.prefab](inst)
end

--储存等级和经验
local function onSave(inst, data)
	data.levels = inst.levels
	data.exps = inst.exps
	if inst.prefab == "wathgrithr" then
		data.killedNumber = inst.killedNumber
		data.causeHarm = inst.causeHarm
		data.buffMaxTime = inst.buffMaxTime
		data.buffTime = inst.buffTime
		data.healHealthByAttack = inst.healHealthByAttack
		data.healHealthNumberByAttack = inst.healHealthNumberByAttack
		data.buffOn = inst.buffOn
	end
end

--加载数据
local function onpreload(inst, data)
	if data and data.levels and data.exps then
		inst.levels = data.levels or 0
		inst.exps = data.exps or 0
		inst.exps = math.floor(inst.exps * 100) / 100
		if inst.prefab == "wickerbottom" then
			updateWickerbottom(inst)
		elseif inst.prefab == "wilson" then
			updateWilson(inst)
		elseif inst.prefab == "wolfgang" then
			updateWolfgang(inst)
		elseif inst.prefab == "wathgrithr" then
			inst.killedNumber = data.killedNumber or 0
			inst.causeHarm = data.causeHarm or 0
			inst.buffMaxTime = data.buffMaxTime or 0
			inst.healHealthByAttack = data.healHealthByAttack or false
			inst.healHealthNumberByAttack = data.healHealthNumberByAttack or 0
			inst.buffOn = data.buffOn or false
			if data.buffTime then
				inst.buffTime = data.buffTime
			else
				inst.buffTime = inst.buffMaxTime
			end
			updateWathgrithr(inst)
			if inst.buffOn then
				addWathgrithrCharacteristicsByLevels(inst)
			end
		end
	else
		inst.levels = 0
		inst.exps = 0
		if inst.prefab == "wathgrithr" then
			inst.killedNumber = 0
			inst.causeHarm = 0
			inst.buffMaxTime = 0
			inst.buffTime = 0
		end
	end
	if data.hunger and data.hunger.hunger then inst.components.hunger.current = data.hunger.hunger end
	if data.sanity and data.sanity.current then inst.components.sanity.current = data.sanity.current end
	if data.health and data.health.health then inst.components.health.currenthealth = data.health.health end
	inst.components.hunger:DoDelta(0)
	inst.components.sanity:DoDelta(0)
	inst.components.health:DoDelta(0)
	if inst.levels == 100 then
		inst.components.talker:Say('当前等级 : max !\n\n\n ')
	else
		inst.components.talker:Say('当前等级:'..inst.levels.."\n当前经验："..inst.exps.."\n\n\n ")
	end
end

--威尔逊的功能
local function FnWilson(inst)
	--初始化等级
	inst.levels = 0
	inst.exps = 0
	--设置保存函数，在存档时调用
	inst.OnSave = onSave
	--设置预加载函数，在人物预加载时调用
	inst.OnPreLoad = onpreload
	--添加工具使用监听事件
	inst:ListenForEvent("working", onWork)
	--添加制作监听事件
	inst:ListenForEvent("builditem", onBuild)
	inst:ListenForEvent("buildstructure", onBuild)
end

--维克波顿的功能
local function FnWickerbottom(inst)
	--初始化等级
	inst.levels = 0
	inst.exps = 0
	--设置保存函数，在存档时调用
	inst.OnSave = onSave
	--设置预加载函数，在人物预加载时调用
	inst.OnPreLoad = onpreload
end

--沃尔夫冈的功能
local function FnWolfgang(inst)
	--初始化等级
	inst.levels = 0
	inst.exps = 0
	--设置监听函数
	inst.components.eater:SetOnEatFn(updateWolfgangExpByEat)
	--设置保存函数，在存档时调用
	inst.OnSave = onSave
	--设置预加载函数，在人物预加载时调用
	inst.OnPreLoad = onpreload
end

--女武神的功能
local function FnWathgrithr(inst)
	--初始化等级
	inst.levels = 0
	inst.exps = 0
	inst.killedNumber = 0
	inst.causeHarm = 0
	inst.buffMaxTime = 0
	inst.buffTime = 0
	inst.healHealthByAttack = false
	inst.healHealthNumberByAttack = 0
	inst.buffOn = false
	--onhitother函数
	inst.components.combat.onhitotherfn = updateWathgrithrCauseHarm
	--设置保存函数，在存档时调用
	inst.OnSave = onSave
	--设置预加载函数，在人物预加载时调用
	inst.OnPreLoad = onpreload
	--添加击杀监听事件
	inst:ListenForEvent("killed", updateWathgrithrExpByKill, inst)
	--添加攻击监听事件
	-- inst:ListenForEvent("attacked", updateWathgrithrCauseHarm)
end

--绑定功能到人物上
AddPlayerPostInit(function(inst)
	if inst.prefab == "wickerbottom" then
		FnWickerbottom(inst)
	elseif inst.prefab == "wilson" then
		FnWilson(inst)
	elseif inst.prefab == "wolfgang" then
		FnWolfgang(inst)
	elseif inst.prefab == "wathgrithr" then
		FnWathgrithr(inst)
	end
end)

--限制玩家重复选人
local function despawnplayer(inst)
	GLOBAL.TheNet:Announce("游戏中已经存在"..(GLOBAL.STRINGS.CHARACTER_TITLES[inst.prefab] or inst.prefab).." ,请 "..inst:GetDisplayName().." 重新选一位角色"  )
	inst:DoTaskInTime(2, function()
		GLOBAL.TheWorld:PushEvent("ms_playerdespawnanddelete", inst)
	end)
end

AddPlayerPostInit(function(inst)
	if GLOBAL.TheWorld.ismastersim then
		inst:DoPeriodicTask(3, function()
			if type(GLOBAL.AllPlayers) == "table" then
				local age = inst.components.age and inst.components.age:GetAge() or 0
				local numAgeLargerThanMe = 0
				for k, v in pairs(GLOBAL.AllPlayers) do
					if v and v.prefab == inst.prefab and v ~= inst then
						local ageother = v.components.age and v.components.age:GetAge() or 0
						if ageother > age then
							numAgeLargerThanMe = numAgeLargerThanMe + 1
						end
					end
				end
				if numAgeLargerThanMe >= 1 then
					despawnplayer(inst)
				end
			end
			
		end)
	end
end)

--其他功能指令
local ORDERS = {
	["#givebuff"] = 1,
}

--升级指令
local MSG_CHOOSE = {
	--提升一个等级
	["#levelup"] = 1,
	--提升十个等级
	["#levelupex"] = 10,
}

--查询玩家状态数据
local STATUE_MSG = {
	--显示经验和等级状况
	["#expstatus"] = 1,
	--显示buff触发状况
	["#buffstatus"] = 2,
}

--显示等级玩家状态
local function showPlayerStatus(inst)
	local lvs = inst.levels or 0
	local xps = inst.exps or 0
	if lvs == 100 then
		lvs = "max"
		xps = "max"
	end
	local status_string = "levels : "..lvs.."\nExps : "..xps.."\n\n\n "
	if inst.components.talker then
		inst.components.talker:Say(status_string, 5)
	end
end

--显示玩家增益累计数据信息，如女武神击杀或者伤害累计
local function showPlayerAccumulativeStatus(inst)
	if inst.prefab == "wathgrithr" then
		local killednum = inst.killedNumber or 0
		local harmnum = inst.causeHarm or 0
		local buffstatus = "false"
		if inst.buffOn then
			buffstatus = "true"
		end
		local bufflefttime = 0
		if inst.buffMaxTime and inst.buffTime then
			bufflefttime = inst.buffMaxTime - inst.buffTime
		end
		local status_string = "kill numbers : "..killednum.."\nharm amounts : "..harmnum.."\nbuff status : "..buffstatus.."\nbuff left time : "..bufflefttime.."\n"
		if inst.components.talker then
			inst.components.talker:Say(status_string, 5)
		end
	end
end

-- 更改说话函数，添加升级指令话语,查询状态信息等
local Old_Networking_Say = _G.Networking_Say
_G.Networking_Say = function(guid, userid, name, prefab, message, colour, whisper, isemote, ...)
	Old_Networking_Say(guid, userid, name, prefab, message, colour, whisper, isemote, ...)
	local player = GetPlayerById(userid)
	if player then
		if TheNet:GetIsServerAdmin() and player.components and player.Network:IsServerAdmin() then
			local choose = MSG_CHOOSE[string.lower(message)]
			local order = ORDERS[string.lower(message)]
			if choose then
				for i = 1, choose do
					addLevel(player)
				end
				UpdatePlayerProperty(player)
			end
			if order == 1 then
				if player.prefab == "wathgrithr" then
					addWathgrithrCharacteristicsByLevels(player)
				end
			end
		end
		
		local status_choose = STATUE_MSG[string.lower(message)]
		if status_choose == 1 then
			showPlayerStatus(player)
		elseif status_choose == 2 then
			showPlayerAccumulativeStatus(player)
		end
	end
end