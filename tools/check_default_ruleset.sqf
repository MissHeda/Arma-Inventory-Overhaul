/*
 * Author: Miss Heda
 * Checks that the shipped default ruleset (CfgEinvRulesets >> default) gives every item the size and
 * stack, and every container the compartments, that the code before the rules gave them - with
 * nothing set in the older tables and both sliders on their defaults - but for what 0.4.0 changed on
 * purpose, which the "before" below does too: grids STORAGE_COLS (10) wide instead of 8, at most
 * 400 cells instead of 320, and uniforms, vests and backpacks laid out from 120 % of their load
 * (default's grid=120%, a fifth more room) instead of all of it. Also checks that the default's
 * groups are a partition (an item in two of them would let a rule for one reach into the other; only
 * medical overlaps on purpose), that texts read and written stay the same, and that names survive
 * being written into a rule.
 *
 * Not part of the mod. Copy it into a mission's folder - the test mission in .hemtt/missions will do -
 * start the mission with the mods to check (vanilla, ACE, a large pack), and run in the debug console:
 *
 *     [] execVM "check_default_ruleset.sqf"
 *
 * It takes a few seconds with large packs. The summary shows as a hint, every finding goes to the RPT
 * and, with the summary, to the clipboard.
 *
 * Expected: no size, compartment or round-trip differences and no overlaps. Stack differences are
 * expected only in the "stackSmall" case: before, items of a single cell stacked by ten; now items of
 * kind item that weigh 10 or less do (@item_small). The two only differ for an item whose own mod
 * gives it another size than the rules would (einv_gridSize[]) without a stack of its own
 * (einv_stackSize). Compartment differences marked "caps" come from the new limits on what a mod's
 * einv_grids[] may ask for (24 compartments, 400 cells). Also checked: a text from before the preset
 * was renamed (base=tarkov) builds on realism, and canvases (grid=aaa/aba/aaa) read and write the same,
 * as does everything else (all > ..., "all" written first wherever it was typed).
 */

private _compiled = ["einv1 base=default", false] call einv_items_fnc_compileRules;
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

// fnc_getSize: einv_gridSize[] in config, else by kind and mass.
private _fnc_oldSize = {
    params ["_config", "_kind", "_mass", "_maxLoad", "_count"];

    private _size = getArray (_config >> "einv_gridSize");

    if (_size isEqualTypeArray [0, 0] && {(_size select 0) >= 1} && {(_size select 1) >= 1}) then {
        _size = _size apply {floor _x};
    } else {
        _size = switch (_kind) do {
            case "rifle": {
                switch (true) do {
                    case (_mass <= 55): {[3, 2]};
                    case (_mass <= 90): {[4, 2]};
                    case (_mass <= 150): {[5, 2]};
                    default {[6, 2]};
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
                    case (_maxLoad <= 160): {[3, 3]};
                    case (_maxLoad <= 280): {[4, 4]};
                    default {[4, 5]};
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

// fnc_getInfo's stacks: einv_stackSize in config, grenades 5, single-cell items einv_items_stackSmall.
private _fnc_oldStack = {
    params ["_config", "_kind", "_size"];

    private _stack = switch (true) do {
        case (isNumber (_config >> "einv_stackSize")): {getNumber (_config >> "einv_stackSize")};
        case (_kind == "grenade"): {5};
        case (_kind in ["item", "kit"] && {_size isEqualTo [1, 1]}): {10};
        default {1};
    };

    if (_kind in ["rifle", "handgun", "launcher", "binocular", "uniform", "vest", "backpack"]) then {
        _stack = 1;
    };

    (floor _stack) max 1
};

// fnc_getBlocks: einv_grids[] in config, else einv_slots, else the load.
private _fnc_oldBlocks = {
    params ["_class", "_kind", "_config", "_maxLoad"];

    private _override = getArray (_config >> "einv_grids");

    if (_override isNotEqualTo [] && {_override findIf {!(_x isEqualTypeArray [0, 0])} < 0}) exitWith {
        _override apply {[((floor (_x select 0)) max 1) min _storageCols, ((floor (_x select 1)) max 1) min 40]}
    };

    private _cells = floor (getNumber (_config >> "einv_slots"));
    private _given = _cells > 0;

    // Default's grid=120% for uniforms, vests and backpacks, as fnc_blocksFor works out a share.
    if (!_given) then {
        _cells = if (_kind in ["uniform", "vest", "backpack"]) then {
            ceil ((_maxLoad max 0) * 120 / 100 / (_cell max 1))
        } else {
            ceil ((_maxLoad max 0) / (_cell max 1))
        };
    };

    if (_cells <= 0) exitWith {[[_storageCols, 0]]};

    _cells = _cells min _maxCells;

    private _hash = 0;
    {_hash = _hash + _x} forEach toArray toLowerANSI _class;

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
            [[[[1, 2]], [[1, 1], [1, 2]]] select (_hash mod 2), 6] call _fnc_fill
        };
        case "vest": {
            [[
                [[1, 2]],
                [[1, 2], [1, 2], [1, 1], [1, 1]],
                [[2, 2], [1, 2], [1, 2]],
                [[1, 3], [1, 2], [1, 1]]
            ] select (_hash mod 4), 16] call _fnc_fill
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

// The default's groups, but medical, which overlaps on purpose.
private _groupIds = (_compiled get "groupOrder") - ["medical"];

{
    private _class = _y;
    private _facts = [_class] call einv_items_fnc_getFacts;
    private _info = [_class, _compiled, _cache] call einv_items_fnc_getInfo;
    private _config = configFile >> (_facts get "root") >> _class;
    private _kind = _facts get "kind";
    private _mass = _facts get "mass";

    _counts set ["classes", (_counts get "classes") + 1];

    // Size
    private _oldSize = [_config, _kind, _mass, _facts get "maxLoad", _facts get "rounds"] call _fnc_oldSize;

    if ((_info get "size") isNotEqualTo _oldSize) then {
        ["size", format ["SIZE %1 (%2, mass %3): before %4, now %5 from %6", _class, _kind, _mass, _oldSize, _info get "size", (_info get "src") get "footprint"]] call _fnc_count;
    };

    // Stack
    private _oldStack = [_config, _kind, _oldSize] call _fnc_oldStack;

    if ((_info get "stack") != _oldStack) then {
        private _smallCase = _kind in ["item", "kit"] && {(_mass <= 10) isNotEqualTo (_oldSize isEqualTo [1, 1])};

        [["stack", "stackSmall"] select _smallCase, format ["STACK%1 %2 (%3, mass %4, size %5): before %6, now %7 from %8", ["", " (stackSmall)"] select _smallCase, _class, _kind, _mass, _oldSize, _oldStack, _info get "stack", (_info get "src") get "stack"]] call _fnc_count;
    };

    // Compartments
    if (_kind in ["uniform", "vest", "backpack", "crate", "vehicle"]) then {
        private _blockKind = [_kind, "crate"] select (_kind in ["crate", "vehicle"]);
        // The old compartments in the shape fnc_blocksFor gives now: [cols, rows, holes, pos], none of them
        // shaped or placed.
        private _oldBlocks = ([_class, _blockKind, _config, _facts get "maxLoad"] call _fnc_oldBlocks) apply {[_x select 0, _x select 1, [], []]};
        private _newBlocks = [_class, _blockKind, _facts get "maxLoad", _info get "grid", _cell] call einv_storage_fnc_blocksFor;

        if (_oldBlocks isNotEqualTo _newBlocks) then {
            // Past the new limits, the old compartments could not come out the same.
            private _total = 0;

            {
                _total = _total + (_x select 0) * (_x select 1);
            } forEach _oldBlocks;

            private _capped = count _oldBlocks > 24 || {_total > _maxCells};

            [["blocks", "caps"] select _capped, format ["BLOCKS%1 %2 (%3, load %4): before %5, now %6 from %7", ["", " (caps)"] select _capped, _class, _kind, _facts get "maxLoad", _oldBlocks, _newBlocks, (_info get "src") get "grid"]] call _fnc_count;
        };
    };

    // Partition
    private _memo = createHashMap;
    private _in = _groupIds select {[_facts, [[false, "@", "=", [_x]]], _compiled, _memo] call einv_items_fnc_matches};

    if (count _in > 1) then {
        ["overlap", format ["OVERLAP %1 (%2, mass %3, rounds %4) is in %5", _class, _kind, _mass, _facts get "rounds", _in]] call _fnc_count;
    };
} forEach _classes;

// ----- Texts read and written again stay the same -----

{
    private _first = [[_x] call einv_items_fnc_parseRules] call einv_items_fnc_writeRules;
    private _second = [[_first] call einv_items_fnc_parseRules] call einv_items_fnc_writeRules;

    if (_first isNotEqualTo _second) then {
        ["roundTrip", format ["ROUND TRIP %1 -> %2 -> %3", _x, _first, _second]] call _fnc_count;
    };
} forEach [
    "",
    "einv1 base=default",
    "einv1 base=realism cell=4, @ak: kind=magazine class~545x39|762x39, @ak > size=1x2, class=ACE_fieldDressing+|ACE_packingBandage+ > stack=20",
    "kind=grenade > stack=3 weight=0.4 name=Frag_%28M67%29, kind=vest class~platecarrier > grid=plate:20, kind=backpack load>280 > grid=120%",
    "einv1 base=none, @mag_rifle: @mag_rifle, @mag_rifle: class=30Rnd_65x39_caseless_green+, !addon~ace_ cat=medical > stack=1, class=B_Carryall_Base+ > grid=6x5+2x3+2x3, size=mass",
    "for=arifle_MX_F > size=1x2, well=CBA_556x45_STANAG > size=1x2, rounds>=100 mass>20 > size=2x3 grid=auto",
    "class=My_Rifle_L > size=xxxx/x---, class=My_Launcher > size=-x-/xxx/---, class=My_Box > shape=xx/xx",
    "class=My_Pack > grid=abbbbbc/abbbbbc/abbbbbc/-bbbbb-/-bbbbb-/-bbbbb-/-bbbbb-, class=My_Ring > grid=2x3+aaa/aba/aaa+1x1, class=My_Row > grid=aaabb",
    "einv1 base=none, all > size=1x1 stack=10, kind=uniform|vest|backpack all > grid=6x4",
    "class=My_Kit > icon=1.4, class=My_Bandage+ > icon=1.4@0.1:-0.05 stack=3, kind=grenade > icon=0.5@-0.2:0.2, class=My_Plain > icon=1",
    "class=My_Kit > icon=1.4@0.1,-0.05, stack=3"
] +((getArray (configFile >> "CfgEinvRulesets" >> "default" >> "rules")) apply {"einv1 base=none, " + _x});

{
    private _back = [[_x] call einv_items_fnc_encodeName] call einv_items_fnc_decodeName;

    if (_back isNotEqualTo _x) then {
        ["roundTrip", format ["NAME %1 -> %2 -> %3", _x, [_x] call einv_items_fnc_encodeName, _back]] call _fnc_count;
    };
} forEach ["Field kit", "Frag (M67), 3 pieces", "Verbandpäckchen", "a_b-c.d 100%", "Gerät; ""quoted"""];

// An icon reads as it is written, a comma typed into a text as the colon, a limit cuts it down, and an offset
// alone (no second number) is no icon.
{
    _x params ["_text", "_want"];

    private _rules = ([_text] call einv_items_fnc_parseRules) get "rules";
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

// A text from before the rename still loads, on the new preset.
private _renamed = (["einv1 base=tarkov"] call einv_items_fnc_parseRules) get "base";

if (_renamed isNotEqualTo "realism") then {
    ["roundTrip", format ["ALIAS base=tarkov reads as base=%1, not realism", _renamed]] call _fnc_count;
};

// ----- Report -----

private _summary = format [
    "Default ruleset: %1 classes - %2 size and %3 stack differences, %4 stackSmall (expected), %5 compartment differences, %6 from the new caps, %7 overlapping groups, %8 round trips that changed. Warnings while compiling: %9.",
    _counts get "classes", _counts get "size", _counts get "stack", _counts get "stackSmall", _counts get "blocks",
    _counts get "caps", _counts get "overlap", _counts get "roundTrip", count (_compiled get "warnings")
];

{
    _report pushBack ("WARNING " + _x);
} forEach (_compiled get "warnings");

diag_log text "----- Enhanced Inventory: default ruleset check -----";

{
    diag_log text _x;
} forEach _report;

diag_log text _summary;
copyToClipboard ((_report + [_summary]) joinString endl);
hint _summary;
systemChat _summary;
