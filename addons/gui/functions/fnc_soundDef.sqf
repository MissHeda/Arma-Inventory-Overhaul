#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What an action of a family sounds like, read from CfgAioSounds once and kept: a HashMap with
 *   "variants" - the variants, each a list of layers [file, volume, lowest pitch, highest pitch, offset,
 *                length, delay] <ARRAY>
 *   "fallback" - the same, played when no layer of the variant could be found <ARRAY>
 *   "world"    - others hear it as well <BOOL>
 *   "range"    - how far, in metres (default 12) <NUMBER>
 *   "worldGap" - at most one such sound to others in this many seconds <NUMBER>
 *   "volume", "pitch" - what the whole sound is scaled by (default 1) <NUMBER>
 *
 * The action of the family, else of Default, else nothing. An action that sounds as another one
 * (use = "x") is that one as this family has it, times its own volume and pitch, with world, range and
 * worldGap replaced where it names them; no deeper than three steps.
 *
 * Arguments:
 * 0: Family, a class of CfgAioSounds <STRING>
 * 1: Action <STRING>
 * 2: How deep the "use" chain went <NUMBER> (default: 0)
 *
 * Return Value:
 * The definition <HASHMAP>
 *
 * Example:
 * ["rifle", "lift"] call aio_gui_fnc_soundDef;
 *
 * Public: No
 */

params [["_family", "", [""]], ["_action", "", [""]], ["_depth", 0, [0]]];

private _key = _family + "|" + _action;
private _cached = GVAR(soundDefs) get _key;

if (!isNil "_cached") exitWith {_cached};

private _root = configFile >> "CfgAioSounds";
private _config = _root >> _family >> _action;

// An unknown family sounds like Default.
if (!isClass _config) then {
    _config = _root >> "Default" >> _action;
};

private _def = createHashMap;

if (!isClass _config) exitWith {
    GVAR(soundDefs) set [_key, _def];

    _def
};

private _fnc_number = {
    params ["_name", "_default"];

    if (isNumber (_config >> _name)) then {getNumber (_config >> _name)} else {_default}
};

private _use = getText (_config >> "use");

if (_use isNotEqualTo "" && {_depth < 3}) then {
    _def = +([_family, _use, _depth + 1] call FUNC(soundDef));

    _def set ["volume", (_def getOrDefault ["volume", 1]) * (["volume", 1] call _fnc_number)];
    _def set ["pitch", (_def getOrDefault ["pitch", 1]) * (["pitch", 1] call _fnc_number)];

    {
        if (isNumber (_config >> _x)) then {
            _def set [_x, getNumber (_config >> _x)];
        };
    } forEach ["range", "worldGap"];

    if (isNumber (_config >> "world")) then {
        _def set ["world", getNumber (_config >> "world") > 0];
    };
} else {
    _def = createHashMapFromArray [
        ["variants", getArray (_config >> "variants")],
        ["fallback", getArray (_config >> "fallback")],
        ["world", (["world", 0] call _fnc_number) > 0],
        ["range", ["range", 12] call _fnc_number],
        ["worldGap", ["worldGap", NOISE_GAP] call _fnc_number],
        ["volume", ["volume", 1] call _fnc_number],
        ["pitch", ["pitch", 1] call _fnc_number]
    ];
};

GVAR(soundDefs) set [_key, _def];

_def
