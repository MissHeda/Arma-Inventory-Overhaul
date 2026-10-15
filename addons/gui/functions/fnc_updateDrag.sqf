#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Follows the mouse while something is dragged: moves the ghost and finds where it would land.
 *
 * On one of the player's own equipment slots (only a tile can go there): it fits when the slot takes
 * that item (einv_storage_fnc_slotAccepts) - on a weapon also a magazine or attachment it takes, which
 * goes on that part (einv_storage_fnc_partFor). Anywhere else over the equipment column it goes into
 * the slot that takes it (einv_storage_fnc_slotFor). Worn gear dragged from a slot onto the same slot of
 * another unit - the player's onto a body's, a body's onto the player's or anywhere over the player's
 * equipment column - is exchanged (fnc_canSwap); the target then names that unit as its 9th element. A
 * uniform, vest or backpack let go on the storage column off its grids (GVAR(storageRect)) goes into that
 * slot as on the slot itself, the footprint faint over the column; wearing none of the three, the column
 * shows only its placeholder and anything else is red there, "NoFit". On a grid: the cells it would cover - the grabbed cell
 * stays under the mouse - must lie inside the compartment and be free, and another container must be
 * able to carry it - and a living person's container has to be one the player may put into
 * (fnc_checkTouch). The footprint shows the answer, green or red. Outside every panel it goes on the
 * ground; over the inspect card it goes nowhere - let go there, it goes back.
 *
 * A uniform, vest or backpack never goes into its own grid or into that of anything lying in it
 * (einv_storage_fnc_liesIn): red, "It cannot go into itself". The cells a move under way goes to
 * (GVAR(inFlight)) count as taken - empty until it arrived, but not for long.
 *
 * Only what lies on top under the mouse is a target (fnc_topAt): over a kit window only that window's
 * grids and the kit tiles in them - no slot, no column's grid and not the ground under it; over the
 * window's title or edge it goes back.
 *
 * Kits of Enhanced First Aid Kits (einv_compat_efak, when loaded): on a kit's tile it goes into that
 * kit, the footprint on the tile; on an open kit window's grid a taken cell is no reason not to for what comes
 * from elsewhere - the kit's layout finds it another. Either way the kit decides whether it takes it
 * (einv_compat_efak_fnc_canDrop), and the red footprint says why not. Moved within one kit, or onto the
 * tile of the kit it comes out of, it is a grid like any other: a taken cell is no room.
 *
 * A magazine over a partly filled one of its kind (einv_magazines, when loaded): the footprint lies on
 * that tile in the accent colour - the two would be repacked (einv_magazines_fnc_canRepack); red, with the
 * reason, when they cannot be (a full one, the player's gear and a crate). Anything that is no repack goes on
 * as it did.
 *
 * Several tiles dragged together (GVAR(dragGroup), fnc_groupMode): over a grid they keep their
 * arrangement when it fits there (one green footprint per tile, every picture at its offset from the
 * mouse), else they are packed into the hovered container (an outline round the compartment: green when
 * all fit, amber when some do, red when none, "4 / 6" on the counter), over a kit the kit decides, over
 * a dragged container or one that lies in it, or a slot, nothing happens (red, and the reason). The
 * hotbar's slots take a single item only (einv_hotbar - only when that addon is loaded).
 *
 * Free cells are the only room there is: a cell that is taken is red, and weight refuses nothing (a backpack
 * into a backpack is the one kind rule left, einv_storage_fnc_backpackIntoBackpack). When the item comes
 * from outside the soldier's own gear into it, the hint warns what it would make of him: "+2.4 kg: you
 * will be Overloaded" (fnc_dragHint, fnc_weightText; an own empty slot too - a swap moves another item off,
 * so no forecast for a filled one), worked out once per drag, target and count (GVAR(dragRoom)). Anything
 * else the target has nothing to say about, the hint is the key help lift wrote. The ghost is held as GVAR(dragSize) says - turned with R - with the
 * count of a stack beside it; at a column's or a kit window body's top or bottom edge it scrolls - only
 * while nothing lies over it there.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Mouse position [x, y] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, getMousePosition] call einv_gui_fnc_updateDrag;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_mouse"];
_mouse params ["_mouseX", "_mouseY"];

GVAR(press) params ["_sourceIndex", "_tileIndex", "", "_grab", "", "_slotSource"];
_grab params ["_grabCol", "_grabRow"];

private _entry = uiNamespace getVariable [QGVAR(dragEntry), createHashMap];

if (count _entry == 0) exitWith {};

// As it is held - turned with R (fnc_rotateDrag).
GVAR(dragSize) params ["_w", "_h"];

(call FUNC(getCell)) params ["_cellW", "_cellH"];

// The middle button takes all of a stack - pressed, not held. Its click reaches the game rather than
// the window while dragging, so it is read here. Several tiles go whole, with no wheel and no middle button.
private _dragGroup = GVAR(dragGroup);
private _stack = [_entry getOrDefault ["count", 1], 1] select (_dragGroup isNotEqualTo []);
private _middle = inputMouse 2 > 0;

if (_middle && {!GVAR(middleHeld)} && {_stack > 1}) then {
    GVAR(dragCount) = _stack;

    [_display, _entry, GVAR(dragCount), false] call FUNC(previewWeight);
};

GVAR(middleHeld) = _middle;

// The ghost, its grabbed cell under the mouse, and the count at its bottom right corner.
private _boxX = _mouseX - (_grabCol + 0.5) * _cellW;
private _boxY = _mouseY - (_grabRow + 0.5) * _cellH;

(uiNamespace getVariable [QGVAR(dragGhostOffset), [0, 0]]) params ["_offsetX", "_offsetY"];

private _ghost = uiNamespace getVariable [QGVAR(dragGhost), controlNull];
_ghost ctrlSetPosition [_boxX + _offsetX, _boxY + _offsetY];
_ghost ctrlCommit 0;

if (uiNamespace getVariable [QGVAR(dragTurned), false]) then {
    _ghost ctrlSetAngle [90, 0.5, 0.5];
};

private _counter = uiNamespace getVariable [QGVAR(dragCounter), controlNull];

if (!isNull _counter) then {
    (ctrlPosition _counter) params ["", "", "_counterW", "_counterH"];

    // A group counts its tiles; over a container that cannot take all of them the grid below says how
    // many fit.
    _counter ctrlSetText ([format ["%1 / %2", GVAR(dragCount), _stack], format ["×%1", count _dragGroup]] select (_dragGroup isNotEqualTo []));
    _counter ctrlSetPosition [_boxX + _w * _cellW - _counterW, _boxY + _h * _cellH + pixelH * 3];
    _counter ctrlCommit 0;
};

// A group's extra footprints and pictures are shown only where they mean something, below.
if (_dragGroup isNotEqualTo []) then {
    {_x ctrlShow false} forEach (uiNamespace getVariable [QGVAR(dragFootprints), []]);
    {(_x select 0) ctrlShow false} forEach (uiNamespace getVariable [QGVAR(dragGhosts), []]);
};

// What lies on top under the mouse (fnc_topAt): "inspect", a kit window's key, or "" for the columns.
private _onTop = [_mouse] call FUNC(topAt);

// The columns and the kit windows' bodies: held where they stood while the wheel counts a stack
// (fnc_onMouseZ); at the top or bottom edge of one that lies on top there they scroll, whatever is held.
// A body lies in its window: its place on the screen comes through it (fnc_gridOrigin).
private _band = _cellH * 0.6;

{
    _x params ["_group", "_value", ["_layer", ""]];

    if (isNull _group) then {continue};

    (ctrlPosition _group) params ["_groupRelX", "_groupRelY", "_groupW", "_groupH"];
    ([createHashMapFromArray [["rel", [_groupRelX, _groupRelY]], ["parent", ctrlParentControlsGroup _group]]] call FUNC(gridOrigin)) params ["_groupX", "_groupY"];

    private _range = (_group getVariable [QGVAR(contentH), _groupH]) - _groupH;

    if (_range <= 0) then {continue};

    private _now = ((ctrlScrollValues _group) select 0) max 0;
    private _want = [_now, _value] select (_stack > 1);

    if (_layer isEqualTo _onTop && {_mouseX >= _groupX} && {_mouseX < _groupX + _groupW}) then {
        private _step = _cellH * 10 * diag_deltaTime / _range;

        if (_mouseY >= _groupY && {_mouseY < _groupY + _band}) then {
            _want = (_want - _step) max 0;
        };

        if (_mouseY > _groupY + _groupH - _band && {_mouseY <= _groupY + _groupH}) then {
            _want = (_want + _step) min 1;
        };
    };

    if (abs (_want - _now) > 0.00001) then {
        _group ctrlSetScrollValues [_want, -1];
    };

    _x set [1, _want];
} forEach (uiNamespace getVariable [QGVAR(dragScroll), []]);

private _footprint = uiNamespace getVariable [QGVAR(dragFootprint), controlNull];
private _grids = uiNamespace getVariable [QGVAR(grids), []];

// A shaped item (size=xx/x-) shows its footprint on a grid on its own cells only (fnc_shapeRects), in
// controls made with the drag so they lie under the ghost (fnc_startDrag). Hidden here every frame and
// shown again below where they mean something; turned with R, the shape turns with it.
private _shapes = uiNamespace getVariable [QGVAR(dragShapes), []];
private _shapeUsed = 0;
private _dragHoles = ([_entry getOrDefault ["class", ""], GVAR(dragRot)] call EFUNC(items,footprintAs)) select 2;

{_x ctrlShow false} forEach _shapes;

// Paints the next free shape controls: false when too few are left, and the caller draws the box. On a
// canvas's compartment it is drawn in where the cells under it are (fnc_spanInsets); _origin is the
// corner drawn in (fnc_spanRect).
private _fnc_paintShape = {
    params ["_origin", "_shape", "_color", ["_insets", [0, 0, 0, 0]]];

    private _rects = [_origin, _cellW, _cellH, _shape, "surface", 0, _insets] call FUNC(shapeRects);

    if (_shapeUsed + count _rects > count _shapes) exitWith {false};

    {
        private _control = _shapes select _shapeUsed;

        _shapeUsed = _shapeUsed + 1;
        _control ctrlSetPosition _x;
        _control ctrlSetBackgroundColor [_color select 0, _color select 1, _color select 2, DRAG_FOOTPRINT_ALPHA];
        _control ctrlCommit 0;
        _control ctrlShow true;
    } forEach _rects;

    true
};

private _fnc_show = {
    params ["_rect", "_fits", ["_alpha", DRAG_FOOTPRINT_ALPHA], ["_colorKey", ""]];

    {_x ctrlShow false} forEach _shapes;

    private _color = if (_fits) then {
        GVAR(theme) getOrDefault ["gain", [0.298, 0.765, 0.541, 1]]
    } else {
        GVAR(theme) getOrDefault ["loss", [0.941, 0.333, 0.353, 1]]
    };

    // A zone may name its own colour (the Arsenal panel's remove zone is drawn in the loss colour whatever fits).
    if (_colorKey isNotEqualTo "" && {_colorKey in GVAR(theme)}) then {
        _color = GVAR(theme) get _colorKey;
    };

    _footprint ctrlSetPosition _rect;
    _footprint ctrlSetBackgroundColor [_color select 0, _color select 1, _color select 2, _alpha];
    _footprint ctrlCommit 0;
    _footprint ctrlShow true;
};

// Over the inspect card nothing under it is a target (fnc_drawInspect): let go there, it goes back.
if (_onTop isEqualTo "inspect") exitWith {
    _footprint ctrlShow false;
    GVAR(dragTarget) = [];
};

// What the hint says about the target, [[text, colour key], ...] - the key help unless the target has something
// to say about weight (fnc_dragHint).
private _hintParts = GVAR(dragKeys);

// What a pick-up would make of the soldier, [] when it changes nothing about his tier or does not come from
// outside his own gear (fnc_previewWeight knows where it came from).
private _fnc_forecast = {
    params ["_need"];

    if !(uiNamespace getVariable [QGVAR(dragExternal), false]) exitWith {[]};

    private _load = [GVAR(unit)] call EFUNC(weight,getLoad);
    private _tier = [GVAR(unit), _load] call EFUNC(weight,getTier);
    private _newTier = [GVAR(unit), _load + _need] call EFUNC(weight,getTier);

    if (_newTier <= _tier) exitWith {[]};

    [[[_need, _newTier, _load + _need] call FUNC(weightText), ["text2", "accent", "loss", "loss"] select _newTier]]
};

// Where it would land: the first that applies - the hotbar, one of the player's slots, a grid (and a kit's tile
// in it), a zone, the ground. A block of its own, so that the window that attached can look at the answer
// whichever way it was reached (below).
call {
    // ----- On the hotbar (einv_hotbar): nothing moves, the item's class goes on that key -----
    // Its slots are drawn in the equipment column as slots without a place of their own (record element 7 is
    // the key's number). Only one item at a time, and only while that addon is loaded.
    private _hotbarSlot = -1;

    if (_dragGroup isEqualTo [] && {_onTop isEqualTo ""} && {call FUNC(isInventoryMode)} && {!isNil QEFUNC(hotbar,canBindFrom)}) then {
        _hotbarSlot = (uiNamespace getVariable [QGVAR(slots), []]) findIf {
            (_x param [7, -1]) >= 0 && {
                ([_x] call FUNC(slotRect)) params [["_left", 0], ["_top", 0], ["_width", 0], ["_height", 0]];
                _mouseX >= _left && {_mouseX < _left + _width} && {_mouseY >= _top} && {_mouseY < _top + _height}
            }
        };
    };

    if (_hotbarSlot >= 0) exitWith {
        private _record = (uiNamespace getVariable [QGVAR(slots), []]) select _hotbarSlot;
        private _from = if (_slotSource isEqualTo []) then {["grid", _grids select _sourceIndex]} else {["slot", _slotSource]};

        ([_entry get "class", _from] call EFUNC(hotbar,canBindFrom)) params ["_fits", "_why"];

        GVAR(dragTarget) = ["hotbar", _record select 7, 0, 0, _fits, _why];
        [[_record] call FUNC(slotRect), _fits] call _fnc_show;
    };

    // ----- On one of the player's own slots -----
    // Where it shows now (fnc_slotRect): the uniform, vest and backpack boxes lie in a scrolling column.
    // Never under a kit window.
    if (_slotSource isEqualTo [] && {_onTop isEqualTo ""}) then {
        private _slots = uiNamespace getVariable [QGVAR(slots), []];
        private _slotIndex = _slots findIf {
            (_x param [5, ""]) isNotEqualTo ""
            && {(_x param [6, objNull]) isEqualTo GVAR(unit)}
            && {
                ([_x] call FUNC(slotRect)) params [["_left", 0], ["_top", 0], ["_width", 0], ["_height", 0]];
                _mouseX >= _left && {_mouseX < _left + _width} && {_mouseY >= _top} && {_mouseY < _top + _height}
            }
        };

        if (_slotIndex < 0) exitWith {};

        private _record = _slots select _slotIndex;
        private _slot = _record select 5;
        private _fits = [GVAR(unit), _slot, _entry get "class"] call EFUNC(storage,slotAccepts);

        // Several items cannot go into one slot.
        if (_dragGroup isNotEqualTo []) then {
            _fits = false;
        };

        // A magazine or attachment on the weapon itself goes on the part that takes it - loaded at once.
        if (!_fits && {_dragGroup isEqualTo []} && {_slot in ["primary", "handgun", "launcher"]}) then {
            private _part = [GVAR(unit), _slot, _entry get "class"] call EFUNC(storage,partFor);

            if (_part isNotEqualTo "") then {
                _slot = _part;
                _fits = true;
            };
        };

        GVAR(dragTarget) = ["slot", _slotIndex, 0, 0, _fits, [["NoFit", "GroupNoSlot"] select (_dragGroup isNotEqualTo []), ""] select _fits, _slot];
        [[_record] call FUNC(slotRect), _fits] call _fnc_show;

        // An empty slot takes the whole of it onto the soldier.
        if (_fits && {(_record select 1) isEqualTo ""} && {_dragGroup isEqualTo []}) then {
            _hintParts = [([[_entry]] call EFUNC(storage,getMass)) / ((_entry getOrDefault ["count", 1]) max 1)] call _fnc_forecast;

            if (_hintParts isEqualTo []) then {
                _hintParts = GVAR(dragKeys);
            };
        };
    };

    // ----- Worn gear onto another unit's slot: exchanged (fnc_canSwap, fnc_doSwap) -----
    // A slot's item - the player's own or a body's - over the same slot of the other: the player's
    // backpack onto a body's backpack slot, a body's vest onto the player's vest box.
    if (_slotSource isNotEqualTo [] && {_onTop isEqualTo ""} && {_dragGroup isEqualTo []} && {[] call FUNC(isInventoryMode)}) then {
        private _slots = uiNamespace getVariable [QGVAR(slots), []];
        private _slotIndex = _slots findIf {
            (_x param [5, ""]) isNotEqualTo "" && {(_x param [7, -1]) < 0}
            && {!isNull (_x param [6, objNull])} && {(_x param [6, objNull]) isNotEqualTo (_slotSource select 0)}
            && {
                ([_x] call FUNC(slotRect)) params [["_left", 0], ["_top", 0], ["_width", 0], ["_height", 0]];
                _mouseX >= _left && {_mouseX < _left + _width} && {_mouseY >= _top} && {_mouseY < _top + _height}
            }
        };

        if (_slotIndex < 0) exitWith {};

        private _record = _slots select _slotIndex;
        private _toUnit = _record select 6;
        private _toSlot = _record select 5;
        private _key = format ["swap|%1", _slotIndex];
        private _why = GVAR(dragRoom) get _key;

        if (isNil "_why") then {
            _why = [_slotSource, _toUnit, _toSlot] call FUNC(canSwap);
            GVAR(dragRoom) set [_key, _why];
        };

        GVAR(dragTarget) = ["slot", _slotIndex, 0, 0, _why isEqualTo "", _why, _toSlot, true, _toUnit];
        [[_record] call FUNC(slotRect), _why isEqualTo ""] call _fnc_show;
    };

    // Over the player's equipment column (fnc_layoutGlass), in the inventory.
    private _inArea = _onTop isEqualTo "" && {_dragGroup isEqualTo []} && {[] call FUNC(isInventoryMode)} && {
        GVAR(equipmentRect) params [["_areaX", 0], ["_areaY", 0], ["_areaW", 0], ["_areaH", 0]];
        _mouseX >= _areaX && {_mouseX < _areaX + _areaW} && {_mouseY >= _areaY} && {_mouseY < _areaY + _areaH}
    };

    if ((GVAR(dragTarget) param [0, ""]) isEqualTo "slot") then {
        // Still on that slot, and nothing over it there: nothing more to look for. A target that stands for
        // the whole equipment column has no slot of its own there (-1) and is looked for anew below.
        private _targetIndex = GVAR(dragTarget) param [1, -1];
        private _record = if (_targetIndex < 0) then {[]} else {(uiNamespace getVariable [QGVAR(slots), []]) param [_targetIndex, []]};
        ([_record] call FUNC(slotRect)) params [["_slotX", 0], ["_slotY", 0], ["_slotW", 0], ["_slotH", 0]];

        if (_onTop isNotEqualTo "" || {!(_mouseX >= _slotX && {_mouseX < _slotX + _slotW} && {_mouseY >= _slotY} && {_mouseY < _slotY + _slotH})}) then {
            GVAR(dragTarget) = [];
        };
    };

    // A slot of the equipment column that does not take it: the column finds the one that does (below).
    if ((GVAR(dragTarget) param [0, ""]) isEqualTo "slot" && {!(GVAR(dragTarget) param [4, false])} && {_inArea}) then {
        GVAR(dragTarget) = [];
    };

    // ----- Anywhere on the equipment column: into the player's slot that takes it -----
    // Not only right onto its slot (Mia, 0.2.3): a helmet let go anywhere over the cards goes on the head,
    // a magazine into the weapon that takes it (einv_storage_fnc_slotFor). A body's worn item is exchanged
    // with the player's own there (fnc_canSwap); the player's own worn gear has its slots right there.
    // The footprint lies on that slot where the column shows one - every piece of worn gear has its slot in
    // the gear row, the backpack's too, empty or not -, else (nothing here takes it) faintly over the whole
    // column.
    if (_inArea && {(GVAR(dragTarget) param [0, ""]) isNotEqualTo "slot"} && {(_slotSource param [0, objNull]) isNotEqualTo GVAR(unit)}) then {
        GVAR(equipmentRect) params ["_areaX", "_areaY", "_areaW", "_areaH"];

        private _player = GVAR(unit);
        private _answer = GVAR(dragRoom) get "equipArea";

        if (isNil "_answer") then {
            private _slot = [_player, _entry getOrDefault ["class", ""]] call EFUNC(storage,slotFor);
            private _why = ["NoFit", ""] select (_slot isNotEqualTo "");

            if (_why isEqualTo "" && {_slotSource isNotEqualTo []}) then {
                _why = [_slotSource, _player, _slot] call FUNC(canSwap);
            };

            _answer = [_slot, _why];
            GVAR(dragRoom) set ["equipArea", _answer];
        };

        _answer params ["_slot", "_why"];

        private _slots = uiNamespace getVariable [QGVAR(slots), []];
        private _slotIndex = if (_slot isEqualTo "") then {-1} else {
            _slots findIf {(_x param [5, ""]) isEqualTo _slot && {(_x param [6, objNull]) isEqualTo _player} && {(_x param [7, -1]) < 0}}
        };
        private _rect = if (_slotIndex < 0) then {[]} else {[_slots select _slotIndex] call FUNC(slotRect)};

        GVAR(dragTarget) = ["slot", _slotIndex, 0, 0, _why isEqualTo "", _why, _slot, true, [objNull, _player] select (_slotSource isNotEqualTo [])];

        if (_rect isEqualTo []) then {
            [[_areaX, _areaY, _areaW, _areaH], _why isEqualTo "", DRAG_FOOTPRINT_ALPHA / 2] call _fnc_show;
        } else {
            [_rect, _why isEqualTo ""] call _fnc_show;
        };
    };

    if ((GVAR(dragTarget) param [0, ""]) isEqualTo "slot") exitWith {};

    // ----- On a grid -----
    // One of the topmost layer there: a kit window's own, or a column's with no window over it. The grid
    // that has a cell there first, and only then one with a hole there, so its footprint shows red: two
    // compartments of a canvas may share a box (a ring and the cell inside it, grid=aaa/aba/aaa), and the
    // hole of the one is the other's cell.
    private _cell = [];
    private _targetIndex = -1;

    {
        private _holesToo = _x;

        _targetIndex = _grids findIf {
            !(_x getOrDefault ["virtual", true]) && {!(_x getOrDefault ["overflow", false])} && {(_x getOrDefault ["window", ""]) isEqualTo _onTop} && {
                _cell = [_x, _mouse, _holesToo] call FUNC(screenToCell);
                _cell isNotEqualTo []
            }
        };

        if (_targetIndex >= 0) exitWith {};
    } forEach [false, true];

    if (_targetIndex < 0) exitWith {
        _footprint ctrlShow false;

        // ----- On the storage column, off its grids: into the uniform, vest or backpack slot -----
        // The column shows what the soldier wears in those three slots, so one let go on it goes on as on its
        // slot in the gear row - one worn there comes off onto the cell the new one lay on (fnc_doEquip) -,
        // a body's worn one is exchanged as there (fnc_canSwap). Wearing none of them, the whole column is that
        // target, its placeholder too, and anything else is refused there with the slot's reason; with
        // sections a grid takes what is let go on it, so only the room around the grids is. The footprint
        // covers the column at half strength, as the equipment column's; the slot is lit already
        // (fnc_showTargets).
        private _inStorage = _onTop isEqualTo "" && {_dragGroup isEqualTo []} && {call FUNC(isInventoryMode)}
            && {(_slotSource param [0, objNull]) isNotEqualTo GVAR(unit)} && {
                GVAR(storageRect) params [["_areaX", 0], ["_areaY", 0], ["_areaW", 0], ["_areaH", 0]];
                _mouseX >= _areaX && {_mouseX < _areaX + _areaW} && {_mouseY >= _areaY} && {_mouseY < _areaY + _areaH}
            };

        private _storageAnswer = if (_inStorage) then {GVAR(dragRoom) get "storageArea"} else {[]};

        if (isNil "_storageAnswer") then {
            private _player = GVAR(unit);
            private _slot = [_player, _entry getOrDefault ["class", ""]] call EFUNC(storage,slotFor);

            if !(_slot in ["uniform", "vest", "backpack"]) then {
                _slot = "";
            };

            private _why = ["NoFit", ""] select (_slot isNotEqualTo "");

            if (_why isEqualTo "" && {_slotSource isNotEqualTo []}) then {
                _why = [_slotSource, _player, _slot] call FUNC(canSwap);
            };

            // Nothing worn there: a slot that is empty takes the whole of it onto the soldier (the weight
            // forecast, as on the slot).
            private _empty = _slot isNotEqualTo "" && {((GVAR(context) getOrDefault ["equipment", createHashMap]) getOrDefault [_slot, ""]) isEqualTo ""};

            _storageAnswer = [_slot, _why, _empty];
            GVAR(dragRoom) set ["storageArea", _storageAnswer];
        };

        if (
            _storageAnswer isNotEqualTo []
            && {(_storageAnswer select 0) isNotEqualTo "" || {(GVAR(context) getOrDefault ["ownSections", []]) isEqualTo []}}
        ) exitWith {
            _storageAnswer params ["_slot", "_why", "_empty"];

            GVAR(dragTarget) = ["slot", -1, 0, 0, _why isEqualTo "", _why, _slot, true, [objNull, GVAR(unit)] select (_slotSource isNotEqualTo [])];
            [GVAR(storageRect), _why isEqualTo "", DRAG_FOOTPRINT_ALPHA / 2] call _fnc_show;

            if (_why isEqualTo "" && {_empty} && {_slotSource isEqualTo []}) then {
                _hintParts = [([[_entry]] call EFUNC(storage,getMass)) / ((_entry getOrDefault ["count", 1]) max 1)] call _fnc_forecast;

                if (_hintParts isEqualTo []) then {
                    _hintParts = GVAR(dragKeys);
                };
            };
        };

        // A zone a window that attached drew (uiNamespace zones, fnc_endDrag hands it to the "drop" hook): the
        // footprint covers it at half strength.
        private _zones = uiNamespace getVariable [QGVAR(zones), []];
        private _zoneIndex = _zones findIf {
            (_x select 0) params [["_zoneX", 0], ["_zoneY", 0], ["_zoneW", 0], ["_zoneH", 0]];

            _mouseX >= _zoneX && {_mouseX < _zoneX + _zoneW} && {_mouseY >= _zoneY} && {_mouseY < _zoneY + _zoneH}
        };

        if (_zoneIndex >= 0) exitWith {
            GVAR(dragTarget) = ["zone", _zoneIndex, 0, 0, true, ""];
            [(_zones select _zoneIndex) select 0, true, DRAG_FOOTPRINT_ALPHA / 2] call _fnc_show;
        };

        // Outside every panel, with no kit window there either: the ground. Not for what lies on the ground
        // already.
        private _outside = _onTop isEqualTo "" && {GVAR(panels) findIf {
            _x params ["_panelX", "_panelY", "_panelW", "_panelH"];
            _mouseX >= _panelX && {_mouseX < _panelX + _panelW} && {_mouseY >= _panelY} && {_mouseY < _panelY + _panelH}
        } < 0};

        private _fromGround = _slotSource isEqualTo [] && {
            if (_dragGroup isEqualTo []) then {
                [(_grids select _sourceIndex) get "container"] call EFUNC(storage,isGroundHolder)
            } else {
                // Several: they all lie on the ground already.
                _dragGroup findIf {
                    !([(_grids param [_x select 0, createHashMap]) getOrDefault ["container", objNull]] call EFUNC(storage,isGroundHolder))
                } < 0
            }
        };

        GVAR(dragTarget) = [[], ["ground", -1, 0, 0, true, ""]] select (_outside && {!_fromGround});
    };

    private _target = _grids select _targetIndex;
    private _col = (_cell select 0) - _grabCol;
    private _row = (_cell select 1) - _grabRow;
    private _reason = "";
    private _place = true;

    // Where it comes from and where it would go: a grid is its container - or, with none, the open kit it
    // stands for (einv_compat_efak). A slot's item comes from no grid at all.
    private _sourceGrid = if (_slotSource isEqualTo []) then {_grids select _sourceIndex} else {createHashMap};
    private _from = _sourceGrid getOrDefault ["container", objNull];
    private _fromKit = _sourceGrid getOrDefault ["kit", ""];
    private _to = _target getOrDefault ["container", objNull];
    private _toKit = _target getOrDefault ["kit", ""];

    // As many of a stack as the wheel left (fnc_onMouseZ), -1 for all of it.
    private _amount = [-1, GVAR(dragCount)] select (GVAR(dragCount) < _stack);

    // ----- Several tiles together -----
    // Keep the arrangement, pack into the hovered container, leave it to the kit, or nothing (fnc_groupMode).
    if (_dragGroup isNotEqualTo []) exitWith {
        ([_targetIndex, _cell] call FUNC(groupMode)) params ["_mode", "_data", "_fitting", "_total", "_why"];

        private _fits = switch (_mode) do {
            case "keep": {true};
            case "pack": {_fitting > 0};
            case "kit": {_fitting == _total};
            default {false};
        };

        GVAR(dragTarget) = [
            "group", _targetIndex, _mode, [-1, _data param [0, -1]] select (_mode isEqualTo "kit"), _fits, _why,
            format ["group|%1|%2|%3", _targetIndex, _cell select 0, _cell select 1]
        ];

        ([_target] call FUNC(gridOrigin)) params ["_originX", "_originY"];

        private _gain = GVAR(theme) getOrDefault ["gain", [0.298, 0.765, 0.541, 1]];
        private _loss = GVAR(theme) getOrDefault ["loss", [0.941, 0.333, 0.353, 1]];
        private _partly = GVAR(theme) getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];

        private _fnc_paint = {
            params ["_control", "_rect", "_color"];

            _control ctrlSetPosition _rect;
            _control ctrlSetBackgroundColor [_color select 0, _color select 1, _color select 2, DRAG_FOOTPRINT_ALPHA];
            _control ctrlCommit 0;
            _control ctrlShow true;
        };

        // The compartment as a whole, for every mode but "keep" - drawn in where it borders another one
        // (fnc_spanRect).
        private _compartment = [_target, [_originX, _originY], 0, 0, _target get "cols", _target get "rows"] call FUNC(spanRect);

        switch (_mode) do {
            case "keep": {
                _footprint ctrlShow false;

                // One footprint per tile, where it would lie; every picture at its own offset from the mouse.
                private _footprints = uiNamespace getVariable [QGVAR(dragFootprints), []];

                {
                    _x params ["_groupGrid", "_groupTile", "_cellCol", "_cellRow"];

                    private _tile = (((_grids param [_groupGrid, createHashMap]) getOrDefault ["tiles", []]) param [_groupTile, createHashMap]);

                    if (_forEachIndex < count _footprints && {count _tile > 0}) then {
                        private _tileHoles = _tile getOrDefault ["holes", []];
                        private _rect = [_target, [_originX, _originY], _cellCol, _cellRow, _tile get "w", _tile get "h"] call FUNC(spanRect);

                        // A shaped tile on its own cells, while there are controls left for it.
                        if (
                            _tileHoles isNotEqualTo []
                            && {[
                                [_rect select 0, _rect select 1], [_tile get "w", _tile get "h", _tileHoles], _gain,
                                [_target, _cellCol, _cellRow, _tile get "w", _tile get "h"] call FUNC(spanInsets)
                            ] call _fnc_paintShape}
                        ) exitWith {
                            (_footprints select _forEachIndex) ctrlShow false;
                        };

                        [_footprints select _forEachIndex, _rect, _gain] call _fnc_paint;
                    };
                } forEach _data;

                {
                    _x params ["_ghostControl", "_offsetCellsX", "_offsetCellsY", "_pictureX", "_pictureY", ["_ghostTurned", false]];

                    _ghostControl ctrlSetPosition [_boxX + _offsetCellsX + _pictureX, _boxY + _offsetCellsY + _pictureY];
                    _ghostControl ctrlCommit 0;

                    // A tile that lies turned keeps its turned picture where it moved, as the held one does above.
                    if (_ghostTurned) then {
                        _ghostControl ctrlSetAngle [90, 0.5, 0.5];
                    };

                    _ghostControl ctrlShow true;
                } forEach (uiNamespace getVariable [QGVAR(dragGhosts), []]);
            };
            case "kit": {
                // On the kit's tile, or the kit's grid.
                private _kitTile = (_target getOrDefault ["tiles", []]) param [_data param [0, -1], createHashMap];

                private _rect = if (count _kitTile > 0) then {
                    [_target, [_originX, _originY], _kitTile get "col", _kitTile get "row", _kitTile get "w", _kitTile get "h"] call FUNC(spanRect)
                } else {
                    _compartment
                };

                [_footprint, _rect, [_loss, _gain] select _fits] call _fnc_paint;
            };
            case "pack": {
                // Green when all fit, amber when some do, red when none.
                [_footprint, _compartment, [_loss, [_partly, _gain] select (_fitting == _total)] select _fits] call _fnc_paint;

                if (_fits && {_fitting < _total}) then {
                    _hintParts = [[format [LLSTRING(Hint_GroupFits), _fitting, _total], "text"]];
                };
            };
            default {
                [_footprint, _compartment, _loss] call _fnc_paint;
            };
        };

        if (!isNull _counter) then {
            _counter ctrlSetText ([format ["×%1", _total], format ["%1 / %2", _fitting, _total]] select (_mode isEqualTo "pack"));
        };
    };

    // ----- On a kit's tile: into that kit, wherever it lies (einv_compat_efak, when loaded) -----
    // The cell under the mouse decides, not the footprint's corner. Not the dragged tile itself, not a kit
    // nobody has found yet, and not the tile of the kit it comes out of: that is where it lies already, so
    // the grid below says no room, as for a tile out of an opened backpack dropped on that backpack.
    private _kitTile = -1;

    if (!isNil QEFUNC(compat_efak,canDrop) && {(_sourceGrid getOrDefault ["source", ""]) isEqualTo ""}) then {
        private _underIndex = [_target, _cell] call FUNC(tileAt);
        private _under = (_target get "tiles") param [_underIndex, createHashMap];

        if (
            _underIndex >= 0
            && {!(_targetIndex == _sourceIndex && {_underIndex == _tileIndex})}
            && {!(_under getOrDefault ["hidden", false])}
            && {(_under getOrDefault ["class", ""]) != _fromKit}
            && {[_under getOrDefault ["class", ""]] call EFUNC(compat_efak,isKit)}
        ) then {
            _kitTile = _underIndex;
        };
    };

    if (_kitTile >= 0) exitWith {
        private _under = (_target get "tiles") select _kitTile;
        private _key = format ["kitTile|%1|%2|%3", _targetIndex, _kitTile, GVAR(dragCount)];
        private _answer = GVAR(dragRoom) get _key;

        if (isNil "_answer") then {
            _answer = [[_from, _fromKit], _under get "class", _entry, _amount, _slotSource, [_to, _toKit]] call EFUNC(compat_efak,canDrop);
            GVAR(dragRoom) set [_key, _answer];
        };

        _answer params ["_fits", "_why"];

        GVAR(dragTarget) = ["kitTile", _targetIndex, _kitTile, 0, _fits, [_why, "Failed"] select (!_fits && {_why isEqualTo ""})];

        // The footprint lies on the kit's tile.
        ([_target] call FUNC(gridOrigin)) params ["_originX", "_originY"];

        [[_target, [_originX, _originY], _under get "col", _under get "row", _under get "w", _under get "h"] call FUNC(spanRect), _fits] call _fnc_show;
    };

    // ----- On a magazine of its kind: the two repacked (einv_magazines, when loaded) -----
    // The cell under the mouse decides, as for a kit's tile. Not a slot's item, not the dragged tile itself.
    // A repack the player clearly meant but cannot have is red with its reason; anything that is no repack
    // goes on below as it always did.
    private _repackTile = -1;
    private _repackAnswer = [false, ""];

    if (_slotSource isEqualTo [] && {!isNil QEFUNC(magazines,canRepack)}) then {
        private _underIndex = [_target, _cell] call FUNC(tileAt);

        if (_underIndex < 0 || {_targetIndex == _sourceIndex && {_underIndex == _tileIndex}}) exitWith {};

        private _key = format ["repack|%1|%2", _targetIndex, _underIndex];
        private _answer = GVAR(dragRoom) get _key;

        if (isNil "_answer") then {
            _answer = [_sourceGrid, _entry, _target, (_target get "tiles") select _underIndex] call EFUNC(magazines,canRepack);
            GVAR(dragRoom) set [_key, _answer];
        };

        if (_answer isNotEqualTo [false, ""]) then {
            _repackTile = _underIndex;
            _repackAnswer = _answer;
        };
    };

    if (_repackTile >= 0) exitWith {
        _repackAnswer params ["_fits", "_why"];

        private _under = (_target get "tiles") select _repackTile;

        GVAR(dragTarget) = ["repack", _targetIndex, _repackTile, 0, _fits, _why];

        // The footprint lies on that magazine, in the accent colour: something else happens than a move.
        ([_target] call FUNC(gridOrigin)) params ["_originX", "_originY"];

        [
            [_target, [_originX, _originY], _under get "col", _under get "row", _under get "w", _under get "h"] call FUNC(spanRect),
            _fits, DRAG_FOOTPRINT_ALPHA, ["", "accent"] select _fits
        ] call _fnc_show;
    };

    // ----- Into itself -----
    // A uniform, vest or backpack - lying somewhere or worn - cannot go into its own grid, nor into that of
    // anything lying in it (einv_storage_fnc_liesIn): the footprint is red and says so.
    private _inside = _entry getOrDefault ["container", objNull];

    if (!isNull _inside) then {
        private _key = format ["itself|%1", _targetIndex];
        private _itself = GVAR(dragRoom) get _key;

        if (isNil "_itself") then {
            private _holder = _target getOrDefault ["holder", objNull];

            _itself = ((_holder isEqualType "") || {!isNull _holder}) && {[_holder, _inside] call EFUNC(storage,liesIn)};
            GVAR(dragRoom) set [_key, _itself];
        };

        if (_itself) then {
            _reason = "IntoItself";
        };
    };

    if (_reason isEqualTo "") then {
        // Inside the compartment, none of its cells on a shaped one's holes, and free - the dragged tile
        // does not count where it was lifted from. A shaped item takes only its own cells, and a shaped
        // tile there only its own (einv_storage_fnc_overlaps).
        private _mask = [_col, _row, _w, _h, _dragHoles];
        private _taken = _col < 0 || {_row < 0} || {_col + _w > _target get "cols"} || {_row + _h > _target get "rows"}
            || {[_target, _col, _row, _w, _h, _dragHoles] call FUNC(hitsHole)};

        if (!_taken) then {
            {
                if (
                    !(_targetIndex == _sourceIndex && {_forEachIndex == _tileIndex})
                    && {[_mask, [_x get "col", _x get "row", _x get "w", _x get "h", _x getOrDefault ["holes", []]]] call EFUNC(storage,overlaps)}
                ) exitWith {
                    _taken = true;
                };
            } forEach (_target get "tiles");
        };

        // A cell a move under way goes to is taken as well (GVAR(inFlight), outlined by fnc_drawPending):
        // nothing shows there before it arrived, but it will.
        if (!_taken && {count GVAR(inFlight) > 0}) then {
            private _holder = _target getOrDefault ["holder", objNull];
            private _block = _target getOrDefault ["block", 0];

            // A HashMap: _x is the request id, _y its record - the cells it goes to second.
            {
                if (((_y param [1, []]) findIf {
                    _x params [["_toHolder", objNull], ["_toBlock", 0], ["_toCol", 0], ["_toRow", 0], ["_toW", 1], ["_toH", 1]];

                    _toHolder isEqualTo _holder && {_toBlock == _block}
                    && {[_mask, [_toCol, _toRow, _toW, _toH]] call EFUNC(storage,overlaps)}
                }) >= 0) exitWith {
                    _taken = true;
                };
            } forEach GVAR(inFlight);
        };

        // In a kit's grid the cell only says where something from elsewhere would like to lie: taken, the
        // kit's layout finds it another (einv_storage_fnc_getLayout). Moved within the kit, the cell is all
        // the move is about (einv_compat_efak_fnc_drop) - there, as in a container, whose cells are its room,
        // a taken one is no room.
        if (_taken) then {
            if (_toKit isEqualTo "" || {[_from, _fromKit] isEqualTo [_to, _toKit]}) then {
                _reason = "NoRoom";
            } else {
                _place = false;
            };
        };
    };

    if (_reason isEqualTo "" && {[_from, _fromKit] isNotEqualTo [_to, _toKit]}) then {
        if (_toKit isNotEqualTo "") exitWith {
            // Into an open kit: what the kit takes and has room for (einv_compat_efak_fnc_canDrop).
            private _key = format ["kit|%1|%2", _targetIndex, GVAR(dragCount)];
            private _answer = GVAR(dragRoom) get _key;

            if (isNil "_answer") then {
                _answer = if (isNil QEFUNC(compat_efak,canDrop)) then {[false, "Failed"]} else {
                    [[_from, _fromKit], _toKit, _entry, _amount, _slotSource] call EFUNC(compat_efak,canDrop)
                };

                GVAR(dragRoom) set [_key, _answer];
            };

            _answer params ["_fits", "_why"];

            if (!_fits) then {
                _reason = [_why, "Failed"] select (_why isEqualTo "");
            };
        };

        // A living person's container the player may not put into, or who is out of reach by now.
        private _touchKey = format ["touch|%1", _targetIndex];
        private _touch = GVAR(dragRoom) get _touchKey;

        if (isNil "_touch") then {
            _touch = [_to, "items"] call FUNC(checkTouch);
            GVAR(dragRoom) set [_touchKey, _touch];
        };

        if (_touch isNotEqualTo "") exitWith {
            _reason = _touch;
        };

        // A backpack never goes into a backpack; the cells above are every other limit.
        if ([_to, _entry] call EFUNC(storage,backpackIntoBackpack)) exitWith {
            _reason = "NoBackpack";
        };

        // Into the soldier's own gear from outside it: what that makes of him, as many of a stack as the wheel
        // left (fnc_onMouseZ), worked out once per target and count.
        private _key = format ["hint|%1|%2", _targetIndex, GVAR(dragCount)];
        private _roomParts = GVAR(dragRoom) get _key;

        if (isNil "_roomParts") then {
            _roomParts = [];

            if (_toKit isEqualTo "" && {[_to] call FUNC(isOwnStorage)}) then {
                _roomParts = [([[_entry]] call EFUNC(storage,getMass)) * ([_stack, _amount] select (_amount > 0)) / _stack] call _fnc_forecast;
            };

            GVAR(dragRoom) set [_key, _roomParts];
        };

        if (_roomParts isNotEqualTo []) then {
            _hintParts = _roomParts;
        };
    };

    GVAR(dragTarget) = ["grid", _targetIndex, _col, _row, _reason isEqualTo "", _reason, "", _place];

    // The footprint lies on the target's cells, clipped to the grid where the item would stick out - and
    // on a canvas's compartment drawn in where those cells border another one (fnc_spanRect).
    ([_target] call FUNC(gridOrigin)) params ["_originX", "_originY"];

    private _left = (_col max 0) min ((_target get "cols") - 1);
    private _top = (_row max 0) min ((_target get "rows") - 1);
    private _right = ((_col + _w) min (_target get "cols")) max (_left + 1);
    private _bottom = ((_row + _h) min (_target get "rows")) max (_top + 1);
    private _clipRect = [_target, [_originX, _originY], _left, _top, _right - _left, _bottom - _top] call FUNC(spanRect);

    [_clipRect, _reason isEqualTo ""] call _fnc_show;

    // A shaped item on its own cells instead, those inside the grid: a cell of the clipped box is a hole
    // where the item has none.
    if (_dragHoles isNotEqualTo []) then {
        private _clipW = _right - _left;
        private _clipH = _bottom - _top;
        private _clipHoles = [];

        for "_r" from 0 to (_clipH - 1) do {
            for "_c" from 0 to (_clipW - 1) do {
                private _itemCol = _left + _c - _col;
                private _itemRow = _top + _r - _row;

                if (
                    _itemCol < 0 || {_itemRow < 0} || {_itemCol >= _w} || {_itemRow >= _h}
                    || {(_itemRow * _w + _itemCol) in _dragHoles}
                ) then {
                    _clipHoles pushBack (_r * _clipW + _c);
                };
            };
        };

        private _color = if (_reason isEqualTo "") then {
            GVAR(theme) getOrDefault ["gain", [0.298, 0.765, 0.541, 1]]
        } else {
            GVAR(theme) getOrDefault ["loss", [0.941, 0.333, 0.353, 1]]
        };

        if (
            count _clipHoles < _clipW * _clipH
            && {[
                [_clipRect select 0, _clipRect select 1], [_clipW, _clipH, _clipHoles], _color,
                [_target, _left, _top, _clipW, _clipH] call FUNC(spanInsets)
            ] call _fnc_paintShape}
        ) then {
            _footprint ctrlShow false;
        };
    };
};

// The hint over this target, written when it differs from what stands there.
[_hintParts] call FUNC(dragHint);

// A window that attached has the last word on where it lands (the "dragCheck" hook): it may change
// whether it fits and why not, or turn the target into another - the Arsenal makes the ground a
// remove zone, or nothing. The footprint follows the final verdict.
private _checked = ["dragCheck", [GVAR(dragTarget), _entry, if (_slotSource isEqualTo []) then {_grids param [_sourceIndex, createHashMap]} else {createHashMap}, _slotSource]] call FUNC(hook);

if (!isNil "_checked" && {_checked isEqualType []}) then {
    GVAR(dragTarget) = _checked;

    switch (_checked param [0, ""]) do {
        case "";
        case "ground": {
            _footprint ctrlShow false;

            {_x ctrlShow false} forEach _shapes;
        };
        case "zone": {
            private _zone = (uiNamespace getVariable [QGVAR(zones), []]) param [_checked param [1, -1], []];

            if (_zone isEqualTo []) then {
                _footprint ctrlShow false;
            } else {
                [_zone select 0, _checked param [4, true], DRAG_FOOTPRINT_ALPHA / 2, _checked param [6, ""]] call _fnc_show;
            };
        };
        default {
            // Where it is, in the colour of the new verdict.
            private _color = if (_checked param [4, false]) then {
                GVAR(theme) getOrDefault ["gain", [0.298, 0.765, 0.541, 1]]
            } else {
                GVAR(theme) getOrDefault ["loss", [0.941, 0.333, 0.353, 1]]
            };

            _footprint ctrlSetBackgroundColor [_color select 0, _color select 1, _color select 2, DRAG_FOOTPRINT_ALPHA];

            // A shaped footprint as well, where one shows.
            {
                _x ctrlSetBackgroundColor [_color select 0, _color select 1, _color select 2, DRAG_FOOTPRINT_ALPHA];
            } forEach _shapes;
        };
    };
};
