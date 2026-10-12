#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Where a drag would land (the "dragCheck" hook): the inventory's answer is corrected for the Arsenal - the
 * ground is no target, it is the give-back zone, or nothing -, a card dropped on the catalog itself is
 * ignored, and the soldier in the middle takes things like Alt+click would.
 *
 * A card dropped on a kit - on its open window's grid or on its tile, open or not - is packed into it
 * when the kit's arsenal setting is everything and the kit would take the item by hand (einv_compat_efak_fnc_
 * arsenalEditing, fnc_canPack); the footprint says why not otherwise. A tile out of a kit that the arsenal
 * may not take things out of cannot be given back: the zone is red.
 * The zones are found by their id (fnc_layout): "giveBack" (the catalog's column) and "soldier". A card
 * dropped on the catalog does nothing; a tile or slot dropped there, or outside every panel, is given back.
 * Outside every panel while the Loadouts are shown, where the column registers no zone, the target is a
 * zone with the index -1, which fnc_onDrop reads as the give-back all the same.
 *
 * The give-back zone carries "loss" as a seventh element: the colour it is to be tinted in. The inventory
 * tints a zone by whether it fits, green; it may read the element.
 *
 * Arguments:
 * 0: The drag target the inventory found <ARRAY>
 * 1: The entry dragged <HASHMAP>
 * 2: The grid it comes from, or an empty HashMap <HASHMAP>
 * 3: Slot it comes from, [unit, slot], or [] <ARRAY>
 *
 * Return Value:
 * The target as it is to stand, [] for none, nil to leave it <ARRAY>
 *
 * Example:
 * [_target, _entry, _grid, []] call einv_arsenal_fnc_dragCheck;
 *
 * Public: No
 */

params [
    ["_target", [], [[]]], ["_entry", createHashMap, [createHashMap]], ["_sourceGrid", createHashMap, [createHashMap]],
    ["_slotSource", [], [[]]]
];

private _unit = GVAR(center);
private _column = uiNamespace getVariable [QGVAR(column), createHashMap];

if (isNull _unit) exitWith {nil};

private _fromCatalog = (_sourceGrid getOrDefault ["source", ""]) isNotEqualTo "";
private _kind = _target param [0, ""];
private _zones = uiNamespace getVariable [QEGVAR(gui,zones), []];
private _giveBack = _zones findIf {(_x select 1) isEqualTo "giveBack"};

// What the hint says while a zone is under the drag: once, when the zone changes.
private _fnc_say = {
    params ["_zone"];

    if ((_column getOrDefault ["dragZone", ""]) isNotEqualTo _zone) then {
        _column set ["dragZone", _zone];

        [[LLSTRING(Hint_GiveBack), LLSTRING(Hint_PutOn)] select (_zone isEqualTo "soldier"), "text2"] call FUNC(message);
    };
};

if (_kind isNotEqualTo "zone") then {
    _column set ["dragZone", ""];
};

// What a kit says about taking one of this class, [fits, reason] - asked every frame of a drag, so kept for
// half a second.
private _fnc_kitVerdict = {
    params ["_kit", "_class"];

    private _cache = _column get "packCache";

    if (isNil "_cache") then {
        _cache = createHashMap;
        _column set ["packCache", _cache];
    };

    private _key = format ["%1|%2", _kit, _class];
    private _kept = _cache get _key;

    if (!isNil "_kept" && {diag_tickTime - (_kept select 0) < 0.5}) exitWith {_kept select 1};

    private _verdict = [true, ""];

    if (isNil QEFUNC(compat_efak,arsenalEditing) || {([_kit] call EFUNC(compat_efak,arsenalEditing)) < EDIT_ALL}) then {
        _verdict = [false, LLSTRING(Hint_KitLocked)];
    } else {
        ([_kit, _class, 1] call EFUNC(compat_efak,canPack)) params ["_ok", "_why"];

        _verdict = [_ok, ["", [_why, "Failed"] select (_why isEqualTo "")] select !_ok];
    };

    _cache set [_key, [diag_tickTime, _verdict]];

    _verdict
};

// Whether the tile or slot dragged comes out of a kit the arsenal may not take things out of.
private _fromKit = _sourceGrid getOrDefault ["kit", ""];
private _stuck = _fromKit isNotEqualTo "" && {isNil QEFUNC(compat_efak,arsenalEditing) || {([_fromKit] call EFUNC(compat_efak,arsenalEditing)) < EDIT_REMOVE}};

private _result = switch (_kind) do {
    // Outside every panel: nothing goes to the ground. A card does nothing; the soldier's own is given back.
    case "ground": {
        if (_fromCatalog) then {
            []
        } else {
            if (!_stuck) then {
                ["giveBack"] call _fnc_say;
            };

            ["zone", _giveBack, 0, 0, !_stuck, ["", LLSTRING(Hint_KitLocked)] select _stuck, "loss"]
        }
    };
    case "zone": {
        private _zoneIndex = _target param [1, -1];
        private _id = if (_zoneIndex < 0) then {"giveBack"} else {(_zones param [_zoneIndex, []]) param [1, ""]};

        switch (_id) do {
            case "giveBack": {
                if (_fromCatalog) then {
                    []
                } else {
                    if (!_stuck) then {
                        ["giveBack"] call _fnc_say;
                    };

                    ["zone", _zoneIndex, 0, 0, !_stuck, ["", LLSTRING(Hint_KitLocked)] select _stuck, "loss"]
                }
            };
            case "soldier": {
                // Put on, as Alt+click does: a card always goes on or is added, an item of his own only
                // when a slot takes it.
                private _fits = _fromCatalog || {([_unit, _entry getOrDefault ["class", ""]] call EFUNC(storage,slotFor)) isNotEqualTo ""};

                ["soldier"] call _fnc_say;

                ["zone", _target param [1, -1], 0, 0, _fits, ["NoFit", ""] select _fits]
            };
            default {nil};
        }
    };
    // A card on a kit's open grid, or on a kit's tile lying in a grid: packed into the kit, if it takes it.
    case "grid": {
        if (_fromCatalog) then {
            private _gridIndex = _target param [1, -1];
            private _grid = (uiNamespace getVariable [QEGVAR(gui,grids), []]) param [_gridIndex, createHashMap];
            private _class = _entry getOrDefault ["class", ""];
            private _kit = _grid getOrDefault ["kit", ""];
            private _tileIndex = -1;

            // A kit's tile under the mouse, in a grid of a container.
            if (_kit isEqualTo "" && {!isNil QEFUNC(compat_efak,isKit)} && {!(_grid getOrDefault ["virtual", true])}) then {
                private _cell = [_grid, getMousePosition] call EFUNC(gui,screenToCell);

                if (_cell isNotEqualTo []) then {
                    private _index = [_grid, _cell] call EFUNC(gui,tileAt);
                    private _tile = (_grid getOrDefault ["tiles", []]) param [_index, createHashMap];

                    if (
                        _index >= 0 && {!(_tile getOrDefault ["hidden", false])}
                        && {[_tile getOrDefault ["class", ""]] call EFUNC(compat_efak,isKit)}
                    ) then {
                        _tileIndex = _index;
                        _kit = _tile getOrDefault ["class", ""];
                    };
                };
            };

            if (_kit isEqualTo "") then {
                nil
            } else {
                ([_kit, _class] call _fnc_kitVerdict) params ["_fits", "_reason"];

                if (_tileIndex >= 0) then {
                    ["kitTile", _gridIndex, _tileIndex, 0, _fits, _reason]
                } else {
                    private _kept = +_target;

                    _kept set [4, _fits];
                    _kept set [5, _reason];

                    _kept
                }
            }
        } else {
            nil
        }
    };
    // The inventory's own kit tile branch is skipped for a card, but should it ever answer: the same.
    case "kitTile": {
        if (_fromCatalog) then {
            private _grid = (uiNamespace getVariable [QEGVAR(gui,grids), []]) param [_target param [1, -1], createHashMap];
            private _tile = (_grid getOrDefault ["tiles", []]) param [_target param [2, -1], createHashMap];

            ([_tile getOrDefault ["class", ""], _entry getOrDefault ["class", ""]] call _fnc_kitVerdict) params ["_fits", "_reason"];

            ["kitTile", _target param [1, -1], _target param [2, -1], 0, _fits, _reason]
        } else {
            nil
        }
    };
    default {nil};
};

if (isNil "_result") exitWith {nil};

_result
