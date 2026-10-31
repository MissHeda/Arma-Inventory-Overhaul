#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Asks the addons of other mods the same question and collects what they answer: each function in the
 * list that exists - the addon of a mod that is loaded - is called with the same arguments and what it
 * returns, when it is an array, is added to the result. The window never names another mod's function
 * itself: this is the one guarded call, in a loop. Used for the radios of TFAR and ACRE2, which never load
 * together (aio_compat_tfar, aio_compat_acre).
 *
 * Arguments:
 * 0: Names of the functions, e.g. [QEFUNC(compat_tfar,tooltip), QEFUNC(compat_acre,tooltip)] <ARRAY of STRINGs>
 * 1: What each is called with <ANY> (default: [])
 *
 * Return Value:
 * What they returned, joined <ARRAY>
 *
 * Example:
 * [[QEFUNC(compat_tfar,tooltip), QEFUNC(compat_acre,tooltip)], [_class, objNull]] call aio_gui_fnc_compatCollect;
 *
 * Public: No
 */

params [["_names", [], [[]]], ["_args", []]];

private _result = [];

{
    if (!isNil _x) then {
        private _answer = _args call (missionNamespace getVariable _x);

        if (!isNil "_answer" && {_answer isEqualType []}) then {
            _result append _answer;
        };
    };
} forEach _names;

_result
