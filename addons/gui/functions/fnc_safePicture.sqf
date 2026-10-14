#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A picture path from a config, as far as it can be shown: a file path - with a backslash or a slash -
 * ending in .paa, .jpg or .png, or with no ending when the .paa of it exists (the engine adds .paa
 * itself), and a file that exists; a procedural texture ("#(...)") as it is. Anything else gives "": a
 * placeholder like picture = "picturething" in some mod's class made the engine pop up "Picture
 * picturething not found" over the window (Mia, 0.4.0), and so does a path to a file that is not there.
 *
 * Each path is looked at once (fileExists, with and without its leading backslash) and the answer kept
 * for the session (uiNamespace einv_gui_pictures): a draw only looks it up.
 *
 * Arguments:
 * 0: Picture path <STRING>
 *
 * Return Value:
 * The path, or "" when it cannot be shown <STRING>
 *
 * Example:
 * [getText (configFile >> "CfgWeapons" >> "arifle_MX_F" >> "picture")] call einv_gui_fnc_safePicture;
 *
 * Public: No
 */

params [["_path", "", [""]]];

if (_path isEqualTo "") exitWith {""};

// The game's own colour fills and the like: no file behind them.
if ((_path select [0, 2]) isEqualTo "#(") exitWith {_path};

private _known = uiNamespace getVariable QGVAR(pictures);

if (isNil "_known") then {
    _known = createHashMap;
    uiNamespace setVariable [QGVAR(pictures), _known];
};

private _key = toLowerANSI _path;
private _answer = _known get _key;

if (!isNil "_answer") exitWith {_answer};

// The engine reads a path with or without its leading backslash; fileExists is asked both ways.
private _fnc_exists = {
    params ["_file"];

    private _other = if ((_file select [0, 1]) isEqualTo "\") then {_file select [1]} else {"\" + _file};

    fileExists _file || {fileExists _other}
};

_answer = call {
    if ((_key find "\") < 0 && {(_key find "/") < 0}) exitWith {""};

    if (count _key > 4 && {(_key select [count _key - 4]) in [".paa", ".jpg", ".png"]}) exitWith {
        ["", _path] select ([_path] call _fnc_exists)
    };

    // No ending at all after the last folder: the engine looks for the .paa.
    private _name = (_key splitString "\/") param [count (_key splitString "\/") - 1, ""];

    if ((_name find ".") < 0 && {[_path + ".paa"] call _fnc_exists}) exitWith {_path};

    ""
};

_known set [_key, _answer];

_answer
