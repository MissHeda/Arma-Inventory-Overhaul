#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads the rules of a shared setup pasted into the wizard: a bare rules text, or lines out of a cba_settings.sqf or
 * CBA's Export - then only the einv_items_rules line counts (read with CBA's own reader,
 * cba_settings_fnc_parse), the rest of the mods' settings are left alone; the server settings' own line is read by
 * fnc_importSettings. Its priority ("force") is not
 * taken over: where and how this machine saves is the wizard's own choice.
 *
 * The text is cleaned the way the setting's own box cleans it (fnc_sanitize) before the rules engine
 * reads it; what the engine cannot read it leaves out and names in the tree's warnings. A text without a
 * single statement the engine could use, and without a header, is no rules text.
 *
 * Arguments:
 * 0: Pasted text <STRING>
 *
 * Return Value:
 * The setup as einv_items_fnc_parseRules returns it; an empty HashMap when no rules text was found; only
 * "tooLong" (its length) when the rules text is longer than TEXT_MAX <HASHMAP>
 *
 * Example:
 * ["force einv_items_rules = ""einv1 base=default cell=4"";"] call einv_setup_fnc_importText;
 *
 * Public: No
 */

params [["_text", "", [""]]];

private _rules = trim _text;

if (_rules isEqualTo "") exitWith {createHashMap};

if ((toLower _rules) find RULES_SETTING >= 0) then {
    private _found = "";

    if (!isNil "cba_settings_fnc_parse") then {
        {
            _x params ["_name", "_value"];

            if (toLower _name isEqualTo RULES_SETTING && {_value isEqualType ""}) then {
                _found = _value;
            };
        } forEach ([_rules, false, "", false] call cba_settings_fnc_parse);
    };

    _rules = _found;
};

_rules = trim ([_rules] call FUNC(sanitize));

if (_rules isEqualTo "") exitWith {createHashMap};

// Longer than a setup may be, the engine reads it as the bare default: not read at all here, so the
// caller can say so instead of putting the default in its place.
if (count _rules > TEXT_MAX) exitWith {createHashMapFromArray [["tooLong", count _rules]]};

private _ast = [_rules] call EFUNC(items,parseRules);

// Nothing the engine could use - another mod's line, any other text - is nothing to import either, not
// the default the engine reads it as. A header alone (einv1 base=default) is something: the engine takes it
// as the header when the first statement starts with einv and a number.
private _first = (((_rules splitString ",") apply {trim _x}) select {_x isNotEqualTo ""}) param [0, ""];
private _word = toLowerANSI ((_first splitString " ") param [0, ""]);
private _digits = toArray (_word select [4]);
private _header = (_word select [0, 4]) isEqualTo "einv" && {_digits isNotEqualTo []} && {(_digits findIf {_x < 48 || {_x > 57}}) < 0};

if ((_ast getOrDefault ["categories", []]) isEqualTo [] && {(_ast getOrDefault ["groups", []]) isEqualTo []} && {(_ast getOrDefault ["rules", []]) isEqualTo []} && {!_header}) exitWith {createHashMap};

_ast
