#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The statement of AIME's action on a ground pile (UPSL_aime_inventory_holder_action, patched in this addon's
 * config). AIME's own picks up the only item that lies there at one click - a weapon, a magazine or a
 * backpack - with the engine's commands, and opens the inventory when the pile holds more. That pick-up skips
 * what this mod asks of everything on the ground: the search. So while the ground has to be searched (the
 * search time above 0, the setting for the ground on, the pile not left out with aio_noSearch) the click
 * opens the window on the pile instead - the engine's Gear action, answered by the window, where the item
 * is searched before it is seen and then taken like any other.
 *
 * With searching off for the ground the pick-up is this mod's own (fnc_holderPick): the thing is taken from
 * the pile and put into the first container of the soldier with free cells, as a quick move does, instead of
 * AIME's addMagazine, which the engine refuses at a container's config load and loads into an empty weapon.
 * What that leaves to AIME - a backpack, a weapon that fits an empty slot, a pile with more than one thing -
 * runs as AIME made it.
 *
 * ACE runs it when the action is chosen.
 *
 * Arguments:
 * 0: The pile <OBJECT>
 * 1: Player <OBJECT>
 * 2: Action parameters - not used <ANY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_pile, ACE_player, []] call aio_compat_aime_fnc_holderRun;
 *
 * Public: No
 */

params [["_target", objNull, [objNull]], ["_player", objNull, [objNull]]];

private _searched = (missionNamespace getVariable [QEGVAR(gui,searchTime), 0]) > 0
    && {missionNamespace getVariable [QEGVAR(gui,searchGround), false]}
    && {!(_target getVariable [QGVARMAIN(noSearch), false])};

if (_searched) exitWith {
    _player action ["Gear", _target];
};

// This mod's pick-up, for what it covers.
if ([_target, _player] call FUNC(holderPick)) exitWith {};

if (isNil "UPSL_aime_inventory_fnc_holder_run") exitWith {
    _player action ["Gear", _target];
};

_this call UPSL_aime_inventory_fnc_holder_run;
