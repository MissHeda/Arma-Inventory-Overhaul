#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The parts a radio adds to the footer's hint: channel and frequency, "Active radio" for the one in use,
 * "Switched off" when it is. A base radio says it has no settings until someone carries it, and the dummy
 * radio ACRE2 keeps in the radio slot says why the slot cannot be used.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: Unused, the same arguments as the other radio addons take <OBJECT> (default: objNull)
 *
 * Return Value:
 * Parts, [[text, theme colour key], ...] <ARRAY>
 *
 * Example:
 * ["ACRE_PRC152_ID_1", objNull] call aio_compat_acre_fnc_hintParts;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_holder", objNull, [objNull]]];

if (_class == "ItemRadioAcreFlagged") exitWith {[[LLSTRING(SlotKept), "muted"]]};

private _type = [_class] call FUNC(radioType);

if (_type isEqualTo 0) exitWith {[]};
if (_type isEqualTo 2) exitWith {[[LLSTRING(NotSetUp), "muted"]]};

([_class] call FUNC(channel)) params [["_channel", ""], ["_frequency", ""], ["_on", true]];

if (_channel isEqualTo "" && {_frequency isEqualTo ""}) exitWith {[]};

private _parts = [];
private _text = [_channel, _frequency] select {_x isNotEqualTo ""};

_parts pushBack [_text joinString "  ·  ", "text2"];

if (_class == ([] call acre_api_fnc_getCurrentRadio)) then {
    _parts pushBack [LLSTRING(Active), "gain"];
};

if (!_on) then {
    _parts pushBack [LLSTRING(Off), "loss"];
};

_parts
