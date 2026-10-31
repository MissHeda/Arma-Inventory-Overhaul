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
 * The search takes wildcards (fnc_searchFilter). With the tree view on (GVAR(treeState)) the box holds the
 * tree of a class instead of the cards (fnc_drawTree).
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
 * [] call aio_setup_fnc_drawResults;
 *
 * Public: No
 */

disableSerialization;

(uiNamespace getVariable [QGVAR(resultsArgs), []]) params [["_display", displayNull, [displayNull]], ["_parent", controlNull, [controlNull]], ["_rect", [], [[]]], ["_theme", createHashMap, [createHashMap]], ["_mode", "items", [""]]];

if (isNull _display || {isNull _parent}) exitWith {};

ctrlDelete (uiNamespace getVariable [QGVAR(results), controlNull]);

private _box = [_display, "AIO_Group", _parent, _rect] call EFUNC(gui,uiCreate);

uiNamespace setVariable [QGVAR(results), _box];

_rect params ["", "", "_width", "_height"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText = _theme getOrDefault ["text", [1, 1, 1, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _muted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
private _accent = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];
private _radius = (_theme getOrDefault ["radius", 0]) min (UNIT * 0.3);

// ----- The tree of a class instead of the list -----

if ((GVAR(treeState) getOrDefault [_mode, createHashMap]) getOrDefault ["on", false]) exitWith {
    uiNamespace setVariable [QGVAR(indexLabel), controlNull];

    [_display, _box, _width, _height, _theme, _mode] call FUNC(drawTree);
};

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

(GVAR(listState) getOrDefault [_mode, ["", "all", false, 0]]) params ["_text", "_chip", "_ownOnly", "_page", ["_modPick", ""]];
private _named = ([] call FUNC(ownClassRules)) select 1;

private _filter = [_text] call FUNC(searchFilter);
private _needle = _filter param [0, ""];
private _expression = _filter param [1, ""];
private _chipKinds = [[_chip], ["crate", "vehicle"]] select (_chip isEqualTo "cargo");

// Own rules that count here: a container's cells, an item's size or stack.
private _ownKeys = [["footprint", "stack"], ["grid", "like"]] select _containers;

private _matches = ((uiNamespace getVariable QGVAR(index)) get "rows") select {
    (if (_containers) then {
        // A backpack is listed with no load of its own on purpose (aio_setup_fnc_indexChunk): its cells are
        // all there is to set, so it is not hidden with the load-0 rest.
        ((_x select ROW_LOAD) > 0 || {(_x select ROW_KIND) isEqualTo "backpack"}) && {(_x select ROW_KIND) in CONTAINER_KINDS} && {_chip isEqualTo "all" || {(_x select ROW_KIND) in _chipKinds}}
    } else {
        (_x select ROW_FAMILY) isNotEqualTo "cargo" && {_chip isEqualTo "all" || {(_x select ROW_FAMILY) isEqualTo _chip}}
    })
    && {!_ownOnly || {private _keys = _named getOrDefault [_x select ROW_LC, createHashMap]; (_ownKeys findIf {_x in _keys}) >= 0}}
    && {_needle isEqualTo "" || {
        if (_expression isEqualTo "") then {
            ((_x select ROW_SEARCH) find _needle) >= 0
        } else {
            [_filter, _x select ROW_SEARCH, _x select ROW_LC, _x select ROW_NAME] call FUNC(searchHit)
        }
    }}
};

// The mods of what is found, for the filter; then only the one picked (issue #32).
private _modNames = [];

{
    _modNames pushBackUnique (_x select ROW_MOD);
} forEach _matches;

_modNames sort true;

if (_modPick isNotEqualTo "" && {!(_modPick in _modNames)}) then {
    _modPick = "";
    (GVAR(listState) getOrDefault [_mode, []]) set [4, ""];
};

if (_modPick isNotEqualTo "") then {
    _matches = _matches select {(_x select ROW_MOD) isEqualTo _modPick};
};

private _total = count _matches;
private _pages = (ceil (_total / LIST_PAGE)) max 1;

_page = (_page min (_pages - 1)) max 0;
(GVAR(listState) getOrDefault [_mode, []]) set [3, _page];

private _shown = _matches select [_page * LIST_PAGE, LIST_PAGE];

// ----- Pages -----

private _footH = UNIT * 1.05;
private _footY = _height - _footH;

[_display, _box, [0, _footY, _width, _footH], _theme, _page, _pages, _total, count _shown, LIST_PAGE, {
    params ["_mode", "_step"];

    private _state = GVAR(listState) get _mode;

    _state set [3, ((_state select 3) + _step) max 0];

    [] call FUNC(drawResults);
}, _mode] call FUNC(drawPager);

// ----- The cards -----

// ----- The mod filter -----

private _barH = UNIT * 1;
private _modOptions = [[LLSTRING(List_AllMods), ""]] + (_modNames apply {[_x, _x]});

[_display, _box, [0, 0, _width, _barH], _modOptions, _modPick, _theme, {
    params ["_new", "_mode"];

    private _state = GVAR(listState) get _mode;

    _state set [4, _new];
    _state set [3, 0];

    [] call FUNC(drawResults);
}, _mode, count _modNames > 1] call FUNC(uiDropdown);

private _listTop = _barH + UNIT * 0.25;
private _list = [_display, "AIO_ScrollGroup", _box, [0, _listTop, _width, _footY - UNIT * 0.2 - _listTop]] call EFUNC(gui,uiCreate);

_list setVariable [QGVAR(scrollId), "list_" + _mode];

// ----- Overrides: one rule for every class whose name starts the same (class=X*) -----
// A search that is the start of a name and a * (B_Assault*) offers an entry of its own above the classes: "Custom override".
// Picked - after a question the first time -, the editor beside the list shows the first class found and what it applies
// is written as the one rule class=B_Assault* (fnc_upsertRule), which takes every class of that name, those a mod adds
// later too. Overrides the draft has already show as such entries as well: all of them with nothing typed, else those the
// text is part of. GVAR(groupEdit) holds the one picked per step: [selector, classes].

private _group = GVAR(groupEdit) getOrDefault [_mode, []];
private _letters = toArray "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";
private _typed = "";

if (count (trim _text) > 3) then {
    private _whole = trim _text;
    private _stem = _whole select [0, count _whole - 1];

    if ((_whole select [count _whole - 1]) isEqualTo "*" && {count _stem >= 3} && {(toArray _stem) findIf {!(_x in _letters)} < 0}) then {
        _typed = _stem;
    };
};

// The overrides the draft has, by their stem as written.
private _stems = [];

{
    _x params ["_conds"];

    if (count _conds == 1) then {
        (_conds select 0) params ["_negated", "_key", "_op", "_names"];

        if (!_negated && {_key isEqualTo "class"} && {_op isEqualTo "="} && {count _names == 1} && {((_names select 0) select [count (_names select 0) - 1]) isEqualTo "*"}) then {
            private _stem = (_names select 0) select [0, count (_names select 0) - 1];

            if ((_stems findIf {_x == _stem}) < 0 && {_needle isEqualTo "" || {(toLowerANSI _stem find (_needle regexReplace ["\*", ""])) >= 0}}) then {
                _stems pushBack _stem;
            };
        };
    };
} forEach (([GVAR(draftText)] call EFUNC(items,parseRules)) getOrDefault ["rules", []]);

private _drafted = +_stems;

if (_typed isNotEqualTo "" && {(_stems findIf {_x == _typed}) < 0}) then {
    _stems pushBack _typed;
};

// Each with the classes of this step whose name starts so.
private _rows = (uiNamespace getVariable QGVAR(index)) get "rows";
private _overrides = _stems apply {
    private _start = toLowerANSI _x;
    private _length = count _start;
    private _classes = (_rows select {
        ((_x select ROW_LC) select [0, _length]) isEqualTo _start && {
            if (_containers) then {(_x select ROW_KIND) in CONTAINER_KINDS} else {(_x select ROW_FAMILY) isNotEqualTo "cargo"}
        }
    }) apply {_x select 1};

    [_x, _classes]
};

_overrides = _overrides select {(_x select 1) isNotEqualTo []};
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
private _overrideH = count _overrides * (_cardH + _gap);

{
    _x params ["_stem", "_classes"];

    private _selector = _stem + "*";
    private _cardY = _forEachIndex * (_cardH + _gap);
    private _active = (_group param [0, ""]) == _selector;
    private _exists = _stem in _drafted;
    private _cardFill = [_fill, _fillPicked] select _active;
    private _surface = [_display, _list, [0, _cardY, _rowW, _cardH], _cardFill, _radius] call EFUNC(gui,uiPanel);

    if (_active) then {
        [_display, _list, [0, _cardY, _rowW, _cardH], _accent, _radius] call EFUNC(gui,uiRing);
    };

    [_display, _list, [SQUARE(UNIT * 0.2) + _picW * 0.2, _cardY + UNIT * 0.2 + _picH * 0.2, _picW * 0.6, _picH * 0.6], UI_TEX(icon_style_ca), _accent] call EFUNC(gui,uiIcon);

    [
        _display, _list, [_textX, _cardY + UNIT * 0.1, _textW, UNIT * 0.75],
        [format [LLSTRING(Override_Title), _selector], _textW, _fontBold, TEXT_BODY] call EFUNC(gui,fitText), TEXT_BODY, _colorText, _fontBold, 0
    ] call EFUNC(gui,uiLabel);

    [
        _display, _list, [_textX, _cardY + UNIT * 0.8, _textW, UNIT * 0.65],
        [format [LLSTRING(Override_About), _stem, count _classes], _textW, _font, TEXT_SMALL] call EFUNC(gui,fitText), TEXT_SMALL, _muted, _font, 0
    ] call EFUNC(gui,uiLabel);

    [
        _display, _list, [_textX, _cardY + UNIT * 1.45, _textW, UNIT * 0.65],
        [[LLSTRING(Override_New), LLSTRING(Override_Own)] select _exists, _textW, _font, TEXT_SMALL] call EFUNC(gui,fitText), TEXT_SMALL,
        [_colorText2, _accent] select _exists, _font, 0
    ] call EFUNC(gui,uiLabel);

    [_display, _list, [0, _cardY, _rowW, _cardH], _surface, _cardFill, [1, 1, 1, 0.085], {
        params ["_mode", "_selector", "_classes", "_exists"];

        private _pick = {
            params ["_mode", "_selector", "_classes"];

            GVAR(groupEdit) set [_mode, [_selector, _classes]];
            GVAR(selection) set [_mode, _classes select 0];
            GVAR(editScope) set [_mode, "class"];

            [format [LLSTRING(Hint_GroupOnRule), _selector select [0, count _selector - 1]], "accent"] call FUNC(setHint);
            [GVAR(step)] call FUNC(showStep);
        };

        if (_exists) exitWith {
            [_mode, _selector, _classes] call _pick;
        };

        [
            uiNamespace getVariable [QGVAR(display), displayNull],
            format [LLSTRING(Override_Question), _selector select [0, count _selector - 1], count _classes],
            LLSTRING(Override_Create), _pick, [_mode, _selector, _classes]
        ] call FUNC(confirm);
    }, [_mode, _selector, _classes, _exists], true, LLSTRING(Override_Tip)] call FUNC(uiHit);
} forEach _overrides;

{
    _x params ["_lc", "_class", "", "_name", "_kind", "_family", "_picture", "_mod"];

    private _cardY = _overrideH + _forEachIndex * (_cardH + _gap);
    private _isPicked = _lc isEqualTo _picked && {_group isEqualTo []};
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

    private _kindWord = localize format [["STR_aio_setup_Family_%1", "STR_aio_setup_Kind_%1"] select _containers, [_family, _kind] select _containers];
    private _about = format ["%1 · %2 · %3", _class, _kindWord, _mod];

    [
        _display, _list, [_textX, _cardY + UNIT * 0.8, _textW, UNIT * 0.65],
        [_about, _textW, _font, TEXT_SMALL] call EFUNC(gui,fitText), TEXT_SMALL, _muted, _font, 0
    ] call EFUNC(gui,uiLabel);

    // What the draft makes of it, in the accent where an own rule decides it.
    ([_class, _mode] call FUNC(answerLine)) params ["_answer", "_isOwn"];

    [
        _display, _list, [_textX, _cardY + UNIT * 1.45, _textW, UNIT * 0.65],
        [_answer, _textW, _font, TEXT_SMALL] call EFUNC(gui,fitText), TEXT_SMALL, [_colorText2, _accent] select _isOwn, _font, 0
    ] call EFUNC(gui,uiLabel);

    // The whole card is the button: it picks the class.
    [_display, _list, [0, _cardY, _rowW, _cardH], _surface, _cardFill, [1, 1, 1, 0.085], {
        params ["_mode", "_class"];

        // Picked here, an edit is for this class alone; the tree view picks a class with everything built on it.
        GVAR(selection) set [_mode, _class];
        GVAR(editScope) set [_mode, "class"];
        GVAR(groupEdit) deleteAt _mode;

        [GVAR(step)] call FUNC(showStep);
    }, [_mode, _class], true, _class] call FUNC(uiHit);
} forEach _shown;
