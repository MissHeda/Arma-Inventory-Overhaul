#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What the comparison card shows (fnc_drawCompare) for a vest, uniform, helmet or backpack: how it differs
 * from the one the unit wears in that slot - armor, the zones it covers, room, what it holds and what it
 * weighs, each with the difference.
 *
 *   Armor (zone)  vests and helmets; uniforms only when the two differ - the chest for a vest or uniform,
 *                 the head for headgear, as ACE's damage counts it (einv_items_fnc_getProtection)
 *   Covers        vests and helmets - the zones that have armor; kept ones in the text colour, ones the item
 *                 gains in green, the worn item's lost ones appended with a minus in red
 *   Space         vests, uniforms and backpacks - cells
 *   Holds         the same - the maximum load; left out while only the room limits (einv_storage_gridOnly)
 *   Weight        all four - the item alone; heavier is red
 *
 * More armor and room are better, more weight is worse: a difference reads green when it helps, red when it
 * does not, "=" when there is none. Against nothing worn the difference is to nothing; the same class as the
 * one worn says so and shows "=" everywhere.
 *
 * Arguments:
 * 0: The unit whose gear it is compared with <OBJECT>
 * 1: Item class <STRING>
 *
 * Return Value:
 * [] for anything else than a vest, uniform, helmet or backpack, else <HASHMAP>
 *   "name"   - the item's name <STRING>
 *   "versus" - "vs. Carrier Lite", "vs. nothing worn" or "the same as yours" <STRING>
 *   "rows"   - [[label, value, difference, colour key of the difference, value is structured text, value as
 *              plain text], ...] - a structured value is TEXT <ARRAY>
 *
 * Example:
 * [player, "V_PlateCarrier2_rgr"] call einv_gui_fnc_compareRows;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_class", "", [""]]];

private _info = [_class] call EFUNC(items,getInfo);
private _kind = _info getOrDefault ["kind", ""];

if !(_kind in ["vest", "uniform", "headgear", "backpack"]) exitWith {[]};

// What the unit wears in that slot, and its container where it has one.
private _worn = "";
private _container = objNull;

switch (_kind) do {
    case "vest": {_worn = vest _unit; _container = vestContainer _unit};
    case "uniform": {_worn = uniform _unit; _container = uniformContainer _unit};
    case "headgear": {_worn = headgear _unit};
    default {_worn = backpack _unit; _container = backpackContainer _unit};
};

private _wornInfo = if (_worn isEqualTo "") then {createHashMap} else {[_worn] call EFUNC(items,getInfo)};
private _same = _worn isNotEqualTo "" && {(toLowerANSI _worn) isEqualTo (toLowerANSI _class)};

private _theme = GVAR(theme);

private _fnc_hex = {
    params ["_key"];

    "#" + ((((_theme getOrDefault [_key, [1, 1, 1, 1]]) select [0, 3]) apply {
        private _value = round ((_x max 0 min 1) * 255);
        ("0123456789ABCDEF" select [floor (_value / 16), 1]) + ("0123456789ABCDEF" select [_value mod 16, 1])
    }) joinString "")
};

// What a difference reads like: "+4" or "-4" or "=", and the colour it gets. Smaller than half a unit of
// the last decimal is no difference.
private _fnc_diff = {
    params ["_value", "_other", ["_higherIsBetter", true], ["_decimals", 0]];

    private _difference = _value - _other;

    if (abs _difference < 0.5 / (10 ^ _decimals)) exitWith {["=", "muted"]};

    [
        (["", "+"] select (_difference > 0)) + (_difference toFixed _decimals),
        ["loss", "gain"] select ((_difference > 0) isEqualTo _higherIsBetter)
    ]
};

private _fnc_zoneName = {
    params ["_zone"];

    switch (_zone) do {
        case "head": {LLSTRING(Zone_Head)};
        case "face": {LLSTRING(Zone_Face)};
        case "neck": {LLSTRING(Zone_Neck)};
        case "arms": {LLSTRING(Zone_Arms)};
        case "chest": {LLSTRING(Zone_Chest)};
        case "stomach": {LLSTRING(Zone_Stomach)};
        case "pelvis": {LLSTRING(Zone_Pelvis)};
        default {LLSTRING(Zone_Legs)};
    }
};

// Cells of a set of compartments, [[cols, rows], ...].
private _fnc_cells = {
    params ["_blocks"];

    private _sum = 0;

    {
        _sum = _sum + (_x select 0) * (_x select 1);
    } forEach _blocks;

    _sum
};

private _fnc_kg = {
    params ["_mass", ["_decimals", 1]];

    format ["%1 kg", (_mass * MASS_TO_KG) toFixed _decimals]
};

private _rows = [];

// ----- Armor, and the zones that have any -----
if (_kind in ["vest", "uniform", "headgear"]) then {
    private _protection = [_class] call EFUNC(items,getProtection);
    private _wornProtection = if (_worn isEqualTo "") then {createHashMap} else {[_worn] call EFUNC(items,getProtection)};

    private _zone = _protection getOrDefault ["mainZone", ""];

    if (_zone isEqualTo "") then {
        _zone = ["chest", "head"] select (_kind isEqualTo "headgear");
    };

    private _armor = round ((_protection getOrDefault ["zones", createHashMap]) getOrDefault [_zone, 0]);
    private _wornArmor = round ((_wornProtection getOrDefault ["zones", createHashMap]) getOrDefault [_zone, 0]);

    if (_kind isNotEqualTo "uniform" || {_armor != _wornArmor}) then {
        private _value = [str _armor, LLSTRING(Compare_NoArmor)] select (_armor <= 0);

        ([_armor, _wornArmor] call _fnc_diff) params ["_diffText", "_diffKey"];

        _rows pushBack [format [LLSTRING(Compare_Armor), [_zone] call _fnc_zoneName], _value, _diffText, _diffKey, false, _value];
    };

    if (_kind isNotEqualTo "uniform") then {
        private _has = (_protection getOrDefault ["order", []]);
        private _hadBefore = (_wornProtection getOrDefault ["order", []]);
        private _texts = [];
        private _plain = [];

        {
            private _name = [_x] call _fnc_zoneName;

            if (_x in _has) then {
                // Kept ones in the text colour; ones this item gains in green - against nothing worn
                // everything would be a gain, which says nothing.
                private _key = ["text", "gain"] select (!(_x in _hadBefore) && {_worn isNotEqualTo ""});

                _texts pushBack (text _name setAttributes ["color", [_key] call _fnc_hex]);
                _plain pushBack _name;
            } else {
                if (_x in _hadBefore) then {
                    _texts pushBack (text ("-" + _name) setAttributes ["color", ["loss"] call _fnc_hex]);
                    _plain pushBack ("-" + _name);
                };
            };
        } forEach ZONE_ORDER;

        if (_texts isNotEqualTo []) then {
            private _joined = [];

            {
                if (_forEachIndex > 0) then {
                    _joined pushBack ", ";
                };

                _joined pushBack _x;
            } forEach _texts;

            _rows pushBack [LLSTRING(Compare_Covers), composeText _joined, "", "muted", true, _plain joinString ", "];
        };
    };
};

// ----- Room: cells, and what it holds -----
if (_kind isNotEqualTo "headgear") then {
    private _cells = [[_class, _kind, _info getOrDefault ["maxLoad", 0], _info getOrDefault ["grid", []]] call EFUNC(storage,blocksFor)] call _fnc_cells;
    private _wornCells = if (isNull _container) then {0} else {[[_container] call EFUNC(storage,getBlocks)] call _fnc_cells};

    ([_cells, _wornCells] call _fnc_diff) params ["_diffText", "_diffKey"];

    private _value = format [LLSTRING(Compare_Cells), _cells];

    _rows pushBack [LLSTRING(Compare_Space), _value, _diffText, _diffKey, false, _value];

    // With only the room limiting, a container's load limits nothing.
    if (!EGVAR(storage,gridOnly)) then {
        private _load = _info getOrDefault ["maxLoad", 0];
        private _wornLoad = if (isNull _container) then {0} else {([_container] call EFUNC(storage,getMaxLoad)) max 0};

        ([_load * MASS_TO_KG, _wornLoad * MASS_TO_KG, true, 1] call _fnc_diff) params ["_loadDiff", "_loadKey"];

        private _loadValue = [_load] call _fnc_kg;

        _rows pushBack [LLSTRING(Compare_Holds), _loadValue, _loadDiff, _loadKey, false, _loadValue];
    };
};

// ----- Weight: the item alone -----
private _mass = _info getOrDefault ["mass", 0];
private _wornMass = _wornInfo getOrDefault ["mass", 0];
private _decimals = [1, 2] select ((_mass * MASS_TO_KG) < 1 || {(_wornMass * MASS_TO_KG) < 1 && {_worn isNotEqualTo ""}});

([_mass * MASS_TO_KG, _wornMass * MASS_TO_KG, false, _decimals] call _fnc_diff) params ["_massDiff", "_massKey"];

private _massValue = [_mass, _decimals] call _fnc_kg;

_rows pushBack [LLSTRING(Compare_Weight), _massValue, _massDiff, _massKey, false, _massValue];

// ----- What it is compared with -----
private _versus = if (_worn isEqualTo "") then {
    LLSTRING(Compare_Nothing)
} else {
    if (_same) then {LLSTRING(Compare_Same)} else {format [LLSTRING(Compare_Versus), [_worn] call FUNC(itemName)]}
};

createHashMapFromArray [["name", [_class] call FUNC(itemName)], ["versus", _versus], ["rows", _rows]]
