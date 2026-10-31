#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Runs every frame while the window is open: follows the mouse over the grids and slots, now and then
 * checks whether the window should still be open at all, and once a second whether what it shows is
 * still what the containers hold - built again when not.
 *
 * That check reads what lies around the unit anew (fnc_readNearby) and compares the signature part by
 * part (fnc_refresh, fnc_getSignature): the unit's own gear or the list of sections changed, and the window
 * is built again; only the cargo or places of some sections changed - another player rearranging a crate -,
 * and only those sections draw their tiles again (fnc_redrawTiles), with the weight card when they are the
 * unit's own; the rest of the window and every column's scroll stays; a section that cannot be drawn again
 * in place builds the window after all. Nothing of it runs more often than SIGNATURE_INTERVAL: the frame
 * itself only follows the mouse and what is held.
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
 * way, what moved learnt, the sections it touched drawn again (fnc_refresh), where it landed lit up, the
 * hint saying what did not go as asked. At each contents check it reports drift to the authorities
 * (fnc_requestNormalize) and stops waiting for moves with no answer after PENDING_TIMEOUT; while its own
 * moves are under way it does not draw for a change of contents - their answers do.
 *
 * While magazines are repacked (aio_magazines - only when that addon is loaded) the hands are busy: the
 * repack is followed every frame (aio_magazines_fnc_onFrame) and nothing else is - no hover, no drag, no
 * searching, no answers finished - but the checks whether the window should still be open and whether
 * what it shows is what the containers hold. Another window over this one stops the repack.
 *
 * At each check, after those whether the window should stay open, a soldier taken away from the loot
 * closes the window (fnc_checkTaken).
 *
 * What clicks asked for that is heavy and had to rest (fnc_coalesce) is run once per key when its time is up
 * (fnc_coalesceTick), not while another window lies over this one.
 *
 * The hands' queue (fnc_queueMoves) runs every frame while it holds something (fnc_animateQueue), not while another
 * window lies over this one; the activity chips of the boxes' caption lines move with it and with the search
 * (fnc_animateStatus).
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
 * With "Log window timings (debug)" on, fnc_frame times it and each part says where it begins (NOTE_PHASE,
 * fnc_notePhase): start, queue, lift, drag, hover, search, warm, answers, check, contents. Off, that is an
 * isNil each.
 *
 * Arguments:
 * None - it is called by the driver of the frame (fnc_startFrame)
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_gui_fnc_onFrame;
 *
 * Public: No
 */

// The display is looked up rather than handed in: CBA keeps its frame handlers in the mission namespace,
// which cannot hold a display.
private _display = uiNamespace getVariable [QGVAR(display), displayNull];

// Gone without its unload handler having run - the frame must not outlive it
// (fnc_stopFrame ends whichever driver called this). The inventory's own dialog always runs its unload
// handler: one that did not was taken away with no event at all, and is ended here as any other close, so
// the RPT says so and nothing of it is left open. A display the window is a guest on ends it from its own
// close (the Arsenal's fnc_onClosed).
if (isNull _display) exitWith {
    if (call FUNC(isInventoryMode)) then {
        GVAR(closeReason) = "display lost - it went without its unload event";
        [displayNull, -1] call FUNC(onUnload);
    } else {
        call FUNC(stopFrame);
    };
};

// Kit windows that went inside an event of their own - raised, closed, drawn again: hidden at once, and
// deleted here, out of that event.
private _trash = uiNamespace getVariable [QGVAR(windowTrash), []];

if (_trash isNotEqualTo []) then {
    {ctrlDelete _x} forEach _trash;
    uiNamespace setVariable [QGVAR(windowTrash), []];
};

// Clip groups of pictures the wheel turned over: the engine scrolled them after the handler put them back, so
// they go back to the top again before this frame is drawn, for UNSCROLL_FRAMES frames (fnc_unscroll).
private _unscroll = uiNamespace getVariable [QGVAR(unscroll), []];

if (_unscroll isNotEqualTo []) then {
    _unscroll = _unscroll select {!isNull (_x select 0) && {diag_frameNo <= (_x select 1)}};

    {
        (_x select 0) ctrlSetScrollValues [0, 0];
    } forEach _unscroll;

    uiNamespace setVariable [QGVAR(unscroll), _unscroll];
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

// The turned pictures of turned tiles lie on the display: they follow their tiles' scroll and windows (fnc_syncTurned).
[] call FUNC(syncTurned);

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
// over this one as well: the person may walk off meanwhile. The answer is why, for the RPT (fnc_onUnload),
// "" to stay open.
private _fnc_mustClose = {
    // A window with its own rules for it (the Arsenal's: its unit is not ACE_player in Eden or Zeus).
    if ("keepOpen" in GVAR(hooks)) exitWith {
        ["", "the window's own rule (keepOpen hook)"] select !(["keepOpen", [], false] call FUNC(hook))
    };

    if (!alive GVAR(unit)) exitWith {"the unit died"};
    if (GVAR(unit) isNotEqualTo ACE_player) exitWith {"the player is no longer this unit (ACE_player changed)"};
    if (GVAR(unit) getVariable ["ACE_isUnconscious", false]) exitWith {"the unit is unconscious"};
    if (GVAR(personMode) isEqualTo "") exitWith {""};

    private _person = GVAR(person);

    if !([GVAR(unit), _person, true] call FUNC(personInReach)) exitWith {"the person is out of reach"};

    if (GVAR(personMode) isEqualTo "backpack" && {GVAR(container) isNotEqualTo backpackContainer _person}) exitWith {
        "the person's backpack is no longer on them"
    };

    if (alive _person && {
        private _mode = [_person] call FUNC(canOpenPerson);
        _mode isEqualTo "" || {_mode isEqualTo "backpack" && {GVAR(personMode) isEqualTo "whole"}}
    }) exitWith {
        "the person may no longer be opened like this"
    };

    ""
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

        if (GVAR(stripDrag) isNotEqualTo []) then {
            [_display, true] call FUNC(endStripDrag);
        };

        GVAR(press) = [];
        GVAR(windowMove) = [];
        call FUNC(closeMenu);
        (uiNamespace getVariable [QGVAR(tooltip), controlNull]) ctrlShow false;

        // The comparison card goes too (fnc_updateHover makes it again once the mouse is back).
        ctrlDelete (uiNamespace getVariable [QGVAR(compare), controlNull]);
        uiNamespace setVariable [QGVAR(compare), controlNull];
        uiNamespace setVariable [QGVAR(tipShown), controlNull];

        // Repacking magazines goes no further under another window (aio_magazines).
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

    private _why = call _fnc_mustClose;

    if (_why isNotEqualTo "") then {
        [_why] call FUNC(closeDisplay);
    };
};

// What clicks asked for that is heavy - a build, the pages, the search's fade - and had to rest (fnc_coalesce): one run per
// key when its time is up. Not under another window, which keeps still.
[] call FUNC(coalesceTick);

// The hands' queue: the first action is sent when its time is up (fnc_animateQueue). Not under
// another window, and the time it stood still does not count.
if (GVAR(handQueue) isNotEqualTo []) then {
    NOTE_PHASE("queue");
    [_display, _now] call FUNC(animateQueue);
    NOTE_PHASE("start");
};

// An open context menu made again on top once something was made on the display after it (fnc_raiseMenu). Asked
// only while one is open: that is all it answers to, and it runs twice every frame.
if (GVAR(menuState) isNotEqualTo []) then {
    [] call FUNC(raiseMenu);
};

// A click into a column gives it the focus, and the engine draws the focused control over every other -
// the context menu, the inspect card, the dragged ghost and the name at the mouse would end up under
// it. The focus goes straight back to the search field's sink (fnc_drawFilter), unless the field is
// being typed in. So does a button of the window's own in a group - a section's Sort, a kit
// window's cross - once its click came: it kept the focus, and its column drew its tiles over the
// context menu and the name at the mouse until the next build (a tester's report on 0.4.6). A window
// with buttons of its own in groups (the "focusAll" flag) has every control but a field sent back. Both
// only while no mouse button is held: a button pressed keeps the focus until its click came, or the
// click would be lost. The context menu's own focus stays where it is (fnc_openMenu).
// While something is held the focus goes back whatever the buttons say (fnc_takeFocus): the ghost and the footprint
// lie over everything only while no other control has it.
if (GVAR(dragging) || {GVAR(stripDrag) isNotEqualTo []}) then {
    [_display] call FUNC(takeFocus);
};

private _focus = focusedCtrl _display;

if (!isNull _focus) then {
    private _sink = uiNamespace getVariable [QGVAR(filterSink), controlNull];

    if (
        ctrlType _focus == 15
        || {
            (["focusAll", [], false] call FUNC(hook)) && {inputMouse 0 == 0} && {inputMouse 1 == 0}
            && {ctrlType _focus != 2} && {_focus isNotEqualTo _sink}
        }
        || {
            !isNull _sink && {_focus isNotEqualTo _sink} && {inputMouse 0 == 0} && {inputMouse 1 == 0}
            && {!(ctrlType _focus in [2, 4])} && {!isNull ctrlParentControlsGroup _focus}
            && {
                // The group it lies in at the top, one the window made (fnc_uiCreate) - not another mod's.
                private _group = ctrlParentControlsGroup _focus;
                private _outer = _group;

                while {!isNull _group} do {
                    _outer = _group;
                    _group = ctrlParentControlsGroup _group;
                };

                _outer in (uiNamespace getVariable [QGVAR(created), []])
                && {!(_outer in (uiNamespace getVariable [QGVAR(menu), []]))}
            }
        }
    ) then {
        ctrlSetFocus _sink;

        // The focused control was drawn over the name at the mouse meanwhile; it is made again on top (fnc_raiseTooltip).
        uiNamespace setVariable [QGVAR(tipStale), true];
        [] call FUNC(raiseTooltip);
    };
};

// Repacking magazines (aio_magazines): the hands are busy - nothing is picked up, lit up or searched
// meanwhile. The repack runs its course; the window still closes and shows changes as always.
if (!isNil QEFUNC(magazines,isBusy) && {[] call EFUNC(magazines,isBusy)}) exitWith {
    [_display, _now] call EFUNC(magazines,onFrame);

    if (!_check) exitWith {};

    GVAR(nextCheck) = _now + CHECK_INTERVAL;

    private _why = call _fnc_mustClose;

    if (_why isNotEqualTo "") exitWith {
        [_why] call FUNC(closeDisplay);
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

// A press on a tile becomes a drag once the mouse moves; a drag follows the mouse every frame. A press on a
// filled slot of the hotbar strip carries the slot's number as its tenth element: it drags the binding.
if (GVAR(press) isNotEqualTo [] && {!GVAR(dragging)} && {GVAR(stripDrag) isEqualTo []}) then {
    NOTE_PHASE("lift");

    (GVAR(press) select 2) params ["_startX", "_startY"];

    if (abs ((_mouse select 0) - _startX) > DRAG_THRESHOLD || {abs ((_mouse select 1) - _startY) > DRAG_THRESHOLD}) then {
        if ((GVAR(press) param [9, -1]) >= 0) then {
            // The button must still be down: a press whose release never reached the window is no drag.
            if (inputMouse 0 > 0) then {
                [_display] call FUNC(startStripDrag);
            } else {
                GVAR(press) = [];
            };
        } else {
            [_display] call FUNC(startDrag);
        };
    };
};

// What a window that attached has to do every frame, also while something is dragged (its camera, its
// scrolling list).
if ("frame" in GVAR(hooks)) then {
    ["frame", [_display, _mouse, _now]] call FUNC(hook);
};

// A hotbar slot's binding held (fnc_startStripDrag): it follows the mouse; let go outside the window - where
// no event reaches - it ends all the same.
NOTE_PHASE("drag");

if (GVAR(stripDrag) isNotEqualTo []) exitWith {
    GVAR(lastMouse) = _mouse;

    if (inputMouse 0 == 0) then {
        [_display] call FUNC(endStripDrag);
    } else {
        [_display, _mouse] call FUNC(updateStripDrag);
    };
};

if (GVAR(dragging)) exitWith {
    GVAR(lastMouse) = _mouse;
    [_display, _mouse] call FUNC(updateDrag);

    // A sealed block under the drag says why it takes nothing (the chips below are not reached while it is held).
    if (GVAR(statusLive)) then {
        [_display, _now, true] call FUNC(animateStatus);
    };
};

// A press on an empty cell is a click and nothing more: let go outside the window, where no event reaches,
// it is forgotten.
if (GVAR(emptyPress) isNotEqualTo [] && {inputMouse 0 == 0}) then {
    GVAR(emptyPress) = [];
};

NOTE_PHASE("hover");

// Scrolling a column moves the tiles under a mouse that stands still, so the hover is looked at again
// on every check as well.
if (_check || {_mouse isNotEqualTo GVAR(lastMouse)}) then {
    GVAR(lastMouse) = _mouse;
    [_display, _mouse] call FUNC(updateHover);
};

// The name at the mouse, or the comparison card in its place, stays centred under the pointer - pushed in from a screen edge
// rather than thrown to the pointer's other side, which made it jump from right to left and back as names of other widths came
// along; above the pointer only where it would run off the bottom. Whichever shows (fnc_updateHover) says how wide and high it is.
private _tip = uiNamespace getVariable [QGVAR(tipShown), controlNull];
private _tipUp = !isNull _tip && {ctrlShown _tip};

// An open menu or the colour popover is drawn over everything only while a control in it holds the focus (fnc_openMenu,
// fnc_openPaletteMenu). Should the focus go elsewhere - a deleted control's, a click that reached the window under it -, the layer
// sinks under the columns and they take every click meant for it: the focus goes back to the layer.
(uiNamespace getVariable [QGVAR(menuFocus), []]) params [["_menuLayer", controlNull], ["_menuFocus", controlNull]];

if (GVAR(menuState) isNotEqualTo [] && {!isNull _menuLayer} && {!isNull _menuFocus}) then {
    private _focused = focusedCtrl _display;
    private _inLayer = false;

    while {!isNull _focused} do {
        if (_focused isEqualTo _menuLayer) exitWith {_inLayer = true};

        _focused = ctrlParentControlsGroup _focused;
    };

    if (!_inLayer) then {
        ctrlSetFocus _menuFocus;
    };
};

if (_tipUp && {GVAR(tooltipAt) isNotEqualTo _mouse}) then {
    GVAR(tooltipAt) = _mouse;
    _mouse params ["_mouseX", "_mouseY"];

    private _width = _tip getVariable [QGVAR(width), 0];
    private _height = _tip getVariable [QGVAR(height), UNIT];
    private _tipX = ((_mouseX - _width / 2) min (safezoneX + safezoneW - TOOLTIP_MARGIN - _width)) max (safezoneX + TOOLTIP_MARGIN);
    private _tipY = _mouseY + TOOLTIP_DY;

    if (_tipY + _height > safezoneY + safezoneH - TOOLTIP_MARGIN) then {
        _tipY = (_mouseY - UNIT * 0.3 - _height) max safezoneY;
    };

    _tip ctrlSetPosition [_tipX, _tipY];
    _tip ctrlCommit 0;
};

// Searching, every frame: the item shows once its time is
// up (fnc_animateSearch). Not while something is held: a rebuild would pull it from under the mouse.
NOTE_PHASE("search");

if (GVAR(press) isEqualTo []) then {
    // Nothing being searched: only the clock of the pause is kept (fnc_animateSearch does no more than that
    // with no search under way).
    if (GVAR(searchQueue) isEqualTo [] && {GVAR(searchStarted) < 0}) then {
        GVAR(searchLast) = _now;
    } else {
        [_display, _now] call FUNC(animateSearch);
    };

    // Nothing held, no menu open: one more slot's drag highlight is made and kept hidden, so that lifting
    // an item makes none (fnc_warmTargets). Not while a menu is open - it would be made again over them.
    // Not once every slot has had its turn.
    if (
        (uiNamespace getVariable [QGVAR(menu), []]) isEqualTo []
        && {(uiNamespace getVariable [QGVAR(glowNext), 0]) < count (uiNamespace getVariable [QGVAR(slots), []])}
    ) then {
        NOTE_PHASE("warm");
        [_display] call FUNC(warmTargets);
    };
};

// The chips in the boxes' caption lines: the ring goes round, the count and the time are written when they changed
// (fnc_animateStatus).
if (GVAR(statusLive)) then {
    [_display, _now] call FUNC(animateStatus);
};

// The hover above may have lit a slot with a ring made on the display: the menu goes over it in this frame.
if (GVAR(menuState) isNotEqualTo []) then {
    [] call FUNC(raiseMenu);
};

// The name at the mouse - a button's tip too - over whatever a click drew since or gave the focus (a column refreshed after Sort,
// a part drawn again): every frame, as the menu. It does nothing while it is the last control made and nothing marked it stale.
// While a mouse button is held the engine draws the group pressed on over everything, whatever was made after it - the name went
// behind the tile it belongs to. It hides for the press, as a tooltip does, and comes back fresh on the release.
private _tipShown = uiNamespace getVariable [QGVAR(tipShown), controlNull];

if (inputMouse 0 != 0 || {inputMouse 1 != 0}) then {
    if (!isNull _tipShown && {ctrlShown _tipShown}) then {
        _tipShown ctrlShow false;
        GVAR(tipHeld) = true;
    };
} else {
    if (GVAR(tipHeld)) then {
        GVAR(tipHeld) = false;
        GVAR(lastMouse) = getMousePosition;
        [_display, GVAR(lastMouse), true] call FUNC(updateHover);
    };

    [] call FUNC(raiseTooltip);
};

// ----- Answers to the window's moves -----
// Each finishes once this machine reads every revision of the places it names - a holder gone
// meanwhile, the last item taken from a pile the engine then deleted, counts as read - or ANSWER_WAIT
// seconds after it came (fnc_onAnswer): a tile never shows on a first-fit cell for a frame because its
// cargo arrived before its place. Every frame, so a move in single player - answered in the frame it was
// asked for - shows at once; not while something is held: a build would pull it from under the mouse.
NOTE_PHASE("answers");

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
    // learnt, the sections it touched drawn again with where it landed lit up, the hint saying what did
    // not go as asked.
    {
        _x call FUNC(afterAction);
    } forEach _ready;
};

if (!_check) exitWith {};

NOTE_PHASE("check");

GVAR(nextCheck) = _now + CHECK_INTERVAL;

private _why = call _fnc_mustClose;

if (_why isNotEqualTo "") exitWith {
    [_why] call FUNC(closeDisplay);
};

// The soldier taken away from the loot closes the window (fnc_checkTaken).
if ([_display] call FUNC(checkTaken)) exitWith {};

// Not while a tile is held: a rebuild would pull it from under the mouse.
if (_now < GVAR(nextSignature) || {GVAR(press) isNotEqualTo []}) exitWith {};

GVAR(nextSignature) = _now + SIGNATURE_INTERVAL;

NOTE_PHASE("contents");

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

// The unit's own gear, or which sections the columns show: the window is built again. Only what some
// sections hold or where it lies: those sections draw their tiles again, and the weight card when it is the
// unit's own (fnc_refresh).
[_display] call FUNC(refresh);
