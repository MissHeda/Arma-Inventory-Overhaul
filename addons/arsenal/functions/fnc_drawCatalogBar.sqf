#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws the bar of the catalog again, on its own: the groups, the chips of the group's categories, and the
 * row of favorites, "fits" and sort. It changes whenever the catalog's state does, without the pool of
 * cards being touched.
 *
 * The chips take two lines; those that do not fit go behind a chip "More" (the column's
 * "moreCategories", fnc_openChoices). While the search field holds text the chips give way to a line that
 * says every category is searched. A group with nothing offered is greyed out.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_arsenal_fnc_drawCatalogBar;
 *
 * Public: No
 */

disableSerialization;

private _column = uiNamespace getVariable [QGVAR(column), createHashMap];
private _items = _column getOrDefault ["itemsGroup", controlNull];
private _display = uiNamespace getVariable [QEGVAR(gui,display), displayNull];

if (isNull _items || {isNull _display}) exitWith {};

ctrlDelete (_column getOrDefault ["bar", controlNull]);

private _theme = EGVAR(gui,theme);
private _inner = _column get "inner";
private _rect = _column get "rect";
private _barW = _inner select 2;
private _barH = _column get "barH";

private _bar = _display ctrlCreate ["EINV_Group", -1, _items];

_bar ctrlSetPosition [0, 0, _barW, _barH];
_bar ctrlCommit 0;
_bar setVariable [QEGVAR(gui,hooked), true];
_bar ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call EFUNC(gui,onMouseButton)}];
_bar ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call EFUNC(gui,onMouseButton)}];
_bar ctrlAddEventHandler ["MouseZChanged", {[_this] call EFUNC(gui,onMouseZ)}];

_column set ["bar", _bar];

private _categories = call FUNC(categories);
private _searching = EGVAR(gui,filter) isNotEqualTo "";
private _font = _theme getOrDefault ["font", "RobotoCondensed"];
private _fontBold = _theme getOrDefault ["fontBold", "RobotoCondensedBold"];
private _accent = _theme getOrDefault ["accent", [0.961, 0.647, 0.141, 1]];
private _onAccent = _theme getOrDefault ["onAccent", [0.086, 0.094, 0.114, 1]];
private _text2 = _theme getOrDefault ["text2", [0.698, 0.734, 0.784, 1]];
private _muted = _theme getOrDefault ["muted", [0.522, 0.553, 0.604, 1]];

// ----- The groups: one film, the picked part filled with the accent -----
private _groupH = UNIT * 1.2;
private _groups = [
    ["weapons", LLSTRING(Group_Weapons)], ["parts", LLSTRING(Group_Parts)], ["ammo", LLSTRING(Group_Ammo)],
    ["gear", LLSTRING(Group_Gear)], ["items", LLSTRING(Group_Items)], ["identity", LLSTRING(Group_Identity)]
];

// Identity is left out when there is none to choose from (the editor, ACE's tabs off).
if ((_categories findIf {(_x select 1) isEqualTo "identity"}) < 0) then {
    _groups deleteAt 5;
};

private _radius = (_theme getOrDefault ["radius", 0]) min (_groupH / 2);
private _partW = _barW / (count _groups);
private _insetX = pixelW * 2;
private _insetY = pixelH * 2;

[_display, _bar, [0, 0, _barW, _groupH], _theme getOrDefault ["button", [1, 1, 1, 0.08]], _radius] call EFUNC(gui,uiPanel);

{
    _x params ["_id", "_label"];

    private _current = _id isEqualTo GVAR(group);
    private _offered = (_categories findIf {(_x select 1) isEqualTo _id}) >= 0;
    private _partX = _forEachIndex * _partW;
    private _fill = [[0, 0, 0, 0], _accent] select _current;
    private _ink = if (_current) then {_onAccent} else {[_muted, _text2] select _offered};
    private _partFont = [_font, _fontBold] select _current;
    private _size = _groupH * 0.5;

    private _surface = [
        _display, _bar, [_partX + _insetX, _insetY, _partW - _insetX * 2, _groupH - _insetY * 2], _fill, (_radius - _insetY) max 0
    ] call EFUNC(gui,uiPanel);

    [
        _display, _bar, [_partX, 0, _partW, _groupH], [_label, _partW * 0.9, _partFont, _size] call EFUNC(gui,fitText),
        _size, _ink, _partFont, 2
    ] call EFUNC(gui,uiLabel);

    [_display, _bar, [_partX, 0, _partW, _groupH], _surface, _fill, [1, 1, 1, 0.06], {
        params ["_groupId"];

        private _categories = call FUNC(categories);
        private _inGroup = _categories select {(_x select 1) isEqualTo _groupId};

        if (_inGroup isEqualTo []) exitWith {};

        // The category last shown in the group, else its first.
        private _last = GVAR(lastCategory) getOrDefault [_groupId, ""];
        private _lastIndex = _inGroup findIf {(_x select 0) isEqualTo _last};
        private _target = (_inGroup select (_lastIndex max 0)) select 0;

        [_target] call FUNC(showCategory);
    }, [_id], _offered && {!_current}] call EFUNC(setup,uiHit);
} forEach _groups;

// ----- Chips -----
private _chipH = UNIT * 0.95;
private _chipGapX = SQUARE(UNIT * 0.25);
private _chipGapY = UNIT * 0.2;
private _chipPad = SQUARE(_chipH * 0.45);
private _chipSize = _chipH * 0.52;
private _iconW = SQUARE(_chipH * 0.45);
private _chipsY = _groupH + UNIT * 0.3;
private _originX = (_rect select 0) + (_inner select 0);
private _originY = (_rect select 1) + (_inner select 1);

// How wide a chip is; the arrow after the text takes its own room.
private _fnc_width = {
    params ["_label", ["_icon", false]];

    ((_label getTextWidth [_fontBold, _chipSize]) * TEXT_SLACK + _chipPad * 2 + ([0, _iconW + _chipPad * 0.5] select _icon)) min _barW
};

// A chip with an arrow or a direction after its text; a click opens the menu named, under the chip.
private _fnc_menuChip = {
    params ["_x0", "_y0", "_width", "_label", "_on", "_icon", "_what"];

    [_display, _bar, [_x0, _y0, _width, _chipH], _label, _on, _theme, {
        params ["", "_arguments"];

        _arguments call FUNC(openChoices);
    }, [_what, [_originX + _x0, _originY + _y0, _width, _chipH]]] call EFUNC(setup,uiChip);

    [
        _display, _bar, [_x0 + _width - _chipPad - _iconW, _y0 + (_chipH - _iconW) / 2, _iconW, _iconW], _icon,
        [_text2, _onAccent] select _on
    ] call EFUNC(gui,uiIcon);
};

if (_searching) then {
    [
        _display, _bar, [0, _chipsY, _barW, _chipH], LLSTRING(Catalog_SearchAll), _chipSize, _muted, _font, 0
    ] call EFUNC(gui,uiLabel);

    _column set ["moreCategories", []];
} else {
    private _cats = _categories select {(_x select 1) isEqualTo GVAR(group)};
    private _widths = _cats apply {[_x select 2] call _fnc_width};
    private _moreW = [LLSTRING(Cat_More), true] call _fnc_width;

    // Chips by line; what does not go on two lines is left over.
    private _fnc_flow = {
        params ["_reserve"];

        private _placed = [];
        private _rest = [];
        private _lineX = 0;
        private _line = 0;

        {
            private _w = _widths select _forEachIndex;

            if (_line < 2) then {
                private _limit = _barW - ([0, _reserve] select (_line == 1));

                if (_lineX > 0 && {_lineX + _w > _limit}) then {
                    _line = _line + 1;
                    _lineX = 0;
                    _limit = _barW - ([0, _reserve] select (_line == 1));
                };

                if (_line < 2) then {
                    _placed pushBack [_x, _lineX, _line, _w];
                    _lineX = _lineX + _w + _chipGapX;
                } else {
                    _rest pushBack _x;
                };
            } else {
                _rest pushBack _x;
            };
        } forEach _cats;

        [_placed, _rest, _lineX]
    };

    private _flow = [0] call _fnc_flow;

    if ((_flow select 1) isNotEqualTo []) then {
        _flow = [_moreW + _chipGapX] call _fnc_flow;
    };

    _flow params ["_placed", "_rest", "_endX"];

    {
        _x params ["_category", "_chipX", "_line", "_w"];

        [
            _display, _bar, [_chipX, _chipsY + _line * (_chipH + _chipGapY), _w, _chipH], _category select 2,
            (_category select 0) isEqualTo GVAR(category), _theme, {
                params ["", "_id"];

                [_id] call FUNC(showCategory);
            }, _category select 0
        ] call EFUNC(setup,uiChip);
    } forEach _placed;

    _column set ["moreCategories", _rest apply {[_x select 0, _x select 2]}];

    if (_rest isNotEqualTo []) then {
        [
            _endX, _chipsY + _chipH + _chipGapY, _moreW, LLSTRING(Cat_More),
            (_rest findIf {(_x select 0) isEqualTo GVAR(category)}) >= 0, UI_TEX(icon_chevron_down_ca), "more"
        ] call _fnc_menuChip;
    };
};

// ----- The row of favorites, fits and sort -----
private _rowY = _groupH + UNIT * 0.3 + _chipH * 2 + _chipGapY + UNIT * 0.25 + (UNIT - _chipH) / 2;
private _rowX = 0;

if (GVAR(group) isNotEqualTo "identity") then {
    private _label = LLSTRING(Filter_Favorites);
    private _w = [_label] call _fnc_width;

    [_display, _bar, [_rowX, _rowY, _w, _chipH], _label, missionNamespace getVariable [QACEGVAR(arsenal,favoritesOnly), false], _theme, {
        params ["_state"];

        missionNamespace setVariable [QACEGVAR(arsenal,favoritesOnly), _state];

        private _column = uiNamespace getVariable [QGVAR(column), createHashMap];

        _column set ["dirty", true];
        _column set ["barDirty", true];
    }] call EFUNC(setup,uiChip);

    _rowX = _rowX + _w + _chipGapX;
};

if (_column getOrDefault ["fitsApplies", false] && {!_searching}) then {
    private _label = _column getOrDefault ["fitsLabel", LLSTRING(Filter_FitsAny)];
    private _w = [_label, true] call _fnc_width;

    [_rowX, _rowY, _w, _label, false, UI_TEX(icon_chevron_down_ca), "fits"] call _fnc_menuChip;
};

private _sortId = GVAR(sort) param [0, "name"];
private _sortLabel = switch (_sortId) do {
    case "weight": {LLSTRING(Sort_Weight)};
    case "size": {LLSTRING(Sort_Size)};
    case "mod": {LLSTRING(Sort_Mod)};
    default {
        // One of ACE's sorts holds for the category shown, and not for a search over all of them: where it
        // does not, the list is sorted by name (fnc_catalogList) and the chip says so.
        private _title = "";

        if ((_sortId select [0, 4]) isEqualTo "ace|") then {
            _title = ["label", _sortId, [GVAR(category), ""] select _searching] call FUNC(aceSorts);
        };

        [_title, LLSTRING(Sort_Name)] select (_title isEqualTo "")
    };
};
private _sortW = [_sortLabel, true] call _fnc_width;

[
    _barW - _sortW, _rowY, _sortW, _sortLabel, false,
    [UI_TEX(icon_sort_desc_ca), UI_TEX(icon_sort_asc_ca)] select (GVAR(sort) param [1, true]), "sort"
] call _fnc_menuChip;

_column set ["barDirty", false];
