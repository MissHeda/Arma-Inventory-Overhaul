#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws the catalog's column: made once per session and again when its rectangle or its view changes, in a
 * control that survives every build (IDC_KEEP) - the glass, the title, the switch between items and
 * loadouts, the bar of groups, categories and filters, and the pool of cards or the loadouts.
 *
 * Everything the catalog keeps about the column is in the HashMap uiNamespace GVAR(column): "display",
 * "group" (the kept control), "rect" (its place on the screen), "inner" (the room under the switch, in the
 * group), "titleCtrl", "countCtrl", "itemsGroup" and "loadoutsGroup" (the content of the view), "barH" and
 * "poolRect" (the places of the bar and of the pool in the items group); fnc_drawCatalog adds the pool, its
 * cards, the source grid and the scrolling.
 *
 * With "loadouts" as the fourth argument only the loadouts are drawn again, in the group that is there
 * (the search changed what they list).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Where, [x, y, w, h] on the screen <ARRAY>
 * 2: Theme <HASHMAP>
 * 3: Draw only "loadouts" again, "" for the whole column <STRING> (default: "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _rect, _theme] call einv_arsenal_fnc_drawColumn;
 *
 * Public: No
 */

disableSerialization;

params [
    ["_display", displayNull, [displayNull]], ["_rect", [0, 0, 0, 0], [[]]], ["_theme", createHashMap, [createHashMap]],
    ["_only", "", [""]]
];

private _column = uiNamespace getVariable [QGVAR(column), createHashMap];

if (isNull _display || {count _rect < 4}) exitWith {};

_rect params ["_left", "_top", "_width", "_height"];

private _padY = UNIT * 0.4;
private _padX = SQUARE(_padY);
private _innerW = _width - _padX * 2;
private _titleH = UNIT * 1.1;
private _switchH = UNIT * 1.2;
private _gap = UNIT * 0.3;
private _contentTop = _padY + _titleH + _gap + _switchH + _gap;
private _contentRect = [_padX, _contentTop, _innerW, (_height - _contentTop - _padY) max 0];

// A group made outside a build is not found by the build's hooks: the clicks over it must reach the window
// all the same, as they do over the columns (fnc_build).
private _fnc_hook = {
    params ["_group"];

    if !(_group getVariable [QEGVAR(gui,hooked), false]) then {
        _group setVariable [QEGVAR(gui,hooked), true];
        _group ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call EFUNC(gui,onMouseButton)}];
        _group ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call EFUNC(gui,onMouseButton)}];
        _group ctrlAddEventHandler ["MouseZChanged", {[_this] call EFUNC(gui,onMouseZ)}];
    };
};

private _fnc_content = {
    params ["_parent"];

    private _content = _display ctrlCreate ["EINV_Group", -1, _parent];

    _content ctrlSetPosition [_contentRect select 0, _contentRect select 1, _contentRect select 2, _contentRect select 3];
    _content ctrlCommit 0;
    [_content] call _fnc_hook;

    _content
};

// ----- Only the loadouts again -----
if (_only isEqualTo "loadouts") exitWith {
    private _group = _column getOrDefault ["group", controlNull];

    if (isNull _group) exitWith {};

    ctrlDelete (_column getOrDefault ["loadoutsGroup", controlNull]);

    private _content = [_group] call _fnc_content;

    _column set ["loadoutsGroup", _content];
    [_display, _content, [0, 0, _contentRect select 2, _contentRect select 3], _theme] call FUNC(drawLoadouts);
};

// ----- The whole column -----
ctrlDelete (_column getOrDefault ["group", controlNull]);
ctrlDelete (_display displayCtrl IDC_KEEP);

private _group = _display ctrlCreate ["EINV_Group", IDC_KEEP];

_group ctrlSetPosition [SNAP_X(_left), SNAP_Y(_top), SNAP_W(_width), SNAP_H(_height)];
_group ctrlCommit 0;
[_group] call _fnc_hook;

_column set ["display", _display];
_column set ["group", _group];
_column set ["rect", _rect];
_column set ["inner", _contentRect];

[
    _display, _group, [0, 0, _width, _height], _theme getOrDefault ["panel", []],
    _theme getOrDefault ["radius", 0], _theme getOrDefault ["panelBorder", []]
] call EFUNC(gui,uiPanel);

private _text = _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]];
private _text2 = _theme getOrDefault ["text2", [0.639, 0.675, 0.725, 1]];
private _muted = _theme getOrDefault ["muted", [0.412, 0.443, 0.494, 1]];
private _font = _theme getOrDefault ["font", "RobotoCondensed"];
private _fontBold = _theme getOrDefault ["fontBold", "RobotoCondensedBold"];

// ----- The title: the box, and how many items the list holds -----
private _box = GVAR(box);

private _name = switch (true) do {
    case (GVAR(full)): {LLSTRING(Title_Full)};
    case (GVAR(source) isEqualTo "bi"): {LLSTRING(Title_Vanilla)};
    case (!isNull _box && {_box isNotEqualTo GVAR(center)}): {
        private _title = getText (configOf _box >> "displayName");

        [_title, LLSTRING(Title)] select (_title isEqualTo "")
    };
    default {LLSTRING(Title)};
};

private _titleY = _padY;
private _countW = (_innerW * 0.34);
private _textX = _padX + SQUARE(_titleH * 0.7) + SQUARE(_titleH * 0.3);

[
    _display, _group, [_padX, _titleY + _titleH * 0.15, SQUARE(_titleH * 0.7), _titleH * 0.7], UI_TEX(icon_crate_ca), _text2
] call EFUNC(gui,uiIcon);

private _titleSize = UNIT * 0.66;
private _titleCtrl = [
    _display, _group, [_textX, _titleY, _innerW - (_textX - _padX) - _countW, _titleH],
    [_name, _innerW - (_textX - _padX) - _countW, _fontBold, _titleSize] call EFUNC(gui,fitText), _titleSize, _text, _fontBold, 0
] call EFUNC(gui,uiLabel);

private _countCtrl = [
    _display, _group, [_padX + _innerW - _countW, _titleY, _countW, _titleH], "", UNIT * 0.5, _muted, _font, 1
] call EFUNC(gui,uiLabel);

_column set ["titleCtrl", _titleCtrl];
_column set ["countCtrl", _countCtrl];

// ----- The switch between the items and the loadouts -----
[
    _display, _group, [_padX, _titleY + _titleH + _gap, _innerW, _switchH],
    [LLSTRING(View_Items), LLSTRING(View_Loadouts)], ["items", "loadouts"] find GVAR(view), _theme,
    {
        params ["_index"];

        private _view = ["items", "loadouts"] select _index;

        if (_view isEqualTo GVAR(view)) exitWith {};

        GVAR(view) = _view;

        // The column is made anew for the other view, and the window with it: what a drop can land on
        // (the cards, the give-back zone) goes by the view.
        private _column = uiNamespace getVariable [QGVAR(column), createHashMap];

        ctrlDelete (_column getOrDefault ["group", controlNull]);
        _column set ["group", controlNull];
        [uiNamespace getVariable [QEGVAR(gui,display), displayNull]] call EFUNC(gui,build);
    }
] call EFUNC(setup,uiSegmented);

// ----- The content of the view -----
_column set ["barH", UNIT * 4.85];
_column set ["itemsGroup", controlNull];
_column set ["loadoutsGroup", controlNull];
_column set ["pool", controlNull];
_column set ["cards", []];

if (GVAR(view) isEqualTo "loadouts") then {
    private _content = [_group] call _fnc_content;

    _column set ["loadoutsGroup", _content];
    [_display, _content, [0, 0, _contentRect select 2, _contentRect select 3], _theme] call FUNC(drawLoadouts);
} else {
    private _content = [_group] call _fnc_content;
    private _barH = _column get "barH";

    _column set ["itemsGroup", _content];
    _column set ["poolRect", [0, _barH + _gap, _contentRect select 2, ((_contentRect select 3) - _barH - _gap) max 0]];

    call FUNC(drawCatalogBar);
    call FUNC(drawCatalog);
};
