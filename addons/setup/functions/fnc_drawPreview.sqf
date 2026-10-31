#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * "This is how it looks": what an editor's canvas (fnc_uiCanvas) gives, the way the inventory draws it -
 * on the inventory's panel, in its cells, a pixel apart.
 *   - A container's compartments laid out as the inventory lays them out (aio_gui_fnc_flowCompartments):
 *     side by side as far as STORAGE_COLS cells reach, a gap between two, then on the next line - and the
 *     ones of a canvas where they were drawn, with the seam's room opened where two of them touch, so
 *     the painted compartments read as the blocks they are.
 *   - Each compartment on its own panel behind its cells, as aio_gui_fnc_drawCompartments draws it: the
 *     theme's card, COMPARTMENT_PAD_PX past the cells, round as far as the corner cells stay inside, a
 *     shaped one's holes left open (aio_gui_fnc_uiShape "panel").
 *   - Every cell the same size with the same gap to the next, whichever compartment it belongs to: the
 *     cell is a whole number of pixels and so is every offset, so no cell comes out a pixel wider than
 *     its neighbour and no gap a pixel wider than another. A canvas that its seams make wider than the
 *     card gets smaller cells, all of them alike, rather than being cut.
 *   - An item's tile on a piece of grid: its surface on its cells only (aio_gui_fnc_uiShape), its
 *     picture over its box, as a tile is drawn.
 * The one routine for Paint and Blocks alike: the same cell, gap and flow for the same compartments, so
 * the two ways give the same picture for the same configuration (fnc_canvasBlocks hands over a painted
 * layout that lies as the flow would put it without places, the Blocks way never has any).
 * Drawn again on its own after a click on the canvas: it replaces the one drawn before
 * (uiNamespace QGVAR(preview)).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Position [x, y, w, h], relative to the group <ARRAY>
 * 3: Theme <HASHMAP>
 * 4: Compartments [[cols, rows, holes, pos, accepts, single], ...] - the last two where a compartment takes only some categories or is a single
 *    slot (its category's picture is drawn faintly in its middle); for an item its shape alone, [] for none <ARRAY>
 * 5: For an item [picture, category, class, icon]; [] for a container <ARRAY> (default: [])
 *    With a class, the tile is drawn for it, by the icon and the picture given ([scale, across, down], the
 *    one being edited, not the draft's); without, its shape and picture only
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _box, [0.2, 0.1, 0.2, 0.2], _theme, [[2, 2, [3]]], [_picture, 2]] call aio_setup_fnc_drawPreview;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", ["_theme", createHashMap, [createHashMap]], ["_blocks", [], [[]]], ["_item", [], [[]]]];

ctrlDelete (uiNamespace getVariable [QGVAR(preview), controlNull]);

_rect params ["", "", "_width", "_height"];

private _group = [_display, "AIO_ScrollGroup", _parent, _rect] call EFUNC(gui,uiCreate);

uiNamespace setVariable [QGVAR(preview), _group];

private _cellColor = +(_theme getOrDefault ["cell", [1, 1, 1, 0.05]]);

// The inventory's cells are faint on its own panel; on the editor's card they would all but vanish.
_cellColor set [3, (_cellColor param [3, 0.05]) max 0.09];

// On whole pixels, as the cells are: a pad between two pixels would put every cell on a pixel's edge.
private _padY = round (UNIT * 0.35 / pixelH) * pixelH;
private _padX = SQUARE(_padY);
private _areaW = _width - _padX * 2 - SCROLL_W;

if (_item isNotEqualTo []) exitWith {
    _item params [["_picture", ""], ["_category", CATEGORY_MISC], ["_class", ""], ["_icon", ICON_PLAIN]];

    (_blocks param [0, [0, 0, []]]) params ["_w", "_h", ["_holes", []]];

    // A piece of grid a cell wider than the tile all round, as wide as it fits - and, where there is room, with
    // the cell the inventory has, so the tile is as big here as it is there.
    private _gridCols = STORAGE_COLS min ((_w max 1) + 2);
    private _gridRows = (_h max 1) + 2;
    private _largest = if (_class isNotEqualTo "") then {([] call EFUNC(gui,getCell)) select 1} else {UNIT * 0.8};
    private _cellPixels = (floor (((_largest min ((_height - _padY * 2) / _gridRows)) min (_areaW / _gridCols * pixelH / pixelW)) / pixelH)) max 1;
    private _cellH = _cellPixels * pixelH;
    private _cellW = _cellPixels * pixelW;
    private _cells = [];

    // How wide the piece of grid came out: what is beside it starts there (fnc_drawItemEditor).
    uiNamespace setVariable [QGVAR(previewDrawnW), _padX * 2 + _gridCols * _cellW];

    [
        _display, _group, [0, 0, _padX * 2 + _gridCols * _cellW, _padY * 2 + _gridRows * _cellH],
        _theme getOrDefault ["panel", [0.05, 0.05, 0.05, 0.92]], (_theme getOrDefault ["radius", 0]) min (UNIT * 0.3)
    ] call EFUNC(gui,uiPanel);

    for "_row" from 0 to (_gridRows - 1) do {
        for "_col" from 0 to (_gridCols - 1) do {
            _cells pushBack (([_display, _group, [_padX + _col * _cellW, _padY + _row * _cellH, _cellW - pixelW, _cellH - pixelH], _cellColor] call EFUNC(gui,uiPanel)) param [0, controlNull]);
        };
    };

    if (_w < 1) exitWith {};

    // The tile of the inventory itself, on this piece of grid: the cells under it make way for it as they do there.
    if (_class isNotEqualTo "") exitWith {
        private _grid = createHashMapFromArray [
            ["parent", _group], ["rel", [_padX, _padY]], ["cols", _gridCols], ["rows", _gridRows], ["cellW", _cellW], ["cellH", _cellH],
            ["cells", _cells], ["holes", []], ["tiles", []], ["section", ""]
        ];

        // A magazine full, as a tile in a container shows it, and one alone.
        private _capacity = ([_class] call EFUNC(items,getInfo)) getOrDefault ["capacity", 0];

        private _entry = createHashMapFromArray [
            ["class", _class], ["col", parseNumber (_w + 2 <= STORAGE_COLS)], ["row", 1], ["w", _w], ["h", _h], ["holes", _holes], ["count", 1],
            ["ammo", _capacity], ["icon", _icon], ["preview", true]
        ];

        // The picture being picked, not the class's own yet.
        if (_picture isNotEqualTo "") then {
            _entry set ["picture", _picture];
        };

        [_display, _grid, _entry, _theme] call EFUNC(gui,createTile);
    };

    private _origin = [_padX + ([_cellW, 0] select (_w + 2 > STORAGE_COLS)), _padY + _cellH];
    private _tileBg = (_theme getOrDefault ["tileBg", []]) param [_category, [0.15, 0.15, 0.15, 0.92]];

    if !(_tileBg isEqualType []) then {
        _tileBg = [0.15, 0.15, 0.15, 0.92];
    };

    [_display, _group, _origin, _cellW, _cellH, [_w, _h, _holes], _tileBg] call EFUNC(gui,uiShape);

    if (_picture isNotEqualTo "") then {
        [_display, _group, [_origin select 0, _origin select 1, _w * _cellW - pixelW, _h * _cellH - pixelH], _picture] call EFUNC(gui,uiPicture);
    };
};

// A container: the compartments where the inventory puts them, as large as fits across - the seams of a
// canvas may make it wider than STORAGE_COLS cells (aio_gui_fnc_flowCompartments says how wide).
private _cellPixels = (floor (((UNIT * 0.85) min (_areaW / (STORAGE_COLS + 0.5) * pixelH / pixelW)) / pixelH)) max 1;
private _layout = createHashMapFromArray [["blocks", _blocks]];
private _flow = [_layout, [_cellPixels * pixelW, _cellPixels * pixelH]] call EFUNC(gui,flowCompartments);

// Too wide: the cell that fits as near as the seams' rounding to pixels allows, then a pixel less until it does.
if ((_flow select 2) > _areaW) then {
    _cellPixels = (floor (_cellPixels * _areaW / (_flow select 2))) max 1;
    _flow = [_layout, [_cellPixels * pixelW, _cellPixels * pixelH]] call EFUNC(gui,flowCompartments);

    while {_cellPixels > 1 && {(_flow select 2) > _areaW}} do {
        _cellPixels = _cellPixels - 1;
        _flow = [_layout, [_cellPixels * pixelW, _cellPixels * pixelH]] call EFUNC(gui,flowCompartments);
    };
};

_flow params ["_places", "_contentH", "_contentW"];

private _cellH = _cellPixels * pixelH;
private _cellW = _cellPixels * pixelW;

[
    _display, _group, [0, 0, (_padX * 2 + (_contentW max (STORAGE_COLS * _cellW))) min (_width - SCROLL_W), (_padY * 2 + _contentH) max (UNIT * 1)],
    _theme getOrDefault ["panel", [0.05, 0.05, 0.05, 0.92]], (_theme getOrDefault ["radius", 0]) min (UNIT * 0.3)
] call EFUNC(gui,uiPanel);

// The compartments' panels, as the inventory draws them (aio_gui_fnc_drawCompartments): the card, the pad
// past the cells, round up to three times the pad.
private _pad = COMPARTMENT_PAD_PX(_cellW);
private _padW = _pad * pixelW;
private _padH = _pad * pixelH;
private _radius = (_theme getOrDefault ["radius", 0]) min (_pad * 3 * pixelH);
private _panelColor = _theme getOrDefault ["card", [1, 1, 1, 0.045]];

if (_panelColor isEqualTo []) then {
    _panelColor = _theme getOrDefault ["line", [1, 1, 1, 0.08]];
};

// Every panel first, then the cells: [corner x, corner y, w, h, holes, colX, rowY] per compartment drawn.
private _drawn = [];

{
    _x params ["_w", "_h", ["_holes", []]];

    private _place = _places param [_forEachIndex, []];

    if (_place isEqualTo [] || {_w <= 0} || {_h <= 0}) then {continue};

    // A canvas's compartment brings where its columns and rows start; a flowed one has the plain pitch.
    _place params ["_left", "_top", ["_colX", []], ["_rowY", []]];

    if (count _colX != _w) then {
        _colX = [];

        for "_col" from 0 to (_w - 1) do {
            _colX pushBack (_col * _cellW);
        };
    };

    if (count _rowY != _h) then {
        _rowY = [];

        for "_row" from 0 to (_h - 1) do {
            _rowY pushBack (_row * _cellH);
        };
    };

    private _x0 = _padX + _left;
    private _y0 = _padY + _top;

    if (_holes isEqualTo []) then {
        [
            _display, _group,
            [_x0 - _padW, _y0 - _padH, (_colX select (_w - 1)) + _cellW - pixelW + _padW * 2, (_rowY select (_h - 1)) + _cellH - pixelH + _padH * 2],
            _panelColor, _radius
        ] call EFUNC(gui,uiPanel);
    } else {
        [
            _display, _group, [_x0, _y0], _cellW, _cellH, [_w, _h, _holes], _panelColor, "panel", _pad,
            [createHashMapFromArray [["colX", _colX], ["rowY", _rowY]], 0, 0]
        ] call EFUNC(gui,uiShape);
    };

    _drawn pushBack [_x0, _y0, _w, _h, _holes, _colX, _rowY, _x param [4, []], _x param [5, false]];
} forEach _blocks;

// The picture the class's compartments show (show=, the Containers step's Picture row; aio_gui_fnc_drawBadge).
private _previewClass = GVAR(selection) getOrDefault ["containers", ""];
private _previewShow = if (_previewClass isEqualTo "") then {""} else {
    ([_previewClass, GVAR(draftRules)] call EFUNC(items,getInfo)) getOrDefault ["show", ""]
};

{
    _x params ["_x0", "_y0", "_w", "_h", "_holes", "_colX", "_rowY", "_accepts", "_single"];

    for "_row" from 0 to (_h - 1) do {
        for "_col" from 0 to (_w - 1) do {
            if ((_row * _w + _col) in _holes) then {continue};

            [_display, _group, [_x0 + (_colX select _col), _y0 + (_rowY select _row), _cellW - pixelW, _cellH - pixelH], _cellColor] call EFUNC(gui,uiPanel);
        };
    };

    // A compartment that takes only some categories shows the first one's picture, large and faint in its middle, as the empty
    // one does in the inventory (aio_gui_fnc_drawBadge); a single slot a little stronger.
    private _texture = "";

    if (_accepts isNotEqualTo [] && {_previewShow isNotEqualTo "none"}) then {
        _texture = [[_accepts select 0, _previewShow] select (_previewShow in _accepts), GVAR(draftRules)] call EFUNC(gui,groupTexture);
    };

    // Small pictures of all of them in the corner instead.
    if (_previewShow isEqualTo "all") then {
        private _side = ((_cellW / pixelW) min (_cellH / pixelH)) * 0.42;
        private _pad = _side * 0.18;

        {
            [
                _display, _group, [_x0 + (_pad + _forEachIndex * (_side + _pad)) * pixelW, _y0 + _pad * pixelH, _side * pixelW, _side * pixelH],
                [_x, GVAR(draftRules)] call EFUNC(gui,groupTexture), [1, 1, 1, 0.4]
            ] call EFUNC(gui,uiPicture);
        } forEach _accepts;

        _texture = "";
    };

    if (_texture isNotEqualTo "") then {
        private _boxW = (_colX select (_w - 1)) + _cellW - pixelW;
        private _boxH = (_rowY select (_h - 1)) + _cellH - pixelH;
        private _sidePx = ((_boxW / pixelW) min (_boxH / pixelH)) * 0.6;
        private _side = [_sidePx * pixelW, _sidePx * pixelH];

        [
            _display, _group, [_x0 + (_boxW - (_side select 0)) / 2, _y0 + (_boxH - (_side select 1)) / 2, _side select 0, _side select 1], _texture, [1, 1, 1, [0.12, 0.2] select _single]
        ] call EFUNC(gui,uiPicture);
    };
} forEach _drawn;
