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
 * The panel looks like ACE's own (fnc_theme): one flat block from the top of ACE's sort bar down to the
 * bottom of ACE's list (fnc_panelRect) with ACE's frame, the container's picture and name in the band
 * beside the sort bar in the sort bar's font - one sees what is being filled -, a black line under it where
 * ACE's list begins, and the column below, which scrolls over both sections. The column draws no background
 * of its own over the block.
 *
 * A section's caption folds it (einv_gui_fnc_toggleSection), kept per container class - the staging
 * space as "staging" - while ACE's window is open (the "fold" hook, GVAR(folded)), whatever the inventory
 * did with its own captions. The staging section has a crate before its caption and says beside its tab
 * that it is emptied when the arsenal closes; its grid grows with what lies in it (fnc_growStaging). ACE's
 * list is registered as a zone of the engine: whatever is let go outside the panel is shown going there,
 * out of the container (fnc_dragCheck).
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

private _sections = [_section];
private _holder = [] call FUNC(staging);

if (!isNull _holder) then {
    // Its rows follow what lies in it, before it is drawn.
    [_holder] call FUNC(growStaging);

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
        ["tabIcon", UI_TEX(icon_crate_ca)]
    ];

    [_staging, "staging"] call _fnc_fold;
    _sections pushBack _staging;

    // For the hint line: what would go with the arsenal's window.
    {
        GVAR(stagingCount) = GVAR(stagingCount) + _y;
    } forEach ([_holder] call FUNC(countAll));
};

// The title band: as tall as ACE's sort bar beside it, so the column starts where ACE's list does.
private _list = _display displayCtrl ARSENAL_IDC_LIST;
private _bodyTop = SNAP_Y((ctrlPosition _list) select 1);

if (_bodyTop - _top < UNIT * 0.5) then {
    _bodyTop = _top + SNAP_H(UNIT * HEAD_LINE_H);
};

private _hintH = SNAP_H(UNIT * HINT_LINE_H);
private _gap = SNAP_H(UNIT * HINT_LINE_GAP);
private _columnH = _top + _height - _bodyTop - _hintH - _gap;

if (_columnH < UNIT * 4) exitWith {[]};

// The block, flat and square in ACE's colour and frame.
[
    _display, controlNull, _rect, _theme getOrDefault ["panel", []], 0, _theme getOrDefault ["panelBorder", []]
] call EFUNC(gui,uiPanel);

// The container's picture and name in the band, the name in the font and size of ACE's sort bar, and ACE's
// black edge under it. The picture is as tall as the band, before the name: one sees what is being filled.
private _padX = SQUARE(UNIT * 0.4);
private _headFont = _theme getOrDefault ["headFont", _theme getOrDefault ["fontBold", "PuristaSemibold"]];
private _headSize = (_theme getOrDefault ["headSize", UNIT * 0.66]) min ((_bodyTop - _top) * 0.9);
private _picture = ([_section getOrDefault ["class", ""]] call EFUNC(items,getInfo)) getOrDefault ["picture", ""];
private _pictureW = [0, SQUARE(_bodyTop - _top)] select (_picture isNotEqualTo "");

if (_pictureW > 0) then {
    [_display, controlNull, [_left + _padX, _top, _pictureW, _bodyTop - _top], _picture] call EFUNC(gui,uiPicture);
    _pictureW = _pictureW + SQUARE(UNIT * 0.2);
};

private _title = [[_section getOrDefault ["title", ""], _theme] call EFUNC(gui,caption), _width - _padX * 2 - _pictureW, _headFont, _headSize] call EFUNC(gui,fitText);

[
    _display, controlNull, [_left + _padX + _pictureW, _top, _width - _padX * 2 - _pictureW, _bodyTop - _top], _title, _headSize,
    _theme getOrDefault ["text", [1, 1, 1, 1]], _headFont, 0
] call EFUNC(gui,uiLabel);

private _edgeColor = _theme getOrDefault ["panelBorder", []];

if (_edgeColor isNotEqualTo []) then {
    private _edge = [_display, "EINV_PanelRect", controlNull, [_left, _bodyTop - pixelH, _width, pixelH]] call EFUNC(gui,uiCreate);
    _edge ctrlSetBackgroundColor _edgeColor;
};

// The column over the block: the same theme, without a background of its own.
private _columnTheme = +_theme;
_columnTheme set ["panel", []];
_columnTheme set ["panelBorder", []];

// Each section as the inventory draws it; the staging one with its subtitle beside its caption's tab,
// between the tab and the weight - left out where the panel is too narrow for it.
private _fnc_draw = {
    params ["_display", "_group", "_top", "_width", "_section", "_theme"];

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
        private _size = _tabH * 0.68;

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
// Inside the frame, which stays visible round the hint line's darker bar.
GVAR(hintRect) = [_left + pixelW, _bodyTop + _columnH + _gap, _width - pixelW * 2, _hintH - pixelH];

// The whole block is the panel, the title band and the hint line too: a drag let go over them is no drop
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
