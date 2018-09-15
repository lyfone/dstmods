local TUNING = GLOBAL.TUNING
local require = GLOBAL.require

--保鲜程度
TUNING.PERISH_FRIDGE_MULT = GetModConfigData("iceboxfresh")

--背包保鲜选项
local backpackperishtime = GetModConfigData("perishtime")
--背包冷藏保暖石
local freezethermal = GetModConfigData("thermal")
local function moreFridge(inst)
	if backpackperishtime  == true and  not inst:AddTag("fridge") then
		inst:AddTag("fridge")
	end
	if nofreezethermal == false then
		inst:AddTag("nocool")
	end
end
AddPrefabPostInit("backpack", moreFridge)
AddPrefabPostInit("piggyback", moreFridge)
AddPrefabPostInit("krampus_sack", moreFridge)

--一次性施肥
local fertilizeonce = GetModConfigData("fertilizeonce")
if fertilizeonce == true then
	TUNING.BERRYBUSH_CYCLES = 9999999999
end
local function fertilizeOnce(inst)
	if inst.prefab == "grass" then
		inst.components.pickable.max_cycles = 9999999999
		inst.components.pickable.cycles_left = 9999999999
	end
end
AddPrefabPostInit("grass", fertilizeOnce)

--快速拾取
local quickpick = GetModConfigData("quickpick")
local function QuickPick(inst)
	if inst.components.pickable then
	inst.components.pickable.quickpick = true
	end
end
if quickpick == true then
	AddPrefabPostInit("sapling", QuickPick)
	AddPrefabPostInit("marsh_bush", QuickPick)
	AddPrefabPostInit("reeds", QuickPick)
	AddPrefabPostInit("grass", QuickPick)
	AddPrefabPostInit("berrybush2", QuickPick)
	AddPrefabPostInit("berrybush", QuickPick)
	AddPrefabPostInit("flower_cave", QuickPick)
	AddPrefabPostInit("flower_cave_double", QuickPick)
	AddPrefabPostInit("flower_cave_triple", QuickPick)
	AddPrefabPostInit("red_mushroom", QuickPick)
	AddPrefabPostInit("green_mushroom", QuickPick)
	AddPrefabPostInit("blue_mushroom", QuickPick)
	AddPrefabPostInit("cactus", QuickPick)
	AddPrefabPostInit("lichen", QuickPick)
end

--保暖石无限使用
local NoThermalStoneDurability = GetModConfigData("NoThermalStoneDurability")
local old_TemperatureChange
local old_heatrock_fn
local function new_TemperatureChange(inst, data)
	inst.components.fueled = {
		GetPercent = function() return 1 end,
		SetPercent = function() end,
	}
	old_TemperatureChange(inst, data)
	inst.components.fueled = nil
end
local function new_heatrock_fn(inst)
	if GLOBAL.TheWorld.ismastersim then
		inst:RemoveComponent("fueled")

		local function switchListenerFns(t)
			local listeners = t["temperaturedelta"]
			local listener_fns = listeners[inst]
			old_TemperatureChange = listener_fns[1]
			listener_fns[1] = new_TemperatureChange
		end

		switchListenerFns(inst.event_listeners)
		switchListenerFns(inst.event_listening)
	end
end
if NoThermalStoneDurability == true then
	AddPrefabPostInit("heatrock", new_heatrock_fn)
end


--禁止草蜥蜴
local nograssgekko = GetModConfigData("nograssgekko")
if nograssgekko == true then
	local modmastersim = GLOBAL.TheNet:GetIsMasterSimulation()

	local SpawnPrefab = GLOBAL.SpawnPrefab
	-- no more grass morphing
	TUNING.GRASSGEKKO_MORPH_CHANCE = 0
	-- no more disease appearing
	TUNING.DISEASE_CHANCE = 0
	TUNING.DISEASE_DELAY_TIME = 0
	TUNING.DISEASE_DELAY_TIME_VARIANCE = 0

	if modmastersim then
		-- gekkos into grass
		local function TurnIntoGrass(inst)
			local x, y, z = inst.Transform:GetWorldPosition()
			local grass = SpawnPrefab("grass")
			grass.Transform:SetPosition(x, y, z)
			inst:Remove()
		end
		local function DelaySwap(inst)
			inst:DoTaskInTime(0, TurnIntoGrass)
		end
		AddPrefabPostInit("grassgekko", DelaySwap)

		-- cure stuff if there is something diseased
		local function TurnIntoNormal(inst)
			local x, y, z = inst.Transform:GetWorldPosition()
			local normal = SpawnPrefab(inst.prefab)
			normal.Transform:SetPosition(x, y, z)
			inst:Remove()
		end
		local function DelayCure(self)
			if self:IsDiseased() or self:IsBecomingDiseased() then
				self.inst:DoTaskInTime(0, TurnIntoNormal)
			end
		end
		AddComponentPostInit("diseaseable", DelayCure)
	end
end

--物品堆叠上限
local stackable_replica = require "components/stackable_replica"
local size = GetModConfigData("stacksize")
local net_byte = GLOBAL.net_byte

TUNING.STACK_SIZE_LARGEITEM = size
TUNING.STACK_SIZE_MEDITEM = size
TUNING.STACK_SIZE_SMALLITEM = size 

local stackable_replica_ctorBase = stackable_replica._ctor or function() return true end    
function stackable_replica._ctor(self, inst)
    self.inst = inst

    self._stacksize = net_byte(inst.GUID, "stackable._stacksize", "stacksizedirty")
    self._maxsize = size
end

local stackable_replicaSetMaxSize_Base = stackable_replica.SetMaxSize or function() return true end
function stackable_replica:SetMaxSize(maxsize)
	self._maxsize = size
end

local stackable_replicaMaxSize_Base = stackable_replica.MaxSize or function() return true end
function stackable_replica:MaxSize()
	return self._maxsize
end