#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Moves a weapon card of the equipment column one place up or down (fnc_drawEquipmentCards) - a click on one of the
 * arrows in its corner. It changes places with the next card that is shown that way: the second primary's card,
 * where no two-primary mod gives the unit that slot, is passed over and keeps its place in the order for when one
 * does. The order is each player's own, kept in the profile (GVAR(weaponOrder)).
 *
 * Arguments:
 * 0: The card's slot, "primary", "primary2", "handgun" or "launcher" <STRING>
 * 1: Direction, -1 up or 1 down <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["handgun", -1] call aio_gui_fnc_moveWeaponCard;
 *
 * Public: No
 */

params [["_slot", "", [""]], ["_direction", 0, [0]]];

private _order = +GVAR(weaponOrder);
private _from = _order find _slot;

if (_from < 0 || {_direction == 0}) exitWith {};

private _hasSecond = ([GVAR(unit)] call EFUNC(storage,secondPrimary)) select 0;
private _to = _from + _direction;

while {_to >= 0 && {_to < count _order} && {!_hasSecond} && {(_order select _to) isEqualTo "primary2"}} do {
    _to = _to + _direction;
};

if (_to < 0 || {_to >= count _order}) exitWith {};

_order set [_from, _order select _to];
_order set [_to, _slot];

GVAR(weaponOrder) = _order;
profileNamespace setVariable [QGVAR(weaponOrder), +_order];
saveProfileNamespace;

[] call FUNC(buildSoon);
