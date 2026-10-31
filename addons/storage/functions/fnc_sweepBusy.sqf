#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the player is in the middle of something the overflow sweep (fnc_requestSweep) must not take a
 * tile out of: an arsenal is open (ACE's or the vanilla one: they add and take back on their own), a loadout
 * was just set in ACE Arsenal (its quiet frames, einv_arsenal_loadoutFrame), a magazine is being repacked,
 * and - only while the window is open - a tile is pressed or dragged (a hotbar binding too), a move of the
 * window is under way or waits in the hands' queue, or an answer of the window is not finished. A tile that
 * is dragged away would be "Gone" when it is let go.
 *
 * Another addon's state is read as a variable with a default, so this works without it. Nothing is
 * asked of the window's variables while it is closed: its last moves may have left entries nobody finishes.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Busy <BOOL>
 *
 * Example:
 * [] call einv_storage_fnc_sweepBusy;
 *
 * Public: No
 */

if (ARSENAL_OPEN) exitWith {true};

if (diag_frameNo <= (missionNamespace getVariable [QEGVAR(arsenal,loadoutFrame), -1])) exitWith {true};

if (!isNil QEFUNC(magazines,isBusy) && {[] call EFUNC(magazines,isBusy)}) exitWith {true};

if (isNull (uiNamespace getVariable [QEGVAR(gui,display), displayNull])) exitWith {false};

(missionNamespace getVariable [QEGVAR(gui,press), []]) isNotEqualTo []
|| {(missionNamespace getVariable [QEGVAR(gui,dragging), false]) isEqualTo true}
|| {(missionNamespace getVariable [QEGVAR(gui,stripDrag), []]) isNotEqualTo []}
|| {(count (missionNamespace getVariable [QEGVAR(gui,inFlight), createHashMap])) > 0}
|| {(missionNamespace getVariable [QEGVAR(gui,handQueue), []]) isNotEqualTo []}
|| {(missionNamespace getVariable [QEGVAR(gui,answers), []]) isNotEqualTo []}
