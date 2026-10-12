#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "sort": the holder's records emptied and its contents laid out anew - everything first fit, largest
 * first. The context menu's Sort, for everyone who looks.
 *
 * Every record of the view's tiles comes out, and the first-fit picture of fnc_getLayout without any
 * records goes in instead; what no tile matches any more stays unused (fnc_getLayout places every tile
 * by its own record first). The end of the phase writes it once (einv_storage_fnc_execute).
 *
 * Arguments:
 * 0: Args, [holder] <ARRAY>
 * 1: Context - "requester", "where", "txId", "root", "settlement" (einv_storage_fnc_execute) <HASHMAP>
 *
 * Return Value:
 * [status, produced, extra] <ARRAY>
 *   status - "" done, else why not ("Gone", "Taken", "NoRoom", "TooHeavy", "NotLocal", "Moved",
 *     "IntoItself", "OutOfReach", "Bounced", "Skipped", "Failed", a guard's reason or a reason already
 *     in words)
 *   produced - the payloads it handed on, each consumed by a later op or settled
 *     (einv_storage_fnc_settle)
 *   extra - what else it tells, [] for nothing
 *
 * Example:
 * [[cursorObject], _context] call einv_storage_fnc_opSort;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];

_args params [["_holder", objNull, [objNull, ""]]];

private _view = [_holder, []] call FUNC(findEntry);

if (count _view == 0) exitWith {["Moved", [], []]};

// Every tile's record out.
{
    if ((_x getOrDefault ["count", 1]) > 0 && {!(_x getOrDefault ["overflow", false])}) then {
        [_holder, _x, []] call FUNC(setPlace);
    };
} forEach (_view getOrDefault ["entries", []]);

// Laid out as if nothing had ever been placed: first fit, largest first - fresh entries, the view's own
// stay as they lie until it is laid out anew.
private _entries = if (_holder isEqualType "") then {
    private _type = GVAR(holderTypes) getOrDefault [(_holder splitString ":") param [0, ""], createHashMap];

    [_holder] call (_type getOrDefault ["entries", {[]}])
} else {
    [_holder] call FUNC(getContents)
};

if (isNil "_entries" || {!(_entries isEqualType [])}) then {
    _entries = [];
};

private _sorted = [_holder, _entries, false, []] call FUNC(getLayout);

{
    if !(_x getOrDefault ["overflow", false]) then {
        [_holder, _x, [_x get "col", _x get "row", _x get "block", _x get "w", _x get "h"], true] call FUNC(setPlace);
    };
} forEach (_sorted getOrDefault ["entries", []]);

// Everything lies elsewhere now: laid out anew when asked.
GVAR(cache) deleteAt (if (_holder isEqualType "") then {_holder} else {netId _holder});

["", [], []]
