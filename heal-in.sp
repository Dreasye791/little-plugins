#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>	  // https://forums.alliedmods.net/showthread.php?t=321696

public Plugin myinfo = {
	name		= "Name",
	author		= "Author",
	description = "Description",
	version		= "Version",
	url			= "URL"
};

public void OnPluginStart()
{
}

public Action L4D2_OnUseHealingItems(int client)
{
	PrintToChatAll("%N正在使用治疗物品", client);
	return Plugin_Continue;
}