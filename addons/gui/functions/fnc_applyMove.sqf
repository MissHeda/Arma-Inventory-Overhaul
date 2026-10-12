#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Moves an item for the window: checked here first, so the hint says at once what this machine can
 * already tell - a living person's gear the player may not change or is out of reach of
 * (fnc_checkTouch), another living player's kit (einv_compat_efak_fnc_checkTile), no room for its load
 * (einv_storage_fnc_roomByWeight: too heavy says for which container and by how much, a backpack into a
 * backpack says so), no free spot when only the grid counts and nobody said where - then sent as
 * a transaction (fnc_sendMoves). Every change happens where the holder's root is local, checked there
 * again; places, search knowledge and the window follow the answer (fnc_afterAction).
 *
 * Within one container it is a rearrangement onto the cell; the ground ("ground") is the surface under
 * the feet, or the vehicle's cargo while seated. A ground pile the window does not show, or none at
 * all, stands for the ground as well (einv_storage_fnc_getGroundHolder, as callers used to ask it).
 *
 * Arguments:
 * 0: Holder it lies in - a container, or a key like "kit:..." <OBJECT or STRING>
 * 1: Holder it goes to, or "ground" <OBJECT or STRING>
 * 2: Entry <HASHMAP>
 * 3: How many of a stack, -1 for all of it <NUMBER> (default: -1)
 * 4: Cell [col, row, compartment] - with [.., width, height] when it lies turned there - or [] to let
 *    the layout find one <ARRAY> (default: [])
 * 5: Options (fnc_sendMoves) <HASHMAP> (default: empty)
 *
 * Return Value:
 * Asked for <BOOL>
 *
 * Example:
 * [_from, _to, _entry, -1, [0, 0, 0]] call einv_gui_fnc_applyMove;
 *
 * Public: No
 */

params ["_from", "_to", "_entry", ["_count", -1], ["_cell", []], ["_options", createHashMap, [createHashMap]]];

// A move of it is under way already, or it was never searched.
if (_entry getOrDefault ["pending", false] || {_entry getOrDefault ["hidden", false]}) exitWith {false};

if (
    _to isEqualType objNull && {!isNull _to} && {[_to] call EFUNC(storage,isGroundHolder)}
    && {(uiNamespace getVariable [QGVAR(grids), []]) findIf {(_x getOrDefault ["container", objNull]) isEqualTo _to} < 0}
) then {
    _to = "ground";
};

if (_from isEqualType objNull && {isNull _from}) exitWith {false};
if (_to isEqualType objNull && {isNull _to}) exitWith {false};

private _class = _entry getOrDefault ["class", ""];
private _why = "";
private _details = [];

// A living person's gear only as the settings say and while in reach - also rearranged, which everyone
// looking at them sees. Their machine asks again (fnc_personGuard).
if (_from isEqualType objNull) then {
    _why = [_from, "items"] call FUNC(checkTouch);
};

if (_why isEqualTo "" && {_to isEqualType objNull} && {_to isNotEqualTo _from}) then {
    _why = [_to, "items"] call FUNC(checkTouch);
};

if (_why isEqualTo "" && {_from isEqualType objNull} && {_to isNotEqualTo _from} && {!isNil QEFUNC(compat_efak,checkTile)}) then {
    _why = [_class, _from] call EFUNC(compat_efak,checkTile);
};

// Room for its load, and with only the grid counting (einv_storage_gridOnly) a free spot when nobody
// said where. The authority asks both again against what it holds then.
if (_why isEqualTo "" && {_to isEqualType objNull} && {_to isNotEqualTo _from}) then {
    private _room = [_to, _entry, _count] call EFUNC(storage,roomByWeight);

    if !(_room get "fits") exitWith {
        _why = _room get "reason";

        // Which container and by how much (fnc_flashHint -> fnc_weightText).
        if (_why isEqualTo "TooHeavy") then {
            _details = [_to, _entry, _count];
        };
    };

    if (EGVAR(storage,gridOnly) && {_cell isEqualTo []} && {!([_to, _entry] call EFUNC(storage,hasSpace))}) then {
        _why = "NoRoom";
    };
};

if (_why isNotEqualTo "") exitWith {
    [_why, _details] call FUNC(flashHint);

    false
};

[[createHashMapFromArray [
    ["kind", "move"], ["from", _from], ["to", _to], ["entry", _entry], ["count", _count], ["cell", _cell]
]], _options] call FUNC(sendMoves)
