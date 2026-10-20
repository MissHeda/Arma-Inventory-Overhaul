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

// What a loadout set on another machine left out of the unit's containers (fnc_onLoadoutSet), added here.
[QGVAR(topUpLoadout), {
    params ["_unit", "_loadout"];

    [{_this call FUNC(topUpLoadout)}, [_unit, _loadout]] call FUNC(nextFrame);
}] call CBA_fnc_addEventHandler;

// A loadout set for a unit that lives on another machine (einv_storage_fnc_setUnitLoadout), set where it is local.
[QGVAR(setUnitLoadout), {_this call FUNC(setUnitLoadout)}] call CBA_fnc_addEventHandler;

// Queued phases, held phases and re-sends.
[{call FUNC(tick)}, 0] call CBA_fnc_addPerFrameHandler;

// Surplus. The engine's own commands (addItem and its relatives, addMagazine, addWeapon, a script's loadout,
// ACE) ignore our cells and fill a uniform, vest or backpack until its mass is reached; what the grid has
// no room for shows as overflow. A unit whose cargo changed is looked at a moment later, and what has
// somewhere to go - the next of its containers with free cells - is moved there by its authority (op
// "migrate", fnc_opMigrate). Nothing raises an event for a script's addItem, so the triggers are the
// nearest things: all of them only note the unit (fnc_queueMigrate), this handler does the looking. Not in
// Eden: no postInit runs there, and there is no gameplay to repair.
[{[] call FUNC(tickMigrate)}, MIGRATE_TICK] call CBA_fnc_addPerFrameHandler;

// What the engine's own inventory actions did to any unit local here: taking from the ground or a
// container, putting away, closing the inventory (a vanilla one that another mod brought up).
{
    ["CAManBase", _x, {
        params [["_unit", objNull, [objNull]]];

        [_unit] call FUNC(queueMigrate);

        // Where the magazines lie, noted again (fnc_useTrack): the player's own only.
        if (hasInterface && {_unit isEqualTo (missionNamespace getVariable ["ACE_player", player])}) then {
            [_unit] call FUNC(useTrack);
        };
    }] call CBA_fnc_addClassEventHandler;
} forEach ["Take", "Put", "InventoryClosed"];

// Strict mode. What a setting on Strict keeps out of a unit's uniform, vest or backpack lives in a hidden
// holder on the unit (op "strict", fnc_opStrict), asked for by the same look as the surplus
// (fnc_requestMigrate). Every unit local here that carries a holder is noted every few seconds besides
// (fnc_hiddenSweep): the net under the events - a player who left and whose unit stays as an AI, a Zeus who
// let a unit go, a setting switched away from Strict, a body whose death this machine did not see.
[{call FUNC(hiddenSweep)}, STRICT_SWEEP] call CBA_fnc_addPerFrameHandler;

// On death the holder goes into the body's containers at once, where the body is local, so its looters find
// everything (fnc_hiddenReturn). Not through a transaction: the body may change hands any moment.
["CAManBase", "Killed", {
    params ["_unit"];

    if (local _unit && {!isNil {_unit getVariable QGVAR(hidden)}}) then {
        [_unit] call FUNC(hiddenReturn);
    };
}] call CBA_fnc_addClassEventHandler;

// A loadout set for a unit on another machine than the one that set it: its owner is told, and looks a
// little later - the containers of the new loadout have to arrive there first (fnc_onLoadoutSet).
[QGVAR(migrateUnit), {
    params [["_unit", objNull, [objNull]]];

    [_unit, 1] call FUNC(queueMigrate);
}] call CBA_fnc_addEventHandler;

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
            WARNING_3("Machine %1 runs Arma Inventory Overhaul %2, this server %3 - it moves nothing through the server.",_client,_version,QUOTE(VERSION_STR));
        };

        [QGVAR(welcome), [QUOTE(VERSION_STR)], _client] call CBA_fnc_ownerEvent;
    }] call CBA_fnc_addEventHandler;
};

if (hasInterface) then {
    // The reload key in front of the engine's, once the main display exists: with a "Use items from ..."
    // limit active the key is this mod's, and the fullest magazine that may be used is loaded
    // (fnc_reloadGuard). The throw key in front of the engine's too: with nothing to throw but closed
    // containers' grenades it does nothing and says where to take one out (fnc_throwGuard). One handler for
    // both, whose answer is either's: with two, the engine was seen going by one handler's false although
    // the other swallowed the key - the reload guard's true was lost, and the game reloaded by its own pick
    // as well. Both always run, each for its own key.
    [{!isNull findDisplay 46}, {
        (findDisplay 46) displayAddEventHandler ["KeyDown", {
            private _reload = _this call FUNC(reloadGuard);
            private _throw = _this call FUNC(throwGuard);

            _reload || _throw
        }];
    }] call CBA_fnc_waitUntilAndExecute;

    // The reload this mod asked for spends its token here, once (fnc_onReloaded tidies the magazine put away).
    // What the keys cannot catch: a reload by the scroll menu, a gamepad button or a script is the game's;
    // a magazine it took from a closed container is taken back after the event (fnc_onReloaded, which needs
    // to know where the magazines lay: fnc_useTrack, once a second and after every move). The throwing is
    // kept to the unit's open containers by ACE's blockThrow effect and the selection (fnc_throwTick).
    ["CAManBase", "Reloaded", {_this call FUNC(onReloaded)}] call CBA_fnc_addClassEventHandler;

    [{[] call FUNC(useTrack)}, TRACK_TICK] call CBA_fnc_addPerFrameHandler;
    [{[] call FUNC(throwTick)}, THROW_TICK] call CBA_fnc_addPerFrameHandler;

    // ACE Arsenal opening here on this machine's own unit: the hidden holder gives everything back to the
    // containers at once, so the arsenal, its panel and the loadouts saved there see the real gear
    // (fnc_hiddenReturn; fnc_hiddenActive keeps it so while it is open). Taken again once it closed
    // (einv_arsenal_fnc_onClosed asks fnc_requestMigrate). The vanilla arsenal is caught by the sweep.
    [QACEGVAR(arsenal,displayOpened), {
        private _unit = missionNamespace getVariable ["ACE_player", player];

        if (!isNull _unit && {local _unit}) then {
            [_unit] call FUNC(hiddenReturn);
        };
    }] call CBA_fnc_addEventHandler;

    // A body's places must be public for its looters, also those written less than OWN_WRITE_DELAY
    // seconds before death.
    ["CAManBase", "Killed", {
        params ["_unit"];

        if (_unit isEqualTo player) then {call FUNC(flushPlaces)};
    }] call CBA_fnc_addClassEventHandler;

    // The player's own unit: any change of its loadout - a script's addItem, ACE, the arsenals, the engine's
    // own actions (CBA polls it, and leaves the rounds in the weapons out, so firing is no change).
    ["loadout", {
        private _unit = _this param [0, objNull];

        if !(_unit isEqualType objNull) then {
            _unit = player;
        };

        [_unit] call FUNC(queueMigrate);
    }] call CBA_fnc_addPlayerEventHandler;

    // The unit the player is now - the start, a respawn, a team switch, a Zeus remote control - may come
    // with more than its grid holds.
    ["unit", {
        private _unit = _this param [0, objNull];

        if !(_unit isEqualType objNull) then {
            _unit = player;
        };

        [_unit] call FUNC(queueMigrate);
    }, true] call CBA_fnc_addPlayerEventHandler;

    // A changed rule set may have shrunk a grid under what it holds. Raised on every machine once it has
    // the new rules.
    [QEGVAR(items,rulesChanged), {
        [missionNamespace getVariable ["ACE_player", player]] call FUNC(queueMigrate);
    }] call CBA_fnc_addEventHandler;
};

// The answer to a transaction this machine asked for.
[QGVAR(answer), {_this call FUNC(onAnswer)}] call CBA_fnc_addEventHandler;

// The server's answer to the greeting: the version of its hub, kept for fnc_hubReady.
if (!isServer) then {
    [QGVAR(welcome), {
        params [["_version", "", [""]]];

        GVAR(serverVersion) = _version;

        if (_version isNotEqualTo QUOTE(VERSION_STR)) then {
            WARNING_2("The server runs Arma Inventory Overhaul %1, this machine %2 - nothing is moved through the server.",_version,QUOTE(VERSION_STR));
        };
    }] call CBA_fnc_addEventHandler;

    call FUNC(greetServer);
};
