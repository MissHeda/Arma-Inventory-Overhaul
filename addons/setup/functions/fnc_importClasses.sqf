#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Applies what was pasted into the import box of the Items and Containers editors (fnc_openClassImport),
 * to the draft in one undo step. What is pasted is one of
 *   - a layout (fnc_exportClasses "layout"): LAYOUT_MARKER and the values of a rule, no class. It has no class
 *     of its own, so it always goes to the class selected in the editor (the selected tree, when the edit is
 *     for one);
 *   - config lines like the ones fnc_exportClasses writes (class CfgVehicles { class X { einv_grid = ""..."";
 *     }; };, several classes at once; einv_items_fnc_parseConfigEntry reads them);
 *   - rules of single classes only (class=X > grid=..., class=X+ > ...) without a header or groups: read the
 *     same as the config lines, a class each;
 *   - else rules, as the setup's Import reads them (fnc_importText): a bare rules text or lines of a
 *     cba_settings.sqf. Their statements join the own ones - the own preset and the rest stay -, and the
 *     ones that are already there are not added twice.
 *
 * Config lines and rules of single classes name their classes, and a class the game does not have (another
 * mod's, not loaded here) must never get a rule. So, with the class selected in the editor:
 *   - the text names one class that this game does not have: its values go to the selected class instead,
 *     and the answer says so ("selected");
 *   - it names several that it does not have: nothing is applied ("skipped");
 *   - it names classes the game has: with one class that is the selected one they go there at once; else the
 *     answer is "ask", and the editor asks (fnc_openImportChoice) which it is to be - the selected class (only
 *     when the text names one class) or the classes named - and calls this again with that choice. Classes the
 *     game lacks are left out of the named ones.
 * Values that cannot mean anything to the selected class are left out: a grid for what is no container, a stack
 * for what never shares a tile.
 * A kit of Enhanced First Aid Kits class=X+, so the kits carried, instances of it, follow (fnc_editScope).
 * Nothing is saved: Save still decides, and Undo takes the import back.
 *
 * Arguments:
 * 0: Pasted text <STRING>
 * 1: The class selected in the editor <STRING> (default: "")
 * 2: The edit is for that class and everything built on it <BOOL> (default: false)
 * 3: What the answer "ask" was answered with: "selected" or "named"; "" the first time <STRING> (default: "")
 *
 * Return Value:
 * What came of it <ARRAY>
 *   0: "config" (the classes the text names, applied), "layout" (a layout applied to the selected class),
 *      "selected" (the values of a class this game does not have applied to the selected one), "rules" (rules
 *      added), "ask" (needs the choice), "skipped" (classes the game does not have, several), "notFit" (no value
 *      fits the selected class), "tooLong" (a setup is never this long), "none" (nothing that could be read),
 *      "refused" (class names the rules cannot hold) <STRING>
 *   1: How many classes (config) or statements (rules) went in; for "tooLong" the length, for "ask" how many
 *      classes the game has, for "skipped" how many the text names <NUMBER>
 *   2: What could not be read, one text each <ARRAY of STRING>
 *   3: For "selected" [selected class, the class of the text], for "layout" [selected class], for "config" how
 *      many classes of the text the game lacks and were left out, for "ask" [the first class, how many the text
 *      names], for "notFit" [selected class] <ARRAY>
 *
 * Example:
 * ["class CfgVehicles { class B_Carryall_blk { einv_grid = ""1x3+5x7+1x3""; }; };", "B_Carryall_blk"] call einv_setup_fnc_importClasses;
 *
 * Public: No
 */

params [["_text", "", [""]], ["_selected", "", [""]], ["_tree", false, [false]], ["_choice", "", [""]]];

private _pasted = trim _text;

if (_pasted isEqualTo "") exitWith {["none", 0, [], []]};

private _messages = [];

// The entries: [class, values, the class and everything built on it], the class "" for a layout.
private _entries = [];
private _from = "";
private _selectedLc = toLowerANSI _selected;

// ----- A layout -----

if ((toLower (_pasted select [0, count LAYOUT_MARKER])) isEqualTo LAYOUT_MARKER) then {
    _from = "layout";

    private _body = trim ([_pasted select [count LAYOUT_MARKER]] call FUNC(sanitize));

    if (count _body > TEXT_MAX) exitWith {
        _from = "tooLong";
        _messages pushBack count _body;
    };

    private _ast = [_body] call EFUNC(items,parseRules);
    private _values = createHashMap;

    {
        _values merge [_x select 1, true];
    } forEach (_ast getOrDefault ["rules", []]);

    _messages append (_ast getOrDefault ["warnings", []]);

    if (count _values > 0) then {
        _entries pushBack ["", _values, _tree];
    };
};

if (_from isEqualTo "tooLong") exitWith {["tooLong", _messages select 0, [], []]};

// ----- Config lines -----

if (_from isEqualTo "" && {!isNil QEFUNC(items,parseConfigEntry)}) then {
    {
        _x params ["_class", "_keys"];

        private _values = [_keys] call FUNC(configValues);

        // A kit of Enhanced First Aid Kits for the instances of it that are carried as well, as its editors
        // write it (fnc_editScope): class=X+.
        if (count _values > 0) then {
            _entries pushBack [_class, _values, (([_class] call EFUNC(items,kitOf)) param [1, -1]) == 0];
        };
    } forEach ([_pasted, _messages] call EFUNC(items,parseConfigEntry));

    if (_entries isNotEqualTo []) then {
        _from = "config";
    };
};

// ----- Rules ----- (of single classes only: a class each, as the config lines)

private _ast = createHashMap;

if (_from isEqualTo "") then {
    _ast = [_pasted] call FUNC(importText);

    if (count _ast == 0) exitWith {};

    if ("tooLong" in _ast) exitWith {};

    private _rules = _ast getOrDefault ["rules", []];

    // Only rules that are nothing but class=X (or X+), no group, no header and no setting around them.
    private _plain = _rules isNotEqualTo []
        && {(_ast getOrDefault ["groups", []]) isEqualTo []}
        && {(toLower (_pasted select [0, 4])) isNotEqualTo "einv"}
        && {(toLower _pasted) find RULES_SETTING < 0}
        && {_rules findIf {
            _x params ["_conds"];

            count _conds != 1 || {
                (_conds select 0) params ["_negated", "_key", "_op", "_names"];

                _negated || {_key isNotEqualTo "class"} || {_op isNotEqualTo "="} || {_names isEqualTo []}
            }
        } < 0};

    if (_plain) then {
        private _byClass = createHashMap;

        {
            _x params ["_conds", "_values"];

            {
                private _isTree = (_x select [count _x - 1]) isEqualTo "+";
                private _name = [_x, _x select [0, count _x - 1]] select _isTree;
                private _lc = toLowerANSI _name;
                private _entry = _byClass getOrDefault [_lc, [_name, createHashMap, _isTree]];

                (_entry select 1) merge [_values, true];
                _byClass set [_lc, _entry];
            } forEach ((_conds select 0) select 3);
        } forEach _rules;

        _entries = values _byClass;
        _from = "classes";
    };
};

// ----- Rules of any kind: their statements join the own ones -----

if (_from isEqualTo "") exitWith {
    if (count _ast == 0) exitWith {["none", 0, _messages, []]};

    if ("tooLong" in _ast) exitWith {["tooLong", _ast get "tooLong", [], []]};

    private _warnings = +(_ast getOrDefault ["warnings", []]);
    private _imported = [[_ast] call EFUNC(items,writeRules)] call FUNC(statements);

    // The own header stays; what the import says that the own rules do not, joins them.
    ([GVAR(draftText)] call FUNC(statements)) params ["_head", "_statements"];

    private _joined = (([_head] + _statements + ((_imported select 1) - _statements)) select {_x isNotEqualTo ""}) joinString ", ";

    // Together too long: the engine would read it as the bare default.
    if (count _joined > TEXT_MAX) exitWith {["tooLong", count _joined, [], []]};

    private _merged = [_joined] call EFUNC(items,parseRules);

    _merged set ["warnings", +_warnings];

    [_merged] call FUNC(commit);

    ["rules", count (_imported select 1), _warnings + _messages, []]
};

if (_entries isEqualTo []) exitWith {["none", 0, _messages, []]};

// ----- Where each class goes -----

// What the selected class can use of a set of values: no grid for what is no container, no stack for what never
// shares a tile, no like=.
private _fnc_fit = {
    params ["_values", "_class"];

    private _kind = ([_class] call EFUNC(items,getFacts)) getOrDefault ["kind", ""];
    private _fit = +_values;

    _fit deleteAt "like";

    if !(_kind in CONTAINER_KINDS) then {
        _fit deleteAt "grid";
    };

    if (_kind in ["rifle", "handgun", "launcher", "binocular", "uniform", "vest", "backpack"]) then {
        _fit deleteAt "stack";
    };

    _fit
};

// The values to the selected class, as the editor itself would write them.
private _fnc_toSelected = {
    params ["_values", "_kind", "_info"];

    if (_selected isEqualTo "") exitWith {["none", 0, _messages, []]};

    private _fit = [_values, _selected] call _fnc_fit;

    if (count _fit == 0) exitWith {["notFit", 0, _messages, [_selected]]};

    if !([[[_selected, _fit, [], _tree]]] call FUNC(upsertRules)) exitWith {["refused", 0, _messages, []]};

    [_kind, 1, _messages, _info]
};

// Never a rule for a class this game does not have: config knows the ones that count.
private _known = _entries select {(_x select 0) isNotEqualTo "" && {((([_x select 0] call EFUNC(items,getFacts)) getOrDefault ["root", ""]) isNotEqualTo "")}};
private _foreign = (count _entries) - (count _known);

// The classes the text names, each its own rule.
private _fnc_toNamed = {
    private _changes = _known apply {[_x select 0, _x select 1, [], _x select 2]};

    if !([_changes] call FUNC(upsertRules)) exitWith {["refused", 0, _messages, []]};

    ["config", count _changes, _messages, [_foreign]]
};

private _only = _entries select 0;

call {
    // A layout has no class: the selected one.
    if (_from isEqualTo "layout") exitWith {
        [_only select 1, "layout", [_selected]] call _fnc_toSelected
    };

    // Answered: the selected class takes the one class of the text.
    if (_choice isEqualTo "selected" && {count _entries == 1}) exitWith {
        [_only select 1, "selected", [_selected, _only select 0]] call _fnc_toSelected
    };

    if (_choice isEqualTo "named" && {_known isNotEqualTo []}) exitWith {
        call _fnc_toNamed
    };

    // Not asked yet, and the game has none of the classes: one goes to the selected class, several cannot.
    if (_known isEqualTo [] && {count _entries == 1}) exitWith {
        [_only select 1, "selected", [_selected, _only select 0]] call _fnc_toSelected
    };

    if (_known isEqualTo []) exitWith {
        ["skipped", count _entries, _messages, []]
    };

    // The text names the class that is selected, and no other: nothing to ask.
    if (count _entries == 1 && {toLowerANSI (_only select 0) isEqualTo _selectedLc}) exitWith {
        call _fnc_toNamed
    };

    ["ask", count _known, _messages, [(_known select 0) select 0, count _entries]]
}
