#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws an open kit's window - a kit of Enhanced First Aid Kits or a pouch of Enhanced Utility Pouches
 * (einv_compat_efak): a card of the inspect card's glass floating over the columns, as Tarkov opens a
 * container in a window of its own. On top the kit's picture and name, a "Take all" button that moves
 * everything into the player's own gear (einv_compat_efak_fnc_unpackAll - the inventory only, while the
 * kit has something in it), a "Sort" button that lays its grid out anew (fnc_sortHolder - the inventory
 * only, where the player may change the kit), how full it is - "12 / 60 mass" in that mod's measure, in
 * the loss colour when over - and a cross that closes it; under a hairline the kit's grid with our tiles,
 * or the line that says why nothing can go in yet (still loading, say). The buttons are as high as the
 * cross and their labels centred (fnc_uiButton, "centred"), and the name and the fill text are centred in
 * the row's height as the buttons are.
 *
 * One controls group of a fixed size, its content fitting it exactly - a group scrolls once its content
 * reaches past it. The grid lies in a scrolling group of its own, the body, which scrolls only for a
 * kit taller than the screen allows: at most the content band high, so the window never covers the
 * header or the footer. It is moved by its title (fnc_onMouseButton, fnc_onFrame) - no button for it: a
 * focused control would draw over everything.
 *
 * Where it was put is kept (GVAR(windowPos)); opened just now it is placed beside the tile it was opened
 * from (fnc_placeWindow), fades in over WINDOW_FADE and its title lights up for a moment. Either way it
 * stays whole between the header and the footer.
 *
 * Its grids are ordinary grids (fnc_drawCompartments) with one more key, "window" - its key - so the
 * mouse finds them only while nothing lies over them (fnc_topAt). The window group and the body report
 * the mouse buttons and the wheel as the columns do.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Section of the kit, see einv_compat_efak_fnc_getSections <HASHMAP>
 * 2: Theme <HASHMAP>
 * 3: Opened just now: fade in <BOOL> (default: false)
 *
 * Return Value:
 * The window's record <HASHMAP>
 *   "key"           - the section's key, "kit:" + the lowercase class
 *   "group", "body" - the window and its scrolling body <CONTROL>
 *   "rect"          - [x, y, w, h] on the screen
 *   "title"         - [x, y, w, h] in the window: the strip that moves it
 *   "close"         - [x, y, w, h] in the window: the cross
 *   "section"       - what it was drawn from, to draw it again (fnc_raiseWindow)
 *   "grids"         - the indices of its grids in the list of grids
 *
 * Example:
 * [_display, _section, GVAR(theme), true] call einv_gui_fnc_drawWindow;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_section", "_theme", ["_fresh", false]];

private _key = _section getOrDefault ["key", ""];
private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _muted = _theme getOrDefault ["muted", [0.412, 0.443, 0.494, 1]];
private _radius = _theme getOrDefault ["radius", 0];

(call FUNC(getCell)) params ["_cellW"];

// The columns' paddings, so a window reads as one of them.
private _padY = UNIT * 0.4;
private _padX = SQUARE(_padY);
private _titleH = UNIT * 1.1;
private _closeW = SQUARE(_titleH);

// The grid and the extra pixel of its lines on the left.
private _innerW = STORAGE_COLS * _cellW + pixelW;
private _width = _padX * 2 + _innerW;

// ----- What the body holds -----

private _notice = _section getOrDefault ["notice", ""];
private _layout = createHashMap;
private _places = [];
private _contentH = UNIT * 0.7;

if (_notice isEqualTo "") then {
    _layout = [_section getOrDefault ["layoutKey", ""], _section getOrDefault ["entries", []]] call EFUNC(storage,getLayout);

    ([_layout] call FUNC(flowCompartments)) params ["_flowed", "_flowH"];

    _places = _flowed;

    // The grid lies a pixel in from the body's corner: its lines reach a pixel left of and above it.
    _contentH = _flowH + pixelH;
};

private _bodyH = _contentH min (CONTENT_H - _padY * 3 - _titleH);
private _height = _padY * 3 + _titleH + _bodyH;

// ----- Where -----

private _position = GVAR(windowPos) getOrDefault [_key, []];

if (_position isEqualTo []) then {
    _position = [[_width, _height], GVAR(windowAnchor) getOrDefault [_key, []]] call FUNC(placeWindow);
    GVAR(windowAnchor) deleteAt _key;
};

_position params ["_left", "_top"];

// Whole between the screen's sides and between header and footer - a window that grew taller is pushed
// up as far as it has to.
_left = SNAP_X((_left min (safezoneX + safezoneW - _width)) max safezoneX);
_top = SNAP_Y((_top min (CONTENT_B - _height)) max CONTENT_Y);

GVAR(windowPos) set [_key, [_left, _top]];

private _group = [_display, "EINV_Group", controlNull, [_left, _top, _width, _height]] call FUNC(uiCreate);
(ctrlPosition _group) params ["", "", "_groupW", "_groupH"];

// Like the columns (fnc_build), the window and its body report the mouse buttons and the wheel as the
// display does: lying over the columns, they take them in their place (fnc_onMouseButton, fnc_onMouseZ).
// Added here rather than by a build: a window is also drawn on its own.
private _fnc_events = {
    params ["_ctrl"];

    _ctrl ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call FUNC(onMouseButton)}];
    _ctrl ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call FUNC(onMouseButton)}];
    _ctrl ctrlAddEventHandler ["MouseZChanged", {[_this] call FUNC(onMouseZ)}];
};

[_group] call _fnc_events;

// ----- The card -----

// The inspect card's glass, so it reads over a column, and the context menu's edge: a dark window over a
// dark column needs one.
[_display, _group, [0, 0, _groupW, _groupH], _theme getOrDefault ["inspectBg", [0.075, 0.083, 0.1, 0.97]], _radius] call FUNC(uiPanel);
[_display, _group, [0, 0, _groupW, _groupH], [1, 1, 1, 0.12], _radius] call FUNC(uiRing);

// ----- The title row: picture, name, how full, the cross -----

private _class = _section getOrDefault ["class", ""];
private _pictureH = _titleH * 0.8;
private _textX = _padX;

if (_class isNotEqualTo "") then {
    [
        _display, _group, [_padX, _padY + (_titleH - _pictureH) / 2, SQUARE(_pictureH), _pictureH],
        ([_class] call EFUNC(items,getInfo)) getOrDefault ["picture", ""]
    ] call FUNC(uiPicture);

    _textX = _padX + SQUARE(_pictureH) + SQUARE(UNIT * 0.3);
};

private _closeX = _groupW - _padX - _closeW;
private _load = _section getOrDefault ["load", ""];
private _loadSize = UNIT * 0.5;
private _loadW = [0, (_load getTextWidth [_font, _loadSize]) * TEXT_SLACK + SQUARE(UNIT * 0.3)] select (_load isNotEqualTo "");
private _loadColor = [
    _theme getOrDefault ["text2", [0.639, 0.675, 0.725, 1]],
    _theme getOrDefault ["loss", [0.941, 0.333, 0.353, 1]]
] select (_section getOrDefault ["loadOver", false]);

// A label draws its text from its top edge down: a text in the row's middle starts above it by TEXT_MID of
// its font height, as the buttons' labels do (fnc_uiButton). [top, height] in the window.
private _fnc_mid = {
    params ["_size"];

    private _labelTop = _padY + _titleH / 2 - TEXT_MID * _size;

    [_labelTop, _padY + _titleH - _labelTop]
};

if (_load isNotEqualTo "") then {
    (_loadSize call _fnc_mid) params ["_loadTop", "_loadH"];

    [_display, _group, [_closeX - _loadW, _loadTop, _loadW, _loadH], _load, _loadSize, _loadColor, _font, 1] call FUNC(uiLabel);
};

// The buttons, left of how full it is: one row of chips as high as the cross, in the size of the fill text
// (fnc_buttonWidth, fnc_uiButton). Take all: everything in the kit into the player's own gear
// (einv_compat_efak_fnc_unpackAll), as on a section of the loot column (fnc_drawSection). Sort: the kit's
// grid laid out anew by the order the player has chosen, each click stepping to the next one (fnc_sortHolder,
// fnc_sortChip), where the player may change the kit (einv_compat_efak_fnc_checkTouch). Both only in the
// inventory and while the kit shows its grid, and drawn disabled while a move out of this kit is under way.
// A button is [id, label, icon, width]; for lack of room the last one goes first.
private _kitClass = _section getOrDefault ["kit", ""];
private _buttonSize = _loadSize;
private _buttonGap = SQUARE(UNIT * 0.3);
private _buttons = [];

if (_kitClass isNotEqualTo "" && {_notice isEqualTo ""} && {call FUNC(isInventoryMode)}) then {
    if ((_section getOrDefault ["entries", []]) isNotEqualTo [] && {!isNil QEFUNC(compat_efak,unpackAll)}) then {
        private _label = LLSTRING(Section_TakeAll);

        _buttons pushBack [format ["take|%1", _kitClass], _label, "", [_label, "", _titleH, _buttonSize, _theme] call FUNC(buttonWidth)];
    };

    if (isNil QEFUNC(compat_efak,checkTouch) || {([_kitClass] call EFUNC(compat_efak,checkTouch)) isEqualTo ""}) then {
        // "Sort: Name", the order the player sorts by now, in a button as wide as the widest label (fnc_sortChip).
        ([_titleH, _buttonSize, _theme] call FUNC(sortChip)) params ["_sortLabel", "_sortIcon", "_sortW"];

        _buttons pushBack [format ["sort|%1", _key], _sortLabel, _sortIcon, _sortW];
    };
};

// What the buttons take, each with the gap after it.
private _fnc_buttonsW = {
    private _sum = 0;

    {
        _sum = _sum + (_x select 3) + _buttonGap;
    } forEach _buttons;

    _sum
};

// The name keeps room for itself first: too narrow for it, the last button goes, then the one before it.
while {_buttons isNotEqualTo [] && {_closeX - _loadW - (call _fnc_buttonsW) - _textX < SQUARE(UNIT * 4)}} do {
    _buttons deleteAt (count _buttons - 1);
};

if (_buttons isNotEqualTo []) then {
    private _busy = false;

    // A HashMap: _y is a move's record, its sources first.
    {
        if (((_y param [0, []]) findIf {(_x param [0, objNull]) isEqualTo _key}) >= 0) exitWith {
            _busy = true;
        };
    } forEach GVAR(inFlight);

    private _buttonX = _closeX - _loadW - (call _fnc_buttonsW);

    {
        _x params ["_buttonId", "_label", "_icon", "_buttonW"];

        private _button = [
            _display, _group, [_buttonX, _padY, _buttonW, _titleH], _buttonId, _label, _icon, _theme,
            {
                params ["_direction", "_buttonId"];

                if (_direction != 1) exitWith {};

                (_buttonId splitString "|") params ["_kind", "_what"];

                if (_kind isEqualTo "sort") then {
                    [_what, objNull, true] call FUNC(sortHolder);
                } else {
                    [_what] call EFUNC(compat_efak,unpackAll);
                };
            },
            _busy, _buttonSize, true
        ] call FUNC(uiButton);

        // Sort says what its next click sorts by, and changes with the order (fnc_sortButtons).
        if ((_buttonId select [0, 5]) isEqualTo "sort|") then {
            [_button] call FUNC(sortButtons);
        };

        _buttonX = _buttonX + _buttonW + _buttonGap;
    } forEach _buttons;
};

private _nameW = (_closeX - _loadW - _textX - (call _fnc_buttonsW)) max 0;
private _nameSize = UNIT * 0.66;
(_nameSize call _fnc_mid) params ["_nameTop", "_nameH"];

[
    _display, _group, [_textX, _nameTop, _nameW, _nameH],
    [[_section getOrDefault ["title", ""], _theme] call FUNC(caption), _nameW, _fontBold, _nameSize] call FUNC(fitText),
    _nameSize, _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]], _fontBold, 0
] call FUNC(uiLabel);

// The cross: its click closes the window, which takes the cross along (fnc_closeWindow). Not while
// something is dragged, as Escape (fnc_onKeyDown) - a right click on it with the left button held: what
// is held may come from this window, and the grids of the windows after it would take other places in
// the list of grids - the drop would take the item out of a kit it never came from.
private _cross = [_display, _group, [_closeX, _padY, _closeW, _titleH], _key, "", UI_TEX(icon_close_ca), _theme, {
    params ["", "_key"];

    if (GVAR(dragging)) exitWith {};

    [_key] call FUNC(closeWindow);
}] call FUNC(uiButton);

(_cross select -1) ctrlSetTooltip LLSTRING(Section_Close);

// A hairline under the title, as under a column's.
private _line = [_display, "EINV_PanelRect", _group, [_padX, _padY + _titleH + _padY * 0.4, _innerW, pixelH]] call FUNC(uiCreate);
_line ctrlSetBackgroundColor (_theme getOrDefault ["line", [1, 1, 1, 0.07]]);

// ----- The body -----

// It reaches into the right padding like a column's group, so a scroll bar runs beside the grid.
private _body = [_display, "EINV_ScrollGroup", _group, [_padX - pixelW, _padY * 2 + _titleH, _groupW - _padX - pixelW, _bodyH]] call FUNC(uiCreate);

[_body] call _fnc_events;

private _grids = uiNamespace getVariable [QGVAR(grids), []];
private _first = count _grids;

if (_notice isNotEqualTo "") then {
    // Nothing to show yet: a line that says why, and no grid that could take anything.
    [
        _display, _body, [pixelW, 0, _innerW, UNIT * 0.7],
        [_notice, _innerW, _font, _loadSize] call FUNC(fitText), _loadSize, _muted, _font, 0
    ] call FUNC(uiLabel);
} else {
    [_display, _body, [pixelW, pixelH], _section, _layout, _places, _theme, _key] call FUNC(drawCompartments);
};

// A clear speck at the very bottom, as in a column (fnc_drawColumn): the engine scrolls as far as the
// lowest control reaches, and this makes that exactly the height stored here.
private _end = [_display, "EINV_PanelRect", _body, [0, _contentH - pixelH, pixelW, pixelH]] call FUNC(uiCreate);
_end ctrlSetBackgroundColor [0, 0, 0, 0];

_body setVariable [QGVAR(contentH), _contentH];

// Back to where the body was scrolled, a frame later, once it knows its height (fnc_onFrame).
private _scrolled = GVAR(windowScroll) getOrDefault [_key, 0];

if (_scrolled > 0) then {
    (uiNamespace getVariable [QGVAR(scrollRestore), []]) pushBack [_body, _scrolled, diag_frameNo];
};

private _made = [];

for "_i" from _first to (count (uiNamespace getVariable [QGVAR(grids), []]) - 1) do {
    _made pushBack _i;
};

// ----- Opened just now -----

if (_fresh) then {
    // The title lights up in the accent colour and dies away, as a tile where something landed
    // (fnc_flashTile) - made last, so it lies over the title. Not over the cross, which stays the
    // topmost thing there for its clicks.
    private _color = +(_theme getOrDefault ["accent", [1, 1, 1, 1]]);
    _color set [3, LAND_FLASH_ALPHA];

    {
        _x ctrlSetFade 0;
        _x ctrlCommit 0;
        _x ctrlSetFade 1;
        _x ctrlCommit LAND_FLASH;
    } forEach ([
        _display, _group, [_padX * 0.5, _padY * 0.5, _closeX - _padX * 0.5, _titleH + _padY], _color, _radius
    ] call FUNC(uiPanel));

    // A group's fade carries everything in it.
    _group ctrlSetFade 1;
    _group ctrlCommit 0;
    _group ctrlSetFade 0;
    _group ctrlCommit WINDOW_FADE;
};

createHashMapFromArray [
    ["key", _key],
    ["group", _group],
    ["body", _body],
    ["rect", ctrlPosition _group],
    ["title", [0, 0, _closeX, _padY * 1.5 + _titleH]],
    ["close", [_closeX, _padY, _closeW, _titleH]],
    ["section", _section],
    ["grids", _made]
]
