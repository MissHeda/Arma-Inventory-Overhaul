#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Moves a weapon card of the equipment column to another place by its header (fnc_drawEquipmentCards). Press on the
 * header and hold it CARD_HOLD_TIME seconds - a bar in the accent colour fills along its foot meanwhile, so the player
 * sees the hold is going somewhere - and the card pops out: its header, a little larger, as a plate in the accent colour,
 * follows the mouse up or down, and a line in the accent colour shows between which cards it will go. Let go, it goes
 * there; let go where it already is and nothing changes.
 *
 * Let go before the bar is full, the press was a click, which the header's own button turns into a fold (its release
 * is its click, fnc_onMouseButton). Moved off by more than CARD_HOLD_SLACK meanwhile, the hold is given up: the player
 * is not holding still on it. A hold that lifted the card takes the click its release would give (GVAR(cardHoldTaken),
 * GVAR(pressedButton)): the card was moved, not folded.
 *
 * The order is each player's own, kept in the profile (GVAR(weaponOrder)). The second primary's card, where no
 * two-primary mod gives the unit that slot, is not shown and keeps its place in the order for when one does.
 *
 * The steps: "press" from the header's press; "wait" from the frame (fnc_onFrame) while it is held, until the hold is let
 * go, given up ("cancel") or full ("begin"); "move" and "end" from the frame for as long as the lifted card is held - the
 * release is seen there whichever control it happens over. What the cards drew this build is in GVAR(cardSpans):
 * [slot, anchor as fnc_gridOrigin takes it, width, height] each, top down.
 *
 * Arguments:
 * 0: Step, "press", "wait", "cancel", "begin", "move" or "end" <STRING>
 * 1: For "press": the header's hit box, with what the hold needs in its variable aio_gui_hold (fnc_drawEquipmentCards)
 *    <CONTROL>; for "begin": that variable <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["press", _hit] call aio_gui_fnc_cardGrip;
 *
 * Public: No
 */

disableSerialization;

params [["_step", "", [""]], ["_argument", controlNull, [controlNull, []]]];

// The cards as they lie on the screen now (the column may have scrolled): [slot, x, y, width, height] each.
private _fnc_spans = {
    (uiNamespace getVariable [QGVAR(cardSpans), []]) apply {
        _x params ["_spanSlot", "_anchor", "_spanW", "_spanH"];

        ([_anchor] call FUNC(gridOrigin)) params ["_spanX", "_spanY"];

        [_spanSlot, _spanX, _spanY, _spanW, _spanH]
    }
};

// Where a header lies on the screen now: [x, y, width, height].
private _fnc_headerRect = {
    params ["_anchor", "_size"];

    ([_anchor] call FUNC(gridOrigin)) params ["_rectX", "_rectY"];

    [_rectX, _rectY, _size select 0, _size select 1]
};

switch (_step) do {
    case "press": {
        private _display = uiNamespace getVariable [QGVAR(display), displayNull];
        private _hold = if (_argument isEqualType controlNull) then {_argument getVariable [QGVAR(hold), []]} else {[]};

        // A new press is a new click, whatever an earlier hold took.
        GVAR(cardHoldTaken) = "";

        ["cancel"] call FUNC(cardGrip);

        if (isNull _display || {_hold isEqualTo []} || {(uiNamespace getVariable [QGVAR(cardDrag), []]) isNotEqualTo []}) exitWith {};

        private _bar = [_display, "AIO_PanelRect", controlNull, [0, 0, 0, 0]] call FUNC(uiCreate);
        _bar ctrlSetBackgroundColor (_hold select 1);

        // Real time, not the mission's: a hold is the player's hand, and the mission's clock may stand still.
        uiNamespace setVariable [QGVAR(cardHold), [_argument, _hold, diag_tickTime, getMousePosition, _bar]];

        ["wait"] call FUNC(cardGrip);
    };

    case "wait": {
        (uiNamespace getVariable [QGVAR(cardHold), []]) params [
            ["_hit", controlNull], ["_hold", []], ["_start", 0], ["_mouseStart", [0, 0]], ["_bar", controlNull]
        ];

        if (_hold isEqualTo []) exitWith {};

        // Let go before the bar was full: a click, which the header's button gives. Built again meanwhile, the window
        // took the header with it.
        if (inputMouse 0 == 0 || {isNull _hit}) exitWith {
            ["cancel"] call FUNC(cardGrip);
        };

        getMousePosition params ["_mouseX", "_mouseY"];
        _mouseStart params ["_startX", "_startY"];

        if (abs (_mouseX - _startX) > CARD_HOLD_SLACK || {abs (_mouseY - _startY) > CARD_HOLD_SLACK}) exitWith {
            ["cancel"] call FUNC(cardGrip);
        };

        ([_hold select 2, _hold select 3] call _fnc_headerRect) params ["_rectX", "_rectY", "_rectW", "_rectH"];

        private _share = ((diag_tickTime - _start) / CARD_HOLD_TIME) min 1;

        if (!isNull _bar) then {
            _bar ctrlSetPosition [_rectX, _rectY + _rectH - pixelH * 3, (_rectW * _share) max pixelW, pixelH * 3];
            _bar ctrlCommit 0;
        };

        if (_share < 1) exitWith {};

        ["cancel"] call FUNC(cardGrip);

        // The release ends the move, not a click: neither the one fnc_onMouseButton would give nor the engine's own - by
        // this header's key, so no other button's click is taken for it.
        GVAR(cardHoldTaken) = _hold select 0;
        GVAR(pressedButton) = [];

        ["begin", _hold] call FUNC(cardGrip);
    };

    case "cancel": {
        private _bar = (uiNamespace getVariable [QGVAR(cardHold), []]) param [4, controlNull];

        uiNamespace setVariable [QGVAR(cardHold), []];
        ctrlDelete _bar;
    };

    case "begin": {
        private _display = uiNamespace getVariable [QGVAR(display), displayNull];

        if !(_argument isEqualType []) exitWith {};

        _argument params ["_slot", "_color", "_anchor", "_size", "_text", "_font", "_textSize", "", "_onAccent"];

        if (isNull _display || {((call _fnc_spans) findIf {(_x select 0) isEqualTo _slot}) < 0}) exitWith {};

        private _rect = [_anchor, _size] call _fnc_headerRect;

        // The lifted card: its header as a plate in the accent colour, its words on it, laid over the column where the
        // header lies - "move" lifts it off from there.
        private _plate = [_display, "AIO_PanelRect", controlNull, _rect] call FUNC(uiCreate);
        _plate ctrlSetBackgroundColor _color;

        private _label = [_display, controlNull, _rect, _text, _textSize, _onAccent, _font, 0, false] call FUNC(uiLabel);

        private _line = [_display, "AIO_PanelRect", controlNull, [0, 0, 0, 0]] call FUNC(uiCreate);
        _line ctrlSetBackgroundColor _color;

        getMousePosition params ["", "_mouseY"];

        // Where on the header it was taken: the header keeps that spot under the mouse.
        private _grab = _mouseY - (_rect select 1);

        uiNamespace setVariable [QGVAR(cardDrag), [_slot, _line, -1, [_plate, _label], _grab, _rect, diag_tickTime]];

        ["move"] call FUNC(cardGrip);
    };

    case "move": {
        (uiNamespace getVariable [QGVAR(cardDrag), []]) params [
            ["_held", ""], ["_line", controlNull], ["_target", -1], ["_ghost", []], ["_grab", 0], ["_rect", []], ["_began", 0]
        ];

        private _spans = call _fnc_spans;

        // The window was built again meanwhile and took the line with it: the drag ends with nothing moved.
        if (isNull _line || {_spans isEqualTo []}) exitWith {
            {ctrlDelete _x} forEach _ghost;
            uiNamespace setVariable [QGVAR(cardDrag), []];
        };

        // The gap the mouse is nearest: before the first card whose middle lies below it.
        getMousePosition params ["", "_mouseY"];

        _target = _spans findIf {_mouseY < (_x select 2) + (_x select 4) / 2};

        if (_target < 0) then {
            _target = count _spans;
        };

        private _first = _spans select 0;
        private _lineY = if (_target < count _spans) then {
            ((_spans select _target) select 2) - pixelH * 4
        } else {
            private _last = _spans select -1;
            (_last select 2) + (_last select 4) + pixelH * 2
        };

        _line ctrlSetPosition [_first select 1, _lineY, _first select 3, pixelH * 2];
        _line ctrlCommit 0;

        // The header pops out: a little larger than it lay, it grows to that in CARD_POP_TIME, and then follows the mouse
        // up and down on the column without lagging behind it.
        if (_rect isNotEqualTo []) then {
            _rect params ["_rectX", "", "_rectW", "_rectH"];
            _ghost params [["_plate", controlNull], ["_label", controlNull]];

            private _liftH = pixelH * 3;
            private _liftW = pixelW * 3;
            private _ghostY = _mouseY - _grab;
            private _commit = [0, CARD_POP_TIME] select (diag_tickTime - _began < CARD_POP_TIME);
            private _textX = _rectX + SQUARE(_rectH);

            _plate ctrlSetPosition [_rectX - _liftW, _ghostY - _liftH, _rectW + _liftW * 2, _rectH + _liftH * 2];
            _plate ctrlCommit _commit;
            _label ctrlSetPosition [_textX, _ghostY, (_rectX + _rectW - _textX) max pixelW, _rectH];
            _label ctrlCommit _commit;
        };

        uiNamespace setVariable [QGVAR(cardDrag), [_held, _line, _target, _ghost, _grab, _rect, _began]];
    };

    case "end": {
        (uiNamespace getVariable [QGVAR(cardDrag), []]) params [["_held", ""], ["_line", controlNull], ["_target", -1], ["_ghost", []]];

        uiNamespace setVariable [QGVAR(cardDrag), []];
        ctrlDelete _line;

        {ctrlDelete _x} forEach _ghost;

        private _shown = (uiNamespace getVariable [QGVAR(cardSpans), []]) apply {_x select 0};
        private _from = _shown find _held;

        if (_from < 0 || {_target < 0}) exitWith {};

        // Let go below itself, the card leaves its own place first.
        if (_target > _from) then {
            _target = _target - 1;
        };

        if (_target == _from) exitWith {};

        _shown deleteAt _from;
        _shown insert [_target, [_held]];

        // A card not shown keeps its place in the order.
        private _order = +_shown;

        {
            if !(_x in _order) then {
                _order insert [_forEachIndex min count _order, [_x]];
            };
        } forEach GVAR(weaponOrder);

        GVAR(weaponOrder) = _order;
        profileNamespace setVariable [QGVAR(weaponOrder), +_order];
        saveProfileNamespace;

        [] call FUNC(buildSoon);
    };
};
