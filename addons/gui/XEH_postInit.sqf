#include "script_component.hpp"
#include "defines.hpp"

// Before the hasInterface exit: a unit respawns where it is local, which can be the server or a
// headless client, and the new body gets no init event - so every client is told to give it the
// person action (fnc_addPersonAction).
["CAManBase", "respawn", {
    params ["_unit"];

    if (local _unit) then {
        [QGVAR(addPersonAction), [_unit]] call CBA_fnc_globalEvent;
    };
}, true] call CBA_fnc_addClassEventHandler;

// A crate or a vehicle the game master places is left out of the search when the server says so (fnc_onZeusPlaced). The
// curator modules are looked for every few seconds on every machine: a game master can be assigned at any time.
[{call FUNC(hookCurators)}, 5] call CBA_fnc_addPerFrameHandler;

if (!hasInterface) exitWith {};

#include "initKeybinds.inc.sqf"

// Someone near loots: the sounds they make reach this machine as resolved layers and play where their hands
// are (fnc_sendNoise sends them only to players within earshot).
[QGVAR(noise), {_this call FUNC(onNoise)}] call CBA_fnc_addEventHandler;

// The engine asks the unit itself whether its inventory may open, so the handler goes onto whichever
// unit the player is - again after a respawn, a team switch or while remote controlling with Zeus - and
// behind every handler of other mods that is on it by then. The person action for agents, who carry no
// actions themselves, goes along (fnc_addAgentAction).
["unit", {
    params ["_unit"];

    [_unit, true] call FUNC(initUnit);
    [_unit] call FUNC(addAgentAction);
}, true] call CBA_fnc_addPlayerEventHandler;

// Other mods add their InventoryOpened handlers after this postInit - in theirs, or in a script that waits for
// the mission's display (SFX Project: Remastered). Once they had time to, this mod's handler goes behind
// them (fnc_initUnit); a handler added later still is found by the guard (fnc_guardVanilla).
[{!isNull findDisplay 46}, {
    [{
        [PLAYER_UNIT, true] call FUNC(initUnit);
    }, [], HANDLER_RECHECK] call CBA_fnc_waitAndExecute;
}] call CBA_fnc_waitUntilAndExecute;

// The vanilla inventory is gone for good. The handler above keeps the engine from opening it, and the
// display's load event (CfgEventHandlers) closes one that comes up anyway; this is the last net, for a
// display that loaded without raising that event.
[{
    [] call FUNC(guardVanilla);
}, GUARD_INTERVAL] call CBA_fnc_addPerFrameHandler;

// One person action per soldier, on every client with a player: the units there now, those made later
// and those that respawned. A team switch or Zeus remote control needs nothing - the condition asks
// ACE_player - and a locality change neither: an action stays on its object.
[QGVAR(addPersonAction), {_this call FUNC(addPersonAction)}] call CBA_fnc_addEventHandler;
["CAManBase", "init", {_this call FUNC(addPersonAction)}, true, [], false] call CBA_fnc_addClassEventHandler;

{
    [_x] call FUNC(addPersonAction);
} forEach allUnits;

// The rules for sizes, stacks and grids changed (aio_items_fnc_loadRules: the server's or the mission's
// setup changed, maybe saved by the wizard just now). An open window is built again under them, so a
// player looking at their gear sees the new sizes at once. Whatever no longer fits where it lay is
// placed anew or shown as overflow; nothing leaves the cargo.
//
// The context menu goes first: its choices were worked out under the old rules. The build waits a frame,
// and while a tile is held it waits for the release - a rebuild would pull it from under the mouse, as
// fnc_onFrame knows. Several changes in a row make one build.
GVAR(rulesRebuild) = false;

[QEGVAR(items,rulesChanged), {
    if (GVAR(rulesRebuild) || {isNull (uiNamespace getVariable [QGVAR(display), displayNull])}) exitWith {};

    call FUNC(closeMenu);
    GVAR(rulesRebuild) = true;

    [{
        [{
            GVAR(press) isEqualTo [] || {isNull (uiNamespace getVariable [QGVAR(display), displayNull])}
        }, {
            GVAR(rulesRebuild) = false;
            [uiNamespace getVariable [QGVAR(display), displayNull]] call FUNC(build);
        }] call CBA_fnc_waitUntilAndExecute;
    }] call CBA_fnc_execNextFrame;
}] call CBA_fnc_addEventHandler;
