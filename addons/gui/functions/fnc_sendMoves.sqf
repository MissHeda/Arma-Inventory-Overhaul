#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Turns the window's moves into transactions (einv_storage_fnc_request) with this function's answer
 * (fnc_onAnswer): each move becomes its phases - within one root a move, between two roots a take at the
 * source and a put at the target, equipping and unequipping as take, putOn, takeOff and put, a kit
 * holder through its type's ops (einv_storage_holderTypes) -, at most BATCH_MAX moves per transaction,
 * the next chunk sent when the last one is answered.
 *
 * Phases on the same root follow each other where they can, so a crate emptied into own gear is one
 * phase of takes at the crate and one of puts here, not one pair per item. Nothing is changed here
 * before the authority did it: no record is written, no tile moves before the answer.
 *
 * "The ground" is the surface under the feet - the server finds or makes the pile (op putGround) -, or
 * the vehicle's cargo for a seated player. The old item of an equip goes back to the item's own cell;
 * out of a kit it goes into the kit where that kit takes it (einv_compat_efak_fnc_canPack), else into
 * the first of the player's own uniform, vest and backpack with room, else wherever settlement puts it.
 *
 * How the first three moves of a transaction will sound once they happened (fnc_feelFor) is kept with its record
 * in flight; the answer plays the first that went (fnc_afterAction, fnc_feelAnswer).
 *
 * Each transaction is recorded in flight (GVAR(inFlight)): its tiles fade and cannot be lifted, its
 * target cells are outlined (fnc_drawPending) until the answer and the places it names arrived. Left out
 * with a hint: a move into itself ("IntoItself"), a drop onto the ground on
 * foot with nothing under the feet ("NoGround"), anything that needs the server's hub before it answered
 * ("NotReady"), a holder whose root is not known ("Moved"), and a move into or out of a container that is
 * locked to the player ("Locked", einv_locks_fnc_canReach): the lock may have been set after the window
 * was built, or by a script; every op asks the lock again where it runs.
 *
 * Several tiles of one holder laid down at once (a group dragged within a compartment, or Take all
 * with the target already holding some of them) are one move of the kind "placeMany": op placeMany lifts
 * them all and puts them down together, so two never wait for each other's cells. It counts for as many
 * moves as it has tiles, but is never cut in two.
 *
 * Two tiles that swap places between two containers (a tile let go on another one, fnc_swapPlan) are one
 * move of the kind "exchange": take the first, take the second, put the first at the cell the second lay
 * on, put the second at the cell the first lay on - four steps in the phases of their roots, so each
 * root runs its own and nothing is put before it was taken. It has two records (one per tile), counts for
 * two moves and is never cut in two; within one container a swap is a "placeMany" of the two. A step
 * that does not go leaves its payload to settlement (back where it came from), so nothing is lost or
 * doubled.
 *
 * Arguments:
 * 0: Moves, each a HashMap <ARRAY>
 *    "kind"     - "move" (default), "equip", "unequip", "swap", "sort", "placeMany" or "exchange"
 *    "from"     - holder it lies in: a container, or a key like "kit:..." (einv_storage_holderTypes);
 *                 for "sort" the holder to sort
 *    "fromRoot" - its root, objNull to look it up (einv_storage_fnc_rootOf)
 *    "entry"    - the tile (move, equip) <HASHMAP>
 *    "count"    - how many of a stack, -1 for all of it (move; default -1)
 *    "to"       - holder it goes to, "ground" or "vehicle" (move, unequip); for an equip, where its old
 *                 item goes when the caller decided that (einv_compat_efak_fnc_equip) - left out, it is
 *                 decided here
 *    "toRoot"   - its root, objNull to look it up
 *    "cell"     - [col, row, compartment] - with [.., width, height] when it lies turned - or [] for the
 *                 first fit (move, unequip)
 *    "unit", "slot" - whose slot and which (equip: the player's, unequip: anybody's, swap: where it
 *                 comes off)
 *    "toUnit", "toSlot" - for "swap": the unit it goes onto and the slot there; what that unit wore
 *                 there comes back onto "unit" (fnc_doSwap)
 *    "tiles"    - for "placeMany": [[entry, cell], ...] in the holder "from"; a cell is [col, row,
 *                 compartment] or, turned, [col, row, compartment, width, height]
 *    "otherEntry", "otherCell" - for "exchange": the tile that lies in "to" and the cell in "from" it
 *                 goes to; "cell" is the cell "entry" goes to in "to" (both [col, row, compartment,
 *                 width, height, rot])
 *    "kit"      - the kit class an equip comes out of, for where its old item may go (default "")
 *    "order"    - for "sort": one of SORT_MODES, what the holder is laid out by (default "size", largest first)
 * 1: Options <HASHMAP> (default: empty)
 *    "flash" - light up where the moves landed once they did <BOOL> (default: true)
 *    "label" - a text the hint shows once everything went as asked <STRING> (default: "")
 *
 * Return Value:
 * Something was sent <BOOL>
 *
 * Example:
 * [[createHashMapFromArray [["from", _crate], ["to", backpackContainer player], ["entry", _tile]]]] call einv_gui_fnc_sendMoves;
 *
 * Public: No
 */

params [["_moves", [], [[]]], ["_options", createHashMap, [createHashMap]]];

if (_moves isEqualTo []) exitWith {false};

// The player the moves are made for - also once the window closed, should a chain of moves go on.
private _unit = GVAR(unit);

if (isNull _unit) then {
    _unit = missionNamespace getVariable ["ACE_player", objNull];
};

private _vehicle = objectParent _unit;
private _own = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit] select {!isNull _x};
private _ready = call EFUNC(storage,hubReady);
private _types = EGVAR(storage,holderTypes);
private _groundPos = false;

// The root of a holder: given, the player for the player's own gear, a unit for its slots, else the
// storage's answer - a uniform, vest or backpack opened from inside another with where it was opened.
private _fnc_rootOf = {
    params ["_holder", ["_given", objNull]];

    if (!isNull _given) exitWith {_given};
    if (_holder isEqualType "") exitWith {[_holder] call EFUNC(storage,rootOf)};
    if (isNull _holder) exitWith {objNull};
    if (_holder isEqualTo _unit || {_holder in _own}) exitWith {_unit};
    if (_holder isKindOf "CAManBase") exitWith {_holder};

    private _index = GVAR(opened) findIf {(_x select 1) isEqualTo _holder};
    private _parent = if (_index < 0) then {objNull} else {(GVAR(opened) select _index) param [2, objNull]};

    [_holder, _parent] call EFUNC(storage,rootOf)
};

// Whether a move reaches into a container that is locked to the player - out of it or into it. People's
// gear and the player's own are never locked, a kit is left to its root (the guard asks there), and so are
// the ground and the vehicle, which are no containers of the window. The root a container was opened from
// counts: a backpack in a locked crate is as locked as the crate (einv_locks_fnc_canReach).
private _fnc_locked = {
    params ["_move"];

    private _locked = false;

    {
        _x params ["_holderKey", "_rootKey"];

        private _holder = _move getOrDefault [_holderKey, objNull];

        if (!(_holder isEqualType objNull) || {isNull _holder} || {_holder isEqualTo _unit} || {_holder in _own} || {_holder isKindOf "CAManBase"}) then {
            continue
        };

        private _root = [_holder, _move getOrDefault [_rootKey, objNull]] call _fnc_rootOf;

        if !(([_unit, _holder, [_root, objNull] select (_root isEqualTo _holder)] call EFUNC(locks,canReach)) select 0) exitWith {
            _locked = true;
        };
    } forEach [["from", "fromRoot"], ["to", "toRoot"]];

    _locked
};

// The op that does a kind of change to a holder: the storage's own for a container, the holder type's
// for a key ("kit:..." -> "kitTake" and so on) - the window never names another addon's op. "" when the
// type has none.
private _fnc_opName = {
    params ["_holder", "_kind"];

    if (_holder isEqualType objNull) exitWith {_kind};

    private _colon = _holder find ":";

    if (_colon < 1) exitWith {""};

    (_types getOrDefault [_holder select [0, _colon], createHashMap]) getOrDefault [_kind, ""]
};

// Where "the ground" is for this player: a seated player's is the vehicle's cargo, as in vanilla; on
// foot the surface under the feet - none (swimming, falling): nothing to put it on.
private _fnc_ground = {
    if (!isNull _vehicle) exitWith {_vehicle};

    // Asked once per call: every move of it is made from where the player stands now.
    if (_groundPos isEqualTo false) then {
        _groundPos = [_unit] call EFUNC(storage,groundPos);
    };

    ["", "ground"] select (_groundPos isNotEqualTo [])
};

// The steps of one move, each [root, op, args, role] - an arg ["#step", k, n] is the n-th payload step k
// produced -, as [why not or "", steps, where it lands]. No steps and no reason: nothing to do.
// Roles: "take" takes it out, "land" puts it where it goes, "old" is the put of an equip's old item.
private _fnc_moveSteps = {
    params ["_move"];

    private _from = _move getOrDefault ["from", objNull];
    private _to = _move getOrDefault ["to", objNull];
    private _entry = _move getOrDefault ["entry", createHashMap];
    private _count = _move getOrDefault ["count", -1];
    private _cell = _move getOrDefault ["cell", []];

    if (_from isEqualType objNull && {isNull _from}) exitWith {["Failed", []]};
    if (_to isEqualType objNull && {isNull _to}) exitWith {["Failed", []]};

    private _array = [_entry] call EFUNC(storage,entryToArray);
    private _fromRoot = [_from, _move getOrDefault ["fromRoot", objNull]] call _fnc_rootOf;
    private _take = [_from, "take"] call _fnc_opName;

    if (_take isEqualTo "") exitWith {["Failed", []]};
    if (isNull _fromRoot) exitWith {["Moved", []]};

    // The ground at the feet, or the vehicle's cargo while seated.
    if (_to isEqualType "" && {_to in ["ground", "vehicle"]}) exitWith {
        private _ground = call _fnc_ground;

        if (_ground isEqualTo "") exitWith {["NoGround", []]};

        if (_ground isEqualType objNull) exitWith {
            // Out of the vehicle's own cargo while seated in it: it is where "the ground" is already.
            if (_from isEqualTo _ground) exitWith {["", []]};

            ["", [
                [_fromRoot, _take, [_from, _array, _count], "take"],
                [_ground, "put", [_ground, ["#step", 0, 0], []], "land"]
            ], _ground]
        };

        ["", [
            [_fromRoot, _take, [_from, _array, _count], "take"],
            [objNull, "putGround", [["#step", 0, 0]], "land"]
        ], "ground"]
    };

    // Within one holder: only somewhere else, and only a whole tile - a container holds a class as one.
    if (_from isEqualTo _to) exitWith {
        if (_cell isEqualTo [] || {_count > 0 && {_count < (_entry getOrDefault ["count", 1])}}) exitWith {["", []]};

        private _place = [_from, "place"] call _fnc_opName;

        if (_place isEqualTo "") exitWith {["Failed", []]};

        ["", [[_fromRoot, _place, [_from, _array, _cell], "land"]], _to]
    };

    // A uniform, vest or backpack never goes into itself or into anything lying in it.
    private _inside = _entry getOrDefault ["container", objNull];

    if (!isNull _inside && {_to isEqualTo _inside || {[_to, _inside] call EFUNC(storage,liesIn)}}) exitWith {["IntoItself", []]};

    private _toRoot = [_to, _move getOrDefault ["toRoot", objNull]] call _fnc_rootOf;
    private _put = [_to, "put"] call _fnc_opName;

    if (_put isEqualTo "") exitWith {["Failed", []]};
    if (isNull _toRoot) exitWith {["Moved", []]};

    // Within one root: one step where both lie - containers by the storage's move, two kits of a type by
    // that type's own, anything else as a take and a put in the same phase.
    if (_fromRoot isEqualTo _toRoot) exitWith {
        if (_from isEqualType objNull && {_to isEqualType objNull}) exitWith {
            ["", [[_fromRoot, "move", [_from, _to, _array, _count, _cell], "land"]], _to]
        };

        private _between = [_from, "move"] call _fnc_opName;

        if (_from isEqualType "" && {_to isEqualType ""} && {_between isNotEqualTo ""} && {_between isEqualTo ([_to, "move"] call _fnc_opName)}) exitWith {
            ["", [[_fromRoot, _between, [_from, _to, _array, _count, _cell], "land"]], _to]
        };

        ["", [
            [_fromRoot, _take, [_from, _array, _count], "take"],
            [_toRoot, _put, [_to, ["#step", 0, 0], _cell], "land"]
        ], _to]
    };

    // Between two roots: out at the source's authority, in at the target's - each checked against its own.
    ["", [
        [_fromRoot, _take, [_from, _array, _count], "take"],
        [_toRoot, _put, [_to, ["#step", 0, 0], _cell], "land"]
    ], _to]
};

private _fnc_equipSteps = {
    params ["_move"];

    private _who = _move getOrDefault ["unit", _unit];
    private _slot = _move getOrDefault ["slot", ""];
    private _from = _move getOrDefault ["from", objNull];
    private _entry = _move getOrDefault ["entry", createHashMap];

    if (isNull _who || {_slot isEqualTo ""} || {_from isEqualType objNull && {isNull _from}}) exitWith {["Failed", []]};

    private _fromRoot = [_from, _move getOrDefault ["fromRoot", objNull]] call _fnc_rootOf;
    private _take = [_from, "take"] call _fnc_opName;

    if (_take isEqualTo "") exitWith {["Failed", []]};
    if (isNull _fromRoot) exitWith {["Moved", []]};

    private _steps = [
        [_fromRoot, _take, [_from, [_entry] call EFUNC(storage,entryToArray), 1], "take"],
        [_who, "putOn", [_who, _slot, ["#step", 0, 0]], "land"]
    ];

    // What comes off the slot. Nothing there now: no step for it - should something come off after all,
    // it has no consumer and settles like every leftover.
    private _old = [_who, _slot] call EFUNC(storage,getSlot);
    private _oldTo = objNull;

    // Where the caller said it goes - a kit that takes it, or one of the player's own containers
    // (einv_compat_efak_fnc_equip decides by that mod's rules).
    private _given = _move getOrDefault ["to", objNull];
    private _givenPut = if (_given isEqualType "" || {!isNull _given}) then {[_given, "put"] call _fnc_opName} else {""};
    private _givenRoot = if (_givenPut isEqualTo "") then {objNull} else {
        [_given, _move getOrDefault ["toRoot", objNull]] call _fnc_rootOf
    };

    if (count _old > 0 && {!isNull _givenRoot}) then {
        _oldTo = _given;
        _steps pushBack [_givenRoot, _givenPut, [_given, ["#step", 1, 0], []], "old"];
    };

    if (count _old > 0 && {isNull _givenRoot}) then {
        if (_from isEqualType objNull) then {
            // Back where the new item came from, onto its cell - unless a stack still lies there.
            private _back = [[], [_entry getOrDefault ["col", 0], _entry getOrDefault ["row", 0], _entry getOrDefault ["block", 0]]] select ((_entry getOrDefault ["count", 1]) <= 1);

            _oldTo = _from;
            _steps pushBack [_fromRoot, "put", [_from, ["#step", 1, 0], _back], "old"];
        } else {
            // Out of a kit: into that kit where it takes it, as the kit's own wearItem does - a uniform,
            // vest or backpack only empty -, else into the player's own gear, the first with room.
            private _kit = _move getOrDefault ["kit", ""];
            private _oldClass = _old getOrDefault ["class", ""];
            private _oldInside = _old getOrDefault ["container", objNull];
            private _empty = isNull _oldInside || {
                ((itemCargo _oldInside) + (magazineCargo _oldInside) + (weaponCargo _oldInside) + (backpackCargo _oldInside)) isEqualTo []
            };

            private _kitPut = [_from, "put"] call _fnc_opName;
            private _intoKit = _kit isNotEqualTo "" && {_empty} && {_kitPut isNotEqualTo ""} && {!isNil QEFUNC(compat_efak,canPack)} && {
                (([_kit, _oldClass, 1] call EFUNC(compat_efak,canPack)) param [0, false]) isEqualTo true
            };

            if (_intoKit) exitWith {
                _oldTo = _from;
                _steps pushBack [_fromRoot, _kitPut, [_from, ["#step", 1, 0], []], "old"];
            };

            private _whoOwn = [uniformContainer _who, vestContainer _who, backpackContainer _who] select {
                !isNull _x && {_x isNotEqualTo _oldInside}
            };
            private _index = _whoOwn findIf {[_x, _old] call EFUNC(storage,hasRoom)};

            if (_index >= 0) then {
                _oldTo = _whoOwn select _index;
                _steps pushBack [_who, "put", [_oldTo, ["#step", 1, 0], []], "old"];
            };
        };
    };

    ["", _steps, objNull, _old getOrDefault ["class", ""], _oldTo]
};

private _fnc_unequipSteps = {
    params ["_move"];

    private _who = _move getOrDefault ["unit", objNull];
    private _slot = _move getOrDefault ["slot", ""];
    private _to = _move getOrDefault ["to", objNull];
    private _cell = _move getOrDefault ["cell", []];

    if (isNull _who || {_slot isEqualTo ""} || {_to isEqualType objNull && {isNull _to}}) exitWith {["Failed", []]};

    private _worn = [_who, _slot] call EFUNC(storage,getSlot);

    if (count _worn == 0) exitWith {["Failed", []]};

    private _first = [_who, "takeOff", [_who, _slot], "take"];

    if (_to isEqualType "" && {_to in ["ground", "vehicle"]}) exitWith {
        private _ground = call _fnc_ground;

        if (_ground isEqualTo "") exitWith {["NoGround", []]};

        if (_ground isEqualType objNull) exitWith {
            ["", [_first, [_ground, "put", [_ground, ["#step", 0, 0], []], "land"]], _ground]
        };

        ["", [_first, [objNull, "putGround", [["#step", 0, 0]], "land"]], "ground"]
    };

    // Not into what comes off with it - a vest lying in the uniform taken off would be gone with it.
    private _inside = _worn getOrDefault ["container", objNull];

    if (!isNull _inside && {_to isEqualTo _inside || {[_to, _inside] call EFUNC(storage,liesIn)}}) exitWith {["IntoItself", []]};

    private _toRoot = [_to, _move getOrDefault ["toRoot", objNull]] call _fnc_rootOf;
    private _put = [_to, "put"] call _fnc_opName;

    if (_put isEqualTo "") exitWith {["Failed", []]};
    if (isNull _toRoot) exitWith {["Moved", []]};

    ["", [_first, [_toRoot, _put, [_to, ["#step", 0, 0], _cell], "land"]], _to]
};

// Worn gear from one unit's slot onto another's: off the first, on the other - which hands back what it
// wore there -, that onto the first. Only takeOff and putOn, each where its unit is local; nothing that
// does not go on is lost: it came off a slot, so settlement puts it back on there while that is empty,
// else into the vehicle or onto the ground.
private _fnc_swapSteps = {
    params ["_move"];

    private _fromUnit = _move getOrDefault ["unit", objNull];
    private _slot = _move getOrDefault ["slot", ""];
    private _toUnit = _move getOrDefault ["toUnit", objNull];
    private _toSlot = _move getOrDefault ["toSlot", _slot];

    if (isNull _fromUnit || {isNull _toUnit} || {_fromUnit isEqualTo _toUnit} || {_slot isEqualTo ""} || {_toSlot isEqualTo ""}) exitWith {["Failed", []]};

    private _worn = [_fromUnit, _slot] call EFUNC(storage,getSlot);

    if (count _worn == 0) exitWith {["Failed", []]};

    private _old = [_toUnit, _toSlot] call EFUNC(storage,getSlot);

    private _steps = [
        [_fromUnit, "takeOff", [_fromUnit, _slot], "take"],
        [_toUnit, "putOn", [_toUnit, _toSlot, ["#step", 0, 0]], "land"]
    ];

    // Nothing there now: no step for it - should something come off after all, it settles.
    if (count _old > 0) then {
        _steps pushBack [_fromUnit, "putOn", [_fromUnit, _slot, ["#step", 1, 0]], "old"];
    };

    ["", _steps, _toUnit, _old getOrDefault ["class", ""], [objNull, _fromUnit] select (count _old > 0)]
};

// Two tiles of two containers that swap places: out of both, then each into the other's holder at the other's
// cell. The takes come first, so the cells the puts want are free by then. Returns [why not or "", steps].
private _fnc_exchangeSteps = {
    params ["_move"];

    private _from = _move getOrDefault ["from", objNull];
    private _to = _move getOrDefault ["to", objNull];
    private _entry = _move getOrDefault ["entry", createHashMap];
    private _other = _move getOrDefault ["otherEntry", createHashMap];

    if (
        !(_from isEqualType objNull) || {!(_to isEqualType objNull)} || {isNull _from} || {isNull _to} || {_from isEqualTo _to}
        || {count _entry == 0} || {count _other == 0}
    ) exitWith {["Failed", []]};

    // A uniform, vest or backpack never goes into itself or into anything lying in it - either of the two.
    private _insideEntry = _entry getOrDefault ["container", objNull];
    private _insideOther = _other getOrDefault ["container", objNull];

    if (
        (!isNull _insideEntry && {_to isEqualTo _insideEntry || {[_to, _insideEntry] call EFUNC(storage,liesIn)}})
        || {!isNull _insideOther && {_from isEqualTo _insideOther || {[_from, _insideOther] call EFUNC(storage,liesIn)}}}
    ) exitWith {["IntoItself", []]};

    private _fromRoot = [_from, _move getOrDefault ["fromRoot", objNull]] call _fnc_rootOf;
    private _toRoot = [_to, _move getOrDefault ["toRoot", objNull]] call _fnc_rootOf;

    if (isNull _fromRoot || {isNull _toRoot}) exitWith {["Moved", []]};

    ["", [
        [_fromRoot, "take", [_from, [_entry] call EFUNC(storage,entryToArray), -1], "take"],
        [_toRoot, "take", [_to, [_other] call EFUNC(storage,entryToArray), -1], "takeOther"],
        [_toRoot, "put", [_to, ["#step", 0, 0], _move getOrDefault ["cell", []]], "land"],
        [_fromRoot, "put", [_from, ["#step", 1, 0], _move getOrDefault ["otherCell", []]], "landOther"]
    ]]
};

private _fnc_sortSteps = {
    params ["_move"];

    private _holder = _move getOrDefault ["from", objNull];

    if (_holder isEqualType objNull && {isNull _holder}) exitWith {["Failed", []]};

    private _root = [_holder, _move getOrDefault ["fromRoot", objNull]] call _fnc_rootOf;

    if (isNull _root) exitWith {["Moved", []]};

    // The order the player chose goes with the op: it is laid out where the root is local.
    ["", [[_root, "sort", [_holder, _move getOrDefault ["order", SORT_DEFAULT]], "land"]], _holder]
};

// Several tiles of one holder laid down at once: one step.
private _fnc_placeManySteps = {
    params ["_move"];

    private _holder = _move getOrDefault ["from", objNull];
    private _tiles = _move getOrDefault ["tiles", []];

    // Containers only: a kit lays its tiles down one by one (its own op place).
    if (_tiles isEqualTo [] || {!(_holder isEqualType objNull)} || {isNull _holder}) exitWith {["Failed", []]};

    private _root = [_holder, _move getOrDefault ["fromRoot", objNull]] call _fnc_rootOf;

    if (isNull _root) exitWith {["Moved", []]};

    ["", [[_root, "placeMany", [_holder, _tiles apply {[[_x select 0] call EFUNC(storage,entryToArray), _x select 1]}], "land"]], _holder]
};

// Puts the steps of one move into the phases, each after the steps whose payloads it takes: [where each
// went, role -> where]. An arg ["#step", k, n] is the n-th payload step k produced.
private _fnc_addSteps = {
    params ["_steps"];

    private _placed = [];
    private _roles = createHashMap;

    {
        _x params ["_root", "_name", "_args", "_role"];

        // A payload an earlier step produced: by where that step's op landed in the phases.
        private _resolved = _args apply {
            if (_x isEqualType [] && {(_x param [0, ""]) isEqualTo "#step"}) then {
                (_placed select (_x select 1)) params ["_phase", "_op"];
                ["#ref", _phase, _op, _x select 2]
            } else {
                _x
            };
        };

        private _previous = if (_forEachIndex == 0) then {[]} else {_placed select (_forEachIndex - 1)};
        private _at = [_root, [_name, _resolved], _previous] call _fnc_place;

        _placed pushBack _at;
        _roles set [_role, _at];
    } forEach _steps;

    [_placed, _roles]
};

// Phases of the transaction, [root, ops] each. A step joins the phase of the step before it when both
// are on the same root, else the first later phase on its root, else a new phase at the end - so a step
// always runs after the steps whose payloads it takes.
private _phases = [];

private _fnc_place = {
    params ["_root", "_op", "_previous"];

    private _index = -1;
    private _start = 0;

    if (_previous isNotEqualTo []) then {
        private _last = _previous select 0;

        if (((_phases select _last) select 0) isEqualTo _root) then {
            _index = _last;
        } else {
            _start = _last + 1;
        };
    };

    if (_index < 0) then {
        for "_i" from _start to (count _phases - 1) do {
            if (((_phases select _i) select 0) isEqualTo _root) exitWith {_index = _i};
        };
    };

    if (_index < 0) then {
        _index = _phases pushBack [_root, []];
    };

    [_index, ((_phases select _index) select 1) pushBack _op]
};

private _records = [];
private _feels = [];
private _sources = [];
private _targets = [];
private _rest = [];
private _refused = "";

// Locked to the player: those moves are left out, and the hint says why unless something else is.
private _lockedOut = false;

_moves = _moves select {
    private _isLocked = [_x] call _fnc_locked;

    if (_isLocked) then {
        _lockedOut = true;
    };

    !_isLocked
};

if (_lockedOut) then {
    _refused = "Locked";
};

if (_moves isEqualTo []) exitWith {
    ["Locked"] call FUNC(flashHint);
    false
};

{
    private _move = _x;
    private _kind = _move getOrDefault ["kind", "move"];

    // A chunk at a time: the rest goes when this one is answered (fnc_onAnswer). A group laid down at
    // once is never cut in two - alone in a chunk it may be longer.
    private _weight = [1, count (_move getOrDefault ["tiles", []])] select (_kind isEqualTo "placeMany");

    if (_kind isEqualTo "exchange") then {
        _weight = 2;
    };

    if (_records isNotEqualTo [] && {count _records + _weight > BATCH_MAX}) then {
        _rest pushBack _move;
        continue;
    };

    // ----- Several tiles of one holder at once: one step, a record for each tile -----
    if (_kind isEqualTo "placeMany") then {
        ([_move] call _fnc_placeManySteps) params [["_manyReason", "Failed"], ["_manySteps", []], ["_manyHolder", objNull]];

        if (_manyReason isEqualTo "" && {!_ready} && {_manySteps findIf {!([_x select 0] call EFUNC(storage,isLocalRoot))} >= 0}) then {
            _manyReason = "NotReady";
        };

        if (_manyReason isNotEqualTo "") then {
            if (_refused isEqualTo "") then {
                _refused = _manyReason;
            };

            continue;
        };

        private _manyRoles = ([_manySteps] call _fnc_addSteps) select 1;

        {
            _x params ["_manyEntry", "_manyCell"];

            private _manyClass = _manyEntry getOrDefault ["class", ""];
            private _manyKey = _manyEntry getOrDefault ["key", ""];

            if (_manyKey isEqualTo "") then {
                _manyKey = [_manyEntry] call EFUNC(storage,entryKey);
            };

            _records pushBack createHashMapFromArray [
                ["kind", "move"], ["from", _manyHolder], ["to", _manyHolder], ["class", _manyClass], ["cell", _manyCell],
                ["oldClass", ""], ["oldTo", objNull], ["roles", _manyRoles]
            ];

            // Rearranged in its holder: it sounds like a move.
            if (count _feels < 3) then {
                _feels pushBack ["move", _manyClass, [_manyHolder, objNull] select (_manyHolder isEqualType ""), "", objNull];
            };

            _sources pushBack [_manyHolder, _manyKey, _manyEntry getOrDefault ["block", 0], _manyEntry getOrDefault ["col", -1], _manyEntry getOrDefault ["row", -1]];

            _targets pushBack [
                _manyHolder, _manyCell param [2, 0], _manyCell select 0, _manyCell select 1,
                _manyCell param [3, _manyEntry getOrDefault ["w", 1]], _manyCell param [4, _manyEntry getOrDefault ["h", 1]]
            ];
        } forEach (_move getOrDefault ["tiles", []]);

        continue;
    };

    // ----- Two tiles swap places between two containers: two records, four steps -----
    if (_kind isEqualTo "exchange") then {
        ([_move] call _fnc_exchangeSteps) params [["_swapReason", "Failed"], ["_swapSteps", []]];

        if (_swapReason isEqualTo "" && {!_ready} && {_swapSteps findIf {!([_x select 0] call EFUNC(storage,isLocalRoot))} >= 0}) then {
            _swapReason = "NotReady";
        };

        if (_swapReason isNotEqualTo "") then {
            if (_refused isEqualTo "") then {
                _refused = _swapReason;
            };

            continue;
        };

        private _swapRoles = ([_swapSteps] call _fnc_addSteps) select 1;
        private _swapFrom = _move get "from";
        private _swapTo = _move get "to";

        // One record per tile, each with the steps that are its own: what the answer reads (fnc_afterAction).
        {
            _x params ["_recordFrom", "_recordTo", "_recordEntry", "_recordCell", "_takeRole", "_landRole"];

            _records pushBack createHashMapFromArray [
                ["kind", "move"], ["from", _recordFrom], ["to", _recordTo], ["class", _recordEntry getOrDefault ["class", ""]],
                ["cell", _recordCell], ["oldClass", ""], ["oldTo", objNull],
                ["roles", createHashMapFromArray [["take", _swapRoles get _takeRole], ["land", _swapRoles get _landRole]]]
            ];

            // How it will sound: like any move (a pile on the ground drops).
            if (count _feels < 3) then {
                _feels pushBack ([createHashMapFromArray [["kind", "move"], ["entry", _recordEntry], ["to", _recordTo]]] call FUNC(feelFor));
            };

            private _recordKey = _recordEntry getOrDefault ["key", ""];

            if (_recordKey isEqualTo "") then {
                _recordKey = [_recordEntry] call EFUNC(storage,entryKey);
            };

            _sources pushBack [_recordFrom, _recordKey, _recordEntry getOrDefault ["block", 0], _recordEntry getOrDefault ["col", -1], _recordEntry getOrDefault ["row", -1]];
            _targets pushBack [
                _recordTo, _recordCell param [2, 0], _recordCell select 0, _recordCell select 1,
                _recordCell param [3, _recordEntry getOrDefault ["w", 1]], _recordCell param [4, _recordEntry getOrDefault ["h", 1]]
            ];
        } forEach [
            [_swapFrom, _swapTo, _move get "entry", _move get "cell", "take", "land"],
            [_swapTo, _swapFrom, _move get "otherEntry", _move get "otherCell", "takeOther", "landOther"]
        ];

        continue;
    };

    private _built = switch (_kind) do {
        case "equip": {[_move] call _fnc_equipSteps};
        case "unequip": {[_move] call _fnc_unequipSteps};
        case "swap": {[_move] call _fnc_swapSteps};
        case "sort": {[_move] call _fnc_sortSteps};
        default {[_move] call _fnc_moveSteps};
    };

    _built params [["_reason", "Failed"], ["_steps", []], ["_landTo", objNull], ["_oldClass", ""], ["_oldTo", objNull]];

    // A server that has not said it runs this version's hub would drop what is sent to it - and an item
    // already taken out here with it (kits had solved this with their own greeting; now the storage's).
    if (_reason isEqualTo "" && {!_ready} && {_steps findIf {!([_x select 0] call EFUNC(storage,isLocalRoot))} >= 0}) then {
        _reason = "NotReady";
    };

    if (_reason isNotEqualTo "") then {
        if (_refused isEqualTo "") then {
            _refused = _reason;
        };

        continue;
    };

    if (_steps isEqualTo []) then {continue};

    ([_steps] call _fnc_addSteps) params ["_placed", "_roles"];

    private _entry = _move getOrDefault ["entry", createHashMap];
    private _from = [_move getOrDefault ["from", objNull], _move getOrDefault ["unit", objNull]] select (_kind in ["unequip", "swap"]);
    private _cell = _move getOrDefault ["cell", []];

    private _class = switch (_kind) do {
        case "unequip";
        case "swap": {([_from, _move getOrDefault ["slot", ""]] call EFUNC(storage,getSlot)) getOrDefault ["class", ""]};
        case "sort": {""};
        default {_entry getOrDefault ["class", ""]};
    };

    // What the answer needs to tell how it went, learn what moved and light up where it landed
    // (fnc_afterAction).
    _records pushBack createHashMapFromArray [
        ["kind", _kind], ["from", _from], ["to", _landTo], ["class", _class], ["cell", _cell],
        ["oldClass", _oldClass], ["oldTo", _oldTo], ["roles", _roles]
    ];

    // How it will sound once it happened (fnc_feelFor); an answer plays the first one that went, and the first
    // three are all it can come to.
    if (count _feels < 3) then {
        _feels pushBack ([_move] call FUNC(feelFor));
    };

    // In flight: the tile it takes from fades, the cells it goes to are outlined (fnc_drawPending).
    if (_kind in ["move", "equip"] && {count _entry > 0}) then {
        private _key = _entry getOrDefault ["key", ""];

        if (_key isEqualTo "") then {
            _key = [_entry] call EFUNC(storage,entryKey);
        };

        _sources pushBack [_from, _key, _entry getOrDefault ["block", 0], _entry getOrDefault ["col", -1], _entry getOrDefault ["row", -1]];
    };

    if (_kind in ["move", "unequip"] && {_cell isNotEqualTo []} && {_landTo isNotEqualTo "ground"}) then {
        private _size = ([_class] call EFUNC(items,getInfo)) getOrDefault ["size", [1, 1]];

        if (_kind isEqualTo "move") then {
            _size = [_entry getOrDefault ["w", _size select 0], _entry getOrDefault ["h", _size select 1]];
        };

        _targets pushBack [
            _landTo, _cell param [2, 0], _cell select 0, _cell select 1,
            _cell param [3, _size select 0], _cell param [4, _size select 1]
        ];
    };
} forEach _moves;

if (_phases isEqualTo []) exitWith {
    if (_refused isNotEqualTo "") then {
        [_refused] call FUNC(flashHint);
    };

    false
};

private _id = [_phases, {_this call FUNC(onAnswer)}, [_records, _options, _rest]] call EFUNC(storage,request);

if (_id isEqualTo "") exitWith {
    ["Failed"] call FUNC(flashHint);
    false
};

// Only while the window shows it: a chain that goes on after the window closed fades nothing. In single
// player the answer is here already - fnc_onFrame finishes it, and this entry with it, the next frame.
if (!isNull (uiNamespace getVariable [QGVAR(display), displayNull])) then {
    GVAR(inFlight) set [_id, [_sources, _targets, diag_tickTime, _feels]];
};

// Some went, some were left out: why those were.
if (_refused isNotEqualTo "") then {
    [_refused] call FUNC(flashHint);
};

true
