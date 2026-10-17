#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Looks whether the soldier was taken away from the loot, at each check of the open window (fnc_onFrame, every
 * CHECK_INTERVAL seconds, after the checks whether the window should stay open at all): into a vehicle,
 * handcuffed or surrendering by ACE, dragging or carrying, or moved more than TAKEN_LEASH metres from where the
 * window opened. The window closes then (GVAR(closeReason) "taken", so no sound of a container closing and no end
 * move). Seated, the vehicle moves him and the leash is not asked: the vehicle he sits in (and the crates of its
 * ACE cargo) goes along, and anything else he opened from the seat is held to the window's reach from where he
 * sits now (einv_storage_fnc_inReach).
 *
 * Only for a window that was opened on something to loot (GVAR(openedOn)); the Arsenal and later windows have no
 * loot to be taken from.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * It closed the window <BOOL>
 *
 * Example:
 * [_display] call einv_gui_fnc_checkTaken;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

if !([] call FUNC(isInventoryMode)) exitWith {false};

private _unit = GVAR(unit);

if (!isNull GVAR(openedOn) && {
    objectParent _unit isNotEqualTo GVAR(openParent)
    || {_unit getVariable [QACEGVAR(captives,isHandcuffed), false]}
    || {_unit getVariable [QACEGVAR(captives,isSurrendering), false]}
    || {_unit getVariable [QACEGVAR(dragging,isDragging), false]}
    || {_unit getVariable [QACEGVAR(dragging,isCarrying), false]}
    || {isNull GVAR(openParent) && {(_unit distance2D (ASLToAGL GVAR(openPos))) > TAKEN_LEASH}}
    || {!isNull GVAR(openParent) && {!([_unit, GVAR(openedOn)] call EFUNC(storage,inReach))}}
}) exitWith {
    ["taken"] call FUNC(closeDisplay);
    true
};

false
