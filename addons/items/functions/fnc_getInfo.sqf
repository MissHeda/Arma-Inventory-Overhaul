#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What an item is: its names, description and picture, its category (the tile's colour), its kind,
 * mass and grid size, how many may share one tile, a magazine's rounds, how much a container holds,
 * and for a container how its grid is split up. The config part comes from fnc_getFacts, the rest from
 * the rules (fnc_resolve) - see there for which layer wins:
 *
 *   1. the older table settings (sizes, stacks, container sizes) - read as rules after the text
 *   2. the rules text, einv_items_rules
 *   3. the item's own mod: einv_gridSize[], einv_stackSize, einv_grids[], einv_slots
 *   4. the preset the text builds on, with einv_items_stackSmall moved off its default
 *   5. built in: 1x1, alone on its tile, a grid by load
 * Weapons, binoculars, uniforms, vests and backpacks are always alone on their tile. A container
 * object can still carry a grid of its own (einv_grid, see einv_storage_fnc_getBlocks).
 *
 * A rule may also give an item a weight (weight=, in kg) and a name (name=). "mass", "name" and
 * "short" are then those; "configMass", "configDisplayName" and "configShort" keep what config says.
 * The engine still weighs every item by its config.
 *
 * Without compiled rules, the rules in effect are used and the result kept per class until the rules
 * change. Where no setting script runs (Eden, and the start of a mission before CBA's settings are
 * ready), those are compiled again first whenever the settings changed (fnc_currentRules), so even
 * there an item never shows by stale rules.
 *
 * Arguments:
 * 0: Class name <STRING>
 * 1: Compiled rules (fnc_compileRules) - a setup wizard's draft, say <HASHMAP> (default: the rules in
 *    effect)
 * 2: Where to keep the result per lowercase class - only with 1; without it nothing is kept
 *    <HASHMAP> (default: nil)
 *
 * Return Value:
 * The item, shared by every caller - do not change it <HASHMAP>
 *   "class"             - configName, or the class as given when no config knows it <STRING>
 *   "name", "short"     - the rules' name, else displayName / displayNameShort (or the name) <STRING>
 *   "description"       - descriptionShort, may contain <br/>, "" if none <STRING>
 *   "picture"           - "" if none <STRING>
 *   "category"          - CATEGORY_* <NUMBER>
 *   "kind"              - see fnc_getFacts <STRING>
 *   "mass"              - in config units (tenths of a pound): the rules' weight, else config's
 *                         <NUMBER>
 *   "size"              - [w, h] in grid cells, upright <ARRAY>
 *   "stack"             - how many may share one tile, at least 1 <NUMBER>
 *   "capacity"          - a magazine's rounds, 0 for everything else <NUMBER>
 *   "maxLoad"           - what a uniform, vest, backpack, crate or vehicle holds, else 0 <NUMBER>
 *   "cells"             - cells it takes, w * h <NUMBER>
 *   "shape"             - its size as the rules write it, "2x3" <STRING>
 *   "grid"              - a container's grid spec (fnc_parseGrid), [] for anything else <ARRAY>
 *   "src"               - field -> where it came from, see fnc_resolve <HASHMAP>
 *   "configMass"        - config mass <NUMBER>
 *   "configDisplayName", "configShort" - config's names <STRING>
 *   "weightOverride"    - the rules' weight in kg, -1 when none <NUMBER>
 *   "nameOverride"      - the rules' name, "" when none <STRING>
 *   and from fnc_getFacts: "lc", "root", "rounds", "lineage", "addon", "mod"
 *
 * Example:
 * ["arifle_MX_F"] call einv_items_fnc_getInfo;
 *
 * Public: Yes
 */

params [["_class", "", [""]], ["_compiled", nil, [createHashMap]], ["_cache", nil, [createHashMap]]];

private _key = toLowerANSI _class;

if (isNil "_compiled") then {
    // Once CBA's settings are ready, every change goes through a setting script, which compiles the
    // rules (fnc_loadRules) - only before that, and in Eden, does anything have to be compared here.
    if (isNil QGVAR(ruleset) || {isNil "cba_settings_ready"}) then {
        call FUNC(currentRules);
    };

    _compiled = GVAR(ruleset);
    _cache = GVAR(info);
};

private _cached = if (isNil "_cache") then {nil} else {_cache get _key};

if (!isNil "_cached") exitWith {_cached};

private _facts = [_class] call FUNC(getFacts);
private _resolved = [_facts, _compiled] call FUNC(resolve);
private _info = +_facts;

(_resolved get "footprint") params ["_w", "_h"];

_info set ["size", [_w, _h]];
_info set ["cells", _w * _h];
_info set ["shape", format ["%1x%2", _w, _h]];
_info set ["stack", _resolved get "stack"];
_info set ["grid", _resolved get "grid"];
_info set ["src", _resolved get "src"];

// What config says stays readable next to what the rules make of it.
private _weight = _resolved get "weight";
private _name = _resolved get "name";

_info set ["configMass", _facts get "mass"];
_info set ["configDisplayName", _facts get "name"];
_info set ["configShort", _facts get "short"];
_info set ["weightOverride", _weight];
_info set ["nameOverride", _name];

if (_weight >= 0) then {
    _info set ["mass", _weight / MASS_TO_KG];
};

if (_name isNotEqualTo "") then {
    _info set ["name", _name];
    _info set ["short", _name];
};

if (!isNil "_cache") then {
    _cache set [_key, _info];
};

_info
