#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How far down a scrolling group - a column, a kit window's body - shows its content, in screen height
 * from the top: kept that way rather than as the scroll bar's place, a group drawn again with more or
 * less in it shows the same things where they were (fnc_build, fnc_clearWindows, fnc_raiseWindow).
 *
 * A group made only a moment ago does not know its height yet: the scroll it is still to get
 * (QGVAR(scrollRestore), put back by fnc_onFrame) counts as its own, so two builds in one frame lose
 * nothing, and a tile is found where it will stand (fnc_gridOrigin).
 *
 * Arguments:
 * 0: The group <CONTROL>
 *
 * Return Value:
 * Screen height scrolled past <NUMBER>
 *
 * Example:
 * [_group] call einv_gui_fnc_scrollPixels;
 *
 * Public: No
 */

disableSerialization;

params [["_group", controlNull, [controlNull]]];

if (isNull _group) exitWith {0};

private _pending = uiNamespace getVariable [QGVAR(scrollRestore), []];
private _index = _pending findIf {(_x select 0) isEqualTo _group};

if (_index >= 0) exitWith {(_pending select _index) select 1};

(ctrlPosition _group) params ["", "", "", "_groupH"];

(((ctrlScrollValues _group) select 0) max 0) * (((_group getVariable [QGVAR(contentH), _groupH]) - _groupH) max 0)
