#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Whether anyone may change a living person's gear by the server's settings: take items out of their
 * uniform, vest or backpack and put items in ("items"), or take off what they wear ("worn"). Opened by
 * the backpack only (fnc_canOpenPerson), nothing else of theirs is there to touch; a container the
 * mission locked (lockInventory) stays shut.
 *
 * Settings and state only, so the machine that changes their gear asks it again before every op
 * (fnc_personGuard). One who died meanwhile is a body, open to everyone like every body.
 *
 * Arguments:
 * 0: Person <OBJECT>
 * 1: Kind - "items" or "worn" <STRING>
 * 2: The person's uniform, vest or backpack the item lies in, objNull for a slot <OBJECT>
 *    (default: objNull)
 *
 * Return Value:
 * Allowed <BOOL>
 *
 * Example:
 * [cursorObject, "items", backpackContainer cursorObject] call einv_gui_fnc_canTouchPerson;
 *
 * Public: No
 */

params [["_person", objNull, [objNull]], ["_kind", "items", [""]], ["_root", objNull, [objNull]]];

if (!alive _person) exitWith {true};

private _mode = [_person] call FUNC(canOpenPerson);

if (_mode isEqualTo "") exitWith {false};

if (_mode isEqualTo "backpack" && {_kind isEqualTo "worn" || {_root isNotEqualTo backpackContainer _person}}) exitWith {false};

if (!isNull _root && {lockedInventory _root}) exitWith {false};

switch ([GVAR(personItems), GVAR(personWorn)] select (_kind isEqualTo "worn")) do {
    case ACCESS_EVERYONE: {true};
    case ACCESS_HELPLESS: {[_person] call FUNC(isHelpless)};
    default {false};
}
