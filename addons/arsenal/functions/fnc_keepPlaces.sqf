#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Keeps where things lie in the soldier's uniform, vest and backpack while ACE's window is open. Picking
 * another uniform, vest or backpack in ACE's list goes through setUnitLoadout, which makes all three
 * containers new objects with first-fit places - the arrangement the player chose in the two that did not
 * change was lost, and separate stacks merged. So the places of each container are noted (GVAR(kept):
 * [container, class, records] per slot, read again at most every KEPT_REFRESH seconds while the object is the
 * same) and, once a slot holds a new object, its notes are written to it (einv_storage_fnc_writePlaces) -
 * whatever its class: ACE carries the contents over to the container picked, so the player's arrangement stays
 * wherever it still fits. Only the records that still fit the new grid are written (einv_storage_fnc_fitRecords:
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
 * [] call einv_arsenal_fnc_keepPlaces;
 *
 * Public: No
 */

private _center = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];

if (isNull _center || {!local _center}) exitWith {};

private _objects = [uniformContainer _center, vestContainer _center, backpackContainer _center];
private _classes = [uniform _center, vest _center, backpack _center];
private _due = diag_tickTime >= GVAR(keptAt);
private _next = [];

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
            // as it fits the new grid. The compartments depend on whose it is (einv_storage_fnc_getOwner).
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

if (_due) then {
    GVAR(keptAt) = diag_tickTime + KEPT_REFRESH;
};
