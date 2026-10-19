#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The activity chip in the caption line of a box (the bar where Take all and Sort stand): what the box is busy with, in one
 * small place and nothing else. A ring that goes round, the words and a button that stops it:
 *
 *   hands - the box has actions waiting in the hands' queue (GVAR(handBoxes)): "Grabbing items 3 / 12", "Putting items
 *     away ...", "Dropping items ..." or "Moving items ...", and the X cancels what still waits of this box
 *   search - the box has loot to search (GVAR(searchQueue)): "Searching 0:07", the time that is left, and the X stops the
 *     search of this box (fnc_stopStatus); a stopped box says "Stopped 0:07" with a still ring and the button "Search"
 *
 * The hands come first where a box has both. No tile carries a ring, a number or a glass: the tiles that wait are tinted
 * (fnc_drawQueue) and the ones not searched are hatched (fnc_createTile), the chip is the only progress.
 *
 * The caption line (fnc_drawSection) only says where there is room for it ("statusParent", "statusRect" - as high as the
 * buttons beside it -, "statusSize" and "tabColor" in the section's info, "statusCover": the room reaches over the weight,
 * which is hidden while the chip stands); this function makes, keeps and deletes the chips. It runs at the end of every
 * build and redraw of tiles (fnc_drawPending, fnc_drawQueue, fnc_revealTile) and when a button changed what a box does. A
 * chip that already says what is true is left alone - the words and the ring are moved every frame in place
 * (fnc_animateStatus).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_gui_fnc_updateStatus;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};

private _theme = GVAR(theme);
private _live = false;

{
    private _info = _x;
    private _parent = _info getOrDefault ["statusParent", controlNull];

    // A section with no chip: no room in its line, or a box that has no such line.
    if (isNull _parent) then {continue};

    private _holder = _info getOrDefault ["holder", objNull];
    private _kind = "";
    private _stopped = false;
    private _idle = false;

    if (!isNull _holder) then {
        if (GVAR(handBoxes) findIf {(_x get "holder") isEqualTo _holder} >= 0) then {
            _kind = "hands";
        } else {
            if (GVAR(searchQueue) findIf {(_x select 0) isEqualTo _holder} >= 0) then {
                _kind = "search";
                _stopped = _holder in GVAR(searchPaused);
                _idle = _stopped && {_holder in GVAR(searchIdle)};
            };
        };
    };

    private _status = _info getOrDefault ["status", createHashMap];
    private _made = _status getOrDefault ["controls", []];
    private _signature = [_kind, _stopped, _idle];

    // What it says is what is true, and the controls are all there: left as it is.
    if (_kind isNotEqualTo "" && {(_status getOrDefault ["signature", []]) isEqualTo _signature} && {_made findIf {isNull _x} < 0}) then {
        _live = true;
        continue;
    };

    {ctrlDelete _x} forEach _made;
    _info deleteAt "status";

    // The weight comes back.
    if (_info getOrDefault ["statusCover", false]) then {
        (_info getOrDefault ["load", controlNull]) ctrlShow true;
    };

    if (_kind isEqualTo "") then {continue};

    _live = true;

    (_info get "statusRect") params ["_left", "_top", "_width", "_height"];

    private _size = _info getOrDefault ["statusSize", UNIT * 0.46];
    private _font = _theme getOrDefault ["fontBold", "PuristaSemibold"];
    private _text2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
    private _controls = [];

    // The button is a cross as wide as the chip is high, or the word "Search" on a button as wide as the word needs.
    private _resume = LLSTRING(Status_Resume);
    private _buttonW = if (_kind isEqualTo "search" && {_stopped}) then {
        (((_resume getTextWidth [_font, _size]) * TEXT_SLACK) + SQUARE(_height * 0.7)) max SQUARE(_height)
    } else {
        SQUARE(_height)
    };

    // The words it will say, at their longest, to know how wide the chip has to be: a count of the queue at its
    // largest, the time at its longest. Grabbing, putting away, dropping and moving are about as long as each
    // other; the longest is taken so that none is cut.
    private _sample = "";

    if (_kind isEqualTo "hands") then {
        private _record = GVAR(handBoxes) select (GVAR(handBoxes) findIf {(_x get "holder") isEqualTo _holder});

        {
            private _try = format [_x, _record get "total", _record get "total"];

            if ((_try getTextWidth [_font, _size]) > (_sample getTextWidth [_font, _size])) then {
                _sample = _try;
            };
        } forEach [LLSTRING(Status_Grab), LLSTRING(Status_Put), LLSTRING(Status_Drop), LLSTRING(Status_Move), LLSTRING(Status_Gear)];
    } else {
        _sample = format [[LLSTRING(Status_Search), [LLSTRING(Status_Stopped), LLSTRING(Status_Idle)] select _idle] select _stopped, "99:59"];
    };

    private _gap = SQUARE(_height * 0.2);
    private _iconW = SQUARE(_height);
    private _needed = _iconW + ((_sample getTextWidth [_font, _size]) * TEXT_SLACK) + _gap * 2 + _buttonW;
    private _chipW = _width min _needed;
    private _labelW = (_chipW - _iconW - _gap * 2 - _buttonW) max 0;

    // The surface of the chip, like the tab's and as round as the buttons beside it: a pill (the theme's radius, at most half the height).
    private _radius = (_theme getOrDefault ["radius", 0]) min (_height / 2);

    _controls append ([_display, _parent, [_left, _top, _chipW, _height], _info getOrDefault ["tabColor", [0, 0, 0, 0.5]], _radius] call FUNC(uiPanel));

    // The ring: its track, and over it the arc that goes round (not while a search is stopped).
    private _ringH = _height * STATUS_ICON;
    private _ringRect = [_left + (_iconW - SQUARE(_ringH)) / 2, _top + (_height - _ringH) / 2, SQUARE(_ringH), _ringH];

    _controls pushBack ([
        _display, _parent, _ringRect, SEARCH_RING(SEARCH_FRAMES), _theme getOrDefault ["searchTrack", [1, 1, 1, 0.12]]
    ] call FUNC(uiIcon));

    private _arc = controlNull;

    if (!_stopped) then {
        _arc = [_display, _parent, _ringRect, SEARCH_RING(STATUS_ARC), _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]]] call FUNC(uiIcon);
        _controls pushBack _arc;
    };

    // A label draws its text from its top edge down: the line of capitals is in the middle of the chip when the label
    // starts TEXT_MID of the font's height above it.
    private _textTop = _top + _height / 2 - _size * TEXT_MID;

    private _label = [
        _display, _parent, [_left + _iconW + _gap, _textTop, _labelW, _size * 1.4], "", _size, _text2, _font, 0
    ] call FUNC(uiLabel);

    _controls pushBack _label;

    // The button, at the end of the chip: round, and a little in from the chip's edge on three sides, so that the chip's own round end shows
    // round it and no square corner pokes out of the chip. The cross is a circle, "Search" a pill.
    private _inset = _height * 0.12;
    private _drawnH = _height - _inset * 2;
    private _drawnW = if (_stopped) then {_buttonW - SQUARE(_inset) * 2} else {SQUARE(_drawnH)};
    private _buttonX = _left + _chipW - SQUARE(_inset) - _drawnW;
    private _buttonRect = [_buttonX, _top + _inset, _drawnW, _drawnH];
    private _buttonColor = if (_stopped) then {
        +(_theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]])
    } else {
        +(_theme getOrDefault ["loss", [0.941, 0.333, 0.353, 1]])
    };

    _buttonColor set [3, 0.5];

    private _surface = [_display, _parent, _buttonRect, _buttonColor, _drawnH / 2] call FUNC(uiPanel);

    _controls append _surface;

    if (_stopped) then {
        _controls pushBack ([
            _display, _parent, [_buttonX, _textTop, _drawnW, _size * 1.4], _resume, _size, [1, 1, 1, 1], _font, 2
        ] call FUNC(uiLabel));
    } else {
        private _crossH = _height * 0.5;

        _controls pushBack ([
            _display, _parent, [_buttonX + (_drawnW - SQUARE(_crossH)) / 2, _top + (_height - _crossH) / 2, SQUARE(_crossH), _crossH],
            UI_TEX(icon_close_ca), [1, 1, 1, 1]
        ] call FUNC(uiIcon));
    };

    // Two pixels more than it is drawn, each side.
    private _hit = [_display, "EINV_Hitbox", _parent, [
        _buttonX - pixelW * 2, _top + _inset - pixelH * 2, _drawnW + pixelW * 4, _drawnH + pixelH * 4
    ]] call FUNC(uiCreate);

    _hit setVariable [QGVAR(key), _holder];
    _hit setVariable [QGVAR(kind), _kind];
    _hit setVariable [QGVAR(surface), _surface];
    _hit ctrlSetTooltip ([
        LLSTRING(Status_StopHands),
        [LLSTRING(Status_StopSearch), [LLSTRING(Status_ResumeSearch), LLSTRING(Status_StartSearch)] select _idle] select _stopped
    ] select (_kind isEqualTo "search"));
    _hit ctrlAddEventHandler ["MouseEnter", {
        {
            _x ctrlSetFade 0.3;
            _x ctrlCommit 0.05;
        } forEach ((_this select 0) getVariable [QGVAR(surface), []]);
    }];
    _hit ctrlAddEventHandler ["MouseExit", {
        {
            _x ctrlSetFade 0;
            _x ctrlCommit 0.05;
        } forEach ((_this select 0) getVariable [QGVAR(surface), []]);
    }];
    _hit ctrlAddEventHandler ["ButtonClick", {
        [{_this call FUNC(stopStatus)}, [
            (_this select 0) getVariable [QGVAR(key), objNull], (_this select 0) getVariable [QGVAR(kind), ""]
        ]] call FUNC(later);
    }];

    _controls pushBack _hit;

    // The chip reaches over the weight where the line had no room beside it.
    if (_info getOrDefault ["statusCover", false]) then {
        (_info getOrDefault ["load", controlNull]) ctrlShow false;
    };

    _info set ["status", createHashMapFromArray [
        ["controls", _controls], ["signature", _signature], ["kind", _kind], ["arc", _arc], ["label", _label],
        ["text", ""], ["stopped", _stopped], ["idle", _idle], ["labelW", _labelW], ["font", _font], ["size", _size]
    ]];
} forEach (uiNamespace getVariable [QGVAR(sectionInfo), []]);

GVAR(statusLive) = _live;

// The words and the ring are right from the first frame.
if (_live) then {
    GVAR(statusSecond) = -1;
    [_display, diag_tickTime] call FUNC(animateStatus);
};
