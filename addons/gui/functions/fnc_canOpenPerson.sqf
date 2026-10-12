#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * How a living person may be opened at all, by the server's settings and the person's state: whole -
 * uniform, vest and backpack - or only by the backpack, as the engine's own action opens them. No
 * reach and no player here, so it answers the same on any machine, the person's own included
 * (fnc_canTouchPerson, fnc_personGuard).
 *
 * Nothing opens an ACE dragging clone (a copy of a body's gear) or a person a mission closed with
 * einv_noAccess.
 *
 * Arguments:
 * 0: Person <OBJECT>
 * 1: May open whole - false where the player switched the window off and the vanilla inventory,
 *    which shows a conscious person only by their backpack, stands in <BOOL> (default: true)
 *
 * Return Value:
 * "whole", "backpack", or "" when not at all <STRING>
 *
 * Example:
 * [cursorObject] call einv_gui_fnc_canOpenPerson;
 *
 * Public: No
 */

params [["_person", objNull, [objNull]], ["_wholeAllowed", true, [false]]];

if (!alive _person || {!(_person isKindOf "CAManBase")}) exitWith {""};

// ACE's stand-in for a body being dragged or carried wears a copy of the body's gear - opening it would
// make everything twice. Its class can be changed in config, its variable cannot.
if (_person isKindOf QACEGVAR(dragging,clone) || {!isNil {_person getVariable QACEGVAR(dragging,original)}}) exitWith {""};

if (_person getVariable ["einv_noAccess", false]) exitWith {""};

// The unconscious always open whole, as ACE's "Inventory" opens them.
if (_wholeAllowed && {
    switch (GVAR(personOpen)) do {
        case ACCESS_EVERYONE: {true};
        case ACCESS_HELPLESS: {[_person] call FUNC(isHelpless)};
        default {lifeState _person isEqualTo "INCAPACITATED"};
    }
}) exitWith {"whole"};

// Otherwise their backpack, as the engine's own action opens it - one that can be opened at all
// (ace_interaction_fnc_canOpenBackpack asks the same).
private _backpack = backpackContainer _person;

if (
    isNull _backpack || {lockedInventory _backpack} || {maxLoad _backpack <= 0}
    || {getNumber (configOf _backpack >> "disableInventory") == 1}
) exitWith {""};

"backpack"
