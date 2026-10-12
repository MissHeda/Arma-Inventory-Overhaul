#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws the Loadouts view into the catalog's column: the tabs, the field for a name and the save button,
 * the list - one row for each loadout, its pictures in one text - the card of the selected one with its
 * buttons, and import and export.
 *
 * Whatever a loadout does is done by its own function (fnc_loadoutSave, fnc_loadoutLoad, ...) on the loadout
 * picked (GVAR(loadoutSelected), by the id of fnc_loadoutsData); a click only changes that and has the view
 * drawn again on the next frame (GVAR(loadoutsDirty), fnc_loadoutsFrame), so there is one way the screen is
 * made. What the column keeps about it is in the HashMap uiNamespace GVAR(column): "nameEdit" (the field),
 * "listGroup", "listRange" (how far it can scroll, in screen units) and "listScroll" (how far it has),
 * "rowCtrls" (for the key of each row its status label and its hit area, so the answer of a check can be
 * written in place), "fnc_status" and "selectedKey".
 *
 * The list scrolls as a group of the engine's: it is as high as its rows, a speck at the foot gives it that
 * height. A row has five controls: the surface, the name, the status, one text with up to seven pictures
 * (primary, launcher, handgun, uniform, vest, backpack, headgear - ACE's order) and the sign that it is
 * shared or who shares it, and the hit area.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The column's group <CONTROL>
 * 2: Where, [x, y, w, h] <ARRAY>
 * 3: Theme <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _group, _rect, _theme] call einv_arsenal_fnc_drawLoadouts;
 *
 * Public: No
 */

disableSerialization;

params [
    ["_display", displayNull, [displayNull]], ["_group", controlNull, [controlNull]], ["_rect", [0, 0, 0, 0], [[]]],
    ["_theme", createHashMap, [createHashMap]]
];

if (isNull _display || {isNull _group} || {count _rect < 4}) exitWith {};

_rect params ["", "", "_width", "_height"];

private _column = uiNamespace getVariable [QGVAR(column), createHashMap];

// What was asked for is being drawn.
GVAR(loadoutsDirty) = false;

private _text = _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]];
private _muted = _theme getOrDefault ["muted", [0.412, 0.443, 0.494, 1]];
private _accent = _theme getOrDefault ["accent", [0.961, 0.647, 0.141, 1]];
private _loss = _theme getOrDefault ["loss", [0.941, 0.333, 0.353, 1]];
private _button = _theme getOrDefault ["button", [1, 1, 1, 0.08]];
private _buttonHover = _theme getOrDefault ["buttonHover", [1, 1, 1, 0.12]];
private _font = _theme getOrDefault ["font", "RobotoCondensed"];
private _fontBold = _theme getOrDefault ["fontBold", "RobotoCondensedBold"];

// The accent, faint, for the loadout that is picked.
private _picked = [_accent select 0, _accent select 1, _accent select 2, 0.26];
private _pickedHover = [_accent select 0, _accent select 1, _accent select 2, 0.36];

// A colour as structured text takes it.
private _fnc_hex = {
    params ["_color"];

    "#" + ((_color select [0, 3]) apply {
        private _value = round ((_x max 0 min 1) * 255);
        ("0123456789ABCDEF" select [floor (_value / 16), 1]) + ("0123456789ABCDEF" select [_value mod 16, 1])
    } joinString "")
};

// ----- What there is to show -----

private _allowDefault = missionNamespace getVariable [QACEGVAR(arsenal,allowDefaultLoadouts), true];
private _allowShared = (missionNamespace getVariable [QACEGVAR(arsenal,allowSharedLoadouts), true]) && {isMultiplayer};
private _canEdit = call ACEFUNC(arsenal,canEditDefaultLoadout);

// Default only while the mission has defaults, Public only in multiplayer where sharing is allowed.
private _tabs = [["mine", LLSTRING(Loadouts_Mine)]];

if (_allowDefault) then {
    _tabs pushBack ["default", LLSTRING(Loadouts_Default)];
};

if (_allowShared) then {
    _tabs pushBack ["public", LLSTRING(Loadouts_Public)];
};

if ((_tabs findIf {(_x select 0) isEqualTo GVAR(loadoutsTab)}) < 0) then {
    GVAR(loadoutsTab) = "mine";
    GVAR(loadoutSelected) = "";
};

private _tab = GVAR(loadoutsTab);
private _rows = [_tab] call FUNC(loadoutsData);
private _selected = ([_tab, false, GVAR(loadoutSelected)] call FUNC(loadoutsData)) param [0, []];
private _has = _selected isNotEqualTo [];

// How a check is put in words: [text, the theme's colour for it, the tooltip of the row]. What is missing from
// the game is written in red and what is not here in grey, and a tooltip tells which ones while ACE's setting
// says so (1: by name, 2: by class).
private _fnc_status = {
    params ["_check"];

    if (_check isEqualTo []) exitWith {[LLSTRING(Loadouts_Checking), "muted", ""]};

    _check params ["", ["_missing", []], ["_notHere", []]];

    private _show = missionNamespace getVariable [QACEGVAR(arsenal,showUnavailableItems), 0];

    if (_missing isNotEqualTo []) exitWith {
        [
            format [LLSTRING(Loadouts_Missing), count _missing], "loss",
            [format [LLSTRING(Loadouts_MissingList), _missing joinString endl], ""] select (_show <= 0)
        ]
    };

    if (_notHere isNotEqualTo []) exitWith {
        private _names = _notHere apply {[[_x] call EFUNC(gui,itemName), _x] select (_show == 2)};

        [
            format [LLSTRING(Loadouts_NotHere), count _notHere], "muted",
            [format [LLSTRING(Loadouts_NotHereList), _names joinString endl], ""] select (_show <= 0)
        ]
    };

    ["", "muted", ""]
};

_column set ["fnc_status", _fnc_status];
_column set ["selectedKey", ["", _tab + "|" + (_selected param [6, ""])] select _has];
_column set ["rowCtrls", createHashMap];
_column set ["listGroup", controlNull];
_column set ["listRange", 0];

// A group made here takes the clicks over it to the window, as the columns do (fnc_build).
private _fnc_hook = {
    params ["_control"];

    if !(_control getVariable [QEGVAR(gui,hooked), false]) then {
        _control setVariable [QEGVAR(gui,hooked), true];
        _control ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call EFUNC(gui,onMouseButton)}];
        _control ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call EFUNC(gui,onMouseButton)}];
        _control ctrlAddEventHandler ["MouseZChanged", {[_this] call EFUNC(gui,onMouseZ)}];
    };
};

// ----- Measures -----

private _padX = SQUARE(UNIT * 0.4);
private _gapX = SQUARE(UNIT * 0.3);
private _gap = UNIT * 0.3;
private _tabsH = UNIT * 1.2;
private _nameH = UNIT * 1.1;
private _rowH = UNIT * 1.9;
private _rowGap = UNIT * 0.2;
private _detailH = UNIT * 5.2;
private _bottomH = UNIT * 1.1;

private _nameY = _tabsH + _gap;
private _listY = _nameY + _nameH + _gap;
private _bottomY = _height - _bottomH;
private _detailY = _bottomY - _gap - _detailH;
private _listH = (_detailY - _gap - _listY) max (UNIT * 2);

// ----- Mine, Default, Public -----

[
    _display, _group, [0, 0, _width, _tabsH], _tabs apply {_x select 1}, _tabs findIf {(_x select 0) isEqualTo _tab}, _theme,
    {
        params ["_index", "_ids"];

        private _id = _ids param [_index, "mine"];

        if (_id isEqualTo GVAR(loadoutsTab)) exitWith {};

        GVAR(loadoutsTab) = _id;
        GVAR(loadoutSelected) = "";
        GVAR(loadoutName) = "";

        (uiNamespace getVariable [QGVAR(column), createHashMap]) set ["listScroll", 0];

        GVAR(loadoutsDirty) = true;
    },
    _tabs apply {_x select 0}
] call EFUNC(setup,uiSegmented);

// ----- The name, and Save -----

private _saveW = SQUARE(UNIT * 4);

private _edit = ([
    _display, _group, [0, _nameY, _width - _saveW - _gapX, _nameH], GVAR(loadoutName), LLSTRING(Loadouts_Name), _theme,
    {
        params ["_typed"];

        GVAR(loadoutName) = _typed;
    }
] call EFUNC(setup,uiEdit)) select -1;

_column set ["nameEdit", _edit];

[
    _display, _group, [_width - _saveW, _nameY, _saveW, _nameH], LLSTRING(Loadouts_Save), "", _theme,
    {
        GVAR(loadoutName) = ctrlText ((uiNamespace getVariable [QGVAR(column), createHashMap]) getOrDefault ["nameEdit", controlNull]);

        [GVAR(loadoutName)] call FUNC(loadoutSave);
    },
    [], true, "accent"
] call EFUNC(setup,uiAction);

// ----- The list -----

private _list = _display ctrlCreate ["EINV_ScrollGroup", -1, _group];

_list ctrlSetPosition [0, _listY, _width, _listH];
_list ctrlCommit 0;
[_list] call _fnc_hook;

private _rowW = floor ((_width - SCROLL_W - pixelW * 2) / pixelW) * pixelW;
private _pitch = _rowH + _rowGap;
private _lineH = UNIT * 0.8;
private _rowCtrls = createHashMap;

// The pictures of the loadout's things, small, one after the other: what ACE's list shows.
private _fnc_pictures = {
    params ["_data"];

    private _loadout = if (count _data == 2) then {_data select 0} else {_data};

    if (!(_loadout isEqualType []) || {count _loadout < 7}) exitWith {""};

    private _weapons = configFile >> "CfgWeapons";
    private _vehicles = configFile >> "CfgVehicles";
    private _pictures = [];

    {
        _x params ["_at", "_where"];

        private _entry = _loadout select _at;
        private _class = if (_entry isEqualType []) then {_entry param [0, ""]} else {_entry};

        if (_class isEqualType "" && {_class isNotEqualTo ""}) then {
            private _picture = getText (_where >> _class >> "picture");

            if (_picture isNotEqualTo "" && {!("'" in _picture)} && {!("<" in _picture)}) then {
                _pictures pushBack format ["<img image='%1' size='1.05'/>", _picture];
            };
        };
    } forEach [[0, _weapons], [1, _weapons], [2, _weapons], [3, _weapons], [4, _weapons], [5, _vehicles], [6, _weapons]];

    _pictures joinString " "
};

{
    _x params ["_name", "_data", "_author", "_shared", "_rowTab", "_check", "_id"];

    private _y = _forEachIndex * _pitch;
    private _isPicked = _id isEqualTo GVAR(loadoutSelected);
    private _fill = [_button, _picked] select _isPicked;
    private _hover = [_buttonHover, _pickedHover] select _isPicked;
    private _statusW = _rowW * 0.4;

    ([_check] call _fnc_status) params ["_statusText", "_statusColor", "_tip"];

    private _surface = [_display, _list, [0, _y, _rowW, _rowH], _fill, 0] call EFUNC(gui,uiPanel);

    [
        _display, _list, [_padX, _y + UNIT * 0.15, _rowW - _statusW - _padX, _lineH],
        [_name, _rowW - _statusW - _padX, _fontBold, UNIT * 0.62] call EFUNC(gui,fitText), UNIT * 0.62, _text, _fontBold, 0
    ] call EFUNC(gui,uiLabel);

    private _status = [
        _display, _list, [_rowW - _statusW - _padX, _y + UNIT * 0.15, _statusW, _lineH], _statusText, UNIT * 0.5,
        _theme getOrDefault [_statusColor, _muted], _font, 1
    ] call EFUNC(gui,uiLabel);

    // Under the name: the pictures, and who has it.
    private _parts = [parseText ([_data] call _fnc_pictures)];

    if (_shared) then {
        _parts pushBack parseText format [" <img image='%1' size='1' color='%2'/>", ICON(icon_share_ca,icon_swap_ca), [_accent] call _fnc_hex];
    };

    if (_author isNotEqualTo "") then {
        _parts pushBack (text format [" %1", format [LLSTRING(Loadouts_By), _author]] setAttributes ["color", [_muted] call _fnc_hex, "size", "0.8"]);
    };

    private _look = [_display, "EINV_StructuredText", _list, [_padX, _y + UNIT * 0.95, _rowW - _padX * 2, UNIT * 0.85]] call EFUNC(gui,uiCreate);
    _look ctrlSetStructuredText composeText _parts;

    private _hit = [
        _display, _list, [0, _y, _rowW, _rowH], _surface, _fill, _hover,
        {
            params ["_id", "_name"];

            private _column = uiNamespace getVariable [QGVAR(column), createHashMap];
            private _before = _column getOrDefault ["lastClick", ["", -1]];
            private _twice = (_before select 0) isEqualTo _id && {diag_tickTime - (_before select 1) <= DOUBLE_CLICK};

            _column set ["lastClick", [_id, diag_tickTime]];

            GVAR(loadoutSelected) = _id;
            GVAR(loadoutName) = _name;
            GVAR(loadoutsDirty) = true;

            // Twice: put on.
            if (_twice) then {
                call FUNC(loadoutLoad);
            };
        },
        [_id, _name], true, _tip
    ] call EFUNC(setup,uiHit);

    _rowCtrls set [_rowTab + "|" + _id, [_status, _hit]];
} forEach _rows;

_column set ["rowCtrls", _rowCtrls];

private _contentH = (count _rows) * _pitch;

if (_rows isEqualTo []) then {
    [
        _display, _list, [0, UNIT * 0.6, _rowW, UNIT * 1.2], LLSTRING(Loadouts_Empty), UNIT * 0.6, _muted, _font, 2
    ] call EFUNC(gui,uiLabel);
} else {
    // The list is as high as its rows; a speck at the very foot makes the engine scroll exactly that far.
    if (_contentH > _listH) then {
        private _speck = [_display, "EINV_PanelRect", _list, [0, _contentH - pixelH, pixelW, pixelH]] call EFUNC(gui,uiCreate);

        _speck ctrlSetBackgroundColor [0, 0, 0, 0];
    };
};

_list setVariable [QEGVAR(gui,contentH), _contentH max _listH];

private _range = (_contentH - _listH) max 0;

_column set ["listGroup", _list];
_column set ["listRange", _range];

// Where it was scrolled to, put back a frame later: a group goes to the top right after its content changed.
// The frame notes the place only after that (fnc_loadoutsFrame).
private _scrolled = _column getOrDefault ["listScroll", 0];

_column set ["scrollHold", diag_frameNo + 3];

if (_scrolled > 0 && {_range > 0}) then {
    [{
        params ["_list", "_fraction"];

        if (!isNull _list) then {
            _list ctrlSetScrollValues [_fraction, -1];
        };
    }, [_list, (_scrolled / _range) min 1]] call EFUNC(gui,later);
};

// ----- The loadout that is picked -----

private _detail = _display ctrlCreate ["EINV_Group", -1, _group];

_detail ctrlSetPosition [0, _detailY, _width, _detailH];
_detail ctrlCommit 0;
[_detail] call _fnc_hook;

[_display, _detail, [0, 0, _width, _detailH], _button, 0] call EFUNC(gui,uiPanel);

private _innerW = _width - _padX * 2;

if (_has) then {
    _selected params ["_name", "", "_author", "", "", "_check"];

    private _title = if (_author isNotEqualTo "") then {format ["%1 - %2", _name, format [LLSTRING(Loadouts_By), _author]]} else {_name};

    [
        _display, _detail, [_padX, UNIT * 0.2, _innerW, UNIT * 0.9], [_title, _innerW, _fontBold, UNIT * 0.62] call EFUNC(gui,fitText),
        UNIT * 0.62, _text, _fontBold, 0
    ] call EFUNC(gui,uiLabel);

    // What is missing from the game, and what is not in this arsenal.
    private _lines = [];

    if (_check isEqualTo []) then {
        _lines pushBack [LLSTRING(Loadouts_Checking), _muted];
    } else {
        _check params ["", ["_missing", []], ["_notHere", []]];

        private _byClass = (missionNamespace getVariable [QACEGVAR(arsenal,showUnavailableItems), 0]) == 2;

        if (_missing isNotEqualTo []) then {
            _lines pushBack [format [LLSTRING(Loadouts_MissingList), _missing joinString ", "], _loss];
        };

        if (_notHere isNotEqualTo []) then {
            private _names = _notHere apply {[[_x] call EFUNC(gui,itemName), _x] select _byClass};

            _lines pushBack [format [LLSTRING(Loadouts_NotHereList), _names joinString ", "], _muted];
        };
    };

    if (_lines isNotEqualTo []) then {
        private _composed = [];

        {
            if (_composed isNotEqualTo []) then {
                _composed pushBack lineBreak;
            };

            _composed pushBack (text (_x select 0) setAttributes ["color", [_x select 1] call _fnc_hex, "size", "0.78"]);
        } forEach _lines;

        private _info = [_display, "EINV_StructuredText", _detail, [_padX, UNIT * 3.7, _innerW, _detailH - UNIT * 3.85]] call EFUNC(gui,uiCreate);
        _info ctrlSetStructuredText composeText _composed;
    };
};

// What can be done to it, three to a line.
private _buttons = [[LLSTRING(Loadouts_Load), {call FUNC(loadoutLoad)}, "accent", "", _has]];

switch (_tab) do {
    case "mine": {
        _buttons pushBack [LLSTRING(Loadouts_Rename), {
            GVAR(loadoutName) = ctrlText ((uiNamespace getVariable [QGVAR(column), createHashMap]) getOrDefault ["nameEdit", controlNull]);

            [GVAR(loadoutName)] call FUNC(loadoutRename);
        }, "", "", _has];
        _buttons pushBack [LLSTRING(Loadouts_Delete), {call FUNC(loadoutDelete)}, "danger", "", _has];

        if (_allowShared) then {
            _buttons pushBack [
                [LLSTRING(Loadouts_Share), LLSTRING(Loadouts_Unshare)] select (_has && {_selected select 3}),
                {call FUNC(loadoutShare)}, "", "", _has
            ];
        };

        if (_canEdit && _allowDefault) then {
            _buttons pushBack [LLSTRING(Loadouts_MakeDefault), {call FUNC(loadoutMakeDefault)}, "", "", _has];
        };
    };
    case "default": {
        if (_canEdit) then {
            _buttons pushBack [LLSTRING(Loadouts_Rename), {
                GVAR(loadoutName) = ctrlText ((uiNamespace getVariable [QGVAR(column), createHashMap]) getOrDefault ["nameEdit", controlNull]);

                [GVAR(loadoutName)] call FUNC(loadoutRename);
            }, "", "", _has];
            _buttons pushBack [LLSTRING(Loadouts_Delete), {call FUNC(loadoutDelete)}, "danger", "", _has];
        };

        _buttons pushBack [LLSTRING(Loadouts_CopyToMine), {
            GVAR(loadoutName) = ctrlText ((uiNamespace getVariable [QGVAR(column), createHashMap]) getOrDefault ["nameEdit", controlNull]);

            call FUNC(loadoutCopy);
        }, "", "", _has];
    };
    case "public": {
        _buttons pushBack [LLSTRING(Loadouts_CopyToMine), {
            GVAR(loadoutName) = ctrlText ((uiNamespace getVariable [QGVAR(column), createHashMap]) getOrDefault ["nameEdit", controlNull]);

            call FUNC(loadoutCopy);
        }, "", "", _has];

        // Only the one who shares it stops it - and the server's admin.
        private _mayStop = _has && {(_selected select 2) isEqualTo profileName || {serverCommandAvailable "#logout"}};

        _buttons pushBack [LLSTRING(Loadouts_Unshare), {call FUNC(loadoutDelete)}, "danger", "", _mayStop];
    };
    default {};
};

private _buttonH = UNIT * 1.1;
private _buttonW = (_innerW - _gapX * 2) / 3;

{
    _x params ["_label", "_code", "_style", "_tooltip", "_enabled"];

    [
        _display, _detail, [
            _padX + (_forEachIndex mod 3) * (_buttonW + _gapX), UNIT * 1.2 + (floor (_forEachIndex / 3)) * (_buttonH + UNIT * 0.2),
            _buttonW, _buttonH
        ],
        _label, "", _theme, _code, [], _enabled, _style, _tooltip
    ] call EFUNC(setup,uiAction);
} forEach _buttons;

// ----- Import and export -----

private _bottom = [
    [LLSTRING(Loadouts_Import), {[false] call FUNC(loadoutImport)}, LLSTRING(Loadouts_Import_Tooltip), ICON(icon_import_ca,icon_undo_ca)],
    [LLSTRING(Loadouts_Export), {[false] call FUNC(loadoutExport)}, LLSTRING(Loadouts_Export_Tooltip), ICON(icon_export_ca,icon_redo_ca)]
];

// The mission's defaults go in and out as a list, for those who may change them.
if (_tab isEqualTo "default" && {_canEdit}) then {
    _bottom pushBack [LLSTRING(Loadouts_ImportList), {[true] call FUNC(loadoutImport)}, LLSTRING(Loadouts_ImportList_Tooltip), ""];
    _bottom pushBack [LLSTRING(Loadouts_ExportList), {[true] call FUNC(loadoutExport)}, LLSTRING(Loadouts_ExportList_Tooltip), ""];
};

private _bottomW = (_width - _gapX * ((count _bottom) - 1)) / (count _bottom);

{
    _x params ["_label", "_code", "_tooltip", "_icon"];

    [
        _display, _group, [_forEachIndex * (_bottomW + _gapX), _bottomY, _bottomW, _bottomH], _label,
        [_icon, ""] select (count _bottom > 2), _theme, _code, [], true, "", _tooltip
    ] call EFUNC(setup,uiAction);
} forEach _bottom;
