name = "Easy DST Plug"
description = "Easy DST Plug v1.0\n 综合多种便捷简化功能，具体内容在配置选项当中查看！"
author = "lyfone"
version = "1.0.1"
forumthread = ""

api_version = 10

--mod兼容
dst_compatible = true
reign_of_giants_compatible = true
dont_starve_compatible = false

--服务器mod
all_clients_require_mod = true
clients_only_mod = false

server_filter_tags = {}

configuration_options =
{
	{
		name = "perishtime",
		label = "背包保鲜",
		options =
	{
		{description = "On", data = true},
		{description = "off", data = false},
	},
		default = true,
	},
	{
		name = "thermal",
		label = "背包冷藏保暖石",
		options =
	{
		{description = "No", data = false},
		{description = "Yes", data = true},
	},
		default = true,
	},
	{
		name = "iceboxfresh",
		label = "冰箱保鲜",
		options = 
	{
		{description = "Normal", data = 0.5},
		{description = "Always", data = 0},
	},
		default = 0,
	},
	{
		name = "fertilizeonce",
		label = "一次性施肥",
		options = 
	{
		{description = "On", data = true},
		{description = "Off", data = false},
	},
		default = true,
	},
	{
		name = "quickpick",
		label = "快速拾取",
		options = 
	{
		{description = "On", data = true},
		{description = "Off", data = false},
	},
		default = true,
	},
	{
		name = "NoThermalStoneDurability",
		label = "消除保暖石耐久",
		options = 
	{
		{description = "On", data = true},
		{description = "Off", data = false},
	},
		default = true,
	},
	{
		name = "nograssgekko",
		label = "禁止草蜥蜴",
		options = 
	{
		{description = "On", data = true},
		{description = "Off", data = false},
	},
		default = true,
	},
	{
		name = "stacksize",
		label = "物品堆叠上限",
		options = 
	{
		{description = "64", data = 64},
		{description = "99", data = 99},
		{description = "128", data = 128},
		{description = "256", data = 256},
		{description = "512", data = 512},
		{description = "999", data = 999},
	},
		default = 99,
	},
}