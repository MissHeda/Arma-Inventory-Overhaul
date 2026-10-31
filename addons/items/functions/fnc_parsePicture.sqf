#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads the value of picture= (a rule) or einv_picture (an item's config): the texture an item shows in
 * place of the one its config names. The one reader of that value, as fnc_parseIcon is of icon=.
 *
 *   \A3\Weapons_F\Data\UI\gear_acc_rail_ca.paa      a path as the engine writes it
 *   /A3/Weapons_F/Data/UI/gear_acc_rail_ca.paa      the same with forward slashes, which is how a rules text
 *                                                   has it (fnc_encodeName with the path switch writes it:
 *                                                   a backslash would be cleaned out of the setting)
 *   my_mod/ui/kit%201_ca.paa                        a space is %20, any other special character %XX
 *
 * A rules text is read decoded (encoded = true), an item's config as it stands (encoded = false: its
 * spaces are spaces, a "%" is a "%"). Either way the answer is the path with backslashes, trimmed, at most
 * PICTURE_MAX characters. It needs a file name with an extension to be taken for a texture; whether the
 * file really exists is not asked here (fileExists is the engine's, and the server may not know the
 * mod) - fnc_getInfo asks it, and falls back to config's picture when there is none.
 *
 * Arguments:
 * 0: The value <STRING>
 * 1: The value is written the way a rules text has it <BOOL> (default: true)
 *
 * Return Value:
 * [path, notes] <ARRAY>
 *   path  - the texture path with backslashes, "" when it cannot be read <STRING>
 *   notes - what was left out, naming the value <ARRAY of STRING>
 *
 * Example:
 * ["/A3/Weapons_F/Data/UI/gear_acc_rail_ca.paa"] call einv_items_fnc_parsePicture;
 * // ["\A3\Weapons_F\Data\UI\gear_acc_rail_ca.paa", []]
 *
 * Public: No
 */

params [["_text", "", [""]], ["_encoded", true, [false]]];

private _path = if (_encoded) then {[_text, true] call FUNC(decodeName)} else {_text};

// Quotes and control characters cannot belong to a path; slashes are written the engine's way.
_path = toString ((toArray _path) apply {[_x, 92] select (_x == 47)} select {_x >= 32 && {_x != 34}});
_path = trim _path;

if (_path isEqualTo "") exitWith {
    [_path, ["picture= without a path - this part is left out"]]
};

if (count _path > PICTURE_MAX) exitWith {
    ["", [format ["picture=%1...: at most %2 characters - this part is left out", _path select [0, 40], PICTURE_MAX]]]
};

// A file name with an extension after the last backslash.
private _slash = _path find "\";
private _name = _path;

while {_slash >= 0} do {
    _name = _name select [_slash + 1];
    _slash = _name find "\";
};

private _dot = _name find ".";

if (_dot < 1 || {_dot >= count _name - 1}) exitWith {
    ["", [format ["picture=%1 is no texture path like a3\ui_f\data\gui\cfg\hints\gear_ca.paa - this part is left out", _path]]]
};

[_path, []]
