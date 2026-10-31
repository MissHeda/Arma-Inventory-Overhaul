#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The tree view of a class list (Items and Containers steps), drawn into the box fnc_drawResults keeps
 * for the list: one class, and every class built on it as an indented tree - each row with its picture,
 * name, class, how many classes are built on it, and what the draft makes of it with where that comes
 * from (fnc_answerLine: "6x4 (your rule)", "6x4 (inherited from B_Carryall_Base)", "(preset)").
 *
 * A click on a row picks that class for the editor beside it with everything built on it (GVAR(editScope)
 * "tree"): Apply there writes one rule, class=X+, for the whole branch. The arrow at the end of a row
 * starts the tree at that class instead; "Up one level" starts it at the class above, which is how a
 * family is found whose members share a hidden base nobody can pick (B_Carryall_Base). The tree starts at
 * the class picked in the list when the view is switched on (GVAR(treeState) "root", lowercase).
 *
 * The tree view is opened by a button of the list (fnc_drawClassList), which starts it where the picked class stands
 * in its family (fnc_treeTop) with that class ringed and its page - the first drawing finds it by GVAR(treeState)
 * "focus" - turned to and scrolled to. "Go to picked" does the same again after the tree has moved away.
 *
 * The search of the list filters the rows (wildcards too), and so does "only with own rules". The rows of
 * LIST_PAGE to a page are drawn, as the cards are.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group the list keeps its cards in <CONTROL>
 * 2: Its width <NUMBER>
 * 3: Its height <NUMBER>
 * 4: Theme <HASHMAP>
 * 5: Step: "items" or "containers" <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _box, 0.2, 0.5, _theme, "containers"] call aio_setup_fnc_drawTree;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_box", "_width", "_height", "_theme", ["_mode", "items", [""]]];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText = _theme getOrDefault ["text", [1, 1, 1, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _muted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
private _accent = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];
private _radius = (_theme getOrDefault ["radius", 0]) min (UNIT * 0.3);

private _state = GVAR(treeState) getOrDefault [_mode, createHashMap];
private _picked = toLowerANSI (GVAR(selection) getOrDefault [_mode, ""]);
private _root = _state getOrDefault ["root", ""];

if (_root isEqualTo "") then {
    _root = _picked;
};

// ----- Nothing to start from -----

if (_root isEqualTo "") exitWith {
    [_display, _box, [0, UNIT * 0.2, _width], LLSTRING(Tree_PickFirst), TEXT_SMALL, _colorText2, _font] call FUNC(uiText);
};

private _rows = ([_root, _mode] call FUNC(treeRows)) getOrDefault ["rows", []];

if (_rows isEqualTo []) exitWith {
    [_display, _box, [0, UNIT * 0.2, _width], format [LLSTRING(Tree_Unknown), _root], TEXT_SMALL, _colorText2, _font] call FUNC(uiText);
};

(_rows select 0) params ["", "_rootClass", "_rootTitle", "", "_rootBelow"];

private _tree = [_root] call FUNC(classTree);
private _rootName = _tree get "root";

// ----- Where it starts, and the way up -----

private _cursorY = 0;

[
    _display, _box, [0, _cursorY, _width, UNIT * 0.85],
    [format [LLSTRING(Tree_Of), _rootTitle], _width, _fontBold, TEXT_BODY] call EFUNC(gui,fitText), TEXT_BODY, _colorText, _fontBold, 0
] call EFUNC(gui,uiLabel);

private _count = [format [LLSTRING(Tree_CountOne), _rootBelow], format [LLSTRING(Tree_Count), _rootBelow]] select (_rootBelow != 1);

[
    _display, _box, [0, _cursorY + UNIT * 0.85, _width, UNIT * 0.65],
    [format ["%1 · %2", _rootClass, _count], _width, _font, TEXT_SMALL] call EFUNC(gui,fitText), TEXT_SMALL, _muted, _font, 0
] call EFUNC(gui,uiLabel);

_cursorY = _cursorY + UNIT * 1.6;

private _buttonH = UNIT * 1;
private _gapX = SQUARE(UNIT * 0.3);
private _parent = _tree get "parent";

// A parent with more under it than TREE_UP_MAX is too broad to be one edit.
private _parentTree = [_parent] call FUNC(classTree);
private _canUp = _parent isNotEqualTo "" && {count (_parentTree getOrDefault ["order", []]) <= TREE_UP_MAX};
private _upTip = if (_canUp) then {
    format [LLSTRING(Tree_UpTip), _parentTree getOrDefault ["class", _parent]]
} else {
    [LLSTRING(Tree_UpNone), LLSTRING(Tree_UpTooBroad)] select (_parent isNotEqualTo "")
};
private _upW = ACTION_W(LLSTRING(Tree_Up),_buttonH,true,_font);

[_display, _box, [0, _cursorY, _upW, _buttonH], LLSTRING(Tree_Up), UI_TEX(icon_chevron_left_ca), _theme, {
    params ["_mode", "_parent"];

    private _state = GVAR(treeState) get _mode;

    _state set ["root", _parent];
    _state set ["page", 0];

    [] call FUNC(drawResults);
}, [_mode, _parent], _canUp, "", _upTip] call FUNC(uiAction);

// Back to the class picked in the list, when the tree has moved away from it.
if (_root isNotEqualTo _picked && {_picked isNotEqualTo ""}) then {
    private _pickedW = ACTION_W(LLSTRING(Tree_ToPicked),_buttonH,false,_font);

    [_display, _box, [_upW + _gapX, _cursorY, _pickedW, _buttonH], LLSTRING(Tree_ToPicked), "", _theme, {
        params ["_mode", "_picked"];

        private _state = GVAR(treeState) get _mode;

        _state set ["root", [_picked] call FUNC(treeTop)];
        _state set ["page", 0];
        _state set ["focus", _picked];

        [] call FUNC(drawResults);
    }, [_mode, _picked], true, "", LLSTRING(Tree_ToPickedTip)] call FUNC(uiAction);
};

_cursorY = _cursorY + _buttonH + UNIT * 0.3;

// ----- The rows the search and the switch let through -----

(GVAR(listState) getOrDefault [_mode, []]) params [["_text", "", [""]], "", ["_ownOnly", false, [false]]];

private _filter = [_text] call FUNC(searchFilter);
private _named = ([] call FUNC(ownClassRules)) select 1;
private _ownKeys = [["footprint", "stack"], ["grid", "like"]] select (_mode isEqualTo "containers");

private _matches = _rows select {
    _x params ["_lc", "", "_title"];

    (!_ownOnly || {private _keys = _named getOrDefault [_lc, createHashMap]; (_ownKeys findIf {_x in _keys}) >= 0})
    && {[_filter, _lc + " " + toLower _title, _lc, _title] call FUNC(searchHit)}
};

// Opened for a class: the page it is on, and where on it. Asked once.
private _focus = _state getOrDefault ["focus", ""];
private _focusRow = -1;

if (_focus isNotEqualTo "") then {
    private _at = _matches findIf {(_x select 0) isEqualTo _focus};

    if (_at >= 0) then {
        _state set ["page", floor (_at / LIST_PAGE)];
        _focusRow = _at mod LIST_PAGE;
    };

    _state set ["focus", ""];
};

private _total = count _matches;
private _pages = (ceil (_total / LIST_PAGE)) max 1;
private _page = (((_state getOrDefault ["page", 0]) min (_pages - 1)) max 0);

_state set ["page", _page];

private _shown = _matches select [_page * LIST_PAGE, LIST_PAGE];

// ----- Pages -----

private _footH = UNIT * 1.05;
private _footY = _height - _footH;

[_display, _box, [0, _footY, _width, _footH], _theme, _page, _pages, _total, count _shown, LIST_PAGE, {
    params ["_mode", "_step"];

    private _state = GVAR(treeState) get _mode;

    _state set ["page", ((_state getOrDefault ["page", 0]) + _step) max 0];

    [] call FUNC(drawResults);
}, _mode] call FUNC(drawPager);

// ----- The rows -----

private _list = [_display, "AIO_ScrollGroup", _box, [0, _cursorY, _width, _footY - UNIT * 0.2 - _cursorY]] call EFUNC(gui,uiCreate);

_list setVariable [QGVAR(scrollId), "tree_" + _mode];

// The class that was asked for is a few rows down: the list is scrolled so it is in view, the row above it at the
// top. A scroll value is a share of how far the list can scroll (its rows' height less its own), not a height.
private _rowPitch = TREE_ROW_H + UNIT * 0.2;
private _travel = (count _shown) * _rowPitch - UNIT * 0.2 - (_footY - UNIT * 0.2 - _cursorY);

if (_focusRow > 1 && {_travel > 0}) then {
    [{
        params ["_list", "_share"];

        if (!isNull _list) then {
            _list ctrlSetScrollValues [_share, -1];
        };
    }, [_list, (((_focusRow - 1) * _rowPitch) / _travel) min 1], 0.1] call FUNC(defer);
};

if (_shown isEqualTo []) then {
    [_display, _list, [SQUARE(UNIT * 0.2), UNIT * 0.1, _width, UNIT * 0.8], LLSTRING(List_None), TEXT_SMALL, _muted, _font, 0] call EFUNC(gui,uiLabel);
};

private _rowW = _width - SCROLL_W - SQUARE(UNIT * 0.25);
private _gap = UNIT * 0.2;
private _picH = TREE_ROW_H - UNIT * 0.4;
private _picW = SQUARE(_picH);
private _stepW = SQUARE(UNIT * 1.1);
private _fill = [1, 1, 1, 0.035];
private _fillPicked = _theme getOrDefault ["accentSoft", [0.84, 0.54, 0.1, 0.2]];

{
    _x params ["_lc", "_class", "_title", "_depth", "_below"];

    // The first row is the tree's own start; classes a step lists below it are moved in a level each.
    private _indent = (_depth min TREE_INDENT_MAX) * TREE_INDENT;
    private _cardX = _indent;
    private _cardW = _rowW - _indent;
    private _cardY = _forEachIndex * (TREE_ROW_H + _gap);
    private _isPicked = _lc isEqualTo _picked;
    private _cardFill = [_fill, _fillPicked] select _isPicked;
    private _surface = [_display, _list, [_cardX, _cardY, _cardW, TREE_ROW_H], _cardFill, _radius] call EFUNC(gui,uiPanel);

    if (_isPicked) then {
        [_display, _list, [_cardX, _cardY, _cardW, TREE_ROW_H], _accent, _radius] call EFUNC(gui,uiRing);
    };

    // The picture of the class itself, only when it can be shown (aio_gui_fnc_safePicture).
    private _picture = [getText (configFile >> _rootName >> _class >> "picture")] call EFUNC(gui,safePicture);

    if (_picture isNotEqualTo "") then {
        [_display, _list, [_cardX + SQUARE(UNIT * 0.2), _cardY + UNIT * 0.2, _picW, _picH], _picture] call EFUNC(gui,uiPicture);
    };

    // The arrow at the end starts the tree at this class, for a class with something below it.
    private _canStart = _below > 0 && {_lc isNotEqualTo _root};
    private _textX = _cardX + SQUARE(UNIT * 0.2) + _picW + SQUARE(UNIT * 0.35);
    private _textW = _cardX + _cardW - _textX - SQUARE(UNIT * 0.2) - ([0, _stepW + SQUARE(UNIT * 0.1)] select _canStart);

    [
        _display, _list, [_textX, _cardY + UNIT * 0.1, _textW, UNIT * 0.75],
        [_title, _textW, _fontBold, TEXT_BODY] call EFUNC(gui,fitText), TEXT_BODY, _colorText, _fontBold, 0
    ] call EFUNC(gui,uiLabel);

    private _about = [_class, format ["%1 · %2", _class, format [LLSTRING(Tree_Below), _below]]] select (_below > 0);

    [
        _display, _list, [_textX, _cardY + UNIT * 0.8, _textW, UNIT * 0.65],
        [_about, _textW, _font, TEXT_SMALL] call EFUNC(gui,fitText), TEXT_SMALL, _muted, _font, 0
    ] call EFUNC(gui,uiLabel);

    ([_class, _mode] call FUNC(answerLine)) params ["_answer", "_isOwn"];

    [
        _display, _list, [_textX, _cardY + UNIT * 1.45, _textW, UNIT * 0.65],
        [_answer, _textW, _font, TEXT_SMALL] call EFUNC(gui,fitText), TEXT_SMALL, [_colorText2, _accent] select _isOwn, _font, 0
    ] call EFUNC(gui,uiLabel);

    // The whole row picks the class with everything built on it.
    [_display, _list, [_cardX, _cardY, _cardW, TREE_ROW_H], _surface, _cardFill, [1, 1, 1, 0.085], {
        params ["_mode", "_class"];

        GVAR(selection) set [_mode, _class];
        GVAR(editScope) set [_mode, "tree"];
        GVAR(groupEdit) deleteAt _mode;

        [GVAR(step)] call FUNC(showStep);
    }, [_mode, _class], true, _class] call FUNC(uiHit);

    // Made after the row's hit area, so it is on top of it.
    if (_canStart) then {
        [_display, _list, [_cardX + _cardW - _stepW - SQUARE(UNIT * 0.1), _cardY + (TREE_ROW_H - _stepW) / 2, _stepW, _stepW], "", UI_TEX(icon_chevron_right_ca), _theme, {
            params ["_mode", "_lc"];

            private _state = GVAR(treeState) get _mode;

            _state set ["root", _lc];
            _state set ["page", 0];

            [] call FUNC(drawResults);
        }, [_mode, _lc], true, "ghost", LLSTRING(Tree_Start)] call FUNC(uiAction);
    };
} forEach _shown;
