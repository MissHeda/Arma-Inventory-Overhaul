#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Takes colours as text - what the colour popover's Export gives, or the CBA setting einv_gui_paletteText - as the player's
 * palette: read as the profile is (fnc_paletteRead), kept and shown at once. Text that is no palette changes nothing.
 *
 * Arguments:
 * 0: Text <STRING>
 *
 * Return Value:
 * Taken <BOOL>
 *
 * Example:
 * ["[[0.6,0.7,1],[],-1]"] call einv_gui_fnc_paletteImport;
 *
 * Public: No
 */

params [["_text", "", [""]]];

_text = _text trim [" ", 0];

if (_text isEqualTo "" || {(_text select [0, 1]) isNotEqualTo "["}) exitWith {false};

// Only text parseSimpleArray reads without an error: strings, true and false and numbers made 0, then every [0,...,0] folded into
// a 0 until nothing changes - a palette ends as one 0. Anything else (cut off, typed over) would raise a script error.
private _shape = ((((_text regexReplace ["""[^""]*""", "0"]) regexReplace ["true|false", "0"]) regexReplace ["\s", ""])
    regexReplace ["-?([0-9]+\.?[0-9]*|\.[0-9]+)([eE][-+]?[0-9]+)?", "0"]);
private _before = "";

while {_shape isNotEqualTo _before} do {
    _before = _shape;
    _shape = _shape regexReplace ["\[(0(,0)*)?\]", "0"];
};

if (_shape isNotEqualTo "0") exitWith {false};

private _parsed = parseSimpleArray _text;
private _read = [_parsed] call FUNC(paletteRead);

if (_read isEqualTo []) exitWith {false};
if (_read isEqualTo GVAR(palette)) exitWith {true};

GVAR(palette) = _read;
GVAR(paletteDirty) = true;

profileNamespace setVariable [QGVAR(palette), +GVAR(palette)];
saveProfileNamespace;

if (!isNull (uiNamespace getVariable [QGVAR(display), displayNull])) then {
    [] call FUNC(buildSoon);
};

true
