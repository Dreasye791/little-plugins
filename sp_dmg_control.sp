#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

public Plugin myinfo =
{
	name		= "特感伤害控制",
	author		= "dreasye",
	description = "",
	version		= "1.0",
	url			= ""
};

ConVar difficulty;
char   difficultyCodes[4][32]  = { "Easy", "Normal", "Hard", "Impossible" };
float  difficultyMultiplier[4] = { 0.5, 0.7, 0.7, 1.0 };
float  chargerCoopDamages[4]   = { 5.0, 10.0, 15.0, 20.0 };
int	   difficultyType;

public void OnPluginStart()
{
	difficulty = FindConVar("z_difficulty");
	HookEvent("player_spawn", Event_PlayerSpawn);
	// HookEvent("player_death", Event_PlayerDeath);
	getVars();
}

public void OnConfigsExecuted()
{
	getVars();
}

public void getVars()
{
	char difficultyString[32];
	GetConVarString(difficulty, difficultyString, sizeof(difficultyString));
	for (int i = 0; i < sizeof(difficultyCodes); i++)
	{
		if (StrEqual(difficultyString, difficultyCodes[i], false))
		{
			difficultyType = i;
		}
	}
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && IsSurvivor(client) && IsRealClient(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeChargerDamage);
	}
}

// void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
// {
// 	int client = GetClientOfUserId(event.GetInt("userid"));
// 	if (IsValidClient(client) && IsSurvivor(client))
// 	{
// 		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeChargerDamage);
// 	}
// }
public Action OnTakeChargerDamage(int victim, int &attacker, int &inflictor, float &damage, int &damageType)
{
	if (IsValidClient(attacker) && IsCharger(attacker))
	{
		PrintToChatAll("此攻击伤害为 %f,type为 %i,验证伤害为 %f", damage, damageType, chargerCoopDamages[difficultyType]);
		if (damage == chargerCoopDamages[difficultyType])
		{
			damage = damage * difficultyMultiplier[difficultyType];
			return Plugin_Changed;
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

bool IsCharger(int client)
{
	return GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 6;
}

bool IsValidClient(int client)
{
	return ((1 <= client <= MaxClients) && IsClientInGame(client));
}

bool IsSurvivor(int client)
{
	return IsClientInGame(client) && GetClientTeam(client) == 2;
}

bool IsRealClient(int client)
{
	return !IsFakeClient(client) && !IsClientObserver((client));
}