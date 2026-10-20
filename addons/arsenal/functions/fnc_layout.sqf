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
 * The button at the right end of the title row folds the whole panel (GVAR(collapsed), fnc_toggleCollapse):
 * folded, the panel is a small square button with the inventory's picture at the panel's right edge and nothing
 * else - no column, staging space or hint line is made, and the panel's rectangle (GVAR(panelRect), the
 * engine's panels) is that square, so ACE's controls and its 3D view behind the rest answer the mouse as without
 * the panel. A click on it unfolds the panel. Unfolded, the column is scrolled to where it stood when it was folded.
 *
 * The other worn containers are sections of the column too, folded to their captions at first (key "other_" +
 * class in GVAR(folded) once opened), between the open container and the staging space, so that things can be
 * dragged between all three; the staging space is the same one in every tab.
 *
 * With a kit of Enhanced First Aid Kits picked in ACE's left list (fnc_focusedKit), in any tab, the panel shows
 * that kit's grid instead of the containers - one section per kit of that type that lies in a worn container or
 * the staging space (fnc_kitSections) - and the staging space below: things are dragged out of ACE's list into
 * it, out of it, and to and from the staging space. No kit is shown otherwise.
 *
 * Switching ACE's tab (or the kit picked) folds the panel anew: the section of what was picked open, every other
 * container's folded, the staging space as it was (GVAR(foldTab)).
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

if (!GVAR(shown)) exitWith {[]};

// The whole panel folded to its title row (the button in it).
private _collapsed = GVAR(collapsed);

// A kit picked in ACE's left list: its grid (with the staging space) is shown in place of the container, in
// any tab (fnc_focusedKit, fnc_kitSections). With no kit picked no kit is shown.
GVAR(focusKit) = ["", [_display] call FUNC(focusedKit)] select (!isNil QEFUNC(compat_efak,arsenalSections));

// Folded, no staging space is looked at: the crate is made when the panel unfolds.
private _holder = if (_collapsed) then {objNull} else {[] call FUNC(staging)};
private _kitSections = [];

// Which class or key each section of this build folds by (the "fold" hook): emptied before the kit sections note
// theirs (fnc_kitSections), so a kit's section folds by hand too.
GVAR(foldKeys) = [];

if (GVAR(focusKit) isNotEqualTo "") then {
    private _worn = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];

    _kitSections = [_display, [uniformContainer _worn, vestContainer _worn, backpackContainer _worn, _holder]] call FUNC(kitSections);
} else {
    // No kit section: where the last ones lay is forgotten (einv_compat_efak_fnc_arsenalSections).
    if (!isNil QEFUNC(compat_efak,arsenalSections)) then {
        [[]] call EFUNC(compat_efak,arsenalSections);
    };
};

private _kitMode = _kitSections isNotEqualTo [];

// Another tab of ACE's left bar - uniform, vest, backpack, any other -, or a kit picked in its left list: the
// panel is folded anew. The section of what was picked is open (the open container, or the kit's), every other
// container's section folded to its caption, the staging space as it was; folds by hand hold until the next
// switch. The order of the sections and the column's scroll stay as they are.
private _tab = [_id, "kit:" + GVAR(focusKit)] select _kitMode;

if (_tab isNotEqualTo GVAR(foldTab)) then {
    GVAR(foldTab) = _tab;

    private _stagingFolded = "staging" in GVAR(folded);

    GVAR(folded) = createHashMap;

    if (_stagingFolded) then {
        GVAR(folded) set ["staging", true];
    };

    {
        _x set ["folded", false];
    } forEach _kitSections;
};

if (_kitMode) then {
    _container = objNull;
};

private _index = (_context getOrDefault ["ownSections", []]) findIf {(_x getOrDefault ["container", objNull]) isEqualTo _container};

if (!_kitMode && {_id isEqualTo "" || {_index < 0}}) exitWith {[]};

private _section = if (_kitMode) then {_kitSections select 0} else {(_context get "ownSections") select _index};
private _rect = [_display, _container] call FUNC(panelRect);

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
// The other worn containers start folded (a closed section is open once its key is in the list).
private _fnc_fold = {
    params ["_section", "_key", ["_closed", false]];

    private _object = _section get "container";
    private _folded = (_key in GVAR(folded)) isNotEqualTo _closed;

    _section set ["folded", _folded isNotEqualTo (_object in EGVAR(gui,collapsed))];
    GVAR(foldKeys) pushBack [_object, _key];
};

if (!_kitMode) then {
    [_section, toLowerANSI (_section getOrDefault ["class", ""])] call _fnc_fold;
};

// The title row names and pictures the container: no box with its picture beside the grid.
_section set ["box", false];

private _sections = [_section];

// A kit's grids, one per kit of the type: all of them in place of the containers.
if (_kitMode) then {
    _sections = +_kitSections;
};

// The other worn containers beside it, folded to their captions and unfolded by a click on them, so that things
// can be dragged between all three; the staging space below is the same one in every tab. The order is always
// uniform, vest, backpack: the open tab only decides which of them is unfolded.
if (!_collapsed && {!_kitMode}) then {
    private _center = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];
    private _order = [uniformContainer _center, vestContainer _center, backpackContainer _center];
    private _all = [];

    {
        private _other = _x;
        private _otherContainer = _other getOrDefault ["container", objNull];

        if (!isNull _otherContainer) then {
            _other set ["box", false];

            if (_otherContainer isNotEqualTo _container) then {
                [_other, "other_" + toLowerANSI (_other getOrDefault ["class", ""]), true] call _fnc_fold;
            };

            _all pushBack [_order find _otherContainer, _other];
        };
    } forEach (_context getOrDefault ["ownSections", []]);

    _all sort true;
    _sections = _all apply {_x select 1};
};

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

// Folded, the panel is a small square button with the inventory's picture at the panel's right edge, by ACE's
// list. It is one surface, the panel's colour, with no second square (the header buttons' film) inside it and
// no frame: lighter under the mouse like the other header buttons. A click on it unfolds the panel.
if (_collapsed) exitWith {
    private _side = SNAP_H(_padY * 2 + _titleH);
    private _squareW = SQUARE(_side);

    _rect = [SNAP_X(_left + _width - _squareW), _top, SNAP_W(_squareW), _side];

    ([_theme, false] call EFUNC(gui,headerStyle)) params ["_fill", "_hover", "_ink"];

    private _surface = +(_theme getOrDefault ["panel", _fill]);
    private _surfaceHover = +_hover;

    if (count _surface >= 4) then {
        _surfaceHover = [
            (_surface select 0) + (1 - (_surface select 0)) * 0.14,
            (_surface select 1) + (1 - (_surface select 1)) * 0.14,
            (_surface select 2) + (1 - (_surface select 2)) * 0.14,
            _surface select 3
        ];
    } else {
        _surface = _fill;
    };

    private _unfoldTheme = createHashMap;
    _unfoldTheme merge _theme;
    _unfoldTheme set ["button", _surface];
    _unfoldTheme set ["buttonHover", _surfaceHover];
    _unfoldTheme set ["buttonText", _ink];

    private _unfold = [
        _display, controlNull, _rect, "collapse", "",
        UI_TEX(icon_inventory_ca), _unfoldTheme, {[] call FUNC(toggleCollapse)}
    ] call EFUNC(gui,uiButton);

    // The button takes no keyboard focus: a focused button draws the engine's frame round itself.
    (_unfold select -1) ctrlAddEventHandler ["SetFocus", {
        params ["_ctrl"];
        private _list = (ctrlParent _ctrl) displayCtrl ARSENAL_IDC_LIST;

        if (!isNull _list) then {
            ctrlSetFocus _list;
        };
    }];

    (_unfold select -1) ctrlSetTooltip LLSTRING(Collapse_Unfold);

    // Where the column was scrolled to is kept for the unfolding.
    private _pixels = (uiNamespace getVariable [QEGVAR(gui,keepPixels), createHashMap]) getOrDefault ["storage", -1];

    if (_pixels >= 0) then {
        GVAR(collapsedScroll) = [_section getOrDefault ["class", ""], _pixels];
    };

    GVAR(panelRect) = _rect;
    EGVAR(gui,panels) pushBack _rect;

    []
};

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

// The fold button is a square as high as the row at its right end; the name ends a gap before it.
private _buttonW = SQUARE(_titleH);
private _headW = _left + _width - _padX - _textX - _buttonW - SQUARE(_titleH * 0.3);
private _title = [[_section getOrDefault ["title", ""], _theme] call EFUNC(gui,caption), _headW, _headFont, _headSize] call EFUNC(gui,fitText);

[
    _display, controlNull, [_textX, _headTop, _headW, _titleTop + _titleH - _headTop], _title, _headSize,
    _theme getOrDefault ["text", [1, 1, 1, 1]], _headFont, 0
] call EFUNC(gui,uiLabel);

// The fold button, drawn as the header's buttons are (einv_gui_fnc_drawHeader): the dark surface one step lighter,
// lighter again under the mouse, a round shape as high as the row. The chevron is the sections': down while the
// panel is open, to the right once it is folded. The hit area is the button and 2 px (einv_gui_fnc_uiButton).
([_theme, false] call EFUNC(gui,headerStyle)) params ["_buttonFill", "_buttonHover", "_buttonInk"];

private _buttonTheme = createHashMap;
_buttonTheme merge _theme;
_buttonTheme set ["button", _buttonFill];
_buttonTheme set ["buttonHover", _buttonHover];
_buttonTheme set ["buttonText", _buttonInk];

private _button = [
    _display, controlNull, [_left + _width - _padX - _buttonW, _titleTop, _buttonW, _titleH], "collapse", "",
    UI_TEX(icon_chevron_down_ca), _buttonTheme,
    {[] call FUNC(toggleCollapse)}
] call EFUNC(gui,uiButton);

(_button select -1) ctrlSetTooltip LLSTRING(Collapse_Fold);

// A hairline under the title row, as the columns of the inventory have under theirs.
[
    _display, controlNull, [_left + _padX, _titleTop + _titleH + _padY * 0.4, _width - _padX * 2, pixelH], _theme getOrDefault ["line", []]
] call EFUNC(gui,uiPanel);

// Unfolded again: the column is scrolled to where it stood when the panel was folded, for the same container class
// (the engine hands the pixels on to the column it draws, einv_gui_fnc_drawColumn, fnc_build).
GVAR(collapsedScroll) params ["_scrollClass", "_scrollPixels"];

if (_scrollClass isEqualTo (_section getOrDefault ["class", ""]) && {_scrollPixels > 0}) then {
    (uiNamespace getVariable [QEGVAR(gui,keepPixels), createHashMap]) set ["storage", _scrollPixels];
};

GVAR(collapsedScroll) = ["", 0];

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

        private _free = ((ctrlPosition _group) select 3) - _top - UNIT * (CAPTION_LINE + 0.25) - pixelH * 2;

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

        // The tab is a pill as high as the section buttons now, its words set in the middle of its height (einv_gui_fnc_drawSection):
        // the subtitle is set the same way, in the same size, so that the one line of capitals runs on.
        private _size = UNIT * 0.42;

        if (_textW < SQUARE(UNIT * 1.5)) exitWith {};

        [
            _display, _group, [_textX, _tabY + _tabH / 2 - TEXT_MID * _size, _textW, TEXT_MID * _size * 2],
            [LLSTRING(Staging_Subtitle), _textW, _font, _size] call EFUNC(gui,fitText), _size,
            _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]], _font, 0
        ] call EFUNC(gui,uiLabel);
    };

    _used
};

// The scroll position is kept across every rebuild (einv_gui_fnc_build deleted the old group already, it kept the
// pixels): only another set of shown containers starts at the top. Set at once and a frame later, as a new group
// does not know its height before.
private _setKey = (_sections apply {_x getOrDefault ["class", ""]}) joinString "|";
private _keepMap = uiNamespace getVariable [QEGVAR(gui,keepPixels), createHashMap];
private _pixels = (_keepMap getOrDefault ["storage", 0]) max 0;

if (_pixels <= 0 && {GVAR(scrollKey) isEqualTo _setKey}) then {
    _pixels = GVAR(scrollPixels);
};

if (GVAR(scrollKey) isNotEqualTo _setKey) then {
    _pixels = 0;
};

GVAR(scrollKey) = _setKey;
_keepMap set ["storage", _pixels];

private _group = [_display, [_left, _bodyTop, _width, _columnH], _sections, _columnTheme, "", "", _fnc_draw, "storage"] call EFUNC(gui,drawColumn);

if (_pixels > 0 && {!isNull _group}) then {
    private _range = (_group getVariable [QEGVAR(gui,contentH), 0]) - ((ctrlPosition _group) select 3);

    if (_range > 0) then {
        _group ctrlSetScrollValues [(_pixels / _range) min 1, -1];
    };

    [{
        params ["_group", "_pixels"];

        if (isNull _group) exitWith {};

        private _range = (_group getVariable [QEGVAR(gui,contentH), 0]) - ((ctrlPosition _group) select 3);

        if (_range > 0) then {
            _group ctrlSetScrollValues [(_pixels / _range) min 1, -1];
        };
    }, [_group, _pixels]] call CBA_fnc_execNextFrame;
};

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
