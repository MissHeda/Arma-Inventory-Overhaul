#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes back a reload the game did from a container the "Use items from ..." settings close to the item
 * (fnc_onReloaded): the magazine that was loaded goes out of the weapon and back into the container it came
 * from, and the magazine the weapon had before goes back into the weapon. Then a line says so - and when a
 * magazine that may be used lies elsewhere, the fullest of those is loaded the way the reload key's guard
 * loads one (fnc_loadMagazine).
 *
 * Every step is looked at before the next one: the loaded magazine must still be the one in the weapon;
 * the cargo is counted before and after, so a magazine is never lost and never doubled - one that cannot
 * go back into its container stays in the unit's inventory, one that cannot be put anywhere goes back into
 * the weapon, and a restore that does not hold gives the old magazine back to the cargo. Nothing changes
 * if the weapon is no longer as the event said. Runs where the unit is local, a frame after the event.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon <STRING>
 * 2: Muzzle <STRING>
 * 3: Magazine that was loaded, [class, rounds] <ARRAY>
 * 4: Magazine that was in the weapon, [class, rounds, ...] or [] <ARRAY>
 * 5: The container it came from: "uniform", "vest" or "backpack" <STRING>
 *
 * Return Value:
 * Whether the reload was taken back <BOOL>
 *
 * Example:
 * [player, "arifle_MX_F", "arifle_MX_F", ["30Rnd_65x39_caseless_mag", 30], [], "backpack"] call einv_storage_fnc_reloadUndo;
 *
 * Public: No
 */

params [
    ["_unit", objNull, [objNull]],
    ["_weapon", "", [""]],
    ["_muzzle", "", [""]],
    ["_new", [], [[]]],
    ["_old", [], [[]]],
    ["_kind", "", [""]]
];

_new params [["_class", "", [""]], ["_rounds", 0, [0]]];
_old params [["_oldClass", "", [""]], ["_oldRounds", 0, [0]]];

if (isNull _unit || {!alive _unit} || {diag_tickTime < GVAR(undoUntil)} || {_class isEqualTo ""} || {!(_kind in USE_KINDS)}) exitWith {false};

private _which = [primaryWeapon _unit, handgunWeapon _unit, secondaryWeapon _unit] find _weapon;

if (_which < 0 || {!isNull objectParent _unit}) exitWith {false};

// Where the muzzle's magazine is in weaponsItems: the first muzzle's at 4, the second's (a grenade
// launcher) at 5.
private _muzzles = getArray (configFile >> "CfgWeapons" >> _weapon >> "muzzles");
private _second = _muzzle isNotEqualTo _weapon && {_muzzle isNotEqualTo "this"} && {_muzzle isNotEqualTo (_muzzles param [0, "this"])};
private _slot = [4, 5] select _second;

private _containers = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];
private _boxAt = USE_KINDS find _kind;
private _box = _containers select _boxAt;

if (isNull _box) exitWith {false};

// The magazine in the muzzle: [class, rounds], [] for none.
private _fnc_loaded = {
    private _item = (weaponsItems _unit) select {(_x select 0) == _weapon};

    if (_item isEqualTo []) exitWith {[]};

    private _mag = (_item select 0) param [_slot, []];

    if (_mag isEqualType [] && {count _mag >= 2} && {(_mag select 0) isNotEqualTo ""}) then {
        [_mag select 0, _mag select 1]
    } else {
        []
    }
};

// How many magazines of a class and rounds a container holds.
private _fnc_count = {
    params [["_container", objNull, [objNull]], ["_of", "", [""]], ["_with", 0, [0]]];

    if (isNull _container) exitWith {0};

    {(_x select 0) == _of && {(_x select 1) == _with}} count (magazinesAmmoCargo _container)
};

private _fnc_counts = {
    params [["_of", "", [""]], ["_with", 0, [0]]];

    _containers apply {[_x, _of, _with] call _fnc_count}
};

// Still the one that was loaded.
if ((call _fnc_loaded) isNotEqualTo [_class, _rounds]) exitWith {false};

private _before = [_class, _rounds] call _fnc_counts;

GVAR(undoUntil) = diag_tickTime + UNDO_BUSY_MAX;

// Out of the weapon. The command takes a magazine of that class out of the muzzle; whether the game puts it
// into the cargo or lets it go, the counts say.
switch (_which) do {
    case 0: {_unit removePrimaryWeaponItem _class};
    case 1: {_unit removeHandgunItem _class};
    default {_unit removeSecondaryWeaponItem _class};
};

if ((call _fnc_loaded) isNotEqualTo []) exitWith {
    // It did not come out: nothing has changed.
    GVAR(undoUntil) = 0;

    false
};

private _after = [_class, _rounds] call _fnc_counts;
private _total = {
    private _sum = 0;

    {_sum = _sum + _x} forEach _this;

    _sum
};

// Into the container it came from.
private _safe = false;

if ((_after call _total) > (_before call _total)) then {
    // The game put it into the cargo: into this container, or into another one that is moved over.
    if ((_after select _boxAt) > (_before select _boxAt)) then {
        _safe = true;
    } else {
        private _from = [0, 1, 2] findIf {(_after select _x) > (_before select _x)};
        private _source = [objNull, _containers select (_from max 0)] select (_from >= 0);

        _safe = true;

        if (!isNull _source) then {
            _source addMagazineAmmoCargo [_class, -1, _rounds];

            if (([_source, _class, _rounds] call _fnc_count) < (_after select _from)) then {
                _box addMagazineAmmoCargo [_class, 1, _rounds];

                if (([_box, _class, _rounds] call _fnc_count) <= (_before select _boxAt)) then {
                    // The box would not take it: back where the game had put it.
                    _source addMagazineAmmoCargo [_class, 1, _rounds];
                };
            };
        };
    };
} else {
    _box addMagazineAmmoCargo [_class, 1, _rounds];

    _safe = ([_box, _class, _rounds] call _fnc_count) > (_before select _boxAt);

    if (!_safe) then {
        // Not into the box: anywhere in the unit's gear.
        _unit addMagazine [_class, _rounds];

        _safe = (([_class, _rounds] call _fnc_counts) call _total) > (_before call _total);
    };
};

// Nowhere to put it: it goes back into the weapon, as the game had it.
if (!_safe) exitWith {
    _unit addWeaponItem [_weapon, [_class, _rounds, _muzzle], true];

    if ((call _fnc_loaded) isEqualTo []) then {
        ERROR_3("Could not put %1 (%2 rounds) back anywhere after undoing a reload of %3 - it is lost.",_class,_rounds,_weapon);
    };

    GVAR(undoUntil) = 0;

    false
};

// The magazine the weapon had before: out of the cargo, into the weapon.
if (_oldClass isNotEqualTo "" && {_oldRounds > 0}) then {
    private _oldCounts = [_oldClass, _oldRounds] call _fnc_counts;
    private _at = [_boxAt, 0, 1, 2] findIf {(_oldCounts select _x) > 0};

    if (_at >= 0) then {
        private _holder = _containers select ([_boxAt, 0, 1, 2] select _at);

        _holder addMagazineAmmoCargo [_oldClass, -1, _oldRounds];

        if (([_holder, _oldClass, _oldRounds] call _fnc_count) < (_oldCounts select ([_boxAt, 0, 1, 2] select _at))) then {
            _unit addWeaponItem [_weapon, [_oldClass, _oldRounds, _muzzle], true];

            if ((call _fnc_loaded) isNotEqualTo [_oldClass, _oldRounds]) then {
                // It did not go in: back into the cargo, so it is neither lost nor in two places.
                _holder addMagazineAmmoCargo [_oldClass, 1, _oldRounds];
            };
        };
    };
};

GVAR(undoUntil) = 0;

[_unit] call FUNC(queueMigrate);

// The magazines put back are new ones to the game: noted again before anything else reloads.
[_unit] call FUNC(useTrack);

// A magazine that may be used: the fullest of them, after a moment; else a line to take one out.
private _pick = [_unit, _weapon, _muzzle] call FUNC(reloadPick);

if (_pick isEqualTo []) then {
    [format [localize "STR_einv_storage_Hint_NoReload", [_kind] call FUNC(useKindName)]] call FUNC(useHint);
} else {
    [format [localize "STR_einv_storage_Hint_NoReloadFrom", [_kind] call FUNC(useKindName)]] call FUNC(useHint);

    [{
        params [["_unit", objNull, [objNull]], ["_weapon", "", [""]], ["_muzzle", "", [""]]];

        if (!alive _unit || {[] call FUNC(reloadBusy)}) exitWith {};

        // Looked at again: the unit may have done something meanwhile. Loaded as every reload is
        // (fnc_loadMagazine): by hand into an empty muzzle, which the undo has just made of it when the
        // weapon had no magazine before.
        private _best = [_unit, _weapon, _muzzle] call FUNC(reloadPick);

        if (_best isEqualTo [] || {currentWeapon _unit isNotEqualTo _weapon}) exitWith {};

        // Only into a muzzle the undo left empty, by hand: a weapon that has its old magazine back is not
        // reloaded again from here (the game's reload would play its animation again and could take the
        // blocked magazine once more - a loop). The next press of the key does it (fnc_reloadGuard).
        if (currentMagazine _unit isNotEqualTo "") exitWith {};

        [_unit, _weapon, _muzzle, _best] call FUNC(loadMagazine);
    }, [_unit, _weapon, _muzzle], UNDO_RELOAD_WAIT] call CBA_fnc_waitAndExecute;
};

true
