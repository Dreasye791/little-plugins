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

#define MAX_CHAT_LENGTH 1024

#define REPACT_RANGE	10
#define REPACT_LIMIT	2
#define GAG_SECOND		60.0
#define RESET_SECOND	10.0

int			lastTime[MAXPLAYERS + 1], repactCount[MAXPLAYERS + 1];
char		lastChat[MAXPLAYERS + 1][MAX_CHAT_LENGTH], logFile[MAX_CHAT_LENGTH];
Handle		repactTimer[MAXPLAYERS + 1];
char		logPath[PLATFORM_MAX_PATH] = "logs/no_repact_chat.log";

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
	AddCommandListener(Command_Say, "say_team");

	BuildPath(Path_SM, logFile, sizeof(logFile), logPath);
}

public Action Command_Say(int client, const char[] command, any args)
{
	static char message[MAX_CHAT_LENGTH];
	GetCmdArgString(message, sizeof(message));

	if (StrEqual(lastChat[client], message))
	{
		if (lastTime[client] + REPACT_RANGE > GetTime())
		{
			if (BaseComm_IsClientGagged(client))
			{
				return Plugin_Handled;
			}
			repactCount[client]++;
			createResetRepactTimer(client);
			if (repactCount[client] > REPACT_LIMIT)
			{
				PrintToChatAll("[GAG] %N 重复发言过多，暂时禁言.", client);
				BaseComm_SetClientGag(client, true);
				// 因为换图后禁言状态会重置，所以不考虑换图后定时器失效的问题
				CreateTimer(GAG_SECOND, gagHandle, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
				repactCount[client] = 0;
				writeLog(client);
				return Plugin_Handled;
			}
		}
	}

	strcopy(lastChat[client], MAX_CHAT_LENGTH, message);
	lastTime[client] = GetTime();
	return Plugin_Continue;
}

/**
 * 取消禁言
 *
 */
public Action gagHandle(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (checkClient(client))
	{
		BaseComm_SetClientGag(client, false);
	}
	return Plugin_Continue;
}

public Action resetRepactCountHandle(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (checkClient(client))
	{
		repactCount[client] = 0;
	}
	return Plugin_Continue;
}

/**
 * 设置、重设复读计数器
 */
public void createResetRepactTimer(int client)
{
	if (IsValidHandle(repactTimer[client]))
	{
		KillTimer(repactTimer[client]);
	}
	repactTimer[client] = CreateTimer(RESET_SECOND, resetRepactCountHandle, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public bool checkClient(int client)
{
	return (!!client && IsClientConnected(client)) && IsClientInGame(client);
}

/**
 * 写入日志
 */
void writeLog(int client)
{
	static char sSteam[64];
	static char sName[MAX_NAME_LENGTH];

	if (client && IsClientInGame(client))
	{
		GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
		GetClientName(client, sName, sizeof(sName));
		LogToFile(logFile, "%s(%s)因复读:“%s”被禁言", sName, sSteam, lastChat[client]);
	}
	else {
		LogToFile(logFile, "记录日志时玩家已离线");
	}
}
