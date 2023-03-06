#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name		= "NoRepactChat",
	author		= "Dreasye",
	description = "禁止频繁的重复发言",
	version		= "1.0",
	url			= ""
};

#define REPACT_RANGE 10
#define REPACT_LIMIT 2
#define GAG_SECOND	 10.0
#define RESET_SECOND 10.0

int			lastTime[MAXPLAYERS + 1], replayTime[MAXPLAYERS + 1];
char		lastChat[MAXPLAYERS][1024];
Handle		replayTimer[MAXPLAYERS + 1];

native bool BaseComm_SetClientGag(int client, bool bState);
native bool BaseComm_IsClientGagged(int client);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("BaseComm_SetClientGag");
	MarkNativeAsOptional("BaseComm_IsClientGagged");
	return APLRes_Success;
}

public void OnPluginStart()
{
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say2");
	AddCommandListener(Command_Say, "say_team");
}

public Action Command_Say(int client, const char[] command, any args)
{
	char message[1024];
	GetCmdArgString(message, sizeof(message));

	if (StrEqual(lastChat[client], message))
	{
		if (lastTime[client] + REPACT_RANGE > GetTime())
		{
			if (BaseComm_IsClientGagged(client))
			{
				return Plugin_Handled;
			}
			replayTime[client]++;
			createResetTimerTimer(client);
			if (replayTime[client] > REPACT_LIMIT)
			{
				PrintToChatAll("[GAG] %N 重复发言过多，暂时禁言.", client);
				BaseComm_SetClientGag(client, true);
				CreateTimer(GAG_SECOND, gagTimerHandle, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
				replayTime[client] = 0;
				return Plugin_Handled;
			}
		}
	}

	strcopy(lastChat[client], PLATFORM_MAX_PATH, message);
	lastTime[client] = GetTime();
	// char t[100];
	// Format(t, 100, "最后发言时间：%i, %s...%s", lastTime[client], lastChat[client], message);
	// PrintToServer(t);
	return Plugin_Continue;
}

public Action gagTimerHandle(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (checkClient(client))
	{
		BaseComm_SetClientGag(client, false);
	}
	return Plugin_Continue;
}

public Action removeRePlayTimeHandle(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (checkClient(client))
	{
		replayTime[client] = 0;
	}
	return Plugin_Continue;
}

/**
 * 设置、重设复读计数器
 */
public void createResetTimerTimer(int client)
{
	if (IsValidHandle(replayTimer[client]))
	{
		KillTimer(replayTimer[client]);
	}
	replayTimer[client] = CreateTimer(RESET_SECOND, removeRePlayTimeHandle, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public bool checkClient(int client)
{
	return (!!client && IsClientConnected(client)) && IsClientInGame(client);
}
