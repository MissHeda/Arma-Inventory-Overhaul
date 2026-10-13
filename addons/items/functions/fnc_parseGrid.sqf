#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads how a container is split into compartments, as "grid=" in the rules and the object variable
 * einv_grid write it. einv_storage_fnc_blocksFor lays a container out by the result.
 *
 *   auto          - by its load: maximum load / mass per cell cells, laid out the way its kind is
 *                   (pockets, pouches, one big compartment)
 *   24            - that many cells, laid out the same way, met exactly
 *   120%          - that share of what its load gives, 10 to 500 %
 *   rig, rig:16   - a pattern by name, with its cells from the load or given: pockets,
 *                   pockets_mixed, rig, mixed, plate, long, single, wide
 *   6x4+2x3+2x3   - the compartments exactly, each W cells across and H down
 *   xxxx/x--x+2x3 - a compartment may also be drawn as a shape: its rows from the top, separated by
 *                   "/", each the same length, "x" a cell and "-" a hole - a cell the compartment does
 *                   not have. Joined with "+" like the others, and mixed with them.
 *   abbbbbc/abbbbbc/abbbbbc/-bbbbb-
 *                 - a canvas: drawn the same way, but each cell carries the letter of its compartment,
 *                   "a" to "z" - cells of one letter are one compartment wherever they lie, "-" is
 *                   no cell. Its compartments stay exactly where they were drawn: here a column of three
 *                   either side of a 5x4 block, all at the top. "aaa/aba/aaa" is a ring of eight with a
 *                   cell of its own inside. Joined with "+" to the others, the canvas is one piece of
 *                   the flow, as wide and high as the box around it. One canvas per grid: the
 *                   compartments of a second one flow on their own, with a message.
 *
 * A shape is read to its smallest form (fnc_parseMask, which reads an item's size= the same way): rows
 * and columns at its edges that are only holes go, and a shape with no hole left is a plain WxH -
 * fnc_formatGrid writes it as 2x3 again. The separator is
 * "/" because it is the one character the rules already allow that reads as "next row"; a row can
 * never be empty, so "//" - which a cba_settings.sqf could take for a comment - is never part of a
 * grid.
 *
 * A canvas of a single row with no hole has nothing that tells it from a word, so there its
 * compartments are named a, b, c ... in the order they start, as fnc_formatGrid writes them: "aaabb"
 * is two compartments, while a pattern's name mistyped ("rigg") stays no grid.
 *
 * The compartments come in the order of the pieces; a canvas's own in reading order of each one's
 * first cell - the order the place records count them in (einv_storage_fnc_getLayout).
 *
 * Within limits: at most STORAGE_COLS across, MAX_ROWS down, MAX_BLOCKS compartments and MAX_CELLS
 * cells in all, holes not counted - the window makes a control per cell. A value past a limit is cut
 * down to it and said so in the messages (a shape or a canvas loses its columns and rows past the
 * limit); one that cannot be read, or a shape without a single cell, gives no spec at all.
 *
 * Arguments:
 * 0: Grid text <STRING>
 *
 * Return Value:
 * [spec, messages] <ARRAY>
 *   spec     - ["auto"], ["cells", N], ["percent", P], ["pattern", name, N or -1] or
 *              ["blocks", [[cols, rows, holes, pos], ...]] - holes the indices row * cols + col of
 *              the cells a shape does not have, ascending, [] for a full rectangle; pos [x, y] the
 *              compartment's top left cell on its canvas, [] for one that flows; [] when the text
 *              cannot be read <ARRAY>
 *   messages - what was cut down, or why it cannot be read <ARRAY of STRING>
 *
 * Example:
 * ["6x4+xxx/x-x"] call einv_items_fnc_parseGrid;
 * ["aaa/aba/aaa"] call einv_items_fnc_parseGrid; // [["blocks", [[3, 3, [4], [0, 0]], [1, 1, [], [1, 1]]]], []]
 *
 * Public: No
 */

params [["_text", "", [""]]];

private _value = toLowerANSI (trim _text);
private _messages = [];

// A whole number written out in digits, else -1.
private _fnc_whole = {
    params ["_digits"];

    if (_digits isEqualTo "" || {(toArray _digits) findIf {_x < 48 || {_x > 57}} >= 0}) exitWith {-1};

    parseNumber _digits
};

// A number of cells: at least one, at most MAX_CELLS.
private _fnc_cells = {
    params ["_cells"];

    if (_cells < 1) then {
        _messages pushBack format ["grid=%1: a container has at least one cell - read as 1", _value];
        _cells = 1;
    };

    if (_cells > MAX_CELLS) then {
        _messages pushBack format ["grid=%1: at most %2 cells - cut down", _value, MAX_CELLS];
        _cells = MAX_CELLS;
    };

    _cells
};

// A compartment cut down to STORAGE_COLS across and MAX_ROWS down. A shape is drawn again and read once
// more within those limits (fnc_formatMask, fnc_parseMask), so it comes out at its smallest as any
// other; with no cell left it is [0, 0, []] and left out.
private _fnc_cut = {
    params ["_cols", "_rows", "_holes"];

    if (_holes isEqualTo []) exitWith {[_cols min STORAGE_COLS, _rows min MAX_ROWS, []]};

    [[_cols, _rows, _holes] call FUNC(formatMask), STORAGE_COLS, MAX_ROWS] call FUNC(parseMask)
};

// Letters only, named a, b, c ... in the order they first appear - how a canvas of one row without a
// hole is told from a word.
private _fnc_inOrder = {
    params ["_piece"];

    private _codes = toArray _piece;
    private _next = 97;

    if (_codes isEqualTo [] || {_codes findIf {_x < 97 || {_x > 122}} >= 0}) exitWith {false};

    _codes findIf {
        if (_x == _next) then {_next = _next + 1};

        _x >= _next
    } < 0
};

private _colon = _value find ":";
private _name = _value;

if (_colon >= 0) then {
    _name = _value select [0, _colon];
};

// The last character, for a share like 120%.
private _last = "";

if (_value isNotEqualTo "") then {
    _last = _value select [count _value - 1];
};

private _spec = switch (true) do {
    case (_value isEqualTo ""): {
        _messages pushBack "an empty grid= says nothing";
        []
    };

    case (_value isEqualTo "auto"): {["auto"]};

    case ([_value] call _fnc_whole >= 0): {
        ["cells", [[_value] call _fnc_whole] call _fnc_cells]
    };

    // A "%" goes into the messages as an argument: in format's own text it could be taken for one.
    case (_last isEqualTo "%" && {[_value select [0, count _value - 1]] call _fnc_whole >= 0}): {
        private _percent = [_value select [0, count _value - 1]] call _fnc_whole;
        private _clamped = (_percent max PERCENT_MIN) min PERCENT_MAX;

        if (_clamped != _percent) then {
            _messages pushBack format ["grid=%1: a share is between %2 and %3 - cut to %4", _value, PERCENT_MIN, PERCENT_MAX, str _clamped + "%"];
        };

        ["percent", _clamped]
    };

    case (_name in GRID_PATTERNS): {
        if (_colon < 0) then {
            ["pattern", _name, -1]
        } else {
            private _cells = [_value select [_colon + 1]] call _fnc_whole;

            if (_cells < 0) then {
                _messages pushBack format ["'%1' is no grid: after the pattern's name comes a number of cells, like rig:16", _value];
                []
            } else {
                ["pattern", _name, [_cells] call _fnc_cells]
            };
        };
    };

    case (_value find "x" >= 0 || {_value find "-" >= 0} || {_value find "/" >= 0} || {(_value splitString "+") findIf {!([_x] call _fnc_inOrder)} < 0}): {
        // Compartments: each piece WxH, both at least 1, a shape or a canvas. A piece that cannot be
        // read is [-1, -1, error]; a canvas has its compartments fourth (fnc_parseMask).
        private _texts = _value splitString "+";
        private _pieces = _texts apply {
            if ((toArray _x) findIf {_x >= 48 && {_x <= 57}} < 0) then {
                private _shape = [_x, -1, -1, true] call FUNC(parseMask);

                if (count _shape > 3 && {_x find "/" < 0} && {_x find "-" < 0} && {!([_x] call _fnc_inOrder)}) then {
                    _shape = [-1, -1, "a canvas of one row names its compartments a, b, c ... in the order they start, like aab"];
                };

                _shape
            } else {
                private _cross = _x find "x";

                if (_cross < 0) then {
                    [-1, -1, ""]
                } else {
                    [[_x select [0, _cross]] call _fnc_whole, [_x select [_cross + 1]] call _fnc_whole, []]
                };
            };
        };

        private _bad = _pieces findIf {(_x select 0) < 1 || {(_x select 1) < 1}};

        if (_pieces isEqualTo [] || {_bad >= 0}) then {
            // A shape says what is wrong with it; a WxH piece holds its holes there, which are no words.
            private _why = if (_bad >= 0) then {(_pieces select _bad) select 2} else {""};

            if (!(_why isEqualType "") || {_why isEqualTo ""}) then {
                _why = "compartments are written like 6x4+2x3, drawn like xxx/x-x or laid out on a canvas like aab/acc, each at least one cell";
            };

            _messages pushBack format ["'%1' is no grid: %2", _value, _why];
            []
        } else {
            // The pieces as compartments, [cols, rows, holes, pos]: a canvas gives its own where they
            // lie on it, a canvas of one compartment is only a shape. A canvas past the limits is read
            // again within them, from its top left part.
            private _blocks = [];
            private _canvases = 0;

            {
                if (count _x <= 3) then {
                    _blocks pushBack [_x select 0, _x select 1, _x select 2, []];
                    continue;
                };

                private _canvas = _x;

                if ((_canvas select 0) > STORAGE_COLS || {(_canvas select 1) > MAX_ROWS}) then {
                    _messages pushBack format ["grid=%1: a canvas is at most %2 across and %3 down - cut down", _value, STORAGE_COLS, MAX_ROWS];
                    _canvas = [_texts select _forEachIndex, STORAGE_COLS, MAX_ROWS, true] call FUNC(parseMask);
                };

                private _parts = _canvas param [3, []];

                if ((_canvas select 0) < 1) then {continue};

                if (count _parts <= 1) then {
                    _blocks pushBack [_canvas select 0, _canvas select 1, _canvas select 2, []];
                    continue;
                };

                // The flow keeps one canvas whole (einv_gui_fnc_flowCompartments); a second one has
                // nothing to say where it lies against the first.
                if (_canvases > 0) then {
                    if (_canvases == 1) then {
                        _messages pushBack format ["grid=%1: one canvas per grid - the compartments of the others flow on their own", _value];
                    };

                    _blocks append (_parts apply {[_x select 0, _x select 1, _x select 2, []]});
                } else {
                    _blocks append _parts;
                };

                _canvases = _canvases + 1;
            } forEach _pieces;

            if (_blocks findIf {(_x select 0) > STORAGE_COLS || {(_x select 1) > MAX_ROWS}} >= 0) then {
                _messages pushBack format ["grid=%1: a compartment is at most %2 across and %3 down - cut down", _value, STORAGE_COLS, MAX_ROWS];
                _blocks = _blocks apply {
                    if ((_x select 0) > STORAGE_COLS || {(_x select 1) > MAX_ROWS}) then {(_x call _fnc_cut) + [[]]} else {_x}
                };
            };

            if (count _blocks > MAX_BLOCKS) then {
                _messages pushBack format ["grid=%1: at most %2 compartments - the rest are left out", _value, MAX_BLOCKS];
                _blocks resize MAX_BLOCKS;
            };

            // Whole compartments only: the ones past MAX_CELLS cells in all are left out. A shape that
            // lost all its cells to a cut is left out the same way.
            private _total = 0;
            private _kept = [];

            {
                _x params ["_cols", "_rows", "_holes"];

                private _cells = _cols * _rows - count _holes;

                _total = _total + _cells;

                if (_total > MAX_CELLS) exitWith {
                    _messages pushBack format ["grid=%1: at most %2 cells in all - the compartments past that are left out", _value, MAX_CELLS];
                };

                if (_cells > 0) then {
                    _kept pushBack _x;
                };
            } forEach _blocks;

            // What is left of a canvas starts at its top left corner; one compartment left of it is
            // only a shape, which flows - read and written again, the text stays the same.
            private _placed = _kept select {(_x select 3) isNotEqualTo []};

            if (count _placed == 1) then {
                (_placed select 0) set [3, []];
            };

            if (count _placed > 1) then {
                private _minX = selectMin (_placed apply {(_x select 3) select 0});
                private _minY = selectMin (_placed apply {(_x select 3) select 1});

                {
                    (_x select 3) params ["_posX", "_posY"];

                    _x set [3, [_posX - _minX, _posY - _minY]];
                } forEach _placed;
            };

            if (_kept isEqualTo []) then {[]} else {["blocks", _kept]};
        };
    };

    default {
        _messages pushBack format ["'%1' is no grid: auto, a number of cells, a share like %3, a pattern (%2) or compartments like 6x4+2x3, xxx/x-x or aab/acc", _value, GRID_PATTERNS joinString ", ", "120%"];
        []
    };
};

[_spec, _messages]
