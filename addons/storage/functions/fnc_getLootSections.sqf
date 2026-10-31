#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What is being looted, as sections for the loot column: the container the inventory was opened on,
 * then the second one the engine named with it (a body and the pile its weapon fell into, say), then
 * the uniforms, vests and backpacks opened from inside a container, then everything lying around the
 * unit (fnc_getNearby) - in the order fnc_orderSections gives.
 *
 *   a body        - what it wears, then its uniform, vest and backpack (fnc_getSections)
 *   a living person (einv_gui_fnc_openPerson) - the same, less a container the mission locked
 *   the ground    - one section, left out when nothing lies there; titled "Ground" when it is the only
 *                   pile in the column, else "Ground - <its largest item>"
 *   anything else - one section titled with the crate's or vehicle's name
 *
 * What a body wears is a section that only exists on the window: it has no container of its own, so
 * it carries its entries with it - one per worn thing, a weapon with its attachments and loaded
 * magazines, its rounds shown like a magazine's.
 *
 * Every section of a container also says where it belongs, for the window to move things in and out:
 *   "holder"  - what its places are kept on: its container <OBJECT>
 *   "root"    - whose locality decides who may change it (fnc_rootOf) <OBJECT>
 *   "parent"  - the container a uniform, vest or backpack was opened from, objNull for none <OBJECT>
 *   "nearby"  - found lying around rather than opened <BOOL>
 *   "folded"  - starts folded to its caption: the crates found lying around <BOOL>
 *   "side"    - "loot" <STRING>
 *
 * Arguments:
 * 0: Container <OBJECT>
 * 1: Second container, objNull for none <OBJECT>
 * 2: Uniforms, vests and backpacks opened from inside a container, [[class, object, container it lies
 *    in, ...], ...] <ARRAY> (default: [])
 * 3: What lies around the unit, fnc_getNearby's answer - what is listed already is left out <ARRAY>
 *    (default: [])
 *
 * Return Value:
 * Sections, as fnc_getSections, plus for the ground, crates and bodies <ARRAY of HASHMAPs>
 *   "id"      - also "ground", "container" or "worn" <STRING>
 *   "class"   - "" for the ground, a crate or what a body wears <STRING>
 *   "entries" - only for "worn": the entries to show, as fnc_getContents, each with its "slot" <ARRAY>
 *
 * Example:
 * [cursorObject, objNull] call einv_storage_fnc_getLootSections;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]], ["_secondary", objNull, [objNull]], ["_opened", [], [[]]], ["_nearby", [], [[]]]];

private _sections = [];

// The piles among them with what lies in each, to title them once all are known.
private _piles = [];

// Where a section of a container belongs (see the header).
private _fnc_belong = {
    params ["_section", "_object", ["_parent", objNull], ["_isNearby", false]];

    _section set ["holder", _object];
    _section set ["root", [_object, _parent] call FUNC(rootOf)];
    _section set ["parent", _parent];
    _section set ["nearby", _isNearby];
    _section set ["folded", _isNearby && {(_section get "id") isEqualTo "container"}];
    _section set ["side", "loot"];

    _section
};

private _fnc_addWorn = {
    params ["_body"];

    private _equipment = [_body] call FUNC(getEquipment);
    private _entries = [];

    // Weapons first, as on the shooters' screens, then from the head down, then the assigned items.
    {
        private _slot = _x;
        private _value = _equipment get _slot;

        if (_value isEqualType []) then {
            if (_value isNotEqualTo []) then {
                // A loaded weapon shows the rounds of its magazine. A designator's battery is no
                // magazine to anyone, so binoculars leave it out.
                private _magazine = _value param [4, [], [[]]];
                private _ammo = 0;
                private _capacity = 0;

                if (_magazine isNotEqualTo [] && {_slot isNotEqualTo "binocular"}) then {
                    _ammo = _magazine param [1, 0, [0]];
                    _capacity = ([_magazine select 0] call EFUNC(items,getInfo)) get "capacity";
                };

                _entries pushBack createHashMapFromArray [
                    ["class", _value select 0],
                    ["count", 1],
                    ["ammo", _ammo],
                    ["capacity", _capacity],
                    ["attachments", _value],
                    ["container", objNull],
                    ["slot", _slot]
                ];
            };
        } else {
            if (_value isNotEqualTo "") then {
                _entries pushBack createHashMapFromArray [
                    ["class", _value],
                    ["count", 1],
                    ["ammo", 0],
                    ["capacity", ([_value] call EFUNC(items,getInfo)) get "capacity"],
                    ["attachments", []],
                    ["container", objNull],
                    ["slot", _slot]
                ];
            };
        };
    } forEach [
        "primary", "handgun", "launcher",
        "headgear", "goggles", "nvg", "binocular", "uniform", "vest", "backpack",
        "map", "gps", "radio", "compass", "watch"
    ];

    private _title = [_body, false, true] call ACEFUNC(common,getName);

    // A body ACE knows no name for is called by what it was - "Rifleman" rather than "Unknown".
    if (_title isEqualTo "" || {_title isEqualTo localize "STR_ACE_Common_Unknown"}) then {
        _title = getText (configOf _body >> "displayName");
    };

    _sections pushBack createHashMapFromArray [
        ["id", "worn"],
        ["title", _title],
        ["class", ""],
        ["container", objNull],
        ["entries", _entries],
        ["unit", _body]
    ];
};

private _fnc_add = {
    params ["_object", ["_isNearby", false]];

    if (isNull _object) exitWith {};

    // A body or a living person (einv_gui_fnc_openPerson): what they wear, then what they carry.
    if (_object isKindOf "CAManBase") exitWith {
        [_object] call _fnc_addWorn;

        private _own = [_object] call FUNC(getSections);

        // A living soldier's uniform, vest or backpack the mission locked (lockInventory) stays shut, as
        // the engine keeps it.
        if (alive _object) then {
            _own = _own select {!lockedInventory (_x get "container")};
        };

        {
            [_x, _x get "container"] call _fnc_belong;
            _sections pushBack _x;
        } forEach _own;
    };

    if ([_object] call FUNC(isGroundHolder)) exitWith {
        // An empty pile is not worth a section - the engine opens one at the player's feet every time.
        private _contents = [_object] call FUNC(getContents);

        if (_contents isEqualTo []) exitWith {};

        private _section = createHashMapFromArray [
            ["id", "ground"],
            ["title", LLSTRING(Ground)],
            ["class", ""],
            ["container", _object]
        ];

        [_section, _object, objNull, _isNearby] call _fnc_belong;
        _sections pushBack _section;
        _piles pushBack [_section, _contents];
    };

    private _section = createHashMapFromArray [
        ["id", "container"],
        ["title", getText (configOf _object >> "displayName")],
        ["class", ""],
        ["container", _object]
    ];

    [_section, _object, objNull, _isNearby] call _fnc_belong;
    _sections pushBack _section;
};

[_container] call _fnc_add;

if (_secondary isNotEqualTo _container) then {
    [_secondary] call _fnc_add;
};

// Uniforms, vests and backpacks opened from inside a container, each under its own name and picture,
// below the container it was opened from (fnc_orderSections).
{
    _x params [["_class", ""], ["_object", objNull], ["_parent", objNull]];

    if (isNull _object || {_sections findIf {(_x getOrDefault ["container", objNull]) isEqualTo _object} >= 0}) then {continue};

    private _section = createHashMapFromArray [
        ["id", "container"],
        ["title", ([_class] call EFUNC(items,getInfo)) getOrDefault ["name", _class]],
        ["class", _class],
        ["container", _object]
    ];

    [_section, _object, _parent] call _fnc_belong;
    _sections pushBack _section;
} forEach _opened;

// What lies around, nearest first - not what is listed already.
{
    private _object = _x;

    if (isNull _object || {_sections findIf {(_x getOrDefault ["container", objNull]) isEqualTo _object} >= 0}) then {continue};

    [_object, true] call _fnc_add;
} forEach _nearby;

// More than one pile in the column: each is named by the largest thing in it, so they can be told apart.
if (count _piles > 1) then {
    {
        _x params ["_section", "_contents"];

        // Largest area first, then category, then class - the same for as long as the contents are.
        private _ranked = [];

        {
            private _rankInfo = [_x get "class"] call EFUNC(items,getInfo);

            (_rankInfo getOrDefault ["size", [1, 1]]) params ["_w", "_h"];
            _ranked pushBack [-(_w * _h), _rankInfo getOrDefault ["category", 0], toLowerANSI (_x get "class"), _forEachIndex];
        } forEach _contents;

        _ranked sort true;

        private _info = [(_contents select ((_ranked select 0) select 3)) get "class"] call EFUNC(items,getInfo);
        private _name = _info getOrDefault ["short", ""];

        if (_name isEqualTo "") then {
            _name = _info getOrDefault ["name", _info getOrDefault ["class", ""]];
        };

        _section set ["title", format [LELSTRING(gui,Ground_With), _name]];
    } forEach _piles;
};

[_sections] call FUNC(orderSections)
