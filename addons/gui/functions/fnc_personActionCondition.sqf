#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The condition of the person action (fnc_addPersonAction, and fnc_addAgentAction for agents): whether
 * the player may open this soldier now, and the entry's text to match - "Inventory" for the whole
 * person, "Open <backpack>" when only the backpack may be opened, as the engine's own entry reads.
 *
 * The engine asks it every frame, but only for the object the player is looking at, so the cheap checks
 * come first. The player is always ACE_player, never the action's caller: under Zeus remote control
 * the controlled soldier is the one who reaches out.
 *
 * Arguments:
 * 0: Soldier to open <OBJECT>
 * 1: Action id <NUMBER>
 * 2: Object the action is on - the soldier itself, or the player's own soldier for an agent, which
 *    carries no actions <OBJECT> (default: the soldier)
 *
 * Return Value:
 * Shown <BOOL>
 *
 * Example:
 * [cursorObject, 3] call einv_gui_fnc_personActionCondition;
 *
 * Public: No
 */

params ["_target", "_actionId", ["_holder", objNull]];

if (isNull _holder) then {
    _holder = _target;
};

private _player = ACE_player;

if (
    _target isEqualTo _player
    || {!isNull objectParent _target}
    || {!isNull objectParent _player}
    // The unconscious have ACE medical's own "Inventory" (ace_medical_status_fnc_addInventoryActions) on
    // them, as ours is - not on an agent - but with a shorter reach, from the eyes to the feet. Where it
    // shows, ours gives way - one entry, not two; further off, ours is the only one.
    || {
        GVAR(aceInventoryAction) && {_holder isEqualTo _target} && {lifeState _target isEqualTo "INCAPACITATED"}
        && {(eyePos _player) distance (getPosASL _target) <= ACE_INVENTORY_REACH}
    }
) exitWith {false};

// With the window switched off for this player (replaceVanilla), only the backpack, as vanilla.
private _mode = [_target, GVAR(replaceVanilla)] call FUNC(canOpenPerson);

// ACE's own conditions: the person not claimed by someone else (dragged, carried, escorted), the player
// free to reach out - not handcuffed, surrendering, dragging, carrying, on a ladder, on the map or in
// Zeus. Swimming is no obstacle, as for ACE's backpack interaction.
if (_mode isEqualTo "" || {!([_player, _target, ["isNotSwimming"]] call ACEFUNC(common,canInteractWith))}) exitWith {false};

// It reads as the engine's own entry. Written only when that changes - kept by action id, as the
// player's soldier carries both its own person action and the one for agents.
private _key = [_actionId, [backpack _target, "whole"] select (_mode isEqualTo "whole")];

if ((_holder getVariable [QGVAR(personActionText), []]) isNotEqualTo _key) then {
    _holder setVariable [QGVAR(personActionText), _key];

    if (_mode isEqualTo "whole") then {
        _holder setUserActionText [_actionId, GVAR(gearText), GVAR(gearIcon)];
    } else {
        _holder setUserActionText [_actionId, format [GVAR(openBagText), getText (configOf backpackContainer _target >> "displayName")]];
    };
};

true
