#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The pager of a paged compartment (fnc_pageRanges): the bar under its cells - "Page 2 / 5" on the left, an arrow back
 * and an arrow on on the right, as the setup wizard's class lists have them (einv_setup_fnc_drawPager) - and, over the
 * edge of the page, the cue that more lies on other pages, which cannot be missed:
 *   - a fade over the last row of the page (the first, on the last page), PAGE_FADE_STEPS strips of rising strength, and
 *     on it a chip "+37 items on other pages" (a click on it turns to the next page, or back on the last one);
 *   - while the search field holds something, the chip says how many matches lie on other pages instead, and an arrow
 *     whose side of the pages has matches wears a small mark with their number (fnc_pageCounts) - a search is found on
 *     any page.
 * The bar and the cue are drawn again whenever the page turns or the search changes (the controls are the grid's
 * "pageControls"); the arrows are registered once per build in uiNamespace pageAreas, where a dragged item held over one
 * turns the page (fnc_updateDrag). A click runs a frame later (fnc_uiButton) and finds the grid by its place in the list
 * of grids of this build.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The grid of a paged compartment, with "pageRanges", "page" and "pageHeight" (fnc_drawCompartments) <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _grid] call einv_gui_fnc_drawPageBar;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_grid"];

{ctrlDelete _x} forEach (_grid getOrDefault ["pageControls", []]);
_grid set ["pageControls", []];

private _ranges = _grid getOrDefault ["pageRanges", []];
private _pages = count _ranges;

if (_pages < 2) exitWith {};

private _page = _grid getOrDefault ["page", 0];
private _theme = GVAR(theme);
private _parent = _grid get "parent";
private _cols = _grid get "cols";
private _cellW = _grid get "cellW";
private _cellH = _grid get "cellH";
(_grid get "rel") params ["_left", "_top"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _muted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
private _text2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _accent = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];
private _controls = [];

private _barH = UNIT * PAGE_BAR_H;
private _barW = _cols * _cellW - pixelW;
private _barTop = _top + (_grid getOrDefault ["pageHeight", 1]) * _cellH + COMPARTMENT_PAD_PX(_cellW) * pixelH + UNIT * PAGE_BAR_GAP;
private _arrowW = SQUARE(_barH);
private _gap = SQUARE(UNIT * 0.1);

([_grid] call FUNC(pageCounts)) params ["_counts", "_matches"];

private _searching = GVAR(filter) isNotEqualTo "";
private _before = 0;
private _after = 0;

for "_i" from 0 to (_pages - 1) do {
    if (_i < _page) then {_before = _before + (_matches select _i)};
    if (_i > _page) then {_after = _after + (_matches select _i)};
};

// ----- The bar -----
_controls append ([_display, _parent, [_left, _barTop, _barW, _barH], _theme getOrDefault ["slotCaptionBg", [0, 0, 0, 0.5]]] call FUNC(uiPanel));

private _arrowsW = _arrowW * 2 + _gap + SQUARE(UNIT * 0.15);
private _labelW = _barW - _arrowsW - SQUARE(_barH * 0.4);
private _size = UNIT * 0.4;

_controls pushBack ([
    _display, _parent, [_left + SQUARE(_barH * 0.4), _barTop, _labelW, _barH],
    [format [LLSTRING(Page_Label), _page + 1, _pages], _labelW, _font, _size] call FUNC(fitText), _size, _text2, _font, 0
] call FUNC(uiLabel));

// The arrows: no surface until the mouse is on one, as the wizard's. A click finds this grid again in this build.
private _ghost = createHashMap;
_ghost merge _theme;
_ghost set ["button", [0, 0, 0, 0]];

private _fnc_click = {
    params ["_direction", "_buttonId"];

    if (_direction != 1) exitWith {};

    (_buttonId splitString "|") params ["", "_index", "_step", ["_build", ""]];

    if (_build isNotEqualTo str GVAR(buildCount)) exitWith {};

    private _target = (uiNamespace getVariable [QGVAR(grids), []]) param [parseNumber _index, createHashMap];

    if (count _target == 0) exitWith {};

    [_target, parseNumber _step] call FUNC(turnPage);
};

private _gridIndex = (uiNamespace getVariable [QGVAR(grids), []]) find _grid;
private _areas = uiNamespace getVariable [QGVAR(pageAreas), []];
private _register = !(_grid getOrDefault ["pageAreasMade", false]);
private _arrowTop = _barTop;
private _nextX = _left + _barW - _arrowW - SQUARE(UNIT * 0.075);
private _prevX = _nextX - _arrowW - _gap;

{
    _x params ["_step", "_x0", "_icon", "_enabled", "_tip", "_mark"];

    _controls append ([
        _display, _parent, [_x0, _arrowTop, _arrowW, _barH], format ["page|%1|%2|%3", _gridIndex, _step, GVAR(buildCount)], "", _icon,
        _ghost, _fnc_click, !_enabled
    ] call FUNC(uiButton));

    (_controls select -1) ctrlSetTooltip _tip;

    // The search found something on that side: a mark with the number on the arrow's corner.
    if (_mark > 0) then {
        private _markH = _barH * 0.62;
        private _markW = SQUARE(_markH) max (((str _mark) getTextWidth [_fontBold, _markH * 0.62]) * TEXT_SLACK + SQUARE(_markH * 0.5));
        private _markRect = [_x0 + _arrowW - _markW * 0.8, _arrowTop - _markH * 0.35, _markW, _markH];

        _controls append ([_display, _parent, _markRect, _accent, _markH / 2] call FUNC(uiPanel));
        _controls pushBack ([
            _display, _parent, _markRect, str _mark, _markH * 0.62, _theme getOrDefault ["onAccent", [0.05, 0.05, 0.05, 1]], _fontBold, 2
        ] call FUNC(uiLabel));
    };

    if (_register) then {
        _areas pushBack createHashMapFromArray [
            ["rel", [_x0, _arrowTop]], ["parent", _parent], ["size", [_arrowW, _barH]], ["grid", _grid], ["step", _step]
        ];
    };
} forEach [
    [-1, _prevX, UI_TEX(icon_chevron_left_ca), _page > 0, LLSTRING(Page_Prev), _before],
    [1, _nextX, UI_TEX(icon_chevron_right_ca), _page < _pages - 1, LLSTRING(Page_Next), _after]
];

if (_register) then {
    uiNamespace setVariable [QGVAR(pageAreas), _areas];
    _grid set ["pageAreasMade", true];
};

// ----- The cue over the page's edge -----
private _window = _ranges select _page;
private _onPage = _counts select _page;
private _fnc_sum = {
    private _sum = 0;

    {_sum = _sum + _x} forEach _this;

    _sum
};
private _others = (_counts call _fnc_sum) - _onPage;
private _elsewhere = (_matches call _fnc_sum) - (_matches select _page);
private _chipText = "";

if (_searching && {_elsewhere > 0}) then {
    _chipText = format [[LLSTRING(Page_Hits), LLSTRING(Page_Hits_One)] select (_elsewhere == 1), _elsewhere];
} else {
    if (_others > 0) then {
        _chipText = format [[LLSTRING(Page_Other), LLSTRING(Page_Other_One)] select (_others == 1), _others];
    };
};

if (_chipText isNotEqualTo "") then {
    private _atTop = _page == _pages - 1;
    private _shownRows = (_window select 1) - (_window select 0);
    private _cueLeft = _left;
    private _cueW = _barW;
    private _stripH = _cellH * PAGE_FADE_ROWS / PAGE_FADE_STEPS;
    private _edge = [_top + _shownRows * _cellH - pixelH, _top] select _atTop;

    // The fade: strips of rising strength towards the edge of the page.
    for "_i" from 0 to (PAGE_FADE_STEPS - 1) do {
        private _alpha = 0.5 * (_i + 1) / PAGE_FADE_STEPS;
        private _stripTop = if (_atTop) then {_edge + (PAGE_FADE_STEPS - 1 - _i) * _stripH} else {_edge - (PAGE_FADE_STEPS - _i) * _stripH};
        private _strip = [_display, "EINV_PanelRect", _parent, [_cueLeft, _stripTop, _cueW, _stripH]] call FUNC(uiCreate);

        _strip ctrlSetBackgroundColor [0, 0, 0, _alpha];
        _controls pushBack _strip;
    };

    // The chip on it.
    private _chipH = UNIT * 0.5;
    private _chipSize = _chipH * 0.62;
    private _shown = [_chipText, _cueW - SQUARE(_chipH), _fontBold, _chipSize] call FUNC(fitText);
    private _chipW = (((_shown getTextWidth [_fontBold, _chipSize]) * TEXT_SLACK) + SQUARE(_chipH * 0.9)) min _cueW;
    private _chipTop = if (_atTop) then {_edge + pixelH * 2} else {_edge - _chipH - pixelH * 2};
    private _chipRect = [_cueLeft + (_cueW - _chipW) / 2, _chipTop, _chipW, _chipH];

    _controls append ([_display, _parent, _chipRect, [0, 0, 0, 0.82], _chipH / 2] call FUNC(uiPanel));
    _controls pushBack ([_display, _parent, _chipRect, _shown, _chipSize, _accent, _fontBold, 2] call FUNC(uiLabel));

    private _hit = [_display, "EINV_Hitbox", _parent, _chipRect] call FUNC(uiCreate);

    _hit ctrlSetTooltip LLSTRING(Page_Chip_Tooltip);
    _hit setVariable [QGVAR(key), [_gridIndex, [1, -1] select _atTop, GVAR(buildCount)]];
    _hit ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];

        (_ctrl getVariable [QGVAR(key), [-1, 0, -1]]) params ["_index", "_step", "_build"];

        [{
            params ["_index", "_step", "_build"];

            if (_build != GVAR(buildCount)) exitWith {};

            private _target = (uiNamespace getVariable [QGVAR(grids), []]) param [_index, createHashMap];

            if (count _target > 0) then {
                [_target, _step] call FUNC(turnPage);
            };
        }, [_index, _step, _build]] call FUNC(later);
    }];

    _controls pushBack _hit;
};

_grid set ["pageControls", _controls];
