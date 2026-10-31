#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where things out of a kit go in the player's own gear, in order: the container the player - or the
 * mission - chose for that kit type in Enhanced First Aid Kits ("take into", efak_core_fnc_getKitContainer),
 * then uniform, vest and backpack. Only those the player has.
 *
 * Arguments:
 * 0: Kit class <STRING>
 *
 * Return Value:
 * Container objects <ARRAY>
 *
 * Example:
 * ["efak_IFAK_7"] call aio_compat_efak_fnc_ownTargets;
 *
 * Public: No
 */

params [["_kit", "", [""]]];

private _unit = EGVAR(gui,unit);
private _own = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];

// That mod's own (Public: No): without it, the usual order.
private _chosen = if (isNil QEFAKFUNC(core,getKitContainer)) then {""} else {[_kit] call EFAKFUNC(core,getKitContainer)};
private _first = ["uniform", "vest", "backpack"] find _chosen;
private _targets = [];

if (_first >= 0) then {
    _targets pushBack (_own select _first);
};

{
    _targets pushBackUnique _x;
} forEach _own;

_targets select {!isNull _x}
