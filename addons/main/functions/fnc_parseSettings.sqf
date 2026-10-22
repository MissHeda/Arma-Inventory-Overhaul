#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads a text of server settings - the setup wizard's own short form of them (its draft, undo steps and
 * changes compare as such texts), and what the settings box of the test builds, einv_main_settings, held
 * (fnc_migrateSettings) - the way the rules text is read: statements
 * separated by commas, a line break counts as a comma, one setting each as key=value, the key being the
 * setting's name without "einv_" (gui_searchTime=0.6, weight_enabled=0, arsenal_biMessage=Closed%0020today). A
 * first statement of "einv" and a number is the header and carries nothing yet. Only what the text says is in the
 * answer; a setting it does not name stays at its default, which the caller's business is. What cannot be
 * read - an unknown key, a value of the wrong kind - is left out with a warning that names it, so one typo
 * never costs the rest. A setting the mod once had and no longer has (GVAR(retiredSettings): gui_animation, the looting
 * animation of 0.4.x) is skipped without a word, so a box written long ago reads clean.
 *
 * Arguments:
 * 0: The text <STRING>
 *
 * Return Value:
 * [values, warnings] - the settings it names, setting's name -> value as its variable holds it <HASHMAP>, and what was
 * left out <ARRAY of STRING>
 *
 * Example:
 * ["einv1, gui_searchTime=0.6, weight_enabled=0"] call einv_main_fnc_parseSettings;
 *
 * Public: Yes
 */

params [["_text", "", [""]]];

private _values = createHashMap;
private _warnings = [];
private _statements = ((_text splitString (toString [10, 13] + ",")) apply {trim _x}) select {_x isNotEqualTo ""};

{
    private _statement = _x;

    // The header: einv and a version, first of all.
    if (_forEachIndex == 0 && {(toLowerANSI _statement) regexMatch "^einv[0-9]+$"}) then {
        continue;
    };

    private _equals = _statement find "=";

    if (_equals <= 0) then {
        _warnings pushBack format ["'%1' is no setting - left out.", _statement];
        continue;
    };

    private _key = toLowerANSI (trim (_statement select [0, _equals]));
    private _name = GVAR(serverKeys) getOrDefault [_key, ""];

    if (_name isEqualTo "" && {_key in GVAR(retiredSettings)}) then {continue};

    if (_name isEqualTo "") then {
        _warnings pushBack format ["'%1': no setting of that name - left out.", _key];
        continue;
    };

    private _value = [GVAR(serverSettings) get _name, trim (_statement select [_equals + 1])] call FUNC(parseValue);

    if (isNil "_value") then {
        _warnings pushBack format ["'%1': the value cannot be read - left out.", _statement];
        continue;
    };

    _values set [_name, _value];
} forEach _statements;

[_values, _warnings]
