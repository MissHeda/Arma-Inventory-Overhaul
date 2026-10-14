#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Applies what was pasted into the import box of the Items and Containers editors (fnc_openClassImport),
 * to the draft in one undo step:
 *   - config lines like the ones fnc_exportClasses writes (class CfgVehicles { class X { einv_grid = ""..."";
 *     }; };, several classes at once; einv_items_fnc_parseConfigEntry reads them): each class gets a rule of
 *     its own, class=X > grid=... size=... - exactly as if it had been set in the editor.
 *   - else rules, as the Import at Review reads them (fnc_importText): a bare rules text or lines of a
 *     cba_settings.sqf. Their statements join the own ones - the own preset and the rest stay -, and the
 *     ones that are already there are not added twice.
 * Nothing is saved: Save at Review still decides, and Undo takes the import back.
 *
 * Arguments:
 * 0: Pasted text <STRING>
 *
 * Return Value:
 * What came of it <ARRAY>
 *   0: "config" (lines of config applied), "rules" (rules added), "tooLong" (a setup is never this long),
 *      "none" (nothing that could be read), "refused" (class names the rules cannot hold) <STRING>
 *   1: How many classes (config) or statements (rules) went in; for "tooLong" the length <NUMBER>
 *   2: What could not be read, one text each <ARRAY of STRING>
 *
 * Example:
 * ["class CfgVehicles { class B_Carryall_blk { einv_grid = ""1x3+5x7+1x3""; }; };"] call einv_setup_fnc_importClasses;
 *
 * Public: No
 */

params [["_text", "", [""]]];

private _pasted = trim _text;

if (_pasted isEqualTo "") exitWith {["none", 0, []]};

// ----- Config lines -----

private _messages = [];
private _entries = [];

if (!isNil QEFUNC(items,parseConfigEntry)) then {
    _entries = [_pasted, _messages] call EFUNC(items,parseConfigEntry);
};

if (_entries isNotEqualTo []) exitWith {
    // The config key of each value, and the field of a rule it becomes.
    private _fields = [["einv_size", "footprint"], ["einv_stack", "stack"], ["einv_grid", "grid"], ["einv_weight", "weight"], ["einv_name", "name"]];
    private _changes = [];

    {
        _x params ["_class", "_keys"];

        private _set = createHashMap;

        {
            _x params ["_key", "_field"];

            if (_key in _keys) then {
                _set set [_field, _keys get _key];
            };
        } forEach _fields;

        if (count _set > 0) then {
            _changes pushBack [_class, _set, [], false];
        };
    } forEach _entries;

    if !([_changes] call FUNC(upsertRules)) exitWith {["refused", 0, _messages]};

    ["config", count _changes, _messages]
};

// ----- Rules -----

private _ast = [_pasted] call FUNC(importText);

if (count _ast == 0) exitWith {["none", 0, _messages]};

if ("tooLong" in _ast) exitWith {["tooLong", _ast get "tooLong", []]};

private _warnings = +(_ast getOrDefault ["warnings", []]);
private _imported = [[_ast] call EFUNC(items,writeRules)] call FUNC(statements);

// The own header stays; what the import says that the own rules do not, joins them.
([GVAR(draftText)] call FUNC(statements)) params ["_head", "_statements"];

private _joined = (([_head] + _statements + ((_imported select 1) - _statements)) select {_x isNotEqualTo ""}) joinString ", ";

// Together too long: the engine would read it as the bare default.
if (count _joined > TEXT_MAX) exitWith {["tooLong", count _joined, []]};

private _merged = [_joined] call EFUNC(items,parseRules);

_merged set ["warnings", +_warnings];

[_merged] call FUNC(commit);

["rules", count (_imported select 1), _warnings + _messages]
