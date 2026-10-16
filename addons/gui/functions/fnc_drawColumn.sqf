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
 * The group reaches into the panel's right padding: its scroll bar runs there, beside the sections
 * rather than over them.
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

[
    _display, controlNull, _rect, _theme getOrDefault ["panel", []],
    _theme getOrDefault ["radius", 0], _theme getOrDefault ["panelBorder", []]
] call FUNC(uiPanel);

private _padY = UNIT * 0.4;
private _padX = SQUARE(_padY);
private _innerTop = _top + _padY;

if (_title isNotEqualTo "") then {
    private _titleH = UNIT * 1.1;
    private _textX = _left + _padX;

    if (_icon isNotEqualTo "") then {
        [_display, controlNull, [_textX, _innerTop + _titleH * 0.15, SQUARE(_titleH * 0.7), _titleH * 0.7], _icon, _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]]] call FUNC(uiIcon);
        _textX = _textX + SQUARE(_titleH * 0.7) + SQUARE(_titleH * 0.3);
    };

    private _size = UNIT * 0.66;
    private _font = _theme getOrDefault ["fontBold", "PuristaSemibold"];
    private _text = [[_title, _theme] call FUNC(caption), _left + _width - _padX - _textX, _font, _size] call FUNC(fitText);

    [_display, controlNull, [_textX, _innerTop, _left + _width - _padX - _textX, _titleH], _text, _size, _theme getOrDefault ["text", [1, 1, 1, 1]], _font, 0] call FUNC(uiLabel);

    // A hairline under the title, like the header's.
    private _line = [_display, "EINV_PanelRect", controlNull, [_left + _padX, _innerTop + _titleH + _padY * 0.4, _width - _padX * 2, pixelH]] call FUNC(uiCreate);
    _line ctrlSetBackgroundColor (_theme getOrDefault ["line", [1, 1, 1, 0.07]]);

    _innerTop = _innerTop + _titleH + _padY;
};

private _groupW = _width - _padX - pixelW * 2;
private _group = [_display, "EINV_ScrollGroup", controlNull, [
    _left + _padX,
    _innerTop,
    _groupW,
    _top + _height - _padY - _innerTop
]] call FUNC(uiCreate);

// Known to the drawers from the start (fnc_drawSection reads the side from it).
_group setVariable [QGVAR(column), _id];

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

// A clear speck at the very bottom: the engine scrolls as far as the lowest control reaches, and this
// makes that exactly the height stored here - a grid's last cell ends a pixel short of it.
if (_contentH > 0) then {
    private _end = [_display, "EINV_PanelRect", _group, [0, _contentH - pixelH, pixelW, pixelH]] call FUNC(uiCreate);
    _end ctrlSetBackgroundColor [0, 0, 0, 0];
};

_group setVariable [QGVAR(contentH), _contentH];

_group
