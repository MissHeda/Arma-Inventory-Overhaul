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
 * Over a tile that lies there (a grid's taken cells, a whole stack held, no kit, no slot's item) the two swap
 * places when that fits (fnc_swapPlan): the dragged one lands on the footprint, which must cover the cells of
 * exactly one other tile of another class, and that tile goes to the cell the dragged one came from, in either
 * grid. Both footprints lie in the accent colour (GVAR(dragRoom) "swap|...", worked out once per hovered
 * cell), the target's 10th element is the plan and fnc_endDrag sends it (fnc_applySwap). A kit's tile, a
 * magazine that repacks and a weapon's slot answer before that; anything that does not swap is refused as
 * before ("NoRoom", or the reason a rule gives).
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
 * so no forecast for a filled one), worked out once per drag, target and count (GVAR(dragRoom)); so are
 * whether a slot takes it ("slot|n"), the forecast of a weight ("forecast|kg"), the mass of what is held
 * ("mass") and whether the cells under the footprint are taken ("taken", again only when the footprint
 * stands on other cells, from the grid's cells: "cells|n") - no frame reads the loadout, asks config or passes
 * every tile of a grid for an answer it has. Anything
 * else the target has nothing to say about, the hint is the key help lift wrote. The ghost is held as GVAR(dragSize) says - turned with R - with the
 * count of a stack beside it; at a column's or a kit window body's top or bottom edge it scrolls - only
 * while nothing lies over it there.
 *
 * A frame does only what changed since the last one. The mouse where it stood, and the count, the turn, the moves
 * under way and the columns' scroll as they were: nothing at all. Where the slots and grids show on the screen is
 * worked out at the first frame and again only after a column scrolled (GVAR(dragRoom) "geometry"); which tile
 * lies on each cell of a grid and which cells are taken, once per grid ("cells|n"). From them a mouse that moved
 * finds what lies under it - the slots whose box holds it, the grid and cell, the equipment and storage columns, a
 * zone, the panels ("spot") - and only when that differs from the last frame's is the target worked out again,
 * the footprint painted, the hint written and the window that attached asked ("dragCheck"). In a cell of a grid
 * that no slot, other grid or the equipment column reaches into, a mouse that stays in that cell moves the ghost
 * and nothing else ("hold"). With "Log window timings (debug)" on (einv_gui_debugTiming), each frame notes what
 * its parts took (fnc_startDrag, fnc_endDrag).
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

private _entry = uiNamespace getVariable [QGVAR(dragEntry), createHashMap];

if (count _entry == 0) exitWith {};

// For the tester's numbers (einv_gui_debugTiming): with the setting on, fnc_startDrag put "timing" into the
// drag's record and each part of this frame notes when it ended (fnc_endDrag writes the line). Off, nothing is.
private _timed = "timing" in GVAR(dragRoom);
private _marks = [];
private _anew = false;

if (_timed) then {
    _marks pushBack ["", diag_tickTime];
};

// Called on the way out with the setting on: what this frame took, how often the target was worked out again,
// and the parts of the slowest frame so far.
private _fnc_noteTime = {
    private _timing = GVAR(dragRoom) get "timing";
    private _took = (diag_tickTime - ((_marks select 0) select 1)) * 1000;

    _timing set [1, (_timing select 1) + 1];
    _timing set [2, (_timing select 2) + _took];

    if (_anew) then {
        _timing set [5, (_timing select 5) + 1];
    };

    if (_took > (_timing select 3)) then {
        private _parts = [];

        for "_i" from 1 to (count _marks - 1) do {
            (_marks select (_i - 1)) params ["", "_from"];
            (_marks select _i) params ["_part", "_to"];

            _parts pushBack format ["%1 %2", _part, ((_to - _from) * 1000) toFixed 2];
        };

        _timing set [3, _took];
        _timing set [4, _parts joinString ", "];
    };
};

GVAR(press) params ["_sourceIndex", "_tileIndex", "", "_grab", "", "_slotSource"];
_grab params ["_grabCol", "_grabRow"];

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

// What the last frame saw: the mouse, what is held (how many, which way round, the moves under way) and what
// lay on top there (fnc_topAt: "inspect", a kit window's key, or "" for the columns). What lies on top changes
// only where the mouse moved - nothing moves a kit window or the inspect card while something is held.
(GVAR(dragRoom) getOrDefault ["frame", []]) params [["_lastMouse", []], ["_lastState", []], ["_lastTop", ""]];

private _moved = _mouse isNotEqualTo _lastMouse;
private _onTop = if (_moved) then {[_mouse] call FUNC(topAt)} else {_lastTop};

// The columns and the kit windows' bodies: held where they stood while the wheel counts a stack
// (fnc_onMouseZ); at the top or bottom edge of one that lies on top there they scroll, whatever is held.
// A body lies in its window: its place on the screen comes through it (fnc_gridOrigin). Where each stands
// and how far it scrolls is worked out at its first frame - neither moves while something is held, only what
// it shows. One that scrolled moved everything in it: every place on the screen is looked at again (below).
private _band = _cellH * 0.6;
private _scrolled = false;

{
    _x params ["_group", "_value", ["_layer", ""], ["_box", []]];

    if (isNull _group) then {continue};

    if (_box isEqualTo []) then {
        (ctrlPosition _group) params ["_groupRelX", "_groupRelY", "_groupW", "_groupH"];
        ([createHashMapFromArray [["rel", [_groupRelX, _groupRelY]], ["parent", ctrlParentControlsGroup _group]]] call FUNC(gridOrigin)) params ["_groupX", "_groupY"];

        _box = [_groupX, _groupY, _groupW, _groupH, (_group getVariable [QGVAR(contentH), _groupH]) - _groupH];
        _x set [3, _box];
    };

    _box params ["_groupX", "_groupY", "_groupW", "_groupH", "_range"];

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

    if (abs (_want - _value) > 0.00001) then {
        _scrolled = true;
    };

    _x set [1, _want];
} forEach (uiNamespace getVariable [QGVAR(dragScroll), []]);

// What is held: the wheel and the middle button change the count, R the way round, an answer the cells a move
// under way goes to (GVAR(inFlight)).
private _state = [GVAR(dragCount), GVAR(dragRot), count GVAR(inFlight)];
private _changed = _scrolled || {_state isNotEqualTo _lastState};

GVAR(dragRoom) set ["frame", [_mouse, _state, _onTop]];

if (_timed) then {
    _marks pushBack ["scroll", diag_tickTime];
};

// The mouse stands where it stood and nothing held changed: everything stays as the last frame left it.
if (!_moved && {!_changed}) exitWith {
    if (_timed) then {call _fnc_noteTime};
};

// ----- The ghost -----
// Its grabbed cell under the mouse, and the count at its bottom right corner.
private _boxX = _mouseX - (_grabCol + 0.5) * _cellW;
private _boxY = _mouseY - (_grabRow + 0.5) * _cellH;

(uiNamespace getVariable [QGVAR(dragGhostOffset), [0, 0]]) params ["_offsetX", "_offsetY"];

private _ghost = uiNamespace getVariable [QGVAR(dragGhost), controlNull];
_ghost ctrlSetPosition [_boxX + _offsetX, _boxY + _offsetY];
_ghost ctrlCommit 0;

if (uiNamespace getVariable [QGVAR(dragTurned), false]) then {
    // A ghost whose picture reaches out of its footprint is a group with the picture in it (fnc_uiItemPicture):
    // the picture is what turns.
    (_ghost getVariable [QGVAR(inner), _ghost]) ctrlSetAngle [90, 0.5, 0.5];
};

private _counter = uiNamespace getVariable [QGVAR(dragCounter), controlNull];

if (!isNull _counter) then {
    (ctrlPosition _counter) params ["", "", "_counterW", "_counterH"];

    _counter ctrlSetPosition [_boxX + _w * _cellW - _counterW, _boxY + _h * _cellH + pixelH * 3];
    _counter ctrlCommit 0;
};

// The pictures of a group that keeps its arrangement, every one at its offset from the mouse - shown by the
// grid below, and following the mouse while they show ("ghosts" in the drag's record).
private _fnc_moveGhosts = {
    {
        _x params ["_ghostControl", "_offsetCellsX", "_offsetCellsY", "_pictureX", "_pictureY", ["_ghostTurned", false]];

        _ghostControl ctrlSetPosition [_boxX + _offsetCellsX + _pictureX, _boxY + _offsetCellsY + _pictureY];
        _ghostControl ctrlCommit 0;

        // A tile that lies turned keeps its turned picture where it moved, as the held one does above.
        if (_ghostTurned) then {
            (_ghostControl getVariable [QGVAR(inner), _ghostControl]) ctrlSetAngle [90, 0.5, 0.5];
        };

        _ghostControl ctrlShow true;
    } forEach (uiNamespace getVariable [QGVAR(dragGhosts), []]);
};

if (GVAR(dragRoom) getOrDefault ["ghosts", false]) then {
    call _fnc_moveGhosts;
};

if (_timed) then {
    _marks pushBack ["ghost", diag_tickTime];
};

// ----- What lies under the mouse -----
private _grids = uiNamespace getVariable [QGVAR(grids), []];
private _slots = uiNamespace getVariable [QGVAR(slots), []];

// Where every slot and every grid shows on the screen, worked out at the first frame and again after a column
// scrolled ("geometry"): each slot's box (fnc_slotRect, [] for one scrolled out of sight); each grid that can
// be a target as [the box its column shows or [] where nothing clips it, left, top, the box of its cells
// that shows] (fnc_screenToCell, fnc_gridOrigin), [] for one that cannot (virtual, overflow). Nothing else
// moves while something is held: a build waits for it, and one that comes ends the drag.
private _geometry = GVAR(dragRoom) getOrDefault ["geometry", []];

if (_scrolled || {_geometry isEqualTo []}) then {
    private _gridBoxes = _grids apply {
        if ((_x getOrDefault ["virtual", true]) || {_x getOrDefault ["overflow", false]}) then {[]} else {
            private _parent = _x getOrDefault ["parent", controlNull];
            private _visible = [];

            if (!isNull _parent) then {
                (ctrlPosition _parent) params ["_groupX", "_groupY", "_groupW", "_groupH"];
                ([createHashMapFromArray [["rel", [_groupX, _groupY]], ["parent", ctrlParentControlsGroup _parent]]] call FUNC(gridOrigin)) params ["_groupLeft", "_groupTop"];

                _visible = [_groupLeft, _groupTop, _groupW, _groupH];
            };

            ([_x] call FUNC(gridOrigin)) params ["_originX", "_originY"];

            // Its cells reach to where its last column and row start and a pitch on (fnc_createGrid "colX",
            // "rowY"): further than the plain pitch where a seam of a canvas opens inside it.
            private _colX = _x getOrDefault ["colX", []];
            private _rowY = _x getOrDefault ["rowY", []];
            private _lastX = if (_colX isEqualTo []) then {((_x get "cols") - 1) * (_x get "cellW")} else {_colX select (count _colX - 1)};
            private _lastY = if (_rowY isEqualTo []) then {((_x get "rows") - 1) * (_x get "cellH")} else {_rowY select (count _rowY - 1)};
            private _left = _originX;
            private _top = _originY;
            private _right = _originX + _lastX + (_x get "cellW");
            private _bottom = _originY + _lastY + (_x get "cellH");

            if (_visible isNotEqualTo []) then {
                _visible params ["_visibleX", "_visibleY", "_visibleW", "_visibleH"];

                _left = _left max _visibleX;
                _top = _top max _visibleY;
                _right = _right min (_visibleX + _visibleW);
                _bottom = _bottom min (_visibleY + _visibleH);
            };

            [_visible, _originX, _originY, [_left, _top, _right - _left, _bottom - _top]]
        }
    };

    _geometry = [_slots apply {[_x] call FUNC(slotRect)}, _gridBoxes];
    GVAR(dragRoom) set ["geometry", _geometry];
};

_geometry params ["_slotRects", "_gridBoxes"];

// The column (row) at _local from a grid's corner as fnc_screenToCell finds it, -1 for none, and whether it
// lies in the room a seam opens after it: the stretch of one pitch it lies in names, in the grid's lookup
// (fnc_createGrid "colAt"), the last column starting there or before - it is that one or the one before. The
// room a seam of a canvas opens inside a compartment belongs to the cell before it where the cells across it
// are the compartment's too; the room between two compartments to no grid.
private _fnc_find = {
    params ["_local", "_starts", "_lookup", "_pitch"];

    private _stretch = floor (_local / _pitch);

    if (_lookup isEqualTo []) exitWith {[_stretch, false]};
    if (_local < 0 || {_local >= (_starts select (count _starts - 1)) + _pitch}) exitWith {[-1, false]};

    private _at = _lookup param [_stretch, count _starts - 1];

    if (_local < (_starts select _at)) then {
        _at = _at - 1;
    };

    [_at, _local >= (_starts select _at) + _pitch]
};

// The cell of grid _index under the mouse as fnc_screenToCell finds it, with or without the grid's holes; []
// for none.
private _fnc_cellAt = {
    params ["_index", "_holesToo"];

    private _grid = _grids select _index;

    (_gridBoxes select _index) params ["_visible", "_originX", "_originY"];

    if (_visible isNotEqualTo [] && {
        _visible params ["_visibleX", "_visibleY", "_visibleW", "_visibleH"];
        !(_mouseX >= _visibleX && {_mouseX < _visibleX + _visibleW} && {_mouseY >= _visibleY} && {_mouseY < _visibleY + _visibleH})
    }) exitWith {[]};

    ([_mouseX - _originX, _grid getOrDefault ["colX", []], _grid getOrDefault ["colAt", []], _grid get "cellW"] call _fnc_find) params ["_col", "_gapX"];
    ([_mouseY - _originY, _grid getOrDefault ["rowY", []], _grid getOrDefault ["rowAt", []], _grid get "cellH"] call _fnc_find) params ["_row", "_gapY"];

    if (_col < 0 || {_row < 0} || {_col >= _grid get "cols"} || {_row >= _grid get "rows"}) exitWith {[]};
    if ((_gapX || {_gapY}) && {[_grid, _col, _row, [1, 2] select _gapX, [1, 2] select _gapY] call FUNC(hitsHole)}) exitWith {[]};
    if (!_holesToo && {[_grid, _col, _row] call FUNC(hitsHole)}) exitWith {[]};

    [_col, _row]
};

// Still on the last frame's cell of a grid that nothing else reaches into ("hold", below), with nothing held
// changed: there is nothing more to look for - the ghost moved, and that is all.
private _hold = GVAR(dragRoom) getOrDefault ["hold", []];

if (
    !_changed && {_hold isNotEqualTo []} && {(_hold select 2) isEqualTo _onTop}
    && {([_hold select 0, true] call _fnc_cellAt) isEqualTo (_hold select 1)}
) exitWith {
    if (_timed) then {
        _marks pushBack ["find", diag_tickTime];
        call _fnc_noteTime;
    };
};

// The slots whose box holds the mouse, in their order: each kind of slot target below takes the first of
// them that is its kind.
private _slotHits = [];

{
    _x params [["_left", 0], ["_top", 0], ["_width", 0], ["_height", 0]];

    if (_mouseX >= _left && {_mouseX < _left + _width} && {_mouseY >= _top} && {_mouseY < _top + _height}) then {
        _slotHits pushBack _forEachIndex;
    };
} forEach _slotRects;

// The grid of the topmost layer there: a kit window's own, or a column's with no window over it. The grid
// that has a cell there first, and only then one with a hole there, so its footprint shows red: two
// compartments of a canvas may share a box (a ring and the cell inside it, grid=aaa/aba/aaa), and the
// hole of the one is the other's cell.
private _hitGrid = -1;
private _hitCell = [];

// Only a grid whose cells that show lie there - a pixel wider all round, for the rounding at their edges - is
// asked for its cell.
{
    private _holesToo = _x;

    {
        if (
            _x isNotEqualTo [] && {
                (_x select 3) params ["_cellsX", "_cellsY", "_cellsW", "_cellsH"];

                _mouseX >= _cellsX - pixelW && {_mouseX < _cellsX + _cellsW + pixelW}
                && {_mouseY >= _cellsY - pixelH} && {_mouseY < _cellsY + _cellsH + pixelH}
            }
            && {((_grids select _forEachIndex) getOrDefault ["window", ""]) isEqualTo _onTop} && {
                _hitCell = [_forEachIndex, _holesToo] call _fnc_cellAt;
                _hitCell isNotEqualTo []
            }
        ) exitWith {
            _hitGrid = _forEachIndex;
        };
    } forEach _gridBoxes;

    if (_hitGrid >= 0) exitWith {};
} forEach [false, true];

if (_hitGrid < 0) then {
    _hitCell = [];
};

// Over the player's equipment column (fnc_layoutGlass), in the inventory.
private _inArea = _onTop isEqualTo "" && {_dragGroup isEqualTo []} && {[] call FUNC(isInventoryMode)} && {
    GVAR(equipmentRect) params [["_areaX", 0], ["_areaY", 0], ["_areaW", 0], ["_areaH", 0]];
    _mouseX >= _areaX && {_mouseX < _areaX + _areaW} && {_mouseY >= _areaY} && {_mouseY < _areaY + _areaH}
};

// Off every grid only: the storage column (GVAR(storageRect)), a zone a window that attached drew
// (uiNamespace zones), or outside every panel.
private _inStorage = false;
private _hitZone = -1;
private _outside = false;

if (_hitGrid < 0) then {
    _inStorage = _onTop isEqualTo "" && {_dragGroup isEqualTo []} && {call FUNC(isInventoryMode)}
        && {(_slotSource param [0, objNull]) isNotEqualTo GVAR(unit)} && {
            GVAR(storageRect) params [["_areaX", 0], ["_areaY", 0], ["_areaW", 0], ["_areaH", 0]];
            _mouseX >= _areaX && {_mouseX < _areaX + _areaW} && {_mouseY >= _areaY} && {_mouseY < _areaY + _areaH}
        };

    _hitZone = (uiNamespace getVariable [QGVAR(zones), []]) findIf {
        (_x select 0) params [["_zoneX", 0], ["_zoneY", 0], ["_zoneW", 0], ["_zoneH", 0]];

        _mouseX >= _zoneX && {_mouseX < _zoneX + _zoneW} && {_mouseY >= _zoneY} && {_mouseY < _zoneY + _zoneH}
    };

    _outside = _onTop isEqualTo "" && {GVAR(panels) findIf {
        _x params ["_panelX", "_panelY", "_panelW", "_panelH"];
        _mouseX >= _panelX && {_mouseX < _panelX + _panelW} && {_mouseY >= _panelY} && {_mouseY < _panelY + _panelH}
    } < 0};
};

if (_timed) then {
    _marks pushBack ["find", diag_tickTime];
};

// All of that as the last frame found it, with nothing held changed: the target, the footprint, the hint and
// the answer of the window that attached stand as they are.
private _spot = [_onTop, _slotHits, _hitGrid, _hitCell, _inArea, _inStorage, _hitZone, _outside];

if (!_changed && {_spot isEqualTo (GVAR(dragRoom) getOrDefault ["spot", []])}) exitWith {
    if (_timed) then {call _fnc_noteTime};
};

GVAR(dragRoom) set ["spot", _spot];
_anew = true;

// A grid's cell into which no slot, no other grid and not the equipment column reach is held for as long as the
// mouse stays in it (above) - the box a pixel larger all round, for the rounding at its edges. The box is where
// the mouse finds that cell: from where its column and row start to where the next ones do, so over the room a
// seam opens inside the compartment too (fnc_createGrid "colX", "rowY").
private _newHold = [];

if (_hitGrid >= 0 && {_slotHits isEqualTo []} && {!_inArea}) then {
    private _grid = _grids select _hitGrid;

    (_gridBoxes select _hitGrid) params ["", "_originX", "_originY"];
    _hitCell params ["_holdCol", "_holdRow"];

    private _pitchW = _grid get "cellW";
    private _pitchH = _grid get "cellH";
    private _colX = _grid getOrDefault ["colX", []];
    private _rowY = _grid getOrDefault ["rowY", []];
    private _cellX = _colX param [_holdCol, _holdCol * _pitchW];
    private _cellY = _rowY param [_holdRow, _holdRow * _pitchH];
    private _left = _originX + _cellX - pixelW;
    private _top = _originY + _cellY - pixelH;
    private _right = _originX + (_colX param [_holdCol + 1, _cellX + _pitchW]) + pixelW;
    private _bottom = _originY + (_rowY param [_holdRow + 1, _cellY + _pitchH]) + pixelH;

    // Whether a box [x, y, w, h] reaches into that cell.
    private _fnc_meets = {
        params [["_rectX", 0], ["_rectY", 0], ["_rectW", 0], ["_rectH", 0]];

        _rectW > 0 && {_rectH > 0} && {_rectX < _right} && {_rectX + _rectW > _left} && {_rectY < _bottom} && {_rectY + _rectH > _top}
    };

    if ((_slotRects findIf {_x call _fnc_meets}) >= 0 || {GVAR(equipmentRect) call _fnc_meets}) exitWith {};

    private _clear = true;

    {
        if (_x isNotEqualTo [] && {_forEachIndex != _hitGrid} && {(_x select 3) call _fnc_meets}) exitWith {
            _clear = false;
        };
    } forEach _gridBoxes;

    if (_clear) then {
        _newHold = [_hitGrid, _hitCell, _onTop];
    };
};

GVAR(dragRoom) set ["hold", _newHold];

// ----- Where it would land: worked out again only now that something changed -----
// The count beside the ghost: as many of a stack as go, or how many tiles - a group's grid says below how many
// of them fit.
if (!isNull _counter) then {
    _counter ctrlSetText ([format ["%1 / %2", GVAR(dragCount), _stack], format ["×%1", count _dragGroup]] select (_dragGroup isNotEqualTo []));
};

// A group's extra footprints and pictures are shown only where they mean something, below.
if (_dragGroup isNotEqualTo []) then {
    {_x ctrlShow false} forEach (uiNamespace getVariable [QGVAR(dragFootprints), []]);
    {(_x select 0) ctrlShow false} forEach (uiNamespace getVariable [QGVAR(dragGhosts), []]);

    GVAR(dragRoom) set ["ghosts", false];
};

private _footprint = uiNamespace getVariable [QGVAR(dragFootprint), controlNull];

// A shaped item (size=xx/x-) shows its footprint on a grid on its own cells only (fnc_shapeRects), in
// controls made with the drag so they lie under the ghost (fnc_startDrag). Hidden here and shown again below
// where they mean something; turned with R, the shape turns with it.
private _shapes = uiNamespace getVariable [QGVAR(dragShapes), []];
private _shapeUsed = 0;
private _dragHoles = ([_entry getOrDefault ["class", ""], GVAR(dragRot)] call EFUNC(items,footprintAs)) select 2;

{_x ctrlShow false} forEach _shapes;

// The other tile's footprint of a swap (fnc_startDrag made it), shown below only where the drop is one.
private _swapFootprint = uiNamespace getVariable [QGVAR(dragSwapFootprint), controlNull];

_swapFootprint ctrlShow false;

// Paints the next free shape controls: false when too few are left, and the caller draws the box.
// _origin is the corner of the cells it lies on (fnc_spanRect), _on [grid, column, row] of that corner, so
// the shape follows the grid's columns and rows over a seam of a canvas (fnc_shapeRects).
private _fnc_paintShape = {
    params ["_origin", "_shape", "_color", ["_on", []]];

    private _rects = [_origin, _cellW, _cellH, _shape, "surface", 0, _on] call FUNC(shapeRects);

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

    if (_timed) then {
        _marks pushBack ["target", diag_tickTime];
        call _fnc_noteTime;
    };
};

// What the hint says about the target, [[text, colour key], ...] - the key help unless the target has something
// to say about weight (fnc_dragHint).
private _hintParts = GVAR(dragKeys);

// What a pick-up would make of the soldier, [] when it changes nothing about his tier or does not come from
// outside his own gear (fnc_previewWeight knows where it came from).
private _fnc_forecast = {
    params ["_need"];

    if !(uiNamespace getVariable [QGVAR(dragExternal), false]) exitWith {[]};

    // Kept for the drag by what it adds: the soldier's load does not change while something is held, and an
    // empty slot or the storage column asks for it each time the mouse comes back to it.
    private _forecastKey = "forecast|" + str _need;
    private _kept = GVAR(dragRoom) get _forecastKey;

    if (!isNil "_kept") exitWith {_kept};

    private _load = [GVAR(unit)] call EFUNC(weight,getLoad);
    private _tier = [GVAR(unit), _load] call EFUNC(weight,getTier);
    private _newTier = [GVAR(unit), _load + _need] call EFUNC(weight,getTier);

    private _parts = [];

    if (_newTier > _tier) then {
        _parts = [[[_need, _newTier, _load + _need] call FUNC(weightText), ["text2", "accent", "loss", "loss"] select _newTier]];
    };

    GVAR(dragRoom) set [_forecastKey, _parts];

    _parts
};

// What is held weighs, worked out once per drag (fnc_previewWeight made it at the lift).
private _fnc_mass = {
    private _mass = GVAR(dragRoom) get "mass";

    if (isNil "_mass") then {
        _mass = [[_entry]] call EFUNC(storage,getMass);
        GVAR(dragRoom) set ["mass", _mass];
    };

    _mass
};

// Which tile lies on each cell of a grid, the first as fnc_tileAt finds it, and whether a tile other than the
// one lifted takes it ([under, taken], a cell at row * cols + col, nil for none): worked out once per drag and
// grid, the first time the mouse comes to it ("cells|n") - nothing on a grid changes while a tile is held. A
// cell looked up then costs one lookup instead of a pass over every tile of the grid.
private _fnc_cells = {
    params ["_index"];

    private _key = "cells|" + str _index;
    private _kept = GVAR(dragRoom) get _key;

    if (!isNil "_kept") exitWith {_kept};

    private _grid = _grids select _index;
    private _cols = _grid get "cols";
    private _rows = _grid get "rows";
    private _under = [];
    private _taken = [];

    _under resize (_cols * _rows);
    _taken resize (_cols * _rows);

    {
        private _at = _forEachIndex;
        private _lifted = _index == _sourceIndex && {_at == _tileIndex};
        private _left = _x get "col";
        private _top = _x get "row";
        private _tileW = _x get "w";
        private _tileH = _x get "h";
        private _tileHoles = _x getOrDefault ["holes", []];

        for "_r" from 0 to (_tileH - 1) do {
            for "_c" from 0 to (_tileW - 1) do {
                private _col = _left + _c;
                private _row = _top + _r;

                if (_col >= 0 && {_row >= 0} && {_col < _cols} && {_row < _rows} && {!((_r * _tileW + _c) in _tileHoles)}) then {
                    private _cellIndex = _row * _cols + _col;

                    if (isNil {_under select _cellIndex}) then {
                        _under set [_cellIndex, _at];
                    };

                    if (!_lifted) then {
                        _taken set [_cellIndex, true];
                    };
                };
            };
        };
    } forEach (_grid get "tiles");

    _kept = [_under, _taken];
    GVAR(dragRoom) set [_key, _kept];

    _kept
};

// The tile on a cell of a grid, as fnc_tileAt answers: its index, -1 for none.
private _fnc_tileUnder = {
    params ["_index", "_at"];

    (([_index] call _fnc_cells) select 0) param [(_at select 1) * ((_grids select _index) get "cols") + (_at select 0), -1]
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
        private _hit = _slotHits findIf {((_slots select _x) param [7, -1]) >= 0};

        if (_hit >= 0) then {
            _hotbarSlot = _slotHits select _hit;
        };
    };

    if (_hotbarSlot >= 0) exitWith {
        private _record = _slots select _hotbarSlot;
        private _from = if (_slotSource isEqualTo []) then {["grid", _grids select _sourceIndex]} else {["slot", _slotSource]};

        ([_entry get "class", _from] call EFUNC(hotbar,canBindFrom)) params ["_fits", "_why"];

        GVAR(dragTarget) = ["hotbar", _record select 7, 0, 0, _fits, _why];
        [_slotRects select _hotbarSlot, _fits] call _fnc_show;
    };

    // ----- On one of the player's own slots -----
    // Where it shows now (fnc_slotRect): the uniform, vest and backpack boxes lie in a scrolling column.
    // Never under a kit window.
    if (_slotSource isEqualTo [] && {_onTop isEqualTo ""}) then {
        private _hit = _slotHits findIf {
            private _record = _slots select _x;

            (_record param [5, ""]) isNotEqualTo "" && {(_record param [6, objNull]) isEqualTo GVAR(unit)}
        };

        if (_hit < 0) exitWith {};

        private _slotIndex = _slotHits select _hit;
        private _record = _slots select _slotIndex;

        // Whether the slot takes it, and the slot it goes into - worked out once per drag and slot, not on
        // every frame the mouse is on it: a weapon's parts read the unit's loadout and the weapon's
        // compatible magazines (einv_storage_fnc_slotAccepts, partFor).
        private _fitKey = "slot|" + str _slotIndex;
        private _fitAnswer = GVAR(dragRoom) get _fitKey;

        if (isNil "_fitAnswer") then {
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

            _fitAnswer = [_fits, _slot];
            GVAR(dragRoom) set [_fitKey, _fitAnswer];
        };

        _fitAnswer params ["_fits", "_slot"];

        GVAR(dragTarget) = ["slot", _slotIndex, 0, 0, _fits, [["NoFit", "GroupNoSlot"] select (_dragGroup isNotEqualTo []), ""] select _fits, _slot];
        [_slotRects select _slotIndex, _fits] call _fnc_show;

        // An empty slot takes the whole of it onto the soldier.
        if (_fits && {(_record select 1) isEqualTo ""} && {_dragGroup isEqualTo []}) then {
            _hintParts = [([] call _fnc_mass) / ((_entry getOrDefault ["count", 1]) max 1)] call _fnc_forecast;

            if (_hintParts isEqualTo []) then {
                _hintParts = GVAR(dragKeys);
            };
        };
    };

    // ----- Worn gear onto another unit's slot: exchanged (fnc_canSwap, fnc_doSwap) -----
    // A slot's item - the player's own or a body's - over the same slot of the other: the player's
    // backpack onto a body's backpack slot, a body's vest onto the player's vest box.
    if (_slotSource isNotEqualTo [] && {_onTop isEqualTo ""} && {_dragGroup isEqualTo []} && {[] call FUNC(isInventoryMode)}) then {
        private _hit = _slotHits findIf {
            private _record = _slots select _x;

            (_record param [5, ""]) isNotEqualTo "" && {(_record param [7, -1]) < 0}
            && {!isNull (_record param [6, objNull])} && {(_record param [6, objNull]) isNotEqualTo (_slotSource select 0)}
        };

        if (_hit < 0) exitWith {};

        private _slotIndex = _slotHits select _hit;
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
        [_slotRects select _slotIndex, _why isEqualTo ""] call _fnc_show;
    };

    if ((GVAR(dragTarget) param [0, ""]) isEqualTo "slot") then {
        // Still on that slot, and nothing over it there: nothing more to look for. A target that stands for
        // the whole equipment column has no slot of its own there (-1) and is looked for anew below.
        if (_onTop isNotEqualTo "" || {!((GVAR(dragTarget) param [1, -1]) in _slotHits)}) then {
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

        private _slotIndex = if (_slot isEqualTo "") then {-1} else {
            _slots findIf {(_x param [5, ""]) isEqualTo _slot && {(_x param [6, objNull]) isEqualTo _player} && {(_x param [7, -1]) < 0}}
        };
        private _rect = if (_slotIndex < 0) then {[]} else {_slotRects select _slotIndex};

        GVAR(dragTarget) = ["slot", _slotIndex, 0, 0, _why isEqualTo "", _why, _slot, true, [objNull, _player] select (_slotSource isNotEqualTo [])];

        if (_rect isEqualTo []) then {
            [[_areaX, _areaY, _areaW, _areaH], _why isEqualTo "", DRAG_FOOTPRINT_ALPHA / 2] call _fnc_show;
        } else {
            [_rect, _why isEqualTo ""] call _fnc_show;
        };
    };

    if ((GVAR(dragTarget) param [0, ""]) isEqualTo "slot") exitWith {};

    // ----- On a grid -----
    // The one found under the mouse above: of the topmost layer there, one with a cell there before one with a
    // hole there.
    private _cell = _hitCell;
    private _targetIndex = _hitGrid;

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
                _hintParts = [([] call _fnc_mass) / ((_entry getOrDefault ["count", 1]) max 1)] call _fnc_forecast;

                if (_hintParts isEqualTo []) then {
                    _hintParts = GVAR(dragKeys);
                };
            };
        };

        // A zone a window that attached drew (uiNamespace zones, fnc_endDrag hands it to the "drop" hook): the
        // footprint covers it at half strength.
        private _zones = uiNamespace getVariable [QGVAR(zones), []];
        private _zoneIndex = _hitZone;

        if (_zoneIndex >= 0) exitWith {
            GVAR(dragTarget) = ["zone", _zoneIndex, 0, 0, true, ""];
            [(_zones select _zoneIndex) select 0, true, DRAG_FOOTPRINT_ALPHA / 2] call _fnc_show;
        };

        // Outside every panel, with no kit window there either (found above): the ground. Not for what lies on
        // the ground already - asked once per drag.
        private _fromGround = GVAR(dragRoom) get "fromGround";

        if (isNil "_fromGround") then {
            _fromGround = _slotSource isEqualTo [] && {
                if (_dragGroup isEqualTo []) then {
                    [(_grids select _sourceIndex) get "container"] call EFUNC(storage,isGroundHolder)
                } else {
                    // Several: they all lie on the ground already.
                    _dragGroup findIf {
                        !([(_grids param [_x select 0, createHashMap]) getOrDefault ["container", objNull]] call EFUNC(storage,isGroundHolder))
                    } < 0
                }
            };

            GVAR(dragRoom) set ["fromGround", _fromGround];
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

        (_gridBoxes select _targetIndex) params ["", "_originX", "_originY"];

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

        // The compartment as a whole, for every mode but "keep" (fnc_spanRect).
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
                            && {[[_rect select 0, _rect select 1], [_tile get "w", _tile get "h", _tileHoles], _gain, [_target, _cellCol, _cellRow]] call _fnc_paintShape}
                        ) exitWith {
                            (_footprints select _forEachIndex) ctrlShow false;
                        };

                        [_footprints select _forEachIndex, _rect, _gain] call _fnc_paint;
                    };
                } forEach _data;

                call _fnc_moveGhosts;

                GVAR(dragRoom) set ["ghosts", true];
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
        private _underIndex = [_targetIndex, _cell] call _fnc_tileUnder;
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
        (_gridBoxes select _targetIndex) params ["", "_originX", "_originY"];

        [[_target, [_originX, _originY], _under get "col", _under get "row", _under get "w", _under get "h"] call FUNC(spanRect), _fits] call _fnc_show;
    };

    // ----- On a magazine of its kind: the two repacked (einv_magazines, when loaded) -----
    // The cell under the mouse decides, as for a kit's tile. Not a slot's item, not the dragged tile itself.
    // A repack the player clearly meant but cannot have is red with its reason; anything that is no repack
    // goes on below as it always did.
    private _repackTile = -1;
    private _repackAnswer = [false, ""];

    if (_slotSource isEqualTo [] && {!isNil QEFUNC(magazines,canRepack)}) then {
        private _underIndex = [_targetIndex, _cell] call _fnc_tileUnder;

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
        (_gridBoxes select _targetIndex) params ["", "_originX", "_originY"];

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
        // Looked at again only when the footprint stands on other cells: nothing on the grid changes while a
        // tile is held (a build waits for it), so a mouse that stays in its cell costs one comparison instead of
        // a pass over every tile of the grid.
        private _takenKey = [_targetIndex, _col, _row, _w, _h, GVAR(dragRot), count GVAR(inFlight)];
        private _takenKept = GVAR(dragRoom) get "taken";
        private _taken = false;

        if (!isNil "_takenKept" && {(_takenKept select 0) isEqualTo _takenKey}) then {
            _taken = _takenKept select 1;
        } else {
            private _mask = [_col, _row, _w, _h, _dragHoles];

            _taken = _col < 0 || {_row < 0} || {_col + _w > _target get "cols"} || {_row + _h > _target get "rows"}
                || {[_target, _col, _row, _w, _h, _dragHoles] call FUNC(hitsHole)};

            // A cell of its own (none of its holes) that a tile other than the lifted one takes (einv_storage_fnc_overlaps,
            // from the grid's cells above).
            if (!_taken) then {
                private _takenCells = ([_targetIndex] call _fnc_cells) select 1;
                private _cols = _target get "cols";

                for "_r" from 0 to (_h - 1) do {
                    for "_c" from 0 to (_w - 1) do {
                        if (!((_r * _w + _c) in _dragHoles) && {_takenCells param [(_row + _r) * _cols + _col + _c, false]}) exitWith {
                            _taken = true;
                        };
                    };

                    if (_taken) exitWith {};
                };
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

            GVAR(dragRoom) set ["taken", [_takenKey, _taken]];
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

    // ----- On a tile that lies there: the two swap places (fnc_swapPlan) -----
    // Only where the drop is refused for want of room and it is a plain tile-on-tile: the whole of a stack, no
    // kit's grid, no slot's item. Worked out once per footprint and per moves under way, then kept.
    private _swap = [];

    if (
        _reason isEqualTo "NoRoom" && {_slotSource isEqualTo []} && {_amount < 0} && {_fromKit isEqualTo ""} && {_toKit isEqualTo ""}
        && {(_gridBoxes param [_sourceIndex, []]) isNotEqualTo []}
    ) then {
        private _swapKey = format ["swap|%1|%2|%3|%4|%5|%6|%7", _targetIndex, _col, _row, _w, _h, GVAR(dragRot), count GVAR(inFlight)];
        private _swapAnswer = GVAR(dragRoom) get _swapKey;

        if (isNil "_swapAnswer") then {
            _swapAnswer = [
                _targetIndex, _col, _row, _w, _h, GVAR(dragRot),
                ([_targetIndex] call _fnc_cells) select 0, ([_sourceIndex] call _fnc_cells) select 0
            ] call FUNC(swapPlan);

            GVAR(dragRoom) set [_swapKey, _swapAnswer];
        };

        _swapAnswer params ["_swapWhy", "_swapPlan"];

        if (_swapPlan isEqualTo []) then {
            _reason = _swapWhy;
        } else {
            _reason = "";
            _swap = _swapPlan;
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

        // A backpack never goes into a backpack; the cells above are every other limit. Asked once per target.
        private _intoKey = format ["backpack|%1", _targetIndex];
        private _into = GVAR(dragRoom) get _intoKey;

        if (isNil "_into") then {
            _into = [_to, _entry] call EFUNC(storage,backpackIntoBackpack);
            GVAR(dragRoom) set [_intoKey, _into];
        };

        if (_into) exitWith {
            _reason = "NoBackpack";
        };

        // Into the soldier's own gear from outside it: what that makes of him, as many of a stack as the wheel
        // left (fnc_onMouseZ), worked out once per target and count.
        private _key = format ["hint|%1|%2", _targetIndex, GVAR(dragCount)];
        private _roomParts = GVAR(dragRoom) get _key;

        if (isNil "_roomParts") then {
            _roomParts = [];

            if (_toKit isEqualTo "" && {[_to] call FUNC(isOwnStorage)}) then {
                _roomParts = [([] call _fnc_mass) * ([_stack, _amount] select (_amount > 0)) / _stack] call _fnc_forecast;
            };

            GVAR(dragRoom) set [_key, _roomParts];
        };

        if (_roomParts isNotEqualTo []) then {
            _hintParts = _roomParts;
        };
    };

    // A swap says so, and with whom - not what the item would add to the soldier.
    if (_swap isNotEqualTo []) then {
        private _swapTile = (_target get "tiles") select (_swap select 0);

        _hintParts = [[format [LLSTRING(Hint_Swap), [_swapTile get "class"] call FUNC(itemName)], "accent"]];
    };

    GVAR(dragTarget) = ["grid", _targetIndex, _col, _row, _reason isEqualTo "", _reason, "", _place, objNull, _swap];

    // The footprint lies on the target's cells, clipped to the grid where the item would stick out.
    (_gridBoxes select _targetIndex) params ["", "_originX", "_originY"];

    private _left = (_col max 0) min ((_target get "cols") - 1);
    private _top = (_row max 0) min ((_target get "rows") - 1);
    private _right = ((_col + _w) min (_target get "cols")) max (_left + 1);
    private _bottom = ((_row + _h) min (_target get "rows")) max (_top + 1);
    private _clipRect = [_target, [_originX, _originY], _left, _top, _right - _left, _bottom - _top] call FUNC(spanRect);

    // A swap lies in the accent colour, on the cells of both tiles: the dragged one's new ones, here, and the
    // other tile's new ones, where the dragged one came from (in view of its column only).
    if (_swap isNotEqualTo []) then {
        [_clipRect, true, DRAG_FOOTPRINT_ALPHA, "accent"] call _fnc_show;

        (_gridBoxes select _sourceIndex) params [["_sourceVisible", []], ["_sourceX", 0], ["_sourceY", 0]];

        (_swap select 2) params ["_swapCol", "_swapRow", "", "_swapW", "_swapH"];

        private _swapRect = [_sourceGrid, [_sourceX, _sourceY], _swapCol, _swapRow, _swapW, _swapH] call FUNC(spanRect);

        // Cut to what its column shows: the grid may be scrolled partly or wholly out of sight.
        if (_sourceVisible isNotEqualTo []) then {
            _sourceVisible params ["_visibleX", "_visibleY", "_visibleW", "_visibleH"];
            _swapRect params ["_rectX", "_rectY", "_rectW", "_rectH"];

            private _left = _rectX max _visibleX;
            private _top = _rectY max _visibleY;
            private _right = (_rectX + _rectW) min (_visibleX + _visibleW);
            private _bottom = (_rectY + _rectH) min (_visibleY + _visibleH);

            _swapRect = [_left, _top, (_right - _left) max 0, (_bottom - _top) max 0];
        };

        if ((_swapRect select 2) > 0 && {(_swapRect select 3) > 0}) then {
            private _accent = GVAR(theme) getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];

            _swapFootprint ctrlSetPosition _swapRect;
            _swapFootprint ctrlSetBackgroundColor [_accent select 0, _accent select 1, _accent select 2, DRAG_FOOTPRINT_ALPHA];
            _swapFootprint ctrlCommit 0;
            _swapFootprint ctrlShow true;
        };
    } else {
        [_clipRect, _reason isEqualTo ""] call _fnc_show;
    };

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

        private _color = if (_swap isNotEqualTo []) then {
            GVAR(theme) getOrDefault ["accent", [0.84, 0.54, 0.1, 1]]
        } else {
            if (_reason isEqualTo "") then {
                GVAR(theme) getOrDefault ["gain", [0.298, 0.765, 0.541, 1]]
            } else {
                GVAR(theme) getOrDefault ["loss", [0.941, 0.333, 0.353, 1]]
            }
        };

        if (
            count _clipHoles < _clipW * _clipH
            && {[[_clipRect select 0, _clipRect select 1], [_clipW, _clipH, _clipHoles], _color, [_target, _left, _top]] call _fnc_paintShape}
        ) then {
            _footprint ctrlShow false;
        };
    };
};

if (_timed) then {
    _marks pushBack ["target", diag_tickTime];
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

if (_timed) then {
    _marks pushBack ["hint", diag_tickTime];
    call _fnc_noteTime;
};
