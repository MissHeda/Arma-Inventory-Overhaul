#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Runs every frame while the window is open: follows the mouse over the grids and slots, now and then
 * checks whether the window should still be open at all, and once a second whether what it shows is
 * still what the containers hold - built again when not.
 *
 * That check reads what lies around the unit anew (fnc_readNearby) and compares the signature part by
 * part (fnc_getSignature): the unit's own gear or the list of sections changed, and the window is built
 * again; only the cargo or places of some sections of the loot column changed - another player
 * rearranging a crate -, and only those sections draw their tiles again (fnc_redrawTiles), the rest of
 * the window and every column's scroll stays; a section that cannot be drawn again in place builds the
 * window after all.
 *
 * A frame dragged out from an empty cell (fnc_startBand) is followed here like a drag, and nothing is
 * built while it is held.
 *
 * The mouse is read here rather than from mouse events: the tiles are drawn by many small controls,
 * and which of them gets an event says little about the cell the mouse is on. The cell comes from the
 * position alone (fnc_screenToCell).
 *
 * While another window lies over this one (fnc_isCovered) it keeps still - no focus taken back, no
 * mouse followed, nothing built again - and only checks whether it should still be open. Uncovered,
 * it looks at once whether anything changed meanwhile.
 *
 * First thing every frame, covered or not, it finishes what could not be done inside an event: the kit
 * windows that went are deleted (fnc_clearWindows, fnc_raiseWindow), and groups made a frame ago are
 * scrolled back to where they were (QGVAR(scrollRestore): fnc_build, fnc_drawWindow).
 *
 * The window's moves are transactions (fnc_sendMoves): their answers (GVAR(answers)) are finished here
 * once the places they name reached this machine, each by fnc_afterAction - the tiles no longer under
 * way, what moved learnt, the window built again, where it landed lit up, the hint saying what did not
 * go as asked. At each contents check it reports drift to the authorities (fnc_requestNormalize) and
 * stops waiting for moves with no answer after PENDING_TIMEOUT; while its own moves are under way it
 * does not build for a change of contents - their answers do.
 *
 * While magazines are repacked (einv_magazines - only when that addon is loaded) the hands are busy: the
 * repack is followed every frame (einv_magazines_fnc_onFrame) and nothing else is - no hover, no drag, no
 * searching, no answers finished - but the checks whether the window should still be open and whether
 * what it shows is what the containers hold. Another window over this one stops the repack.
 *
 * At each check, after those whether the window should stay open, the looting pose is looked after: a
 * soldier taken away from the loot closes the window, the pose comes back after a weapon change
 * (fnc_poseCheck).
 *
 * The sound of each answer is played as it is finished (fnc_afterAction, fnc_feelAnswer).
 *
 * A window that attached with hooks (fnc_attach) is asked about the rest: whether it should stay open at all
 * ("keepOpen" - the inventory's rules read the player's unit, which is not what an editor window
 * dresses), once a frame what it has to do ("frame", also while something is dragged, not while another
 * window lies over this one), and whether the focus is given back to the sink for every control that
 * has it ("focusAll", only while no mouse button is held: a button pressed keeps the focus until its
 * click came).
 *
 * Arguments:
 * None - it is called by the driver of the frame (fnc_startFrame)
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_gui_fnc_onFrame;
 *
 * Public: No
 */

// The display is looked up rather than handed in: CBA keeps its frame handlers in the mission namespace,
// which cannot hold a display.
private _display = uiNamespace getVariable [QGVAR(display), displayNull];

// Gone without its unload handler having run - the frame must not outlive it, nor the camera
// (fnc_stopFrame ends whichever driver called this).
if (isNull _display) exitWith {
    call FUNC(stopFrame);
    call FUNC(cameraStop);
};

// Kit windows that went inside an event of their own - raised, closed, drawn again: hidden at once, and
// deleted here, out of that event.
private _trash = uiNamespace getVariable [QGVAR(windowTrash), []];

if (_trash isNotEqualTo []) then {
    {ctrlDelete _x} forEach _trash;
    uiNamespace setVariable [QGVAR(windowTrash), []];
};

// Groups made a frame ago know their height now: each goes back to where it was scrolled, in screen
// height from the top - as far as its new content lets it.
private _restore = uiNamespace getVariable [QGVAR(scrollRestore), []];

if (_restore isNotEqualTo []) then {
    private _later = [];

    {
        _x params ["_group", "_pixels", "_frame"];

        if (isNull _group) then {continue};

        if (_frame >= diag_frameNo) then {
            _later pushBack _x;
            continue;
        };

        (ctrlPosition _group) params ["", "", "", "_groupH"];

        private _range = (_group getVariable [QGVAR(contentH), _groupH]) - _groupH;

        if (_range > 0) then {
            _group ctrlSetScrollValues [(_pixels / _range) min 1, -1];
        };
    } forEach _restore;

    uiNamespace setVariable [QGVAR(scrollRestore), _later];
};

private _mouse = getMousePosition;
private _now = diag_tickTime;
private _check = _now >= GVAR(nextCheck);

// A vanilla inventory that came up over this window - another mod's doing - is closed again. The display's
// load event does that already; this is for one it missed.
if (_check) then {
    [] call FUNC(guardVanilla);
};

// The vanilla inventory closes when its unit dies or passes out, and when the player stops being it.
// A living person walks off by themselves, unlike a crate: the window goes when they are gone, out of
// reach, in a vehicle, taken by someone else (ACE dragging, carrying, escorting), when their backpack is
// no longer on them, or when they may no longer be opened as shown (fnc_canOpenPerson). One who dies
// meanwhile is a body now, and the window stays while it lies in reach. Asked while another window lies
// over this one as well: the person may walk off meanwhile.
private _fnc_mustClose = {
    // A window with its own rules for it (the Arsenal's: its unit is not ACE_player in Eden or Zeus).
    if ("keepOpen" in GVAR(hooks)) exitWith {
        !(["keepOpen", [], false] call FUNC(hook))
    };

    !alive GVAR(unit)
    || {GVAR(unit) isNotEqualTo ACE_player}
    || {GVAR(unit) getVariable ["ACE_isUnconscious", false]}
    || {GVAR(personMode) isNotEqualTo "" && {
        private _person = GVAR(person);

        !([GVAR(unit), _person, true] call FUNC(personInReach))
        || {GVAR(personMode) isEqualTo "backpack" && {GVAR(container) isNotEqualTo backpackContainer _person}}
        || {alive _person && {
            private _mode = [_person] call FUNC(canOpenPerson);
            _mode isEqualTo "" || {_mode isEqualTo "backpack" && {GVAR(personMode) isEqualTo "whole"}}
        }}
    }}
};

// Another window over this one - one an option of another mod's context menu opened, or Enhanced First
// Aid Kits' own. Its keys and its mouse are its own: taking the focus back every frame would make it
// unusable. Once it is gone, whatever it changed shows.
private _covered = [_display] call FUNC(isCovered);

if (_covered isNotEqualTo GVAR(covered)) then {
    GVAR(covered) = _covered;

    if (_covered) then {
        // What was held goes back, and a press can no longer become a drag: its button comes up over the
        // other window.
        if (GVAR(dragging)) then {
            GVAR(dragTarget) = [];
            [_display] call FUNC(endDrag);
        };

        GVAR(press) = [];
        GVAR(windowMove) = [];
        call FUNC(closeMenu);
        (uiNamespace getVariable [QGVAR(tooltip), controlNull]) ctrlShow false;

        // The comparison card goes too (fnc_updateHover makes it again once the mouse is back).
        ctrlDelete (uiNamespace getVariable [QGVAR(compare), controlNull]);
        uiNamespace setVariable [QGVAR(compare), controlNull];
        uiNamespace setVariable [QGVAR(tipShown), controlNull];

        // Repacking magazines goes no further under another window (einv_magazines).
        if (!isNil QEFUNC(magazines,stop)) then {
            ["Interrupted"] call EFUNC(magazines,stop);
        };
    } else {
        call FUNC(requestRebuild);
    };
};

if (_covered) exitWith {
    if (!_check) exitWith {};

    GVAR(nextCheck) = _now + CHECK_INTERVAL;

    if (call _fnc_mustClose) then {
        _display closeDisplay 2;
    };
};

// A click into a column gives it the focus, and the engine draws the focused control over every other -
// the context menu, the inspect card, the dragged ghost and the name at the mouse would end up under
// it. The focus goes straight back to the search field's sink (fnc_drawFilter), unless the field is
// being typed in. A window with buttons of its own in groups (the "focusAll" flag) has every control but
// a field sent back - while no mouse button is held: a button pressed keeps the focus until its click
// came, or the click would be lost.
private _focus = focusedCtrl _display;

if (!isNull _focus) then {
    private _sink = uiNamespace getVariable [QGVAR(filterSink), controlNull];

    if (
        ctrlType _focus == 15
        || {
            (["focusAll", [], false] call FUNC(hook)) && {inputMouse 0 == 0} && {inputMouse 1 == 0}
            && {ctrlType _focus != 2} && {_focus isNotEqualTo _sink}
        }
    ) then {
        ctrlSetFocus _sink;
    };
};

// Repacking magazines (einv_magazines): the hands are busy - nothing is picked up, lit up or searched
// meanwhile. The repack runs its course; the window still closes and shows changes as always.
if (!isNil QEFUNC(magazines,isBusy) && {[] call EFUNC(magazines,isBusy)}) exitWith {
    [_display, _now] call EFUNC(magazines,onFrame);

    if (!_check) exitWith {};

    GVAR(nextCheck) = _now + CHECK_INTERVAL;

    if (call _fnc_mustClose) exitWith {
        _display closeDisplay 2;
    };

    if (_now < GVAR(nextSignature) || {count GVAR(inFlight) > 0}) exitWith {};

    GVAR(nextSignature) = _now + SIGNATURE_INTERVAL;

    if ((call FUNC(getSignature)) isNotEqualTo GVAR(signatureParts)) then {
        [_display] call FUNC(build);
    };
};

// The inspect card follows the mouse while its title is held (fnc_drawInspect) - whole on the screen.
if (GVAR(inspectMove) isNotEqualTo []) then {
    private _group = uiNamespace getVariable [QGVAR(inspectGroup), controlNull];

    if (inputMouse 0 == 0 || {isNull _group}) then {
        GVAR(inspectMove) = [];
    } else {
        GVAR(inspectMove) params ["_holdX", "_holdY"];
        (ctrlPosition _group) params ["", "", "_cardW", "_cardH"];

        private _cardX = (((_mouse select 0) - _holdX) max safezoneX) min (safezoneX + safezoneW - _cardW);
        private _cardY = (((_mouse select 1) - _holdY) max safezoneY) min ((safezoneY + safezoneH - _cardH) max safezoneY);

        _group ctrlSetPosition [_cardX, _cardY];
        _group ctrlCommit 0;

        GVAR(inspectPos) = [_cardX, _cardY];
        uiNamespace setVariable [QGVAR(inspectRect), [_cardX, _cardY, _cardW, _cardH]];
    };
};

// A kit window follows the mouse the same way while its title is held (fnc_onMouseButton) - whole on the
// screen's sides and between header and footer, its corner on a pixel so every see-through edge stays
// sharp. Looked up by its key every frame: a build meanwhile makes it anew.
if (GVAR(windowMove) isNotEqualTo []) then {
    GVAR(windowMove) params ["_key", "_holdX", "_holdY"];

    private _windows = uiNamespace getVariable [QGVAR(windows), []];
    private _index = _windows findIf {(_x getOrDefault ["key", ""]) isEqualTo _key};
    private _record = if (_index >= 0) then {_windows select _index} else {createHashMap};
    private _group = _record getOrDefault ["group", controlNull];

    if (inputMouse 0 == 0 || {isNull _group}) then {
        GVAR(windowMove) = [];
    } else {
        (ctrlPosition _group) params ["", "", "_windowW", "_windowH"];

        private _windowX = SNAP_X((((_mouse select 0) - _holdX) min (safezoneX + safezoneW - _windowW)) max safezoneX);
        private _windowY = SNAP_Y((((_mouse select 1) - _holdY) min (CONTENT_B - _windowH)) max CONTENT_Y);

        _group ctrlSetPosition [_windowX, _windowY];
        _group ctrlCommit 0;

        _record set ["rect", [_windowX, _windowY, _windowW, _windowH]];
        GVAR(windowPos) set [_key, [_windowX, _windowY]];
    };
};

// A press on a tile becomes a drag once the mouse moves; a drag follows the mouse every frame.
if (GVAR(press) isNotEqualTo [] && {!GVAR(dragging)}) then {
    (GVAR(press) select 2) params ["_startX", "_startY"];

    if (abs ((_mouse select 0) - _startX) > DRAG_THRESHOLD || {abs ((_mouse select 1) - _startY) > DRAG_THRESHOLD}) then {
        [_display] call FUNC(startDrag);
    };
};

// What a window that attached has to do every frame, also while something is dragged (its camera, its
// scrolling list).
["frame", [_display, _mouse, _now]] call FUNC(hook);

if (GVAR(dragging)) exitWith {
    GVAR(lastMouse) = _mouse;
    [_display, _mouse] call FUNC(updateDrag);
};

// A press on an empty cell of a column becomes a frame once the mouse moves; the frame follows the mouse
// every frame. Let go outside the window - where no event reaches - it ends all the same.
if (GVAR(bandPress) isNotEqualTo [] && {!GVAR(band)}) then {
    (GVAR(bandPress) select 1) params ["_bandStartX", "_bandStartY"];

    if (inputMouse 0 == 0) then {
        // The button came up where no click reached us: it was a click on an empty cell all the same.
        GVAR(bandPress) = [];
    } else {
        if (abs ((_mouse select 0) - _bandStartX) > DRAG_THRESHOLD || {abs ((_mouse select 1) - _bandStartY) > DRAG_THRESHOLD}) then {
            [_display] call FUNC(startBand);
        };
    };
};

if (GVAR(band)) exitWith {
    GVAR(lastMouse) = _mouse;

    if (inputMouse 0 == 0) then {
        [_display] call FUNC(endBand);
    } else {
        [_display, _mouse] call FUNC(updateBand);
    };
};

// Scrolling a column moves the tiles under a mouse that stands still, so the hover is looked at again
// on every check as well.
if (_check || {_mouse isNotEqualTo GVAR(lastMouse)}) then {
    GVAR(lastMouse) = _mouse;
    [_display, _mouse] call FUNC(updateHover);
};

// The name at the mouse, or the comparison card in its place, stays beside the pointer - on its left near the
// screen's right edge, above it near the bottom. Whichever shows (fnc_updateHover) says how wide and high it is.
private _tip = uiNamespace getVariable [QGVAR(tipShown), controlNull];

if (!isNull _tip && {ctrlShown _tip} && {GVAR(tooltipAt) isNotEqualTo _mouse}) then {
    GVAR(tooltipAt) = _mouse;
    _mouse params ["_mouseX", "_mouseY"];

    private _width = _tip getVariable [QGVAR(width), 0];
    private _height = _tip getVariable [QGVAR(height), UNIT];
    private _tipX = _mouseX + TOOLTIP_DX;
    private _tipY = _mouseY + TOOLTIP_DY;

    if (_tipX + _width > safezoneX + safezoneW) then {_tipX = _mouseX - TOOLTIP_DX - _width};
    if (_tipY + _height > safezoneY + safezoneH) then {_tipY = (_mouseY - TOOLTIP_DY - _height) max safezoneY};

    _tip ctrlSetPosition [_tipX, _tipY];
    _tip ctrlCommit 0;
};

// Searching, every frame: the ring fills and the glass goes round, and the item shows once its time is
// up (fnc_animateSearch). Not while something is held: a rebuild would pull it from under the mouse.
if (GVAR(press) isEqualTo []) then {
    [_display, _now] call FUNC(animateSearch);
};

// ----- Answers to the window's moves -----
// Each finishes once this machine reads every revision of the places it names - a holder gone
// meanwhile, the last item taken from a pile the engine then deleted, counts as read - or ANSWER_WAIT
// seconds after it came (fnc_onAnswer): a tile never shows on a first-fit cell for a frame because its
// cargo arrived before its place. Every frame, so a move in single player - answered in the frame it was
// asked for - shows at once; not while something is held: a build would pull it from under the mouse.
if (GVAR(answers) isNotEqualTo [] && {GVAR(press) isEqualTo []}) then {
    private _ready = [];
    private _waiting = [];

    {
        _x params ["", "", ["_revisions", [], [[]]], "", ["_arrived", 0, [0]]];

        private _reached = _now >= _arrived + ANSWER_WAIT || {
            (_revisions findIf {
                _x params [["_holder", objNull, [objNull, ""]], ["_revision", 0, [0]]];

                (_holder isEqualType "" || {!isNull _holder}) && {(([_holder] call EFUNC(storage,readPlaces)) select 0) < _revision}
            }) < 0
        };

        if (_reached) then {
            _ready pushBack _x;
        } else {
            _waiting pushBack _x;
        };
    } forEach GVAR(answers);

    if (_ready isEqualTo []) exitWith {};

    GVAR(answers) = _waiting;

    // Each handed to fnc_afterAction, in the order they came: its tiles no longer under way, what moved
    // learnt, the window built again with where it landed lit up, the hint saying what did not go as
    // asked.
    {
        _x call FUNC(afterAction);
    } forEach _ready;
};

if (!_check) exitWith {};

GVAR(nextCheck) = _now + CHECK_INTERVAL;

if (call _fnc_mustClose) exitWith {
    _display closeDisplay 2;
};

// The looting pose: the soldier taken away from the loot closes the window; a pose that is not reached yet,
// or lost to a weapon change, is looked after (fnc_poseCheck).
if ([_display] call FUNC(poseCheck)) exitWith {};

// Not while a tile is held, or a frame is about to be dragged out: a rebuild would pull it from under the
// mouse.
if (_now < GVAR(nextSignature) || {GVAR(press) isNotEqualTo []} || {GVAR(bandPress) isNotEqualTo []}) exitWith {};

GVAR(nextSignature) = _now + SIGNATURE_INTERVAL;

// Holders whose places disagree with what they hold are reported to their authorities
// (fnc_requestNormalize, from what fnc_drawCompartments noted).
call FUNC(requestNormalize);

// Moves with no answer after PENDING_TIMEOUT: the window stops waiting and shows what is there. Nothing
// is touched by that - an answer that still comes is finished as any other.
private _late = [];

// A HashMap: _x is the request id, _y its record - sent at its third element.
{
    if (_now > ((_y param [2, _now, [0]]) + PENDING_TIMEOUT)) then {
        _late pushBack _x;
    };
} forEach GVAR(inFlight);

if (_late isNotEqualTo []) exitWith {
    {
        GVAR(inFlight) deleteAt _x;
    } forEach _late;

    [_display] call FUNC(build);
    [LLSTRING(Hint_Waiting)] call FUNC(flashHint);
};

// Built again when what the containers hold or where it lies changed - and while a uniform, vest or
// backpack opened from inside a container is still to be found again (fnc_build). Not while the
// window's own moves are under way: the cargo they change may come before its places, and a tile would
// show on a first-fit cell for a moment - their answers build it once both are here.
if (count GVAR(inFlight) > 0) exitWith {};

// What lies around now - a pile that came or went changes the list of sections.
call FUNC(readNearby);

private _signature = call FUNC(getSignature);
private _before = GVAR(signatureParts);

// The unit's own gear, or which sections the loot column shows: the window is built again.
if (
    _before isEqualTo [] || {(_signature select 0) isNotEqualTo (_before select 0)}
    || {(_signature select 1) isNotEqualTo (_before select 1)} || {GVAR(opened) findIf {isNull (_x select 1)} >= 0}
    || {count (_signature select 2) != count (_before select 2)}
) exitWith {
    [_display] call FUNC(build);
};

// Only what some sections of the loot column hold or where it lies: those sections draw their tiles again.
private _changed = [];

{
    if (_x isNotEqualTo ((_before select 2) param [_forEachIndex, []])) then {
        _changed pushBack (_x select 0);
    };
} forEach (_signature select 2);

if (_changed isEqualTo []) exitWith {};

if ([_changed] call FUNC(redrawTiles)) then {
    GVAR(signatureParts) = _signature;
} else {
    [_display] call FUNC(build);
};
