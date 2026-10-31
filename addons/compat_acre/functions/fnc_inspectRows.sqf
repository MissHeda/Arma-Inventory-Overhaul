#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The rows a radio adds to the inspect card: channel, frequency, and its state - active, switched off, or
 * on. A base radio says it has no settings until someone carries it.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: Unused, the same arguments as the other radio addons take <OBJECT> (default: objNull)
 *
 * Return Value:
 * Rows, [[label, value], ...] <ARRAY>
 *
 * Example:
 * ["ACRE_PRC152_ID_1", objNull] call aio_compat_acre_fnc_inspectRows;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_holder", objNull, [objNull]]];

private _type = [_class] call FUNC(radioType);

if (_type isEqualTo 0) exitWith {[]};
if (_type isEqualTo 2) exitWith {[[LLSTRING(Inspect_Channel), LLSTRING(NotSetUp)]]};

([_class] call FUNC(channel)) params [["_channel", ""], ["_frequency", ""], ["_on", true]];

if (_channel isEqualTo "" && {_frequency isEqualTo ""}) exitWith {[]};

private _rows = [];

if (_channel isNotEqualTo "") then {
    _rows pushBack [LLSTRING(Inspect_Channel), _channel];
};

if (_frequency isNotEqualTo "") then {
    _rows pushBack [LLSTRING(Inspect_Frequency), _frequency];
};

private _state = if (!_on) then {
    LLSTRING(Off)
} else {
    [LLSTRING(On), LLSTRING(Active)] select (_class == ([] call acre_api_fnc_getCurrentRadio))
};

_rows pushBack [LLSTRING(Inspect_State), _state];

_rows
