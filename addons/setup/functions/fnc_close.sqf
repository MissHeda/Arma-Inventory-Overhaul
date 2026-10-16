#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Closes the wizard - after asking, when the draft holds changes not saved: they would be gone. The card says
 * "You have unsaved changes." and offers three answers: "Save and close" (saves as Save at Review does - the
 * conflict question and the checks included - and closes once it is saved; only offered where this wizard may
 * save at all), "Close without saving" (in the loss colour) and "Keep editing", which Escape is as well.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_setup_fnc_close;
 *
 * Public: No
 */

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (isNull _display) exitWith {};

if (call FUNC(isDirty)) exitWith {
    private _discard = {
        (uiNamespace getVariable [QGVAR(display), displayNull]) closeDisplay 2;
    };

    // Saving is offered where it is allowed; the last answer is the one that does it, so it is Save then.
    if (GVAR(readOnly)) then {
        [
            _display, LLSTRING(Discard_Body), LLSTRING(Discard_Close), _discard, [], LLSTRING(Discard_Keep), [], LLSTRING(Discard_Title), "danger"
        ] call FUNC(confirm);
    } else {
        [
            _display, LLSTRING(Discard_Body), LLSTRING(Discard_Save), {
                // Saved as Review's Save does it; closed once the draft is the saved one. A question on the way
                // (someone else saved meanwhile) or a refusal leaves it open, with the reason in the hint.
                [] call FUNC(save);

                if (!(call FUNC(isDirty))) then {
                    (uiNamespace getVariable [QGVAR(display), displayNull]) closeDisplay 2;
                };
            }, [], LLSTRING(Discard_Keep), [[LLSTRING(Discard_Close), _discard, "danger"]], LLSTRING(Discard_Title)
        ] call FUNC(confirm);
    };
};

_display closeDisplay 2;
