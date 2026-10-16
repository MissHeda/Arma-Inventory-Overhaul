#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The content of the picture picker (fnc_openPicturePicker), in the style of the "Same as another class"
 * popover (fnc_drawSameAs):
 *   - Chips under the search: "Item icons", "Uniforms & gear", "Vehicles & boxes" and "All" - which group of the
 *     catalog is looked through (a picture's categories come from the classes that own it, fnc_pictureCategory). The
 *     picker opens on the chip of the class being edited, and on the page of the picture it has in use, ringed.
 *   - A search field over the picture catalog (fnc_pictureCatalog: every picture of every class the wizard
 *     indexes, with the classes and names that own it), by name, class and path, wildcards too
 *     (fnc_searchFilter).
 *   - A page of thumbnails, PICKER_COLS across and PICKER_ROWS down, each the picture at tile size with the first
 *     owner's name under it; the page turned by the arrows beside the range. A click picks one (a ring round it),
 *     a second click on it takes it.
 *   - A field for any texture path, for an advanced user: it is read as a config would have it (backslashes or
 *     slashes, einv_items_fnc_parsePicture) and a thumbnail beside it shows the picture while the game has the
 *     file (fileExists), with a line that says so. The last of the two - the list or this field - that was used
 *     is the one "Use picture" takes.
 * What it shows is kept in GVAR(picker). Typing in the search draws only the list, so the field keeps the cursor;
 * typing in the path field changes only its thumbnail and line. While the index and the catalog are still being
 * read it says how far, and looks again a moment later. Nothing is drawn once the popover is closed.
 *
 * Arguments:
 * 0: What to draw: "all", "list" for the thumbnails alone, "chips" for the category chips alone, "custom" for
 *    the path field's thumbnail and line <STRING> (default: "all")
 *
 * Return Value:
 * None
 *
 * Example:
 * ["all"] call einv_setup_fnc_drawPicturePicker;
 *
 * Public: No
 */

disableSerialization;

params [["_part", "all", [""]]];

(uiNamespace getVariable [QGVAR(pickerArgs), []]) params [["_display", displayNull], ["_inner", controlNull], ["_theme", createHashMap]];

if (isNull _display || {isNull _inner}) exitWith {};

(ctrlPosition _inner) params ["", "", "_width", "_height"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _muted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
private _accent = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];
private _gain = _theme getOrDefault ["gain", [0.35, 0.78, 0.5, 1]];
private _loss = _theme getOrDefault ["loss", [0.941, 0.333, 0.353, 1]];
private _radius = (_theme getOrDefault ["radius", 0]) min (UNIT * 0.3);

private _searchH = UNIT * 1.15;
private _buttonH = UNIT * 1.15;
private _chipsH = UNIT * 1;
private _chipsY = _searchH + UNIT * 0.3;
private _cellH = UNIT * 3.55;
private _thumbH = UNIT * 2.55;
private _gridY = _chipsY + _chipsH + UNIT * 0.3;
private _listH = PICKER_ROWS * _cellH + UNIT * 1;
private _customY = _gridY + _listH + UNIT * 0.3;
private _thumbSide = UNIT * 2.3;
private _cancelW = SQUARE(UNIT * 5);
private _useW = SQUARE(UNIT * 8);
private _summaryW = _width - _cancelW - _useW - SQUARE(UNIT * 0.6);

// Whether the game has the file: the path as the engine reads it, with or without its leading backslash
// (einv_items_fnc_getInfo asks the same).
private _fnc_there = {
    params ["_path"];

    private _other = if ((_path select [0, 1]) isEqualTo "\") then {_path select [1]} else {"\" + _path};

    _path isNotEqualTo "" && {fileExists _path || {fileExists _other}}
};

// ----- The path field: its thumbnail and its line -----

if (_part isEqualTo "custom") exitWith {
    private _text = GVAR(picker) getOrDefault ["custom", ""];
    private _thumb = uiNamespace getVariable [QGVAR(pickerThumb), controlNull];
    private _status = uiNamespace getVariable [QGVAR(pickerStatus), controlNull];

    ([_text, false] call EFUNC(items,parsePicture)) params ["_path", "_notes"];

    private _there = _path isNotEqualTo "" && {_notes isEqualTo []} && {[_path] call _fnc_there};

    GVAR(picker) set ["customOk", _there];

    // A file that is not there is never given to the control: the engine would pop up a message.
    if (!isNull _thumb) then {
        _thumb ctrlSetText (["", _path] select _there);
    };

    if (!isNull _status) then {
        _status ctrlSetText (["", [LLSTRING(Pic_Missing), LLSTRING(Pic_Found)] select _there] select (_text isNotEqualTo ""));
        _status ctrlSetTextColor ([_loss, _gain] select _there);
    };
};

// ----- The chips -----

if (_part isEqualTo "chips") exitWith {
    ctrlDelete (uiNamespace getVariable [QGVAR(pickerChips), controlNull]);

    private _box = uiNamespace getVariable [QGVAR(pickerBox), controlNull];

    if (isNull _box) exitWith {};

    private _row = [_display, "EINV_Group", _box, [0, _chipsY, _width, _chipsH]] call EFUNC(gui,uiCreate);
    private _now = GVAR(picker) getOrDefault ["chip", "all"];
    private _chipX = 0;

    uiNamespace setVariable [QGVAR(pickerChips), _row];

    {
        _x params ["_id", "_text"];

        private _chipW = SQUARE(_chipsH * 0.9) + (_text getTextWidth [_fontBold, _chipsH * 0.52]) * TEXT_SLACK;

        [_display, _row, [_chipX, 0, _chipW, _chipsH], _text, _id isEqualTo _now, _theme, {
            params ["", "_id"];

            GVAR(picker) set ["chip", _id];
            GVAR(picker) set ["page", 0];
            GVAR(picker) set ["reveal", false];

            ["chips"] call FUNC(drawPicturePicker);
            ["list"] call FUNC(drawPicturePicker);
        }, _id] call FUNC(uiChip);

        _chipX = _chipX + _chipW + SQUARE(UNIT * 0.3);
    } forEach [
        ["items", LLSTRING(Pic_CatItems)], ["gear", LLSTRING(Pic_CatGear)], ["vehicles", LLSTRING(Pic_CatVehicles)], ["all", LLSTRING(Pic_CatAll)]
    ];
};

// ----- Everything: the search, the path field, the buttons -----

if (_part isEqualTo "all") then {
    ctrlDelete (uiNamespace getVariable [QGVAR(pickerBox), controlNull]);

    private _box = [_display, "EINV_Group", _inner, [0, 0, _width, _height]] call EFUNC(gui,uiCreate);

    uiNamespace setVariable [QGVAR(pickerBox), _box];
    uiNamespace setVariable [QGVAR(pickerList), controlNull];

    private _search = [
        _display, _box, [0, 0, _width, _searchH], GVAR(picker) getOrDefault ["text", ""], LLSTRING(Pic_Search), _theme, {
            params ["_text"];

            if (_text isEqualTo (GVAR(picker) getOrDefault ["text", ""])) exitWith {};

            GVAR(picker) set ["text", _text];
            GVAR(picker) set ["page", 0];
            GVAR(picker) set ["reveal", false];

            ["list"] call FUNC(drawPicturePicker);
        }
    ] call FUNC(uiEdit);

    ctrlSetFocus (_search select (count _search - 1));

    ["chips"] call FUNC(drawPicturePicker);

    // Any texture path: the field, and beside it a thumbnail and a line that says whether the game has the file.
    private _fieldW = _width - _thumbSide - SQUARE(UNIT * 0.4);

    [_display, _box, [0, _customY, _fieldW, UNIT * 0.65], LLSTRING(Pic_Custom), TEXT_SMALL, _colorText2, _fontBold, 0] call EFUNC(gui,uiLabel);

    [
        _display, _box, [0, _customY + UNIT * 0.7, _fieldW, UNIT * 1.15], GVAR(picker) getOrDefault ["custom", ""], LLSTRING(Pic_CustomHint), _theme, {
            params ["_text", "_submitted"];

            if (_text isEqualTo (GVAR(picker) getOrDefault ["custom", ""]) && {!_submitted}) exitWith {};

            private _source = GVAR(picker) getOrDefault ["source", "list"];

            GVAR(picker) set ["custom", _text];
            GVAR(picker) set ["source", ["list", "custom"] select (_text isNotEqualTo "")];
            ["custom"] call FUNC(drawPicturePicker);

            // A thumbnail was ringed and no longer counts: the ring goes.
            if (_source isNotEqualTo (GVAR(picker) get "source")) then {
                ["list"] call FUNC(drawPicturePicker);
            };

            if (_submitted && {GVAR(picker) getOrDefault ["customOk", false]}) then {
                [([_text, false] call EFUNC(items,parsePicture)) select 0] call FUNC(pickPicture);
            };
        }
    ] call FUNC(uiEdit);

    [
        _display, _box, [_fieldW + SQUARE(UNIT * 0.4), _customY + UNIT * 0.1, _thumbSide, _thumbSide], [1, 1, 1, 0.06], _radius
    ] call EFUNC(gui,uiPanel);

    uiNamespace setVariable [QGVAR(pickerThumb), [
        _display, _box, [_fieldW + SQUARE(UNIT * 0.4) + SQUARE(UNIT * 0.1), _customY + UNIT * 0.2, _thumbSide - SQUARE(UNIT * 0.2), _thumbSide - UNIT * 0.2], ""
    ] call EFUNC(gui,uiPicture)];

    uiNamespace setVariable [QGVAR(pickerStatus), [
        _display, _box, [0, _customY + UNIT * 1.95, _fieldW, UNIT * 0.65], "", TEXT_SMALL, _muted, _font, 0
    ] call EFUNC(gui,uiLabel)];

    ["custom"] call FUNC(drawPicturePicker);

    // The one picked, Cancel and Use picture.
    uiNamespace setVariable [QGVAR(pickerSummary), [
        _display, _box, [0, _height - _buttonH, _summaryW, _buttonH], "", TEXT_SMALL, _colorText2, _font, 0
    ] call EFUNC(gui,uiLabel)];

    [_display, _box, [_width - _cancelW - _useW - SQUARE(UNIT * 0.3), _height - _buttonH, _cancelW, _buttonH], LLSTRING(Cancel), "", _theme, {
        call FUNC(closePopover);
    }, [], true, "ghost"] call FUNC(uiAction);

    [_display, _box, [_width - _useW, _height - _buttonH, _useW, _buttonH], LLSTRING(Pic_Use), UI_TEX(icon_check_ca), _theme, {
        private _path = "";

        if ((GVAR(picker) getOrDefault ["source", "list"]) isEqualTo "custom") then {
            if (GVAR(picker) getOrDefault ["customOk", false]) then {
                _path = ([GVAR(picker) get "custom", false] call EFUNC(items,parsePicture)) select 0;
            } else {
                [LLSTRING(Pic_BadPath), "loss"] call FUNC(setHint);
            };
        } else {
            _path = GVAR(picker) getOrDefault ["picked", ""];

            if (_path isEqualTo "") then {
                [LLSTRING(Pic_Nothing), "loss"] call FUNC(setHint);
            };
        };

        if (_path isNotEqualTo "") then {
            [_path] call FUNC(pickPicture);
        };
    }, [], true, "accent"] call FUNC(uiAction);
};

// ----- The thumbnails -----

private _box = uiNamespace getVariable [QGVAR(pickerBox), controlNull];

if (isNull _box) exitWith {};

ctrlDelete (uiNamespace getVariable [QGVAR(pickerList), controlNull]);

private _list = [_display, "EINV_Group", _box, [0, _gridY, _width, _listH]] call EFUNC(gui,uiCreate);

uiNamespace setVariable [QGVAR(pickerList), _list];

// Still reading: say how far, and look again a moment later.
if !(call FUNC(pictureCatalog)) exitWith {
    private _index = uiNamespace getVariable [QGVAR(index), createHashMap];
    private _catalog = uiNamespace getVariable [QGVAR(pictures), createHashMap];
    private _text = if (_index getOrDefault ["done", false]) then {
        format [LLSTRING(Pic_Reading), floor (100 * (_catalog getOrDefault ["position", 0]) / ((count (_index getOrDefault ["rows", []])) max 1)) min 99, "%"]
    } else {
        format [LLSTRING(Index_Reading), floor (100 * (_index getOrDefault ["read", 0]) / (_index getOrDefault ["total", 1])) min 99]
    };

    [_display, _list, [0, 0, _width, UNIT * 0.8], _text, TEXT_SMALL, _colorText2, _font, 0] call EFUNC(gui,uiLabel);

    [{
        params ["_list"];

        if (!isNull _list) then {
            ["list"] call FUNC(drawPicturePicker);
        };
    }, [_list], 0.5] call FUNC(defer);
};

// ----- What is found, a page of thumbnails -----

private _typed = GVAR(picker) getOrDefault ["text", ""];
private _chip = GVAR(picker) getOrDefault ["chip", "all"];
private _found = GVAR(picker) getOrDefault ["found", []];

// What the catalog has of a chip's group that the text finds.
private _fnc_find = {
    params ["_typed", "_chip"];

    private _all = (uiNamespace getVariable QGVAR(pictures)) get "list";

    if (_chip isNotEqualTo "all") then {
        _all = _all select {_chip in (_x select 8)};
    };

    private _filter = [_typed] call FUNC(searchFilter);

    if (_filter isEqualTo []) exitWith {_all};

    _filter params [["_needle", "", [""]], ["_expression", "", [""]], ["_literal", "", [""]]];

    if (_expression isEqualTo "") exitWith {
        _all select {((_x select 2) find _needle) >= 0}
    };

    // The longest plain run has to be there, whatever else the wildcard asks; then it must fit the path,
    // a class or a name as a whole.
    _all select {
        (_literal isEqualTo "" || {((_x select 2) find _literal) >= 0})
        && {
            (_x select 1) regexMatch _expression
            || {(_x select 6) findIf {_x regexMatch _expression} >= 0}
            || {(_x select 7) findIf {(toLower _x) regexMatch _expression} >= 0}
        }
    }
};

// Found once per text and chip: turning a page does not look through the catalog again.
if (!("foundFor" in GVAR(picker)) || {(GVAR(picker) get "foundFor") isNotEqualTo [_typed, _chip]}) then {
    _found = [_typed, _chip] call _fnc_find;

    GVAR(picker) set ["found", _found];
    GVAR(picker) set ["foundFor", [_typed, _chip]];
};

// Opened on the picture in use: the entry of that very file (the whole path, however it is written -
// fnc_pictureKey - and never another picture of a class that owns it too), ringed, and the page it is on.
// Not in the chip's group - a uniform's picture on the items chip, say - the chip turns to All. A path the
// catalog does not have is the path field's.
if (GVAR(picker) getOrDefault ["reveal", false]) then {
    GVAR(picker) set ["reveal", false];

    private _byPath = (uiNamespace getVariable QGVAR(pictures)) getOrDefault ["byPath", createHashMap];
    private _entry = _byPath getOrDefault [[GVAR(picker) getOrDefault ["picked", ""]] call FUNC(pictureKey), []];

    if (_entry isEqualTo []) then {
        GVAR(picker) set ["picked", ""];

        if ((GVAR(picker) getOrDefault ["custom", ""]) isNotEqualTo "") then {
            GVAR(picker) set ["source", "custom"];
        };
    } else {
        GVAR(picker) set ["picked", _entry select 0];

        private _at = _found findIf {(_x select 1) isEqualTo (_entry select 1)};

        if (_at < 0 && {_chip isNotEqualTo "all"}) then {
            _chip = "all";
            _found = [_typed, _chip] call _fnc_find;
            _at = _found findIf {(_x select 1) isEqualTo (_entry select 1)};

            GVAR(picker) set ["chip", _chip];
            GVAR(picker) set ["found", _found];
            GVAR(picker) set ["foundFor", [_typed, _chip]];

            ["chips"] call FUNC(drawPicturePicker);
        };

        if (_at >= 0) then {
            GVAR(picker) set ["page", floor (_at / (PICKER_COLS * PICKER_ROWS))];
        };
    };
};

private _perPage = PICKER_COLS * PICKER_ROWS;
private _total = count _found;
private _pages = (ceil (_total / _perPage)) max 1;
private _page = ((GVAR(picker) getOrDefault ["page", 0]) min (_pages - 1)) max 0;
private _shown = _found select [_page * _perPage, _perPage];
private _picked = ["", [GVAR(picker) getOrDefault ["picked", ""]] call FUNC(pictureKey)] select ((GVAR(picker) getOrDefault ["source", "list"]) isEqualTo "list");
private _cellW = _width / PICKER_COLS;
private _gap = SQUARE(UNIT * 0.2);

GVAR(picker) set ["page", _page];

{
    _x params ["_path", "", "", "_name", "", "_owners", "_classes", "", "", "_key"];

    private _col = _forEachIndex mod PICKER_COLS;
    private _row = floor (_forEachIndex / PICKER_COLS);
    private _left = _col * _cellW + _gap / 2;
    private _top = _row * _cellH;
    private _cardW = _cellW - _gap;
    private _surface = [_display, _list, [_left, _top, _cardW, _thumbH], [1, 1, 1, 0.06], _radius] call EFUNC(gui,uiPanel);

    [
        _display, _list, [_left + SQUARE(UNIT * 0.15), _top + UNIT * 0.15, _cardW - SQUARE(UNIT * 0.3), _thumbH - UNIT * 0.3], _path
    ] call EFUNC(gui,uiPicture);

    if (_picked isNotEqualTo "" && {_key isEqualTo _picked}) then {
        [_display, _list, [_left, _top, _cardW, _thumbH], _accent, _radius] call EFUNC(gui,uiRing);
    };

    private _label = ["%1", "%1 +%2"] select (_owners > 1);

    [
        _display, _list, [_left, _top + _thumbH, _cardW, UNIT * 0.65],
        [format [_label, _name, _owners - 1], _cardW, _font, TEXT_SMALL * 0.9] call EFUNC(gui,fitText), TEXT_SMALL * 0.9, _colorText2, _font, 2
    ] call EFUNC(gui,uiLabel);

    private _tip = format ["%1%2%3%2%4", _name, toString [10], _classes joinString ", ", _path];

    [_display, _list, [_left, _top, _cardW, _thumbH + UNIT * 0.65], _surface, [1, 1, 1, 0.06], [1, 1, 1, 0.14], {
        params ["_path"];

        private _now = diag_tickTime;
        private _last = GVAR(picker) getOrDefault ["last", ["", 0]];

        // The second click on the same one, quickly: take it.
        if ((_last select 0) isEqualTo _path && {_now - (_last select 1) < 0.6}) exitWith {
            [_path] call FUNC(pickPicture);
        };

        GVAR(picker) set ["last", [_path, _now]];
        GVAR(picker) set ["picked", _path];
        GVAR(picker) set ["source", "list"];

        ["list"] call FUNC(drawPicturePicker);
    }, [_path], true, _tip] call FUNC(uiHit);
} forEach _shown;

if (_shown isEqualTo []) then {
    [_display, _list, [SQUARE(UNIT * 0.2), 0, _width, UNIT * 0.8], LLSTRING(List_None), TEXT_SMALL, _muted, _font, 0] call EFUNC(gui,uiLabel);
};

// The one picked, beside the buttons.
private _summary = uiNamespace getVariable [QGVAR(pickerSummary), controlNull];

if (!isNull _summary) then {
    private _current = GVAR(picker) getOrDefault ["picked", ""];
    private _text = "";

    if (_current isNotEqualTo "" && {(GVAR(picker) getOrDefault ["source", "list"]) isEqualTo "list"}) then {
        private _entry = ((uiNamespace getVariable QGVAR(pictures)) get "byPath") getOrDefault [[_current] call FUNC(pictureKey), []];

        _text = [format ["%1 · %2", _entry param [3, ""], _current], _summaryW, _font, TEXT_SMALL] call EFUNC(gui,fitText);
    };

    _summary ctrlSetText _text;
};

// ----- The page, with the range, under the thumbnails -----

private _turnW = SQUARE(UNIT * 1.1);
private _pagerY = PICKER_ROWS * _cellH + UNIT * 0.1;

[
    _display, _list, [0, _pagerY, _width - _turnW * 2 - SQUARE(UNIT * 0.6), UNIT * 0.9],
    [LLSTRING(List_None), format [LLSTRING(List_Range), _page * _perPage + 1, _page * _perPage + count _shown, _total]] select (_total > 0),
    TEXT_SMALL, _muted, _font, 0
] call EFUNC(gui,uiLabel);

{
    _x params ["_icon", "_step", "_enabled", "_buttonX"];

    [_display, _list, [_buttonX, _pagerY - UNIT * 0.05, _turnW, UNIT * 1], "", _icon, _theme, {
        params ["_step"];

        GVAR(picker) set ["page", ((GVAR(picker) getOrDefault ["page", 0]) + _step) max 0];

        ["list"] call FUNC(drawPicturePicker);
    }, [_step], _enabled, "ghost"] call FUNC(uiAction);
} forEach [
    [UI_TEX(icon_chevron_left_ca), -1, _page > 0, _width - _turnW * 2 - SQUARE(UNIT * 0.3)],
    [UI_TEX(icon_chevron_right_ca), 1, _page < _pages - 1, _width - _turnW]
];
