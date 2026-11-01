#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The bar's per-frame handler (started by fnc_hudPing). Makes the bar when it is wanted (fnc_hudWanted)
 * and fades it in; fades it out when it is not, and stops once it is gone - unless the setting is
 * "always", which keeps the handler for when the bar is wanted again.
 *
 * While the bar shows: every moment (HUD_COUNT_INTERVAL) the counts and keys are read, and the boxes
 * painted again (fnc_hudDraw) when anything of it changed. Every frame:
 *   - the bar along the bottom of the box of a treatment or a meal mirrors ACE's progress bar; the slot
 *     is free again once that is gone
 *   - the bar of a throwable counts down the two seconds ACE keeps between two throws
 *   - the box of the slot in use, or of the bound throwable in the hand, is lit in the text colour
 *   - the box of a refused press is lit in the error colour until HUD_FLASH has passed
 *   - the line over the boxes shows its message until HUD_MESSAGE_TIME has passed
 *
 * Arguments (a per-frame handler's):
 * 0: Arguments - not used <ARRAY>
 * 1: Handler id <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[], _handlerId] call aio_hotbar_fnc_hudFrame;
 *
 * Public: No
 */

disableSerialization;

params ["", "_handler"];

private _now = diag_tickTime;

// ----- Not wanted: fade out, then go -----

if (!(call FUNC(hudWanted))) exitWith {
    private _ctrls = uiNamespace getVariable [QGVAR(hudCtrls), createHashMap];

    if (GVAR(hudVisible)) then {
        private _group = _ctrls getOrDefault ["group", controlNull];

        _group ctrlSetFade 1;
        _group ctrlCommit HUD_FADE;

        GVAR(hudVisible) = false;
        GVAR(hudHideAt) = _now + HUD_FADE;
    } else {
        if (_now > GVAR(hudHideAt) && {GVAR(hudMode) != 2}) then {
            [_handler] call CBA_fnc_removePerFrameHandler;
            GVAR(hudPFH) = -1;

            QGVAR(hud) cutText ["", "PLAIN"];
        };
    };
};

// ----- Wanted: make it, fade it in -----

private _display = uiNamespace getVariable [QGVAR(hud), displayNull];

if (isNull _display) then {
    _display = call FUNC(hudCreate);
};

if (isNull _display) exitWith {};

private _ctrls = uiNamespace getVariable [QGVAR(hudCtrls), createHashMap];
private _slotCtrls = _ctrls getOrDefault ["slots", []];

if (_slotCtrls isEqualTo []) exitWith {};

if (!GVAR(hudVisible)) then {
    private _group = _ctrls get "group";

    _group ctrlSetFade 0;
    _group ctrlCommit HUD_FADE;

    GVAR(hudVisible) = true;
};

// ----- What the boxes show -----

if (_now >= GVAR(nextCount)) then {
    GVAR(nextCount) = _now + HUD_COUNT_INTERVAL;

    private _counts = call FUNC(counts);
    private _keys = [0, 1, 2, 3, 4, 5, 6] apply {[_x] call FUNC(keyName)};
    private _signature = str [GVAR(slots), _counts, _keys];

    if (_signature isNotEqualTo GVAR(hudSignature)) then {
        GVAR(hudSignature) = _signature;

        [_counts] call FUNC(hudDraw);
    };
};

// ----- A treatment or a meal under way: the bar mirrors ACE's -----

private _busyIndex = -1;

if (GVAR(busy) isNotEqualTo []) then {
    GVAR(busy) params ["_index", "_started"];

    private _progress = uiNamespace getVariable ["ace_common_ctrlProgressBar", controlNull];
    private _bar = (_slotCtrls param [_index, createHashMap]) getOrDefault ["bar", controlNull];

    if (!isNull _progress) then {
        _busyIndex = _index;
        _bar progressSetPosition (progressPosition _progress);
    } else {
        // Over - or never began: ACE needs a moment to open its bar.
        if (_now > _started + 0.2) then {
            _bar progressSetPosition 0;
            GVAR(busy) = [];
        } else {
            _busyIndex = _index;
        };
    };
};

// ----- A throwable: the gap to the next throw, and whether it is in the hand -----

private _held = "";

if (PLAYER_UNIT getVariable ["ace_advanced_throwing_inHand", false]) then {
    _held = (currentThrowable PLAYER_UNIT) param [0, ""];
};

private _cooling = missionNamespace getVariable ["ace_advanced_throwing_enabled", false];
private _lastThrown = PLAYER_UNIT getVariable ["ace_advanced_throwing_lastThrownTime", -10];

// ----- A refused press -----

private _flashIndex = -1;

if (GVAR(flash) isNotEqualTo []) then {
    if (_now < (GVAR(flash) select 2)) then {
        _flashIndex = GVAR(flash) select 0;
    } else {
        GVAR(flash) = [];
    };
};

// ----- Paint the boxes that are lit -----

private _states = _ctrls getOrDefault ["states", []];

{
    private _ctrl = _slotCtrls select _forEachIndex;
    private _class = GVAR(slots) select _forEachIndex;
    private _isThrow = (GVAR(hudKinds) param [_forEachIndex, ""]) isEqualTo "throw";

    if (_isThrow && {_cooling}) then {
        (_ctrl get "bar") progressSetPosition ((((_lastThrown + THROW_COOLDOWN - CBA_missionTime) / THROW_COOLDOWN) max 0) min 1);
    };

    private _state = "base";

    if (_forEachIndex == _busyIndex || {_isThrow && {_held isNotEqualTo ""} && {_class == _held}}) then {
        _state = "active";
    };

    if (_forEachIndex == _flashIndex) then {
        _state = "flash";
    };

    if (_state isNotEqualTo (_states param [_forEachIndex, "base"])) then {
        _states set [_forEachIndex, _state];

        private _color = switch (_state) do {
            case "flash": {GVAR(hudColors) getOrDefault ["error", [0.8, 0, 0, 0.8]]};
            case "active": {
                private _lit = +(GVAR(hudColors) getOrDefault ["text", [1, 1, 1, 0.8]]);
                _lit set [3, 0.35];
                _lit
            };
            default {
                private _background = +(GVAR(hudColors) getOrDefault ["bcg", [0, 0, 0, 0.5]]);

                if (_class isEqualTo "") then {
                    _background set [3, (_background select 3) / 2];
                };

                _background
            };
        };

        (_ctrl get "box") ctrlSetBackgroundColor _color;
    };
} forEach GVAR(slots);

// ----- The line over the boxes -----

private _message = _ctrls get "message";

if (GVAR(message) isNotEqualTo []) then {
    GVAR(message) params ["_words", "_colour", "_until"];

    if (_now < _until) then {
        if ((_ctrls getOrDefault ["shown", ""]) isNotEqualTo _words) then {
            // Structured text reads "<" and "&" as its own.
            private _safe = (_words regexReplace ["&", "&amp;"]) regexReplace ["<", "&lt;"];
            private _hex = (GVAR(hudColors) getOrDefault [_colour, [1, 1, 1, 0.8]]) call BIS_fnc_colorRGBAtoHTML;

            _message ctrlSetStructuredText parseText format ["<t color='%1' align='center'>%2</t>", _hex, _safe];
            _message ctrlSetFade 0;
            _message ctrlCommit 0;

            _ctrls set ["shown", _words];
        };
    } else {
        _message ctrlSetFade 1;
        _message ctrlCommit HUD_FADE;

        _ctrls set ["shown", ""];
        GVAR(message) = [];
    };
};
