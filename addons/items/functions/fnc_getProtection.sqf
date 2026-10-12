#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What a vest, uniform or helmet protects: its armor per body zone (head, face, neck, arms, chest,
 * stomach, pelvis, legs) as ACE's damage counts it (fnc_getArmor), and the one number the comparison card
 * leads with - the chest for a vest or uniform, the head for headgear (or, should that give none, the
 * zone it protects best). A zone with no armor is left out; a uniform gives its chest only, as the body's
 * own armor sits under every other zone.
 *
 * Config does not change while the game runs and the rules do not touch armor, so this is read once per
 * class and kept in uiNamespace for good.
 *
 * Arguments:
 * 0: Item class <STRING>
 *
 * Return Value:
 * Protection, shared by every caller - do not change it <HASHMAP>
 *   "zones"    - zone -> armor, only where above 0 <HASHMAP>
 *   "order"    - the zones that have armor, head to legs <ARRAY of STRINGs>
 *   "mainZone" - the zone the card leads with, "" for an item that protects nothing <STRING>
 *   "main"     - its armor <NUMBER>
 *
 * Example:
 * ["V_PlateCarrier1_rgr"] call einv_items_fnc_getProtection;
 *
 * Public: Yes
 */

params [["_class", "", [""]]];

private _cache = uiNamespace getVariable QGVAR(protection);

if (isNil "_cache") then {
    _cache = createHashMap;
    uiNamespace setVariable [QGVAR(protection), _cache];
};

private _key = toLowerANSI _class;
private _known = _cache get _key;

if (!isNil "_known") exitWith {_known};

private _kind = ([_class] call FUNC(getInfo)) getOrDefault ["kind", ""];

// The zones and the hitpoints that make each up, in the order they are listed in. Arms and legs take the
// most the item gives to any of theirs.
private _table = [
    ["head", ["HitHead"]], ["face", ["HitFace"]], ["neck", ["HitNeck"]],
    ["arms", ["HitArms", "HitLeftArm", "HitRightArm", "HitHands"]],
    ["chest", ["HitChest"]], ["stomach", ["HitAbdomen"]], ["pelvis", ["HitPelvis"]],
    ["legs", ["HitLegs", "HitLeftLeg", "HitRightLeg"]]
];

private _zones = createHashMap;
private _order = [];

if (_kind in ["vest", "uniform", "headgear"]) then {
    {
        _x params ["_zone", "_hitpoints"];

        // A uniform: only the chest. The soldier's own armor lies under every other zone alike.
        if (_kind isEqualTo "uniform" && {_zone isNotEqualTo "chest"}) then {continue};

        private _armor = 0;

        {
            _armor = _armor max ([_class, _x] call FUNC(getArmor));
        } forEach _hitpoints;

        if (_armor > 0) then {
            _zones set [_zone, _armor];
            _order pushBack _zone;
        };
    } forEach _table;
};

private _mainZone = ["chest", "head"] select (_kind isEqualTo "headgear");
private _main = _zones getOrDefault [_mainZone, 0];

// Nothing there: the zone it protects best leads instead.
if (_main <= 0 && {_order isNotEqualTo []}) then {
    _mainZone = _order select 0;
    _main = _zones get _mainZone;

    {
        if ((_zones get _x) > _main) then {
            _mainZone = _x;
            _main = _zones get _x;
        };
    } forEach _order;
};

if (_main <= 0) then {
    _mainZone = "";
};

private _protection = createHashMapFromArray [["zones", _zones], ["order", _order], ["mainZone", _mainZone], ["main", _main]];

_cache set [_key, _protection];

_protection
