#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Keeps where things lie in the soldier's uniform, vest and backpack while ACE's window is open. Picking
 * another uniform, vest or backpack in ACE's list goes through setUnitLoadout, which makes all three
 * containers new objects with first-fit places - the arrangement the player chose in the two that did not
 * change was lost, and separate stacks merged. So the places of each container are noted (GVAR(kept):
 * [container, class, records] per slot, read again at most every KEPT_REFRESH seconds while the object is the
 * same) and, once a slot holds a new object, its notes are written to it (aio_storage_fnc_writePlaces) -
 * whatever its class: ACE carries the contents over to the container picked, so the player's arrangement stays
 * wherever it still fits. Only the records that still fit the new grid are written (aio_storage_fnc_fitRecords:
 * the box inside a compartment, on no hole, overlapping no other), so a container with the exact same layout -
 * another vest of the same cut, the same uniform again after the insignia was changed - keeps everything as it
 * lay, and in a different one only what has no room where it lay gets a fresh first fit. Records that no longer
 * match the contents drop out at the next layout, so a changed content is safe.
 * Called before anything of ours reads or normalizes the new containers (fnc_snapshot, fnc_onItemsChanged,
 * the frame hook), so no first-fit picture is written first.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call aio_arsenal_fnc_keepPlaces;
 *
 * Public: No
 */

private _center = (call FUNC(center));

if (isNull _center || {!local _center}) exitWith {};

// The uniforms, vests and backpacks lying in the containers first: one the arsenal's rebuild left empty is filled
// again before anything of ours lays it out or gives it a fresh id (fnc_keepNested).
["check"] call FUNC(keepNested);

private _objects = [uniformContainer _center, vestContainer _center, backpackContainer _center];
private _classes = [uniform _center, vest _center, backpack _center];
private _due = diag_tickTime >= GVAR(keptAt);
private _next = [];
// The slots (3 uniform, 4 vest, 5 backpack of a loadout) that hold another class of container than at the last look.
private _swapped = [];

{
    private _object = _x;
    private _class = toLowerANSI (_classes select _forEachIndex);
    (GVAR(kept) param [_forEachIndex, [objNull, "", []]]) params ["_oldObject", "_oldClass", "_oldRecords"];

    if (isNull _object) then {
        _next pushBack [objNull, "", []];
    } else {
        private _records = _oldRecords;

        if (_object isNotEqualTo _oldObject) then {
            // A new object, of the same class or another: the arrangement the player had comes back to it, as far
            // as it fits the new grid. The compartments depend on whose it is (aio_storage_fnc_getOwner).
            if (_oldClass isNotEqualTo "" && {_class isNotEqualTo ""} && {_class isNotEqualTo _oldClass}) then {
                _swapped pushBack (_forEachIndex + 3);
            };

            if (_oldClass isNotEqualTo "" && {_oldRecords isNotEqualTo []}) then {
                _object setVariable [QEGVAR(storage,owner), _center];

                private _fitting = [_object, _oldRecords] call EFUNC(storage,fitRecords);

                if (_fitting isNotEqualTo []) then {
                    [_object, _fitting] call EFUNC(storage,writePlaces);
                };
            };

            _records = (([_object] call EFUNC(storage,readPlaces)) select 1);
        } else {
            if (_due) then {
                _records = (([_object] call EFUNC(storage,readPlaces)) select 1);
            };
        };

        _next pushBack [_object, _class, _records];
    };
} forEach _objects;

GVAR(kept) = _next;

// Another uniform, vest or backpack picked: ACE carries the contents over with setUnitLoadout, which stops filling at the
// new container's maximumLoad - a smaller vest came back with half the magazines, the rest gone for good (Haiden, Discord
// 2026-11-09). The grid does not care about that load, so what the engine left out is added again as for any loadout
// (aio_storage_fnc_topUpLoadout, only what was turned down for the load); what has no cells then moves on to another
// container or the staging space like any overflow (fnc_stageOverflow). Only when the new container holds nothing that
// was not there before - a loadout loaded into another vest brings contents of its own and is left alone - and never in a
// loadout's quiet time.
if (_swapped isNotEqualTo [] && {GVAR(keptLoadout) isNotEqualTo []} && {diag_frameNo > GVAR(loadoutFrame)}) then {
    private _now = getUnitLoadout _center;
    private _wanted = +GVAR(keptLoadout);

    // An entry of a container's list without its count, so the same thing in other numbers is the same key.
    private _keys = {
        params ["_list"];

        private _result = createHashMap;

        {
            if (_x isEqualType [] && {count _x >= 2}) then {
                private _key = toLowerANSI str ((_x select [0, 1]) + (_x select [2]));

                private _count = _x select 1;

                if (_count isEqualType 0) then {
                    _result set [_key, (_result getOrDefault [_key, 0]) + (_count max 0)];
                };
            };
        } forEach _list;

        _result
    };

    private _onlyOld = _swapped findIf {
        private _index = _x;
        private _old = [((GVAR(keptLoadout) param [_index, []]) param [1, [], [[]]])] call _keys;
        private _new = [((_now param [_index, []]) param [1, [], [[]]])] call _keys;

        (keys _new) findIf {(_new get _x) > (_old getOrDefault [_x, 0])} >= 0
    } < 0;

    if (_onlyOld) then {
        {
            private _slot = _wanted param [_x, []];

            if (_slot isEqualType [] && {count _slot >= 2}) then {
                _slot set [0, _classes select (_x - 3)];
            };
        } forEach _swapped;

        private _added = [_center, _wanted] call EFUNC(storage,topUpLoadout);

        if (_added > 0) then {
            INFO_1("Another container picked in the arsenal: %1 things its load turned down were put back.",_added);

            // A uniform among them comes back empty, as a class: filled from what it held (fnc_keepNested).
            ["check"] call FUNC(keepNested);
        };
    };

    _due = true;
};

if (_due) then {
    GVAR(keptAt) = diag_tickTime + KEPT_REFRESH;
    GVAR(keptLoadout) = getUnitLoadout _center;
};
