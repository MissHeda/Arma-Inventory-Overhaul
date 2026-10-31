#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Hands a holder's records on to be kept: while a phase runs here (fnc_execute) into the execution's
 * buffer, written once when the phase ends; outside a phase - the Arsenal, Eden - at once
 * (fnc_writePlaces), which refuses on any machine but the authority.
 *
 * Arguments:
 * 0: Holder - a container, or the key of a grid with no object <OBJECT or STRING>
 * 1: Records, [[key, col, row, w, h, block, rot, count], ...] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_crate, _records] call aio_storage_fnc_setRecords;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull, ""]], ["_records", [], [[]]]];

if (GVAR(executing)) then {
    private _index = GVAR(buffer) findIf {(_x select 0) isEqualTo _holder};

    if (_index >= 0) then {
        (GVAR(buffer) select _index) set [1, _records];
    } else {
        GVAR(buffer) pushBack [_holder, _records];
    };
} else {
    [_holder, _records] call FUNC(writePlaces);
};
