#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Folds the second primary's card to a single line, or opens it again (fnc_drawEquipmentCards) - a click on the
 * chevron in its corner. Folded it still shows the weapon's name and still takes a weapon dragged onto it, but not
 * its attachments, so the column does not keep the room of a card that is not used. The choice is each player's
 * own, kept in the profile (GVAR(secondFold)); until the first click the card is folded while the back is empty.
 *
 * Arguments:
 * 0: Folded now, as the card is drawn <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [true] call aio_gui_fnc_toggleSecondFold;
 *
 * Public: No
 */

params [["_folded", false, [false]]];

GVAR(secondFold) = ["folded", "open"] select _folded;
profileNamespace setVariable [QGVAR(secondFold), GVAR(secondFold)];
saveProfileNamespace;

[] call FUNC(buildSoon);
