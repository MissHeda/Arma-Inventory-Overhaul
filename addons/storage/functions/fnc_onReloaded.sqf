#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A unit reloaded. Two cases, while a "Use items from ..." setting limits something:
 *
 *   - the reload this mod asked for (fnc_loadMagazine wrote GVAR(reloadToken) before the game's action): the
 *     token is spent by the first event of that unit, whatever it shows - so nothing here can run twice for
 *     one reload. When the magazine now loaded is the one asked for, the reload stands, and a frame later the
 *     magazine the game put away is moved once out of a container the settings close (fnc_reloadTidy). When
 *     it is another one (the game did a reload of its own), an RPT line says so and the case below decides.
 *   - any other reload - the scroll menu's entry, a gamepad button, a script, the game's own reload when a
 *     magazine ran dry: if the loaded magazine came out of a container the settings close to it (noted
 *     beforehand, fnc_useTrack) and is not whitelisted for it, the reload is undone a frame later
 *     (fnc_reloadUndo), which never starts a reload of the game's again.
 *
 * Left alone: a magazine from a container that allows it, one whose origin is not known, one the window put
 * in by hand (fnc_noteHandLoad), a reload of another unit, from a vehicle's gun, or of a weapon the unit does
 * not carry. Without limits nothing is looked at.
 *
 * A handler of the "Reloaded" event of CAManBase (XEH_postInit); it runs where the unit is local.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon <STRING>
 * 2: Muzzle <STRING>
 * 3: New magazine, [class, rounds, ...] <ARRAY>
 * 4: Old magazine, [] when nothing was loaded <ARRAY>
 *
 * Return Value:
 * Whether it is being undone <BOOL>
 *
 * Example:
 * [player, "arifle_MX_F", "arifle_MX_F", ["30Rnd_65x39_caseless_mag", 30, 1, 0], []] call einv_storage_fnc_onReloaded;
 *
 * Public: No
 */

params [
    ["_unit", objNull, [objNull]],
    ["_weapon", "", [""]],
    ["_muzzle", "", [""]],
    ["_new", [], [[]]],
    ["_old", [], [[]]]
];

// The reload this mod asked for: spent by the first event of its unit, one that ran out by any.
private _token = GVAR(reloadToken);

if (_token isNotEqualTo []) then {
    if (diag_tickTime > (_token select 8) || {_unit isEqualTo (_token select 0)}) then {
        GVAR(reloadToken) = [];
    };

    if (diag_tickTime > (_token select 8) || {_unit isNotEqualTo (_token select 0)}) then {
        _token = [];
    };
};

if (!(missionNamespace getVariable [QGVAR(useActive), false]) || {diag_tickTime < GVAR(undoUntil)}) exitWith {false};

if (isNull _unit || {!local _unit} || {_unit isNotEqualTo (missionNamespace getVariable ["ACE_player", player])}) exitWith {false};

if (!alive _unit || {!isNull objectParent _unit} || {([primaryWeapon _unit, handgunWeapon _unit, secondaryWeapon _unit] find _weapon) < 0}) exitWith {false};

_new params [["_class", "", [""]], ["_rounds", 0, [0]]];

if (_class isEqualTo "" || {_rounds <= 0}) exitWith {false};

// A magazine the window put into the weapon by hand (a drag onto the weapon, "Load into", fnc_noteHandLoad) was
// chosen on purpose from wherever it lay: the settings are about using items in the field, not about handling
// the gear, so nothing is taken back. The note answers one event and runs out by itself.
private _hand = GVAR(handLoad);

if (_hand isNotEqualTo [] && {diag_tickTime >= (_hand select 3)}) then {
    GVAR(handLoad) = [];
    _hand = [];
};

if (
    _hand isNotEqualTo [] && {(_hand select 0) isEqualTo _unit} && {(_hand select 1) isEqualTo (toLowerANSI _weapon)}
    && {(_hand select 2) isEqualTo (toLowerANSI _class)}
) exitWith {
    GVAR(handLoad) = [];

    false
};

// The magazine that is in the weapon now. The event does not say which one it was by id, so the loaded
// magazine of this class and these rounds is looked for; more than one (the same magazine in two weapons)
// is not told apart.
private _loaded = (magazinesAmmoFull _unit) select {
    count _x >= 7 && {_x select 2} && {(_x select 0) == _class} && {(_x select 1) == _rounds}
};

private _id = if (count _loaded == 1) then {format ["%1:%2", (_loaded select 0) select 6, (_loaded select 0) select 5]} else {""};

// The reload asked for: the magazine by its id, or - when it cannot be told apart - by class and rounds.
if (_token isNotEqualTo []) then {
    _token params ["", "_tokenWeapon", "_tokenId", "_tokenClass", "_tokenRounds", "_tokenOld", "_tokenKind", "_tokenCounts"];

    private _asked = (toLowerANSI _weapon) isEqualTo _tokenWeapon && {
        [_id isEqualTo _tokenId, _class == _tokenClass && {_rounds == _tokenRounds}] select (_id isEqualTo "")
    };

    if (_asked) then {
        // A frame later: the game is still putting the old magazine away.
        [FUNC(reloadTidy), [_unit, _tokenOld, _tokenKind, _tokenCounts]] call CBA_fnc_execNextFrame;
    } else {
        INFO_3("The reload action asked for %1 (%2) but the game loaded %3.",_tokenClass,_tokenId,_class);

        _token = [];
    };
};

if (_token isNotEqualTo []) exitWith {false};

if (_id isEqualTo "") exitWith {false};

private _kind = GVAR(useIds) getOrDefault [_id, ""];

if (_kind isEqualTo "" || {([_class, _kind] call FUNC(useState)) isNotEqualTo "blocked"}) exitWith {false};

// A frame later: the game is still putting the old magazine away.
[FUNC(reloadUndo), [_unit, _weapon, _muzzle, [_class, _rounds], _old, _kind]] call CBA_fnc_execNextFrame;

true
