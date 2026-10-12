#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Binds the cards to the list shown from its first visible row: moves them to their rows and sets picture,
 * name, size, count, favorite star, the logo of the item's mod and colour - no control is made. With counts
 * only, only what the soldier carries and the favorites are bound again, as after every build of the window.
 *
 * The logo is what ACE's setting for mod icons asks for (ace_arsenal_enableModIcons: none, the mod's own
 * logo, or the logo of the DLC the item belongs to), found as ACE's list finds it and kept per class.
 *
 * Also makes the source grid's tiles (fnc_drawCatalog) from the cards that show something: a tile brings
 * the entry that is dragged ("dragEntry": the item at its true size, a whole stack at most), the cell it is
 * held by ("grab") and the controls that fade with it.
 *
 * Reads the session only through the list the column holds, GVAR(carried) and ACE's favorites.
 *
 * Arguments:
 * 0: Counts only <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_arsenal_fnc_bindCatalog;
 *
 * Public: No
 */

disableSerialization;

params [["_countsOnly", false, [false]]];

private _column = uiNamespace getVariable [QGVAR(column), createHashMap];
private _cards = _column getOrDefault ["cards", []];

if (_cards isEqualTo []) exitWith {};

private _theme = EGVAR(gui,theme);
private _list = _column getOrDefault ["list", []];
private _total = count _list;
private _cols = _column get "cols";
private _firstRow = _column getOrDefault ["firstRow", 0];
(_column get "pitch") params ["_pitchX", "_pitchY"];
(_column get "cardSize") params ["_cardW", "_cardH"];
private _pillW = _column get "pillW";
private _grid = _column get "grid";
private _cardIdx = _column get "cardIdx";
private _names = _column get "names";

private _tileBg = _theme getOrDefault ["tileBg", []];
private _carried = GVAR(carried);
private _favorites = missionNamespace getVariable [QACEGVAR(arsenal,favorites), createHashMap];
private _font = _theme getOrDefault ["font", "RobotoCondensed"];
private _nameW = _cardW * 0.62 - SQUARE(_cardH * 0.07);
private _nameSize = UNIT * 0.44;
private _pillSize = UNIT * 0.42;
private _padX = round (SQUARE(round (_cardH * 0.07 / pixelH) * pixelH) / pixelW) * pixelW;
private _tiles = [];

// The logo of an item's mod or DLC, by ACE's setting, kept for the session.
private _modIcons = missionNamespace getVariable [QACEGVAR(arsenal,enableModIcons), 0];
private _logos = uiNamespace getVariable QGVAR(modLogos);

if (isNil "_logos") then {
    _logos = createHashMap;
    uiNamespace setVariable [QGVAR(modLogos), _logos];
};

private _fnc_logo = {
    params ["_class"];

    if (_modIcons == 0 || {isNil QACEFUNC(common,getAddon)}) exitWith {""};

    private _key = format ["%1|%2", _modIcons, toLowerANSI _class];
    private _kept = _logos get _key;

    if (!isNil "_kept") exitWith {_kept};

    private _texture = "";

    if (_modIcons == 1) then {
        private _config = _class call CBA_fnc_getItemConfig;
        private _mod = if (isNull _config) then {""} else {[_config] call ACEFUNC(common,getAddon)};

        if (_mod isNotEqualTo "") then {
            _texture = (modParams [_mod, ["logo"]]) param [0, ""];
        };
    } else {
        private _dlc = ([_class] call ACEFUNC(common,getDLC)) param [0, ""];

        if (_dlc isNotEqualTo "") then {
            _texture = getText (configFile >> "CfgMods" >> _dlc >> "logo");
        };
    };

    _logos set [_key, _texture];

    _texture
};

{
    private _parts = _x;
    private _i = _forEachIndex;
    private _contentRow = _firstRow + floor (_i / _cols);
    private _originX = (_i mod _cols) * _pitchX;
    private _originY = _contentRow * _pitchY;
    private _idx = [_contentRow * _cols + (_i mod _cols), _cardIdx select _i] select _countsOnly;

    if (_idx < 0 || {_idx >= _total}) then {
        // Nothing for this card: it is put away.
        if ((_cardIdx select _i) != -1 || {!_countsOnly}) then {
            {
                (_x select 0) ctrlShow false;
            } forEach _parts;

            if (!_countsOnly) then {
                _cardIdx set [_i, -1];
            };
        };
    } else {
        private _row = _list select _idx;
        private _class = _row select ROW_CLASS;
        private _kind = _row select ROW_KIND;
        private _identity = _kind in ["face", "voice", "insignia"];

        if (!_countsOnly) then {
            // To its row, and its look.
            {
                _x params ["_control", "_dx", "_dy", "_w", "_h"];

                _control ctrlSetPosition [_originX + _dx, _originY + _dy, _w, _h];
                _control ctrlCommit 0;
            } forEach _parts;

            _parts params ["_surface", "_picture", "_nameCtrl", "_sizeCtrl"];

            private _color = _tileBg param [_row select ROW_TILE_CATEGORY, [1, 1, 1, 0.075]];

            (_surface select 0) ctrlSetBackgroundColor _color;
            (_surface select 0) ctrlShow true;
            (_picture select 0) ctrlSetText (_row select ROW_PICTURE);
            (_picture select 0) ctrlShow true;

            private _lc = toLowerANSI _class;
            private _shown = _names get _lc;

            if (isNil "_shown") then {
                _shown = [_row select ROW_SHORT, _nameW, _font, _nameSize] call EFUNC(gui,fitText);
                _names set [_lc, _shown];
            };

            (_nameCtrl select 0) ctrlSetText _shown;
            (_nameCtrl select 0) ctrlShow true;
            (_sizeCtrl select 0) ctrlSetText ([format ["%1×%2", _row select ROW_W, _row select ROW_H], ""] select _identity);
            (_sizeCtrl select 0) ctrlShow true;

            // The mod's logo, when the setting asks for it.
            private _logoCtrl = (_parts select 7) select 0;
            private _texture = if (_identity) then {""} else {[_class] call _fnc_logo};

            _logoCtrl ctrlSetText _texture;
            _logoCtrl ctrlShow (_texture isNotEqualTo "");

            // The tile: what is dragged is the item at its true size, a whole stack at most.
            private _controls = _parts apply {_x select 0};
            private _width = _row select ROW_W;
            private _height = _row select ROW_H;
            private _capacity = _row select ROW_CAPACITY;

            private _entry = if (_identity) then {
                // Nothing of identity is dragged: a drag that finds no entry never starts.
                createHashMap
            } else {
                createHashMapFromArray [
                    ["class", _class], ["w", _width], ["h", _height], ["col", 0], ["row", 0], ["count", _row select ROW_STACK],
                    ["ammo", _capacity], ["capacity", _capacity], ["attachments", []], ["container", objNull],
                    ["controls", _controls]
                ]
            };

            _tiles pushBack createHashMapFromArray [
                ["class", _class], ["col", _i mod _cols], ["row", floor (_i / _cols)], ["w", 1], ["h", 1], ["count", 1],
                ["ammo", _capacity], ["capacity", _capacity], ["attachments", []], ["container", objNull],
                ["size", [_width, _height]], ["grab", [floor (_width / 2), floor (_height / 2)]], ["dragStart", 1],
                ["dragEntry", _entry], ["background", _surface select 0], ["color", _color], ["controls", _controls],
                ["card", true], ["kind", _kind]
            ];

            _cardIdx set [_i, _idx];
        };

        // The count the soldier carries, and the star of a favorite.
        _parts params ["", "", "", "", "_pillBg", "_pillText", "_star"];

        private _have = [_carried getOrDefault [_row select ROW_KEY, 0], 0] select _identity;

        if (_have > 0) then {
            private _label = format ["×%1", _have];
            private _wide = (((_label getTextWidth [_theme getOrDefault ["fontBold", "RobotoCondensedBold"], _pillSize]) * TEXT_SLACK) + _padX * 2) max _pillW;

            {
                _x params ["_control", "_dx", "_dy", "_w", "_h"];

                _control ctrlSetPosition [_originX + _cardW - _padX - _wide, _originY + _dy, _wide, _h];
                _control ctrlCommit 0;
            } forEach [_pillBg, _pillText];

            (_pillText select 0) ctrlSetText _label;
            (_pillBg select 0) ctrlShow true;
            (_pillText select 0) ctrlShow true;
        } else {
            (_pillBg select 0) ctrlShow false;
            (_pillText select 0) ctrlShow false;
        };

        (_star select 0) ctrlShow (!_identity && {(toLowerANSI _class) in _favorites});
    };
} forEach _cards;

if (!_countsOnly) then {
    _grid set ["tiles", _tiles];
    _grid set ["rel", [0, _firstRow * _pitchY]];

    private _count = _column getOrDefault ["countCtrl", controlNull];

    if (!isNull _count) then {
        _count ctrlSetText format [LLSTRING(Catalog_Count), _total];
    };
};
