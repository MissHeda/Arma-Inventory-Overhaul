#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The left column of the Items and Containers steps: a search over the class index (fnc_buildIndex), by
 * class and by name, a row of chips for the kind, a switch for only the classes the own rules name, and
 * under them the cards found (fnc_drawResults). A click on a card picks the class for the editor beside
 * it - or, while the Containers step is picking the class another one takes after (GVAR(likePick)),
 * links the two.
 *
 * Typing redraws only the cards, a moment after the last key (GVAR(searchToken)): the field keeps the
 * cursor. The chips and the switch draw the whole step again.
 *
 * What it shows is kept per step in GVAR(listState): [search text, chip, own rules only, page].
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The step's group <CONTROL>
 * 2: Position [x, y, w, h], relative to the group <ARRAY>
 * 3: Theme <HASHMAP>
 * 4: Step: "items" or "containers" <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _group, [0, 0, 0.3, 0.5], _theme, "containers"] call einv_setup_fnc_drawClassList;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_group", "_rect", "_theme", ["_mode", "items", [""]]];
_rect params ["_left", "_top", "_width", "_height"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _accent = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];

if !(_mode in GVAR(listState)) then {
    GVAR(listState) set [_mode, ["", "all", false, 0]];
};

(GVAR(listState) get _mode) params ["_text", "_chip", "_ownOnly"];

private _cursorY = [_display, _group, _rect, "", _theme] call FUNC(uiCard);
private _innerX = _left + CARD_PAD_X;
private _innerW = _width - CARD_PAD_X * 2;
private _bottom = _top + _height - CARD_PAD_Y;

// ----- Picking the class another one takes after -----

if (_mode isEqualTo "containers" && {GVAR(likePick) isNotEqualTo ""}) then {
    private _cancelW = SQUARE(UNIT * 4.2);
    private _rowH = UNIT * 1.05;

    [
        _display, _group, [_innerX, _cursorY, _innerW - _cancelW - SQUARE(UNIT * 0.3), _rowH],
        [format [LLSTRING(List_PickLike), GVAR(likePick)], _innerW - _cancelW, _fontBold, TEXT_SMALL] call EFUNC(gui,fitText), TEXT_SMALL, _accent, _fontBold, 0
    ] call EFUNC(gui,uiLabel);

    [_display, _group, [_innerX + _innerW - _cancelW, _cursorY, _cancelW, _rowH], LLSTRING(List_Cancel), "", _theme, {
        GVAR(likePick) = "";

        [GVAR(step)] call FUNC(showStep);
    }, [], true, "ghost"] call FUNC(uiAction);

    _cursorY = _cursorY + _rowH + UNIT * 0.25;
};

// ----- Search -----

private _searchH = UNIT * 1.2;
private _search = [_display, _group, [_innerX, _cursorY, _innerW, _searchH], _text, LLSTRING(Items_Search), _theme, {
    params ["_text", "", "_mode"];

    private _state = GVAR(listState) get _mode;

    if (_text isEqualTo (_state select 0)) exitWith {};

    _state set [0, _text];
    _state set [3, 0];

    // Only the cards, and only once the typing stops for a moment.
    GVAR(searchToken) = GVAR(searchToken) + 1;

    [{
        params ["_token"];

        if (_token == GVAR(searchToken)) then {
            [] call FUNC(drawResults);
        };
    }, [GVAR(searchToken)], 0.15] call FUNC(defer);
}, _mode] call FUNC(uiEdit);

uiNamespace setVariable [QGVAR(searchEdit), _search select (count _search - 1)];

_cursorY = _cursorY + _searchH + UNIT * 0.35;

// ----- Kind chips -----

private _chips = if (_mode isEqualTo "containers") then {
    [
        ["all", LLSTRING(Groups_All)],
        ["uniform", LLSTRING(Tab_Uniforms)],
        ["vest", LLSTRING(Tab_Vests)],
        ["backpack", LLSTRING(Tab_Backpacks)],
        ["cargo", LLSTRING(Filter_Cargo)]
    ]
} else {
    [
        ["all", LLSTRING(Groups_All)],
        ["weapon", LLSTRING(Filter_Weapons)],
        ["magazine", LLSTRING(Filter_Magazines)],
        ["gear", LLSTRING(Filter_Gear)],
        ["item", LLSTRING(Filter_Items)]
    ]
};

private _chipH = UNIT * 0.95;
private _chipGap = SQUARE(UNIT * 0.25);
private _chipW = (_innerW - _chipGap * (count _chips - 1)) / count _chips;

{
    _x params ["_id", "_label"];

    [_display, _group, [_innerX + _forEachIndex * (_chipW + _chipGap), _cursorY, _chipW, _chipH], _label, _id isEqualTo _chip, _theme, {
        params ["", "_arguments"];
        _arguments params ["_mode", "_id"];

        private _state = GVAR(listState) get _mode;

        _state set [1, _id];
        _state set [3, 0];

        [GVAR(step)] call FUNC(showStep);
    }, [_mode, _id]] call FUNC(uiChip);
} forEach _chips;

_cursorY = _cursorY + _chipH + UNIT * 0.3;

// ----- Only classes with own rules -----

private _toggleH = UNIT * 1;

[_display, _group, [_innerX, _cursorY, _innerW, _toggleH], _ownOnly, _theme, {
    params ["_on", "_mode"];

    private _state = GVAR(listState) get _mode;

    _state set [2, _on];
    _state set [3, 0];

    [GVAR(step)] call FUNC(showStep);
}, _mode, true, LLSTRING(List_OwnOnly)] call FUNC(uiToggle);

_cursorY = _cursorY + _toggleH + UNIT * 0.3;

// ----- The cards -----

uiNamespace setVariable [QGVAR(resultsArgs), [_display, _group, [_innerX, _cursorY, _innerW, _bottom - _cursorY], _theme, _mode]];

[] call FUNC(drawResults);
