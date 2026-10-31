#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes the repack's result in one transaction (aio_storage_fnc_request): one phase at the root's
 * authority with the op "repack" (aio_storage_fnc_opRepack) - the magazines whose rounds changed leave their
 * containers by their old rounds, checked before and after, and come back with the new ones, their places
 * kept. A magazine taken meanwhile turns the whole repack down ("Gone"), nothing half-done. Where the
 * root is this player (own gear, and anything in single player) it runs at once; otherwise the server's
 * hub carries it to the machine the crate, vehicle, pile or body is local to.
 *
 * The answer comes to fnc_onCommitted with the record built here.
 *
 * Arguments:
 * 0: The job <HASHMAP>
 * 1: The rounds of each part at the end, as the schedule's counts <ARRAY>
 * 2: Why it ended, see fnc_stop <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_job, [0, 2, 30], "Stopped"] call aio_magazines_fnc_commit;
 *
 * Public: No
 */

params ["_job", "_counts", "_why"];

private _class = _job get "class";
private _parts = [];    // aio_storage_fnc_opRepack: [container, class, before, after, cell]
private _changed = [];  // for the window's search knowledge: [container, class, before, after]

// Only the magazines whose rounds changed - the others keep their place and their record.
{
    _x params ["_container", "_cell", "_before"];

    private _after = _counts select _forEachIndex;

    if (_after != _before) then {
        _parts pushBack [_container, _class, _before, _after, +_cell];
        _changed pushBack [_container, _class, _before, _after];
    };
} forEach (_job get "parts");

private _record = createHashMapFromArray [
    ["class", _class], ["capacity", _job get "capacity"], ["picture", _job get "picture"],
    ["why", _why], ["counts", _counts], ["parts", _changed]
];

private _id = [[[_job get "root", [["repack", [_parts]]]]], {_this call FUNC(onCommitted)}, _record] call EFUNC(storage,request);

// Nothing asked for: the same as a refusal.
if (_id isEqualTo "") then {
    ["Failed", _record] call FUNC(finish);
};
