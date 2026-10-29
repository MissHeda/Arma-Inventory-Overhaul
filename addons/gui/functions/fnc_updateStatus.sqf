#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The activity chip in the caption line of a box (the bar where Sort stands): what the box is busy with, in one
 * small place and nothing else. A ring that goes round, the words and a button that stops it:
 *
 *   hands - the box has actions waiting in the hands' queue (GVAR(handBoxes)): "Grabbing items 3 / 12", "Putting items
 *     away ...", "Dropping items ..." or "Moving items ...", and the X cancels what still waits of this box
 *   search - the box has loot to search (GVAR(searchQueue)): "Searching 0:07", the time that is left, and the X stops the
 *     search of this box (fnc_stopStatus); a stopped box says "Stopped 0:07" with a still ring and the button "Search",
 *     one that waits for its first click "Unsearched 0:07". Every box that is not stopped searches at the same time.
 *
 * The hands come first where a box has both. No tile carries a ring, a number or a glass: the tiles that wait are tinted
 * (fnc_drawQueue) and the ones not searched are hatched (fnc_createTile), the chip is the only progress.
 *
 * The chip is as wide as what it says, no wider (issue 16): the ring, one gap, the words (fnc_statusWords) in a label just
 * as wide as they measure - centred in it, so the room the engine's text may need more than getTextWidth says lies evenly
 * on both sides -, one gap and the button, as wide as the word "Search" or a round cross. Its width follows the shape of
 * the words (every digit counted as a 0): when that changes - another state, a time that loses a digit - fnc_animateStatus
 * has the chip made anew here; the seconds that tick within one shape are written in place.
 *
 * The caption line (fnc_drawSection) only says where there is room for it ("statusParent", "statusRect" - as high as the
 * buttons beside it -, "statusSize" and "tabColor" in the section's info, "statusCover": the room reaches over the weight,
 * which is hidden while the chip stands); this function makes, keeps and deletes the chips. It runs at the end of every
 * build and redraw of tiles (fnc_drawPending, fnc_drawQueue, fnc_revealTile) and when a button changed what a box does. A
 * chip that already says what is true is left alone - the words and the ring are moved every frame in place
 * (fnc_animateStatus).
 *
 * A sealed box (fnc_isSealed) also has its block's line written here - "Click to search", "Searching ...", "Stopped",
 * "Waiting to be searched" - and its ring shown while it searches; its chip says what the search does without the time,
 * which would tell how much the container holds. While a sealed block stands, the chips are animated every frame: a drag
 * held over the block is refused there (fnc_animateStatus).
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
private _now = diag_tickTime;

{
    private _info = _x;
    private _parent = _info getOrDefault ["statusParent", controlNull];
    private _seal = _info getOrDefault ["seal", createHashMap];

    // A section with no chip: no room in its line, or a box that has no such line - unless it is sealed, whose block
    // says what its search does whether there is a chip or not.
    if (isNull _parent && {count _seal == 0}) then {continue};

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

    // The sealed block (fnc_drawSection): its line says what the search does, its ring goes round while it runs - every box
    // with something queued that is not stopped searches (fnc_animateSearch).
    if (count _seal > 0) then {
        _live = true;

        private _state = switch (true) do {
            case (_kind isNotEqualTo "search"): {"wait"};
            case (_idle): {"idle"};
            case (_stopped): {"stopped"};
            default {"running"};
        };

        if (_state isNotEqualTo (_seal get "state")) then {
            _seal set ["state", _state];

            private _words = switch (_state) do {
                case "idle": {LLSTRING(Seal_Click)};
                case "stopped": {[LLSTRING(Seal_Stopped), LLSTRING(Seal_StoppedClick)] select GVAR(searchOnClick)};
                case "running": {LLSTRING(Seal_Searching)};
                default {LLSTRING(Seal_Waiting)};
            };

            _words = [_words, _seal get "width", _theme getOrDefault ["font", "PuristaMedium"], _seal get "size"] call FUNC(fitText);
            _seal set ["words", _words];

            // Not while a drag held over it says why it takes nothing (fnc_animateStatus): its own words come back after.
            if !(_seal isEqualRef GVAR(sealDragOver)) then {
                (_seal get "line") ctrlSetText _words;
            };

            (_seal get "arc") ctrlShow (_state isEqualTo "running");
        };
    };

    if (isNull _parent) then {continue};

    private _status = _info getOrDefault ["status", createHashMap];
    private _made = _status getOrDefault ["controls", []];

    (_info get "statusRect") params ["_left", "_top", "_width", "_height"];

    private _size = _info getOrDefault ["statusSize", UNIT * 0.46];
    private _font = _theme getOrDefault ["fontBold", "PuristaSemibold"];
    private _sealedBox = _info getOrDefault ["sealed", false];

    // The parts that do not depend on the words: the ring as far in from the chip's round end as from its top and bottom,
    // one gap before the words and one after them, the button a little in from the chip's edge on three sides - so that
    // the chip's own round end shows round it - and as wide as "Search" or a round cross.
    private _ringH = _height * STATUS_ICON;
    private _padLeft = SQUARE((_height - _ringH) / 2);
    private _gap = SQUARE(_height * 0.25);
    private _inset = _height * 0.12;
    private _drawnH = _height - _inset * 2;
    private _resume = LLSTRING(Status_Resume);
    private _drawnW = if (_kind isEqualTo "search" && {_stopped}) then {
        ((((_resume getTextWidth [_font, _size]) * TEXT_SLACK) + SQUARE(_height * 0.7)) max SQUARE(_height)) - SQUARE(_inset) * 2
    } else {
        SQUARE(_drawnH)
    };
    private _fixed = _padLeft + SQUARE(_ringH) + _gap * 2 + _drawnW + SQUARE(_inset);
    private _room = (_width - _fixed) max 0;

    // What it says now, and its shape - the width it is made for.
    private _words = if (_kind isEqualTo "") then {""} else {
        [_holder, _kind, _stopped, _idle, _sealedBox, _now, _room, _font, _size] call FUNC(statusWords)
    };

    if (_words isEqualTo "") then {
        _kind = "";
    };

    private _shape = _words regexReplace ["[0-9]", "0"];
    private _signature = [_kind, _stopped, _idle, _shape];

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

    private _text2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
    private _controls = [];
    private _labelW = ((_shape getTextWidth [_font, _size]) * TEXT_SLACK) min _room;
    private _chipW = _fixed + _labelW;

    // The surface of the chip, like the tab's and as round as the buttons beside it: a pill (the theme's radius, at most half the height).
    private _radius = (_theme getOrDefault ["radius", 0]) min (_height / 2);

    _controls append ([_display, _parent, [_left, _top, _chipW, _height], _info getOrDefault ["tabColor", [0, 0, 0, 0.5]], _radius] call FUNC(uiPanel));

    // The ring: its track, and over it the arc that goes round (not while a search is stopped).
    private _ringRect = [_left + _padLeft, _top + (_height - _ringH) / 2, SQUARE(_ringH), _ringH];

    _controls pushBack ([
        _display, _parent, _ringRect, SEARCH_RING(SEARCH_FRAMES), _theme getOrDefault ["searchTrack", [1, 1, 1, 0.12]]
    ] call FUNC(uiIcon));

    private _arc = controlNull;

    if (!_stopped) then {
        _arc = [_display, _parent, _ringRect, SEARCH_RING(STATUS_ARC), _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]]] call FUNC(uiIcon);
        _controls pushBack _arc;
    };

    // A label draws its text from its top edge down: the line of capitals is in the middle of the chip when the label
    // starts TEXT_MID of the font's height above it. Centred in its room, which is just as wide as the words.
    private _textTop = _top + _height / 2 - _size * TEXT_MID;

    private _label = [
        _display, _parent, [_left + _padLeft + SQUARE(_ringH) + _gap, _textTop, _labelW, _size * 1.4], _words, _size, _text2, _font, 2, -1
    ] call FUNC(uiLabel);

    _controls pushBack _label;

    // The button, at the end of the chip: round, one gap after the words. The cross is a circle, "Search" a pill.
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
            _display, _parent, [_buttonX, _textTop, _drawnW, _size * 1.4], _resume, _size, [1, 1, 1, 1], _font, 2, "button"
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
    [_hit, [
        LLSTRING(Status_StopHands),
        [LLSTRING(Status_StopSearch), [LLSTRING(Status_ResumeSearch), LLSTRING(Status_StartSearch)] select _idle] select _stopped
    ] select (_kind isEqualTo "search")] call FUNC(setTooltip);
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
        ["text", _words], ["shape", _shape], ["stopped", _stopped], ["idle", _idle], ["room", _room], ["font", _font],
        ["size", _size], ["sealed", _sealedBox]
    ]];
} forEach (uiNamespace getVariable [QGVAR(sectionInfo), []]);

GVAR(statusLive) = _live;

// The words and the ring are right from the first frame.
if (_live) then {
    GVAR(statusSecond) = -1;
    [_display, diag_tickTime] call FUNC(animateStatus);
};
