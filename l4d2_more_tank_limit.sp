#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name		= "L4D2 1+ Tank Health Limit",
	author		= "Dreasye",
	description = "限制多坦克血量",
	version		= "1.0",
	url			= ""
};

#define Z_TANK		   8
#define TEAM_INFECTED  3

#define TANK_LIMIT	   1

#define NOT_A_TANK	   -1
#define NOT_SET_HEALTH 0
#define HAD_SET_HEALTH 1

int tankCount;
int tankClients[32] = { NOT_A_TANK, ... };

public void OnPluginStart()
{
	HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_Pre);
	HookEvent("player_death", TankDeath);
	tankCount = 0;
}

public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client))
	{
		return;
	}
	tankClients[client] = NOT_SET_HEALTH;
	tankCount++;

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
		tankCount--;
		if (tankCount < 0)
		{
			tankCount = 0;
		}
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
	for (int i = 0; i < sizeof(tankClients); i++)
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
