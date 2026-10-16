#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A mouse button went down or up anywhere on the window. Down on a tile or a filled equipment slot
 * remembers the press - moving the mouse turns it into a drag (fnc_onFrame, fnc_startDrag). Down on an
 * empty cell of a column remembers the press as well: moved, it drags out a frame that selects the tiles
 * it touches (fnc_startBand). Up ends a drag (fnc_endDrag) or a frame (fnc_endBand), or, after a press
 * that never moved:
 *   a plain click - a tile is selected (fnc_select); on a tile of a selection of several it does nothing,
 *                   so that a double click can move them all; on an empty cell the selection is cleared
 *   Ctrl  - a tile is selected or not (fnc_select "toggle"), a slot's item comes off (fnc_quickUnequip)
 *   Shift - a stack is split: half of it goes onto the nearest free cell, as a stack of its own
 *           (fnc_splitStack - only where the storage keeps separate stacks); else a tile and all between it
 *           and the last one clicked are selected (fnc_select "range")
 *   a double click - a kit or a uniform, vest or backpack lying in a container opens, anything else
 *                    moves over (fnc_quickMove); a tile of a selection of several moves them all
 *                    (fnc_quickMoveGroup)
 * On the ground (a pile's grid, in the inventory) two of them work as Mia asked after 0.2.3: a double
 * click puts on what can be worn or carried in a slot of its own - uniform, vest, backpack, headgear, a
 * weapon, ... (fnc_quickEquip; magazines and attachments still move over) -, and Ctrl+click opens a
 * uniform, vest or backpack lying there (fnc_openNested) - anything else is selected as everywhere. The
 * hint names both while the mouse is on such a tile (fnc_updateHover).
 * The box of a uniform, vest or backpack opened from inside a container is pressed as its tile there
 * (fnc_boxTile): dragged, clicked and double clicked like the tile itself.
 * Shift held while pressing a stack drags half of it. Alt+click has no meaning of its own (it was the quick
 * equip before; putting on is a drag onto a slot, a double click on the ground and the menu's Equip).
 * A press on a filled slot of the hotbar strip (einv_hotbar) is a press of its own: moved, it becomes a drag
 * of the binding (fnc_startStripDrag - dropped on another slot it moves there, anywhere else it is
 * removed), let go in place it does nothing. A right click opens the item's context menu
 * (fnc_contextMenu) - with another menu open, beside it, it closes that one and opens the new one at once. Selecting works in the inventory only (fnc_isInventoryMode): where other windows
 * attach, Ctrl+click moves a tile over as before.
 *
 * A window that attached with hooks (fnc_attach) is asked first: "mouseDown" and "mouseUp" before the right
 * click (true: taken), and on a click that never became a drag "click" ["single" / "double", target, shift,
 * ctrl, alt] - target a HashMap with "type" ("tile", "slot", "cell" or "none"), "grid", "tile", "cell"
 * [col, row], "slot" (an index into the slots) and "source" (the grid's, or ""). So that it hears the
 * clicks on empty slots and free cells, those are recorded as presses with no tile; a tile of a source
 * grid (fnc_createGrid, "source") is pressed like one in a container. A Shift double click counts as a
 * double click there.
 *
 * An action waiting for the hands (fnc_queueMoves) has its circle on its tile or slot: a left press there
 * cancels it (fnc_cancelQueued) and starts no drag or click.
 *
 * While a repack of magazines runs (einv_magazines - only when that addon is loaded) the hands are busy: a
 * button going down anywhere stops it and does nothing else, and that button coming up is no click either.
 *
 * Added to the display and to every controls group of the window: which of them gets a click depends
 * on what lies under the mouse. The same click arriving twice in one frame counts once. What was
 * clicked comes from the mouse position (fnc_updateHover), never from the control that got the event,
 * and only what lies on top there gets it (fnc_topAt): the inspect card, then the kit windows, then the
 * columns. A press on a kit window that lies under another brings it to the top first
 * (fnc_raiseWindow) - not on its cross or its body's scroll bar -, and is then worked out on the window
 * drawn anew, its body scrolled as it was (fnc_gridOrigin); a left press on its title holds it to move
 * it (fnc_onFrame).
 *
 * A body's worn gear that shows as tiles stands for its slots.
 *
 * Arguments:
 * 0: Button went down <BOOL>
 * 1: The event's own arguments [control or display, button, x, y, shift, ctrl, alt] <ARRAY>
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * [true, _this] call einv_gui_fnc_onMouseButton;
 *
 * Public: No
 */

disableSerialization;

params ["_down", "_args"];
_args params ["", "_button", "", "", ["_shift", false], ["_ctrl", false], ["_alt", false]];

if !(_button in [0, 1]) exitWith {false};

private _stamp = [diag_frameNo, _down, _button];

if (_stamp isEqualTo GVAR(lastButton)) exitWith {false};

GVAR(lastButton) = _stamp;

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (isNull _display) exitWith {false};

// Repacking magazines (einv_magazines): a press anywhere stops it and does nothing else - nor does
// letting go of that button. The header's buttons keep their own click: Close during a repack stops it
// and closes.
if (_down && {!isNil QEFUNC(magazines,isBusy)} && {[] call EFUNC(magazines,isBusy)}) exitWith {
    GVAR(swallowUp) = _button;
    ["Stopped"] call EFUNC(magazines,stop);
    true
};

// A new press is a new click, whatever became of the release that was to be swallowed.
if (_down) then {
    GVAR(swallowUp) = -1;
};

if (!_down && {_button == GVAR(swallowUp)}) exitWith {
    GVAR(swallowUp) = -1;
    true
};

// A click beside the field being typed in ends typing in it - the keys are the window's again. The search
// field counts with its whole box; another field (a window that attached brings its own) with itself.
if (_down) then {
    private _edit = focusedCtrl _display;

    if (!isNull _edit && {ctrlType _edit == 2}) then {
        private _rect = if (_edit isEqualTo (uiNamespace getVariable [QGVAR(filterEdit), controlNull])) then {
            uiNamespace getVariable [QGVAR(filterRect), [0, 0, 0, 0]]
        } else {
            (ctrlPosition _edit) params ["_editX", "_editY", "_editW", "_editH"];
            ([createHashMapFromArray [["rel", [_editX, _editY]], ["parent", ctrlParentControlsGroup _edit]]] call FUNC(gridOrigin)) + [_editW, _editH]
        };

        _rect params ["_left", "_top", "_width", "_height"];
        getMousePosition params ["_mouseX", "_mouseY"];

        if !(_mouseX >= _left && {_mouseX < _left + _width} && {_mouseY >= _top} && {_mouseY < _top + _height}) then {
            ctrlSetFocus (uiNamespace getVariable [QGVAR(filterSink), controlNull]);
        };
    };
};

// The inspect card takes the clicks on it (fnc_drawInspect) - the inventory and the kit windows under it
// get none. A drag let go over it still ends, and what was held goes back (fnc_updateDrag finds no
// target there); a press let go there is no click.
getMousePosition params ["_clickX", "_clickY"];

private _layer = [[_clickX, _clickY]] call FUNC(topAt);

if (_layer isEqualTo "inspect") exitWith {
    if (!_down && {_button == 0}) then {
        if (GVAR(dragging)) then {
            GVAR(dragTarget) = [];
            [_display] call FUNC(endDrag);
        } else {
            GVAR(press) = [];
        };
    };

    false
};

// An open context menu takes the clicks itself (fnc_openMenu) - except a right press beside it: that one
// closes the menu and goes on as the right click it is, so the menu of the tile under the mouse opens in
// the same go (on empty space nothing opens, and the menu is just closed). The menu's own rows keep it.
private _menuOpen = (uiNamespace getVariable [QGVAR(menu), []]) isNotEqualTo [];

if (_menuOpen && {_down} && {_button == 1}) then {
    (uiNamespace getVariable [QGVAR(menuRect), [0, 0, 0, 0]]) params ["_menuX", "_menuY", "_menuW", "_menuH"];

    private _onMenu = _clickX >= _menuX && {_clickX < _menuX + _menuW} && {_clickY >= _menuY} && {_clickY < _menuY + _menuH};

    if (!_onMenu) then {
        call FUNC(closeMenu);
        _menuOpen = false;
    };
};

if (_menuOpen) exitWith {false};

// A window that attached may take the button first - the Arsenal panel takes every press outside its own, so the
// engine ignores it.
private _taken = if (_down) then {
    ["mouseDown", [_button, [_clickX, _clickY], _shift, _ctrl, _alt], false] call FUNC(hook)
} else {
    ["mouseUp", [_button, [_clickX, _clickY], _shift, _ctrl, _alt], false] call FUNC(hook)
};

if (_taken isEqualTo true) exitWith {true};

// Pressed on a kit window: on its cross, the cross closes it (fnc_drawWindow) and nothing happens here,
// nor on its Take all and Sort, whose own clicks they are (a raise would draw them anew under the mouse and
// the click would be lost), nor on its body's scroll bar. Anywhere else it comes to the top first - a right
// click's menu then opens over it, a tile pressed there is the raised window's -, and a left press on its
// title holds it to move it.
private _onWindow = "";

if (_down && {_layer isNotEqualTo ""} && {!GVAR(dragging)}) then {
    private _windows = uiNamespace getVariable [QGVAR(windows), []];
    private _index = _windows findIf {(_x getOrDefault ["key", ""]) isEqualTo _layer};

    if (_index < 0) exitWith {};

    private _record = _windows select _index;

    (_record getOrDefault ["rect", [0, 0, 0, 0]]) params ["_windowX", "_windowY"];

    private _inX = _clickX - _windowX;
    private _inY = _clickY - _windowY;

    private _fnc_inside = {
        params ["_rect"];
        _rect params [["_rectX", 0], ["_rectY", 0], ["_rectW", 0], ["_rectH", 0]];

        _inX >= _rectX && {_inX < _rectX + _rectW} && {_inY >= _rectY} && {_inY < _rectY + _rectH}
    };

    if ([_record getOrDefault ["close", []]] call _fnc_inside) exitWith {
        _onWindow = "close";
    };

    if ((_record getOrDefault ["buttons", []]) findIf {[_x] call _fnc_inside} >= 0) exitWith {
        _onWindow = "button";
    };

    // On its body's scroll bar it stays where it lies: that bar is the engine's, and the body drawn anew
    // by a raise would take it away under the mouse - its drag would end before it began.
    private _body = _record getOrDefault ["body", controlNull];

    if (!isNull _body) then {
        (ctrlPosition _body) params ["_bodyX", "_bodyY", "_bodyW", "_bodyH"];

        private _bar = [_bodyX + _bodyW - SCROLL_W, _bodyY, SCROLL_W, _bodyH];

        if ((_body getVariable [QGVAR(contentH), _bodyH]) > _bodyH && {[_bar] call _fnc_inside}) then {
            _onWindow = "scrollbar";
        };
    };

    if (_onWindow isNotEqualTo "") exitWith {};

    [_layer] call FUNC(raiseWindow);

    if (_button == 0 && {[_record getOrDefault ["title", []]] call _fnc_inside}) then {
        GVAR(press) = [];
        GVAR(windowMove) = [_layer, _inX, _inY];
        _onWindow = "title";
    };
};

if (_onWindow in ["close", "button", "scrollbar"]) exitWith {false};
if (_onWindow isEqualTo "title") exitWith {true};

// Right click: the choices for what the mouse is on (fnc_contextMenu).
if (_button == 1) exitWith {
    if (_down && {!GVAR(dragging)}) then {
        GVAR(press) = [];
        [_display] call FUNC(contextMenu);
    };

    true
};

if (_down) exitWith {
    GVAR(press) = [];

    private _mouse = getMousePosition;
    [_display, _mouse, true] call FUNC(updateHover);

    // Only a window that attached wants to hear every click: what was pressed on is kept with the press, as
    // the target its "click" hook is told (see above).
    private _listening = "click" in GVAR(hooks);

    private _fnc_target = {
        params ["_type", ["_gridIndex", -1], ["_tileIndex", -1], ["_cell", []], ["_slotIndex", -1], ["_source", ""]];

        createHashMapFromArray [
            ["type", _type], ["grid", _gridIndex], ["tile", _tileIndex], ["cell", _cell], ["slot", _slotIndex], ["source", _source]
        ]
    };

    switch (GVAR(hover) param [0, ""]) do {
        case "tile": {
            GVAR(hover) params ["", "_gridIndex", "_tileIndex"];

            private _grid = (uiNamespace getVariable [QGVAR(grids), []]) select _gridIndex;
            private _tile = (_grid get "tiles") select _tileIndex;

            if (_tile getOrDefault ["hidden", false]) exitWith {};

            // An action waiting for the hands (fnc_queueMoves): a click on its tile cancels it.
            if ((_tile getOrDefault ["queued", 0]) > 0) exitWith {
                [_tile get "queued"] call FUNC(cancelQueued);
            };

            // A tile of a source grid (ACE's list in the Arsenal panel) is lifted like one in a container, though no
            // container stands behind it: it brings the cell it is held by itself.
            if ((_grid getOrDefault ["source", ""]) isNotEqualTo "") exitWith {
                GVAR(press) = [_gridIndex, _tileIndex, _mouse, _tile getOrDefault ["grab", [0, 0]], _ctrl, [], _alt, _shift];

                if (_listening) then {
                    GVAR(press) pushBack (["tile", _gridIndex, _tileIndex, [_grid, _mouse] call FUNC(screenToCell), -1, _grid get "source"] call _fnc_target);
                };
            };

            if (_grid getOrDefault ["virtual", true]) exitWith {
                private _slot = _tile getOrDefault ["slot", ""];
                private _unit = _grid getOrDefault ["unit", objNull];

                if (_slot isNotEqualTo "" && {!isNull _unit}) then {
                    GVAR(press) = [-1, -1, _mouse, [0, 0], _ctrl, [_unit, _slot], _alt];

                    if (_listening) then {
                        GVAR(press) append [_shift, ["tile", _gridIndex, _tileIndex] call _fnc_target];
                    };
                };
            };

            // A grid with no container takes nothing out - but for the contents of an open kit's window
            // (einv_compat_efak), which has its own way out.
            if (isNull (_grid getOrDefault ["container", objNull]) && {(_grid getOrDefault ["kit", ""]) isEqualTo ""}) exitWith {};

            private _cell = [_grid, _mouse] call FUNC(screenToCell);

            if (_cell isEqualTo []) exitWith {};

            GVAR(press) = [
                _gridIndex,
                _tileIndex,
                _mouse,
                [(_cell select 0) - (_tile get "col"), (_cell select 1) - (_tile get "row")],
                _ctrl,
                [],
                _alt,
                _shift
            ];

            if (_listening) then {
                GVAR(press) pushBack (["tile", _gridIndex, _tileIndex, _cell] call _fnc_target);
            };
        };
        case "slot": {
            private _slotIndex = GVAR(hover) select 1;
            private _record = (uiNamespace getVariable [QGVAR(slots), []]) select _slotIndex;
            private _slot = _record param [5, ""];
            private _unit = _record param [6, objNull];

            // The box of a uniform, vest or backpack opened from inside a container: pressed as its tile there
            // (fnc_boxTile), so the drag is the tile's own. Held by its middle cell - the ghost comes out
            // centred on the mouse rather than hanging from its corner.
            private _asTile = [_record param [8, objNull]] call FUNC(boxTile);

            if (_asTile isNotEqualTo []) exitWith {
                _asTile params ["_gridIndex", "_tileIndex"];

                private _tile = (((uiNamespace getVariable [QGVAR(grids), []]) select _gridIndex) get "tiles") select _tileIndex;

                // Waiting for the hands (fnc_queueMoves): a click cancels it.
                if ((_tile getOrDefault ["queued", 0]) > 0) exitWith {
                    [_tile get "queued"] call FUNC(cancelQueued);
                };

                GVAR(press) = [
                    _gridIndex, _tileIndex, _mouse,
                    [floor ((_tile getOrDefault ["w", 1]) / 2), floor ((_tile getOrDefault ["h", 1]) / 2)],
                    _ctrl, [], _alt, _shift
                ];
            };

            // A filled slot of the hotbar strip (einv_hotbar): its binding is dragged, not an item (fnc_startStripDrag).
            // The press carries the slot's number as its tenth element. An empty one has nothing to lift.
            if ((_record param [7, -1]) >= 0) exitWith {
                if ((_record param [1, ""]) isNotEqualTo "" && {call FUNC(isInventoryMode)}) then {
                    GVAR(press) = [-1, -1, _mouse, [0, 0], _ctrl, [], _alt, _shift, createHashMap, _record select 7];
                };
            };

            if (_slot isEqualTo "" || {isNull _unit}) exitWith {};

            // An empty slot cannot be lifted, but a window that attached hears the click on it.
            if ((_record param [1, ""]) isEqualTo "") exitWith {
                if (_listening) then {
                    GVAR(press) = [-1, -1, _mouse, [0, 0], _ctrl, [], _alt, _shift, ["slot", -1, -1, [], _slotIndex] call _fnc_target];
                };
            };

            // Its item waits to be taken off (fnc_queueMoves): a click cancels that.
            private _queuedId = [_unit, _slot] call FUNC(queuedSlot);

            if (_queuedId > 0) exitWith {
                [_queuedId] call FUNC(cancelQueued);
            };

            GVAR(press) = [-1, -1, _mouse, [0, 0], _ctrl, [_unit, _slot], _alt];

            if (_listening) then {
                GVAR(press) append [_shift, ["slot", -1, -1, [], _slotIndex] call _fnc_target];
            };
        };
        default {
            // A window that attached hears the clicks on a free cell of a grid and on nothing at all too.
            if (_listening && {_layer isEqualTo ""}) exitWith {
                private _cell = [];
                private _gridIndex = (uiNamespace getVariable [QGVAR(grids), []]) findIf {
                    !(_x getOrDefault ["virtual", true]) && {!(_x getOrDefault ["overflow", false])}
                    && {(_x getOrDefault ["window", ""]) isEqualTo ""}
                    && {
                        _cell = [_x, _mouse] call FUNC(screenToCell);
                        _cell isNotEqualTo []
                    }
                };

                private _target = if (_gridIndex >= 0) then {
                    ["cell", _gridIndex, -1, _cell] call _fnc_target
                } else {
                    ["none"] call _fnc_target
                };

                GVAR(press) = [_gridIndex, -1, _mouse, [0, 0], _ctrl, [], _alt, _shift, _target];
            };

            // An empty cell of a column (not under a kit window, which has no frame to drag out): the press
            // may become a frame that selects, or a click that deselects.
            if (_layer isNotEqualTo "" || {!(call FUNC(isInventoryMode))}) exitWith {};

            private _cell = [];
            private _gridIndex = (uiNamespace getVariable [QGVAR(grids), []]) findIf {
                !(_x getOrDefault ["virtual", true]) && {!(_x getOrDefault ["overflow", false])}
                && {(_x getOrDefault ["window", ""]) isEqualTo ""} && {(_x getOrDefault ["side", ""]) isNotEqualTo ""}
                && {
                    _cell = [_x, _mouse] call FUNC(screenToCell);
                    _cell isNotEqualTo []
                }
            };

            if (_gridIndex < 0) exitWith {};

            private _grid = (uiNamespace getVariable [QGVAR(grids), []]) select _gridIndex;

            if (([_grid, _cell] call FUNC(tileAt)) >= 0) exitWith {};

            private _column = _grid getOrDefault ["parent", controlNull];

            if (isNull _column) exitWith {};

            GVAR(bandPress) = [_column, _mouse, [_column] call FUNC(scrollPixels), _ctrl, _grid get "side"];
        };
    };

    false
};

if (GVAR(dragging)) exitWith {
    [_display] call FUNC(endDrag);
    true
};

// A hotbar slot's binding dragged out: moved onto another slot, or removed (fnc_endStripDrag).
if (GVAR(stripDrag) isNotEqualTo []) exitWith {
    [_display] call FUNC(endStripDrag);
    true
};

// A frame dragged out from an empty cell comes up: the tiles it touched are the selection.
if (GVAR(band)) exitWith {
    [_display] call FUNC(endBand);
    true
};

// A press on an empty cell that never moved is a click on it: the selection goes, unless Ctrl is held.
if (GVAR(bandPress) isNotEqualTo []) exitWith {
    private _ctrlAtBandPress = GVAR(bandPress) select 3;

    GVAR(bandPress) = [];

    if (!_ctrl && {!_ctrlAtBandPress}) then {
        call FUNC(clearSelection);
    };

    true
};

if (GVAR(press) isEqualTo []) exitWith {false};

GVAR(press) params ["_gridIndex", "_tileIndex", "", "", "_ctrlAtPress", "_slotSource", "_altAtPress", ["_shiftAtPress", false], ["_target", createHashMap]];
GVAR(press) = [];

// A double click is two plain clicks on the same tile. Only a plain click can be the first of one, and
// a double click is the first of none: the window is built again after it, and the next click would
// find another item at the same place. A window that attached counts Shift as plain (its Shift+double
// click is a gesture), and tells clicks that hit no tile apart by what they hit (a free cell, a slot, the
// middle).
private _now = diag_tickTime;
private _listening = "click" in GVAR(hooks);
private _plain = _slotSource isEqualTo [] && {!_ctrl} && {!_ctrlAtPress} && {!_alt} && {!_altAtPress} && {_listening || {!_shift}};
private _clickKey = [_gridIndex, _tileIndex];

if (_tileIndex < 0 && {_listening}) then {
    _clickKey append [_target getOrDefault ["type", ""], _target getOrDefault ["slot", -1], _target getOrDefault ["cell", []]];
};

private _double = _plain && {_clickKey isEqualTo (GVAR(lastClick) select 0)} && {_now - (GVAR(lastClick) select 1) < DOUBLE_CLICK};

GVAR(lastClick) = [[_clickKey, []] select (_double || {!_plain}), _now];

// The window that attached has the first word on a click that never became a drag: what it did with it
// is the whole answer.
private _answer = if (_listening) then {
    ["click", [["single", "double"] select _double, _target, _shift || _shiftAtPress, _ctrl || _ctrlAtPress, _alt || _altAtPress], false] call FUNC(hook)
} else {
    false
};

if (_answer isEqualTo true) exitWith {true};

// A click on a free cell, an empty slot or nothing was recorded only for the window that attached (above):
// there is nothing here for the inventory's own handling to work on.
if (_tileIndex < 0 && {_slotSource isEqualTo []}) exitWith {true};

// What the ground does with a double click and a Ctrl+click (see the header): only in the inventory, only
// on a pile's grid, only on a searched tile that is not under way.
private _fnc_groundTile = {
    params ["_gridIndex", "_tileIndex"];

    private _grid = (uiNamespace getVariable [QGVAR(grids), []]) param [_gridIndex, createHashMap];
    private _tile = (_grid getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];

    if (
        count _tile == 0 || {!([] call FUNC(isInventoryMode))} || {_grid getOrDefault ["virtual", true]}
        || {_tile getOrDefault ["hidden", false]} || {_tile getOrDefault ["pending", false]}
        || {!([_grid getOrDefault ["container", objNull]] call EFUNC(storage,isGroundHolder))}
    ) exitWith {createHashMap};

    _tile
};

private _fnc_groundOpen = {
    private _tile = _this call _fnc_groundTile;

    count _tile > 0 && {!isNull (_tile getOrDefault ["container", objNull])}
};

// A double click does what the quick move key does (fnc_quickAction).
if (_double) exitWith {
    [_gridIndex, _tileIndex] call FUNC(quickAction);

    true
};

switch (true) do {
    case (_ctrl || {_ctrlAtPress}): {
        if (_slotSource isNotEqualTo []) then {
            _slotSource call FUNC(quickUnequip);
        } else {
            // Selecting in the inventory; a window that attaches to this one (the Arsenal) keeps Ctrl+click
            // as the quick move.
            if (call FUNC(isInventoryMode)) then {
                // On the ground a uniform, vest or backpack opens; anything else is selected.
                if ([_gridIndex, _tileIndex] call _fnc_groundOpen) exitWith {
                    [_gridIndex, _tileIndex] call FUNC(openNested);
                };

                [_gridIndex, _tileIndex, "toggle"] call FUNC(select);
            } else {
                [_gridIndex, _tileIndex] call FUNC(quickMove);
            };
        };
    };
    case (_slotSource isEqualTo [] && {call FUNC(isInventoryMode)}): {
        // Shift: a stack is split where the storage keeps stacks apart (fnc_splitStack); else from the last
        // tile clicked to this one. A plain click selects this one - but not when it is one of several
        // selected: a double click on it moves them all (above).
        if (_shift) then {
            if !([_gridIndex, _tileIndex] call FUNC(splitStack)) then {
                [_gridIndex, _tileIndex, "range"] call FUNC(select);
            };
        } else {
            private _selected = call FUNC(selectionTiles);

            if (count _selected < 2 || {!([_gridIndex, _tileIndex] in _selected)}) then {
                [_gridIndex, _tileIndex, "only"] call FUNC(select);
            };
        };
    };
};

true
