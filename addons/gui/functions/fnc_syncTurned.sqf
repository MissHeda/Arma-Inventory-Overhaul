#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Keeps the turned pictures of turned tiles (fnc_turnPicture) on their tiles - every frame from fnc_onFrame, and
 * once for a new one. A turned picture lies on the display, its tile in groups that scroll and move, so it is put
 * where its tile is now: the groups it lies in are walked from the top (as fnc_gridOrigin counts, a pending scroll
 * included), which gives both where the tile's space starts on the screen and the part of the screen those groups
 * show.
 *
 * It shows only where its fallback (the upright picture the tile was drawn with) would: shown with every group
 * it lies in, wholly inside what they show (half a pixel of give), and with nothing over it that is drawn over the
 * tile - a kit window above the tile's own (later in GVAR(windows), the order the engine draws them in) or the
 * inspect card. The name at the mouse and the comparison card are no cover: they are made again over the turned
 * pictures (fnc_raiseTooltip), so a hovered tile keeps its turned picture (before 0.5.53 it flipped upright under
 * the mouse). Then it takes the fallback's fade, and the
 * fallback goes see-through (its colour's alpha 0) - otherwise it is hidden and the fallback shows as it was. A
 * record whose turned picture or fallback is gone is dropped, its turned picture deleted.
 *
 * Arguments:
 * 0: The records to look at, see fnc_turnPicture; every one when left out <ARRAY> (default: all)
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call aio_gui_fnc_syncTurned;
 *
 * Public: No
 */

disableSerialization;

params [["_records", nil, [[]]]];

private _all = isNil "_records";

if (_all) then {
    _records = uiNamespace getVariable [QGVAR(turnedPictures), []];
};

if (_records isEqualTo []) exitWith {};

// What lies over the tiles, as [x0, y0, x1, y1].
private _covers = [];

private _inspect = uiNamespace getVariable [QGVAR(inspectGroup), controlNull];

if (!isNull _inspect && {ctrlShown _inspect}) then {
    (uiNamespace getVariable [QGVAR(inspectRect), []]) params [["_inspectX", 0], ["_inspectY", 0], ["_inspectW", 0], ["_inspectH", 0]];
    _covers pushBack [_inspectX, _inspectY, _inspectX + _inspectW, _inspectY + _inspectH];
};

private _windows = (uiNamespace getVariable [QGVAR(windows), []]) apply {_x getOrDefault ["group", controlNull]};

// Per group a tile lies in, worked out once per call: [group, content origin x, y, shown, visible x0, y0, x1, y1, top group].
private _spaces = [];

private _fnc_space = {
    params ["_group"];

    private _index = _spaces findIf {(_x select 0) isEqualTo _group};

    if (_index >= 0) exitWith {_spaces select _index};

    private _chain = [];
    private _walk = _group;

    while {!isNull _walk} do {
        _chain pushBack _walk;
        _walk = ctrlParentControlsGroup _walk;
    };

    private _originX = 0;
    private _originY = 0;
    private _shown = true;
    private _x0 = safezoneX;
    private _y0 = safezoneY;
    private _x1 = safezoneX + safezoneW;
    private _y1 = safezoneY + safezoneH;

    for "_i" from (count _chain - 1) to 0 step -1 do {
        private _level = _chain select _i;

        (ctrlPosition _level) params ["_levelX", "_levelY", "_levelW", "_levelH"];

        private _screenX = _originX + _levelX;
        private _screenY = _originY + _levelY;
        private _contentH = _level getVariable [QGVAR(contentH), _levelH];
        private _scrolled = ([_level] call FUNC(scrollPixels)) min ((_contentH - _levelH) max 0);

        _shown = _shown && {ctrlShown _level};
        _x0 = _x0 max _screenX;
        _y0 = _y0 max _screenY;
        _x1 = _x1 min (_screenX + _levelW);
        _y1 = _y1 min (_screenY + _levelH);
        _originX = _screenX;
        _originY = _screenY - _scrolled;
    };

    private _space = [_group, _originX, _originY, _shown, _x0, _y0, _x1, _y1, _chain param [count _chain - 1, controlNull]];

    _spaces pushBack _space;
    _space
};

private _keep = [];
private _giveX = pixelW / 2;

// Twice a second the turned textures shown are looked after (fnc_turnedTexture): one the engine dropped is made again.
private _check = diag_tickTime >= (uiNamespace getVariable [QGVAR(turnCheckAt), 0]);
private _checked = createHashMap;

if (_check) then {
    uiNamespace setVariable [QGVAR(turnCheckAt), diag_tickTime + 0.5];
};
private _giveY = pixelH / 2;

{
    _x params ["_overlay", "_fallback", "_inner", "_color", "_parent", "_middle", "_state"];

    if (isNull _overlay) then {continue};

    if (isNull _fallback || {isNull _inner}) then {
        ctrlDelete _overlay;
        continue;
    };

    _keep pushBack _x;

    ([_parent] call _fnc_space) params ["", "_originX", "_originY", "_shown", "_x0", "_y0", "_x1", "_y1", "_top"];
    (_overlay getVariable [QGVAR(shown), [0, 0]]) params ["_shownW", "_shownH"];

    private _centerX = _originX + (_middle select 0);
    private _centerY = _originY + (_middle select 1);
    private _left = _centerX - _shownW / 2;
    private _upper = _centerY - _shownH / 2;
    private _right = _centerX + _shownW / 2;
    private _lower = _centerY + _shownH / 2;

    private _want = _shown && {ctrlShown _fallback}
        && {_left >= _x0 - _giveX} && {_right <= _x1 + _giveX} && {_upper >= _y0 - _giveY} && {_lower <= _y1 + _giveY};

    if (_want) then {
        // Under a kit window drawn after the tile's own (a column's tile lies under every window).
        private _own = _windows find _top;

        {
            if (_forEachIndex > _own && {!isNull _x} && {ctrlShown _x}) then {
                (ctrlPosition _x) params ["_windowX", "_windowY", "_windowW", "_windowH"];

                if (_left < _windowX + _windowW && {_right > _windowX} && {_upper < _windowY + _windowH} && {_lower > _windowY}) exitWith {
                    _want = false;
                };
            };
        } forEach _windows;
    };

    if (_want) then {
        {
            _x params ["_coverX0", "_coverY0", "_coverX1", "_coverY1"];

            if (_left < _coverX1 && {_right > _coverX0} && {_upper < _coverY1} && {_lower > _coverY0}) exitWith {
                _want = false;
            };
        } forEach _covers;
    };

    if (_want) then {
        (ctrlPosition _overlay) params ["_nowX", "_nowY", "_ctrlW", "_ctrlH"];

        private _newX = _centerX - _ctrlW / 2;
        private _newY = _centerY - _ctrlH / 2;
        private _fade = ctrlFade _fallback;
        private _moved = abs (_newX - _nowX) > pixelW / 4 || {abs (_newY - _nowY) > pixelH / 4};

        if (_moved || {_fade != ctrlFade _overlay}) then {
            _overlay ctrlSetPosition [_newX, _newY];
            _overlay ctrlSetFade _fade;
            _overlay ctrlCommit 0;

            // The picture is turned in its texture (fnc_turnedTexture), the control is not: nothing to turn again.
        };

        if (!ctrlShown _overlay) then {
            _overlay ctrlShow true;
        };

        private _source = _overlay getVariable [QGVAR(turnedSource), ""];
        private _attachments = _overlay getVariable [QGVAR(turnedAttachments), []];
        private _checkKey = _source + "|" + str _attachments;

        if (_check && {_source isNotEqualTo ""} && {!(_checkKey in _checked)}) then {
            _checked set [_checkKey, true];
            [ctrlParent _overlay, _source, false, _attachments] call FUNC(turnedTexture);
        };

        if (_state isNotEqualTo true) then {
            _inner ctrlSetTextColor ((_color select [0, 3]) + [0]);
            _x set [6, true];
        };
    } else {
        if (ctrlShown _overlay) then {
            _overlay ctrlShow false;
        };

        if (_state isEqualTo true) then {
            _inner ctrlSetTextColor _color;
            _x set [6, false];
        };
    };
} forEach _records;

if (_all && {count _keep != count _records}) then {
    uiNamespace setVariable [QGVAR(turnedPictures), _keep];
};
