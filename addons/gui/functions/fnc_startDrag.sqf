#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Lifts what was pressed on (GVAR(press)) - a tile, or the item in an equipment slot: its picture
 * follows the mouse as a ghost (fnc_makeGhost), a tile fades where it lay, and a footprint shows where
 * it would land (fnc_updateDrag) - green where it fits, red where not.
 *
 * A stack goes whole, half with Shift; the mouse wheel changes how many (fnc_onMouseZ), the middle
 * button takes all of it again. R turns what is held (fnc_rotateDrag). The hint says so meanwhile.
 *
 * On a tile of a selection of several, all of them are lifted together (GVAR(dragGroup)): whole stacks, no
 * turning, no wheel, the grabbed tile's picture at the mouse and a footprint for each tile. On any other
 * tile the selection becomes that tile alone, as for a single item it always was.
 *
 * A tile a move under way takes from (GVAR(inFlight), fnc_drawPending) is not lifted at all. A tile of a
 * source grid (a row of ACE's list in the Arsenal panel, "source") is lifted as the entry it brings along ("dragEntry"), one
 * at a time, a whole stack with Shift; a press that recorded a click only (fnc_onMouseButton) lifts nothing.
 *
 * Nothing is lifted that could go nowhere: a living person's item or slot the player may not touch
 * (fnc_checkTouch) stays, and the hint says why - also out of a kit lying in their gear
 * (einv_compat_efak_fnc_checkTouch), and a kit lying in the gear another living player wears
 * (einv_compat_efak_fnc_checkTile).
 *
 * What is picked up sounds like what it is (fnc_playSound "lift": a rifle, a magazine, a vest ...).
 *
 * Right away the weight card previews what it would add (fnc_previewWeight) - before the ghost is made,
 * which has to stay the last control.
 * The key help in the hint is kept as GVAR(dragKeys): fnc_updateDrag writes it back whenever the target has
 * nothing to say (fnc_dragHint). The comparison card at the mouse goes while something is held.
 *
 * The item, as an entry, is kept in uiNamespace (dragEntry): a tile's entry holds its controls.
 * Footprint first, ghost second: created controls draw over earlier ones, and the ghost belongs on top - as long
 * as no other control has the focus (fnc_takeFocus).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_gui_fnc_startDrag;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

private _start = diag_tickTime;

GVAR(press) params ["_gridIndex", "_tileIndex", "", "", "", "_slotSource", "", ["_shift", false]];

// A press that recorded a click only - on a free cell, an empty slot, nothing (fnc_onMouseButton, for the
// window that attached) - has nothing to lift.
if (_tileIndex < 0 && {_slotSource isEqualTo []}) exitWith {
    GVAR(press) = [];
};

// A tile of a source grid (a row of ACE's list in the Arsenal panel) is a place things come from: what is dragged is the
// entry the tile brings along ("dragEntry"), else the tile itself.
private _sourceGrid = if (_slotSource isEqualTo []) then {(uiNamespace getVariable [QGVAR(grids), []]) param [_gridIndex, createHashMap]} else {createHashMap};
private _fromSource = (_sourceGrid getOrDefault ["source", ""]) isNotEqualTo "";

private _pressed = if (_slotSource isEqualTo []) then {(_sourceGrid getOrDefault ["tiles", []]) param [_tileIndex, createHashMap]} else {createHashMap};

private _entry = if (_slotSource isEqualTo []) then {
    if (_fromSource) then {_pressed getOrDefault ["dragEntry", _pressed]} else {_pressed}
} else {
    _slotSource call EFUNC(storage,getSlot)
};

// ACRE2's dummy radio stays in its slot (einv_compat_acre): not lifted at all.
if (
    _slotSource isNotEqualTo []
    && {!isNil QEFUNC(compat_acre,isFixedSlot)}
    && {[_slotSource select 0, _slotSource select 1] call EFUNC(compat_acre,isFixedSlot)}
) exitWith {
    GVAR(press) = [];
};

if (count _entry == 0) exitWith {
    GVAR(press) = [];
};

// A tile on its way somewhere stays where it is until the answer came (fnc_drawPending flags it): lifted
// again, it would be asked for twice. Looked up in the moves under way as well - a kit's window drawn on
// its own since the last build has its tiles unflagged.
private _pending = _slotSource isEqualTo [] && {!_fromSource} && {
    _entry getOrDefault ["pending", false] || {
        private _grid = (uiNamespace getVariable [QGVAR(grids), []]) param [_gridIndex, createHashMap];
        private _holder = _grid getOrDefault ["holder", objNull];
        private _source = [_entry getOrDefault ["key", ""], _entry getOrDefault ["block", 0], _entry getOrDefault ["col", 0], _entry getOrDefault ["row", 0]];
        private _found = false;

        // A HashMap: _x is the request id, _y its record - its sources first.
        {
            if (((_y param [0, []]) findIf {
                _x params [["_fromHolder", objNull], ["_fromKey", ""], ["_fromBlock", 0], ["_fromCol", 0], ["_fromRow", 0]];
                _fromHolder isEqualTo _holder && {[_fromKey, _fromBlock, _fromCol, _fromRow] isEqualTo _source}
            }) >= 0) exitWith {
                _found = true;
            };
        } forEach GVAR(inFlight);

        // And those waiting for the hands (fnc_queueMoves).
        if (!_found) then {
            _found = GVAR(handQueue) findIf {
                (_x getOrDefault ["sources", []]) findIf {
                    _x params [["_fromHolder", objNull], ["_fromKey", ""], ["_fromBlock", 0], ["_fromCol", 0], ["_fromRow", 0]];
                    _fromHolder isEqualTo _holder && {[_fromKey, _fromBlock, _fromCol, _fromRow] isEqualTo _source}
                } >= 0
            } >= 0;
        };

        _found
    }
};

if (_pending) exitWith {
    GVAR(press) = [];
};

// A living person's gear the player may only look at, or who is out of reach by now - also a kit lying
// in it, and another living player's kit, which stays where it is (einv_compat_efak).
private _why = switch (true) do {
    // Nothing to touch: a source grid is no living person's.
    case (_fromSource): {""};
    case (_slotSource isEqualTo []): {
        private _grid = (uiNamespace getVariable [QGVAR(grids), []]) param [_gridIndex, createHashMap];
        private _kit = _grid getOrDefault ["kit", ""];
        private _container = _grid getOrDefault ["container", objNull];

        if (_kit isNotEqualTo "" && {!isNil QEFUNC(compat_efak,checkTouch)}) then {
            [_kit] call EFUNC(compat_efak,checkTouch)
        } else {
            private _reason = [_container, "items"] call FUNC(checkTouch);

            if (_reason isEqualTo "" && {!isNil QEFUNC(compat_efak,checkTile)}) then {
                _reason = [_entry getOrDefault ["class", ""], _container] call EFUNC(compat_efak,checkTile);
            };

            _reason
        }
    };
    default {[_slotSource select 0, "worn"] call FUNC(checkTouch)};
};

// Several selected tiles and this is one of them: all go together. The same rules hold for each - a
// living person's gear the player may not touch stays where it is.
private _group = [];

if (_slotSource isEqualTo [] && {call FUNC(isInventoryMode)}) then {
    private _selected = call FUNC(selectionTiles);

    if (count _selected >= 2 && {[_gridIndex, _tileIndex] in _selected}) then {
        _group = _selected;

        if (_why isEqualTo "") then {
            {
                private _groupGrid = (uiNamespace getVariable [QGVAR(grids), []]) param [_x select 0, createHashMap];
                private _groupContainer = _groupGrid getOrDefault ["container", objNull];
                private _groupWhy = [_groupContainer, "items"] call FUNC(checkTouch);

                // Another living player's kit stays where it is, as for a single tile (einv_compat_efak).
                if (_groupWhy isEqualTo "" && {!isNil QEFUNC(compat_efak,checkTile)}) then {
                    private _groupTile = (_groupGrid getOrDefault ["tiles", []]) param [_x select 1, createHashMap];

                    _groupWhy = [_groupTile getOrDefault ["class", ""], _groupContainer] call EFUNC(compat_efak,checkTile);
                };

                if (_groupWhy isNotEqualTo "") exitWith {
                    _why = _groupWhy;
                };
            } forEach _selected;
        };
    };
};

if (_why isNotEqualTo "") exitWith {
    GVAR(press) = [];
    [_why] call FUNC(flashHint);
};

// The name at the mouse and the comparison card go first: the selection drawn below would make them again
// over its frames (fnc_raiseTooltip) just to have them hidden a moment later.
(uiNamespace getVariable [QGVAR(tooltip), controlNull]) ctrlShow false;

ctrlDelete (uiNamespace getVariable [QGVAR(compare), controlNull]);
uiNamespace setVariable [QGVAR(compare), controlNull];
uiNamespace setVariable [QGVAR(tipShown), controlNull];

// The hover outline of the tile lifted goes: the footprint shows where it would land (fnc_updateHover looks
// again when the drag ends, fnc_endDrag).
if ((GVAR(hover) param [0, ""]) isEqualTo "tile") then {
    {ctrlDelete _x} forEach (uiNamespace getVariable [QGVAR(hoverRing), []]);
    uiNamespace setVariable [QGVAR(hoverRing), []];
};

// Any other tile: the selection is that tile alone (drawn again only when that changes it).
if (_group isEqualTo [] && {_slotSource isEqualTo []} && {call FUNC(isInventoryMode)}) then {
    [_gridIndex, _tileIndex, "only"] call FUNC(select);
};

GVAR(dragGroup) = _group;
uiNamespace setVariable [QGVAR(dragGhosts), []];

// What each target has to say is worked out once per drag, when the mouse comes to it (fnc_updateDrag); the
// weight of what is held is the first of it (fnc_previewWeight).
GVAR(dragRoom) = createHashMap;
GVAR(pageHover) = [];

// The frames before it are written first (fnc_logFrame), so the drag line stands beside its own.
[""] call FUNC(logFrame);

private _footprint = [_display, "EINV_PanelRect", controlNull, [0, 0, 0, 0]] call FUNC(uiCreate);
_footprint ctrlShow false;

private _stack = _entry getOrDefault ["count", 1];

GVAR(dragSize) = [_entry getOrDefault ["w", 1], _entry getOrDefault ["h", 1]];
GVAR(dragRot) = parseNumber (_entry getOrDefault ["rotated", false]);

// A tile in a single slot has the slot's size (einv_storage_fnc_getLayout "single"): lifted it is its own size again.
if (_entry getOrDefault ["single", false]) then {
    GVAR(dragSize) = (([_entry getOrDefault ["class", ""]] call EFUNC(items,getInfo)) getOrDefault ["size", [1, 1]]) select [0, 2];
    GVAR(dragRot) = 0;
};
GVAR(dragCount) = [_stack, (floor (_stack / 2)) max 1] select (_shift && {_stack > 1} && {_group isEqualTo []});

// Held by its middle, wherever it was pressed: the picture centres on the mouse and the footprint is worked out
// from there (fnc_updateDrag) - the middle cell is what a group keeps its arrangement by (fnc_groupMode).
GVAR(press) set [3, [floor ((GVAR(dragSize) select 0) / 2), floor ((GVAR(dragSize) select 1) / 2)]];

// From a source grid the count starts at the tile's own number (one, for a row of ACE's list) and Shift takes the
// whole stack - the wheel and the middle button change it as for any stack.
if (_fromSource) then {
    GVAR(dragCount) = [((_pressed getOrDefault ["dragStart", 1]) max 1) min _stack, _stack] select _shift;
};
GVAR(middleHeld) = inputMouse 2 > 0;

uiNamespace setVariable [QGVAR(dragEntry), _entry];
uiNamespace setVariable [QGVAR(dragFootprint), _footprint];

// The other tile's footprint, shown where the drop would swap the two (fnc_swapPlan, fnc_updateDrag): one
// control, made here so it lies under the ghost as the footprint does. A group or a slot's item never swaps.
private _swapFootprint = controlNull;

if (_group isEqualTo [] && {_slotSource isEqualTo []}) then {
    _swapFootprint = [_display, "EINV_PanelRect", controlNull, [0, 0, 0, 0]] call FUNC(uiCreate);
    _swapFootprint ctrlShow false;
};

uiNamespace setVariable [QGVAR(dragSwapFootprint), _swapFootprint];

// Several tiles: a footprint for each, made before the ghost (which lies over them), and every tile
// fades where it lay.
uiNamespace setVariable [QGVAR(dragFootprints), []];

// They show only where the tiles keep their arrangement (fnc_groupMode), which they do only when they all lie
// in one compartment - from several there is nothing to keep, and neither footprints nor shapes are made for them.
private _keepable = _group isNotEqualTo [] && {(_group findIf {(_x select 0) != ((_group select 0) select 0)}) < 0};

if (_keepable) then {
    private _footprints = [];

    for "_i" from 1 to (count _group min 150) do {
        private _more = [_display, "EINV_PanelRect", controlNull, [0, 0, 0, 0]] call FUNC(uiCreate);

        _more ctrlShow false;
        _footprints pushBack _more;
    };

    uiNamespace setVariable [QGVAR(dragFootprints), _footprints];
};

// A shaped item (size=xx/x-) shows its footprint on its own cells (fnc_shapeRects, fnc_updateDrag): the
// controls for them, made here so they lie under the ghost as the footprint does - as many as it needs
// held either way round, for a group as many as its shaped tiles need as they lie.
private _shapeCount = 0;

if (_group isEqualTo []) then {
    private _shapeInfo = [_entry getOrDefault ["class", ""]] call EFUNC(items,getInfo);

    {
        if ((_x param [2, []]) isNotEqualTo []) then {
            _shapeCount = _shapeCount max count ([[0, 0], 1, 1, _x] call FUNC(shapeRects));
        };
    } forEach [_shapeInfo getOrDefault ["footprint", [1, 1, []]], _shapeInfo getOrDefault ["footprintTurned", [1, 1, []]]];
} else {
    if (!_keepable) exitWith {};

    {
        _x params ["_shapeGrid", "_shapeTile"];

        private _tile = (((uiNamespace getVariable [QGVAR(grids), []]) param [_shapeGrid, createHashMap]) getOrDefault ["tiles", []]) param [_shapeTile, createHashMap];
        private _tileHoles = _tile getOrDefault ["holes", []];

        if (_tileHoles isNotEqualTo []) then {
            _shapeCount = _shapeCount + count ([[0, 0], 1, 1, [_tile get "w", _tile get "h", _tileHoles]] call FUNC(shapeRects));
        };
    } forEach (_group select [0, 150]);
};

private _shapes = [];

for "_i" from 1 to _shapeCount do {
    private _shape = [_display, "EINV_PanelRect", controlNull, [0, 0, 0, 0]] call FUNC(uiCreate);

    _shape ctrlShow false;
    _shapes pushBack _shape;
};

uiNamespace setVariable [QGVAR(dragShapes), _shapes];

// The footprint of one item where it reaches a corner of its compartment's panel is round there (fnc_updateDrag, fnc_uiSurface): two
// strips and four quarter circles that make the box up with the footprint control itself, made here so they lie under the ghost as it
// does. Hidden until a target needs them. A group's footprints keep to squares.
private _roundPieces = [];

if (_group isEqualTo []) then {
    for "_i" from 1 to 2 do {
        _roundPieces pushBack ([_display, "EINV_PanelRect", controlNull, [0, 0, 0, 0]] call FUNC(uiCreate));
    };

    {
        private _piece = [_display, "EINV_PanelCorner", controlNull, [0, 0, 0, 0]] call FUNC(uiCreate);

        _piece ctrlSetText _x;
        _roundPieces pushBack _piece;
    } forEach [UI_TEX(corner_tl_ca), UI_TEX(corner_tr_ca), UI_TEX(corner_bl_ca), UI_TEX(corner_br_ca)];

    {_x ctrlShow false} forEach _roundPieces;
};

uiNamespace setVariable [QGVAR(dragCorners), _roundPieces];

// The slots that take it light up - under the ghost, which comes last. Several tiles go into no slot; a
// worn item lights up the same slot of the unit it may be exchanged with.
if (_group isEqualTo []) then {
    [_display, _entry, _slotSource] call FUNC(showTargets);
};

// What it would add to the soldier, on the weight card.
if (_group isEqualTo []) then {
    [_display, _entry, GVAR(dragCount), true] call FUNC(previewWeight);
};

[_display] call FUNC(makeGhost);

// What lies on top while something is held: the engine draws a focused control over every other, and the one
// that took the press - a button in a column's group - would put its column over the ghost and the footprint
// (fnc_onFrame takes it back every frame as well).
[_display] call FUNC(takeFocus);

{
    _x ctrlSetFade DRAG_SOURCE_FADE;
    _x ctrlCommit 0;
} forEach (_entry getOrDefault ["controls", []]);

{
    private _faded = ((uiNamespace getVariable [QGVAR(grids), []]) param [_x select 0, createHashMap]) getOrDefault ["tiles", []];

    {
        _x ctrlSetFade DRAG_SOURCE_FADE;
        _x ctrlCommit 0;
    } forEach ((_faded param [_x select 1, createHashMap]) getOrDefault ["controls", []]);
} forEach _group;

// Where every column and every kit window's body stands: while a stack is held the wheel counts, and
// they stay put (fnc_updateDrag) - but for their edges, where they scroll with what is held while they
// lie on top there. Each with its layer, as fnc_topAt names it: "" for a column, a window's key.
private _scroll = [];

// The columns this window built. A window that attached has scrolling groups of its own that stay across
// builds, so every scrolling group of the display counts for it.
private _groups = if (call FUNC(isInventoryMode)) then {
    uiNamespace getVariable [QGVAR(created), []]
} else {
    (allControls _display) select {ctrlType _x == 15 && {!isNil {_x getVariable QGVAR(contentH)}}}
};

{
    if (!isNull _x && {ctrlType _x == 15} && {!(call FUNC(isInventoryMode)) || {(_x getVariable [QGVAR(column), ""]) isNotEqualTo ""}}) then {
        _scroll pushBack [_x, ((ctrlScrollValues _x) select 0) max 0, ""];
    };
} forEach _groups;

{
    private _body = _x getOrDefault ["body", controlNull];

    if (!isNull _body) then {
        _scroll pushBack [_body, ((ctrlScrollValues _body) select 0) max 0, _x getOrDefault ["key", ""]];
    };
} forEach (uiNamespace getVariable [QGVAR(windows), []]);

uiNamespace setVariable [QGVAR(dragScroll), _scroll];

// What the keys and the wheel do now, in the hint.
private _hint = uiNamespace getVariable [QGVAR(hint), controlNull];

if (!isNull _hint) then {
    private _rotateKey = call FUNC(rotateKeyName);
    private _parts = [[], [format [LLSTRING(Hint_Rotate), _rotateKey]]] select (_rotateKey isNotEqualTo "");

    if (_stack > 1) then {
        _parts append [LLSTRING(Hint_Amount), LLSTRING(Hint_All)];
    };

    // A box with pages on the window: Page Up / Page Down carry the item to another page (fnc_onKeyDown).
    if ((uiNamespace getVariable [QGVAR(grids), []]) findIf {count (_x getOrDefault ["pageRanges", []]) > 1} >= 0) then {
        _parts pushBack LLSTRING(Hint_Pages);
    };

    // Several tiles: no turning, whole stacks.
    if (_group isNotEqualTo []) then {
        _parts = [LLSTRING(Hint_GroupDrag)];
    };

    GVAR(dragKeys) = [[_parts joinString "    ", "text2"]];
    GVAR(dragHintShown) = [];

    [GVAR(dragKeys)] call FUNC(dragHint);
};

GVAR(dragging) = true;
GVAR(dragTarget) = [];

// What was picked up sounds like what it is (fnc_playSound): a rifle like a rifle, a magazine like a magazine.
["lift", _entry getOrDefault ["class", ""], _sourceGrid getOrDefault ["container", objNull]] call FUNC(playSound);

// For the tester's numbers (einv_gui_debugTiming): the lift up to its first frame, then each frame of the drag
// (fnc_updateDrag) - [lift ms, frames, their ms together, the slowest frame's ms, what its parts took, how many
// worked the target out anew], written as one line when it ends (fnc_endDrag).
if (missionNamespace getVariable [QGVAR(debugTiming), false]) then {
    GVAR(dragRoom) set ["timing", [(diag_tickTime - _start) * 1000, 0, 0, -1, "", 0]];
};

[_display, getMousePosition] call FUNC(updateDrag);
