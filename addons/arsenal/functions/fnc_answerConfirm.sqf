#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * "Remove and close" of the question fnc_confirmClose asks: everything that lies on no cell of the unit's
 * uniform, vest and backpack is taken out (fnc_dropOverflow - the arsenal's own unit is local, and ACE hears
 * of each removal as of its own), the RPT says what went, and ACE Arsenal's window closes with the exit code
 * the player asked for.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call aio_arsenal_fnc_answerConfirm;
 *
 * Public: No
 */

disableSerialization;

// Answered already: a second click.
if (isNull (uiNamespace getVariable [QGVAR(confirm), controlNull])) exitWith {};

private _display = uiNamespace getVariable [QGVAR(display), displayNull];
private _code = uiNamespace getVariable [QGVAR(confirmCode), 1];

[] call FUNC(closeConfirm);

if (isNull _display) exitWith {};

private _center = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];
private _gone = [_center] call FUNC(dropOverflow);

if (count _gone > 0) then {
    private _list = [];

    {
        _list pushBack format ["%1 x%2", _x, _y];
    } forEach _gone;

    private _text = _list joinString ", ";

    INFO_1("Closing ACE Arsenal: removed what did not fit - %1.",_text);
};

_display closeDisplay _code;
