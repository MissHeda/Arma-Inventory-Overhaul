#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * AIME's one-click pick-up of the only thing lying on a ground pile, done through this mod's grid when
 * the ground need not be searched (fnc_holderRun). AIME picks a magazine up with the engine's addMagazine
 * after a canAdd, and then clears the pile's magazines whatever the add did: the engine refuses an add at
 * a container's config maximumLoad, which this mod's grid does not care about, puts the magazine straight
 * into an empty compatible weapon (a spent RPG-7), and a refusal after canAdd was true leaves the magazine
 * nowhere (issue 20: an RHS RPG round "loaded into the RPG" or gone from both the pile and the pockets).
 *
 * Here the click is what the quick move out of a pile is: the thing is taken from the pile and put into the
 * first worn container with a free spot (aio_storage_fnc_unitTargets - a container with a slot for its
 * category first; aio_storage_fnc_hasRoom), as a transaction (aio_storage_fnc_moveEntry), with the cargo
 * commands, which ignore maximumLoad and never load a weapon. A thing no container has room for stays on
 * the ground, with this mod's hint "No container has room for that". What goes wrong on the way is
 * settled by the transaction as ever: back on the pile, never lost.
 *
 * Left to AIME's own pick-up (false): a pile that holds more than the one thing AIME picks up - it opens the
 * window, as ever -, a backpack (AIME takes the worn one off and puts this one on: a wearing, not a stowing)
 * and a weapon that fits an empty slot of the soldier, which the game's TakeWeapon action wields. A weapon
 * that does not - the soldier has one of that kind already - goes into a container like a magazine.
 *
 * Arguments:
 * 0: The pile <OBJECT>
 * 1: Player <OBJECT>
 *
 * Return Value:
 * It was done or refused here, AIME's own pick-up is not to run <BOOL>
 *
 * Example:
 * [_pile, ACE_player] call aio_compat_aime_fnc_holderPick;
 *
 * Public: No
 */

params [["_pile", objNull, [objNull]], ["_player", objNull, [objNull]]];

if (isNull _pile || {isNull _player} || {!alive _player}) exitWith {false};

// What AIME's click picks up: exactly one weapon, magazine or backpack lies here (items are not counted).
private _weapons = count weaponCargo _pile;
private _magazines = count magazineCargo _pile;
private _backpacks = count backpackCargo _pile;

if (_weapons + _magazines + _backpacks != 1 || {_backpacks == 1}) exitWith {false};

// Weapons come first in the pile's entries, then magazines: the one thing is the first.
private _entry = ([_pile] call EFUNC(storage,getContents)) param [0, createHashMap];
private _class = _entry getOrDefault ["class", ""];

if (_class isEqualTo "") exitWith {false};

// Not what the cargo lists say lies there (a hidden entry, a changed pile): AIME's own pick-up decides.
if (_weapons == 1 && {(_entry getOrDefault ["attachments", []]) isEqualTo []}) exitWith {false};
if (_magazines == 1 && {toLowerANSI _class isNotEqualTo toLowerANSI ((magazineCargo _pile) select 0)}) exitWith {false};

// A weapon for an empty slot is wielded by the game's own action, as AIME had it.
private _wield = false;

if (_weapons == 1) then {
    private _slot = [_player, _class] call EFUNC(storage,slotFor);

    _wield = _slot in ["primary", "handgun", "launcher", "binocular"]
        && {count ([_player, _slot] call EFUNC(storage,getSlot)) == 0};
};

if (_wield) exitWith {false};

private _target = objNull;

{
    if ([_x, _entry] call EFUNC(storage,hasRoom)) exitWith {
        _target = _x;
    };
} forEach ([_player, _class] call EFUNC(storage,unitTargets));

if (isNull _target) exitWith {
    [LELSTRING(gui,Hint_NowhereToGo)] call EFUNC(storage,useHint);

    true
};

// The same movement AIME played for a magazine.
_player playAction "PutDown";

private _status = [_pile, _target, _entry, -1, [], _player] call EFUNC(storage,moveEntry);

// "" it is in, "Requested" the server carries it on and settles whatever goes wrong; else why not.
if !(_status in ["", "Requested"]) then {
    private _text = switch (_status) do {
        case "NoRoom": {LELSTRING(gui,Hint_NowhereToGo)};
        case "NoBackpack": {LELSTRING(gui,Hint_NoBackpack)};
        case "OutOfReach": {LELSTRING(gui,Hint_OutOfReach)};
        case "Gone": {LELSTRING(gui,Hint_Gone)};
        case "Taken": {LELSTRING(gui,Hint_Taken)};
        case "Moved": {LELSTRING(gui,Hint_Moved)};
        case "NotReady": {LELSTRING(gui,Hint_NotReady)};
        default {LELSTRING(gui,Hint_Failed)};
    };

    [_text] call EFUNC(storage,useHint);
};

true
