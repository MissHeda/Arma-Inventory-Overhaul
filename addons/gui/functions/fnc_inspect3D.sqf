#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda, after KPblM Item Preview by Dimon UA (KPBLM, Workshop 3822903400) - its showcase scene, included with the
 * author's permission
 * The inspect card's 3D view (fnc_drawInspect): the item in a small scene of its own far off the map (INSPECT_3D_PLACE) - a
 * dark sphere round it and three lights, key, fill and rim - filmed by a camera of its own into a texture (render to texture,
 * INSPECT_3D_TARGET) that the card shows in its picture box. The window's own view stays as it is. Held and dragged in the box
 * the camera goes round the item (fnc_onFrame), the wheel brings it nearer or farther, a double click puts it back.
 *
 * A weapon lies on a scripted weapon holder with the attachments it has (as fnc_getContents gives them, the holder's own
 * format), else with what its config fits on it; gear the holder shows the right way up - uniforms, vests, headgear - lies
 * on it too. What the holder will not take or shows upside down - backpacks, glasses, magazines, small items - stands as the
 * model alone, turned as KPBLM measured it. The camera aims at the weapon's base on the holder, gear a little higher. The
 * frame is the item's size, at most INSPECT_3D_FRAME. The lights shine by day too; the aperture is left to the engine - set,
 * it lit or darkened the whole world behind the window as well.
 *
 * The state is GVAR(scene3D): the class and attachments it shows, the camera, the lights, every object made, the target
 * [ASL], the turn (dir, pitch), the distance and its limits.
 *
 * Arguments:
 * 0: What to do <STRING>
 *    "start"   the scene for the item, unless it stands for it already - the one before goes (arguments: [class, attachments])
 *    "stop"    the scene goes: camera, lights, objects
 *    "turn"    the camera goes round by how far the mouse moved, a share of the screen (arguments: [across, down])
 *    "zoom"    nearer for a turn of the wheel up, farther for one down (arguments: [turn])
 *    "pan"     the camera and what it looks at move across and up or down, as the middle mouse button drags them - the item
 *              moves with the mouse, at most its frame away from where it was (arguments: [across, down])
 *    "reset"   the view the scene started with
 * 1: Arguments <ARRAY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * ["start", ["arifle_MX_F", []]] call aio_gui_fnc_inspect3D;
 *
 * Public: No
 */

params [["_mode", "", [""]], ["_arguments", [], [[]]]];

private _scene = GVAR(scene3D);

// The camera where the turn and the distance put it, looking at the item, and the lights round it with it.
private _fnc_camera = {
    private _camera = _scene getOrDefault ["camera", objNull];

    if (isNull _camera) exitWith {};

    private _target = _scene get "target";
    private _dir = _scene get "dir";
    private _pitch = _scene get "pitch";
    private _distance = _scene get "distance";
    private _across = (cos _pitch) * _distance;
    private _cameraPos = _target vectorAdd [(sin _dir) * _across, (cos _dir) * _across, (sin _pitch) * _distance];

    // The scene is in ASL, the camera takes AGL.
    _camera camSetPos (ASLToAGL _cameraPos);
    _camera camSetTarget (ASLToAGL _target);
    _camera camSetFov INSPECT_3D_FOV;
    _camera camCommit 0;

    (_scene get "lights") params ["_key", "_fill", "_rim"];

    private _side = [cos _dir, -(sin _dir), 0];

    // Key above and left of the camera, fill to the right a little lower, rim behind the item and above it.
    _key setPosASL ((_cameraPos vectorAdd (_side vectorMultiply (-0.5 * _distance))) vectorAdd [0, 0, 0.4 * _distance]);
    _fill setPosASL ((_cameraPos vectorAdd (_side vectorMultiply (0.7 * _distance))) vectorAdd [0, 0, -0.1 * _distance]);
    _rim setPosASL ((_target vectorAdd ((_target vectorDiff _cameraPos) vectorMultiply 0.8)) vectorAdd [0, 0, 0.5 * _distance]);
};

switch (_mode) do {
    case "start": {
        _arguments params [["_class", "", [""]], ["_attachments", [], [[]]]];

        if (_class isEqualTo "") exitWith {};

        if (
            (_scene getOrDefault ["class", ""]) isEqualTo _class && {(_scene getOrDefault ["attachments", []]) isEqualTo _attachments}
            && {!isNull (_scene getOrDefault ["camera", objNull])}
        ) exitWith {};

        ["stop"] call FUNC(inspect3D);

        _scene = createHashMapFromArray [["class", _class], ["attachments", +_attachments]];
        GVAR(scene3D) = _scene;

        private _objects = [];
        _scene set ["objects", _objects];

        // The sphere, about 125 m round: the holder has to stand inside it.
        private _sceneBase = INSPECT_3D_PLACE + [((getTerrainHeightASL INSPECT_3D_PLACE) max 0) + 300];
        private _sphere = "Sphere_3DEN" createVehicleLocal [0, 0, 0];
        _sphere setPosASL _sceneBase;

        {
            _sphere setObjectTexture [_x, "#(argb,8,8,3)color(0.05,0.055,0.065,1)"];
        } forEach [0, 1];

        _objects pushBack _sphere;

        private _holderPos = _sceneBase vectorAdd [0, 0, 100];
        private _holder = "GroundWeaponHolder_Scripted" createVehicleLocal [0, 0, 0];
        _holder setPosASL _holderPos;
        _holder setVectorDirAndUp [[0, 0, 1], [0, 1, 0]];
        _objects pushBack _holder;

        private _weapons = configFile >> "CfgWeapons";
        private _itemConfig = _weapons >> _class;
        private _isWeapon = (["Rifle", "Pistol", "Launcher"] findIf {_class isKindOf [_x, _weapons]}) >= 0
            || {getNumber (_itemConfig >> "type") == 2};

        // What the holder takes at all: weapons and what is worn from CfgWeapons; binoculars and night vision it turns down,
        // as it does backpacks, glasses and magazines.
        private _holderTakes = _isWeapon || {isClass _itemConfig && {!(_class isKindOf ["Binocular", _weapons])}};

        // A weapon with what it carries, else as its config fits it out - a magazine full: some belt-fed weapons show
        // their box by the rounds.
        _attachments params ["", ["_muzzle", ""], ["_pointer", ""], ["_optic", ""], ["_magazine", []], ["_magazine2", []], ["_bipod", ""]];

        if (_attachments isEqualTo []) then {
            private _linked = _itemConfig >> "LinkedItems";

            _muzzle = getText (_linked >> "LinkedItemsMuzzle" >> "item");
            _pointer = getText (_linked >> "LinkedItemsAcc" >> "item");
            _optic = getText (_linked >> "LinkedItemsOptic" >> "item");
            _bipod = getText (_linked >> "LinkedItemsUnder" >> "item");

            private _magazines = getArray (_itemConfig >> "magazines");

            if (_magazines isNotEqualTo []) then {
                private _first = _magazines select 0;
                _magazine = [_first, (getNumber (configFile >> "CfgMagazines" >> _first >> "count")) max 1];
            };
        };

        if (count _magazine < 2 || {(_magazine param [0, ""]) isEqualTo ""}) then {_magazine = []};
        if (count _magazine2 < 2 || {(_magazine2 param [0, ""]) isEqualTo ""}) then {_magazine2 = []};

        // The model, where the class lives - a magazine's real one rather than the box it lies on the ground as (fnc_itemModel).
        private _model = [_class] call FUNC(itemModel);

        // The base of a weapon on the holder - the proxy every weapon of every mod is put on. Gear on the holder hangs above it,
        // by a fixed lift: its box is blown up to the whole body's (a vest's, KPBLM measured 0.25 m).
        private _fnc_base = {
            params ["_lift"];

            private _proxy = _holder selectionPosition ["proxy:\a3\characters_f\proxies\weapon.001", 0.5];

            // The holder's model is not loaded yet: nothing rather than its own position.
            if (_proxy isEqualTo [0, 0, 0]) exitWith {[]};

            (_holder modelToWorldWorld _proxy) vectorAdd [0, 0, _lift]
        };

        private _target = +_holderPos;
        private _frame = INSPECT_3D_FRAME;

        // A uniform as it is worn, not the bundle it lies on the ground as: the soldier class it dresses (ItemInfo uniformClass),
        // made from its class so its textures are the uniform's - and framed whole, as tall as it is.
        private _wornClass = if (getNumber (_itemConfig >> "ItemInfo" >> "type") == 801) then {
            getText (_itemConfig >> "ItemInfo" >> "uniformClass")
        } else {
            ""
        };

        private _worn = if (_wornClass isNotEqualTo "" && {isClass (configFile >> "CfgVehicles" >> _wornClass)}) then {
            createSimpleObject [_wornClass, _holderPos, true]
        } else {
            objNull
        };

        // Standing, a body is tall where the view is wide: framed by its height (a share the box shows up and down, as the field
        // of view gives it), not by the width a weapon is. A uniform that cannot be made so lies there as its model.
        if (!isNull _worn) then {
            _objects pushBack _worn;

            (0 boundingBoxReal _worn) params ["_boxMin", "_boxMax"];

            _target = _worn modelToWorldWorld ((_boxMin vectorAdd _boxMax) vectorMultiply 0.5);
            _frame = (((_boxMax select 2) - (_boxMin select 2)) max 1) * INSPECT_3D_TALL;
        } else {
            if (_model isNotEqualTo "") then {
                private _probe = createSimpleObject [_model, [0, 0, 0], true];

                if (isNull _probe) exitWith {};

                (0 boundingBoxReal _probe) params ["_boxMin", "_boxMax"];
                deleteVehicle _probe;

                private _middle = (_boxMin vectorAdd _boxMax) vectorMultiply 0.5;
                private _extent = _boxMax vectorDiff _boxMin;
                private _size = vectorMagnitude _extent;

                _frame = (_size max 0.1) min INSPECT_3D_FRAME;

                // On the holder: weapons, and gear whose box is blown up past the frame - it stands right there. Small things from
                // CfgWeapons (a radio, a compass) the holder lays upside down: they stand as their model, as magazines do.
                private _onHolder = _holderTakes && {_isWeapon || {_size > INSPECT_3D_FRAME}};

                if (_onHolder) then {
                    _holder addWeaponWithAttachmentsCargo [[_class, _muzzle, _pointer, _optic, _magazine, _magazine2, _bipod], 1];

                    private _base = [[0.25, 0] select _isWeapon] call _fnc_base;

                    if (_base isNotEqualTo []) then {
                        _target = _base;
                    };
                } else {
                    private _base = [0] call _fnc_base;
                    private _placed = [_base, _holderPos] select (_base isEqualTo []);
                    private _prop = createSimpleObject [_model, _placed, true];

                    // A magazine is modelled as it sits in its weapon: stood up, its mouth up, by the axis it is longest along. A small
                    // thing from CfgWeapons laid out as worn hangs below its base, its top on local -z: turned half round its thin axis.
                    private _turn = [];

                    if (isClass (configFile >> "CfgMagazines" >> _class)) then {
                        _turn = [[[0, 1, 0], [0, 0, 1]], [[0, 0, -1], [0, -1, 0]]] select (abs (_extent select 1) >= abs (_extent select 2));
                    } else {
                        if (abs (_extent select 2) > abs (_extent select 1) && {(_middle select 2) < 0}) then {
                            _turn = [[0, 1, 0], [0, 0, -1]];
                        };
                    };

                    if (_turn isNotEqualTo []) then {
                        _prop setVectorDirAndUp _turn;
                    };

                    _objects pushBack _prop;

                    // Aimed at the middle of the model as it stands now - moving a turned simple object would undo its turn.
                    private _seen = _prop modelToWorldWorld _middle;

                    if (count _seen == 3 && {vectorMagnitude (_seen vectorDiff _placed) < 3}) then {
                        _target = _seen;
                    };
                };
            };
        };

        _scene set ["target", _target];
        _scene set ["origin", +_target];
        _scene set ["frame", _frame];

        // The lights, placed with the camera.
        private _lights = [[30, [1, 0.97, 0.92], [1, 0.97, 0.92]], [12, [0.6, 0.7, 0.9], [0.7, 0.8, 1]], [20, [1, 1, 1], [1, 0.9, 0.8]]] apply {
            _x params ["_brightness", "_ambient", "_colour"];

            private _light = "#lightpoint" createVehicleLocal [0, 0, 0];
            _light setPosASL _target;
            _light setLightBrightness _brightness;
            _light setLightIntensity (_brightness * 10);
            _light setLightAmbient _ambient;
            _light setLightColor _colour;
            _light setLightUseFlare false;
            _light setLightDayLight true;
            _light setLightAttenuation [0, 1, 0, 0, 20, 40];
            _objects pushBack _light;

            _light
        };

        _scene set ["lights", _lights];

        // A little above the item, from the front left; near enough for its size.
        private _distance = ((_frame * INSPECT_3D_DISTANCE) max 0.25) min 6;

        _scene set ["dir", 45];
        _scene set ["pitch", 15];
        _scene set ["distance", _distance];
        _scene set ["start", _distance];
        _scene set ["near", _distance * 0.3];
        _scene set ["far", _distance * 3];

        private _camera = "camera" camCreate (ASLToAGL _target);
        _camera cameraEffect ["Internal", "Back", INSPECT_3D_TARGET];
        _camera camSetFocus [-1, -1];
        _scene set ["camera", _camera];

        call _fnc_camera;
    };
    case "stop": {
        if (count _scene == 0) exitWith {};

        private _camera = _scene getOrDefault ["camera", objNull];

        // Destroying a camera does not end what it films into.
        if (!isNull _camera) then {
            _camera cameraEffect ["Terminate", "Back", INSPECT_3D_TARGET];
            camDestroy _camera;
        };

        {
            if (!isNull _x) then {
                deleteVehicle _x;
            };
        } forEach (_scene getOrDefault ["objects", []]);

        GVAR(scene3D) = createHashMap;
        GVAR(inspect3DTurn) = [];
        GVAR(inspect3DPan) = [];
    };
    case "turn": {
        if (count _scene == 0) exitWith {};

        _arguments params [["_across", 0, [0]], ["_down", 0, [0]]];

        // The item follows the mouse: dragged to the right, its front turns to the right.
        _scene set ["dir", (_scene get "dir") + _across * INSPECT_3D_TURN_ACROSS];
        _scene set ["pitch", (((_scene get "pitch") + _down * INSPECT_3D_TURN_DOWN) max -80) min 80];

        call _fnc_camera;
    };
    case "zoom": {
        if (count _scene == 0) exitWith {};

        _arguments params [["_turn", 0, [0]]];

        if (_turn == 0) exitWith {};

        // By how far the wheel turned: several notches in one frame come as one turn of that many.
        private _distance = (_scene get "distance") / (1.15 ^ ((_turn max -6) min 6));

        _scene set ["distance", ((_distance max (_scene get "near")) min (_scene get "far"))];

        call _fnc_camera;
    };
    case "pan": {
        if (count _scene == 0) exitWith {};

        _arguments params [["_across", 0, [0]], ["_down", 0, [0]]];

        private _dir = _scene get "dir";
        private _distance = _scene get "distance";
        private _side = [cos _dir, -(sin _dir), 0];
        private _origin = _scene get "origin";

        // Dragged right, the item goes right: the camera and its target go left. Dragged down, they go up.
        private _target = ((_scene get "target") vectorAdd (_side vectorMultiply (-_across * _distance * INSPECT_3D_PAN)))
            vectorAdd [0, 0, _down * _distance * INSPECT_3D_PAN];
        private _offset = _target vectorDiff _origin;
        private _limit = _scene getOrDefault ["frame", INSPECT_3D_FRAME];

        if (vectorMagnitude _offset > _limit) then {
            _target = _origin vectorAdd ((vectorNormalized _offset) vectorMultiply _limit);
        };

        _scene set ["target", _target];

        call _fnc_camera;
    };
    case "reset": {
        if (count _scene == 0) exitWith {};

        _scene set ["target", +(_scene get "origin")];
        _scene set ["dir", 45];
        _scene set ["pitch", 15];
        _scene set ["distance", _scene get "start"];

        call _fnc_camera;
    };
};
