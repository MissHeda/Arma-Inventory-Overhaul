#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Everything built on a class, the class itself first: the classes of its config root that inherit from
 * it, directly or through others, scope 1 or 2 and the hidden bases between them (fnc_treeIndex). This is
 * the set a rule class=X+ covers, and so what an edit of the tree writes to. Kept per class for the game
 * session; fnc_treeRows makes the list a step shows of it.
 *
 * Arguments:
 * 0: Class, lowercase or as config names it <STRING>
 *
 * Return Value:
 * An empty HashMap for a class no config knows, else <HASHMAP>
 *   "class"    - the class as config names it
 *   "root"     - the config root it is in
 *   "parent"   - its parent, lowercase, "" for none
 *   "order"    - [[class in lowercase, depth], ...] in tree order (a class, then its children), the class
 *                itself at depth 0
 *   "set"      - the same classes as a set: class in lowercase -> true
 *
 * Example:
 * ["B_Carryall_Base"] call aio_setup_fnc_classTree;
 *
 * Public: No
 */

params [["_class", "", [""]]];

private _lc = toLowerANSI _class;
private _cache = uiNamespace getVariable QGVAR(treeCache);

if (isNil "_cache") then {
    _cache = createHashMap;
    uiNamespace setVariable [QGVAR(treeCache), _cache];
};

private _known = _cache get _lc;

if (!isNil "_known") exitWith {_known};

private _rootName = [_lc] call FUNC(classRoot);

if (_rootName isEqualTo "") exitWith {createHashMap};

private _data = [_rootName] call FUNC(treeIndex);
private _children = _data get "children";
private _order = [];
private _set = createHashMap;
private _stack = [[_lc, 0]];

// The class, then each of its children with theirs; the children are pushed last first so the first one
// is taken next.
while {_stack isNotEqualTo []} do {
    (_stack deleteAt (count _stack - 1)) params ["_node", "_depth"];

    if (_node in _set) then {continue};

    _set set [_node, true];
    _order pushBack [_node, _depth];

    private _kids = _children getOrDefault [_node, []];

    for "_i" from (count _kids - 1) to 0 step -1 do {
        _stack pushBack [_kids select _i, _depth + 1];
    };
};

_known = createHashMapFromArray [
    ["class", (_data get "names") getOrDefault [_lc, _class]],
    ["root", _rootName],
    ["parent", (_data get "parent") getOrDefault [_lc, ""]],
    ["order", _order],
    ["set", _set]
];

_cache set [_lc, _known];

_known
