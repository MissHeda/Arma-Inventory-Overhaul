#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Mag Repack (Antistasi's core\Scripts\MagRepack, made by its own script on the client): while its window is open it
 * takes magazines out and adds them back with addMagazine, which lays them out first-fit wherever the engine put them.
 * Its window's two ends are wrapped here - opening (outlw_MR_createDialog) notes where everything lay (fnc_layoutOf),
 * closing (outlw_MR_onDialogDestroy) writes it back (fnc_restorePlaces): every magazine finds its cell again by its
 * kind, the repacked ones too. Run every MAGREPACK_TICK seconds (XEH_postInit): its script makes both functions anew
 * after a respawn, and they are wrapped again. Nothing while Mag Repack is not there.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Wrapped now <BOOL>
 *
 * Example:
 * call aio_compat_antistasi_fnc_wrapMagRepack;
 *
 * Public: No
 */

if (isNil "outlw_MR_createDialog" || {isNil "outlw_MR_onDialogDestroy"}) exitWith {false};
if (!(outlw_MR_createDialog isEqualType {}) || {!(outlw_MR_onDialogDestroy isEqualType {})}) exitWith {false};

// Each end wrapped on its own: one Mag Repack made anew keeps its new code, one still ours is left as it is.
private _wrapped = false;

if (outlw_MR_createDialog isNotEqualTo GVAR(mrCreateWrapper)) then {
    GVAR(mrCreate) = outlw_MR_createDialog;
    outlw_MR_createDialog = GVAR(mrCreateWrapper);
    _wrapped = true;
};

if (outlw_MR_onDialogDestroy isNotEqualTo GVAR(mrDestroyWrapper)) then {
    GVAR(mrDestroy) = outlw_MR_onDialogDestroy;
    outlw_MR_onDialogDestroy = GVAR(mrDestroyWrapper);
    _wrapped = true;
};

_wrapped
