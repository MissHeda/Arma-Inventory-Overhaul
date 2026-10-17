#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The pager of a paged compartment (fnc_pageRanges): a bar under its cells, PAGE_BAR_H of a UNIT tall, and nothing else - no
 * cue, no fade and no chip lies over the tiles. Its left half turns back and its right half turns on: the whole half is the
 * button (it lights up under the mouse, a hit area as large as the half), with an arrow at its outer end. In the middle the
 * bar says where it stands and what lies elsewhere, in one line:
 *   "Page 2 / 5  |  +180 items on other pages  |  12 queued"
 * - the items on the pages not shown, the entries of the hands' queue waiting on tiles of those pages (they have no circle
 * while their tile is not drawn, so they are counted here), and, while the search field holds something, the matches on
 * other pages instead of the items (fnc_pageCounts) - a search is found on any page. An arrow whose side of the pages has
 * matches wears a small mark with their number.
 * The bar is drawn again whenever the page turns, the search or the queue changes what it says; one that would look as it
 * does (the grid's "pageSig") is left alone, so a redraw of the tiles does not flicker it (the controls are the grid's
 * "pageControls"). The outer PAGE_ZONE of the bar on each side is registered once per build in uiNamespace pageAreas,
 * where a dragged item held over it turns the page (fnc_updateDrag). A click runs a frame later (fnc_uiButton) and finds the
 * grid by its place in the list of grids of this build.
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

private _ranges = _grid getOrDefault ["pageRanges", []];
private _pages = count _ranges;

if (_pages < 2) exitWith {
    {ctrlDelete _x} forEach (_grid getOrDefault ["pageControls", []]);
    _grid set ["pageControls", []];
};

private _page = _grid getOrDefault ["page", 0];
private _theme = GVAR(theme);

([_grid] call FUNC(pageCounts)) params ["_counts", "_matches"];

private _searching = GVAR(filter) isNotEqualTo "";
private _before = 0;
private _after = 0;

for "_i" from 0 to (_pages - 1) do {
    if (_i < _page) then {_before = _before + (_matches select _i)};
    if (_i > _page) then {_after = _after + (_matches select _i)};
};

// What the bar says: the page, what lies on the others, what of the hands' queue waits on them.
private _fnc_sum = {
    private _sum = 0;

    {_sum = _sum + _x} forEach _this;

    _sum
};
private _others = (_counts call _fnc_sum) - (_counts select _page);
private _elsewhere = (_matches call _fnc_sum) - (_matches select _page);
private _queued = 0;

{
    if (_x getOrDefault ["offPage", false] && {(_x getOrDefault ["queued", 0]) != 0}) then {
        _queued = _queued + 1;
    };
} forEach (_grid getOrDefault ["tiles", []]);

private _parts = [format [LLSTRING(Page_Label), _page + 1, _pages]];

if (_searching && {_elsewhere > 0}) then {
    _parts pushBack format [[LLSTRING(Page_Hits), LLSTRING(Page_Hits_One)] select (_elsewhere == 1), _elsewhere];
} else {
    if (_others > 0) then {
        _parts pushBack format [[LLSTRING(Page_Other), LLSTRING(Page_Other_One)] select (_others == 1), _others];
    };
};

if (_queued > 0) then {
    _parts pushBack format [LLSTRING(Page_Queued), _queued];
};

private _text = _parts joinString "  |  ";

// Nothing it says changed since it was drawn, and the controls are all there: left as it is.
private _signature = [GVAR(buildCount), _page, _pages, _text, _before, _after];
private _drawn = _grid getOrDefault ["pageControls", []];

if (_drawn isNotEqualTo [] && {(_grid getOrDefault ["pageSig", []]) isEqualTo _signature} && {_drawn findIf {isNull _x} < 0}) exitWith {};

{ctrlDelete _x} forEach _drawn;
_grid set ["pageControls", []];
_grid set ["pageSig", _signature];

private _parent = _grid get "parent";
private _cols = _grid get "cols";
private _cellW = _grid get "cellW";
(_grid get "rel") params ["_left", "_top"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _muted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
private _text2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _accent = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];
private _controls = [];

private _barH = UNIT * PAGE_BAR_H;
private _barW = _cols * _cellW - pixelW;
private _barTop = _top + (_grid getOrDefault ["pageHeight", 1]) * (_grid get "cellH") + COMPARTMENT_PAD_PX(_cellW) * pixelH + UNIT * PAGE_BAR_GAP;
private _halfW = _barW / 2;
private _slot = SQUARE(_barH);
private _size = UNIT * 0.46;

// ----- The bar -----
_controls append ([_display, _parent, [_left, _barTop, _barW, _barH], _theme getOrDefault ["slotCaptionBg", [0, 0, 0, 0.5]]] call FUNC(uiPanel));

// The words, in the middle of the bar between the two arrows' places.
private _labelW = _barW - _slot * 2 - SQUARE(_barH * 0.3);

_controls pushBack ([
    _display, _parent, [_left + (_barW - _labelW) / 2, _barTop + _barH / 2 - TEXT_MID * _size, _labelW, TEXT_MID * _size * 2],
    [_text, _labelW, _font, _size] call FUNC(fitText), _size, _text2, _font, 2
] call FUNC(uiLabel));

// The halves have no surface until the mouse is on one, and square corners like the bar. A click finds this grid
// again in this build.
private _ghost = createHashMap;
_ghost merge _theme;
_ghost set ["button", [0, 0, 0, 0]];
_ghost set ["radius", 0];

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
private _iconH = _barH * 0.5;
private _hits = [];

// Each half: [step, where its half starts, where its arrow stands, whether it can turn, the tooltip, the search's mark, where the drag's zone starts].
{
    _x params ["_step", "_halfX", "_arrowX", "_enabled", "_tip", "_mark", "_zoneX"];

    // The arrow at the half's outer end; the half is the button, lit under the mouse.
    private _ink = +([_muted, _text2] select _enabled);

    if (!_enabled) then {
        _ink set [3, (_ink param [3, 1]) * 0.4];
    };

    _controls pushBack ([
        _display, _parent, [_arrowX + (_slot - SQUARE(_iconH)) / 2, _barTop + (_barH - _iconH) / 2, SQUARE(_iconH), _iconH],
        [UI_TEX(icon_chevron_left_ca), UI_TEX(icon_chevron_right_ca)] select (_step > 0), _ink
    ] call FUNC(uiIcon));

    // The search found something on that side: a mark with the number on the arrow's corner.
    if (_mark > 0) then {
        private _markH = _barH * 0.5;
        private _markW = SQUARE(_markH) max (((str _mark) getTextWidth [_fontBold, _markH * 0.62]) * TEXT_SLACK + SQUARE(_markH * 0.5));
        private _markRect = [_arrowX + _slot - _markW * 0.8, _barTop + _barH * 0.04, _markW, _markH];

        _controls append ([_display, _parent, _markRect, _accent, _markH / 2] call FUNC(uiPanel));
        _controls pushBack ([
            _display, _parent, _markRect, str _mark, _markH * 0.62, _theme getOrDefault ["onAccent", [0.05, 0.05, 0.05, 1]], _fontBold, 2
        ] call FUNC(uiLabel));
    };

    _hits pushBack [_step, _halfX, _enabled, _tip];

    if (_register) then {
        _areas pushBack createHashMapFromArray [
            ["rel", [_zoneX, _barTop]], ["parent", _parent], ["size", [_barW * PAGE_ZONE, _barH]], ["grid", _grid], ["step", _step]
        ];
    };
} forEach [
    [-1, _left, _left + SQUARE(_barH * 0.1), _page > 0, LLSTRING(Page_Prev), _before, _left],
    [1, _left + _halfW, _left + _barW - _slot - SQUARE(_barH * 0.1), _page < _pages - 1, LLSTRING(Page_Next), _after, _left + _barW * (1 - PAGE_ZONE)]
];

// The two halves last, so nothing lies over their hit areas.
{
    _x params ["_step", "_halfX", "_enabled", "_tip"];

    _controls append ([
        _display, _parent, [_halfX, _barTop, _halfW, _barH], format ["page|%1|%2|%3", _gridIndex, _step, GVAR(buildCount)], "", "",
        _ghost, _fnc_click, !_enabled
    ] call FUNC(uiButton));

    (_controls select -1) ctrlSetTooltip _tip;
} forEach _hits;

if (_register) then {
    uiNamespace setVariable [QGVAR(pageAreas), _areas];
    _grid set ["pageAreasMade", true];
};

_grid set ["pageControls", _controls];
