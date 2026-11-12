#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The box a weapon takes in a scene as it is fitted out - the weapon itself and what it carries: muzzle attachment, rail
 * attachment, optic, bipod and the loaded magazine, each where the weapon's model has its slot (its proxy) - as the eight
 * corners of that box in the world, on the scene's holder. For putting the whole weapon in the middle of its picture and
 * fitting it to it (fnc_cardScene, fnc_inspect3D): a suppressor makes it longer at the muzzle, an optic higher, a magazine or
 * a bipod deeper, and the middle of the picture is the middle of all of it.
 *
 * Each model's own box is fnc_modelBox's (without the proxies' corners). A part's box is carried into the weapon's model by
 * its slot's place and axes; a muzzle attachment on a weapon without a muzzle slot sits at the muzzle. The box in the
 * weapon's model is kept on the scene for the weapon and parts it was made for; onto the holder it goes as the parts'
 * places do (fnc_weaponPoints).
 *
 * Arguments:
 * 0: The scene (fnc_cardScene, fnc_inspect3D): "class", "fitted" (optional: the weapon with its parts, as
 *    addWeaponWithAttachmentsCargo takes it) and "objects" with the holder second <HASHMAP>
 *
 * Return Value:
 * The eight corners in the world (ASL) <ARRAY>, nil while the holder's model is not loaded, [] where there is no holder
 *
 * Example:
 * [_scene] call aio_gui_fnc_weaponBounds;
 *
 * Public: No
 */

params [["_scene", createHashMap, [createHashMap]]];

private _class = _scene getOrDefault ["class", ""];
private _fitted = _scene getOrDefault ["fitted", [_class]];

// ----- In the weapon's model, once per weapon and parts -----
if ((_scene getOrDefault ["boundsFor", []]) isNotEqualTo _fitted) then {
    private _least = [-0.3, -0.05, -0.1];
    private _most = [0.3, 0.05, 0.1];
    private _model = [_class] call FUNC(itemModel);
    private _probe = if (_model isEqualTo "") then {objNull} else {createSimpleObject [_model, [0, 0, 0], true]};

    if (!isNull _probe) then {
        ([_probe] call FUNC(modelBox)) params ["_boxMin", "_boxMax"];

        _least = +_boxMin;
        _most = +_boxMax;

        // The first visual LOD the engine finds proxies in by its resolution (not every LOD is found by it).
        private _visual = -1;
        private _proxies = [];

        {
            _x params ["", "", ["_resolution", -1]];

            if (_proxies isEqualTo [] && {_resolution >= 0.5} && {_resolution < 900}) then {
                _proxies = (_probe selectionNames _resolution) select {"proxy:" in _x};
                _visual = _resolution;
            };
        } forEach (allLODs _probe);

        // A slot's place and axes in the weapon's model: [place, direction, up], or [].
        private _fnc_slot = {
            params ["_patterns"];

            private _name = _proxies param [_proxies findIf {private _proxy = _x; _patterns findIf {_x in _proxy} >= 0}, ""];

            if (_name isEqualTo "") exitWith {[]};

            // Its place first: that loads the LOD, which selectionVectorDirAndUp needs loaded (fnc_modelBox).
            private _place = _probe selectionPosition [_name, _visual];

            (_probe selectionVectorDirAndUp [_name, _visual]) params [["_dir", [0, 1, 0]], ["_up", [0, 0, 1]]];

            [_place, _dir, _up]
        };

        _fitted params ["", ["_muzzle", ""], ["_rail", ""], ["_optic", ""], ["_magazine", []], "", ["_bipod", ""]];

        private _magazineClass = if (_magazine isEqualType []) then {_magazine param [0, "", [""]]} else {""};
        private _magazineConfig = configFile >> "CfgMagazines" >> _magazineClass;
        private _magazineModel = ["", getText (_magazineConfig >> "modelSpecial")] select (
            _magazineClass isNotEqualTo "" && {getNumber (_magazineConfig >> "modelSpecialIsProxy") > 0}
        );

        // Without a muzzle slot the attachment sits at the muzzle.
        private _muzzleSlot = [["weapon_slots\muzzle"]] call _fnc_slot;

        if (_muzzleSlot isEqualTo []) then {
            private _point = ([_scene, true] call FUNC(weaponPoints)) getOrDefault ["muzzle", []];

            if (count _point == 3) then {
                _muzzleSlot = [_point, [0, 1, 0], [0, 0, 1]];
            };
        };

        {
            _x params ["_partModel", "_slot", ["_folded", false], ["_small", true]];

            if (_partModel isEqualTo "" || {_slot isEqualTo []}) then {continue};

            private _part = createSimpleObject [_partModel, [0, 0, 0], true];

            if (isNull _part) then {continue};

            ([_part] call FUNC(modelBox)) params ["_partMin", "_partMax"];
            deleteVehicle _part;

            // A bipod's model stands on its legs, but on a weapon that lies somewhere it is folded up under the barrel: only
            // its top BIPOD_FOLDED counts, or the box reached a leg's length under the weapon and the weapon sat too high (the
            // M14 EBR with a Harris bipod, measured in game, 0.7.10).
            if (_folded) then {
                _partMin set [2, (_partMin select 2) max ((_partMax select 2) - BIPOD_FOLDED)];
            };

            // An attachment is a small thing round its slot: what its model says beyond PART_REACH beside, below or above the slot
            // is something hidden on it, not its shape - RHS's ACOG measured 26 cm high, and the M4 it sat on came out half as
            // large as its card (measured in game, 0.7.13). Not a magazine: a drum hangs deep.
            if (_small) then {
                (PART_REACH) params ["_beside", "_below", "_above"];

                _partMin set [1, (_partMin select 1) max -_beside];
                _partMax set [1, (_partMax select 1) min _beside];
                _partMin set [2, (_partMin select 2) max -_below];
                _partMax set [2, (_partMax select 2) min _above];
            };

            _slot params ["_place", "_dir", "_up"];

            private _right = _dir vectorCrossProduct _up;

            {
                _x params ["_atX", "_atY", "_atZ"];

                private _corner = _place vectorAdd (_right vectorMultiply _atX) vectorAdd (_dir vectorMultiply _atY) vectorAdd (_up vectorMultiply _atZ);

                {
                    _least set [_x, (_least select _x) min (_corner select _x)];
                    _most set [_x, (_most select _x) max (_corner select _x)];
                } forEach [0, 1, 2];
            } forEach [
                [_partMin select 0, _partMin select 1, _partMin select 2], [_partMax select 0, _partMin select 1, _partMin select 2],
                [_partMin select 0, _partMax select 1, _partMin select 2], [_partMax select 0, _partMax select 1, _partMin select 2],
                [_partMin select 0, _partMin select 1, _partMax select 2], [_partMax select 0, _partMin select 1, _partMax select 2],
                [_partMin select 0, _partMax select 1, _partMax select 2], [_partMax select 0, _partMax select 1, _partMax select 2]
            ];
        } forEach [
            [[[_muzzle, ""] select !(_muzzle isEqualType "")] call FUNC(itemModel), _muzzleSlot],
            [[[_rail, ""] select !(_rail isEqualType "")] call FUNC(itemModel), [["weapon_slots\side"]] call _fnc_slot],
            [[[_optic, ""] select !(_optic isEqualType "")] call FUNC(itemModel), [["weapon_slots\top"]] call _fnc_slot],
            [[[_bipod, ""] select !(_bipod isEqualType "")] call FUNC(itemModel), [["weapon_slots\underbarrel", "weapon_slots\bipod"]] call _fnc_slot, true],
            [_magazineModel, [["magazineslot"]] call _fnc_slot, false, false]
        ];

        deleteVehicle _probe;
    };

    _scene set ["boundsFor", +_fitted];
    _scene set ["boundsModel", [_least, _most]];
};

// ----- On the holder of the scene far off -----
private _holder = (_scene getOrDefault ["objects", []]) param [1, objNull];

if (isNull _holder) exitWith {[]};

private _proxy = "proxy:\a3\characters_f\proxies\weapon.001";
private _base = _holder selectionPosition [_proxy, 0.5];

// The holder's model is not loaded yet.
if (_base isEqualTo [0, 0, 0]) exitWith {nil};

(_holder selectionVectorDirAndUp [_proxy, 0.5]) params [["_dir", [0, 1, 0]], ["_up", [0, 0, 1]]];

private _right = _dir vectorCrossProduct _up;

(_scene get "boundsModel") params ["_least", "_most"];

private _corners = [];

{
    private _atX = _x;

    {
        private _atY = _x;

        {
            private _onHolder = _base vectorAdd (_right vectorMultiply _atX) vectorAdd (_dir vectorMultiply _atY) vectorAdd (_up vectorMultiply _x);

            _corners pushBack (_holder modelToWorldWorld _onHolder);
        } forEach [_least select 2, _most select 2];
    } forEach [_least select 1, _most select 1];
} forEach [_least select 0, _most select 0];

_corners
