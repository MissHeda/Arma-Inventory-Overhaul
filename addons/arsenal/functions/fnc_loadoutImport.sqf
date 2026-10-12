#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Ctrl+V: puts on the loadout in the clipboard - or, with Shift in the Eden editor, adds a list of default
 * loadouts. The text is parsed as data (parseSimpleArray) and never run, and checked with ACE's own
 * functions before anything is set.
 *
 * Arguments:
 * 0: A list of defaults, not one loadout <BOOL> (default: false)
 *
 * Return Value:
 * Imported <BOOL>
 *
 * Example:
 * [false] call einv_arsenal_fnc_loadoutImport;
 *
 * Public: No
 */

params [["_lists", false, [false]]];

private _unit = GVAR(center);
private _display = uiNamespace getVariable [QEGVAR(gui,display), displayNull];

if (isNull _unit) exitWith {false};

// A list of defaults is for those who may change them.
if (_lists && {!(call ACEFUNC(arsenal,canEditDefaultLoadout))}) exitWith {false};

// The clipboard is data, never code: ACE compiles it in single player, this window parses it.
private _text = trim (call FUNC(clipboardRead));

if (_text isNotEqualTo "" && {_text select [count _text - 1] isEqualTo ";"}) then {
    _text = _text select [0, count _text - 1];
};

private _parsed = parseSimpleArray _text;

if (!(_parsed isEqualType []) || {_parsed isEqualTo []}) exitWith {
    [LLSTRING(Loadouts_ErrFormat), "loss"] call FUNC(message);

    false
};

if (_lists) exitWith {
    // [[name, loadout or extended loadout], ...], as the export wrote it.
    private _added = 0;

    {
        if (
            _x isEqualType [] && {count _x == 2} && {(_x select 0) isEqualType ""} && {(_x select 0) isNotEqualTo ""}
            && {(_x select 1) isEqualType []} && {count (_x select 1) in [2, 10]}
        ) then {
            [_x select 0, _x select 1, !is3DEN] call ACEFUNC(arsenal,addDefaultLoadout);

            _added = _added + 1;
        };
    } forEach _parsed;

    if (_added == 0) exitWith {
        [LLSTRING(Loadouts_ErrFormat), "loss"] call FUNC(message);

        false
    };

    GVAR(loadoutsDirty) = true;

    ["put"] call EFUNC(gui,playSound);
    [LLSTRING(Loadouts_ImportedDefaults)] call FUNC(message);

    [QACEGVAR(arsenal,loadoutImported), [_display, true]] call CBA_fnc_localEvent;

    true
};

// One loadout: a getUnitLoadout array, or an extended loadout.
if (count _parsed == 10) then {
    _parsed = [_parsed, createHashMap];
};

if (count _parsed != 2 || {!((_parsed select 0) isEqualType [])} || {count (_parsed select 0) != 10}) exitWith {
    [LLSTRING(Loadouts_ErrFormat), "loss"] call FUNC(message);

    false
};

// Checked with ACE's functions before anything is set; a container this game lacks gives way to the one worn.
private _checked = [_parsed, true] call ACEFUNC(arsenal,verifyLoadout);
_checked = [_unit, _checked] call ACEFUNC(arsenal,recoverInvalidContainers);

// The magazines stay as they were exported.
private _went = [_checked select 0, "", false, false] call FUNC(applyLoadout);

["put"] call EFUNC(gui,playSound);

private _message = LLSTRING(Loadouts_Imported);

if (_went isNotEqualTo []) then {
    private _names = (_went select [0, 4]) apply {format ["%1× %2", _x select 1, [_x select 0] call EFUNC(gui,itemName)]};

    _message = format ["%1. %2", _message, format [LLSTRING(Hint_WentBack), (_names joinString ", ") + (["", ", ..."] select (count _went > 4))]];
};

[_message, ["text2", "loss"] select (_went isNotEqualTo [])] call FUNC(message);

[QACEGVAR(arsenal,loadoutImported), [_display, false]] call CBA_fnc_localEvent;

true
