#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the draft changes against another setup, one row per change, the way CBA lists what differs from
 * the default - for Review against what is saved, for Start against the Default preset (both drawn by
 * fnc_drawChanges), and for the header's count (fnc_countChanges):
 *   - "saved": against GVAR(clean), the setup in effect where the wizard saves - as it was when the
 *     wizard opened, was saved or reloaded. On a machine that may not save, the one in use. The switch to
 *     force it over the mission's own setup is a change as well.
 *   - "default": against the Default preset without any rules of its own (RULES_DEFAULT).
 * The preset, the cell size, then every group and rule. A statement is matched with the one the other
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
 *   kind      - "preset", "cell", "override", "group" or "rule"
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
// engine as the draft is, so their statements compare as text.
private _refText = [GVAR(clean), RULES_DEFAULT] select (_against isEqualTo "default");
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

// ----- The statements -----

// Each by what it is for - a group by its name, a rule by its conditions, the second of the same counted
// apart - with [key, is a group, statement, index in its own list, as written, index in these entries].
private _fnc_entries = {
    params ["_ast", "_statements"];

    private _groups = _ast getOrDefault ["groups", []];
    private _groupCount = count _groups;
    private _seen = createHashMap;
    private _entries = [];

    {
        private _isGroup = _forEachIndex < _groupCount;
        private _subject = if (_isGroup) then {"@" + (_x select 0)} else {str (_x select 0)};
        private _nth = _seen getOrDefault [_subject, 0];

        _seen set [_subject, _nth + 1];
        _entries pushBack [format ["%1#%2", _subject, _nth], _isGroup, _x, [_forEachIndex - _groupCount, _forEachIndex] select _isGroup, _statements param [_forEachIndex, ""], count _entries];
    } forEach (_groups + (_ast getOrDefault ["rules", []]));

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
    params ["_isGroup", "_statement", "_ast"];

    if (_isGroup) exitWith {[[_statement, _ast, true] call FUNC(describeRule), "", "", ""]};

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
    params ["_refIndex", "_isGroup", ["_taken", -1]];

    private _at = 0;

    for "_i" from _refIndex - 1 to 0 step -1 do {
        private _previous = _refEntries select _i;
        private _kept = _draftByKey get (_previous select 0);

        if ((_previous select 1) isEqualTo _isGroup && {!isNil "_kept"}) exitWith {
            private _keptAt = _kept select 3;

            if (_taken >= 0 && {_keptAt > _taken}) then {
                _keptAt = _keptAt - 1;
            };

            _at = _keptAt + 1;
        };
    };

    _at
};

// Takes one statement's change back: [what, is a group, index, statement, place] - "delete" a new one,
// "set" a changed one to what it was (taken out at the index and put in at the place, which is where the
// other setup has it: the edit moved it to the end, and with it out of order the list would still differ
// from the other when every change was undone), "insert" a removed one at the index.
private _undoStatement = {
    params ["_what", "_isGroup", "_index", "_statement", ["_at", 0]];

    private _key = ["rules", "groups"] select _isGroup;
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
    params ["_status", "_isGroup", "_statement", "_ast", "_before", "_undo"];

    private _row = [["rule", "group"] select _isGroup, _status, "", "", "", "", "", _statement, [_undoStatement, _undo]];

    if (_describe) then {
        ([_isGroup, _statement, _ast] call _fnc_words) params ["_label", "_words", "_picture", "_class"];

        _row set [2, _label];
        _row set [3, _words];
        _row set [4, _picture];
        _row set [6, _class];

        if (_before isNotEqualTo []) then {
            ([_isGroup, _before, _refAst] call _fnc_words) params ["_beforeLabel", "_beforeWords"];

            _row set [5, [_beforeLabel, _beforeWords] select (_beforeWords isNotEqualTo "")];
        };
    };

    _row
};

{
    _x params ["_key", "_isGroup", "_statement", "_index", "_written"];

    private _other = _refByKey get _key;

    if (isNil "_other") then {
        _rows pushBack (["new", _isGroup, _statement, _draft, [], ["delete", _isGroup, _index, []]] call _fnc_row);
    } else {
        if ((_other select 4) isNotEqualTo _written) then {
            _rows pushBack (["changed", _isGroup, _statement, _draft, _other select 2, ["set", _isGroup, _index, _other select 2, [_other select 5, _isGroup, _index] call _fnc_placeOf]] call _fnc_row);
        };
    };
} forEach _draftEntries;

{
    _x params ["_key", "_isGroup", "_statement"];

    if !(_key in _draftByKey) then {
        private _at = [_forEachIndex, _isGroup] call _fnc_placeOf;

        _rows pushBack (["removed", _isGroup, _statement, _refAst, [], ["insert", _isGroup, _at, _statement]] call _fnc_row);
    };
} forEach _refEntries;

_rows
