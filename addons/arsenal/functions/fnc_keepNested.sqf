#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Keeps what the uniforms, vests and backpacks lying in the soldier's uniform, vest and backpack hold while an
 * arsenal is open (issue 72). Both arsenals rebuild the soldier's containers from class names: ACE Arsenal sets
 * the whole loadout again whenever another uniform, vest or backpack is picked (setUnitLoadout in its
 * onSelChangedLeft), and the vanilla one puts every container on anew - removeBackpack, addBackpack and
 * addItemToBackpack of what backpackItems named, the same for the vest and the uniform - each time its lists pick
 * the worn one, which its start does for all of them (BIS_fnc_arsenal "Init", "ListSelectCurrent", "SelectItem").
 * A uniform put into a backpack by its class is a new, empty container object: getUnitLoadout and backpackItems
 * carry its class, never what it held, so its things were gone.
 *
 * So what each of them holds is noted (aio_storage_fnc_snapshot, with everything nested deeper and its id) when the
 * arsenal opens and every NESTED_REFRESH seconds while it is open: [unit, [[container, [[object, item class, id,
 * snapshot], ...]] per slot uniform, vest, backpack], lost]. One that is gone at a later look is "lost" only when
 * the arsenal rebuilt where it lay - that container is a new object, or a new one of its class lies there in its
 * place -; then a new object of its class that the storage did not make (it carries none of the ids noted) is
 * filled from its snapshot (aio_storage_fnc_restore), in the same slot first, then in any: the arsenal carried it
 * over into another backpack. One the storage moved comes with its id and its things (a transaction's own
 * snapshot) and is only noted where it is now. One that was taken out on purpose ("Remove", ACE's "Remove all", a
 * smaller backpack it does not fit) has no new object, and its things go with it, after NESTED_LOST_KEEP seconds.
 *
 * Modes:
 *   "start" - note the unit's containers anew, nothing lost; and look every NESTED_REFRESH seconds
 *   "check" - look: fill what was rebuilt, note again
 *   "stop"  - a last look, then forget it all
 *
 * The look runs where the unit is local, and not in the Eden editor, where both arsenals dress a copy of the unit.
 *
 * Arguments:
 * 0: Mode <STRING> (default: "check")
 * 1: Unit, for "start" <OBJECT> (default: objNull)
 *
 * Return Value:
 * How many were filled again <NUMBER>
 *
 * Example:
 * ["start", player] call aio_arsenal_fnc_keepNested;
 *
 * Public: No
 */

params [["_mode", "check", [""]], ["_unit", objNull, [objNull]]];

// The unit's three containers, each with what lies in it: [container, [[object, item class, id, snapshot], ...]].
private _fnc_read = {
    params ["_unit"];

    [uniformContainer _unit, vestContainer _unit, backpackContainer _unit] apply {
        private _parent = _x;

        if (isNull _parent) then {
            [objNull, []]
        } else {
            [_parent, (everyContainer _parent) apply {
                _x params ["_class", "_object"];

                private _snapshot = [_object, _class] call EFUNC(storage,snapshot);

                // The id as the snapshot read it - the tile's key, wherever the authority keeps it.
                [_object, _class, ((_snapshot select 5) param [1, []]) param [0, ""], _snapshot]
            }]
        }
    }
};

if (_mode isEqualTo "stop") exitWith {
    private _filled = ["check"] call FUNC(keepNested);

    if (GVAR(nestedHandler) >= 0) then {
        [GVAR(nestedHandler)] call CBA_fnc_removePerFrameHandler;
        GVAR(nestedHandler) = -1;
    };

    GVAR(nestedKept) = [objNull, [], []];

    _filled
};

if (_mode isEqualTo "start") exitWith {
    if (isNull _unit || {!local _unit} || {is3DEN}) exitWith {
        GVAR(nestedKept) = [objNull, [], []];
        0
    };

    GVAR(nestedKept) = [_unit, [_unit] call _fnc_read, []];

    // Looked at while the arsenal is open; "stop" takes the handler away. It also goes by itself once nothing is
    // watched any more - an arsenal that closed in a way no event of it said.
    if (GVAR(nestedHandler) < 0) then {
        GVAR(nestedHandler) = [{
            if (isNull (GVAR(nestedKept) param [0, objNull])) exitWith {
                [_this select 1] call CBA_fnc_removePerFrameHandler;
                GVAR(nestedHandler) = -1;
            };

            ["check"] call FUNC(keepNested);
        }, NESTED_REFRESH] call CBA_fnc_addPerFrameHandler;
    };

    0
};

GVAR(nestedKept) params [["_watched", objNull, [objNull]], ["_kept", [], [[]]], ["_lost", [], [[]]]];

if (isNull _watched || {!local _watched}) exitWith {0};

private _parents = [uniformContainer _watched, vestContainer _watched, backpackContainer _watched];

// What lies in each now, [[item class, object], ...] per slot, and the objects and ids noted at the last look.
private _now = _parents apply {
    if (isNull _x) then {[]} else {everyContainer _x}
};

private _nowObjects = [];

{
    {
        _nowObjects pushBack (_x select 1);
    } forEach _x;
} forEach _now;

private _nowIds = _nowObjects apply {
    private _tag = _x getVariable [QEGVAR(storage,tag), []];

    if (_tag isEqualType []) then {_tag param [0, "", [""]]} else {""}
};

private _knownObjects = [];
private _knownIds = [];

{
    {
        _knownObjects pushBack (_x select 0);

        if ((_x select 2) isNotEqualTo "") then {
            _knownIds pushBack (_x select 2);
        };
    } forEach (_x param [1, []]);
} forEach _kept;

// ---------------------------------------------------------------------------
// Gone since the last look: lost where the arsenal rebuilt the container it lay in.
// ---------------------------------------------------------------------------
{
    _x params [["_oldParent", objNull, [objNull]], ["_entries", [], [[]]]];

    private _slot = _forEachIndex;
    private _parent = _parents select _slot;

    // New objects lying in this slot that were not there at the last look.
    private _newClasses = ((_now select _slot) select {!((_x select 1) in _knownObjects)}) apply {toLowerANSI (_x select 0)};

    {
        _x params ["_object", "_class", "_uid", "_snapshot"];

        // Still there, or moved by the storage with its id - its things went along.
        if (_object in _nowObjects || {_uid isNotEqualTo "" && {_uid in _nowIds}}) then {continue};

        if (_parent isNotEqualTo _oldParent || {(toLowerANSI _class) in _newClasses}) then {
            _lost pushBack [_slot, _class, _uid, _snapshot, diag_tickTime + NESTED_LOST_KEEP];
        };
    } forEach _entries;
} forEach _kept;

_lost = _lost select {(_x select 4) >= diag_tickTime};

// ---------------------------------------------------------------------------
// New objects the arsenal made: filled from what their lost one held.
// ---------------------------------------------------------------------------
private _filled = 0;

{
    private _slot = _forEachIndex;
    private _parent = _parents select _slot;

    {
        _x params ["_class", "_object"];

        if (_object in _knownObjects) then {continue};

        private _tag = _object getVariable [QEGVAR(storage,tag), []];
        private _uid = if (_tag isEqualType []) then {_tag param [0, "", [""]]} else {""};

        // One the storage moved carries its id, and its things: only no longer waited for.
        if (_uid isNotEqualTo "") then {
            private _byId = _lost findIf {(_x select 2) isEqualTo _uid};

            if (_byId >= 0) then {
                _lost deleteAt _byId;
                continue;
            };

            if (_uid in _knownIds) then {continue};
        };

        private _lower = toLowerANSI _class;
        private _index = _lost findIf {(_x select 0) isEqualTo _slot && {(toLowerANSI (_x select 1)) isEqualTo _lower}};

        if (_index < 0) then {
            _index = _lost findIf {(toLowerANSI (_x select 1)) isEqualTo _lower};
        };

        if (_index < 0) then {continue};

        private _snapshot = (_lost deleteAt _index) select 3;

        if ([_object, _snapshot, _parent] call EFUNC(storage,restore)) then {
            _filled = _filled + 1;
        } else {
            WARNING_2("%1 in %2 was made anew by the arsenal and could not be filled again whole - see the lines above.",_class,typeOf _parent);
        };
    } forEach (_now select _slot);
} forEach _parents;

if (_filled > 0) then {
    INFO_1("The arsenal rebuilt the containers that %1 nested uniforms or vests or backpacks lay in - what they held was put back.",_filled);
};

// Noted again as they are now, with what they hold now.
GVAR(nestedKept) = [_watched, [_watched] call _fnc_read, _lost];

_filled
