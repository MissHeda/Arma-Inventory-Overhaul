#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * While the window is open: compares the current weapon's attachments with the last look and plays TSP Animate's
 * gesture for each slot that changed - mount or dismount, muzzle, side rail, optic, bipod - the same gestures and
 * conditions as its own tsp_fnc_animate_attachment (setting "Attachment Change" on, the weapon in the hands
 * unchanged, standing or crouching). TSP's snapshot (tsp_animate_attach) is kept in step, so its own handler
 * never plays a change twice. Its close sound as well, which its InventoryClosed handler never hears from this
 * window.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_compat_tsp_animate_fnc_tick;
 *
 * Public: No
 */

private _open = !isNull (uiNamespace getVariable [QEGVAR(gui,display), displayNull]);
private _unit = missionNamespace getVariable ["ACE_player", player];

if (!_open || {isNull _unit} || {!alive _unit}) exitWith {
    // Closed since the last look: TSP's close sound.
    if (GVAR(last) isNotEqualTo [] && {!isNil "tsp_fnc_animate_effect"} && {!isNull _unit}) then {
        [_unit, 0.5, "tsp_animate\snd\inventory_close.ogg", missionNamespace getVariable ["tsp_cba_animate_sound_inv", 3]] call tsp_fnc_animate_effect;
    };

    GVAR(last) = [];
};

private _now = [currentWeapon _unit, primaryWeaponItems _unit, secondaryWeaponItems _unit, handgunItems _unit];
private _last = GVAR(last);

GVAR(last) = _now;
tsp_animate_attach = +_now;

if (_last isEqualTo [] || {_last isEqualTo _now}) exitWith {};

private _weapon = _now select 0;

if (
    _weapon isEqualTo "" || {_weapon isNotEqualTo (_last select 0)}
    || {!(missionNamespace getVariable ["tsp_cba_animate_attachment", true])}
    || {!(stance _unit in ["STAND", "CROUCH"])}
) exitWith {};

private _at = [primaryWeapon _unit, secondaryWeapon _unit, handgunWeapon _unit] find _weapon;

if (_at < 0) exitWith {};

private _old = _last select (_at + 1);
private _new = _now select (_at + 1);
private _suffix = ["", "", "pistol"] select _at;

// The slots in the order of primaryWeaponItems: muzzle, side rail, optic, bipod - TSP's own gesture names.
{
    _x params ["_index", "_part"];

    private _was = _old param [_index, ""];
    private _is = _new param [_index, ""];

    if (_was isNotEqualTo _is) then {
        private _mode = ["dismount", "mount"] select (_is isNotEqualTo "");
        private _gesture = if (_index == 0) then {"gesture" + _mode + "muzzle" + _suffix} else {_mode + _part + _suffix};

        _unit playAction _gesture;
    };
} forEach [[0, "muzzle"], [1, "side"], [2, "optic"], [3, "side"]];
