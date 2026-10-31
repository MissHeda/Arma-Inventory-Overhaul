#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Notes in which of the unit's uniform, vest and backpack every magazine lies, by its id: GVAR(useIds),
 * "creator:id" -> "uniform", "vest" or "backpack". The game's "Reloaded" event says which magazine was
 * loaded but not where it came from, and by then it has left the container - so the answer is written down
 * beforehand (once a second, after every move of the window and the engine's Take / Put, see postInit).
 *
 * Where a magazine lies is read from the location the game gives in magazinesAmmoFull; if that is not one of
 * the three, from the containers' own lists by class and rounds - and only when exactly one container holds
 * such a magazine. Whatever stays unclear is not noted, and what is not noted is never acted on.
 *
 * A magazine that is loaded keeps what was noted while it lay in a container: the reload animation takes a
 * moment, and a note taken in the middle of it must not erase where the magazine came from. Notes of
 * magazines the unit no longer has are dropped.
 *
 * While no setting limits anything the notes are dropped and this costs one variable read.
 *
 * Arguments:
 * 0: Unit - the player's by default <OBJECT> (default: ACE_player)
 *
 * Return Value:
 * How many magazines are noted <NUMBER>
 *
 * Example:
 * [player] call aio_storage_fnc_useTrack;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) then {
    _unit = missionNamespace getVariable ["ACE_player", player];
};

if (isNull _unit || {!local _unit} || {!(missionNamespace getVariable [QGVAR(useActive), false])}) exitWith {
    if (count GVAR(useIds) > 0) then {
        GVAR(useIds) = createHashMap;
    };

    0
};

// Per container what lies in it by class and rounds: "class|rounds" -> the containers holding one.
private _cargo = createHashMap;

{
    private _kind = _x;
    private _container = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit] select _forEachIndex;

    if (!isNull _container) then {
        {
            private _key = format ["%1|%2", toLowerANSI (_x select 0), _x select 1];
            private _kinds = _cargo getOrDefault [_key, []];

            _kinds pushBackUnique _kind;
            _cargo set [_key, _kinds];
        } forEach (magazinesAmmoCargo _container);
    };
} forEach USE_KINDS;

private _ids = GVAR(useIds);
private _seen = createHashMap;

{
    // magazinesAmmoFull: class, rounds, loaded, type, location, id, creator.
    if (count _x < 7) then {continue};

    private _id = format ["%1:%2", _x select 6, _x select 5];

    _seen set [_id, true];

    if (_x select 2) then {continue};

    private _where = toLowerANSI (format ["%1", _x select 4]);
    private _kind = "";

    if (_where in USE_KINDS) then {
        _kind = _where;
    } else {
        private _kinds = _cargo getOrDefault [format ["%1|%2", toLowerANSI (_x select 0), _x select 1], []];

        if (count _kinds == 1) then {
            _kind = _kinds select 0;
        };
    };

    if (_kind isEqualTo "") then {
        _ids deleteAt _id;
    } else {
        _ids set [_id, _kind];
    };
} forEach (magazinesAmmoFull _unit);

{
    if !(_seen getOrDefault [_x, false]) then {
        _ids deleteAt _x;
    };
} forEach (keys _ids);

count _ids
