#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "sort": the holder's records emptied and its contents laid out anew - everything first fit, in the
 * order asked for (largest first when none is). The Sort button of a section's caption line and of a kit
 * window, for everyone who looks.
 *
 * Every record of the view's tiles comes out, and the first-fit picture of fnc_getLayout without any
 * records goes in instead; what no tile matches any more stays unused (fnc_getLayout places every tile
 * by its own record first). The end of the phase writes it once (einv_storage_fnc_execute). The order
 * travels in the op's arguments: the player who asked chose it, and it is laid out where the container's
 * root is local, so the places that everyone reads are the same.
 *
 * Arguments:
 * 0: Args, [holder, order] - the order one of SORT_MODES, "size" for none or anything else (fnc_getLayout)
 *    <ARRAY>
 * 1: Context - "requester", "where", "txId", "root", "settlement" (einv_storage_fnc_execute) <HASHMAP>
 *
 * Return Value:
 * [status, produced, extra] <ARRAY>
 *   status - "" done, else why not ("Gone", "Taken", "NoRoom", "NotLocal", "Moved",
 *     "IntoItself", "OutOfReach", "Bounced", "Skipped", "Failed", a guard's reason or a reason already
 *     in words)
 *   produced - the payloads it handed on, each consumed by a later op or settled
 *     (einv_storage_fnc_settle)
 *   extra - what else it tells, [] for nothing
 *
 * Example:
 * [[cursorObject, "name"], _context] call einv_storage_fnc_opSort;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];

_args params [["_holder", objNull, [objNull, ""]], ["_order", SORT_DEFAULT, [""]]];

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

private _sorted = [_holder, _entries, false, [], _order] call FUNC(getLayout);

{
    if !(_x getOrDefault ["overflow", false]) then {
        [_holder, _x, [_x get "col", _x get "row", _x get "block", _x get "w", _x get "h", parseNumber (_x getOrDefault ["rotated", false])], true] call FUNC(setPlace);
    };
} forEach (_sorted getOrDefault ["entries", []]);

// Everything lies elsewhere now: laid out anew when asked.
GVAR(cache) deleteAt (if (_holder isEqualType "") then {_holder} else {netId _holder});

["", [], []]
