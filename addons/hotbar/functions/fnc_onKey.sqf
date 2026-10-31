#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A slot's key was pressed (its CBA keybind). Decides whether the hotbar takes the key or leaves it to
 * Arma and ACE, which have uses for the same keys.
 *
 * Left alone - the key reports false and does what it always did - when the slot is empty, while Arma's
 * command menu is open (0-0-1 for the radio is typed on these keys), in Zeus and in a feature camera,
 * and, as the setting says, while the player leads AI soldiers. A slot with something on it takes its
 * key: the handler reports true, so Arma's command menu does not open on it. Another mod's keybind on
 * the same key still runs - CBA runs every handler of a key.
 *
 * What the key does happens a frame later (fnc_use): ACE's grenade keys, which share 6, 7 and 0, have
 * selected their grenade by then and the slot's wins; and ACE's progress bar closes and opens a dialog,
 * which must not happen inside a key handler.
 *
 * Arguments:
 * 0: Slot index <NUMBER>
 *
 * Return Value:
 * The key is taken <BOOL>
 *
 * Example:
 * [0] call aio_hotbar_fnc_onKey;
 *
 * Public: No
 */

params [["_index", 0, [0]]];

if (!(call FUNC(isActive))) exitWith {false};

private _class = GVAR(slots) param [_index, ""];

if (_class isEqualTo "") exitWith {false};
if (commandingMenu isNotEqualTo "") exitWith {false};
if (!isNull curatorCamera || {(call CBA_fnc_getActiveFeatureCamera) isNotEqualTo ""}) exitWith {false};

private _unit = ACE_player;

if (GVAR(leaderKeys) && {[_unit] call FUNC(isLeading)}) exitWith {false};

// Taken, but nothing to do: someone who is dead, helpless or not in control of this unit.
if (!alive _unit || {!local _unit} || {_unit getVariable ["ACE_isUnconscious", false]}) exitWith {true};

// One thing at a time: ACE's progress bar is up already.
if (!isNull (uiNamespace getVariable ["ace_common_ctrlProgressBar", controlNull])) exitWith {
    [_index, LLSTRING(Reason_Busy), "warning"] call FUNC(flash);
    true
};

if (diag_tickTime < GVAR(lockUntil)) exitWith {true};

GVAR(lockUntil) = diag_tickTime + USE_LOCK;

[FUNC(use), [_index]] call CBA_fnc_execNextFrame;

true
