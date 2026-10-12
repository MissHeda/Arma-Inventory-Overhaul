#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The parts a radio adds to the footer's hint: channel and frequency, the alternate channel when one is
 * set, "Active radio" for the short-range radio in use (or the long-range one), "Switched off" when it
 * is. A prototype says it has no settings until someone carries it.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: The backpack object, for a long-range radio <OBJECT> (default: objNull)
 *
 * Return Value:
 * Parts, [[text, theme colour key], ...] <ARRAY>
 *
 * Example:
 * ["TFAR_anprc152_1", objNull] call einv_compat_tfar_fnc_hintParts;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_holder", objNull, [objNull]]];

private _type = [_class] call FUNC(radioType);

if (_type isEqualTo 0) exitWith {[]};
if (_type isEqualTo 2) exitWith {[[LLSTRING(NotSetUp), "muted"]]};

private _settings = [_class, _holder] call FUNC(settings);

if (_settings isEqualTo []) exitWith {[]};

private _frequencies = _settings param [2, [], [[]]];
private _channel = _settings param [0, 0, [0]];
private _parts = [];

// The channel, with its frequency.
private _frequency = _frequencies param [_channel, "", [""]];
private _text = format [LLSTRING(Channel), _channel + 1];

if (_frequency isNotEqualTo "") then {
    _text = _text + "  ·  " + format [LLSTRING(Frequency), _frequency];
};

_parts pushBack [_text, "text2"];

// The alternate channel, when one is set (-1 for none).
private _additional = _settings param [5, -1, [0]];

if (_additional >= 0) then {
    private _alternate = format [LLSTRING(Alternate), _additional + 1];
    private _alternateFrequency = _frequencies param [_additional, "", [""]];

    if (_alternateFrequency isNotEqualTo "") then {
        _alternate = _alternate + "  ·  " + format [LLSTRING(Frequency), _alternateFrequency];
    };

    _parts pushBack [_alternate, "muted"];
};

// The one in use: the short-range radio in the radio slot, or the long-range radio TFAR talks through.
if (_type isEqualTo 1) then {
    private _active = [] call TFAR_fnc_activeSwRadio;

    if (!isNil "_active" && {_class == _active}) then {
        _parts pushBack [LLSTRING(Active), "gain"];
    };
} else {
    private _active = [] call TFAR_fnc_activeLrRadio;

    if (!isNil "_active" && {_active isEqualTo [_holder, "radio_settings"]}) then {
        _parts pushBack [LLSTRING(ActiveLr), "gain"];
    };
};

if !(_settings param [9, true, [true]]) then {
    _parts pushBack [LLSTRING(Off), "loss"];
};

_parts
