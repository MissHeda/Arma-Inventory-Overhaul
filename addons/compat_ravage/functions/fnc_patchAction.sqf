#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Makes Ravage's "Search" (fnc_lootSearchAction, the hold action its loot scan puts on the player while he looks at
 * furniture) over for this mod's search: held only a moment (SEARCH_HOLD seconds, not Ravage's 1.5), and what it
 * finds goes into a hidden box at the furniture that the window opens on, searched there item by item like any
 * crate (fnc_search). Ravage's rummage sound is left out: the window's search has its own.
 *
 * Ravage defines the action again for a player who joins later and after a respawn; a new one is made over the
 * next time this runs (every second, XEH_postInit). An action already on the player - added before - is taken
 * off, and Ravage's scan puts the new one on as soon as he looks at furniture again (its player variable
 * rvg_lootSearchAction).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Made over now <BOOL>
 *
 * Example:
 * call aio_compat_ravage_fnc_patchAction;
 *
 * Public: No
 */

if (isNil "fnc_lootSearchAction" || {!(fnc_lootSearchAction isEqualType [])} || {count fnc_lootSearchAction < 12}) exitWith {false};

if ((fnc_lootSearchAction select 8) isEqualTo GVAR(onCompleted)) exitWith {false};

private _action = +fnc_lootSearchAction;

_action set [6, {player playAction "gear"}];
_action set [8, GVAR(onCompleted)];
_action set [11, SEARCH_HOLD];

fnc_lootSearchAction = _action;

private _id = player getVariable "rvg_lootSearchAction";

if (!isNil "_id") then {
    [player, _id] call BIS_fnc_holdActionRemove;
    player setVariable ["rvg_lootSearchAction", nil];
};

INFO("Ravage's Search made over: at once, into a hidden box at the furniture.");

true
