#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The large red warning over the game when this machine and the server do not run the same Arma Inventory Overhaul - as ACE
 * warns of a version mismatch: the server answered with another version ("mismatch", both named), or has not answered for a
 * minute and most likely does not run the mod ("silent"). Moves that go through the server stay off then (fnc_hubReady), which
 * a line in the window's hint alone did not get across (Steam report, 0.7.2: dropping "sometimes" does not work).
 *
 * A display of its own over the mission's, closed with its button or Esc; shown once per reason and mission, when the
 * mission's display is there.
 *
 * Arguments:
 * 0: Reason - "mismatch" or "silent" <STRING>
 * 1: The server's version <STRING> (default: "")
 * 2: This machine's version <STRING> (default: this build's)
 * 3: Again, although this reason was shown already - for a look at it <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["mismatch", "0.7.2", "0.7.18", true] call aio_gui_fnc_serverPopup;
 *
 * Public: No
 */

#define POPUP_RED [0.78, 0.09, 0.11, 1]
#define POPUP_RED_DARK [0.42, 0.04, 0.06, 1]
#define POPUP_BODY [0.09, 0.03, 0.04, 0.97]
#define POPUP_DIM [0.16, 0, 0, 0.6]

params [["_reason", "mismatch", [""]], ["_server", "", [""]], ["_own", QUOTE(VERSION_STR), [""]], ["_again", false, [false]]];

if (!hasInterface || {!(_reason in ["mismatch", "silent"])}) exitWith {};

if (isNil QGVAR(serverPopupsShown)) then {
    GVAR(serverPopupsShown) = [];
};

if (!_again && {_reason in GVAR(serverPopupsShown)}) exitWith {};

GVAR(serverPopupsShown) pushBackUnique _reason;

[{!isNull findDisplay 46 && {time > 0}}, {
    params ["_reason", "_server", "_own"];

    disableSerialization;

    private _display = (findDisplay 46) createDisplay "RscDisplayEmpty";

    if (isNull _display) exitWith {};

    // Two thirds of the screen wide, in the middle; heights in lines of the title's size.
    private _line = safeZoneH * 0.045;
    private _w = safeZoneW * 0.62;
    private _h = _line * 10.2;
    private _left = safeZoneX + (safeZoneW - _w) / 2;
    private _top = safeZoneY + (safeZoneH - _h) / 2;
    private _edge = _line * 0.12;
    private _pad = _line * 0.8;

    private _fnc_box = {
        params ["_rect", "_color"];

        private _ctrl = _display ctrlCreate ["RscText", -1];

        _ctrl ctrlSetPosition _rect;
        _ctrl ctrlSetBackgroundColor _color;
        _ctrl ctrlCommit 0;
        _ctrl
    };

    // The game behind it dimmed red, a red frame, the dark body, the red title bar.
    [[safeZoneX, safeZoneY, safeZoneW, safeZoneH], POPUP_DIM] call _fnc_box;
    [[_left - _edge * 0.75, _top - _edge, _w + _edge * 1.5, _h + _edge * 2], POPUP_RED] call _fnc_box;
    [[_left, _top, _w, _h], POPUP_BODY] call _fnc_box;
    [[_left, _top, _w, _line * 2.2], POPUP_RED] call _fnc_box;
    [[_left, _top + _line * 2.2, _w, _edge], POPUP_RED_DARK] call _fnc_box;

    private _title = _display ctrlCreate ["RscStructuredText", -1];

    _title ctrlSetPosition [_left, _top + _line * 0.42, _w, _line * 1.5];
    _title ctrlSetStructuredText parseText format [
        "<t align='center' font='PuristaBold' size='%2' color='#ffffff'>%1</t>",
        toUpper ([LLSTRING(ServerPopup_TitleMismatch), LLSTRING(ServerPopup_TitleSilent)] select (_reason isEqualTo "silent")),
        (_line * 1.25) / (getNumber (configFile >> "RscStructuredText" >> "size") max 0.001)
    ];
    _title ctrlCommit 0;

    private _body = if (_reason isEqualTo "silent") then {
        LLSTRING(ServerPopup_Silent)
    } else {
        format [LLSTRING(ServerPopup_Mismatch), _server, _own]
    };

    private _text = _display ctrlCreate ["RscStructuredText", -1];

    _text ctrlSetPosition [_left + _pad, _top + _line * 3, _w - _pad * 2, _line * 4.9];
    _text ctrlSetStructuredText parseText format [
        "<t align='center' font='RobotoCondensed' size='%2' color='#ffffff'>%1<br/><br/><t color='#ffb3b3'>%3</t></t>",
        _body, (_line * 0.82) / (getNumber (configFile >> "RscStructuredText" >> "size") max 0.001), LLSTRING(ServerPopup_Effect)
    ];
    _text ctrlCommit 0;

    private _button = _display ctrlCreate ["RscButtonMenu", -1];
    private _buttonW = _w * 0.24;

    _button ctrlSetPosition [_left + (_w - _buttonW) / 2, _top + _h - _line * 1.75, _buttonW, _line * 1.15];
    _button ctrlSetStructuredText parseText format [
        "<t align='center' font='PuristaBold' size='%2'>%1</t>", toUpper LLSTRING(ServerPopup_Close),
        (_line * 0.8) / (getNumber (configFile >> "RscButtonMenu" >> "size") max 0.001)
    ];
    _button ctrlSetBackgroundColor POPUP_RED;
    _button ctrlCommit 0;
    _button ctrlAddEventHandler ["ButtonClick", {(ctrlParent (_this select 0)) closeDisplay 1}];

    ctrlSetFocus _button;
}, [_reason, _server, _own]] call CBA_fnc_waitUntilAndExecute;
