#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What follows a radio's name at the mouse: its channel and the frequency of that channel - "Ch 3",
 * "152.6 MHz". Nothing for a radio that has no settings yet (a prototype, or one nobody carried so far)
 * and for anything that is no radio.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: The backpack object, for a long-range radio <OBJECT> (default: objNull)
 *
 * Return Value:
 * Texts to join after the name <ARRAY of STRINGs>
 *
 * Example:
 * ["TFAR_anprc152_1", objNull] call aio_compat_tfar_fnc_tooltip;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_holder", objNull, [objNull]]];

private _settings = [_class, _holder] call FUNC(settings);

if (_settings isEqualTo []) exitWith {[]};

private _channel = _settings param [0, 0, [0]];
private _frequency = (_settings param [2, [], [[]]]) param [_channel, "", [""]];
private _result = [format [LLSTRING(Channel), _channel + 1]];

if (_frequency isNotEqualTo "") then {
    _result pushBack format [LLSTRING(Frequency), _frequency];
};

_result
