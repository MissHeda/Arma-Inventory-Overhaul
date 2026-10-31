#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The player's overflow sweep, when it is due (fnc_sweepTick): everything in the uniform, vest or backpack that lies on
 * no cell - a script, ACE's pick-up, another mod's action, a loadout added it beyond the grid - first goes to
 * another worn container with free cells, else onto the ground next to the player, with a short hint
 * ("No room for X - put on the ground"). The engine takes such an add (the config load allows it), the grid has no
 * cell for it, and it would stay as a lone tile outside the grid for ever.
 *
 * Only the player's own unit: never an AI, a body, a crate or a vehicle - their overflow stays as it is. Not at
 * all with the setting aio_storage_migrate off, and never while the player is in the middle of moving something:
 * an arsenal is open, a tile is dragged or waits in the hands' queue, a move of the window is under way
 * (fnc_sweepBusy), or a worn container was swapped a minute ago (fnc_wornHeld: only some of them, and only until
 * something new comes in; a new unit's first sweep ignores that). It looks again a moment later instead (fnc_queueSweep), and after the time a loadout needs for its top-up
 * and its places (fnc_onLoadoutSet).
 *
 * One look per due time: the overflow of the unit's containers (fnc_getLayout), and then, in this order,
 *  1. some of it has a free cell in another worn container - uniform, vest, backpack, the ones after its own
 *     first, then the ones before it (fnc_migratePasses), a compartment with a slot for its category first (fnc_plan):
 *     op "migrate" with "wide", a silent request on the unit as root, which runs at once here. The look is asked
 *     again SWEEP_AGAIN seconds later; after three asks that moved nothing the rest goes to the ground.
 *  2. the rest goes onto the ground: one transaction, a "take" of each tile at the unit (at most SWEEP_MAX) and
 *     a "putGround" at the server with the take's payload as its input - the same two phases as a drag out of
 *     the window, so the server finds the pile at the feet or makes one, and a tile that could not be put down
 *     settles back where it came from (fnc_settle): nothing is lost or doubled. The pile is the dropper's own
 *     (what he put there he knows, aio_gui_fnc_learn), so it opens at once in the Ground section.
 *
 * Not while seated (a drop goes into the vehicle's cargo there, which may be full and bounce everything back) and
 * not with nothing under the feet (swimming, falling): looked at again SWEEP_BLOCKED seconds later. Nothing goes onto the
 * ground before the same overflow was seen twice running, SWEEP_AGAIN apart (a layout read while places are still
 * arriving can show a tile without a cell that has one). A pass that put nothing down holds the next one back
 * (SWEEP_FAIL seconds, longer each time), so a pile that cannot take it is not tried every second - that hold is the
 * ground's only, a move into a free cell of another worn container still runs at once.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * A request was made <BOOL>
 *
 * Example:
 * [] call aio_storage_fnc_requestSweep;
 *
 * Public: No
 */

private _unit = player;
private _now = diag_tickTime;

// One RPT line per new verdict on the player's overflow (issue #23): why a tile on no cell stays where it is. Only
// written when the verdict or the overflow changed, so a tile that waits a minute leaves one line, not hundreds.
private _fnc_trace = {
    params ["_verdict", ["_classes", []]];

    private _line = format ["%1 %2", _verdict, _classes];

    if (_line isNotEqualTo GVAR(sweepTrace)) then {
        GVAR(sweepTrace) = _line;

        INFO_1("Overflow sweep: %1",_line);
    };
};

if (is3DEN || {!hasInterface} || {isNull _unit} || {!alive _unit} || {!(_unit isKindOf "CAManBase")}) exitWith {false};

// Off: nothing is swept, as before.
if !(missionNamespace getVariable [QGVAR(migrate), true]) exitWith {false};

// A loadout was just set, a unit just arrived: its top-up and its places come first.
if (_now < GVAR(sweepNotBefore)) exitWith {
    ["waits for a loadout's top-up"] call _fnc_trace;

    [GVAR(sweepNotBefore) - _now] call FUNC(queueSweep);

    false
};

// A pass is still under way (its answer clears this).
if (GVAR(sweepRunning) > _now) exitWith {
    ["waits for the last pass"] call _fnc_trace;

    [SWEEP_BUSY] call FUNC(queueSweep);

    false
};

// In the middle of something.
if ([] call FUNC(sweepBusy)) exitWith {
    [format ["busy (arsenal %1, window %2)", ARSENAL_OPEN, !isNull (uiNamespace getVariable [QEGVAR(gui,display), displayNull])]] call _fnc_trace;

    [SWEEP_BUSY] call FUNC(queueSweep);

    false
};

// A worn container swapped lately: the others stay as they are, and nothing is put on the ground because of it.
private _held = [_unit] call FUNC(wornHeld);

if (_held > 0 && {!GVAR(sweepFresh)}) exitWith {
    [format ["held %1 s after a swapped container", round _held]] call _fnc_trace;

    [_held + SWEEP_DELAY] call FUNC(queueSweep);

    false
};

GVAR(sweepFresh) = false;

// Uniform, vest, backpack - those the unit has. getSections also marks each with its unit, which the compartments
// depend on (fnc_getOwner).
private _containers = ([_unit] call FUNC(getSections)) apply {_x get "container"};

// What lies on no cell of each (a tile in Strict mode's hidden holder is none of this).
private _strictOver = [];
private _over = _containers apply {
    private _all = ([_x, [_x] call FUNC(getContents)] call FUNC(getLayout)) getOrDefault ["overflow", []];

    {
        if (_x getOrDefault ["strict", false]) then {
            _strictOver pushBack (_x getOrDefault ["class", ""]);
        };
    } forEach _all;

    _all select {!(_x getOrDefault ["strict", false])}
};

if (_over findIf {_x isNotEqualTo []} < 0) exitWith {
    GVAR(sweepFails) = 0;
    GVAR(sweepMigrates) = 0;
    GVAR(sweepOverSeen) = "";
    GVAR(sweepSeen) = "";

    // Nothing on no cell as the sweep sees it - while the window may show a red tile (issue #23); Strict mode's
    // hidden tiles on no cell are not the sweep's and are named.
    [format ["sees no overflow (%1 worn containers, Strict tiles on no cell %2)", count _containers, _strictOver]] call _fnc_trace;

    false
};

// What lies on no cell, by class and count: the asks to move it count up while it stays the same, and start again
// when it changed (something new came in, something left). The count is not reset when the look goes on to the
// ground, so a move that keeps finding a cell it then cannot take is not asked for again and again for ever.
private _overPrint = str (_over apply {_x apply {[_x getOrDefault ["class", ""], _x getOrDefault ["count", 1]]}});

if (_overPrint isNotEqualTo GVAR(sweepOverSeen)) then {
    GVAR(sweepOverSeen) = _overPrint;
    GVAR(sweepMigrates) = 0;
};

// ----- 1. Another worn container with a free cell -----

private _movable = false;

{
    _x params ["_fromIndex", "_toIndices"];

    private _list = _over select _fromIndex;

    if (_list isEqualTo []) then {continue};

    private _targets = _toIndices apply {[_containers select _x, _unit]};

    if ((([_list, _targets] call FUNC(plan)) select 0) isNotEqualTo []) exitWith {
        _movable = true;
    };
} forEach ([count _containers, true] call FUNC(migratePasses));

private _classes = _over apply {_x apply {_x getOrDefault ["class", ""]}};

if (_movable && {GVAR(sweepMigrates) < 3}) exitWith {
    GVAR(sweepMigrates) = GVAR(sweepMigrates) + 1;

    [format ["move %1 into another worn container", GVAR(sweepMigrates)], _classes] call _fnc_trace;

    [[[_unit, [["migrate", [_unit, true]]]]], {}, [], true, _unit] call FUNC(request);

    [SWEEP_AGAIN] call FUNC(queueSweep);

    true
};

// ----- 2. The ground -----

// A pass that put nothing down a moment ago holds back the next one (only this step: moves into a free cell
// above are never held by it).
if (_now < GVAR(sweepQuiet)) exitWith {
    [format ["ground held %1 s, a free cell %2", round (GVAR(sweepQuiet) - _now), _movable], _classes] call _fnc_trace;

    [GVAR(sweepQuiet) - _now] call FUNC(queueSweep);

    false
};

// Seated, a drop would go into the vehicle's cargo; with nothing under the feet it would hang in the air; a
// client whose server has not answered its greeting has nowhere to hand the tile to (fnc_hubReady).
if (!isNull objectParent _unit || {([_unit] call FUNC(groundPos)) isEqualTo []} || {!([] call FUNC(hubReady))}) exitWith {
    [format ["ground blocked (seated %1, hub %2)", !isNull objectParent _unit, [] call FUNC(hubReady)], _classes] call _fnc_trace;

    GVAR(sweepQuiet) = _now + SWEEP_BLOCKED;

    [SWEEP_BLOCKED] call FUNC(queueSweep);

    false
};

// Seen twice running before anything goes onto the ground: a layout read while the places are still arriving (a
// joining player, a loadout) or a move is half done can show a tile without a cell that has one. The same overflow
// and the same revisions half a second later is the real thing. Right after a pass that put something down the
// state was just confirmed, and the next tiles of a long list go at once.
private _print = str [
    _over apply {_x apply {[_x getOrDefault ["class", ""], _x getOrDefault ["count", 1]]}},
    _containers apply {([_x] call FUNC(readPlaces)) select 0}
];

if (_now >= GVAR(sweepTrusted) && {_print isNotEqualTo GVAR(sweepSeen)}) exitWith {
    GVAR(sweepSeen) = _print;

    [SWEEP_AGAIN] call FUNC(queueSweep);

    false
};

GVAR(sweepSeen) = "";

[format ["onto the ground, a free cell %1", _movable], _classes] call _fnc_trace;

// A few tiles at a time, the unit's own order: uniform, vest, backpack.
private _takes = [];
private _puts = [];
private _tiles = [];
private _more = 0;

{
    private _container = _containers select _forEachIndex;

    {
        if (count _tiles < SWEEP_MAX) then {
            _takes pushBack ["take", [_container, [_x] call FUNC(entryToArray), -1]];
            _puts pushBack ["putGround", [["#ref", 0, count _tiles, 0]]];
            _tiles pushBack [_x getOrDefault ["class", ""], _x getOrDefault ["count", 1]];
        } else {
            _more = _more + 1;
        };
    } forEach _x;
} forEach _over;

GVAR(sweepRunning) = _now + SWEEP_TIMEOUT;

private _id = [[[_unit, _takes], [objNull, _puts]], {
    params ["", "_summary", "", "_args"];
    _args params ["_unit", "_tiles", "_more"];

    GVAR(sweepRunning) = 0;

    // Per op of the second phase, [status, extra]: "" and the pile for each tile that lay down.
    private _results = ((_summary param [0, []]) param [1, []]);
    private _landed = [];

    {
        _x params [["_status", "Failed", [""]], ["_extra", []]];

        if (_status isEqualTo "") then {
            private _pile = if (_extra isEqualType []) then {_extra param [0, objNull]} else {objNull};

            _landed pushBack [_tiles param [_forEachIndex, ["", 1]], _pile];
        };
    } forEach _results;

    if (_landed isEqualTo []) then {
        private _statuses = _results apply {_x param [0, ""]};

        INFO_1("Overflow sweep: nothing lay on the ground %1",_statuses);

        // Nothing lay down (the server would not, the unit moved on): the next try waits, longer each time.
        GVAR(sweepFails) = GVAR(sweepFails) + 1;
        GVAR(sweepQuiet) = diag_tickTime + ((SWEEP_FAIL * GVAR(sweepFails)) min SWEEP_FAIL_MAX);
    } else {
        GVAR(sweepFails) = 0;
        GVAR(sweepQuiet) = 0;
        GVAR(sweepTrusted) = diag_tickTime + SWEEP_TRUST;
    };

    private _names = [];

    {
        _x params ["_tile", "_pile"];

        private _class = _tile select 0;

        // What you put somewhere you know is there: a pile you dropped onto opens to you at once (aio_gui).
        if (_pile isEqualType objNull && {!isNull _pile} && {!isNil QEFUNC(gui,learn)}) then {
            [_pile, _class, 1] call EFUNC(gui,learn);
        };

        _names pushBackUnique (([_class] call EFUNC(items,getInfo)) getOrDefault ["name", _class]);
    } forEach _landed;

    if (_names isNotEqualTo []) then {
        private _text = (_names select [0, 2]) joinString ", ";

        if (count _names > 2) then {
            _text = format ["%1 +%2", _text, count _names - 2];
        };

        INFO_2("No room for %1 - put on the ground (%2 tiles).",_text,count _landed);

        [format [LLSTRING(Hint_NoRoomGround), _text]] call FUNC(useHint);
    };

    // More than one pass held, or a tile that did not lie down: looked at again.
    if (_more > 0 || {count _landed < count _tiles}) then {
        [SWEEP_AGAIN] call FUNC(queueSweep);
    };
}, [_unit, _tiles, _more], false, _unit] call FUNC(request);

if (_id isEqualTo "") then {
    GVAR(sweepRunning) = 0;
};

_id isNotEqualTo ""
