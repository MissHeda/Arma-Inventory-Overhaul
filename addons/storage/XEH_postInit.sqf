#include "script_component.hpp"

// Every change to a container runs where its root is local - its authority: the player's own gear on the
// player's machine, a crate, pile, body or anything AI wears wherever that is local. A move is a
// transaction of phases, one root each (fnc_request); what a phase took out travels to the next one
// through the server's hub, which keeps it in its books until it landed (fnc_hubStart). CBA events
// rather than remoteExec, so a mission's CfgRemoteExec whitelist does not block them.

// A phase of a transaction for something local here - on every machine with or without a screen: a
// headless client holds its AI's gear.
[QGVAR(runPhase), {_this call FUNC(runPhase)}] call CBA_fnc_addEventHandler;

// Places of a loadout set on another machine, written here where the unit is local.
[QGVAR(loadoutPlaces), {_this call FUNC(onLoadoutPlaces)}] call CBA_fnc_addEventHandler;

// Queued phases, held phases and re-sends.
[{call FUNC(tick)}, 0] call CBA_fnc_addPerFrameHandler;

if (isServer) then {
    [QGVAR(hubStart), {_this call FUNC(hubStart)}] call CBA_fnc_addEventHandler;
    [QGVAR(phaseDone), {_this call FUNC(hubPhaseDone)}] call CBA_fnc_addEventHandler;
    addMissionEventHandler ["PlayerDisconnected", {_this call FUNC(hubDisconnect)}];

    // A machine id given out again to a new connection may be sent to again (fnc_hubRoute).
    addMissionEventHandler ["PlayerConnected", {
        params ["", "", "", "", "_owner"];

        GVAR(gone) = GVAR(gone) - [_owner];
    }];

    // A client asks once which version of the hub this server runs (fnc_greetServer). Answered whatever
    // it is: the client compares, and hands nothing to a hub of another version (fnc_hubReady).
    [QGVAR(hello), {
        params [["_client", -1, [0]], ["_version", "", [""]]];

        if (_version isNotEqualTo QUOTE(VERSION_STR)) then {
            WARNING_3("Machine %1 runs Enhanced Inventory %2, this server %3 - it moves nothing through the server.",_client,_version,QUOTE(VERSION_STR));
        };

        [QGVAR(welcome), [QUOTE(VERSION_STR)], _client] call CBA_fnc_ownerEvent;
    }] call CBA_fnc_addEventHandler;
};

if (hasInterface) then {
    // A body's places must be public for its looters, also those written less than OWN_WRITE_DELAY
    // seconds before death.
    ["CAManBase", "Killed", {
        params ["_unit"];

        if (_unit isEqualTo player) then {call FUNC(flushPlaces)};
    }] call CBA_fnc_addClassEventHandler;
};

// The answer to a transaction this machine asked for.
[QGVAR(answer), {_this call FUNC(onAnswer)}] call CBA_fnc_addEventHandler;

// The server's answer to the greeting: the version of its hub, kept for fnc_hubReady.
if (!isServer) then {
    [QGVAR(welcome), {
        params [["_version", "", [""]]];

        GVAR(serverVersion) = _version;

        if (_version isNotEqualTo QUOTE(VERSION_STR)) then {
            WARNING_2("The server runs Enhanced Inventory %1, this machine %2 - nothing is moved through the server.",_version,QUOTE(VERSION_STR));
        };
    }] call CBA_fnc_addEventHandler;

    call FUNC(greetServer);
};
