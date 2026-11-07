#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The weapon cards' real pictures (fnc_drawEquipmentCards, Mia after 0.6.78): each of the player's weapons as it really looks, with the
 * attachments, magazine and bipod it carries, filmed side on - the muzzle to the left, as Arma's own pictures show a weapon - into
 * a texture of its own (render to texture) that its card shows in the place of the flat picture and the white marks
 * (fnc_drawAttachments). The way the inspect card's 3D view does it (fnc_inspect3D): a scene far off the map, a dark sphere round
 * a scripted weapon holder, three lights and a camera. One scene per weapon slot, each in a sphere of its own, apart from the
 * inspect card's.
 *
 * A scene stands while its card is shown: drawn again with the same weapon and parts it is kept as it is, with other parts only the
 * holder is fitted out anew, another weapon makes it anew. "keep" takes away the scenes of the slots no card was drawn for, "stop"
 * all of them (the window closing, fnc_onUnload). Until the holder's model is loaded the camera looks from the front left; then it
 * turns side on to the barrel (fnc_weaponPoints finds the muzzle).
 *
 * Only with Picture-in-Picture on (isPiPEnabled) and the player's setting aio_gui_weapon3D: else the cards stay flat.
 *
 * Arguments:
 * 0: What to do <STRING>
 *    "show" a slot's scene for this weapon (arguments: [slot, weapon as fnc_getEquipment has it, render target, background RGB,
 *           [share of the picture's width the card shows, share of its height]]) - the camera stands so far off that the whole
 *           weapon fits what the card shows of the picture, whatever size the layout gives the card
 *    "keep" only these slots' scenes stay (arguments: [slots])
 *    "stop" every scene goes
 * 1: Arguments <ARRAY> (default: [])
 *
 * Return Value:
 * "show": the scene films into the target <BOOL>; else nothing
 *
 * Example:
 * ["show", ["primary", (weaponsItems player) select 0, "aio_card3d_primary_1024x512", [0.05, 0.05, 0.06]]] call aio_gui_fnc_cardScene;
 *
 * Public: No
 */

params [["_mode", "", [""]], ["_arguments", [], [[]]]];

if (isNil QGVAR(cardScenes)) then {GVAR(cardScenes) = createHashMap};

// A scene goes: what it films into is ended first - destroying a camera does not end it.
private _fnc_drop = {
    params ["_scene"];

    private _camera = _scene getOrDefault ["camera", objNull];

    if (!isNull _camera) then {
        _camera cameraEffect ["Terminate", "Back", _scene getOrDefault ["target3D", ""]];
        camDestroy _camera;
    };

    {
        if (!isNull _x) then {deleteVehicle _x};
    } forEach (_scene getOrDefault ["objects", []]);
};

// The weapon as the holder takes it: magazines as [class, rounds] or none.
private _fnc_fitOut = {
    params ["_weapon"];
    _weapon params [["_class", ""], ["_muzzle", ""], ["_pointer", ""], ["_optic", ""], ["_magazine", []], ["_magazine2", []], ["_bipod", ""]];

    if !(_magazine isEqualType [] && {count _magazine >= 2} && {(_magazine param [0, ""]) isNotEqualTo ""}) then {_magazine = []};
    if !(_magazine2 isEqualType [] && {count _magazine2 >= 2} && {(_magazine2 param [0, ""]) isNotEqualTo ""}) then {_magazine2 = []};

    [_class, _muzzle, _pointer, _optic, _magazine, _magazine2, _bipod]
};

// The camera at its turn and distance, looking at the weapon, the lights round it as the inspect card's.
private _fnc_camera = {
    params ["_scene"];

    private _camera = _scene getOrDefault ["camera", objNull];

    if (isNull _camera) exitWith {};

    private _target = _scene get "target";
    private _dir = _scene get "dir";
    private _pitch = _scene get "pitch";
    private _distance = _scene get "distance";
    private _across = (cos _pitch) * _distance;
    private _cameraPos = _target vectorAdd [(sin _dir) * _across, (cos _dir) * _across, (sin _pitch) * _distance];

    _camera camSetPos (ASLToAGL _cameraPos);
    _camera camSetTarget (ASLToAGL _target);
    _camera camSetFov INSPECT_3D_FOV;
    _camera camCommit 0;

    (_scene get "lights") params ["_key", "_fill", "_rim"];

    private _side = [cos _dir, -(sin _dir), 0];

    _key setPosASL ((_cameraPos vectorAdd (_side vectorMultiply (-0.5 * _distance))) vectorAdd [0, 0, 0.4 * _distance]);
    _fill setPosASL ((_cameraPos vectorAdd (_side vectorMultiply (0.7 * _distance))) vectorAdd [0, 0, -0.1 * _distance]);
    _rim setPosASL ((_target vectorAdd ((_target vectorDiff _cameraPos) vectorMultiply 0.8)) vectorAdd [0, 0, 0.5 * _distance]);
};

// How far off the camera stands: the whole weapon - its length across, its height up and down - inside what the card shows of the
// picture (its shares of the picture's width and height), with a little room round it. The picture's height at a distance is
// 2 * INSPECT_3D_FOV of it, its width that times the screen's shape (the target is filmed in the screen's shape).
private _fnc_frame = {
    params ["_scene"];

    (_scene getOrDefault ["shares", [1, 1]]) params [["_widthShare", 1], ["_heightShare", 1]];

    private _length = _scene getOrDefault ["length", _scene getOrDefault ["frameSize", 1]];
    private _height = _scene getOrDefault ["height", _length / 3];
    private _perMetre = 2 * INSPECT_3D_FOV;
    private _room = CARD_3D_ROOM;
    private _distance = ((_length / (_room * (_widthShare max 0.05) * _perMetre * INSPECT_3D_ASPECT)) max (_height / (_room * 0.75 * (_heightShare max 0.05) * _perMetre))) max 0.2;

    _scene set ["distance", _distance min 8];

    [_scene] call _fnc_camera;
};

switch (_mode) do {
    case "show": {
        _arguments params [
            ["_slot", "", [""]], ["_weapon", [], [[]]], ["_target3D", "", [""]], ["_background", [0.05, 0.055, 0.065], [[]]], ["_shares", [1, 1], [[]]]
        ];

        private _class = _weapon param [0, "", [""]];

        if (_slot isEqualTo "" || {_class isEqualTo ""} || {!isPiPEnabled} || {!(missionNamespace getVariable [QGVAR(weapon3D), true])}) exitWith {
            private _old = GVAR(cardScenes) getOrDefault [_slot, createHashMap];

            if (count _old > 0) then {
                [_old] call _fnc_drop;
                GVAR(cardScenes) deleteAt _slot;
            };

            false
        };

        private _fitted = [_weapon] call _fnc_fitOut;
        private _scene = GVAR(cardScenes) getOrDefault [_slot, createHashMap];

        // A still of this very weapon, parts, target and card size: kept as it is - nothing films any more.
        if (
            count _scene > 0 && {_scene getOrDefault ["frozen", false]} && {(_scene get "fitted") isEqualTo _fitted}
            && {(_scene get "target3D") isEqualTo _target3D} && {(_scene getOrDefault ["shares", []]) isEqualTo _shares}
        ) exitWith {true};

        // The same weapon still being filmed: kept - another target filmed into, other parts put on the holder.
        if (count _scene > 0 && {(_scene get "class") isEqualTo _class} && {!isNull (_scene getOrDefault ["camera", objNull])}) exitWith {
            if ((_scene get "target3D") isNotEqualTo _target3D) then {
                private _camera = _scene get "camera";

                _camera cameraEffect ["Terminate", "Back", _scene get "target3D"];
                _camera cameraEffect ["Internal", "Back", _target3D];
                _scene set ["target3D", _target3D];
            };

            if ((_scene getOrDefault ["shares", []]) isNotEqualTo _shares) then {
                _scene set ["shares", _shares];
                [_scene] call _fnc_frame;
            };

            if ((_scene get "fitted") isNotEqualTo _fitted) then {
                private _holder = (_scene get "objects") param [1, objNull];

                clearWeaponCargo _holder;
                clearMagazineCargo _holder;
                _holder addWeaponWithAttachmentsCargo [_fitted, 1];
                _scene set ["fitted", _fitted];
            };

            true
        };

        if (count _scene > 0) then {
            [_scene] call _fnc_drop;
        };

        // Its own place: a sphere of its own per slot, apart from each other and from the inspect card's.
        private _index = (["primary", "handgun", "launcher", "primary2"] find _slot) max 0;
        private _place = [(INSPECT_3D_PLACE select 0) + 600 * (_index + 1), (INSPECT_3D_PLACE select 1) - 900];
        private _sceneBase = _place + [((getTerrainHeightASL _place) max 0) + 300];
        private _objects = [];

        _scene = createHashMapFromArray [["class", _class], ["fitted", _fitted], ["target3D", _target3D], ["objects", _objects], ["shares", _shares]];
        GVAR(cardScenes) set [_slot, _scene];

        // The sphere in the card's own colour, so the picture sits on the card as the flat one did.
        _background params [["_red", 0.05], ["_green", 0.055], ["_blue", 0.065]];

        private _sphere = "Sphere_3DEN" createVehicleLocal [0, 0, 0];
        _sphere setPosASL _sceneBase;

        {
            _sphere setObjectTexture [_x, format ["#(argb,8,8,3)color(%1,%2,%3,1)", _red toFixed 3, _green toFixed 3, _blue toFixed 3]];
        } forEach [0, 1];

        _objects pushBack _sphere;

        private _holderPos = _sceneBase vectorAdd [0, 0, 100];
        private _holder = "GroundWeaponHolder_Scripted" createVehicleLocal [0, 0, 0];
        _holder setPosASL _holderPos;
        _holder setVectorDirAndUp [[0, 0, 1], [0, 1, 0]];
        _holder addWeaponWithAttachmentsCargo [_fitted, 1];
        _objects pushBack _holder;

        // Framed by the weapon's size, at most the inspect card's frame.
        private _frame = INSPECT_3D_FRAME;
        private _model = [_class] call FUNC(itemModel);

        if (_model isNotEqualTo "") then {
            private _probe = createSimpleObject [_model, [0, 0, 0], true];

            if (!isNull _probe) then {
                (0 boundingBoxReal _probe) params ["_boxMin", "_boxMax"];
                deleteVehicle _probe;

                _frame = ((vectorMagnitude (_boxMax vectorDiff _boxMin)) max 0.1) min INSPECT_3D_FRAME;
            };
        };

        // How far weaponPoints keeps a point from the holder: wide - the ends of a long weapon are points here (below).
        _scene set ["frame", 3];
        _scene set ["target", +_holderPos];
        _scene set ["origin", +_holderPos];
        _scene set ["dir", 45];
        _scene set ["pitch", 6];
        _scene set ["frameSize", _frame];
        _scene set ["distance", ((_frame * INSPECT_3D_DISTANCE * CARD_3D_DISTANCE) max 0.25) min 6];

        // Softer than the inspect card's: at its strength a black weapon came out white on the small card (seen in game, 0.6.88).
        _scene set ["lights", [[CARD_3D_LIGHT * 30, [1, 0.97, 0.92], [1, 0.97, 0.92]], [CARD_3D_LIGHT * 12, [0.6, 0.7, 0.9], [0.7, 0.8, 1]], [CARD_3D_LIGHT * 20, [1, 1, 1], [1, 0.9, 0.8]]] apply {
            _x params ["_brightness", "_ambient", "_colour"];

            private _light = "#lightpoint" createVehicleLocal [0, 0, 0];
            _light setPosASL _holderPos;
            _light setLightBrightness _brightness;
            _light setLightIntensity (_brightness * 10);
            _light setLightAmbient _ambient;
            _light setLightColor _colour;
            _light setLightUseFlare false;
            _light setLightDayLight true;
            _light setLightAttenuation [0, 1, 0, 0, 20, 40];
            _objects pushBack _light;

            _light
        }];

        private _camera = "camera" camCreate (ASLToAGL _holderPos);
        _camera cameraEffect ["Internal", "Back", _target3D];
        _camera camSetFocus [-1, -1];
        _scene set ["camera", _camera];

        [_scene] call _fnc_camera;

        // Once the holder's model is there: aimed at the weapon's base, side on to its barrel with the muzzle to the left.
        [
            {
                params ["_scene"];

                isNull (_scene getOrDefault ["camera", objNull]) || {
                    private _holder = (_scene get "objects") param [1, objNull];

                    !isNull _holder && {(_holder selectionPosition ["proxy:\a3\characters_f\proxies\weapon.001", 0.5]) isNotEqualTo [0, 0, 0]}
                        && {!isNil {[_scene] call FUNC(weaponPoints)}}
                }
            },
            {
                params ["_scene", "_fnc_camera", "_fnc_frame"];

                if (isNull (_scene getOrDefault ["camera", objNull])) exitWith {};

                private _holder = (_scene get "objects") select 1;
                private _base = _holder modelToWorldWorld (_holder selectionPosition ["proxy:\a3\characters_f\proxies\weapon.001", 0.5]);
                private _muzzle = ([_scene] call FUNC(weaponPoints)) getOrDefault ["muzzle", []];

                // The weapon's box in its model, its middle and its ends along the barrel and up and down, carried onto the holder
                // as the parts' places are (fnc_weaponPoints): the middle of the picture is the middle of the weapon - stock and
                // all, not the middle between its grip and its muzzle (Mia, 0.6.80: "not centred").
                private _model = [_scene get "class"] call FUNC(itemModel);
                private _probe = if (_model isEqualTo "") then {objNull} else {createSimpleObject [_model, [0, 0, 0], true]};
                private _inModel = [_scene, true] call FUNC(weaponPoints);

                if (!isNull _probe && {!isNil "_inModel"}) then {
                    (0 boundingBoxReal _probe) params ["_boxMin", "_boxMax"];
                    deleteVehicle _probe;

                    private _middle = (_boxMin vectorAdd _boxMax) vectorMultiply 0.5;
                    private _extent = _boxMax vectorDiff _boxMin;
                    private _muzzleInModel = _inModel getOrDefault ["muzzle", [0, 1, 0]];
                    private _along = 0;

                    // The barrel lies along the axis the muzzle is farthest out on; up and down is z, or y for a model laid on z.
                    {
                        if (abs (_muzzleInModel select _x) > abs (_muzzleInModel select _along)) then {_along = _x};
                    } forEach [1, 2];

                    private _upAxis = [2, 1] select (_along == 2);
                    private _fnc_at = {
                        params ["_axis", "_sign"];

                        private _point = +_middle;
                        _point set [_axis, (_point select _axis) + _sign * (_extent select _axis) / 2];
                        _point
                    };

                    _inModel set ["centre", _middle];
                    _inModel set ["front", [_along, 1] call _fnc_at];
                    _inModel set ["back", [_along, -1] call _fnc_at];
                    _inModel set ["top", [_upAxis, 1] call _fnc_at];
                    _inModel set ["bottom", [_upAxis, -1] call _fnc_at];

                    _scene deleteAt "points";
                } else {
                    if (!isNull _probe) then {deleteVehicle _probe};
                };

                private _points = [_scene] call FUNC(weaponPoints);

                if (isNil "_points") then {_points = createHashMap};

                // Never far from the weapon's base: a model's box is often blown up by its hit geometry (as the inspect card's frame
                // says), and a middle or ends far off left the card empty (Mia, 0.6.86).
                private _centre = _points getOrDefault ["centre", _base];

                if (_centre distance _base > 0.6) then {_centre = _base};

                _scene set ["target", _centre];

                private _front = _points getOrDefault ["front", []];
                private _back = _points getOrDefault ["back", []];
                private _top = _points getOrDefault ["top", []];
                private _bottom = _points getOrDefault ["bottom", []];

                if (count _front == 3 && {count _back == 3}) then {_scene set ["length", ((_front distance _back) max 0.25) min (INSPECT_3D_FRAME * 1.4)]};
                if (count _top == 3 && {count _bottom == 3}) then {_scene set ["height", ((_top distance _bottom) max 0.08) min ((_scene getOrDefault ["length", 1]) * 0.6)]};

                [_scene] call _fnc_frame;

                if (count _muzzle == 3) then {
                    private _barrel = _muzzle vectorDiff _base;
                    _barrel set [2, 0];

                    if (vectorMagnitude _barrel >= 0.05) then {
                        _barrel = vectorNormalized _barrel;

                        // The camera looks along -[sin dir, cos dir], its right is [-cos dir, sin dir]: the barrel to the left.
                        _scene set ["dir", (-(_barrel select 1)) atan2 (_barrel select 0)];
                    };
                };

                [_scene] call _fnc_camera;

                // No still: once its camera goes the engine forgets what it filmed into and the card turns grey (seen in game,
                // 0.6.88) - the camera stays while the card is shown.
            },
            [_scene, _fnc_camera, _fnc_frame],
            5
        ] call CBA_fnc_waitUntilAndExecute;

        true
    };

    case "keep": {
        _arguments params [["_slots", [], [[]]]];

        {
            if !(_x in _slots) then {
                [_y] call _fnc_drop;
            };
        } forEach GVAR(cardScenes);

        {
            GVAR(cardScenes) deleteAt _x;
        } forEach ((keys GVAR(cardScenes)) select {!(_x in _slots)});
    };

    case "stop": {
        {
            [_y] call _fnc_drop;
        } forEach GVAR(cardScenes);

        GVAR(cardScenes) = createHashMap;
    };
};
