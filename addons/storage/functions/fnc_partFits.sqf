#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether an attachment or a magazine fits a part of a weapon - by the weapon alone, not whose it is or where it lies. The one
 * check every way of putting a part on asks: a worn weapon's slot (fnc_slotAccepts), a weapon lying in a container (op "fit",
 * fnc_opFit, the attachments view, a part dropped on a weapon's tile) - so the drag's green and red are what the drop does.
 * The kind decides first: only a magazine or grenade goes on a magazine part, only an attachment of that kind on its own part.
 * What the weapon takes is kept per weapon and part in GVAR(compatSets), class names in lower case, read from config once:
 * the magazines of the part's muzzle (mag: the weapon's own, mag2: its second), or the weapon's compatible items (CBA).
 *
 * Arguments:
 * 0: Weapon class <STRING>
 * 1: Part - "muzzle", "optic", "rail", "bipod", "mag" or "mag2" <STRING>
 * 2: Item class <STRING>
 *
 * Return Value:
 * Fits <BOOL>
 *
 * Example:
 * ["arifle_MX_F", "optic", "optic_Aco"] call aio_storage_fnc_partFits;
 *
 * Public: No
 */

params [["_weapon", "", [""]], ["_part", "", [""]], ["_class", "", [""]]];

if (_weapon isEqualTo "" || {_class isEqualTo ""}) exitWith {false};
if !(_part in ["muzzle", "rail", "optic", "bipod", "mag", "mag2"]) exitWith {false};

private _kind = ([_class] call EFUNC(items,getInfo)) get "kind";
private _isMagazine = _part in ["mag", "mag2"];

if (_isMagazine && {!(_kind in ["magazine", "grenade"])}) exitWith {false};
if (!_isMagazine && {_kind isNotEqualTo _part}) exitWith {false};

private _setKey = (toLowerANSI _weapon) + (["|items", "|" + _part] select _isMagazine);
private _set = GVAR(compatSets) get _setKey;

if (isNil "_set") then {
    private _list = [];

    if (_isMagazine) then {
        private _muzzles = getArray (configFile >> "CfgWeapons" >> _weapon >> "muzzles");
        private _muzzle = if (_part isEqualTo "mag") then {"this"} else {
            (_muzzles select {_x != "this" && {_x != (_muzzles param [0, ""])}}) param [0, ""]
        };

        if (_muzzle isNotEqualTo "") then {
            _list = compatibleMagazines [_weapon, _muzzle];
        };
    } else {
        _list = [_weapon] call CBA_fnc_compatibleItems;
    };

    if (isNil "_list" || {!(_list isEqualType [])}) then {
        _list = [];
    };

    _set = createHashMapFromArray (_list apply {[toLowerANSI _x, true]});
    GVAR(compatSets) set [_setKey, _set];
};

(toLowerANSI _class) in _set
