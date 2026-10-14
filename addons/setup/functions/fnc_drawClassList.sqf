#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The left column of the Items and Containers steps: a search over the class index (fnc_buildIndex), by
 * class and by name, with wildcards (fnc_searchFilter), a switch between the list and the tree view, a row
 * of chips for the kind, a switch for only the classes the own rules name, and under them the cards found
 * (fnc_drawResults) or the tree (fnc_drawTree). A click on a card picks the class for the editor beside
 * it; a click on a node of the tree picks it with everything built on it.
 *
 * Typing redraws only the cards, a moment after the last key (GVAR(searchToken)): the field keeps the
 * cursor. The chips and the switches draw the whole step again.
 *
 * What it shows is kept per step in GVAR(listState): [search text, chip, own rules only, page], and in
 * GVAR(treeState): whether the tree view is on, the class it starts at and its page.
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

if !(_mode in GVAR(listState)) then {
    GVAR(listState) set [_mode, ["", "all", false, 0]];
};

if !(_mode in GVAR(treeState)) then {
    GVAR(treeState) set [_mode, createHashMapFromArray [["on", false], ["root", ""], ["page", 0]]];
};

(GVAR(listState) get _mode) params ["_text", "_chip", "_ownOnly"];

private _treeView = (GVAR(treeState) get _mode) getOrDefault ["on", false];

private _cursorY = [_display, _group, _rect, "", _theme] call FUNC(uiCard);
private _innerX = _left + CARD_PAD_X;
private _innerW = _width - CARD_PAD_X * 2;
private _bottom = _top + _height - CARD_PAD_Y;

// ----- Search, and the list or the tree -----

private _searchH = UNIT * 1.2;
private _viewW = SQUARE(UNIT * 7);
private _search = [_display, _group, [_innerX, _cursorY, _innerW - _viewW - SQUARE(UNIT * 0.3), _searchH], _text, LLSTRING(Items_Search), _theme, {
    params ["_text", "", "_mode"];

    private _state = GVAR(listState) get _mode;

    if (_text isEqualTo (_state select 0)) exitWith {};

    _state set [0, _text];
    _state set [3, 0];
    (GVAR(treeState) get _mode) set ["page", 0];

    // Only the cards (or the tree), and only once the typing stops for a moment.
    GVAR(searchToken) = GVAR(searchToken) + 1;

    [{
        params ["_token"];

        if (_token == GVAR(searchToken)) then {
            [] call FUNC(drawResults);
        };
    }, [GVAR(searchToken)], 0.15] call FUNC(defer);
}, _mode] call FUNC(uiEdit);

uiNamespace setVariable [QGVAR(searchEdit), _search select (count _search - 1)];

[
    _display, _group, [_innerX + _innerW - _viewW, _cursorY, _viewW, _searchH], [LLSTRING(View_List), LLSTRING(View_Tree)], [0, 1] select _treeView, _theme, {
        params ["_index", "_mode"];

        private _state = GVAR(treeState) get _mode;

        _state set ["on", _index == 1];
        _state set ["page", 0];

        // The tree of the class picked.
        if (_index == 1) then {
            _state set ["root", toLowerANSI (GVAR(selection) getOrDefault [_mode, ""])];
        };

        [GVAR(step)] call FUNC(showStep);
    }, _mode
] call FUNC(uiSegmented);

_cursorY = _cursorY + _searchH + UNIT * 0.35;

// ----- Kind chips: the list only, a tree is of one class -----

if (!_treeView) then {
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
};

// ----- Only classes with own rules -----

private _toggleH = UNIT * 1;

[_display, _group, [_innerX, _cursorY, _innerW, _toggleH], _ownOnly, _theme, {
    params ["_on", "_mode"];

    private _state = GVAR(listState) get _mode;

    _state set [2, _on];
    _state set [3, 0];
    (GVAR(treeState) get _mode) set ["page", 0];

    [GVAR(step)] call FUNC(showStep);
}, _mode, true, [LLSTRING(List_OwnOnlyItems), LLSTRING(List_OwnOnlyContainers)] select (_mode isEqualTo "containers")] call FUNC(uiToggle);

_cursorY = _cursorY + _toggleH + UNIT * 0.3;

// ----- The cards -----

uiNamespace setVariable [QGVAR(resultsArgs), [_display, _group, [_innerX, _cursorY, _innerW, _bottom - _cursorY], _theme, _mode]];

[] call FUNC(drawResults);
