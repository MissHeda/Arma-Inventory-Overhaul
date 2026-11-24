#include "script_component.hpp"

if (!GVAR(loaded) || {!hasInterface}) exitWith {};

// Money taken through the window is money (fnc_convertMoney): Antistasi turns it into funds only on the engine's Take,
// which the window's moves never raise. CBA's loadout event catches every change of the player's gear.
["loadout", {call FUNC(convertMoney)}] call CBA_fnc_addPlayerEventHandler;

// Nothing is turned into money while an arsenal is open: once it closed, a moment later (its display has to go first).
["ace_arsenal_displayClosed", {[{call FUNC(convertMoney)}, [], 0.5] call CBA_fnc_waitAndExecute}] call CBA_fnc_addEventHandler;
[missionNamespace, "arsenalClosed", {[{call FUNC(convertMoney)}, [], 0.5] call CBA_fnc_waitAndExecute}] call BIS_fnc_addScriptedEventHandler;

// Mag Repack (Antistasi's core\Scripts\MagRepack) takes every magazine out and adds them back: its window keeps where
// they lay and puts them back there when it closes (fnc_wrapMagRepack). Its functions are made by its own script,
// again after a respawn, so they are looked at now and then.
[{call FUNC(wrapMagRepack)}, MAGREPACK_TICK] call CBA_fnc_addPerFrameHandler;
