#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The compartments of a kit's grid, for the storage (einv_storage_holderTypes "kit" "blocks",
 * einv_storage_fnc_getBlocks) and so for its window, its layout and every check of a cell in it: the
 * grid a rule or its config gives the kit (fnc_roomMode "cells"), laid out as any container's
 * (einv_storage_fnc_blocksFor, kind "kit": one compartment as near square as it goes, when the grid is a
 * number of cells or by its load - the type's capacity). [] while that mod's capacity is its room: an
 * open grid, STORAGE_COLS wide, that grows with what lies in it.
 *
 * Kept per kit until the rules change (einv_items_rulesRevision): asked whenever a kit is laid out.
 *
 * Arguments:
 * 0: Kit class <STRING>
 *
 * Return Value:
 * Compartments [[cols, rows, holes, pos], ...] - a copy, one with attributes also with its accepts and single
 * (einv_items_fnc_parseGrid) -, [] for an open grid <ARRAY>
 *
 * Example:
 * ["efak_IFAK_7"] call einv_compat_efak_fnc_kitBlocks;
 *
 * Public: No
 */

params [["_kit", "", [""]]];

private _key = toLowerANSI _kit;

if (_key isEqualTo "") exitWith {[]};

private _revision = missionNamespace getVariable [QEGVAR(items,rulesRevision), 0];

if ((GVAR(blocksCache) select 0) isNotEqualTo _revision) then {
    GVAR(blocksCache) = [_revision, createHashMap];
};

private _known = (GVAR(blocksCache) select 1) get _key;

if (isNil "_known") then {
    _known = [];

    if (([_kit] call FUNC(roomMode)) isEqualTo "cells") then {
        private _info = [_kit] call EFUNC(items,getInfo);

        _known = [
            _info getOrDefault ["class", _kit], "kit", _info getOrDefault ["maxLoad", 0], _info getOrDefault ["grid", ["auto"]],
            ([] call EFUNC(items,currentRules)) getOrDefault ["cell", 5]
        ] call EFUNC(storage,blocksFor);
    };

    (GVAR(blocksCache) select 1) set [_key, _known];
};

// A compartment that accepts only some categories or is a single slot keeps those two (einv_storage_fnc_blockMode): the kit's
// layout, its room checks and its window honour them as a container's do.
_known apply {
    private _block = [_x select 0, _x select 1, +(_x param [2, []]), +(_x param [3, []])];

    if (count _x > 4) then {
        _block append [+(_x param [4, []]), _x param [5, false]];
    };

    _block
}
