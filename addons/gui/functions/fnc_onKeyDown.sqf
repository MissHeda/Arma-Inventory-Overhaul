#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Display key down. Escape closes the window by itself - after the context menu, the inspect card, the kit
 * windows and the selection, one at a time. Ctrl+A selects everything in the section under the mouse
 * (fnc_selectSection). G drops the selected tiles, else the item under the mouse (Delete still does the
 * same, but the footer names G); the Gear key closes the window again, as it closes the vanilla inventory. A key the hotbar has a use for goes to it first
 * (einv_hotbar_fnc_onWindowKey - only when that addon is loaded). A window that attached (fnc_attach) is
 * offered the keys after those (the "key" hook) and before the Delete and Gear keys, and hears Return in
 * any field of its own ("submit").
 *
 * A movement key pressed while looting or searching closes the window (einv_gui_moveToStop): the search
 * stops and the soldier walks off. Keys already held as the window opened count only once they were let
 * go, keys pressed with Ctrl or Alt never (Ctrl+A is the selection's). Only on foot: a soldier in a seat
 * walks off nowhere, and there the same keys are the vehicle's - the window stays, as the vanilla
 * inventory stays in a vehicle. While magazines are repacked
 * (einv_magazines) Escape stops the repack and the window stays, and G and Delete wait.
 *
 * Not the press that opened the window, which can still be held down or repeating when it arrives here.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: DIK code <NUMBER>
 * 2: Shift held <BOOL>
 * 3: Ctrl held <BOOL>
 * 4: Alt held <BOOL>
 *
 * Return Value:
 * Key handled <BOOL>
 *
 * Example:
 * [_display, 23, false, false, false] call einv_gui_fnc_onKeyDown;
 *
 * Public: No
 */

params ["_display", "_key", ["_shift", false], ["_ctrl", false], ["_alt", false]];

// Repacking magazines (einv_magazines): Escape stops it and the window stays; G and Delete wait. Every other
// key does what it always does - the Gear key closes the window, which stops the repack too.
private _handled = false;

if (!isNil QEFUNC(magazines,isBusy) && {[] call EFUNC(magazines,isBusy)}) then {
    if (_key == DIK_ESCAPE) exitWith {
        ["Stopped"] call EFUNC(magazines,stop);
        _handled = true;
    };

    if (_key in [DIK_G, DIK_DELETE]) exitWith {
        _handled = true;
    };
};

if (_handled) exitWith {true};

// Escape closes an open context menu first, then the inspect card, then the topmost kit window
// (fnc_closeWindow), the window only after that. Not a kit window while the search field is typed in
// and has something to empty, nor while something is dragged - what is held may come from that window.
private _filterEdit = uiNamespace getVariable [QGVAR(filterEdit), controlNull];
private _focused = focusedCtrl _display;
private _typing = !isNull _filterEdit && {_focused isEqualTo _filterEdit};

// Any field with the cursor in it - the search field, or one on a display this window is a guest on
// (ACE Arsenal's search) - has the keys.
private _editing = !isNull _focused && {ctrlType _focused == 2};

if (_key == DIK_ESCAPE && {call FUNC(closeMenu)}) exitWith {true};
if (_key == DIK_ESCAPE && {call FUNC(closeInspect)}) exitWith {true};

if (
    _key == DIK_ESCAPE && {!GVAR(dragging)} && {!(_typing && {GVAR(filter) isNotEqualTo ""})}
    && {GVAR(windowOrder) isNotEqualTo []}
    && {[GVAR(windowOrder) select -1] call FUNC(closeWindow)}
) exitWith {true};

// R turns what is being dragged a quarter round - not several tiles dragged together.
if (_key == DIK_R && {GVAR(dragging)}) exitWith {
    if (GVAR(dragGroup) isEqualTo []) then {
        [_display] call FUNC(rotateDrag);
    };

    true
};

// Typing in a field: the keys are the field's. In the search field Escape empties it first (and, empty,
// closes the window as ever); in another field it leaves it. Return is done: the cursor goes back to the
// sink, and the window that attached is told which field it was (the "submit" hook).
if (_editing) exitWith {
    switch (true) do {
        case (_typing && {_key == DIK_ESCAPE} && {GVAR(filter) isNotEqualTo ""}): {
            _filterEdit ctrlSetText "";
            GVAR(filter) = "";
            (_filterEdit getVariable [QGVAR(placeholder), controlNull]) ctrlShow true;
            call FUNC(applyFilter);
            true
        };
        case (!_typing && {_key == DIK_ESCAPE}): {
            ctrlSetFocus (uiNamespace getVariable [QGVAR(filterSink), controlNull]);
            true
        };
        case (_key in [DIK_RETURN, DIK_NUMPADENTER]): {
            ctrlSetFocus (uiNamespace getVariable [QGVAR(filterSink), controlNull]);
            ["submit", [_focused]] call FUNC(hook);
            true
        };
        default {
            // Escape in the empty search field closes the window, as anywhere else.
            if (_key == DIK_ESCAPE && {call FUNC(isInventoryMode)}) then {
                GVAR(closeReason) = "Escape";
            };

            false
        };
    };
};

// Moving while looting or searching: the soldier stops and walks off (einv_gui_moveToStop). A key that was
// held already when the window opened counts once it was let go and pressed again (KeyUp in fnc_open), and
// nothing counts in the first moment, while the press that opened the window may still be repeating. A
// movement key pressed with Ctrl or Alt is something else (Ctrl+A selects the section, and A is MoveLeft).
// Keyboard only: KeyDown gives DIK codes, and the combos, mouse and joystick bindings are left out. A movement
// key pressed with Ctrl or Alt counts as held until it is let go: its repeats, once Ctrl is up first, close
// nothing (Ctrl+A held a moment too long). Seated in a vehicle the keys close nothing: the soldier does not walk
// off, and a driver's W, S, A and D are the vehicle's - a tap meant for it closed the window he sat looking into.
if (_ctrl || _alt) then {
    private _action = GVAR(moveKeys) getOrDefault [_key, ""];

    if (_action isNotEqualTo "") then {
        GVAR(moveHeld) pushBackUnique _action;
    };
};

if (
    GVAR(moveToStop) && {!_ctrl} && {!_alt}
    && {!isNull GVAR(openedOn) || {GVAR(searchQueue) isNotEqualTo []}}
    && {isNull objectParent GVAR(unit)}
    && {call FUNC(isInventoryMode)}
    && {diag_tickTime - GVAR(openedAt) > MOVE_GRACE}
    && {
        private _action = GVAR(moveKeys) getOrDefault [_key, ""];

        _action isNotEqualTo "" && {!(_action in GVAR(moveHeld))}
    }
) exitWith {
    ["move"] call FUNC(closeDisplay);
    true
};

// The hotbar's keys inside this window (einv_hotbar): a key bound to a slot puts what the mouse is on there,
// G (or Delete) on a slot of the bar empties it.
if (
    !GVAR(dragging) && {call FUNC(isInventoryMode)} && {!isNil QEFUNC(hotbar,onWindowKey)}
    && {[_display, _key, _shift, _ctrl, _alt] call EFUNC(hotbar,onWindowKey)}
) exitWith {true};

// Selecting several (fnc_select): Escape lets go of the selection, Ctrl+A takes the whole section under
// the mouse, G (or Delete) drops what is selected. Not while something is dragged.
private _selecting = !GVAR(dragging) && {call FUNC(isInventoryMode)};

if (_selecting && {_key == DIK_ESCAPE} && {call FUNC(clearSelection)}) exitWith {true};

if (_selecting && {_key == DIK_A} && {_ctrl}) exitWith {
    // The section the mouse is over: the tile's, else the free cells of a grid.
    private _grids = uiNamespace getVariable [QGVAR(grids), []];
    private _mouse = getMousePosition;
    private _layer = [_mouse] call FUNC(topAt);
    private _holder = objNull;

    if ((GVAR(hover) param [0, ""]) isEqualTo "tile") then {
        _holder = (_grids param [GVAR(hover) select 1, createHashMap]) getOrDefault ["holder", objNull];
    } else {
        _holder = ((_grids select {
            (_x getOrDefault ["window", ""]) isEqualTo _layer && {([_x, _mouse] call FUNC(screenToCell)) isNotEqualTo []}
        }) param [0, createHashMap]) getOrDefault ["holder", objNull];
    };

    if (_holder isEqualType "" || {!isNull _holder}) then {
        [_holder] call FUNC(selectSection);
    };

    true
};

if (_selecting && {_key in [DIK_G, DIK_DELETE]} && {GVAR(selection) isNotEqualTo []}) exitWith {
    [call FUNC(selectionTiles), true] call FUNC(quickMoveGroup);
    true
};

// The window that attached gets the keys the engine would act on next (the "key" hook). True: taken.
if ((["key", [_display, _key, _shift, _ctrl, _alt], false] call FUNC(hook)) isEqualTo true) exitWith {true};

// G (in the inventory) or Delete drops what the mouse is on: a tile, or the item of a worn slot (as the
// slot's menu does, fnc_contextMenu; fnc_doUnequip says why not for a living person's).
if (_key == DIK_DELETE || {_key == DIK_G && {call FUNC(isInventoryMode)}}) exitWith {
    if (!GVAR(dragging)) then {
        switch (GVAR(hover) param [0, ""]) do {
            case "tile": {
                [GVAR(hover) select 1, GVAR(hover) select 2] call FUNC(dropToGround);
            };
            case "slot": {
                private _record = (uiNamespace getVariable [QGVAR(slots), []]) param [GVAR(hover) select 1, []];
                private _owner = _record param [6, objNull];
                private _slot = _record param [5, ""];

                if (
                    _record isNotEqualTo [] && {(_record param [7, -1]) < 0} && {_slot isNotEqualTo ""} && {!isNull _owner}
                    && {(_record param [1, ""]) isNotEqualTo ""}
                ) then {
                    [_owner, _slot, "ground", []] call FUNC(doUnequip);
                };
            };
        };
    };

    true
};

// Escape is left to the engine, which closes the dialog - told as the reason first (fnc_onUnload). Not on
// a display the window is a guest on: that one's own handlers decide what Escape does there.
if (_key == DIK_ESCAPE && {call FUNC(isInventoryMode)}) then {
    GVAR(closeReason) = "Escape";
};

if !(_key in actionKeys "Gear") exitWith {false};
if (diag_tickTime - GVAR(openedAt) < GEAR_KEY_GRACE) exitWith {true};

["the Gear key"] call FUNC(closeDisplay);
true
