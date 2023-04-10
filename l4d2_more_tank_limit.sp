#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

public Plugin myinfo =
{
	name		= "L4D2 1+ Tank Health Limit",
	author		= "Dreasye",
	description = "限制多坦克血量",
	version		= "1.0",
	url			= "https://github.com/Dreasye791/little-plugins/blob/master/l4d2_more_tank_limit.sp"
};

#define Z_TANK		   8
#define TEAM_INFECTED  3

#define TANK_LIMIT	   1

#define NOT_A_TANK	   -1
#define NOT_SET_HEALTH 0
#define HAD_SET_HEALTH 1

int tankClients[32] = { NOT_A_TANK, ... };

public void OnPluginStart()
{
	HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_Post);
	HookEvent("player_death", TankDeath);
	HookEvent("round_start", ClearData);
}

public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client))
	{
		return;
	}
	tankClients[client] = NOT_SET_HEALTH;
	// 导演系统在这时候还没有统计克数量,需要 +1 返回正确数量
	int tankCount		= L4D2_GetTankCount() + 1;
	if (tankCount > TANK_LIMIT)
	{
		RequestFrame(checkAllTankHealth);
	}
}

public void TankDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && IsInfected(client) && IsTank(client))
	{
		tankClients[client] = NOT_A_TANK;
	}
}

public void ClearData(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i < sizeof(tankClients); i++)
	{
		tankClients[i] = NOT_A_TANK;
	}
}

public void setTankHealthByClient(int client)
{
	if (!IsValidClient(client))
	{
		return;
	}
	setTankHealth(client);
}

public void setTankHealth(int client)
{
	int health	  = GetEntProp(client, Prop_Send, "m_iHealth");
	int MaxHealth = GetEntProp(client, Prop_Send, "m_iMaxHealth");
	SetEntProp(client, Prop_Data, "m_iHealth", health / 2);
	SetEntProp(client, Prop_Data, "m_iMaxHealth", MaxHealth / 2);
	PrintToChatAll("\x04[提示]\x05坦克数量到达上限，\x03坦克%s\x05血量调整为\x04:\x03%d", GetSurvivorName(client, true), health / 2);
}

public void checkAllTankHealth()
{
	for (int i = 1; i < sizeof(tankClients); i++)
	{
		if (tankClients[i] == NOT_SET_HEALTH)
		{
			setTankHealthByClient(i);
			tankClients[i] = HAD_SET_HEALTH;
		}
	}
}

bool IsValidClient(int client)
{
	return (client > 0 && client < MaxClients);
}

bool IsTank(int client)
{
	return (GetEntProp(client, Prop_Send, "m_zombieClass") == Z_TANK);
}

bool IsInfected(int client)
{
	return (IsClientInGame(client) && GetClientTeam(client) == TEAM_INFECTED);
}

char[] GetSurvivorName(int client, bool bPromptType)
{
	char sName[32];
	GetClientName(client, sName, sizeof(sName));
	if (!IsFakeClient(client))
		FormatEx(sName, sizeof(sName), "%s%N", !bPromptType ? "" : "\x04", sName);
	else
		SplitString(sName, "Tank", sName, sizeof(sName));
	return sName;
}
