#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Turns a rules text into what fnc_resolve asks fast, together with everything it builds on. Never
 * fails: what cannot be used is left out and named in the warnings, an unknown preset falls back to
 * "default", an empty text is the default. The result is plain data - no code - since it is kept in
 * the mission namespace and so in save games.
 *
 * 1. The text (fnc_parseRules) is the own layer - but for its rules with "all", everything else, which
 *    are a layer of their own (fallback): asked after the preset - before the preset's rules without
 *    conditions, its own everything else - and before the built-in answer (fnc_resolve). A preset's rule
 *    with "all" is left out with a warning: its rules without conditions already are its everything else.
 * 2. Its base= and the bases of that preset (CfgEinvRulesets, MAX_CHAIN deep, no loops) are the
 *    preset layer, the base first and each derived preset after it. Read presets are kept in
 *    uiNamespace: config does not change.
 * 3. Groups: a later preset's or the text's definition of a name replaces the earlier one; the same
 *    name twice in one of them means either. Inside a definition, @its own name means the definition
 *    it replaces - so "@mag_rifle: @mag_rifle" plus "@mag_rifle: class=X+" adds X to the preset's
 *    group. A definition nothing of which holds up - it refers to a group that does not exist, to
 *    itself through others, or more than MAX_GROUP_DEPTH groups deep - is left out like a statement
 *    that cannot be read: the definition below it counts again, so a typo in the text's @mag_rifle
 *    leaves the preset's @mag_rifle in effect. With none below, the group does not exist - and a rule
 *    using it is left out, rather than "not in that group" reaching every item.
 * 4. The older tables (einv_items_sizeTable, einv_items_stackTable, einv_storage_containerTable) are
 *    read as rules of the own layer after the text, class=X+ each, the classes built on fewer others
 *    first - so the nearest class listed wins, as it did. einv_items_stackSmall, when moved off its
 *    default, is the preset layer's last word on @item_small: a rule or a mod still beats it, as they
 *    did.
 * 5. Rules are sorted by the kinds they can be about, so an item meets only those (byKind).
 * 6. The mass per grid cell: the text's cell=, else the nearest preset that sets one, else the slider
 *    einv_items_massPerCell.
 *
 * Arguments:
 * 0: Rules text <STRING>
 * 1: Read the older tables and einv_items_stackSmall too, as the rules in effect do <BOOL>
 *    (default: true)
 *
 * Return Value:
 * Compiled rules <HASHMAP>
 *   "text"        - the own text as fnc_writeRules writes it <STRING>
 *   "ast"         - the own text's parts (fnc_parseRules) <HASHMAP>
 *   "base"        - the preset it builds on in the end, "none" for none <STRING>
 *   "chain"       - the presets read, the base first <ARRAY>
 *   "cell"        - config mass per grid cell <NUMBER>
 *   "categoryIds" - every category there is: the eight built-in ones (ITEM_GROUPS), then the text's own in the order it
 *                   defines them (fnc_categories) <ARRAY of STRING>
 *   "categoryDefs" - id -> [name, picture] the text gives it, "" for what it does not set (fnc_categoryInfo) <HASHMAP>
 *   "groups"      - group key -> its definitions, each a list of compiled conditions; the key of the
 *                   definition in effect is the group's name, replaced ones are "name#layer" <HASHMAP>
 *   "groupKeys"   - name -> key of the definition in effect <HASHMAP>
 *   "groupSource" - name -> "own" or "preset:<preset>", where it is defined in the end <HASHMAP>
 *   "groupOrder"  - names in the order they first appear, the presets' first <ARRAY>
 *   "own"         - [[conditions, values, tag, text, kinds], ...]: the text's rules in text order, then
 *                   the tables'; tag "own:<i>" or "legacy:<setting>:<i>", kinds -1 for any <ARRAY>
 *   "preset"      - the same for the presets, tag "preset:<preset>:<i>" <ARRAY>
 *   "fallback"    - the same for the text's rules with "all", in text order, tag "all:<i>" (the i-th
 *                   rule of the text, counted as for "own:<i>") <ARRAY>
 *   "byKind"      - kind -> [own indices, preset indices (both highest first), fields own rules can
 *                   set, fields preset rules can set, fallback indices (highest first), fields
 *                   fallback rules can set] <HASHMAP>
 *   "hash"        - one value for all of it, to compare between machines <STRING>
 *   "warnings"    - everything left out or cut down <ARRAY of STRING>
 * A rule's values: "like" the class in lowercase <STRING>, "footprint" [w, h, holes] or "mass", "stack"
 * <NUMBER>, "grid" spec (fnc_parseGrid), "weight" kg <NUMBER>, "name" <STRING>, "icon" [scale, across,
 * down] (fnc_parseIcon), "picture" <STRING> (fnc_parsePicture), "use" [containers] (fnc_parseUse), "cats" [categories] (fnc_parseGroups). A rule with like=
 * counts in byKind as setting every one of LIKE_FIELDS, which fnc_resolve takes from that class.
 *
 * Example:
 * ["einv1 base=default, kind=grenade > stack=3"] call einv_items_fnc_compileRules;
 *
 * Public: Yes
 */

params [["_text", "", [""]], ["_legacy", true, [false]]];

private _warnings = [];
private _ast = [_text] call FUNC(parseRules);

_warnings append (_ast get "warnings");

// ----- The categories -----
// The eight built-in ones, then those the text defines (category=...). Only the text defines any: a preset has no say in them.
private _categoryIds = ITEM_GROUPS;
private _categoryDefs = createHashMap;

{
    _x params ["_categoryId", "_categoryName", "_categoryPicture", ["_categoryColor", ""]];

    _categoryDefs set [_categoryId, [_categoryName, _categoryPicture, _categoryColor]];
    _categoryIds pushBackUnique _categoryId;
} forEach (_ast getOrDefault ["categories", []]);

// ----- The preset chain -----

private _rulesets = configFile >> "CfgEinvRulesets";
private _base = _ast get "base";

if (_base isNotEqualTo "none" && {!isClass (_rulesets >> _base)}) then {
    _warnings pushBack format ["There is no preset '%1' - built on 'default' instead.", _base];
    _base = "default";
};

private _chain = [];
private _next = _base;

while {_next isNotEqualTo "" && {_next isNotEqualTo "none"}} do {
    if (_next in _chain) exitWith {
        _warnings pushBack format ["Preset '%1' builds on itself through others - read without that.", _next];
    };

    if (count _chain >= MAX_CHAIN) exitWith {
        _warnings pushBack format ["Presets build on each other more than %1 deep - '%2' and below are left out.", MAX_CHAIN, _next];
    };

    if (!isClass (_rulesets >> _next)) exitWith {
        _warnings pushBack format ["A preset builds on '%1', which does not exist - left out.", _next];
    };

    _chain pushBack _next;
    _next = toLowerANSI (getText (_rulesets >> _next >> "base"));

    // Another mod's preset may still build on a preset under its old id - unless a preset of that very name
    // exists: a third party's own is not shadowed by the alias.
    private _alias = PRESET_ALIASES findIf {(_x select 0) isEqualTo _next && {!isClass (_rulesets >> _next)}};

    if (_alias >= 0) then {
        _next = (PRESET_ALIASES select _alias) select 1;
    };
};

// Read as derived first; the base goes first.
reverse _chain;

private _presetCache = uiNamespace getVariable QGVAR(presetCache);

if (isNil "_presetCache") then {
    _presetCache = createHashMap;
    uiNamespace setVariable [QGVAR(presetCache), _presetCache];
};

// Layers, lowest first: [name, parts]. The presets, then the text.
private _layers = [];

{
    private _preset = _x;
    private _presetAst = _presetCache get _preset;

    if (isNil "_presetAst") then {
        private _statements = (getArray (_rulesets >> _preset >> "rules")) select {_x isEqualType ""};

        _presetAst = [(["einv1 base=none"] + _statements) joinString ", "] call FUNC(parseRules);
        _presetCache set [_preset, _presetAst];
    };

    {
        _warnings pushBack format ["Preset %1: %2", _preset, _x];
    } forEach (_presetAst get "warnings");

    _layers pushBack [_preset, _presetAst];
} forEach _chain;

_layers pushBack ["own", _ast];

// ----- Mass per cell -----

private _cell = _ast get "cell";

if (_cell <= 0) then {
    private _derivedFirst = +_chain;
    reverse _derivedFirst;

    {
        private _presetCell = getNumber (_rulesets >> _x >> "cell");

        if (_presetCell > 0) exitWith {
            _cell = _presetCell;
        };
    } forEach _derivedFirst;
};

if (_cell <= 0) then {
    _cell = missionNamespace getVariable [QGVAR(massPerCell), DEFAULT_MASS_PER_CELL];
};

_cell = (_cell max CELL_MIN) min CELL_MAX;

// Conditions cheapest first, by the cost fnc_compileCond gives them (the fifth element). Sorted by
// cost and place only - the conditions themselves hold booleans, which sort cannot compare.
private _fnc_sortConds = {
    params ["_conds"];

    private _place = -1;
    private _sorted = _conds apply {
        _place = _place + 1;
        [_x select 4, _place, _x]
    };

    _sorted sort true;

    _sorted apply {_x select 2}
};

// One statement as the writer has it - for warnings, "Why?" and the hash.
private _fnc_groupText = {
    params ["_id", "_conds"];

    [createHashMapFromArray [["groups", [[_id, _conds]]]], false] call FUNC(writeRules)
};

private _fnc_ruleText = {
    params ["_conds", "_values"];

    [createHashMapFromArray [["rules", [[_conds, _values]]]], false] call FUNC(writeRules)
};

// ----- Groups -----

private _definitions = createHashMap; // "name#layer" -> [conditions as read, ...]
private _top = createHashMap;         // name -> "name#layer" of the definition in effect
private _groupOrder = [];

{
    _x params ["_layerName", "_layerAst"];

    private _layer = _forEachIndex;

    {
        _x params ["_id", "_conds"];

        private _groupKey = format ["%1#%2", _id, _layer];

        if !(_groupKey in _definitions) then {
            _definitions set [_groupKey, []];
        };

        (_definitions get _groupKey) pushBack _conds;
        _top set [_id, _groupKey];
        _groupOrder pushBackUnique _id;
    } forEach (_layerAst get "groups");
} forEach _layers;

// The definition of the same name nearest below a group key, "" for none.
private _fnc_below = {
    params ["_groupKey"];

    private _parts = _groupKey splitString "#";
    private _id = _parts select 0;
    private _below = "";

    for "_lower" from ((parseNumber (_parts select 1)) - 1) to 0 step -1 do {
        if (format ["%1#%2", _id, _lower] in _definitions) exitWith {
            _below = format ["%1#%2", _id, _lower];
        };
    };

    _below
};

// Where a group key's definition is, for a warning.
private _fnc_layerName = {
    params ["_groupKey"];

    private _layer = parseNumber ((_groupKey splitString "#") select 1);

    [format ["preset %1", (_layers select _layer) select 0], "your text"] select (_layer == count _layers - 1)
};

// Which group keys hold up: each definition only refers to groups that hold up themselves, with no
// loop and at most MAX_GROUP_DEPTH deep. Depth of a key that holds up, 0 for one that does not.
private _groups = createHashMap;
private _status = createHashMap;
private _roundWarnings = []; // [group key, warning], of the last round only

private _fnc_check = {
    params ["_groupKey"];

    private _known = _status get _groupKey;

    // -1: being looked at - a loop, which does not hold up.
    if (!isNil "_known") exitWith {_known max 0};

    _status set [_groupKey, -1];

    private _kept = [];
    private _depth = 0;

    {
        private _alternative = _x;
        private _deepest = 0;
        private _holds = true;

        {
            if ((_x select 1) isEqualTo "@") then {
                {
                    private _inner = [_x] call _fnc_check;

                    if (_inner <= 0) exitWith {
                        _holds = false;
                    };

                    _deepest = _deepest max _inner;
                } forEach (_x select 3);
            };
        } forEach _alternative;

        if (_holds && {_deepest < MAX_GROUP_DEPTH}) then {
            _kept pushBack _alternative;
            _depth = _depth max (_deepest + 1);
        } else {
            _roundWarnings pushBack [_groupKey, format ["Group @%1: a definition uses a group that does not exist, itself, or groups more than %2 deep - left out.", (_groupKey splitString "#") select 0, MAX_GROUP_DEPTH]];
        };
    } forEach (_groups getOrDefault [_groupKey, []]);

    _groups set [_groupKey, _kept];

    private _result = [0, _depth] select (_kept isNotEqualTo []);

    _status set [_groupKey, _result];

    _result
};

// Each definition's conditions compiled, and checked. A definition nothing of which holds up counts
// as left out, like a statement that cannot be read: the one below it - the preset's, or the base
// preset's - is in effect again, and all of them are compiled once more with that. Each round leaves
// out at least one definition or is the last, so it ends.
private _settled = false;

while {!_settled} do {
    _groups = createHashMap;
    _status = createHashMap;
    _roundWarnings = [];

    // Inside a definition, the group's own name stands for the definition it replaces - the nearest
    // one below - or for nothing.
    {
        private _groupKey = _x;
        private _id = (_groupKey splitString "#") select 0;
        private _below = [_groupKey] call _fnc_below;
        private _keys = +_top;

        if (_below isEqualTo "") then {
            _keys deleteAt _id;
        } else {
            _keys set [_id, _below];
        };

        private _alternatives = [];

        {
            private _conds = _x;
            private _compiledConds = [];
            private _error = "";

            {
                ([_x, _keys] call FUNC(compileCond)) params ["_condError", "_cond"];

                if (_condError isNotEqualTo "") exitWith {
                    _error = _condError;
                };

                _compiledConds pushBack _cond;
            } forEach _conds;

            if (_error isEqualTo "") then {
                _alternatives pushBack ([_compiledConds] call _fnc_sortConds);
            } else {
                _roundWarnings pushBack [_groupKey, format ["'%1': %2 - left out.", [_id, _conds] call _fnc_groupText, _error]];
            };
        } forEach _y;

        _groups set [_groupKey, _alternatives];
    } forEach _definitions;

    // Definitions nothing of which could even be compiled - wrong whatever the other groups hold.
    private _unread = (keys _groups) select {(_groups get _x) isEqualTo []};

    {
        [_x] call _fnc_check;
    } forEach (keys _groups);

    private _failed = (keys _status) select {(_status get _x) <= 0 && {([_x] call _fnc_below) isNotEqualTo ""}};

    // Those go first: a definition that only failed through one of them may hold up once it is
    // replaced. Only when none is left go the ones caught in a loop or too deep.
    private _drop = _failed select {_x in _unread};

    if (_drop isEqualTo []) then {
        _drop = _failed;
    };

    _settled = _drop isEqualTo [];

    {
        private _groupKey = _x;
        private _id = (_groupKey splitString "#") select 0;
        private _below = [_groupKey] call _fnc_below;

        // What was wrong with it is said only now - the next round does not compile it any more.
        _warnings append ((_roundWarnings select {(_x select 0) isEqualTo _groupKey}) apply {_x select 1});
        _warnings pushBack format ["Group @%1: its definition in %2 does not hold up - the one in %3 is used instead.", _id, [_groupKey] call _fnc_layerName, [_below] call _fnc_layerName];

        _definitions deleteAt _groupKey;

        if ((_top get _id) isEqualTo _groupKey) then {
            _top set [_id, _below];
        };
    } forEach _drop;
};

_warnings append (_roundWarnings apply {_x select 1});

// Where each group is defined in the end.
private _groupSource = createHashMap;

{
    private _layer = parseNumber ((_y splitString "#") select 1);

    _groupSource set [_x, ["preset:" + ((_layers select _layer) select 0), "own"] select (_layer == count _layers - 1)];
} forEach _top;

// The definition in effect also under the group's own name - what rules and the setup wizard use.
private _groupKeys = createHashMap;

{
    if ((_status getOrDefault [_y, 0]) > 0) then {
        _groups set [_x, _groups get _y];
        _groupKeys set [_x, _x];
    };
} forEach _top;

// The kinds a set of conditions can be about: -1 for any, else the kinds. Only what must hold narrows
// it down - kind=, and a group whose every definition does.
private _kindsMemo = createHashMap;

private _fnc_groupKinds = {
    params ["_groupKey"];

    private _known = _kindsMemo get _groupKey;

    if (!isNil "_known") exitWith {_known};

    private _kinds = [];

    {
        private _these = [_x] call _fnc_condsKinds;

        if (_these isEqualType 0) exitWith {
            _kinds = -1;
        };

        _kinds append _these;
    } forEach (_groups getOrDefault [_groupKey, []]);

    if (_kinds isEqualType []) then {
        _kinds = _kinds arrayIntersect _kinds;
    };

    _kindsMemo set [_groupKey, _kinds];

    _kinds
};

private _fnc_condsKinds = {
    params ["_conds"];

    private _kinds = -1;

    {
        _x params ["_negated", "_key", "", "_data"];

        if (!_negated) then {
            private _these = -1;

            if (_key isEqualTo "kind") then {
                _these = keys _data;
            };

            if (_key isEqualTo "@") then {
                _these = [];

                {
                    private _groupKinds = [_x] call _fnc_groupKinds;

                    if (_groupKinds isEqualType 0) exitWith {
                        _these = -1;
                    };

                    _these append _groupKinds;
                } forEach _data;
            };

            if (_these isEqualType []) then {
                _kinds = if (_kinds isEqualType 0) then {_these} else {_kinds arrayIntersect _these};
            };
        };
    } forEach _conds;

    _kinds
};

// ----- Rules -----

private _fnc_values = {
    params ["_values"];

    private _compiledValues = createHashMap;

    {
        switch (_x) do {
            case "footprint": {
                if (_y isEqualTo "mass") then {
                    _compiledValues set ["footprint", "mass"];
                } else {
                    // WxH has digits, a drawn shape none (fnc_parseRules let only those two through).
                    if ((toArray _y) findIf {_x >= 48 && {_x <= 57}} >= 0) then {
                        private _sides = _y splitString "x";

                        _compiledValues set ["footprint", [parseNumber (_sides select 0), parseNumber (_sides select 1), []]];
                    } else {
                        _compiledValues set ["footprint", [_y] call FUNC(parseMask)];
                    };
                };
            };
            case "grid": {
                _compiledValues set ["grid", ([_y] call FUNC(parseGrid)) select 0];
            };
            // Config does not mind the case of a class: lowercase, as fnc_getFacts' "lc".
            case "like": {
                _compiledValues set ["like", toLowerANSI _y];
            };
            default {
                _compiledValues set [_x, _y];
            };
        };
    } forEach _values;

    _compiledValues
};

private _own = [];
private _preset = [];
private _fallback = [];

{
    _x params ["_layerName", "_layerAst"];

    // The text is the last layer - whatever a preset may be called.
    private _isOwn = _forEachIndex == count _layers - 1;

    {
        _x params ["_conds", "_values"];

        private _statement = [_conds, _values] call _fnc_ruleText;

        // Everything else (all): the text's rules for the gaps, a layer of their own under the preset.
        private _isFallback = _conds findIf {(_x select 1) isEqualTo "all"} >= 0;

        if (_isFallback && {!_isOwn}) then {
            _warnings pushBack format ["Preset %1: '%2': 'all' is for the rules text, not a preset - left out.", _layerName, _statement];
            continue;
        };

        private _compiledConds = [];
        private _error = "";

        {
            ([_x, _groupKeys] call FUNC(compileCond)) params ["_condError", "_cond"];

            if (_condError isNotEqualTo "") exitWith {
                _error = _condError;
            };

            _compiledConds pushBack _cond;
        } forEach _conds;

        if (_error isEqualTo "") then {
            _compiledConds = [_compiledConds] call _fnc_sortConds;

            private _entry = [
                _compiledConds,
                [_values] call _fnc_values,
                switch (true) do {
                    case (_isFallback): {format ["all:%1", _forEachIndex]};
                    case (_isOwn): {format ["own:%1", _forEachIndex]};
                    default {format ["preset:%1:%2", _layerName, _forEachIndex]};
                },
                _statement,
                [_compiledConds] call _fnc_condsKinds
            ];

            switch (true) do {
                case (_isFallback): {_fallback pushBack _entry};
                case (_isOwn): {_own pushBack _entry};
                default {_preset pushBack _entry};
            };
        } else {
            _warnings pushBack format [["Preset %3: '%1': %2 - left out.", "'%1': %2 - left out."] select _isOwn, _statement, _error, _layerName];
        };
    } forEach (_layerAst get "rules");
} forEach _layers;

// ----- The older settings -----

private _legacyTexts = [];

if (_legacy) then {
    // How many classes a class is built on: the nearer to an item, the deeper.
    private _fnc_depth = {
        params ["_class"];

        private _config = configNull;

        {
            private _candidate = configFile >> _x >> _class;

            if (isClass _candidate) exitWith {
                _config = _candidate;
            };
        } forEach ["CfgWeapons", "CfgMagazines", "CfgVehicles", "CfgGlasses"];

        private _depth = 0;

        while {isClass _config} do {
            _depth = _depth + 1;
            _config = inheritsFrom _config;
        };

        _depth
    };

    {
        _x params ["_setting", "_type"];

        private _table = [missionNamespace getVariable [_setting, ""], _type, _warnings] call FUNC(parseTable);
        private _entries = [];

        {
            _entries pushBack [[_x] call _fnc_depth, _x, _y];
        } forEach _table;

        // Shallow first: of two classes listed for the same item, the nearer comes later and wins.
        _entries sort true;

        {
            _x params ["", "_class", "_value"];

            private _conds = [[false, "class", "=", [_class + "+"]]];

            // The value as the rules text would write it, for the text, and as compiled.
            private _written = switch (_type) do {
                case "size": {createHashMapFromArray [["footprint", format ["%1x%2", _value select 0, _value select 1]]]};
                case "grid": {createHashMapFromArray [["grid", [_value] call FUNC(formatGrid)]]};
                default {createHashMapFromArray [["stack", _value]]};
            };
            private _compiledValues = switch (_type) do {
                case "size": {createHashMapFromArray [["footprint", [_value select 0, _value select 1, []]]]};
                case "grid": {createHashMapFromArray [["grid", _value]]};
                default {createHashMapFromArray [["stack", _value]]};
            };
            private _statement = [_conds, _written] call _fnc_ruleText;

            ([_conds select 0] call FUNC(compileCond)) params ["", "_cond"];

            _own pushBack [[_cond], _compiledValues, format ["legacy:%1:%2", _setting, _forEachIndex], _statement, -1];
            _legacyTexts pushBack _statement;
        } forEach _entries;
    } forEach [
        [QGVAR(sizeTable), "size"],
        [QGVAR(stackTable), "stack"],
        [QEGVAR(storage,containerTable), "grid"]
    ];

    // The small items' stack - only when the slider was moved, so it never undoes a preset's own.
    private _stackSmall = missionNamespace getVariable [QGVAR(stackSmall), DEFAULT_STACK_SMALL];

    if (_stackSmall != DEFAULT_STACK_SMALL && {"item_small" in _groupKeys}) then {
        private _count = (floor _stackSmall) max 1;
        private _conds = [[false, "@", "=", ["item_small"]]];
        private _statement = [_conds, createHashMapFromArray [["stack", _count]]] call _fnc_ruleText;

        ([_conds select 0, _groupKeys] call FUNC(compileCond)) params ["", "_cond"];

        _preset pushBack [[_cond], createHashMapFromArray [["stack", _count]], format ["legacy:%1:0", QGVAR(stackSmall)], _statement, [[_cond]] call _fnc_condsKinds];
        _legacyTexts pushBack _statement;
    };
};

// ----- Categories nobody defined -----
// An item or a compartment of the text that names a category the text does not define: left out where it is used
// (fnc_getInfo, fnc_cleanGrid), said here once.
private _undefined = [];

{
    private _values = _x select 1;
    private _used = +(_values getOrDefault ["cats", []]);
    private _gridSpec = _values getOrDefault ["grid", []];

    if ((_gridSpec param [0, ""]) isEqualTo "blocks") then {
        {
            _used append (_x param [4, []]);
        } forEach (_gridSpec select 1);
    };

    {
        _undefined pushBackUnique _x;
    } forEach (_used select {!(_x in _categoryIds)});
} forEach _own;

{
    _warnings pushBack format ["There is no category '%1' - the items and compartments that name it ignore it. Add category=%1 > name=... to define it.", _x];
} forEach _undefined;

// ----- By kind -----

private _byKind = createHashMap;

{
    private _kind = _x;
    private _buckets = [_own, _preset, _fallback] apply {
        private _indices = [];
        private _fields = [];

        {
            private _kinds = _x select 4;

            // A kit meets the rules about items too (KINDS_AS_ITEM, fnc_matches).
            if (_kinds isEqualType 0 || {_kind in _kinds} || {_kind in KINDS_AS_ITEM && {"item" in _kinds}}) then {
                _indices pushBack _forEachIndex;
                _fields append (keys (_x select 1));

                // like= answers these from another class (fnc_resolve).
                if ("like" in (_x select 1)) then {
                    _fields append LIKE_FIELDS;
                };
            };
        } forEach _x;

        // Later rules win, so they are asked first.
        reverse _indices;

        [_indices, _fields arrayIntersect _fields]
    };

    _byKind set [_kind, [
        (_buckets select 0) select 0, (_buckets select 1) select 0, (_buckets select 0) select 1, (_buckets select 1) select 1,
        (_buckets select 2) select 0, (_buckets select 2) select 1
    ]];
} forEach ITEM_KINDS;

// ----- All of it in one value -----

private _ownText = [_ast] call FUNC(writeRules);
private _layerTexts = _layers apply {[_x select 1, false] call FUNC(writeRules)};

createHashMapFromArray [
    ["text", _ownText],
    ["ast", _ast],
    ["base", ["none", _base] select (_chain isNotEqualTo [])],
    ["chain", _chain],
    ["cell", _cell],
    ["categoryIds", _categoryIds],
    ["categoryDefs", _categoryDefs],
    ["groups", _groups],
    ["groupKeys", _groupKeys],
    ["groupSource", _groupSource],
    ["groupOrder", _groupOrder],
    ["own", _own],
    ["preset", _preset],
    ["fallback", _fallback],
    ["byKind", _byKind],
    ["hash", hashValue [_cell, _chain, _layerTexts, _legacyTexts]],
    ["warnings", _warnings]
]
