#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The statement of AIME's action on a ground pile (UPSL_aime_inventory_holder_action, patched in this addon's
 * config). AIME's own picks up the only item that lies there at one click - a weapon, a magazine or a
 * backpack - with the engine's commands, and opens the inventory when the pile holds more. That pick-up skips
 * what this mod asks of everything on the ground: the search. So while the ground has to be searched (the
 * search time above 0, the setting for the ground on, the pile not left out with einv_noSearch) the click
 * opens the window on the pile instead - the engine's Gear action, answered by the window, where the item
 * is searched before it is seen and then taken like any other. With searching off for the ground AIME's
 * pick-up runs as it always did: what it adds the engine's way is laid on the grid by the usual look
 * (fnc_queueMigrate), and what has no room goes back to the ground.
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
 * [_pile, ACE_player, []] call einv_compat_aime_fnc_holderRun;
 *
 * Public: No
 */

params [["_target", objNull, [objNull]], ["_player", objNull, [objNull]]];

private _searched = (missionNamespace getVariable [QEGVAR(gui,searchTime), 0]) > 0
    && {missionNamespace getVariable [QEGVAR(gui,searchGround), false]}
    && {!(_target getVariable [QGVARMAIN(noSearch), false])};

if (_searched || {isNil "UPSL_aime_inventory_fnc_holder_run"}) exitWith {
    _player action ["Gear", _target];
};

_this call UPSL_aime_inventory_fnc_holder_run;
