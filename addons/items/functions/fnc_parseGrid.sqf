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
 *   1x2:ammo+1x1:grenade:one+6x4
 *                 - attributes after a compartment's colon. A list of categories (weapon, ammo, grenade, gear,
 *                   medical, food, tool, misc - ITEM_GROUPS, joined with |) means the compartment accepts only
 *                   items in one of them: "2x2:ammo|grenade" takes magazines and grenades and nothing else; no
 *                   list takes everything. The word "one" makes it a single slot: it holds one tile whatever
 *                   its size, and the item takes the whole slot ("1x1:grenade:one", the vest's grenade loop).
 *                   On a canvas each letter has its own, "aab/aab:a=ammo:b=grenade|one". A compartment without
 *                   attributes is written as it always was, so no older text changes. A rig:16 pattern, a
 *                   number of cells or a share cannot carry any: they say nothing about single compartments.
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
 *              compartment's top left cell on its canvas, [] for one that flows; and for a compartment with
 *              attributes two more: accepts, the categories it takes ([] for all of them), and single, true
 *              for a slot of one item of any size (fnc_blocksFor, einv_storage_fnc_blockMode). A compartment
 *              without attributes has the four only; [] when the text cannot be read <ARRAY>
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

// What follows a compartment's geometry after a colon is its attributes: "6x4:ammo|grenade" accepts only those
// categories, "1x1:grenade:one" holds one item of any size, and on a canvas each letter has its own, "aab/aab:a=ammo:b=one".
// A pattern's colon (rig:16) is not one. Taken apart here, so everything below reads the geometry alone, as it always did;
// _tails holds, per piece, the tokens after its colons.
private _tails = [];

if (_colon >= 0 && {!(_name in GRID_PATTERNS)}) then {
    private _cores = [];

    {
        private _at = _x find ":";

        _cores pushBack ([_x, _x select [0, _at]] select (_at >= 0));
        _tails pushBack ([[], (_x select [_at + 1]) splitString ":"] select (_at >= 0));
    } forEach (_value splitString "+");

    if (_cores findIf {_x isEqualTo ""} >= 0) then {
        _messages pushBack format ["'%1' is no grid: after a compartment may come :categories or :one, not before it", _value];
        _value = "";
        _tails = [];
    } else {
        _value = _cores joinString "+";
    };
};

// The attributes of one piece: letter ("" for a piece without a canvas) -> [accepts, single]. A category is one of
// ITEM_GROUPS, "one" says one item of any size; "a=" in front names the compartment of a canvas.
private _fnc_attrs = {
    params ["_pieceTails"];

    private _map = createHashMap;

    {
        private _token = _x;
        private _letter = "";

        if ((_token select [1, 1]) isEqualTo "=") then {
            _letter = _token select [0, 1];
            _token = _token select [2];
        };

        private _single = false;
        private _words = [];

        {
            if (_x in ["one", "single"]) then {
                _single = true;
            } else {
                _words pushBack _x;
            };
        } forEach (_token splitString "|");

        private _groups = [];

        if (_words isNotEqualTo []) then {
            ([_words joinString "|", "grid"] call FUNC(parseGroups)) params ["_found", "_notes", "_readable"];

            _messages append _notes;
            _groups = _found;
        };

        if (_groups isEqualTo [] && {!_single}) then {
            _messages pushBack format ["grid=%1: ':%2' says no category and not 'one' - left out", _value, _x];
            continue;
        };

        private _had = _map getOrDefault [_letter, [[], false]];

        _map set [_letter, [ITEM_GROUPS select {_x in (_had select 0) || {_x in _groups}}, (_had select 1) || _single]];
    } forEach _pieceTails;

    _map
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

            // The attributes of a block, [accepts, single], appended to it only when it has some: a grid without
            // them is exactly what it always was.
            private _fnc_extra = {
                params ["_block", "_attr"];

                _attr params [["_accepts", []], ["_single", false]];

                if (_accepts isEqualTo [] && {!_single}) exitWith {_block};

                _block + [_accepts, _single]
            };

            {
                private _attrs = [_tails param [_forEachIndex, []]] call _fnc_attrs;
                private _plain = _attrs getOrDefault ["", [[], false]];

                if (count _x <= 3) then {
                    _blocks pushBack ([[_x select 0, _x select 1, _x select 2, []], _plain] call _fnc_extra);
                    continue;
                };

                private _canvas = _x;

                if ((_canvas select 0) > STORAGE_COLS || {(_canvas select 1) > MAX_ROWS}) then {
                    _messages pushBack format ["grid=%1: a canvas is at most %2 across and %3 down - cut down", _value, STORAGE_COLS, MAX_ROWS];
                    _canvas = [_texts select _forEachIndex, STORAGE_COLS, MAX_ROWS, true] call FUNC(parseMask);
                };

                private _parts = _canvas param [3, []];
                private _letters = _canvas param [4, []];

                if ((_canvas select 0) < 1) then {continue};

                // A canvas of one compartment is only a shape: what its letter says counts as said of it, together with
                // anything said without a letter ("aa/a-:a=ammo" is "xx/x-:ammo").
                if (count _parts <= 1) then {
                    private _own = _attrs getOrDefault [_letters param [0, ""], [[], false]];
                    private _merged = [
                        ITEM_GROUPS select {_x in (_plain select 0) || {_x in (_own select 0)}},
                        (_plain select 1) || {_own select 1}
                    ];

                    _blocks pushBack ([[_canvas select 0, _canvas select 1, _canvas select 2, []], _merged] call _fnc_extra);
                    continue;
                };

                // Each compartment of the canvas has the attributes of its letter.
                private _lettered = [];

                {
                    _lettered pushBack ([_x, _attrs getOrDefault [_letters param [_forEachIndex, ""], [[], false]]] call _fnc_extra);
                } forEach _parts;

                // The flow keeps one canvas whole (einv_gui_fnc_flowCompartments); a second one has
                // nothing to say where it lies against the first.
                if (_canvases > 0) then {
                    if (_canvases == 1) then {
                        _messages pushBack format ["grid=%1: one canvas per grid - the compartments of the others flow on their own", _value];
                    };

                    _blocks append (_lettered apply {
                        [[_x select 0, _x select 1, _x select 2, []], [_x param [4, []], _x param [5, false]]] call _fnc_extra
                    });
                } else {
                    _blocks append _lettered;
                };

                _canvases = _canvases + 1;
            } forEach _pieces;

            if (_blocks findIf {(_x select 0) > STORAGE_COLS || {(_x select 1) > MAX_ROWS}} >= 0) then {
                _messages pushBack format ["grid=%1: a compartment is at most %2 across and %3 down - cut down", _value, STORAGE_COLS, MAX_ROWS];
                _blocks = _blocks apply {
                    if ((_x select 0) > STORAGE_COLS || {(_x select 1) > MAX_ROWS}) then {
                        [(_x call _fnc_cut) + [[]], [_x param [4, []], _x param [5, false]]] call _fnc_extra
                    } else {
                        _x
                    }
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

// Attributes need compartments written out: "auto:ammo" says nothing about which compartment.
if (_spec isNotEqualTo [] && {(_spec select 0) isNotEqualTo "blocks"} && {(_tails findIf {_x isNotEqualTo []}) >= 0}) then {
    _messages pushBack format ["grid=%1: :categories and :one go with compartments written out like 6x4:ammo - left out", _value];
};

[_spec, _messages]
