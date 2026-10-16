#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The config lines that give a class what the rules make of it now, ready to paste into a mod:
 *
 *   class CfgVehicles { class B_Carryall_blk { einv_grid = "1x3+5x7+1x3"; }; };
 *
 * The root is the class's own (CfgWeapons for uniforms, vests, headgear and most items, CfgVehicles for
 * backpacks, crates and vehicles, CfgMagazines, CfgGlasses), the keys are the ones an item's config may
 * set (fnc_readConfigKeys): einv_size, einv_stack, einv_grid, einv_weight, einv_name and einv_icon, each
 * as applicable - a container has a grid, a rifle, vest or backpack no stack. They are written as the
 * rules write the same value, so a shaped grid or a canvas comes out as the text that draws it.
 *
 * Only what differs is written. The class's current answer is set beside what it would get without
 * the rules text and the older tables - the answer of its own config and of the preset the rules are
 * built on, and the built-in one for what neither says. So a class whose size the preset already
 * gives and whose grid was painted in the wizard gets its grid and nothing else, and the lines say
 * what the mod itself has to add for the class to look like this; the preset stays the server's to
 * choose. A class that already is what the lines would make gets "". With "all" every key that has an
 * answer is written, differing or not (a weight, a name and an icon only where something sets them).
 *
 * The lines go inside the class's own definition in the mod's config. Another mod's class is patched
 * with an external class declaration and its addon in requiredAddons; a subclass inherits the keys
 * of its parent, as everything in config does.
 *
 * Arguments:
 * 0: Class name, from CfgWeapons, CfgVehicles, CfgMagazines or CfgGlasses <STRING>
 * 1: Write every key that has an answer, not only the ones that differ <BOOL> (default: false)
 * 2: Compiled rules to read the class by - a setup wizard's draft, say; the rules in effect when
 *    left out <HASHMAP> (default: nil)
 *
 * Return Value:
 * One line of config, "" for a class no config knows or when nothing differs <STRING>
 *
 * Example:
 * ["B_Carryall_blk"] call einv_items_fnc_configEntry;
 * ["V_PlateCarrier1_rgr", true] call einv_items_fnc_configEntry;
 *
 * Public: Yes
 */

params [["_class", "", [""]], ["_all", false, [false]], ["_compiled", nil, [createHashMap]]];

private _facts = [_class] call FUNC(getFacts);
private _root = _facts get "root";

if (_root isEqualTo "") exitWith {""};

private _info = if (isNil "_compiled") then {
    [_class] call FUNC(getInfo)
} else {
    [_class, _compiled] call FUNC(getInfo)
};

private _kind = _facts get "kind";

// What the class would get without the rules text and the older tables (both are the "own" rules of
// the compiled form): the same rules, shallow-copied, with the own rules gone and the kind's index
// list pointing at the preset's alone.
private _rules = if (isNil "_compiled") then {[] call FUNC(currentRules)} else {_compiled};
private _bare = createHashMapFromArray (toArray _rules);
private _byKind = createHashMapFromArray (toArray (_rules getOrDefault ["byKind", createHashMap]));
private _kindRules = _byKind getOrDefault [_kind, [[], [], [], []]];

_byKind set [_kind, [[], _kindRules select 1, [], _kindRules select 3, [], []]];
_bare set ["own", []];
// The text's "all" rules are the text's too.
_bare set ["fallback", []];
_bare set ["byKind", _byKind];

private _plain = [_facts, _bare] call FUNC(resolve);
private _lines = [];

// A text as config holds it in quotes: a quote in it is written twice.
private _fnc_quote = {
    params ["_text"];

    private _codes = [];

    {
        _codes pushBack _x;

        if (_x == 34) then {
            _codes pushBack 34;
        };
    } forEach toArray _text;

    toString [34] + toString _codes + toString [34]
};

// ----- size -----

private _footprint = _info get "footprint";

if (_all || {_footprint isNotEqualTo (_plain get "footprint")}) then {
    _lines pushBack format ["%1 = %2;", QGVARMAIN(size), [_footprint call FUNC(formatMask)] call _fnc_quote];
};

// ----- stack -----
// Not for what never shares a tile: whatever the config says, it stays 1.

if !(_kind in KINDS_SINGLE) then {
    private _stack = _info get "stack";

    if (_all || {_stack != (_plain get "stack")}) then {
        _lines pushBack format ["%1 = %2;", QGVARMAIN(stack), _stack];
    };
};

// ----- grid -----

if (_kind in KINDS_CONTAINER) then {
    private _grid = [_info get "grid"] call FUNC(formatGrid);

    if (_grid isNotEqualTo "" && {_all || {_grid isNotEqualTo ([_plain get "grid"] call FUNC(formatGrid))}}) then {
        _lines pushBack format ["%1 = %2;", QGVARMAIN(grid), [_grid] call _fnc_quote];
    };
};

// ----- weight -----
// In kg, as weight= has it. The rules' weight against config's own, to the gram.

private _weight = _info get "weightOverride";

if (_weight >= 0) then {
    private _plainWeight = _plain get "weight";

    if (_plainWeight < 0) then {
        _plainWeight = (_facts get "mass") * MASS_TO_KG;
    };

    if (_all || {abs (_weight - _plainWeight) >= 0.0005}) then {
        _lines pushBack format ["%1 = %2;", QGVARMAIN(weight), _weight];
    };
};

// ----- name -----

private _name = _info get "nameOverride";

if (_name isNotEqualTo "") then {
    private _plainName = _plain get "name";

    if (_plainName isEqualTo "") then {
        _plainName = _facts get "name";
    };

    if (_all || {_name isNotEqualTo _plainName}) then {
        _lines pushBack format ["%1 = %2;", QGVARMAIN(name), [_name] call _fnc_quote];
    };
};

// ----- icon -----
// As config writes it, the comma between the offsets. Only where the rules or the config set one: the plain
// picture needs no line.

private _icon = _info get "icon";

if (
    (_all && {_icon isNotEqualTo ICON_PLAIN})
    || {!_all && {_icon isNotEqualTo (_plain get "icon")}}
) then {
    _lines pushBack format ["%1 = %2;", QGVARMAIN(icon), [[_icon, ","] call FUNC(formatIcon)] call _fnc_quote];
};

if (_lines isEqualTo []) exitWith {""};

format ["class %1 { class %2 { %3 }; };", _root, _facts get "class", _lines joinString " "]
