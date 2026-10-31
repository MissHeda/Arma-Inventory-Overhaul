#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The rows a radio adds to the inspect card: channel, frequency, the alternate channel when one is set,
 * and its state - active, switched off, or on. A prototype says it has no settings until someone carries it.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: The backpack object, for a long-range radio <OBJECT> (default: objNull)
 *
 * Return Value:
 * Rows, [[label, value], ...] <ARRAY>
 *
 * Example:
 * ["TFAR_anprc152_1", objNull] call aio_compat_tfar_fnc_inspectRows;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_holder", objNull, [objNull]]];

private _type = [_class] call FUNC(radioType);

if (_type isEqualTo 0) exitWith {[]};
if (_type isEqualTo 2) exitWith {[[LLSTRING(Inspect_Channel), LLSTRING(NotSetUp)]]};

private _settings = [_class, _holder] call FUNC(settings);

if (_settings isEqualTo []) exitWith {[]};

private _frequencies = _settings param [2, [], [[]]];
private _channel = _settings param [0, 0, [0]];
private _frequency = _frequencies param [_channel, "", [""]];
private _rows = [[LLSTRING(Inspect_Channel), str (_channel + 1)]];

if (_frequency isNotEqualTo "") then {
    _rows pushBack [LLSTRING(Inspect_Frequency), format [LLSTRING(Frequency), _frequency]];
};

private _additional = _settings param [5, -1, [0]];

if (_additional >= 0) then {
    private _alternate = str (_additional + 1);
    private _alternateFrequency = _frequencies param [_additional, "", [""]];

    if (_alternateFrequency isNotEqualTo "") then {
        _alternate = _alternate + "  ·  " + format [LLSTRING(Frequency), _alternateFrequency];
    };

    _rows pushBack [LLSTRING(Inspect_Alternate), _alternate];
};

// Its state: in use, switched off, or on.
private _active = if (_type isEqualTo 1) then {
    private _radio = [] call TFAR_fnc_activeSwRadio;

    !isNil "_radio" && {_class == _radio}
} else {
    private _radio = [] call TFAR_fnc_activeLrRadio;

    !isNil "_radio" && {_radio isEqualTo [_holder, "radio_settings"]}
};

private _state = if !(_settings param [9, true, [true]]) then {
    LLSTRING(Off)
} else {
    [LLSTRING(On), [LLSTRING(Active), LLSTRING(ActiveLr)] select (_type isEqualTo 3)] select _active
};

_rows pushBack [LLSTRING(Inspect_State), _state];

_rows
