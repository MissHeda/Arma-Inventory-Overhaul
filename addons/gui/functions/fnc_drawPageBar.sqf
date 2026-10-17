#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The pager of a paged compartment (fnc_pageRanges): a bar under its cells, PAGE_BAR_H of a UNIT tall, and nothing else - no
 * cue, no fade and no chip lies over the tiles. One control: a soft track with a round arrow button at each end and, between
 * them, one line that says where it stands and what lies elsewhere:
 *   "Page 2 / 5  ·  +180 items on other pages  ·  12 queued"
 * - the items on the pages not shown, the entries of the hands' queue waiting on tiles of those pages (they have no circle
 * while their tile is not drawn, so they are counted here), and, while the search field holds something or a category is
 * chosen at the box's side (fnc_drawGroupStrip), the matches on other pages instead of the items (fnc_pageCounts) - a search
 * and a category are found on any page. An arrow whose side of the pages has
 * matches wears a small mark with their number.
 * The arrows are round buttons of their own, a good deal bigger than the line of words, its surface fading in under the mouse and
 * out again (a pair of fades, not a jump). The hit area of each is the button and 2 pixels on every side (the rule of fnc_uiButton),
 * not the half of the bar, so the bar between is free. An arrow with no page behind it is dimmed and does nothing.
 * On the last page - not the first - the bar says so itself (Mia, 0.5.5): "Last page  ·  174 items on earlier pages", with the arrow
 * back lit and tinted with the accent. The words are a button too, as soon as there is a page before: a click on them jumps to the
 * first page (they light under the mouse). Nothing lies on the grid's free cells any more: the note and its "First page" button of 0.5.4,
 * which stood behind the tiles' background, are gone.
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

// The matches are counted for the search field and for the category chosen at this box's side (fnc_pageCounts): either one makes the
// bar say how many lie on the other pages.
private _searching = GVAR(filter) isNotEqualTo "" || {([_grid getOrDefault ["holder", _grid getOrDefault ["container", objNull]]] call FUNC(boxGroup)) isNotEqualTo ""};
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
    if ((_x getOrDefault ["offPage", false]) && {(_x getOrDefault ["queued", 0]) != 0}) then {
        _queued = _queued + 1;
    };
} forEach (_grid getOrDefault ["tiles", []]);

// The last page, not the first: the bar says so, and how much lies before it.
private _last = _page > 0 && {_page == _pages - 1};

private _parts = [format [LLSTRING(Page_Label), _page + 1, _pages]];

if (_last) then {
    _parts = [LLSTRING(Page_Last_None)];
};

if (_searching && {_elsewhere > 0}) then {
    _parts pushBack format [[LLSTRING(Page_Hits), LLSTRING(Page_Hits_One)] select (_elsewhere == 1), _elsewhere];
} else {
    if (_others > 0) then {
        if (_last) then {
            _parts pushBack format [[LLSTRING(Page_Earlier), LLSTRING(Page_Earlier_One)] select (_others == 1), _others];
        } else {
            _parts pushBack format [[LLSTRING(Page_Other), LLSTRING(Page_Other_One)] select (_others == 1), _others];
        };
    };
};

if (_queued > 0) then {
    _parts pushBack format [LLSTRING(Page_Queued), _queued];
};

private _text = _parts joinString "  ·  ";

// Nothing it says changed since it was drawn, and the controls are all there: left as it is.
private _signature = [GVAR(buildCount), _page, _pages, _text, _before, _after, _others];
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
private _size = UNIT * 0.46;

// The arrows are round buttons inside the bar, a little in from its ends: nearly the bar's height and wider than they are high.
private _inset = _barH * 0.07;
private _buttonH = _barH - _inset * 2;
private _buttonW = SQUARE(_buttonH * 1.5);
private _buttonRadius = (_theme getOrDefault ["radius", 0]) min (_buttonH * 0.35);

// ----- The bar -----
_controls append ([
    _display, _parent, [_left, _barTop, _barW, _barH], _theme getOrDefault ["slotCaptionBg", [0, 0, 0, 0.5]],
    (_theme getOrDefault ["radius", 0]) min (_barH * 0.35)
] call FUNC(uiPanel));

// The words, in the middle of the bar between the two buttons.
private _labelW = _barW - (_buttonW + SQUARE(_inset)) * 2 - SQUARE(_barH * 0.3);
private _labelRect = [_left + (_barW - _labelW) / 2, _barTop + _barH / 2 - TEXT_MID * _size, _labelW, TEXT_MID * _size * 2];

private _labelInk = [_text2, _theme getOrDefault ["text", [1, 1, 1, 1]]] select _last;

private _labelCtrl = [
    _display, _parent, _labelRect, [_text, _labelW, _font, _size] call FUNC(fitText), _size, _labelInk, _font, 2
] call FUNC(uiLabel);

_controls pushBack _labelCtrl;

// A click finds this grid again in this build; it runs a frame later (the page redraws its own bar).
private _fnc_click = {
    params ["_direction", "_buttonId"];

    if (_direction != 1) exitWith {};

    (_buttonId splitString "|") params ["", "_index", "_step", ["_build", ""]];

    if (_build isNotEqualTo str GVAR(buildCount)) exitWith {};

    private _target = (uiNamespace getVariable [QGVAR(grids), []]) param [parseNumber _index, createHashMap];

    if (count _target == 0) exitWith {};

    // Clicked fast, the pages the first and the last click asked for are drawn, not each between (fnc_pageSoon).
    [_target, parseNumber _step] call FUNC(pageSoon);
};

// A click on the words: the same, to the first page.
private _fnc_first = {
    params ["_direction", "_buttonId"];

    if (_direction != 1) exitWith {};

    (_buttonId splitString "|") params ["", "_index", ["_build", ""]];

    if (_build isNotEqualTo str GVAR(buildCount)) exitWith {};

    private _target = (uiNamespace getVariable [QGVAR(grids), []]) param [parseNumber _index, createHashMap];

    if (count _target == 0) exitWith {};

    [_target, 0, false] call FUNC(pageSoon);
};

private _gridIndex = (uiNamespace getVariable [QGVAR(grids), []]) find _grid;
private _areas = uiNamespace getVariable [QGVAR(pageAreas), []];
private _register = !(_grid getOrDefault ["pageAreasMade", false]);
private _iconH = _buttonH * 0.6;

// The hit area of an arrow: its button and two pixels on every side (the rule of fnc_uiButton).
private _hitX = pixelW * 2;
private _hitY = pixelH * 2;
private _buttonColor = _theme getOrDefault ["button", [1, 1, 1, 0.07]];
private _hoverColor = _theme getOrDefault ["buttonHover", [1, 1, 1, 0.16]];
private _hits = [];

// Each arrow: [step, where its button stands, whether it can turn, the tooltip, the search's mark, where the drag's zone starts].
{
    _x params ["_step", "_buttonX", "_enabled", "_tip", "_mark", "_zoneX"];

    private _buttonRect = [_buttonX, _barTop + _inset, _buttonW, _buttonH];

    // On the last page the arrow back is the way out: lit, with the accent on its icon.
    private _emphasis = _last && {_step < 0};
    private _ink = +([[_muted, _text2] select _enabled, _accent] select _emphasis);

    // A surface of its own, dimmer when there is no page that way, brighter for the emphasised arrow; lit by a second one that fades
    // in under the mouse.
    private _surface = +_buttonColor;

    if (_emphasis) then {
        _surface = +_hoverColor;
    };

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

    _hits pushBack [_step, _buttonRect, _enabled, _tip, _light];

    if (_register) then {
        _areas pushBack createHashMapFromArray [
            ["rel", [_zoneX, _barTop]], ["parent", _parent], ["size", [_barW * PAGE_ZONE, _barH]], ["grid", _grid], ["step", _step]
        ];
    };
} forEach [
    [-1, _left + SQUARE(_inset), _page > 0, LLSTRING(Page_Prev), _before, _left],
    [1, _left + _barW - SQUARE(_inset) - _buttonW, _page < _pages - 1, LLSTRING(Page_Next), _after, _left + _barW * (1 - PAGE_ZONE)]
];

// ----- The hit areas -----
// Last, so nothing lies over them. Under the mouse the light of the arrow's button fades in and out again. The hit area of an arrow is
// its button and two pixels around it; the words get one as soon as there is a page before (a click on them goes to the first).
{
    _x params ["_step", "_buttonRect", "_enabled", "_tip", "_light"];

    _buttonRect params ["_hitLeft", "_hitTop", "_hitW", "_hitH"];

    private _hit = [
        _display, "EINV_Hitbox", _parent, [_hitLeft - _hitX, _hitTop - _hitY, _hitW + _hitX * 2, _hitH + _hitY * 2]
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

if (_page > 0) then {
    private _words = [_display, "EINV_Hitbox", _parent, [_labelRect select 0, _barTop, _labelW, _barH]] call FUNC(uiCreate);

    _controls pushBack _words;

    _words setVariable [QGVAR(id), format ["pagefirst|%1|%2", _gridIndex, GVAR(buildCount)]];
    _words setVariable [QGVAR(code), _fnc_first];
    _words setVariable [QGVAR(label), _labelCtrl];
    _words setVariable [QGVAR(ink), _labelInk];
    _words ctrlSetTooltip LLSTRING(Page_First);

    _words ctrlAddEventHandler ["MouseEnter", {
        params ["_ctrl"];

        (_ctrl getVariable [QGVAR(label), controlNull]) ctrlSetTextColor (GVAR(theme) getOrDefault ["text", [1, 1, 1, 1]]);
    }];

    _words ctrlAddEventHandler ["MouseExit", {
        params ["_ctrl"];

        (_ctrl getVariable [QGVAR(label), controlNull]) ctrlSetTextColor (_ctrl getVariable [QGVAR(ink), [1, 1, 1, 1]]);
    }];

    _words ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];

        [_ctrl getVariable [QGVAR(code), {}], [1, _ctrl getVariable [QGVAR(id), ""]]] call FUNC(later);
    }];
};

if (_register) then {
    uiNamespace setVariable [QGVAR(pageAreas), _areas];
    _grid set ["pageAreasMade", true];
};

_grid set ["pageControls", _controls];
