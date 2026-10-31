#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a soldier cannot keep anyone out of their gear: unconscious, or a captive - surrendered or
 * handcuffed with ACE. The settings for living persons let "Unconscious and captives" do more to them
 * (aio_gui_personOpen, personItems, personWorn).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Helpless <BOOL>
 *
 * Example:
 * [cursorObject] call aio_gui_fnc_isHelpless;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

lifeState _unit isEqualTo "INCAPACITATED"
|| {_unit getVariable [QACEGVAR(captives,isSurrendering), false]}
|| {_unit getVariable [QACEGVAR(captives,isHandcuffed), false]}
