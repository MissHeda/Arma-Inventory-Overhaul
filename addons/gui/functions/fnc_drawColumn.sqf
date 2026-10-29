#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws a column of sections - the unit's storage, or what it loots: a panel in the theme's colour, an
 * optional title row, and a scrolling group with the sections stacked in it, each drawn by the drawer
 * the style chose. Stores the height of everything in the group on it (QGVAR(contentH)), which
 * fnc_gridOrigin needs to know how far the group is scrolled, and the column's id (QGVAR(column)):
 * fnc_build keeps each column's scroll by it, so a column that comes or goes beside it - the loot
 * column - never sends another one back to the top, and fnc_startDrag tells the columns from the other
 * groups on the window by it. It is known from the start, so a section's drawer (fnc_drawSection) can tell
 * which side it is drawing for: "storage" is the unit's own, "loot" what it loots (selecting works on one
 * side at a time, fnc_select). Where the storage column lies is kept as GVAR(storageRect): a uniform, vest
 * or backpack let go on it goes on (fnc_updateDrag).
 *
 * The loot column is told apart from the player's own at a glance (issue 7), in the theme's loot colours where it
 * has them (fnc_theme; [] in fnc_themeBase leaves a column plain): a pane of its own tint (lootPanel), a thin ring
 * round it (lootBorder) and an accent strip under its title with the title's icon in the same colour (lootAccent),
 * where the player's own column keeps the plain pane and hairline. The title row is TEXT_UNIT high and its words
 * grow with the tile scale (fnc_textScale).
 *
 * The group reaches into the panel's right padding: its scroll bar runs there, beside the sections
 * rather than over them.
 *
 * A column that was scrolled down and is drawn again in the same place with the same title (fnc_build: a section folded or
 * unfolded, a move) keeps its panel, its title and its scroll group - fnc_build hands them over in uiNamespace keepColumns
 * by the column's id: the sections are drawn into the group first and the controls that were in it go afterwards, in the same
 * call, as the setup wizard's General page does (fnc_showStep). Kept too when only the panel's colour, the hairline's and the title's
 * text and icon colours changed (the palette's panels, transparency, lines and text, fnc_palette): they are painted in place, so a
 * picker dragged with a column scrolled does not send it to the top for a frame at every build. A group made anew starts at the top and learns its height a
 * frame later, so the column showed its top for a moment before fnc_onFrame put it back (Mia, 0.5.3: the list jumped up
 * when a section was folded). The scroll is put back all the same, now and a frame later, in screen height from the top.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Position [x, y, w, h] on the screen <ARRAY>
 * 2: Sections, see einv_storage_fnc_getSections <ARRAY>
 * 3: Theme <HASHMAP>
 * 4: Title, "" for no title row <STRING> (default: "")
 * 5: Title icon, "" for none <STRING> (default: "")
 * 6: Drawer, called as [display, group, y, width, section, theme] and returning the height it used -
 *    code, or a function's name <CODE or STRING> (default: einv_gui_fnc_drawSection)
 * 7: Id, "storage" or "loot" <STRING> (default: "")
 *
 * Return Value:
 * The scrolling group <CONTROL>
 *
 * Example:
 * [_display, [0.3, 0.1, 0.3, 0.8], _context get "ownSections", _theme, "Storage", "", "einv_gui_fnc_drawSection", "storage"] call einv_gui_fnc_drawColumn;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_rect", "_sections", "_theme", ["_title", ""], ["_icon", ""], ["_drawer", FUNC(drawSection)], ["_id", ""]];
_rect params ["_left", "_top", "_width", "_height"];

if (_drawer isEqualType "") then {
    _drawer = missionNamespace getVariable [_drawer, FUNC(drawSection)];
};

GVAR(panels) pushBack _rect;

// The unit's own column is a drop target of its own: what is worn in it goes on there (fnc_updateDrag).
if (_id isEqualTo "storage") then {
    GVAR(storageRect) = _rect;
};

// The loot column's own look, where the theme has one: each key left [] keeps the plain one.
private _loot = _id isEqualTo "loot";
private _panelColor = _theme getOrDefault ["panel", []];
private _ringColor = [];
private _accentColor = [];

if (_loot) then {
    private _lootPanel = _theme getOrDefault ["lootPanel", []];

    if (_lootPanel isNotEqualTo []) then {
        _panelColor = _lootPanel;
    };

    _ringColor = _theme getOrDefault ["lootBorder", []];
    _accentColor = _theme getOrDefault ["lootAccent", []];
};

// The hairline under the title: the loot column's accent strip, else the theme's line. The title's words, and its icon: in the loot
// column's accent, else the second line's grey.
private _lineColor = [_accentColor, _theme getOrDefault ["line", [1, 1, 1, 0.07]]] select (_accentColor isEqualTo []);
private _titleColor = _theme getOrDefault ["text", [1, 1, 1, 1]];
private _iconColor = [_accentColor, _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]]] select (_accentColor isEqualTo []);

// What a kept column can take on in place and what it cannot. The palette (fnc_palette) changes colours while the window is open, with a
// column scrolled: the panel's colour, the hairline's and the title's words and icon are painted over the kept controls (below), so the
// column stays where it is; a change of anything in the first list draws the column anew.
// The title in the palette's gradient is set once (fnc_uiLabel): the gradient and the accent belong to what cannot be painted over.
private _look = [
    _ringColor, _accentColor, _theme getOrDefault ["radius", 0], _theme getOrDefault ["panelBorder", []], _panelColor isEqualTo [],
    _theme getOrDefault ["titleGradient", []], _theme getOrDefault ["titleColor", []], _theme getOrDefault ["panelGradient", []],
    [[], _theme getOrDefault ["accent", []]] select ((_theme getOrDefault ["titleGradient", []]) isNotEqualTo [])
];
private _paintLook = [_panelColor, _lineColor, _titleColor, _iconColor];

// What fnc_build kept of this column from its last drawing, when it was scrolled: [group, panel and title controls, [rect, title,
// icon]]. The same place, words and look: all of it stays as it is, only the sections in the group are drawn again.
private _keepList = uiNamespace getVariable [QGVAR(keepColumns), createHashMap];
private _kept = _keepList getOrDefault [_id, []];
private _key = [_rect, _title, _icon];

_keepList deleteAt _id;

private _reuse = _id isNotEqualTo "" && {_kept isNotEqualTo []} && {!isNull (_kept select 0)} && {(_kept select 2) isEqualTo _key}
    && {(_kept select 1) findIf {isNull _x} < 0} && {((_kept select 0) getVariable [QGVAR(columnLook), []]) isEqualTo _look};

// One that cannot be kept (it moved, it is named otherwise) goes now.
if (!_reuse && {_kept isNotEqualTo []}) then {
    ctrlDelete (_kept select 0);

    {ctrlDelete _x} forEach (_kept select 1);
};

private _created = uiNamespace getVariable [QGVAR(created), []];
private _madeFrom = count _created;

private _padY = UNIT * 0.4;
private _padX = SQUARE(_padY);
private _innerTop = _top + _padY;

// The pieces of the panel, the hairline, the title's words and its icon, which a kept column is painted over with (the group keeps
// them; a part the column has not is controlNull).
private _paint = [[], controlNull, controlNull, controlNull];

if (_reuse) then {
    _paint = (_kept select 0) getVariable [QGVAR(columnPaint), _paint];

    if (((_kept select 0) getVariable [QGVAR(columnPaintLook), []]) isNotEqualTo _paintLook) then {
        if (_panelColor isNotEqualTo []) then {
            [_paint param [0, []], _panelColor] call FUNC(paintSurface);
        };

        (_paint param [1, controlNull]) ctrlSetBackgroundColor _lineColor;
        (_paint param [2, controlNull]) ctrlSetTextColor _titleColor;
        (_paint param [3, controlNull]) ctrlSetTextColor _iconColor;
    };
};

if (!_reuse) then {
    private _panelParts = [
        _display, controlNull, _rect, _panelColor,
        _theme getOrDefault ["radius", 0], _theme getOrDefault ["panelBorder", []]
    ] call FUNC(uiPanel);

    _paint set [0, _panelParts select {ctrlClassName _x in ["EINV_PanelRect", "EINV_PanelCorner"]}];

    if (_panelColor isNotEqualTo []) then {
        [_display, controlNull, _rect, _theme getOrDefault ["radius", 0]] call FUNC(panelGradient);
    };

    if (_ringColor isNotEqualTo []) then {
        [_display, controlNull, _rect, _ringColor, _theme getOrDefault ["radius", 0]] call FUNC(uiRing);
    };
};

if (_title isNotEqualTo "") then {
    private _titleH = TEXT_UNIT * 1.1;
    private _textX = _left + _padX;

    if (!_reuse) then {
        if (_icon isNotEqualTo "") then {
            _paint set [3, [
                _display, controlNull, [_textX, _innerTop + _titleH * 0.15, SQUARE(_titleH * 0.7), _titleH * 0.7], _icon, _iconColor
            ] call FUNC(uiIcon)];
        };

        private _size = _titleH * 0.6;
        private _font = _theme getOrDefault ["fontBold", "PuristaSemibold"];
        private _iconW = [0, SQUARE(_titleH * 0.7) + SQUARE(_titleH * 0.3)] select (_icon isNotEqualTo "");
        private _text = [[_title, _theme] call FUNC(caption), _left + _width - _padX - _textX - _iconW, _font, _size] call FUNC(fitText);

        _paint set [2, [
            _display, controlNull, [_textX + _iconW, _innerTop, _left + _width - _padX - _textX - _iconW, _titleH], _text, _size, _titleColor, _font, 0, true
        ] call FUNC(uiLabel)];

        // A hairline under the title, like the header's - the loot column's is its accent strip, two pixels in its colour.
        private _lineH = [pixelH * 2, pixelH] select (_accentColor isEqualTo []);
        private _line = [_display, "EINV_PanelRect", controlNull, [_left + _padX, _innerTop + _titleH + _padY * 0.4, _width - _padX * 2, _lineH]] call FUNC(uiCreate);
        _line ctrlSetBackgroundColor _lineColor;
        _paint set [1, _line];
    };

    _innerTop = _innerTop + _titleH + _padY;
};

// Everything made above, from the panel on, is what a later drawing may keep.
private _parts = (uiNamespace getVariable [QGVAR(created), []]) select [_madeFrom];

if (_reuse) then {
    _parts = _kept select 1;

    // It is a registered control again, as every one of the window's is (fnc_build deletes them all by that list).
    (uiNamespace getVariable [QGVAR(created), []]) append _parts;
};

private _groupW = _width - _padX - pixelW * 2;
private _groupRect = [
    _left + _padX,
    _innerTop,
    _groupW,
    _top + _height - _padY - _innerTop
];
private _group = controlNull;
private _old = [];

if (_reuse) then {
    _group = _kept select 0;

    (uiNamespace getVariable [QGVAR(created), []]) pushBack _group;

    // What it holds now goes once the new sections are in: a group never stands empty between the two.
    _old = (allControls _group) select {ctrlParentControlsGroup _x isEqualTo _group};
} else {
    _group = [_display, "EINV_ScrollGroup", controlNull, _groupRect] call FUNC(uiCreate);
};

// Known to the drawers from the start (fnc_drawSection reads the side from it).
_group setVariable [QGVAR(column), _id];
_group setVariable [QGVAR(columnParts), _parts];
_group setVariable [QGVAR(columnKey), _key];
_group setVariable [QGVAR(columnLook), _look];
_group setVariable [QGVAR(columnPaintLook), _paintLook];
_group setVariable [QGVAR(columnPaint), _paint];

// As wide as the padding leaves - narrower only where the scroll bar would not fit beside it.
private _contentW = (_width - _padX * 2) min (_groupW - SCROLL_W - pixelW * 2);
private _gap = UNIT * 0.5;
private _cursor = 0;

{
    private _used = [_display, _group, _cursor, _contentW, _x, _theme] call _drawer;

    // A drawer that returns nothing must not stop the sections after it.
    if (isNil "_used" || {!(_used isEqualType 0)}) then {
        _used = 0;
    };

    _cursor = _cursor + _used + _gap;
} forEach _sections;

private _contentH = (_cursor - _gap) max 0;

{ctrlDelete _x} forEach _old;

// A clear speck at the very bottom: the engine scrolls as far as the lowest control reaches, and this
// makes that exactly the height stored here - a grid's last cell ends a pixel short of it.
if (_contentH > 0) then {
    private _end = [_display, "EINV_PanelRect", _group, [0, _contentH - pixelH, pixelW, pixelH]] call FUNC(uiCreate);
    _end ctrlSetBackgroundColor [0, 0, 0, 0];
};

_group setVariable [QGVAR(contentH), _contentH];

// A column that stayed is put back where it was scrolled at once; fnc_build asks for it again a frame later (fnc_onFrame), when
// the group is sure of its height.
if (_reuse) then {
    private _pixels = (uiNamespace getVariable [QGVAR(keepPixels), createHashMap]) getOrDefault [_id, 0];
    private _range = _contentH - (_groupRect select 3);

    if (_pixels > 0 && {_range > 0}) then {
        _group ctrlSetScrollValues [(_pixels / _range) min 1, -1];
    };
};

_group
