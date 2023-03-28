#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>	  // https://forums.alliedmods.net/showthread.php?t=321696
public Plugin myinfo =
{
	name		= "安全后医疗包无限使用",
	author		= "dreasye",
	description = "在进图离开安全室前和到达终点安全室后，可无限使用医疗包",
	version		= "1.0",
	url			= "https://github.com/Dreasye791/little-plugins/blob/master/heal_Infinite.sp"
};

public void OnPluginStart()
{
	HookEvent("heal_success", Event_HealSuccess);
}

public void Event_HealSuccess(Handle event, char[] name, bool dontBroadcast)
{
	int userid = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userid);
	if (L4D_IsInLastCheckpoint(client) || !L4D_HasAnySurvivorLeftSafeArea())
	{
		CreateTimer(0.0, giveFirstAid, userid);
	}
}

public Action giveFirstAid(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		giveItem(client, "first_aid_kit");
	}
	return Plugin_Continue;
}

void giveItem(int client, const char[] weapon)
{
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", weapon);
	SetCommandFlags("give", flags);
}

bool IsValidClient(int client)
{
	return ((1 <= client <= MaxClients) && IsClientInGame(client));
}
