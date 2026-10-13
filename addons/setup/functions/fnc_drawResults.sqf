#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The cards of a class list (fnc_drawClassList), drawn again on their own - after typing in the search,
 * a page turned, or the class index done reading. Each card: picture, name, class, kind and mod, and what
 * the draft makes of the class (fnc_answerText) - the grid on the Containers step, the size and stack on
 * the Items step -, in the accent where an own rule decides it. The picked class is ringed.
 *
 * Only one page of LIST_PAGE cards is drawn, and only those are asked what the rules make of them: a
 * search that finds thousands costs no more than one that finds thirty. While the index is still being
 * read, a line says how far it is (fnc_indexChunk keeps it up to date and calls this when done).
 *
 * Its place and step come from uiNamespace QGVAR(resultsArgs), which fnc_drawClassList sets; nothing is
 * drawn when the step it belongs to is gone.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call einv_setup_fnc_drawResults;
 *
 * Public: No
 */

disableSerialization;

(uiNamespace getVariable [QGVAR(resultsArgs), []]) params [["_display", displayNull, [displayNull]], ["_parent", controlNull, [controlNull]], ["_rect", [], [[]]], ["_theme", createHashMap, [createHashMap]], ["_mode", "items", [""]]];

if (isNull _display || {isNull _parent}) exitWith {};

ctrlDelete (uiNamespace getVariable [QGVAR(results), controlNull]);

private _box = [_display, "EINV_Group", _parent, _rect] call EFUNC(gui,uiCreate);

uiNamespace setVariable [QGVAR(results), _box];

_rect params ["", "", "_width", "_height"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText = _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.698, 0.734, 0.784, 1]];
private _muted = _theme getOrDefault ["muted", [0.522, 0.553, 0.604, 1]];
private _accent = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];
private _radius = (_theme getOrDefault ["radius", 0]) min (UNIT * 0.3);

// ----- Still reading -----

if !(call FUNC(buildIndex)) exitWith {
    private _index = uiNamespace getVariable [QGVAR(index), createHashMap];
    private _label = [
        _display, _box, [0, UNIT * 0.2, _width, UNIT * 0.8],
        format [LLSTRING(Index_Reading), floor (100 * (_index getOrDefault ["read", 0]) / (_index getOrDefault ["total", 1])) min 99],
        TEXT_BODY, _colorText2, _font, 0
    ] call EFUNC(gui,uiLabel);

    uiNamespace setVariable [QGVAR(indexLabel), _label];
};

uiNamespace setVariable [QGVAR(indexLabel), controlNull];

// ----- What is found -----

private _containers = _mode isEqualTo "containers";

(GVAR(listState) getOrDefault [_mode, ["", "all", false, 0]]) params ["_text", "_chip", "_ownOnly", "_page"];
(call FUNC(ownClassRules)) params ["_exact", "_named"];

private _needle = toLower (trim _text);
private _chipKinds = [[_chip], ["crate", "vehicle"]] select (_chip isEqualTo "cargo");

// Own rules that count here: a container's cells, an item's size or stack.
private _ownKeys = [["footprint", "stack"], ["grid", "like"]] select _containers;

private _matches = ((uiNamespace getVariable QGVAR(index)) get "rows") select {
    (if (_containers) then {
        (_x select ROW_LOAD) > 0 && {(_x select ROW_KIND) in CONTAINER_KINDS} && {_chip isEqualTo "all" || {(_x select ROW_KIND) in _chipKinds}}
    } else {
        (_x select ROW_FAMILY) isNotEqualTo "cargo" && {_chip isEqualTo "all" || {(_x select ROW_FAMILY) isEqualTo _chip}}
    })
    && {!_ownOnly || {private _keys = _named getOrDefault [_x select ROW_LC, createHashMap]; (_ownKeys findIf {_x in _keys}) >= 0}}
    && {_needle isEqualTo "" || {((_x select ROW_SEARCH) find _needle) >= 0}}
};

private _total = count _matches;
private _pages = (ceil (_total / LIST_PAGE)) max 1;

_page = (_page min (_pages - 1)) max 0;
(GVAR(listState) getOrDefault [_mode, []]) set [3, _page];

private _shown = _matches select [_page * LIST_PAGE, LIST_PAGE];

// ----- Pages -----

private _footH = UNIT * 1.05;
private _footY = _height - _footH;
private _turnW = SQUARE(_footH);

[
    _display, _box, [0, _footY, _width - _turnW * 2 - SQUARE(UNIT * 0.4), _footH],
    [LLSTRING(List_None), format [LLSTRING(List_Range), _page * LIST_PAGE + 1, _page * LIST_PAGE + count _shown, _total]] select (_total > 0),
    TEXT_SMALL, _muted, _font, 0
] call EFUNC(gui,uiLabel);

{
    _x params ["_icon", "_step", "_enabled", "_buttonX"];

    [_display, _box, [_buttonX, _footY, _turnW, _footH], "", _icon, _theme, {
        params ["_mode", "_step"];

        private _state = GVAR(listState) get _mode;

        _state set [3, ((_state select 3) + _step) max 0];

        [] call FUNC(drawResults);
    }, [_mode, _step], _enabled, "ghost"] call FUNC(uiAction);
} forEach [
    [UI_TEX(icon_chevron_left_ca), -1, _page > 0, _width - _turnW * 2 - SQUARE(UNIT * 0.15)],
    [UI_TEX(icon_chevron_right_ca), 1, _page < _pages - 1, _width - _turnW]
];

// ----- The cards -----

private _list = [_display, "EINV_ScrollGroup", _box, [0, 0, _width, _footY - UNIT * 0.2]] call EFUNC(gui,uiCreate);

_list setVariable [QGVAR(scrollId), "list_" + _mode];

private _rowW = _width - SCROLL_W - SQUARE(UNIT * 0.25);
private _cardH = UNIT * 2.3;
private _gap = UNIT * 0.2;
private _picH = _cardH - UNIT * 0.4;
private _picW = SQUARE(_picH);
private _textX = SQUARE(UNIT * 0.2) + _picW + SQUARE(UNIT * 0.35);
private _textW = _rowW - _textX - SQUARE(UNIT * 0.2);
private _picked = toLowerANSI (GVAR(selection) getOrDefault [_mode, ""]);
private _fill = [1, 1, 1, 0.035];
private _fillPicked = _theme getOrDefault ["accentSoft", [0.84, 0.54, 0.1, 0.2]];

{
    _x params ["_lc", "_class", "", "_name", "_kind", "_family", "_picture", "_mod"];

    private _cardY = _forEachIndex * (_cardH + _gap);
    private _isPicked = _lc isEqualTo _picked;
    private _cardFill = [_fill, _fillPicked] select _isPicked;
    private _surface = [_display, _list, [0, _cardY, _rowW, _cardH], _cardFill, _radius] call EFUNC(gui,uiPanel);

    if (_isPicked) then {
        [_display, _list, [0, _cardY, _rowW, _cardH], _accent, _radius] call EFUNC(gui,uiRing);
    };

    if (_picture isNotEqualTo "") then {
        [_display, _list, [SQUARE(UNIT * 0.2), _cardY + UNIT * 0.2, _picW, _picH], _picture] call EFUNC(gui,uiPicture);
    };

    [
        _display, _list, [_textX, _cardY + UNIT * 0.1, _textW, UNIT * 0.75],
        [_name, _textW, _fontBold, TEXT_BODY] call EFUNC(gui,fitText), TEXT_BODY, _colorText, _fontBold, 0
    ] call EFUNC(gui,uiLabel);

    private _kindWord = localize format ["STR_einv_setup_%1_%2", ["Family", "Kind"] select _containers, [_family, _kind] select _containers];
    private _about = format ["%1 · %2 · %3", _class, _kindWord, _mod];

    [
        _display, _list, [_textX, _cardY + UNIT * 0.8, _textW, UNIT * 0.65],
        [_about, _textW, _font, TEXT_SMALL] call EFUNC(gui,fitText), TEXT_SMALL, _muted, _font, 0
    ] call EFUNC(gui,uiLabel);

    // What the draft makes of it, in the accent where an own rule decides it.
    private _info = [_class, GVAR(draftRules), GVAR(draftCache)] call EFUNC(items,getInfo);
    private _own = _exact getOrDefault [_lc, createHashMap];
    private _answer = "";
    private _isOwn = false;

    if (_containers) then {
        ([_info, "grid", _own] call FUNC(answerText)) params ["_words", "_from"];

        _answer = format [LLSTRING(Answer_Line), _words, _from];
        _isOwn = (((_info get "src") getOrDefault ["grid", ""]) select [0, 4]) isEqualTo "own:";
    } else {
        ([_info, "size", _own] call FUNC(answerText)) params ["_sizeWords", "_sizeFrom"];
        ([_info, "stack", _own] call FUNC(answerText)) params ["_stackWords", "_stackFrom"];

        private _src = _info get "src";

        _isOwn = ({((_src getOrDefault [_x, ""]) select [0, 4]) isEqualTo "own:"} count ["footprint", "stack"]) > 0;
        _answer = switch (true) do {
            // Weapons, uniforms, vests and backpacks never share a tile: only the size says anything.
            case ((_src getOrDefault ["stack", ""]) isEqualTo "forced"): {format [LLSTRING(Answer_Line), _sizeWords, _sizeFrom]};
            case (_sizeFrom isEqualTo _stackFrom): {format [LLSTRING(Answer_Line), format ["%1, %2", _sizeWords, _stackWords], _sizeFrom]};
            default {format ["%1 · %2", format [LLSTRING(Answer_Line), _sizeWords, _sizeFrom], format [LLSTRING(Answer_Line), _stackWords, _stackFrom]]};
        };
    };

    [
        _display, _list, [_textX, _cardY + UNIT * 1.45, _textW, UNIT * 0.65],
        [_answer, _textW, _font, TEXT_SMALL] call EFUNC(gui,fitText), TEXT_SMALL, [_colorText2, _accent] select _isOwn, _font, 0
    ] call EFUNC(gui,uiLabel);

    // The whole card is the button: it picks the class.
    [_display, _list, [0, _cardY, _rowW, _cardH], _surface, _cardFill, [1, 1, 1, 0.085], {
        params ["_mode", "_class"];

        GVAR(selection) set [_mode, _class];

        [GVAR(step)] call FUNC(showStep);
    }, [_mode, _class], true, _class] call FUNC(uiHit);
} forEach _shown;
