#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What ACRE2 says of a radio's channel, in the words of its own inventory label (acre_sys_core_fnc_
 * getDescriptiveName): the AN/PRC-343 by block and channel, the AN/PRC-77 by its one frequency alone, the
 * SEM 52 SL by channel with H and P, the SEM 70 by channel and net when it is not on a single channel,
 * the others by channel number. The frequency in MHz after it, where the radio has one. Read only - a
 * radio ACRE has not set up yet (nobody carried it so far) has nothing to tell.
 *
 * Arguments:
 * 0: ACRE radio id, e.g. "ACRE_PRC152_ID_1" <STRING>
 *
 * Return Value:
 * [channel text, frequency text, switched on], [] while the radio has no data <ARRAY>
 *
 * Example:
 * ["ACRE_PRC152_ID_1"] call aio_compat_acre_fnc_channel;
 *
 * Public: No
 */

params [["_id", "", [""]]];

if (_id isEqualTo "" || {!([_id] call acre_sys_data_fnc_isRadioInitialized)}) exitWith {[]};

private _data = [_id, "getCurrentChannelData"] call acre_sys_data_fnc_dataEvent;
private _frequency = if (isNil "_data") then {nil} else {_data getVariable "frequencyTX"};
private _channel = "";

// ACRE's own way of naming the channel per radio.
switch ([_id] call acre_api_fnc_getBaseRadio) do {
    case "ACRE_PRC343": {
        private _raw = [_id, "getCurrentChannel"] call acre_sys_data_fnc_dataEvent;

        if (!isNil "_raw") then {
            _channel = format [LLSTRING(Block), floor (_raw / 16) + 1, (_raw % 16) + 1];
        };
    };

    // A single channel: its frequency says it all.
    case "ACRE_PRC77": {};

    case "ACRE_SEM52SL": {
        private _number = [_id] call acre_api_fnc_getRadioChannel;

        _channel = format [LLSTRING(Channel), [_number, "H", "P"] select (([13, 14] find _number) + 1)];
    };

    case "ACRE_SEM70": {
        if (!isNil "_data" && {(_data getVariable ["mode", ""]) isNotEqualTo "singleChannel"}) then {
            _channel = format [LLSTRING(Channel), [_id, "getCurrentChannel"] call acre_sys_data_fnc_dataEvent]
                + "  ·  " + format [LLSTRING(Net), _data getVariable ["networkID", ""]];
            _frequency = nil;
        };
    };

    default {
        _channel = format [LLSTRING(Channel), [_id] call acre_api_fnc_getRadioChannel];
    };
};

private _frequencyText = "";

if (!isNil "_frequency" && {_frequency isEqualType 0}) then {
    _frequencyText = format [LLSTRING(Frequency), [_frequency, 1, 3] call CBA_fnc_formatNumber];
};

[_channel, _frequencyText, ([_id] call acre_api_fnc_getRadioOnOffState) isNotEqualTo 0]
