#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What the draft changes against another setup, one row per change, the way CBA lists what differs from
 * the default - for what is not saved yet and for what the classes change on top of the General step's
 * settings (both drawn by fnc_drawChanges), and for the header's count (fnc_countChanges):
 *   - "saved": against GVAR(clean) and GVAR(cleanSettings), the setup in effect where the wizard saves - as it
 *     was when the wizard opened, was saved or reloaded. On a machine that may not save, the one in use. The
 *     switch to force it over the mission's own setup is a change as well.
 *   - "default": against the default setup that has what the General step sets - the cell size and the size of
 *     each kind of container (the rules "all kind=uniform > grid=5x5") - as the draft has it. Those are the
 *     defaults the classes are measured against: when all uniforms are 10x10 by their kind and one is 5x5, only
 *     that one is a change. The server settings are not part of it.
 * The preset (only a text can still change it), the cell size, each server setting, then every group and rule. A statement is matched with the one the other
 * setup has for the same conditions - a group by its name -, so a class given another size is one row,
 * "changed", rather than one rule taken away and another added. Those the draft lost come last.
 *
 * Each row takes its own change back, alone: the preset or cell size the other setup has, a new
 * statement removed, a changed or a removed one put back after the statement it followed there - a later
 * rule wins, and an edited class's rule is moved to the end of the text (fnc_upsertRule), so it gets its
 * place back rather than staying where the edit left it.
 *
 * Arguments:
 * 0: "saved" or "default" <STRING> (default: "saved")
 * 1: In words, with pictures - without, only what changed, to count <BOOL> (default: true)
 *
 * Return Value:
 * Rows, [[kind, status, label, words, picture, before, class, statement, undo], ...] <ARRAY>
 *   kind      - "preset", "cell", "override", "setting", "category", "group" or "rule"
 *   status    - "new", "changed" or "removed"
 *   label     - what it is about: "Preset", the class by its display name, or the whole sentence
 *   words     - the change in words (fnc_describeRule), "" when the label says it all
 *   picture   - the class's picture, "" for none
 *   before    - the same as the other setup has it, "" for none
 *   class     - the one class a rule is for, "" for any other
 *   statement - the group or rule as the draft has it, as the other setup had it when removed
 *   undo      - [code, arguments], the code called with the arguments as _this
 *
 * Example:
 * count (["saved", false] call einv_setup_fnc_changeRows);
 *
 * Public: No
 */

params [["_against", "saved", [""]], ["_describe", true, [true]]];

// The other setup, read once per text: the header and both lists ask on every redraw. Written out by the
// engine as the draft is, so their statements compare as text. Against the default it is the default with
// what the General step sets kept as the draft has it.
private _refText = GVAR(clean);

if (_against isEqualTo "default") then {
    private _general = [RULES_DEFAULT] call EFUNC(items,parseRules);

    _general set ["cell", GVAR(draft) getOrDefault ["cell", -1]];
    // The categories are the General step's own, as the cell size is.
    _general set ["categories", +(GVAR(draft) getOrDefault ["categories", []])];
    _general set ["rules", (GVAR(draft) getOrDefault ["rules", []]) select {
        private _rule = _x;

        (GENERAL_KINDS findIf {([[_rule], [_x]] call FUNC(allRule)) == 0}) >= 0
    }];

    _refText = [_general] call EFUNC(items,writeRules);
};

private _refs = missionNamespace getVariable [QGVAR(changeRefs), createHashMap];
private _ref = _refs get _refText;

if (isNil "_ref") then {
    private _canonical = [[_refText] call EFUNC(items,parseRules)] call EFUNC(items,writeRules);

    _ref = [[_canonical] call EFUNC(items,parseRules), ([_canonical] call FUNC(statements)) select 1];
    _refs set [_refText, _ref];

    missionNamespace setVariable [QGVAR(changeRefs), _refs];
};

_ref params ["_refAst", "_refStatements"];

private _draft = GVAR(draft);
private _draftStatements = ([GVAR(draftText)] call FUNC(statements)) select 1;
private _rows = [];

// ----- The preset and the cell size -----

private _base = _draft getOrDefault ["base", "default"];
private _refBase = _refAst getOrDefault ["base", "default"];

if (_base isNotEqualTo _refBase) then {
    private _words = "";

    if (_describe) then {
        _words = format [LLSTRING(Change_From), [_refBase] call FUNC(presetName), [_base] call FUNC(presetName)];
    };

    _rows pushBack ["preset", "changed", LLSTRING(Change_Preset), _words, "", "", "", [], [{
        private _ast = [GVAR(draftText)] call EFUNC(items,parseRules);
        _ast set ["base", _this];

        [_ast] call FUNC(commit);
    }, _refBase]];
};

// -1 (or none): the preset's own.
private _cell = _draft getOrDefault ["cell", -1];
private _refCell = _refAst getOrDefault ["cell", -1];

if (_cell isNotEqualTo _refCell && {_cell > 0 || {_refCell > 0}}) then {
    private _words = "";

    if (_describe) then {
        private _fnc_cell = {
            if (_this > 0) exitWith {format ["%1 (%2 kg)", _this, (_this * MASS_TO_KG) toFixed 2]};

            LLSTRING(Change_CellPreset)
        };

        _words = format [LLSTRING(Change_From), _refCell call _fnc_cell, _cell call _fnc_cell];
    };

    _rows pushBack ["cell", ["changed", "new", "removed"] select ([[0, 2] select (_cell <= 0), 1] select (_refCell <= 0)), LLSTRING(Cell_Title), _words, "", "", "", [], [{
        private _ast = [GVAR(draftText)] call EFUNC(items,parseRules);
        _ast set ["cell", _this];

        [_ast] call FUNC(commit);
    }, _refCell]];
};

// Not part of the text - it decides how firmly Save stores it - but a change all the same.
if (_against isEqualTo "saved" && {GVAR(override) isNotEqualTo GVAR(cleanOverride)}) then {
    _rows pushBack [
        "override", "changed", [LLSTRING(Change_OverrideOff), LLSTRING(Change_OverrideOn)] select GVAR(override), "", "", "", "", [], [{
            GVAR(override) = GVAR(cleanOverride);

            [GVAR(step)] call FUNC(showStep);
        }, []]
    ];
};

// ----- The server settings -----

// Each one that is not at the same value in the other setup: set where it was at its default, taken back to it,
// or changed. Only what is saved is compared - the default has no settings of its own to be measured against.
if (_against isEqualTo "saved") then {
    private _registry = missionNamespace getVariable [QEGVAR(main,serverSettings), createHashMap];
    private _refValues = ([GVAR(cleanSettings)] call EFUNC(main,parseSettings)) select 0;

    {
        private _name = _x;
        private _now = GVAR(draftSettings) get _name;
        private _was = _refValues get _name;

        if (isNil "_now" && {isNil "_was"}) then {continue};
        if (!isNil "_now" && {!isNil "_was"} && {_now isEqualTo _was}) then {continue};

        private _entry = _registry get _name;
        private _words = "";

        if (_describe) then {
            _words = format [LLSTRING(Change_From), [_name, _was] call FUNC(settingText), [_name, _now] call FUNC(settingText)];
        };

        _rows pushBack [
            "setting", ["changed", "new", "removed"] select ([[0, 2] select (isNil "_now"), 1] select (isNil "_was")),
            _entry get "label", _words, "", "", "", [], [{
                params ["_name", "_value"];

                [_name, _value] call FUNC(setSetting);
            }, [_name, _was]]
        ];
    } forEach (missionNamespace getVariable [QEGVAR(main,serverOrder), []]);
};

// ----- The statements -----

// Each by what it is for - a category by its id, a group by its name, a rule by its conditions, the second of the same counted
// apart - with [key, type (0 rule, 1 group, 2 category), statement, index in its own list, as written, index in these entries].
// The text writes them in this order: the categories, the groups, the rules.
private _fnc_entries = {
    params ["_ast", "_statements"];

    private _categories = _ast getOrDefault ["categories", []];
    private _groups = _ast getOrDefault ["groups", []];
    private _categoryCount = count _categories;
    private _groupCount = count _groups;
    private _seen = createHashMap;
    private _entries = [];

    {
        private _type = 0;

        if (_forEachIndex < _categoryCount) then {
            _type = 2;
        } else {
            if (_forEachIndex < _categoryCount + _groupCount) then {
                _type = 1;
            };
        };

        private _subject = switch (_type) do {
            case 2: {"category=" + (_x select 0)};
            case 1: {"@" + (_x select 0)};
            default {str (_x select 0)};
        };
        private _nth = _seen getOrDefault [_subject, 0];

        _seen set [_subject, _nth + 1];
        _entries pushBack [
            format ["%1#%2", _subject, _nth], _type, _x,
            _forEachIndex - ([_categoryCount + _groupCount, _categoryCount, 0] select _type),
            _statements param [_forEachIndex, ""], count _entries
        ];
    } forEach (_categories + _groups + (_ast getOrDefault ["rules", []]));

    _entries
};

private _draftEntries = [_draft, _draftStatements] call _fnc_entries;
private _refEntries = [_refAst, _refStatements] call _fnc_entries;
private _draftByKey = createHashMap;
private _refByKey = createHashMap;

{_draftByKey set [_x select 0, _x]} forEach _draftEntries;
{_refByKey set [_x select 0, _x]} forEach _refEntries;

// In words: a rule for exactly one class (class=X, not X+) by that class's picture and display name and
// what it sets; anything else as the whole sentence. [label, words, picture, class]
private _fnc_words = {
    params ["_type", "_statement", "_ast"];

    if (_type == 2) exitWith {[[_statement, _ast, false, false, true] call FUNC(describeRule), "", "", ""]};
    if (_type == 1) exitWith {[[_statement, _ast, true] call FUNC(describeRule), "", "", ""]};

    private _conds = _statement param [0, []];
    private _class = "";

    if (count _conds == 1) then {
        (_conds select 0) params [["_negated", false], ["_key", ""], ["_op", ""], ["_names", []]];

        if (!_negated && {_key isEqualTo "class"} && {_op isEqualTo "="} && {count _names == 1} && {((_names select 0) find "+") < 0}) then {
            _class = _names select 0;
        };
    };

    if (_class isEqualTo "") exitWith {[[_statement, _ast] call FUNC(describeRule), "", "", ""]};

    private _facts = [_class] call EFUNC(items,getFacts);
    private _known = (_facts getOrDefault ["root", ""]) isNotEqualTo "";
    private _words = [_statement, _ast, false, true] call FUNC(describeRule);

    if (!_known) exitWith {[_class, _words, "", _class]};

    [_facts getOrDefault ["name", _class], _words, [_facts getOrDefault ["picture", ""]] call EFUNC(gui,safePicture), _facts getOrDefault ["class", _class]]
};

// Where a statement of the other setup goes in the draft's own list: after the nearest statement before it
// there that the draft still has, else first. The draft index to be taken out first (a changed statement,
// put back after) shifts those behind it by one.
private _fnc_placeOf = {
    params ["_refIndex", "_type", ["_taken", -1]];

    private _at = 0;

    for "_i" from _refIndex - 1 to 0 step -1 do {
        private _previous = _refEntries select _i;
        private _kept = _draftByKey get (_previous select 0);

        if ((_previous select 1) isEqualTo _type && {!isNil "_kept"}) exitWith {
            private _keptAt = _kept select 3;

            if (_taken >= 0 && {_keptAt > _taken}) then {
                _keptAt = _keptAt - 1;
            };

            _at = _keptAt + 1;
        };
    };

    _at
};

// Takes one statement's change back: [what, type, index, statement, place] - "delete" a new one,
// "set" a changed one to what it was (taken out at the index and put in at the place, which is where the
// other setup has it: the edit moved it to the end, and with it out of order the list would still differ
// from the other when every change was undone), "insert" a removed one at the index.
private _undoStatement = {
    params ["_what", "_type", "_index", "_statement", ["_at", 0]];

    private _key = ["rules", "groups", "categories"] select _type;
    private _ast = [GVAR(draftText)] call EFUNC(items,parseRules);
    private _list = _ast getOrDefault [_key, []];

    switch (_what) do {
        case "delete": {_list deleteAt _index};
        case "set": {
            _list deleteAt _index;
            _list = (_list select [0, _at]) + [+_statement] + (_list select [_at]);
        };
        default {_list = (_list select [0, _index]) + [+_statement] + (_list select [_index])};
    };

    _ast set [_key, _list];

    [_ast] call FUNC(commit);
};

private _fnc_row = {
    params ["_status", "_type", "_statement", "_ast", "_before", "_undo"];

    private _row = [["rule", "group", "category"] select _type, _status, "", "", "", "", "", _statement, [_undoStatement, _undo]];

    if (_describe) then {
        ([_type, _statement, _ast] call _fnc_words) params ["_label", "_words", "_picture", "_class"];

        _row set [2, _label];
        _row set [3, _words];
        _row set [4, _picture];
        _row set [6, _class];

        if (_before isNotEqualTo []) then {
            ([_type, _before, _refAst] call _fnc_words) params ["_beforeLabel", "_beforeWords"];

            _row set [5, [_beforeLabel, _beforeWords] select (_beforeWords isNotEqualTo "")];
        };
    };

    _row
};

{
    _x params ["_key", "_type", "_statement", "_index", "_written"];

    private _other = _refByKey get _key;

    if (isNil "_other") then {
        _rows pushBack (["new", _type, _statement, _draft, [], ["delete", _type, _index, []]] call _fnc_row);
    } else {
        if ((_other select 4) isNotEqualTo _written) then {
            _rows pushBack (["changed", _type, _statement, _draft, _other select 2, ["set", _type, _index, _other select 2, [_other select 5, _type, _index] call _fnc_placeOf]] call _fnc_row);
        };
    };
} forEach _draftEntries;

{
    _x params ["_key", "_type", "_statement"];

    if !(_key in _draftByKey) then {
        private _at = [_forEachIndex, _type] call _fnc_placeOf;

        _rows pushBack (["removed", _type, _statement, _refAst, [], ["insert", _type, _at, _statement]] call _fnc_row);
    };
} forEach _refEntries;

_rows
