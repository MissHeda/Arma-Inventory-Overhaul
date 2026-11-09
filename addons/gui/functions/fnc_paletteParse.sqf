#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads colours as text - what the colour popover's Export gives, or the CBA setting aio_gui_paletteText - into an array,
 * without the script error parseSimpleArray raises on text it cannot read: an empty setting, one cut off or typed over (a
 * server that forced the setting empty showed "parseSimpleArray format error" on every theme build - Haiden, Discord
 * 2026-11-09). Only text made of strings, true and false, numbers and brackets is read; anything else gives [].
 *
 * Arguments:
 * 0: Text <STRING>
 *
 * Return Value:
 * The array read, [] for text that is no array <ARRAY>
 *
 * Example:
 * ["[[0.6,0.7,1],[],-1]"] call aio_gui_fnc_paletteParse;
 *
 * Public: No
 */

params [["_text", "", [""]]];

_text = _text trim [" ", 0];

if (_text isEqualTo "" || {(_text select [0, 1]) isNotEqualTo "["}) exitWith {[]};

// Strings, true and false and numbers made 0, then every [0,...,0] folded into a 0 until nothing changes - a readable
// array ends as one 0.
private _shape = ((((_text regexReplace ["""[^""]*""", "0"]) regexReplace ["true|false", "0"]) regexReplace ["\s", ""])
    regexReplace ["-?([0-9]+\.?[0-9]*|\.[0-9]+)([eE][-+]?[0-9]+)?", "0"]);
private _before = "";

while {_shape isNotEqualTo _before} do {
    _before = _shape;
    _shape = _shape regexReplace ["\[(0(,0)*)?\]", "0"];
};

if (_shape isNotEqualTo "0") exitWith {[]};

parseSimpleArray _text
