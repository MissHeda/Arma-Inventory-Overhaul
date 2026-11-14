#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The large red warning over the game when this machine and the server do not run the same Arma Inventory Overhaul - as ACE
 * warns of a version mismatch: the server answered with another version ("mismatch", both named), or has not answered for a
 * minute and most likely does not run the mod ("silent"). Moves that go through the server stay off then (fnc_hubReady), which
 * a line in the window's hint alone did not get across (Steam report, 0.7.2: dropping "sometimes" does not work). It says what
 * to do: with the server's version the newer one, repair the mod in the Arma 3 Launcher - Steam fetches the current one then -;
 * with this machine's the newer one, the server has to update.
 *
 * The same warning says that a newer version is on the Workshop ("outdated", fnc_updateCheck), also where the server runs
 * this machine's version: repair in the launcher, and on a server that one has to update too.
 *
 * A display of its own over the mission's, closed with its button or Esc; shown once per reason and mission, when the
 * mission's display is there.
 *
 * Arguments:
 * 0: Reason - "mismatch", "silent" or "outdated" <STRING>
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
#define POPUP_BODY [0.09, 0.03, 0.04, 0.97]
#define POPUP_DIM [0.16, 0, 0, 0.6]

// How long after it came up nothing closes it, in seconds.
#define POPUP_GUARD 1.5

params [["_reason", "mismatch", [""]], ["_server", "", [""]], ["_own", QUOTE(VERSION_STR), [""]], ["_again", false, [false]]];

if (!hasInterface || {!(_reason in ["mismatch", "silent", "outdated"])}) exitWith {};

// The server's other version says it already.
if (_reason isEqualTo "outdated" && {!_again} && {"mismatch" in (missionNamespace getVariable [QGVAR(serverPopupsShown), []])}) exitWith {};

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

    // Two thirds of the screen wide, in the middle, as high as its words need. Sizes in lines: _line is the body's
    // text height.
    private _line = safeZoneH * 0.034;
    private _w = safeZoneW * 0.62;
    private _left = safeZoneX + (safeZoneW - _w) / 2;
    private _edge = _line * 0.16;
    private _pad = _line * 1.6;
    private _innerW = _w - _pad * 2;
    private _index = ["mismatch", "silent", "outdated"] find _reason;

    private _fnc_box = {
        params ["_color"];

        private _ctrl = _display ctrlCreate ["RscText", -1];

        _ctrl ctrlSetBackgroundColor _color;
        _ctrl
    };

    // A block of words: as wide as the box inside its padding, its height as its lines need. Returns [control, height].
    private _base = getNumber (configFile >> "RscStructuredText" >> "size") max 0.001;

    private _fnc_words = {
        params ["_words", "_font", "_size", "_color"];

        private _ctrl = _display ctrlCreate ["RscStructuredText", -1];

        _ctrl ctrlSetPosition [_left + _pad, 0, _innerW, _line];
        _ctrl ctrlCommit 0;
        _ctrl ctrlSetStructuredText parseText format [
            "<t align='center' shadow='0' font='%2' size='%3' color='%4'>%1</t>", _words, _font, _size / _base, _color
        ];

        [_ctrl, ctrlTextHeight _ctrl]
    };

    // The backgrounds first, under the words: the game dimmed red, the red frame, the dark body, the red title bar.
    // Placed below, once the heights are known.
    private _dim = [POPUP_DIM] call _fnc_box;
    private _frame = [POPUP_RED] call _fnc_box;
    private _back = [POPUP_BODY] call _fnc_box;
    private _bar = [POPUP_RED] call _fnc_box;

    // Which of the two is behind: the server's version is the newer one - this machine's mod is out of date, which a
    // repair in the launcher mends -, or this machine's is - the server has to update. Compared number by number.
    private _fnc_parts = {(_this splitString ".") apply {parseNumber _x}};
    private _serverParts = _server call _fnc_parts;
    private _ownParts = _own call _fnc_parts;
    private _serverNewer = false;

    {
        private _mine = _ownParts param [_forEachIndex, 0];

        if (_x != _mine) exitWith {_serverNewer = _x > _mine};
    } forEach _serverParts;

    // The title never wider than the bar: a long one - another language - is set smaller until it fits.
    private _titleWords = toUpper ([LLSTRING(ServerPopup_TitleMismatch), LLSTRING(ServerPopup_TitleSilent), LLSTRING(ServerPopup_TitleOutdated)] select _index);
    private _titleSize = _line * 1.9;
    private _titleW = _titleWords getTextWidth ["PuristaBold", _titleSize];

    if (_titleW > _innerW) then {
        _titleSize = _titleSize * _innerW / _titleW;
    };

    private _mod = [toUpper LLSTRING(ServerPopup_Mod), "PuristaSemibold", _line * 0.8, "#ffd9d9"] call _fnc_words;
    private _title = [_titleWords, "PuristaBold", _titleSize, "#ffffff"] call _fnc_words;
    private _what = [
        [format [LLSTRING(ServerPopup_Mismatch), _server, _own], LLSTRING(ServerPopup_Silent), format [LLSTRING(ServerPopup_Outdated), _own]] select _index,
        "PuristaSemibold", _line * 1.15, "#ffffff"
    ] call _fnc_words;
    private _fix = [
        [
            [LLSTRING(ServerPopup_FixServer), LLSTRING(ServerPopup_FixRepair)] select _serverNewer,
            LLSTRING(ServerPopup_SilentFix),
            // On someone else's server, that one has to update as well.
            [LLSTRING(ServerPopup_FixUpdate), LLSTRING(ServerPopup_FixUpdateServer)] select (isMultiplayer && {!isServer})
        ] select _index,
        "PuristaMedium", _line, "#ffffff"
    ] call _fnc_words;

    private _barH = _line * 0.7 + (_mod select 1) + (_title select 1) + _line * 0.7;
    private _buttonH = _line * 1.5;
    private _h = _barH + _line * 1.3 + (_what select 1) + _line * 0.6 + (_fix select 1) + _line * 1.5 + _buttonH + _line * 1.1;
    private _top = safeZoneY + (safeZoneH - _h) / 2;

    {
        _x params ["_ctrl", "_rect"];

        _ctrl ctrlSetPosition _rect;
        _ctrl ctrlCommit 0;
    } forEach [
        [_dim, [safeZoneX, safeZoneY, safeZoneW, safeZoneH]],
        [_frame, [_left - _edge * 0.75, _top - _edge, _w + _edge * 1.5, _h + _edge * 2]],
        [_back, [_left, _top, _w, _h]],
        [_bar, [_left, _top, _w, _barH]]
    ];

    // The words, top down.
    private _cursor = _top + _line * 0.7;

    {
        _x params ["_block", "_gap"];
        _block params ["_ctrl", "_blockH"];

        _ctrl ctrlSetPosition [_left + _pad, _cursor, _innerW, _blockH];
        _ctrl ctrlCommit 0;
        _cursor = _cursor + _blockH + _gap;
    } forEach [
        [_mod, 0], [_title, _line * 0.7 + _line * 1.3], [_what, _line * 0.6], [_fix, _line * 1.5]
    ];

    private _button = _display ctrlCreate ["RscButtonMenu", -1];
    private _buttonW = _w * 0.26;

    _button ctrlSetPosition [_left + (_w - _buttonW) / 2, _cursor, _buttonW, _buttonH];
    _button ctrlSetStructuredText parseText format [
        "<t align='center' font='PuristaBold' size='%2'>%1</t>", toUpper LLSTRING(ServerPopup_Close),
        (_line * 1.05) / (getNumber (configFile >> "RscButtonMenu" >> "size") max 0.001)
    ];
    _button ctrlCommit 0;

    // It comes up in the middle of play, under whatever keys are being pressed: for its first moments no key and no press
    // of its button closes it - Space or Enter on the button, Esc -, or it would be gone before it was seen (0.7.22: a key
    // typed as it opened closed it at once).
    _display setVariable [QGVAR(popupFrom), diag_tickTime + POPUP_GUARD];
    _display displayAddEventHandler ["KeyDown", {diag_tickTime < ((_this select 0) getVariable [QGVAR(popupFrom), 0])}];
    _button ctrlAddEventHandler ["ButtonClick", {
        private _display = ctrlParent (_this select 0);

        if (diag_tickTime >= (_display getVariable [QGVAR(popupFrom), 0])) then {
            _display closeDisplay 1;
        };
    }];

    ctrlSetFocus _button;
}, [_reason, _server, _own]] call CBA_fnc_waitUntilAndExecute;
