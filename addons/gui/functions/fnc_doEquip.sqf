#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Puts an item from a container on the player - dragged onto a slot, Alt+click, Equip / Attach to /
 * Load into in the context menu: taken out where the container's root is local, put on here, what was in
 * the slot put back on the item's cell (fnc_sendMoves) - one transaction, so whatever does not go
 * where it should is settled, never lost. The window follows the answer (fnc_afterAction).
 *
 * With a body given (the 5th argument) the item goes on that body's slot instead - dragged from the ground, a
 * crate or the player's gear onto the body's paper doll (fnc_updateDrag): gear only, never from a kit, and
 * what fnc_canPutOn says. What the body wore there goes back on the cell the item lay on.
 *
 * Out of a living person's container only as the settings say and while in reach (fnc_checkTouch) - the
 * person's machine asks again -, never another living player's kit (aio_compat_efak_fnc_checkTile).
 *
 * From an open kit of Enhanced First Aid Kits the kit's addon checks it first and sends it
 * (aio_compat_efak_fnc_equip - only when that addon is loaded); what was in the slot goes into the kit
 * where that kit takes it, else into the player's own gear (fnc_sendMoves).
 *
 * Arguments:
 * 0: Slot id <STRING>
 * 1: Container the item lies in, objNull for a kit <OBJECT>
 * 2: Entry <HASHMAP>
 * 3: Kit the item lies in, "" for a container <STRING> (default: "")
 * 4: A body to put it on instead of the player, objNull for the player <OBJECT> (default: objNull)
 *
 * Return Value:
 * Asked for <BOOL>
 *
 * Example:
 * ["primary_optic", backpackContainer player, _entry] call aio_gui_fnc_doEquip;
 *
 * Public: No
 */

params ["_slot", "_from", "_entry", ["_kit", "", [""]], ["_on", objNull, [objNull]]];

private _unit = GVAR(unit);
private _class = _entry getOrDefault ["class", ""];

// A move of it is under way already, or it was never searched.
if (_entry getOrDefault ["pending", false] || {_entry getOrDefault ["hidden", false]}) exitWith {false};

// Onto a body's slot, not the player's. A kit has no way to put its item on another unit.
private _onBody = !isNull _on && {_on isNotEqualTo _unit};

if (_onBody) then {
    _unit = _on;
};

if (_onBody && {_kit isNotEqualTo ""}) exitWith {
    ["NoFit"] call FUNC(flashHint);
    false
};

private _refusal = if (_onBody) then {
    [_class, _unit, _slot] call FUNC(canPutOn)
} else {
    ["NoFit", ""] select ([_unit, _slot, _class] call EFUNC(storage,slotAccepts))
};

if (_refusal isNotEqualTo "") exitWith {
    [_refusal] call FUNC(flashHint);
    false
};

if (_kit isNotEqualTo "") exitWith {
    if (!isNil QEFUNC(compat_efak,equip)) exitWith {
        [_slot, _kit, _entry] call EFUNC(compat_efak,equip)
    };

    // The kit's addon without a check of its own: the kit's grid stands for the kit as a holder.
    private _grids = uiNamespace getVariable [QGVAR(grids), []];
    private _index = _grids findIf {(_x getOrDefault ["kit", ""]) isEqualTo _kit};
    private _grid = if (_index < 0) then {createHashMap} else {_grids select _index};
    private _holder = _grid getOrDefault ["holder", _grid getOrDefault ["layoutKey", ""]];

    if !(_holder isEqualType "" && {_holder isNotEqualTo ""}) exitWith {
        ["Failed"] call FUNC(flashHint);
        false
    };

    [[createHashMapFromArray [
        ["kind", "equip"], ["unit", _unit], ["slot", _slot], ["from", _holder],
        ["fromRoot", _grid getOrDefault ["root", objNull]], ["entry", _entry], ["kit", _kit]
    ]]] call FUNC(sendMoves)
};

if (isNull _from) exitWith {false};

private _why = [_from, "items"] call FUNC(checkTouch);

// Another living player's kit stays where it is (aio_compat_efak), should a slot ever take one.
if (_why isEqualTo "" && {!isNil QEFUNC(compat_efak,checkTile)}) then {
    _why = [_class, _from] call EFUNC(compat_efak,checkTile);
};

if (_why isNotEqualTo "") exitWith {
    [_why] call FUNC(flashHint);
    false
};

[[createHashMapFromArray [
    ["kind", "equip"], ["unit", _unit], ["slot", _slot], ["from", _from], ["entry", _entry]
]]] call FUNC(sendMoves)
