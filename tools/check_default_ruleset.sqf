/*
 * Author: Miss Heda
 * Checks that the shipped default ruleset (CfgAioRulesets >> default, the one preset there is) gives every
 * item the size and stack, and every container the compartments, it is meant to: the sizes of "expected" below
 * (rifles from 4x2 to 7x2, backpack tiles 4x4, 5x5 and 5x6, the rest as they always were), nothing stacking
 * but the classes of the @stack_* groups with the number of their group and the medical items of the rules that follow
 * them (class=..., ACE, ACM, ACME, EFAK; checked against those rules compiled alone, and a few of them by the stack
 * the play settings of issue #21 give: dressings, vials, cannulas and syringes 5, tourniquets and injectors 4, lozenges and
 * IV lines 10, bags and devices 1; aio_storage_fnc_stackFor multiplies those in a crate), and containers laid out from
 * 120 % of their load - a uniform one block 6 wide and 2 to 5 rows high, a vest pouches of 1x2 and 2x2, a backpack one
 * near-square block, crates and vehicles as wide as the columns - with nothing set in the older tables and both
 * sliders on their defaults. Also checks that the default's groups are a partition (an item in two of them
 * would let a rule for one reach into the other; only medical and the stack groups overlap on purpose), that
 * texts read and written stay the same, and that names survive being written into a rule.
 *
 * Not part of the mod. Copy it into a mission's folder - the test mission in .hemtt/missions will do -
 * start the mission with the mods to check (vanilla, ACE, a large pack), and run in the debug console:
 *
 *     [] execVM "check_default_ruleset.sqf"
 *
 * It takes a few seconds with large packs. The summary shows as a hint, every finding goes to the RPT
 * and, with the summary, to the clipboard.
 *
 * Expected: no size, stack, compartment or round-trip differences and no overlaps. Compartment differences
 * marked "caps" come from the limits on what a mod's aio_grids[] may ask for (24 compartments, 400 cells). Also
 * checked: a text that names a preset that is gone (base=tarkov, realism, weight) builds on the default, and
 * canvases (grid=aaa/aba/aaa) read and write the same, as does everything else (all > ..., "all" written first
 * wherever it was typed), and categories of the setup's own (category=bandit > name=... picture=...) are registered, merged
 * and refused as the rules say.
 */

private _compiled = ["aio1 base=default", false] call aio_items_fnc_compileRules;

// The medical items of ACE, ACM, ACME and Enhanced First Aid Kits (issue #9): the default's rules that name a class
// (they follow the @stack_* groups) give them sizes and stacks of their own, not the old ones below. Compiled alone,
// they say what such a class has to come out as; every other class is still checked against the old answers.
private _medicalRules = (getArray (configFile >> "CfgAioRulesets" >> "default" >> "rules")) select {
    (_x select [0, 6]) in ["class=", "class~"]
};
private _medical = ["aio1 base=none, " + (_medicalRules joinString ", "), false] call aio_items_fnc_compileRules;
private _medicalCache = createHashMap;
private _cache = createHashMap;
private _cell = _compiled get "cell";
private _report = [];
private _counts = createHashMapFromArray [
    ["classes", 0], ["size", 0], ["stack", 0], ["stackSmall", 0], ["blocks", 0], ["caps", 0], ["overlap", 0], ["roundTrip", 0]
];
private _fnc_count = {
    params ["_key", "_line"];

    _counts set [_key, (_counts get _key) + 1];

    // Enough to see what is going on; the counts say how many there are.
    if ((_counts get _key) <= 200) then {
        _report pushBack _line;
    };
};

// ----- The code before the rules, with the tables empty - ten columns and default's 120 % -----

// STORAGE_COLS and MAX_CELLS, which a mission's script cannot include.
private _storageCols = 10;
private _maxCells = 400;

// The sizes the default ships: aio_gridSize[] in config, else by kind and mass.
private _fnc_oldSize = {
    params ["_config", "_kind", "_mass", "_maxLoad", "_count"];

    private _size = getArray (_config >> "aio_gridSize");

    if (_size isEqualTypeArray [0, 0] && {(_size select 0) >= 1} && {(_size select 1) >= 1}) then {
        _size = _size apply {floor _x};
    } else {
        _size = switch (_kind) do {
            case "rifle": {
                switch (true) do {
                    case (_mass <= 55): {[4, 2]};
                    case (_mass <= 90): {[5, 2]};
                    case (_mass <= 150): {[6, 2]};
                    default {[7, 2]};
                };
            };
            case "handgun": {[2, 1]};
            case "launcher": {[6, 2]};
            case "magazine": {
                switch (true) do {
                    case (_count >= 50 && {_mass > 15}): {[2, 2]};
                    case (_count == 1 && {_mass > 15}): {[[1, 3], [2, 3]] select (_mass > 60)};
                    case (_mass <= 5): {[1, 1]};
                    case (_mass <= 20): {[1, 2]};
                    default {[2, 2]};
                };
            };
            case "grenade": {[1, 1]};
            case "muzzle": {[2, 1]};
            case "optic": {[[1, 1], [2, 1]] select (_mass > 8)};
            case "rail";
            case "bipod": {[1, 1]};
            case "uniform": {[2, 2]};
            case "vest": {[3, 3]};
            case "headgear": {[2, 2]};
            case "goggles": {[1, 1]};
            case "nvg";
            case "binocular": {[2, 1]};
            case "backpack": {
                switch (true) do {
                    case (_maxLoad <= 160): {[4, 4]};
                    case (_maxLoad <= 280): {[5, 5]};
                    default {[5, 6]};
                };
            };
            case "map";
            case "gps";
            case "radio";
            case "compass";
            case "watch": {[1, 1]};
            // A kit of Enhanced First Aid Kits is an item to the rules as well (kind=item reaches it).
            case "kit";
            case "item": {
                switch (true) do {
                    case (_mass <= 10): {[1, 1]};
                    case (_mass <= 30): {[2, 1]};
                    case (_mass <= 60): {[2, 2]};
                    default {[3, 2]};
                };
            };
            default {[1, 1]};
        };
    };

    [(_size select 0) min _storageCols, _size select 1]
};

// The stacks the default ships: aio_stackSize in config, else the number of the @stack_* group the class is in,
// else 1.
private _fnc_oldStack = {
    params ["_config", "_kind", "_size", "_facts"];

    private _stack = switch (true) do {
        case (isNumber (_config >> "aio_stackSize")): {getNumber (_config >> "aio_stackSize")};
        default {
            private _number = 1;
            private _memo = createHashMap;

            {
                if ([_facts, [[false, "@", "=", [format ["stack_%1", _x]]]], _compiled, _memo] call aio_items_fnc_matches) exitWith {
                    _number = _x;
                };
            } forEach [20, 10, 5, 2];

            _number
        };
    };

    if (_kind in ["rifle", "handgun", "launcher", "binocular", "uniform", "vest", "backpack"]) then {
        _stack = 1;
    };

    (floor _stack) max 1
};

// The compartments the default ships: aio_grids[] in config, else aio_slots, else the load.
private _fnc_oldBlocks = {
    params ["_class", "_kind", "_config", "_maxLoad"];

    private _override = getArray (_config >> "aio_grids");

    if (_override isNotEqualTo [] && {_override findIf {!(_x isEqualTypeArray [0, 0])} < 0}) exitWith {
        _override apply {[((floor (_x select 0)) max 1) min _storageCols, ((floor (_x select 1)) max 1) min 40]}
    };

    private _cells = floor (getNumber (_config >> "aio_slots"));
    private _given = _cells > 0;

    // A fifth more than the load for uniforms, vests and backpacks (the built-in answer), as fnc_blocksFor works out a share.
    if (!_given) then {
        _cells = if (_kind in ["uniform", "vest", "backpack"]) then {
            ceil ((_maxLoad max 0) * 120 / 100 / (_cell max 1))
        } else {
            ceil ((_maxLoad max 0) / (_cell max 1))
        };
    };

    if (_cells <= 0) exitWith {[[_storageCols, 0]]};

    _cells = _cells min _maxCells;

    private _fnc_fill = {
        params ["_pattern", "_limit"];

        if (_given) then {_limit = _cells};

        private _blocks = [];
        private _covered = 0;
        private _index = 0;

        while {_covered < _cells && {count _blocks < _limit}} do {
            private _block = +(_pattern select (_index mod count _pattern));
            private _left = _cells - _covered;

            if (_given && {(_block select 0) * (_block select 1) > _left}) then {
                _block = [[1, _left], [_block select 0, _left / (_block select 0)]] select (_left mod (_block select 0) == 0);
            };

            _blocks pushBack _block;
            _covered = _covered + (_block select 0) * (_block select 1);
            _index = _index + 1;
        };

        _blocks
    };

    private _fnc_rows = {
        params ["_cols"];

        if (!_given || {_cells mod _cols == 0}) exitWith {[[_cols, ceil (_cells / _cols)]]};

        [[_cols, floor (_cells / _cols)], [_cells mod _cols, 1]] select {(_x select 1) > 0}
    };

    switch (_kind) do {
        case "uniform": {
            // UNIFORM_COLS 6 wide, UNIFORM_ROWS_MIN 2 to UNIFORM_ROWS_MAX 5 rows high; a number given at most MAX_ROWS 40 rows.
            if (_given) then {
                _cells = _cells min (6 * 40);
                [6] call _fnc_rows
            } else {
                [[6, ((ceil (_cells / 6)) max 2) min 5]]
            }
        };
        case "vest": {
            [[[1, 2], [2, 2]], 20] call _fnc_fill
        };
        case "backpack": {
            [(ceil sqrt _cells) min _storageCols] call _fnc_rows
        };
        default {
            [_storageCols] call _fnc_rows
        };
    }
};

// ----- Every class an inventory can show -----

private _classes = createHashMap;

{
    _x params ["_root", "_condition"];

    {
        _classes set [toLowerANSI (configName _x), configName _x];
    } forEach (_condition configClasses (configFile >> _root));
} forEach [
    ["CfgWeapons", "getNumber (_x >> 'scope') == 2"],
    ["CfgMagazines", "getNumber (_x >> 'scope') == 2"],
    ["CfgGlasses", "getNumber (_x >> 'scope') == 2"],
    ["CfgVehicles", "getNumber (_x >> 'scope') == 2 && {getNumber (_x >> 'isBackpack') == 1 || {getNumber (_x >> 'maximumLoad') > 0}}"]
];

// The default's groups, but medical and the stack groups, which overlap on purpose.
private _groupIds = (_compiled get "groupOrder") - ["medical", "stack_20", "stack_10", "stack_5", "stack_2"];

{
    private _class = _y;
    private _facts = [_class] call aio_items_fnc_getFacts;
    private _info = [_class, _compiled, _cache] call aio_items_fnc_getInfo;
    private _config = configFile >> (_facts get "root") >> _class;
    private _kind = _facts get "kind";
    private _mass = _facts get "mass";

    _counts set ["classes", (_counts get "classes") + 1];

    // The medical list's answer, where one of its rules reaches the class.
    private _medicalInfo = [_class, _medical, _medicalCache] call aio_items_fnc_getInfo;
    private _medicalSize = (((_medicalInfo get "src") get "footprint") select [0, 4]) isEqualTo "own:";
    private _medicalStack = (((_medicalInfo get "src") get "stack") select [0, 4]) isEqualTo "own:";

    // Size
    private _oldSize = [_config, _kind, _mass, _facts get "maxLoad", _facts get "rounds"] call _fnc_oldSize;

    if (_medicalSize) then {
        _oldSize = _medicalInfo get "size";
    };

    if ((_info get "size") isNotEqualTo _oldSize) then {
        ["size", format ["SIZE %1 (%2, mass %3): expected %4, now %5 from %6", _class, _kind, _mass, _oldSize, _info get "size", (_info get "src") get "footprint"]] call _fnc_count;
    };

    // Stack
    private _oldStack = [_config, _kind, _oldSize, _facts] call _fnc_oldStack;

    if (_medicalStack) then {
        _oldStack = _medicalInfo get "stack";
    };

    if ((_info get "stack") != _oldStack) then {
        ["stack", format ["STACK %1 (%2, mass %3, size %4): expected %5, now %6 from %7", _class, _kind, _mass, _oldSize, _oldStack, _info get "stack", (_info get "src") get "stack"]] call _fnc_count;
    };

    // Compartments
    if (_kind in ["uniform", "vest", "backpack", "crate", "vehicle"]) then {
        private _blockKind = [_kind, "crate"] select (_kind in ["crate", "vehicle"]);
        // The old compartments in the shape fnc_blocksFor gives now: [cols, rows, holes, pos], none of them
        // shaped or placed.
        private _oldBlocks = ([_class, _blockKind, _config, _facts get "maxLoad"] call _fnc_oldBlocks) apply {[_x select 0, _x select 1, [], []]};
        private _newBlocks = [_class, _blockKind, _facts get "maxLoad", _info get "grid", _cell] call aio_storage_fnc_blocksFor;

        if (_oldBlocks isNotEqualTo _newBlocks) then {
            // Past the new limits, the old compartments could not come out the same.
            private _total = 0;

            {
                _total = _total + (_x select 0) * (_x select 1);
            } forEach _oldBlocks;

            private _capped = count _oldBlocks > 24 || {_total > _maxCells};

            [["blocks", "caps"] select _capped, format ["BLOCKS%1 %2 (%3, load %4): expected %5, now %6 from %7", ["", " (caps)"] select _capped, _class, _kind, _facts get "maxLoad", _oldBlocks, _newBlocks, (_info get "src") get "grid"]] call _fnc_count;
        };
    };

    // Partition
    private _memo = createHashMap;
    private _in = _groupIds select {[_facts, [[false, "@", "=", [_x]]], _compiled, _memo] call aio_items_fnc_matches};

    if (count _in > 1) then {
        ["overlap", format ["OVERLAP %1 (%2, mass %3, rounds %4) is in %5", _class, _kind, _mass, _facts get "rounds", _in]] call _fnc_count;
    };
} forEach _classes;

// ----- The stacks for play (issue #21) -----

// A few classes of each stack the medical list gives, named here and not derived from its rules (the loop above can only
// compare the rules with themselves). A class of a mod that is not loaded is skipped.
{
    _x params ["_stackWanted", "_stackNames"];

    {
        if (isClass (configFile >> "CfgWeapons" >> _x) || {isClass (configFile >> "CfgMagazines" >> _x)}) then {
            private _got = ([_x, _compiled, _cache] call aio_items_fnc_getInfo) get "stack";

            if (_got != _stackWanted) then {
                ["stack", format ["STACK %1: the stacks for play say %2, now %3", _x, _stackWanted, _got]] call _fnc_count;
            };
        };
    } forEach _stackNames;
} forEach [
    [1, ["ACM_Stethoscope", "ACE_suture", "ACM_PocketBVM", "ACM_BloodBag_O_NEG"]],
    [4, ["ACE_tourniquet", "ACE_morphine", "ACE_epinephrine", "ACM_SAMSplint"]],
    [5, [
        "ACE_fieldDressing", "ACE_elasticBandage", "ACE_packingBandage", "ACE_quikclot", "ACM_PressureBandage", "ACM_ElasticWrap",
        "ACM_CombatGauze", "ACM_EmergencyTraumaDressing", "ACM_ChestSeal", "ACM_IV_16g", "ACM_IO_EZ", "ACM_Syringe_10",
        "ACM_Vial_Morphine", "ACME_MannitolVial"
    ]],
    [10, ["ACM_Lozenge_Fentanyl", "ACME_IVLine", "ACME_YTubing"]]
];

// aio_storage_fnc_stackFor: a crate multiplies a class that stacks (FirstAidKit stacks 5 in the default), a worn container,
// a kit and a class that does not stack (a rifle, a magazine) are not multiplied, and 1 turns it off. The setting is put
// back afterwards.
private _stackSaved = missionNamespace getVariable ["aio_storage_stackMultiplier", 1];
private _crate = createVehicle ["Box_NATO_Ammo_F", [0, 0, 0], [], 0, "CAN_COLLIDE"];
private _worn = [vestContainer player, backpackContainer player, uniformContainer player] select {!isNull _x};

{
    _x params ["_multiplier", "_holder", "_class", "_wantedStack"];

    missionNamespace setVariable ["aio_storage_stackMultiplier", _multiplier];

    private _gotStack = [_holder, _class] call aio_storage_fnc_stackFor;

    if (_gotStack != _wantedStack) then {
        ["stack", format ["STACKFOR x%1 %2 in %3: expected %4, now %5", _multiplier, _class, str _holder, _wantedStack, _gotStack]] call _fnc_count;
    };
} forEach ([
    [5, _crate, "FirstAidKit", 25],
    [1, _crate, "FirstAidKit", 5],
    [5, _crate, "arifle_MX_F", 1],
    [5, _crate, "30Rnd_65x39_caseless_mag", 1],
    [5, "kit:efak_ifak_1", "FirstAidKit", 5],
    [5, objNull, "FirstAidKit", 5]
] + (_worn apply {[5, _x, "FirstAidKit", 5]}));

missionNamespace setVariable ["aio_storage_stackMultiplier", _stackSaved];
deleteVehicle _crate;

// ----- Texts read and written again stay the same -----

{
    private _first = [[_x] call aio_items_fnc_parseRules] call aio_items_fnc_writeRules;
    private _second = [[_first] call aio_items_fnc_parseRules] call aio_items_fnc_writeRules;

    if (_first isNotEqualTo _second) then {
        ["roundTrip", format ["ROUND TRIP %1 -> %2 -> %3", _x, _first, _second]] call _fnc_count;
    };
} forEach [
    "",
    "aio1 base=default",
    "aio1 base=default cell=4, @ak: kind=magazine class~545x39|762x39, @ak > size=1x2, class=ACE_fieldDressing+|ACE_packingBandage+ > stack=20",
    "kind=grenade > stack=3 weight=0.4 name=Frag_%28M67%29, kind=vest class~platecarrier > grid=plate:20, kind=backpack load>280 > grid=120%",
    "aio1 base=none, @mag_rifle: @mag_rifle, @mag_rifle: class=30Rnd_65x39_caseless_green+, !addon~ace_ cat=medical > stack=1, class=B_Carryall_Base+ > grid=6x5+2x3+2x3, size=mass",
    "for=arifle_MX_F > size=1x2, well=CBA_556x45_STANAG > size=1x2, rounds>=100 mass>20 > size=2x3 grid=auto",
    "class=My_Rifle_L > size=xxxx/x---, class=My_Launcher > size=-x-/xxx/---, class=My_Box > shape=xx/xx",
    "class=My_Pack > grid=abbbbbc/abbbbbc/abbbbbc/-bbbbb-/-bbbbb-/-bbbbb-/-bbbbb-, class=My_Ring > grid=2x3+aaa/aba/aaa+1x1, class=My_Row > grid=aaabb",
    "aio1 base=none, all > size=1x1 stack=10, kind=uniform|vest|backpack all > grid=6x4",
    "class=My_Kit > icon=1.4, class=My_Bandage+ > icon=1.4@0.1:-0.05 stack=3, kind=grenade > icon=0.5@-0.2:0.2, class=My_Plain > icon=1",
    "class=My_Kit > icon=1.4@0.1,-0.05, stack=3",
    "class=My_Kit > icon=1.4 picture=/A3/Weapons_F/Data/UI/gear_acc_rail_ca.paa, class=My_Mag > picture=/my_mod/ui/kit%201_ca.paa",
    "category=bandit > name=Bandit_loot picture=/a3/ui_f/data/gui/cfg/hints/gear_ca.paa, category=weapon > name=Arms, category=zeta, class=My_Pack > cats=zeta+bandit+medical grid=2x2:bandit|medical+1x1:zeta:one"
] +((getArray (configFile >> "CfgAioRulesets" >> "default" >> "rules")) apply {"aio1 base=none, " + _x});

{
    private _back = [[_x] call aio_items_fnc_encodeName] call aio_items_fnc_decodeName;

    if (_back isNotEqualTo _x) then {
        ["roundTrip", format ["NAME %1 -> %2 -> %3", _x, [_x] call aio_items_fnc_encodeName, _back]] call _fnc_count;
    };
} forEach ["Field kit", "Frag (M67), 3 pieces", "Verbandpäckchen", "a_b-c.d 100%", "Gerät; ""quoted"""];

// An icon reads as it is written, a comma typed into a text as the colon, a limit cuts it down, and an offset
// alone (no second number) is no icon.
{
    _x params ["_text", "_want"];

    private _rules = ([_text] call aio_items_fnc_parseRules) get "rules";
    private _got = if (_rules isEqualTo []) then {[]} else {((_rules select 0) select 1) getOrDefault ["icon", []]};

    if (_got isNotEqualTo _want) then {
        ["roundTrip", format ["ICON %1 -> %2, wanted %3", _text, _got, _want]] call _fnc_count;
    };
} forEach [
    ["icon=1.4", [1.4, 0, 0]],
    ["icon=1.4@0.1:-0.05", [1.4, 0.1, -0.05]],
    ["kind=grenade > icon=1.4@0.1,-0.05", [1.4, 0.1, -0.05]],
    ["icon=9@2:-3", [4, 1, -1]],
    ["icon=1.4@0.1", []]
];

// A picture reads as the engine writes a path: slashes either way, a space as %20, an underscore as it is; a text
// that is no texture path is left out.
{
    _x params ["_text", "_want"];

    private _rules = ([_text] call aio_items_fnc_parseRules) get "rules";
    private _got = if (_rules isEqualTo []) then {""} else {((_rules select 0) select 1) getOrDefault ["picture", ""]};

    if (_got isNotEqualTo _want) then {
        ["roundTrip", format ["PICTURE %1 -> %2, wanted %3", _text, _got, _want]] call _fnc_count;
    };
} forEach [
    ["picture=/A3/Weapons_F/Data/UI/gear_acc_rail_ca.paa", "\A3\Weapons_F\Data\UI\gear_acc_rail_ca.paa"],
    ["class=My_Kit > picture=a3/ui_f/data/gui/cfg/hints/gear_ca.paa", "a3\ui_f\data\gui\cfg\hints\gear_ca.paa"],
    ["picture=my_mod/ui/kit%201_ca.paa", "my_mod\ui\kit 1_ca.paa"],
    ["picture=my_mod/ui/nofile", ""]
];

// Categories of the setup's own: the eight come first, then the text's in the order it defines them, a statement of the same id
// adds to the first, a word cats= would read as a built-in one (tools) and a built-in id with nothing to change are left out, and a
// category named but never defined is a warning.
private _categoryText = "category=bandit > name=Bandit_loot, category=tools > name=X, category=medical, category=weapon > name=Arms, category=bandit > picture=/my_mod/ui/bandit_ca.paa, class=My_Item > cats=bandit+ghost";
private _categoryRules = [_categoryText, false] call aio_items_fnc_compileRules;
private _wantIds = ["weapon", "ammo", "grenade", "gear", "medical", "food", "tool", "misc", "bandit"];
private _banditDef = (_categoryRules get "categoryDefs") getOrDefault ["bandit", []];
private _weaponDef = (_categoryRules get "categoryDefs") getOrDefault ["weapon", []];

if ((_categoryRules get "categoryIds") isNotEqualTo _wantIds) then {
    ["roundTrip", format ["CATEGORIES ids %1, wanted %2", _categoryRules get "categoryIds", _wantIds]] call _fnc_count;
};

if (_banditDef isNotEqualTo ["Bandit loot", "\my_mod\ui\bandit_ca.paa"] || {_weaponDef isNotEqualTo ["Arms", ""]}) then {
    ["roundTrip", format ["CATEGORIES bandit %1, weapon %2", _banditDef, _weaponDef]] call _fnc_count;
};

// tools and medical are left out, ghost is named but not defined: three warnings.
if (count ((_categoryRules get "warnings") select {(_x find "tools") >= 0 || {(_x find "category=medical") >= 0} || {(_x find "ghost") >= 0}}) != 3) then {
    ["roundTrip", format ["CATEGORIES warnings %1", _categoryRules get "warnings"]] call _fnc_count;
};

// A text that names a preset that is gone still loads, on the default.
{
    private _renamed = (["aio1 base=" + _x] call aio_items_fnc_parseRules) get "base";

    if (_renamed isNotEqualTo "default") then {
        ["roundTrip", format ["ALIAS base=%1 reads as base=%2, not default", _x, _renamed]] call _fnc_count;
    };
} forEach ["tarkov", "realism", "weight"];

// ----- Report -----

private _summary = format [
    "Default ruleset: %1 classes - %2 size and %3 stack differences, %4 (not used), %5 compartment differences, %6 from the caps, %7 overlapping groups, %8 round trips that changed. Warnings while compiling: %9.",
    _counts get "classes", _counts get "size", _counts get "stack", _counts get "stackSmall", _counts get "blocks",
    _counts get "caps", _counts get "overlap", _counts get "roundTrip", count (_compiled get "warnings")
];

{
    _report pushBack ("WARNING " + _x);
} forEach (_compiled get "warnings");

diag_log text "----- Arma Inventory Overhaul: default ruleset check -----";

{
    diag_log text _x;
} forEach _report;

diag_log text _summary;
copyToClipboard ((_report + [_summary]) joinString endl);
hint _summary;
systemChat _summary;
