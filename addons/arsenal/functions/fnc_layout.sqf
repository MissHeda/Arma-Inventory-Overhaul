#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The layout of the panel (the "layout" hook): the uniform, vest or backpack whose tab is open in ACE's
 * left bar, as one section of the inventory's own (einv_gui_fnc_drawColumn with einv_gui_fnc_drawSection) -
 * its caption with what it holds weighs, its compartments and tiles -, under it the staging space
 * (fnc_staging) as a second section, and at the bottom the line for the hints (fnc_footer). Nothing while
 * another tab is open, that slot is empty, or ACE's panels are hidden (Backspace).
 *
 * The panel looks like one of the inventory's columns (the glass, corner radius, fonts and colours of its
 * theme) and is laid out the way they are, on one grid of PANEL_PAD UNITs: one block from the top of ACE's
 * sort bar down to the bottom of ACE's list (fnc_panelRect). On top the title row - the container's
 * picture, TITLE_H high and square, and its name beside it, TITLE_SIZE high, centred in the row's height;
 * both in ACE's grid, as the rows of ACE's list beside them are -, under it a hairline. Then the column,
 * which scrolls over both sections and reaches down to the hint line, the block's last band, over which
 * runs a hairline of its own: the staging space fills what the container leaves of it (fnc_growStaging). The picture, the
 * sections' tabs and grids start on one left edge, the load texts end on one right edge; the sections draw
 * no picture box of their own ("box" false), and the column draws no background over the block.
 *
 * A section's caption folds it (einv_gui_fnc_toggleSection), kept per container class - the staging
 * space as "staging" - while ACE's window is open (the "fold" hook, GVAR(folded)), whatever the inventory
 * did with its own captions. The staging section has a crate before its caption and says beside its tab
 * that it is emptied when the arsenal closes, in the caption's size and colour of the muted texts; its
 * grid is at least STAGING_MIN_ROWS rows, as many as reach down to the hint line, and grows with what lies
 * in it (fnc_growStaging). ACE's list is registered as a zone of the engine: whatever is let go outside
 * the panel is shown going there, out of the container (fnc_dragCheck).
 *
 * The focus sink (GVAR(focusSink) in uiNamespace) is made here the first time: a control of no size in the
 * screen's corner that fnc_onFrame gives the focus to, so that ACE's list loses it.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 * 1: Theme <HASHMAP>
 * 2: Context <HASHMAP>
 *
 * Return Value:
 * Where the soldier stands - nothing: the camera is ACE's <ARRAY>
 *
 * Example:
 * [_display, _theme, _context] call einv_arsenal_fnc_layout;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_theme", createHashMap, [createHashMap]], ["_context", createHashMap, [createHashMap]]];

GVAR(panelRect) = [];
GVAR(hintRect) = [];
GVAR(removeZone) = -1;
GVAR(stagingCount) = 0;

(call FUNC(selected)) params ["_id", "_container"];

if (_id isEqualTo "" || {!GVAR(shown)}) exitWith {[]};

private _index = (_context getOrDefault ["ownSections", []]) findIf {(_x getOrDefault ["container", objNull]) isEqualTo _container};

if (_index < 0) exitWith {[]};

private _section = (_context get "ownSections") select _index;
private _rect = [_display] call FUNC(panelRect);

if (_rect isEqualTo []) exitWith {[]};

_rect params ["_left", "_top", "_width", "_height"];

// The focus goes here, away from ACE's list, while the panel is used (fnc_onFrame): a control of no size
// that covers nothing. ACE's 3D area, where ACE puts the focus itself, covers the whole screen - focused,
// the engine draws it over the panel, and it took the first press on a tile and the wheel. Made once and
// never swept, so a build never hands the focus on to one of ACE's fields.
private _sink = uiNamespace getVariable [QGVAR(focusSink), controlNull];

if (isNull _sink) then {
    _sink = _display ctrlCreate ["EINV_Hitbox", -1];
    _sink ctrlSetPosition [safezoneX, safezoneY, 0, 0];
    _sink ctrlCommit 0;

    uiNamespace setVariable [QGVAR(focusSink), _sink];
};

// Folded is what a section starts as, turned round by the inventory's clicks on its caption
// (einv_gui_collapsed). Here the panel's own folds count (the "fold" hook): started against that list, a
// section is folded exactly when its key - the container's class, or "staging" - is in GVAR(folded).
private _fnc_fold = {
    params ["_section", "_key"];

    private _object = _section get "container";

    _section set ["folded", (_key in GVAR(folded)) isNotEqualTo (_object in EGVAR(gui,collapsed))];
    GVAR(foldKeys) pushBack [_object, _key];
};

GVAR(foldKeys) = [];
[_section, toLowerANSI (_section getOrDefault ["class", ""])] call _fnc_fold;

// The title row names and pictures the container: no box with its picture beside the grid.
_section set ["box", false];

private _sections = [_section];
private _holder = [] call FUNC(staging);

if (!isNull _holder) then {
    private _staging = createHashMapFromArray [
        ["id", "staging"],
        ["title", LLSTRING(Staging_Title)],
        ["class", ""],
        ["container", _holder],
        ["holder", _holder],
        ["root", _holder],
        ["parent", objNull],
        ["nearby", false],
        ["side", "own"],
        ["box", false],
        ["tabIcon", UI_TEX(icon_crate_ca)]
    ];

    [_staging, "staging"] call _fnc_fold;
    _sections pushBack _staging;

    // For the hint line: what would go with the arsenal's window.
    {
        GVAR(stagingCount) = GVAR(stagingCount) + _y;
    } forEach ([_holder] call FUNC(countAll));
};

// The padding of the block, as the inventory's columns have it (einv_gui_fnc_drawColumn): the title row
// starts a padding under the block's top and the column a padding under the title row, the column's own
// padding being the one between them - so the title band reaches down to the end of the title row.
private _list = _display displayCtrl ARSENAL_IDC_LIST;
private _padY = UNIT * PANEL_PAD;
private _padX = SQUARE(_padY);
private _titleH = TITLE_H;
private _bandH = SNAP_H(_padY + _titleH);
private _bodyTop = _top + _bandH;

// The hint line, the block's last band: a line as high as the footer's key hints, a second while the
// staging space holds something - for the note that it goes with the window (the "hint" hook) -, and room
// above and below, in ACE's grid as its text is. The column reaches down to it.
private _lines = [1, 2] select (GVAR(stagingCount) > 0);
private _hintH = SNAP_H(HINT_LINE_H * _lines + HINT_PAD * 2);
private _hintTop = _top + _height - _hintH;
private _columnH = _hintTop - _bodyTop;

if (_columnH < UNIT * 4) exitWith {[]};

// The block: the inventory's glass with its corner radius.
[
    _display, controlNull, _rect, _theme getOrDefault ["panel", []], _theme getOrDefault ["radius", 0], _theme getOrDefault ["panelBorder", []]
] call EFUNC(gui,uiPanel);

// The container's picture and name in the title row: one sees what is being filled. The picture is as high as
// the row and square, the name beside it in the columns' title font at TITLE_SIZE, its line of capitals
// centred in the row's height (TEXT_MID: a label draws its text from its top edge down).
private _titleTop = _top + _padY;
private _textX = _left + _padX;
private _picture = [([_section getOrDefault ["class", ""]] call EFUNC(items,getInfo)) getOrDefault ["picture", ""]] call EFUNC(gui,safePicture);

if (_picture isNotEqualTo "") then {
    [_display, controlNull, [_textX, _titleTop, SQUARE(_titleH), _titleH], _picture] call EFUNC(gui,uiPicture);

    _textX = _textX + SQUARE(_titleH) + SQUARE(_titleH * 0.3);
};

private _headFont = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _headSize = TITLE_SIZE;
private _headTop = _titleTop + _titleH / 2 - TEXT_MID * _headSize;
private _headW = _left + _width - _padX - _textX;
private _title = [[_section getOrDefault ["title", ""], _theme] call EFUNC(gui,caption), _headW, _headFont, _headSize] call EFUNC(gui,fitText);

[
    _display, controlNull, [_textX, _headTop, _headW, _titleTop + _titleH - _headTop], _title, _headSize,
    _theme getOrDefault ["text", [1, 1, 1, 1]], _headFont, 0
] call EFUNC(gui,uiLabel);

// A hairline under the title row, as the columns of the inventory have under theirs.
[
    _display, controlNull, [_left + _padX, _titleTop + _titleH + _padY * 0.4, _width - _padX * 2, pixelH], _theme getOrDefault ["line", []]
] call EFUNC(gui,uiPanel);

// The column over the block: the same theme, without a background of its own.
private _columnTheme = +_theme;
_columnTheme set ["panel", []];
_columnTheme set ["panelBorder", []];

// Each section as the inventory draws it; the staging one with its subtitle beside its caption's tab,
// between the tab and the weight - left out where the panel is too narrow for it.
private _fnc_draw = {
    params ["_display", "_group", "_top", "_width", "_section", "_theme"];

    // The staging space reaches down to the hint line: at least the rows that fill what the sections above
    // leave of the column - under its caption line and the gap below it, as einv_gui_fnc_drawSection draws
    // them -, more as what lies in it needs (fnc_growStaging), and those scroll. Sized before it is drawn.
    if ((_section getOrDefault ["id", ""]) isEqualTo "staging") then {
        (call EFUNC(gui,getCell)) params ["", "_cellH"];

        private _free = ((ctrlPosition _group) select 3) - _top - UNIT * (0.62 + 0.25) - pixelH * 2;

        [_section get "container", floor (_free / _cellH)] call FUNC(growStaging);
    };

    private _used = _this call EFUNC(gui,drawSection);

    if ((_section getOrDefault ["id", ""]) isEqualTo "staging") then {
        private _infos = (uiNamespace getVariable [QEGVAR(gui,sectionInfo), []]) select {
            (_x getOrDefault ["holder", objNull]) isEqualTo (_section get "container")
        };

        if (_infos isEqualTo []) exitWith {};

        private _info = _infos select (count _infos - 1);
        private _tab = _info getOrDefault ["tab", []];

        if (_tab isEqualTo []) exitWith {};

        (ctrlPosition (_tab select 0)) params ["", "_tabY", "", "_tabH"];

        private _tabRight = 0;

        {
            (ctrlPosition _x) params ["_tabX", "", "_tabW"];
            _tabRight = _tabRight max (_tabX + _tabW);
        } forEach _tab;

        private _load = _info getOrDefault ["load", controlNull];
        private _end = if (isNull _load) then {_width} else {(ctrlPosition _load) select 0};
        private _gapX = SQUARE(UNIT * 0.3);
        private _textX = _tabRight + _gapX;
        private _textW = _end - _gapX - _textX;
        private _font = _theme getOrDefault ["font", "PuristaMedium"];

        // The caption line's own text size, from the same top as the tab's text and the weight's: one
        // baseline all along the line (einv_gui_fnc_drawSection).
        private _size = UNIT * 0.46;

        if (_textW < SQUARE(UNIT * 1.5)) exitWith {};

        [
            _display, _group, [_textX, _tabY, _textW, _tabH],
            [LLSTRING(Staging_Subtitle), _textW, _font, _size] call EFUNC(gui,fitText), _size,
            _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]], _font, 0
        ] call EFUNC(gui,uiLabel);
    };

    _used
};

[_display, [_left, _bodyTop, _width, _columnH], _sections, _columnTheme, "", "", _fnc_draw, "storage"] call EFUNC(gui,drawColumn);

GVAR(panelRect) = _rect;
// The hint line's band (fnc_footer).
GVAR(hintRect) = [_left, _hintTop, _width, _hintH];

// The whole block is the panel, the title row and the hint line too: a drag let go over them is no drop
// outside.
EGVAR(gui,panels) pushBack _rect;

// ACE's list takes back what is let go outside the panel.
if (!isNull _list) then {
    private _zones = uiNamespace getVariable [QEGVAR(gui,zones), []];

    GVAR(removeZone) = count _zones;
    _zones pushBack [ctrlPosition _list, "remove"];

    uiNamespace setVariable [QEGVAR(gui,zones), _zones];
};

[]
