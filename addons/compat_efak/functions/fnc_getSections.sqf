#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The open kits, each as the section its floating window is drawn from (einv_gui_fnc_drawWindows, at
 * every build and whenever a kit opens or closes): the kit's picture and name on the window's title, how
 * full it is beside them, and a grid of tiles under them. No longer part of the loot column - a kit
 * opening or closing changes nothing there.
 *
 * Each open kit is looked for anew, by its class: in the cargo of every container the window shows
 * (the player's own, the loot, uniforms, vests and backpacks opened from inside a container), else
 * among the contents of another open kit - so a kit stays open wherever it is moved to within sight.
 * One found nowhere is closed: it left the window's reach, went back to a kit nobody has carried
 * (a loadout set with CBA, which gives it a new class) or was removed when it was emptied. Where each
 * one lies is kept for moving things in and out (GVAR(holders)).
 *
 * The kits an AI body carries may still be kits nobody has carried; while the window looks at one,
 * Enhanced First Aid Kits is asked to make them real (efak_core_fnc_requestUnitKits, which asks at
 * most every five seconds). A living soldier the window opens only while his kits are the player's to
 * reach by that mod's rule (fnc_mayReach) - not every soldier the player looks into: each kit made
 * real takes one of that mod's kit ids.
 *
 * Arguments:
 * 0: The player's own sections (einv_storage_fnc_getSections) <ARRAY>
 * 1: The loot column's sections (einv_storage_fnc_getLootSections) - real loot only, no kits <ARRAY>
 *
 * Return Value:
 * Sections, one per open kit in the order they were opened <ARRAY of HASHMAPs>
 *   "id"         - "kit"
 *   "title"      - the kit's name (fnc_getName, else the window's), its window's title
 *   "class"      - the kit's class, for the picture on its window's title
 *   "container"  - objNull: a kit is no container
 *   "maxLoad"    - -1
 *   "entries"    - what it holds (fnc_getEntries), [] while that has not reached this machine
 *   "virtual"    - false: things move in and out of it
 *   "kit"        - the kit's class, for its grid
 *   "key"        - "kit:" + the lowercase class: its window's key (einv_gui_fnc_openWindow,
 *                  einv_gui_fnc_closeWindow)
 *   "layoutKey"  - the same, the holder its places are kept for (einv_storage_fnc_getLayout)
 *   "holder"     - the same: the kit as a holder of the storage's transactions
 *                  (einv_storage_holderTypes "kit")
 *   "root"       - the root of the container it lies in, or of the container the outermost kit it is
 *                  packed in lies in - whose authority runs its ops (einv_storage_fnc_rootOf); objNull
 *                  when that is not known
 *   "parent"     - where it lies: the container its tile lies in, or "kit:" + the lowercase class of the
 *                  kit it is packed in
 *   "load"       - how full it is, "used / capacity" in that mod's measure
 *   "loadOver"   - fuller than its capacity
 *   "loadFraction" - how full it is, used / capacity, 0 for a kit with no capacity: the load bar's fill
 *                  (einv_gui_fnc_drawSection)
 *   "notice"     - "" or, while no kit may change yet - its contents have not reached this machine
 *                  (fnc_notReady) -, a line that says why, in its window in place of the grid
 *
 * Example:
 * [_ownSections, _lootSections] call einv_compat_efak_fnc_getSections;
 *
 * Public: No
 */

params [["_ownSections", [], [[]]], ["_lootSections", [], [[]]]];

if (!isNil QEFAKFUNC(core,requestUnitKits)) then {
    {
        if (
            !isNull _x && {_x isKindOf "CAManBase"} && {_x isNotEqualTo EGVAR(gui,unit)}
            && {!alive _x || {
                missionNamespace getVariable [QEFAKGVAR(core,interactWithOthers), true]
                && {missionNamespace getVariable [QEFAKGVAR(core,interactWithAwake), false] || {!([_x] call ACEFUNC(common,isAwake))}}
            }}
        ) then {
            [_x] call EFAKFUNC(core,requestUnitKits);
        };
    } forEach [EGVAR(gui,container), EGVAR(gui,secondary)];
};

if (GVAR(opened) isEqualTo []) exitWith {
    GVAR(holders) = createHashMap;
    []
};

// What the window shows, each with the lowercase classes of the items in it.
private _containers = [];

{
    private _container = _x getOrDefault ["container", objNull];

    if (!isNull _container && {!(_container in _containers)}) then {
        _containers pushBack _container;
    };
} forEach (_ownSections + _lootSections);

private _cargo = _containers apply {
    private _container = _x;
    private _classes = ((getItemCargo _container) param [0, []]) apply {toLowerANSI _x};

    [_container, _classes]
};

// The open kits by their lowercase class, to name a kit's holder in its own spelling.
private _spelling = createHashMapFromArray (GVAR(opened) apply {[toLowerANSI _x, _x]});
private _resolved = createHashMap;

// A kit packed in another open kit is found once that one is: a pass per level, as deep as kits go.
for "_pass" from 1 to KIT_MAX_DEPTH do {
    private _found = false;

    {
        private _key = toLowerANSI _x;

        if (_key in _resolved) then {continue};

        private _index = _cargo findIf {_key in (_x select 1)};

        if (_index >= 0) then {
            _resolved set [_key, [(_cargo select _index) select 0, ""]];
            _found = true;
            continue;
        };

        private _parent = "";

        // A HashMap: _x is the lowercase class of a kit found already.
        {
            private _candidate = _x;
            private _contents = [_candidate] call EFAKFUNC(core,getContents);

            if ((_contents findIf {toLowerANSI (_x select 0) isEqualTo _key}) >= 0) exitWith {
                _parent = _spelling getOrDefault [_candidate, _candidate];
            };
        } forEach _resolved;

        if (_parent isNotEqualTo "") then {
            _resolved set [_key, [objNull, _parent]];
            _found = true;
        };
    } forEach GVAR(opened);

    if (!_found) exitWith {};
};

GVAR(opened) = GVAR(opened) select {toLowerANSI _x in _resolved};
GVAR(holders) = _resolved;

private _synced = missionNamespace getVariable [QEFAKGVAR(core,contentsSynced), true];

// Why no kit may change yet, shown in place of the grid, so nothing can be dropped there
// (fnc_notReady).
private _wait = call FUNC(notReady);

GVAR(opened) apply {
    private _kit = _x;
    private _key = "kit:" + toLowerANSI _kit;
    private _used = [_kit] call EFAKFUNC(core,getUsedCapacity);
    private _capacity = [_kit] call EFAKFUNC(core,getCapacity);
    private _title = [_kit] call FUNC(getName);
    private _fraction = 0;

    if (_capacity > 0) then {
        _fraction = _used / _capacity;
    };

    if (_title isEqualTo "") then {
        _title = ([_kit] call EFUNC(items,getInfo)) getOrDefault ["name", _kit];
    };

    // Where it lies, and up to the container the outermost kit lies in - whose root runs its ops.
    (_resolved getOrDefault [toLowerANSI _kit, [objNull, ""]]) params ["_container", "_parentKit"];

    private _top = _container;
    private _outer = _parentKit;

    for "_i" from 1 to KIT_MAX_DEPTH do {
        if (!isNull _top || {_outer isEqualTo ""}) exitWith {};

        (_resolved getOrDefault [toLowerANSI _outer, [objNull, ""]]) params ["_next", "_nextParent"];

        _top = _next;
        _outer = _nextParent;
    };

    createHashMapFromArray [
        ["id", "kit"],
        ["title", _title],
        ["class", _kit],
        ["container", objNull],
        ["maxLoad", -1],
        ["entries", if (_synced) then {[_kit] call FUNC(getEntries)} else {[]}],
        ["virtual", false],
        ["kit", _kit],
        ["key", _key],
        ["layoutKey", _key],
        ["holder", _key],
        ["root", if (isNull _top) then {objNull} else {[_top] call EFUNC(storage,rootOf)}],
        ["parent", if (_parentKit isEqualTo "") then {_container} else {"kit:" + toLowerANSI _parentKit}],
        ["load", format ["%1 / %2 %3", round _used, round _capacity, localize "STR_efak_gui_MassUnit"]],
        ["loadOver", _used > _capacity + KIT_MASS_EPSILON],
        ["loadFraction", _fraction],
        ["notice", _wait]
    ]
}
