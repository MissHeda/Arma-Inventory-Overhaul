#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The compartments a container of a class gets, Tarkov-like: not one grid as big as its load, but
 * pockets and pouches of their own sizes. An item has to fit into one of them, so what a container
 * takes depends on its shape, not only on its weight - a rig of magazine pouches takes magazines, not
 * a helmet. Works on the class alone, so the setup wizard can show a container nobody carries;
 * fnc_getBlocks finds what to ask for a real one. What a container gets is worked out from the load
 * alone, never from its name: two containers with the same load look the same.
 *
 * The grid spec (einv_items_fnc_parseGrid, as the rules or einv_grid give it):
 *   ["auto"]                 - maximum load / mass per cell cells, laid out by the kind's pattern
 *   ["cells", N]             - N cells, the same way
 *   ["percent", P]           - P % of what the load gives
 *   ["pattern", name, N]     - a pattern by name; N cells, or from the load when N is -1
 *   ["blocks", [[c, r, holes, pos], ..]] - the compartments exactly; holes and pos may be left out
 *                            for none
 *
 * The patterns, and which a kind takes when none is named:
 *   uniform  - block: one compartment UNIFORM_COLS wide, as many rows as the load asks for, UNIFORM_ROWS_MIN to
 *              UNIFORM_ROWS_MAX of them - 6x2 for a plain uniform, a row or two more for one that carries more
 *   vest     - pouches: [1x2, 2x2] one after the other, magazine pouches as a real rig has them, as many as the
 *              load asks for, at most VEST_POUCHES_MAX
 *   backpack - single: one big compartment, as near square as STORAGE_COLS columns allow
 *   kit      - single as well: a kit or pouch of Enhanced First Aid Kits is a bag of one space
 *   anything else (crates, vehicles) - wide: one compartment STORAGE_COLS wide
 * Named by a rule they are also pockets [1x2] or pockets_mixed [1x1, 1x2], at most six from the load, and for a
 * vest rig [1x2], mixed [1x2, 1x2, 1x1, 1x1], plate [2x2, 1x2, 1x2] or long [1x3, 1x2, 1x1], at most sixteen.
 *
 * A number that was given (N cells, einv_grid = "24", einv_slots) is met exactly: as many pockets or
 * pouches as it takes, and the last pouch or the last, unfilled row cut down to what is left. One from
 * the load is only a rough measure, so there the limits hold and the last pouch or row may be bigger
 * than needed.
 * Either way at most MAX_CELLS cells and MAX_BLOCKS compartments: a given number that MAX_BLOCKS
 * pouches cannot cover gets MAX_BLOCKS - 2 of them and what is left as rows STORAGE_COLS wide.
 *
 * Arguments:
 * 0: Class - the uniform's or vest's item class, the backpack's, crate's or vehicle's own <STRING>
 * 1: Kind: "uniform", "vest", "backpack", "kit", or anything else for one wide compartment <STRING>
 * 2: Maximum load <NUMBER>
 * 3: Grid spec <ARRAY> (default: ["auto"])
 * 4: Config mass per cell <NUMBER> (default: the rules in effect)
 *
 * Return Value:
 * Compartments [[cols, rows, holes, pos], ...] - holes the indices row * cols + col of the cells a
 * shaped compartment does not have (einv_items_fnc_parseGrid), [] for a full rectangle, which every
 * pattern gives; pos [x, y] the cell its top left corner lies on, on the canvas it was drawn on (grid=
 * aab/acc), [] for one the window flows - every pattern's. In the order the place records count them:
 * the canvas's in reading order of each one's first cell. Every compartment keeps cells of its own,
 * numbered from its own top left corner, wherever it is drawn. [[STORAGE_COLS, 0, [], []]] when there
 * are no cells <ARRAY>
 *
 * Example:
 * ["V_PlateCarrier1_rgr", "vest", 80, ["pattern", "rig", 20]] call einv_storage_fnc_blocksFor;
 *
 * Public: No
 */

params [
    ["_class", "", [""]],
    ["_kind", "crate", [""]],
    ["_maxLoad", 0, [0]],
    ["_spec", ["auto"], [[]]],
    ["_cell", -1, [0]]
];

_spec params [["_mode", "auto", [""]]];

// Compartments given exactly - a copy, the spec is shared. The older table and einv_grids[] give
// rectangles as [cols, rows]: everyone reads four, and whoever only wants three still finds them first.
if (_mode isEqualTo "blocks") exitWith {
    (_spec select 1) apply {[_x select 0, _x select 1, +(_x param [2, []]), +(_x param [3, []])]}
};

if (_cell <= 0) then {
    _cell = (call EFUNC(items,currentRules)) getOrDefault ["cell", 5];
};

// The patterns: pouches, how many at most from the load, and how they are laid out.
private _patterns = createHashMapFromArray [
    ["pouches", [[[1, 2], [2, 2]], VEST_POUCHES_MAX]],
    ["pockets", [[[1, 2]], 6]],
    ["pockets_mixed", [[[1, 1], [1, 2]], 6]],
    ["rig", [[[1, 2]], 16]],
    ["mixed", [[[1, 2], [1, 2], [1, 1], [1, 1]], 16]],
    ["plate", [[[2, 2], [1, 2], [1, 2]], 16]],
    ["long", [[[1, 3], [1, 2], [1, 1]], 16]]
];

private _pattern = switch (_kind) do {
    case "uniform": {"block"};
    case "vest": {"pouches"};
    case "backpack";
    case "kit": {"single"};
    default {"wide"};
};

// What the load gives, rough.
private _fromLoad = ceil ((_maxLoad max 0) / (_cell max 1));
private _cells = _fromLoad;
private _given = false;

switch (_mode) do {
    case "cells": {
        _cells = _spec select 1;
        _given = true;
    };
    case "percent": {
        _cells = ceil ((_maxLoad max 0) * (_spec select 1) / 100 / (_cell max 1));
    };
    case "pattern": {
        _pattern = _spec select 1;

        if ((_spec param [2, -1]) > 0) then {
            _cells = _spec select 2;
            _given = true;
        };
    };
};

if (_cells <= 0) exitWith {[[STORAGE_COLS, 0, [], []]]};

// Never more than MAX_CELLS cells, whatever the kind - a typo or a huge load would otherwise build a
// control for each of thousands of cells.
_cells = _cells min MAX_CELLS;

// One compartment _cols wide for _count cells. A number that was given and leaves the last row
// unfilled gets that row as a compartment of its own, only as long as what is left - and no
// full-width one when there is not even one full row.
private _fnc_rows = {
    params ["_cols", "_count"];

    if (!_given || {_count mod _cols == 0}) exitWith {[[_cols, ceil (_count / _cols)]]};

    [[_cols, floor (_count / _cols)], [_count mod _cols, 1]] select {(_x select 1) > 0}
};

// Pouches after a pattern, round and round, until the cells are covered or there are _limit of them:
// [compartments, cells they cover]. With a number that was given, the last pouch is cut down to what
// is left, so the container has exactly that many cells.
private _fnc_pouches = {
    params ["_pouches", "_limit"];

    private _blocks = [];
    private _covered = 0;
    private _index = 0;

    while {_covered < _cells && {count _blocks < _limit}} do {
        private _block = +(_pouches select (_index mod count _pouches));
        private _left = _cells - _covered;

        // Bigger than what is left: as wide as it was if that width divides the rest, else one column.
        if (_given && {(_block select 0) * (_block select 1) > _left}) then {
            _block = [[1, _left], [_block select 0, _left / (_block select 0)]] select (_left mod (_block select 0) == 0);
        };

        _blocks pushBack _block;
        _covered = _covered + (_block select 0) * (_block select 1);
        _index = _index + 1;
    };

    [_blocks, _covered]
};

// A number that was given lifts the pattern's limit - every pouch is at least one cell, so _cells of
// them always cover it - up to MAX_BLOCKS pouches, so whatever those cover comes out as it always
// did. Only when even they do not cover it are there two pouches fewer, and what is left below them
// as rows STORAGE_COLS wide.
private _fnc_fill = {
    params ["_pouches", "_limit"];

    if (_given) then {_limit = _cells};

    ([_pouches, _limit min MAX_BLOCKS] call _fnc_pouches) params ["_blocks", "_covered"];

    if (_given && {_covered < _cells}) then {
        ([_pouches, _limit min (MAX_BLOCKS - 2)] call _fnc_pouches) params ["_fewer", "_fewerCovered"];

        _blocks = _fewer + ([STORAGE_COLS, _cells - _fewerCovered] call _fnc_rows);
    };

    _blocks
};

// A pattern's compartments are full rectangles that flow: no holes, no place of their own.
(switch (_pattern) do {
    case "single": {
        [(ceil sqrt _cells) min STORAGE_COLS, _cells] call _fnc_rows
    };
    // A uniform: UNIFORM_COLS wide, and from the load as many rows as it asks for - at least two, at most five.
    // A number that was given is met exactly instead, row after row.
    case "block": {
        if (_given) then {
            [UNIFORM_COLS min STORAGE_COLS, _cells] call _fnc_rows
        } else {
            [[UNIFORM_COLS min STORAGE_COLS, ((ceil (_cells / UNIFORM_COLS)) max UNIFORM_ROWS_MIN) min UNIFORM_ROWS_MAX]]
        }
    };
    case "wide": {
        [STORAGE_COLS, _cells] call _fnc_rows
    };
    default {
        (_patterns getOrDefault [_pattern, [[[1, 2]], 16]]) params ["_pouches", "_limit"];

        [_pouches, _limit] call _fnc_fill
    };
}) apply {[_x select 0, _x select 1, [], []]}
