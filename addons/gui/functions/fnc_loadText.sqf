#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The load on a section's caption line: what it holds in kilograms, and against its limit when it has
 * one - "3.4 / 12.0 kg". Whether it is over the limit (possible through scripts and other mods) is
 * returned with it: the text turns red then, but not while only the grid limits a container
 * (einv_storage_gridOnly) - going past the weight is normal there.
 *
 * Arguments:
 * 0: Entries it holds <ARRAY of HASHMAPs>
 * 1: What it can hold, config mass, -1 for no limit <NUMBER>
 *
 * Return Value:
 * [text, over the limit] <ARRAY>
 *
 * Example:
 * [_entries, 120] call einv_gui_fnc_loadText;
 *
 * Public: No
 */

params [["_entries", [], [[]]], ["_maxLoad", -1, [0]]];

private _mass = [_entries] call EFUNC(storage,getMass);
private _kg = (_mass * MASS_TO_KG) toFixed 1;

private _text = if (_maxLoad > 0) then {
    format ["%1 / %2 kg", _kg, (_maxLoad * MASS_TO_KG) toFixed 1]
} else {
    format ["%1 kg", _kg]
};

[_text, _maxLoad > 0 && {!EGVAR(storage,gridOnly)} && {_mass >= _maxLoad}]
