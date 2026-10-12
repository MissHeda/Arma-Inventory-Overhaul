#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the Enhanced Arsenal may do with a kit: nothing, take things out of it, or take things out and pack
 * new ones in. It is the setting of Enhanced First Aid Kits for the kit's type (its "arsenal editing"; in
 * the Eden editor always everything, the mission maker sets the mission up), asked through that mod so the
 * two arsenals agree. A class that is no kit is not the Arsenal's to change: nothing.
 *
 * Arguments:
 * 0: Kit class, prototype or instance <STRING>
 *
 * Return Value:
 * 0 - nothing, 1 - take out only, 2 - everything <NUMBER>
 *
 * Example:
 * ["efak_IFAK_7"] call einv_compat_efak_fnc_arsenalEditing;
 *
 * Public: Yes
 */

params [["_kit", "", [""]]];

if (_kit isEqualTo "" || {isNil QEFAKFUNC(core,getArsenalEditing)} || {!([_kit] call FUNC(isKit))}) exitWith {0};

[_kit] call EFAKFUNC(core,getArsenalEditing)
