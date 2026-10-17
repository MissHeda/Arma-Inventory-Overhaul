#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The pager of a paged compartment (fnc_pageRanges): a bar under its cells, PAGE_BAR_H of a UNIT tall, and nothing else - no
 * cue, no fade and no chip lies over the tiles. One control: a soft track with a round arrow button at each end and, between
 * them, one line that says where it stands and what lies elsewhere:
 *   "Page 2 / 5  ·  +180 items on other pages  ·  12 queued"
 * - the items on the pages not shown, the entries of the hands' queue waiting on tiles of those pages (they have no circle
 * while their tile is not drawn, so they are counted here), and, while the search field holds something, the matches on
 * other pages instead of the items (fnc_pageCounts) - a search is found on any page. An arrow whose side of the pages has
 * matches wears a small mark with their number.
 * The arrows are the only things that light: each is a round button of its own, its surface fading in under the mouse and
 * out again (a pair of fades, not a jump), though its hit area is the whole half of the bar and a little more above and
 * below, so it is easy to hit. An arrow with no page behind it is dimmed and does nothing.
 * On the last page - not the first - with free rows under its tiles, those rows carry a note (Mia, 0.5.4): "Last page - the
 * earlier pages hold 256 items" and a button "First page", so a box opened there is not taken for an empty one. The note lies
 * on the free cells only, never over a tile; with one free row the words and the button share it, with more they are stacked.
 * The bar is drawn again whenever the page turns, the search or the queue changes what it says or the free rows change; one
 * that would look as it does (the grid's "pageSig") is left alone, so a redraw of the tiles does not flicker it (the controls are
 * the grid's "pageControls"). The outer PAGE_ZONE of the bar on each side is registered once per build in uiNamespace
 * pageAreas, where a dragged item held over it turns the page (fnc_updateDrag). A click runs a frame later (fnc_later) and finds
 * the grid by its place in the list of grids of this build.
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

// The rows under the last tile of the rows that show: free, whatever page it is.
private _rowFrom = _grid getOrDefault ["rowFrom", 0];
private _rowTo = _grid getOrDefault ["rowTo", _grid get "rows"];
private _freeFrom = _rowFrom;

{
    if (_x getOrDefault ["offPage", false]) then {
        if ((_x getOrDefault ["queued", 0]) != 0) then {
            _queued = _queued + 1;
        };
    } else {
        _freeFrom = _freeFrom max ((_x getOrDefault ["row", 0]) + (_x getOrDefault ["h", 1]));
    };
} forEach (_grid getOrDefault ["tiles", []]);

_freeFrom = _freeFrom min _rowTo;

// The last page, not the first, with room left under its tiles: it says so there.
private _note = _page > 0 && {_page == _pages - 1} && {_rowTo - _freeFrom >= 1} && {_freeFrom < (_grid get "rows")};

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

private _text = _parts joinString "  ·  ";

// Nothing it says changed since it was drawn, and the controls are all there: left as it is.
private _signature = [GVAR(buildCount), _page, _pages, _text, _before, _after, [-1, _freeFrom] select _note, _others];
private _drawn = _grid getOrDefault ["pageControls", []];

if (_drawn isNotEqualTo [] && {(_grid getOrDefault ["pageSig", []]) isEqualTo _signature} && {_drawn findIf {isNull _x} < 0}) exitWith {};

{ctrlDelete _x} forEach _drawn;
_grid set ["pageControls", []];
_grid set ["pageSig", _signature];

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
private _halfW = _barW / 2;
private _size = UNIT * 0.46;

// The arrows are round buttons inside the bar, a little in from its ends.
private _inset = _barH * 0.12;
private _buttonH = _barH - _inset * 2;
private _buttonW = SQUARE(_buttonH);
private _buttonRadius = (_theme getOrDefault ["radius", 0]) min (_buttonH * 0.35);

// ----- The bar -----
_controls append ([
    _display, _parent, [_left, _barTop, _barW, _barH], _theme getOrDefault ["slotCaptionBg", [0, 0, 0, 0.5]],
    (_theme getOrDefault ["radius", 0]) min (_barH * 0.35)
] call FUNC(uiPanel));

// The words, in the middle of the bar between the two buttons.
private _labelW = _barW - (_buttonW + SQUARE(_inset)) * 2 - SQUARE(_barH * 0.3);

_controls pushBack ([
    _display, _parent, [_left + (_barW - _labelW) / 2, _barTop + _barH / 2 - TEXT_MID * _size, _labelW, TEXT_MID * _size * 2],
    [_text, _labelW, _font, _size] call FUNC(fitText), _size, _text2, _font, 2
] call FUNC(uiLabel));

// A click finds this grid again in this build; it runs a frame later (the page redraws its own bar).
private _fnc_click = {
    params ["_direction", "_buttonId"];

    if (_direction != 1) exitWith {};

    (_buttonId splitString "|") params ["", "_index", "_step", ["_build", ""]];

    if (_build isNotEqualTo str GVAR(buildCount)) exitWith {};

    private _target = (uiNamespace getVariable [QGVAR(grids), []]) param [parseNumber _index, createHashMap];

    if (count _target == 0) exitWith {};

    [_target, parseNumber _step] call FUNC(turnPage);
};

// "First page" in the note on the last page: the same, to the first page.
private _fnc_first = {
    params ["_direction", "_buttonId"];

    if (_direction != 1) exitWith {};

    (_buttonId splitString "|") params ["", "_index", ["_build", ""]];

    if (_build isNotEqualTo str GVAR(buildCount)) exitWith {};

    private _target = (uiNamespace getVariable [QGVAR(grids), []]) param [parseNumber _index, createHashMap];

    if (count _target == 0) exitWith {};

    [_target, 0] call FUNC(setPage);
};

private _gridIndex = (uiNamespace getVariable [QGVAR(grids), []]) find _grid;
private _areas = uiNamespace getVariable [QGVAR(pageAreas), []];
private _register = !(_grid getOrDefault ["pageAreasMade", false]);
private _iconH = _buttonH * 0.55;
private _hitUp = UNIT * 0.1;
private _hitDown = UNIT * 0.1;
private _buttonColor = _theme getOrDefault ["button", [1, 1, 1, 0.07]];
private _hoverColor = _theme getOrDefault ["buttonHover", [1, 1, 1, 0.16]];
private _hits = [];

// Each arrow: [step, where its half starts, where its button stands, whether it can turn, the tooltip, the search's mark, where the
// drag's zone starts].
{
    _x params ["_step", "_halfX", "_buttonX", "_enabled", "_tip", "_mark", "_zoneX"];

    private _buttonRect = [_buttonX, _barTop + _inset, _buttonW, _buttonH];
    private _ink = +([_muted, _text2] select _enabled);

    // A surface of its own, dimmer when there is no page that way; lit by a second one that fades in under the mouse.
    private _surface = +_buttonColor;

    if (!_enabled) then {
        _ink set [3, (_ink param [3, 1]) * 0.4];
        _surface set [3, (_surface select 3) * 0.5];
    };

    _controls append ([_display, _parent, _buttonRect, _surface, _buttonRadius] call FUNC(uiPanel));

    private _light = [];

    if (_enabled) then {
        _light = [_display, _parent, _buttonRect, _hoverColor, _buttonRadius] call FUNC(uiPanel);

        {
            _x ctrlSetFade 1;
            _x ctrlCommit 0;
        } forEach _light;

        _controls append _light;
    };

    _controls pushBack ([
        _display, _parent, [_buttonX + (_buttonW - SQUARE(_iconH)) / 2, _barTop + _inset + (_buttonH - _iconH) / 2, SQUARE(_iconH), _iconH],
        [UI_TEX(icon_chevron_left_ca), UI_TEX(icon_chevron_right_ca)] select (_step > 0), _ink
    ] call FUNC(uiIcon));

    // The search found something on that side: a mark with the number on the button's corner.
    if (_mark > 0) then {
        private _markH = _barH * 0.5;
        private _markW = SQUARE(_markH) max (((str _mark) getTextWidth [_fontBold, _markH * 0.62]) * TEXT_SLACK + SQUARE(_markH * 0.5));
        private _markRect = [_buttonX + _buttonW - _markW * 0.8, _barTop + _barH * 0.04, _markW, _markH];

        _controls append ([_display, _parent, _markRect, _accent, _markH / 2] call FUNC(uiPanel));
        _controls pushBack ([
            _display, _parent, _markRect, str _mark, _markH * 0.62, _theme getOrDefault ["onAccent", [0.05, 0.05, 0.05, 1]], _fontBold, 2
        ] call FUNC(uiLabel));
    };

    _hits pushBack [_step, _halfX, _enabled, _tip, _light];

    if (_register) then {
        _areas pushBack createHashMapFromArray [
            ["rel", [_zoneX, _barTop]], ["parent", _parent], ["size", [_barW * PAGE_ZONE, _barH]], ["grid", _grid], ["step", _step]
        ];
    };
} forEach [
    [-1, _left, _left + SQUARE(_inset), _page > 0, LLSTRING(Page_Prev), _before, _left],
    [1, _left + _halfW, _left + _barW - SQUARE(_inset) - _buttonW, _page < _pages - 1, LLSTRING(Page_Next), _after, _left + _barW * (1 - PAGE_ZONE)]
];

// ----- The note on the last page -----
if (_note) then {
    private _freeRows = _rowTo - _freeFrom;
    private _noteLeft = _left;
    private _noteWidth = _barW;
    private _noteTop = _top + ((_grid get "rowY") select _freeFrom);
    private _noteHeight = (_freeRows min 2) * _cellH - pixelH;

    private _noteText = if (_others <= 0) then {
        LLSTRING(Page_Last_None)
    } else {
        format [[LLSTRING(Page_Last), LLSTRING(Page_Last_One)] select (_others == 1), _others]
    };

    private _noteSize = UNIT * 0.5;
    private _lineH = TEXT_MID * _noteSize * 2;
    private _firstH = UNIT * 1;
    private _firstW = [LLSTRING(Page_First), "", _firstH, UNIT * 0.46, _theme] call FUNC(buttonWidth);
    private _padNote = SQUARE(UNIT * 0.5);

    // One free row: the words on the left, the button on the right. More: the words, and the button under them, in the middle.
    private _textRect = [];
    private _buttonRectFirst = [];

    if (_freeRows < 2) then {
        _buttonRectFirst = [_noteLeft + _noteWidth - _padNote - _firstW, _noteTop + (_noteHeight - _firstH) / 2, _firstW, _firstH];
        _textRect = [_noteLeft + _padNote, _noteTop + _noteHeight / 2 - _lineH / 2, _noteWidth - _padNote * 3 - _firstW, _lineH];
    } else {
        private _gap = UNIT * 0.25;
        private _block = _lineH + _gap + _firstH;
        private _blockTop = _noteTop + (_noteHeight - _block) / 2;

        _textRect = [_noteLeft + _padNote, _blockTop, _noteWidth - _padNote * 2, _lineH];
        _buttonRectFirst = [_noteLeft + (_noteWidth - _firstW) / 2, _blockTop + _lineH + _gap, _firstW, _firstH];
    };

    _controls pushBack ([
        _display, _parent, _textRect, [_noteText, _textRect select 2, _font, _noteSize] call FUNC(fitText), _noteSize, _text2, _font,
        [2, 0] select (_freeRows < 2)
    ] call FUNC(uiLabel));

    _controls append ([
        _display, _parent, _buttonRectFirst, format ["pagefirst|%1|%2", _gridIndex, GVAR(buildCount)], LLSTRING(Page_First), "", _theme,
        _fnc_first, false, UNIT * 0.46, true, [SQUARE(UNIT * 0.1), UNIT * 0.1]
    ] call FUNC(uiButton));
};

// ----- The hit areas -----
// The two halves last, so nothing lies over them. Under the mouse the light of the arrow's button fades in and out again; the
// whole half is the hit area, a little taller than the bar, though only the button shows the light.
{
    _x params ["_step", "_halfX", "_enabled", "_tip", "_light"];

    private _hit = [
        _display, "EINV_Hitbox", _parent, [_halfX, _barTop - _hitUp, _halfW, _barH + _hitUp + _hitDown]
    ] call FUNC(uiCreate);

    _controls pushBack _hit;

    if (!_enabled) then {continue};

    _hit setVariable [QGVAR(id), format ["page|%1|%2|%3", _gridIndex, _step, GVAR(buildCount)]];
    _hit setVariable [QGVAR(code), _fnc_click];
    _hit setVariable [QGVAR(light), _light];

    _hit ctrlSetTooltip _tip;

    _hit ctrlAddEventHandler ["MouseEnter", {
        params ["_ctrl"];

        {
            _x ctrlSetFade 0;
            _x ctrlCommit 0.08;
        } forEach (_ctrl getVariable [QGVAR(light), []]);
    }];

    _hit ctrlAddEventHandler ["MouseExit", {
        params ["_ctrl"];

        {
            _x ctrlSetFade 1;
            _x ctrlCommit 0.2;
        } forEach (_ctrl getVariable [QGVAR(light), []]);
    }];

    // The code runs a frame later: it redraws this bar, which deletes this very control.
    _hit ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];

        [_ctrl getVariable [QGVAR(code), {}], [1, _ctrl getVariable [QGVAR(id), ""]]] call FUNC(later);
    }];
} forEach _hits;

if (_register) then {
    uiNamespace setVariable [QGVAR(pageAreas), _areas];
    _grid set ["pageAreasMade", true];
};

_grid set ["pageControls", _controls];
