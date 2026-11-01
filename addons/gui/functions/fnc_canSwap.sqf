#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Whether a worn item may go from one unit's slot onto the same slot of another, the other's item - if
 * any - coming back onto the first (fnc_doSwap): the player's backpack onto a body's backpack slot, a
 * body's vest onto the player's. One of the two is always the player. Only the gear one wears
 * (SWAP_SLOTS) - uniform, vest, backpack, headgear, face cover, night vision and the assigned items -,
 * never a weapon: the engine does not hand a body a weapon.
 *
 * The one exchange on a single unit: its primary and the second primary on its back (WebKnight's or KJW's Two
 * Primary Weapons, aio_storage_fnc_secondPrimary) - dragged onto each other or the menu's "Swap with primary".
 * Either may be empty: the other one then just moves over. Each must take the other's weapon (KJW's lists).
 *
 * Asked while dragging (fnc_updateDrag, fnc_showTargets) and once more before anything is sent; the
 * machines that take the gear off and put it on ask their own guards again (a living person's settings,
 * aio_gui_fnc_personGuard).
 *
 * Arguments:
 * 0: Where it comes from, [unit, slot id] <ARRAY>
 * 1: The unit it goes onto <OBJECT>
 * 2: The slot id there <STRING>
 *
 * Return Value:
 * "" when it may, else the reason (fnc_flashHint) <STRING>
 *
 * Example:
 * [[player, "backpack"], _body, "backpack"] call aio_gui_fnc_canSwap;
 * [[player, "primary2"], player, "primary"] call aio_gui_fnc_canSwap;
 *
 * Public: No
 */

params [["_source", [], [[]]], ["_toUnit", objNull, [objNull]], ["_toSlot", "", [""]]];
_source params [["_fromUnit", objNull, [objNull]], ["_fromSlot", "", [""]]];

if (isNull _fromUnit || {isNull _toUnit}) exitWith {"NoFit"};

// The primary and the second primary of one unit.
if (_fromUnit isEqualTo _toUnit) exitWith {
    if !([_fromSlot, _toSlot] in [["primary", "primary2"], ["primary2", "primary"]]) exitWith {"NoFit"};
    if (_fromUnit isNotEqualTo GVAR(unit)) exitWith {"NoFit"};

    private _entry = [_fromUnit, _fromSlot] call EFUNC(storage,getSlot);
    private _old = [_fromUnit, _toSlot] call EFUNC(storage,getSlot);

    if (count _entry == 0 && {count _old == 0}) exitWith {"Gone"};
    if (count _entry > 0 && {!([_fromUnit, _toSlot, _entry getOrDefault ["class", ""]] call EFUNC(storage,slotAccepts))}) exitWith {"NoFit"};
    if (count _old > 0 && {!([_fromUnit, _fromSlot, _old getOrDefault ["class", ""]] call EFUNC(storage,slotAccepts))}) exitWith {"NoFit"};

    [_fromUnit, "worn"] call FUNC(checkTouch)
};
if (_fromSlot isNotEqualTo _toSlot || {!(_toSlot in SWAP_SLOTS)}) exitWith {"NoFit"};
if !(GVAR(unit) in [_fromUnit, _toUnit]) exitWith {"NoFit"};

private _entry = [_fromUnit, _fromSlot] call EFUNC(storage,getSlot);

if (count _entry == 0) exitWith {"Gone"};
if !([_toUnit, _toSlot, _entry getOrDefault ["class", ""]] call EFUNC(storage,slotAccepts)) exitWith {"NoFit"};

// What the other wears there comes back onto the first.
private _old = [_toUnit, _toSlot] call EFUNC(storage,getSlot);

if (count _old > 0 && {!([_fromUnit, _fromSlot, _old getOrDefault ["class", ""]] call EFUNC(storage,slotAccepts))}) exitWith {"NoFit"};

// A living person's worn gear only as the settings say and while in reach - both ways.
private _why = [_fromUnit, "worn"] call FUNC(checkTouch);

if (_why isEqualTo "") then {
    _why = [_toUnit, "worn"] call FUNC(checkTouch);
};

_why
