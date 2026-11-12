#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Keeps the magazines right when WebKnight's Two Primary Weapons takes the weapon off the back (issue 74). That mod does not
 * put the weapon's own magazine back into it: it adds a new one of its class to the soldier's uniform, vest or backpack
 * (addMagazine), lets addWeapon load whatever fits from there and then sets that magazine's rounds. With every container full
 * the new magazine is refused and the weapon comes out empty - and the next switch notes the other weapon with no magazine as
 * well - or a spare one is loaded and its rounds overwritten (measured in game, with and without this mod, 0.7.14). With room
 * it may load a spare of other rounds and leave the new full one behind.
 *
 * So what the weapon on the back carries and what magazines of that class lie in the soldier's containers is noted before a
 * switch, and after it both are put right: the containers hold those magazines again, each with its rounds and where it lay
 * (with the cargo commands, which a full container does not refuse), and the weapon holds its own magazine with its own rounds
 * (addWeaponItem, which needs no room). Nothing is touched where the switch left it all right.
 *
 * Modes:
 *   "note"   - what is on the back and in the containers now: [weapon as WebKnight notes it or [], magazines] - asked right
 *              before a switch, and every GUARD_NOTE seconds for the switch that mod makes by itself when the primary weapon
 *              is put away (its Put handler cannot be wrapped)
 *   "watch"  - waits for the weapon noted to come into the hands, GUARD_WAIT seconds at most (that mod's switch plays its
 *              gesture first and gives up when the weapon in hand changes meanwhile), then "repair". Scheduled.
 *   "repair" - puts the magazines right
 *
 * Arguments:
 * 0: Mode <STRING>
 * 1: Unit <OBJECT>
 * 2: "watch", "repair": what "note" answered <ARRAY> (default: [])
 *
 * Return Value:
 * "note": [weapon, magazines] <ARRAY>; "repair": something was put right <BOOL>; else nothing
 *
 * Example:
 * ["note", player] call aio_compat_wbk_twoprimary_fnc_guard;
 *
 * Public: No
 */

#define GUARD_WAIT 5

params [["_mode", "", [""]], ["_unit", objNull, [objNull]], ["_noted", [], [[]]]];

// The magazines lying in the unit's containers: [class, rounds, "Uniform", "Vest" or "Backpack"].
private _fnc_magazines = {
    ((magazinesAmmoFull _this) select {!(_x select 2) && {(_x select 4) in ["Uniform", "Vest", "Backpack"]}}) apply {[_x select 0, _x select 1, _x select 4]}
};

switch (_mode) do {
    case "note": {
        private _back = (_unit getVariable ["WBK_SecondWeapon", []]) param [1, []];

        [[[], +_back] select (_back isEqualType []), _unit call _fnc_magazines]
    };

    case "watch": {
        _noted params [["_back", [], [[]]], ["_magazines", [], [[]]]];

        private _class = _back param [0, "", [""]];

        if (_class isEqualTo "" || {!local _unit}) exitWith {};

        private _until = time + GUARD_WAIT;

        waitUntil {
            sleep 0.05;

            time > _until || {!alive _unit} || {
                primaryWeapon _unit == _class && {((_unit getVariable ["WBK_SecondWeapon", []]) param [1, []]) isNotEqualTo _back}
            }
        };

        if (time > _until || {!alive _unit}) exitWith {};

        // That mod's commands follow each other in a scheduled script: all of them through before anything is put right.
        sleep 0.25;

        ["repair", _unit, _noted] call FUNC(guard);
    };

    case "repair": {
        _noted params [["_back", [], [[]]], ["_magazines", [], [[]]]];
        _back params [["_class", "", [""]], "", "", "", ["_magazine", [], [[]]]];

        if (_class isEqualTo "" || {!local _unit} || {primaryWeapon _unit != _class}) exitWith {false};

        // WebKnight notes a weapon without a magazine as [nil, 0].
        private _mag = _magazine param [0, ""];
        private _rounds = _magazine param [1, 0];

        if (isNil "_mag" || {!(_mag isEqualType "")} || {_mag isEqualTo ""}) exitWith {false};
        if (isNil "_rounds" || {!(_rounds isEqualType 0)}) then {_rounds = 0};

        private _fixed = false;

        // The containers' magazines of that class as they lay before the switch: rounds and place, in any order.
        private _fnc_ofClass = {
            private _list = (_this select {(_x select 0) == _mag}) apply {[_x select 1, _x select 2]};

            _list sort true;
            _list
        };

        private _was = _magazines call _fnc_ofClass;

        if (((_unit call _fnc_magazines) call _fnc_ofClass) isNotEqualTo _was) then {
            _unit removeMagazines _mag;

            {
                _x params ["_count", "_place"];

                private _container = switch (_place) do {
                    case "Uniform": {uniformContainer _unit};
                    case "Vest": {vestContainer _unit};
                    default {backpackContainer _unit};
                };

                if (!isNull _container) then {
                    _container addMagazineAmmoCargo [_mag, 1, _count];
                };
            } forEach _was;

            _fixed = true;
        };

        // The weapon's own magazine in it, with its own rounds - looked at after the containers: taking their magazines out may
        // have taken the loaded one too.
        if (((primaryWeaponMagazine _unit) param [0, ""]) != _mag) then {
            _unit addWeaponItem [_class, [_mag, _rounds], true];
            _fixed = true;
        } else {
            if ((_unit ammo _class) != _rounds) then {
                _unit setAmmo [_class, _rounds];
                _fixed = true;
            };
        };

        if (_fixed) then {
            INFO_3("WebKnight's switch left the magazines wrong - put right: %1 holds %2 with %3 rounds again.",_class,_mag,_rounds);

            if (!isNil QEFUNC(gui,requestRebuild)) then {
                call EFUNC(gui,requestRebuild);
            };
        };

        _fixed
    };
};
