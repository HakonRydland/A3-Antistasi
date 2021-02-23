/*
    Author: [Håkon]
    [Description]
        Handles placement attempt of a vehicle

    Arguments:
    0. <String> className of vehicle
    1. <Array>  Arrays of [className of Mount, Index of mount in garage]
    2. <Struct/nil> Vehicle state (optional)
    3. <Bool>   use garage vehicle pool for placement (optional: default true)

    Return Value:
    <nil>

    Scope: Clients
    Environment: Any
    Public: [Yes]
    Dependencies:

    Example: [_class, [], _state, false] call HR_GRG_fnc_confirmPlacement;

    License: MIT License
*/
#include "\a3\ui_f\hpp\definedikcodes.inc"
params [ ["_class", "", [""]], ["_mounts", [], [[]]], ["_pylons", [], [[]]], "_state", ["_useGRGPool", true, [true]] ];
if (!isClass (configFile >> "CfgVehicles" >> _class)) exitWith {HR_GRG_Placing = false};
if (isNil "HR_GRG_CurTexture") then {HR_GRG_CurTexture = []};
if (isNil "HR_GRG_CurAnims") then {HR_GRG_CurAnims = []};
HR_GRG_Placing = true;

//define global variables
HR_GRG_pos = screenToWorld [0.5,0.5];
HR_GRG_dir = 0;
RB_KeyPause = time;
HR_GRG_KeyQ = false;
HR_GRG_KeyE = false;
HR_GRG_validPlacement = 0;
HR_GRG_Mounts_ = _mounts; //HR_GRG_Mounts is used in garage internaly
HR_GRG_Pylons_ = if (!isNil "_pylons") then {_pylons} else {[]}; //same for HR_GRG_Pylons
HR_GRG_usePool = _useGRGPool;

//define private use function
HR_GRG_cleanUp = {
    //remove EH's
    removeMissionEventHandler ["EachFrame", HR_GRG_EH_EF];
    findDisplay 46 displayRemoveEventHandler ["KeyDown", HR_GRG_EH_KeyDown];
    terminate HR_GRG_keyHint;

    //remove display vehicle
    { detach _x; deleteVehicle _x } forEach (attachedObjects HR_GRG_dispVehicle);
    deleteVehicle HR_GRG_dispVehicle;

    //clean variables
    HR_GRG_dispVehicle = nil;
    HR_GRG_pos = nil;
    HR_GRG_dir = nil;
    HR_GRG_bb = nil;
    RB_KeyPause = nil;
    HR_GRG_KeyQ = nil;
    HR_GRG_KeyE = nil;
    HR_GRG_EH_EF = nil;
    HR_GRG_EH_KeyDown = nil;
    HR_GRG_keyHint = nil;
};

HR_GRG_fnc_execForGarageUsers = {
    params ["_client", "_player", "_fnc"];
    private _UID = getPlayerUID _player;
    private _recipients = +HR_GRG_Users;
    _recipients pushBackUnique 2;
    _recipients pushBackUnique _client;
    [_UID, _player] remoteExecCall [_fnc,_recipients];
};

//create display vehicle localy
HR_GRG_dispVehicle = _class createVehicleLocal HR_GRG_pos;
if (!isNil "_state") then {
    [HR_GRG_dispVehicle, _state] call HR_GRG_fnc_setState;
};
HR_GRG_dispVehicle enableSimulation false;
HR_GRG_dispVehicle allowDamage false;
HR_GRG_dispVehicle lock true;
HR_GRG_dispVehicle lockInventory true;
HR_GRG_dispVehicle setDir HR_GRG_dir;
[HR_GRG_dispVehicle, HR_GRG_CurTexture, HR_GRG_CurAnims] call BIS_fnc_initVehicle;
HR_GRG_dispMounts = [];
{
    private _static = (_x#0) createVehicleLocal HR_GRG_pos;
    _static enableSimulation false;
    _static allowDamage false;

    private _nodes = [HR_GRG_dispVehicle, _static] call A3A_fnc_logistics_canLoad;
    (_nodes + [true]) call A3A_fnc_logistics_load; //we know we can load it, just need the nodes from can load
    hintSilent ""; //clear load hint

    private _offsetAndDir = [_static] call A3A_fnc_logistics_getCargoOffsetAndDir;
    private _node = _nodes#2;
    private _nodeOffset = if ((_node#0) isEqualType []) then {
        private _lastNode = (count _node) -1;
        private _offsetOne = (_node#0#1);
        private _offsetTwo = (_node#_lastNode#1);
        private _diff = _offsetOne vectorDiff _offsetTwo;
        _offsetTwo vectorAdd [0,(_diff#1)/2,0];
    } else { _node#1 };

    HR_GRG_dispMounts pushBack [_static, _nodeOffset vectorAdd (_offsetAndDir#0), _offsetAndDir#1, _x ];
} forEach HR_GRG_Mounts_;

{
    _x params ["_pylonIndex", "_mag", "_forced", "_turret"];
    HR_GRG_dispVehicle setPylonLoadout [_pylonIndex, _mag, _forced, _turret];
} forEach HR_GRG_Pylons_;

//calculate raycast positions
private _bb = (0 boundingBoxReal HR_GRG_dispVehicle);
private _back = (_bb#0#1);
private _front = (_bb#1#1);
private _top = (_bb#1#2);
private _left = (_bb#0#0);
private _right = (_bb#1#0);
private _bottom = (_bb#0#2) + 0.2;//rais slightly from the ground
private _knee = _bottom + 0.5;
HR_GRG_rays = [
    //outer box
    [[_left,_back,_bottom], [_right,_back,_top]]            //back cross
    ,[[_left,_back,_top], [_right,_back,_bottom]]

    ,[[_left,_front,_bottom], [_right,_front,_top]]         //front cross
    ,[[_left,_front,_top], [_right,_front,_bottom]]

    ,[[_left,_back,_bottom], [_left,_front,_top]]           //left cross
    ,[[_left,_back,_top], [_left,_front,_bottom]]

    ,[[_right,_back,_bottom], [_right,_front,_top]]         //right cross
    ,[[_right,_back,_top], [_right,_front,_bottom]]

    ,[[_left,_back,_top], [_right,_front,_top]]             //top cross
    ,[[_right,_back,_top], [_left,_front,_top]]

    ,[[_left,_back,_bottom], [_right,_front,_bottom]]       //bottom cross
    ,[[_right,_back,_bottom], [_left,_front,_bottom]]

    ,[[_left,_back,_bottom], [_left,_back,_top]]            //back left vertical
    ,[[_left,_front,_bottom], [_left,_front,_top]]          //front left vertical
    ,[[_right,_back,_bottom], [_right,_back,_top]]          //back right vertical
    ,[[_right,_front,_bottom], [_right,_front,_top]]        //front right vertical

    ,[[_left,_back,_bottom], [_left,_front,_bottom]]        //left bottom horisontal
    ,[[_left,_back,_top], [_left,_front,_top]]              //left top horisontal

    ,[[_right,_back,_bottom], [_right,_front,_bottom]]      //right bottom horisontal
    ,[[_right,_back,_top], [_right,_front,_top]]            //right top horisontal

    ,[[_left,_front,_bottom], [_right,_front,_bottom]]      //front bottom horisontal
    ,[[_left,_front,_top], [_right,_front,_top]]            //front top horisontal

    ,[[_left,_back,_bottom], [_right,_back,_bottom]]        //back bottom horisontal
    ,[[_left,_back,_top], [_right,_back,_top]]              //back top horisontal

    //inner lines
    ,[[_left,_back,_bottom], [_right,_front,_top]]          //diag 1
    ,[[_left,_back,_top], [_right,_front,_bottom]]

    ,[[_right,_back,_bottom], [_left,_front,_top]]          //diag 2
    ,[[_right,_back,_top], [_left,_front,_bottom]]

    ,[[_left,_back,0], [_right,_front,0]]                   //diag 3
    ,[[_right,_back,0], [_left,_front,0]]

    ,[[_left,0,0], [_right,0,0]]                            //center
    ,[[0,_back,0], [0,_front,0]]
    ,[[0,0,_bottom], [0,0,_top]]

    ,[[_left,_back,_knee], [_right,_front,_knee]]           //knee check
    ,[[_right,_back,_knee], [_left,_front,_knee]]
    ,[[0,_back,_knee], [0,_front,_knee]]
    ,[[_left,0,_knee], [_right,0,_knee]]
    ,[[_left,_back,_knee], [_left,_front,_knee]]
    ,[[_left,_front,_knee], [_right,_front,_knee]]
    ,[[_right,_front,_knee], [_right,_back,_knee]]
    ,[[_right,_back,_knee], [_left,_back,_knee]]
];

//player in vehicle detection
private _diff = ((_bb#1) vectorDiff (_bb#0)) apply {_x/2};
private _adjustment = (_bb#1) vectorDiff _diff;
HR_GRG_dispSquare = [_adjustment, _diff apply {_x + 0.6}, (_bb#2)]; //square offset from center, square radius [x,y], bb diameter

//add EH's (data is set on the display vehicle)
HR_GRG_EH_KeyDown = findDisplay 46 displayAddEventHandler ["KeyDown", {
    params ["", "_key"];
    private _return = false;

    //rotate vehicle
    if (_key isEqualTo DIK_Q && RB_KeyPause < time) then {
        _return = true;
        RB_KeyPause = time + 0.01;
        HR_GRG_KeyQ = true;
    };

    if (_key isEqualTo DIK_E && RB_KeyPause < time) then {
        _return = true;
        RB_KeyPause = time + 0.01;
        HR_GRG_KeyE = true;
    };

    if (HR_GRG_validPlacement > 0) exitWith { // 0 is valid placement, 1 too far away, 2 colision
        if (_key in [DIK_ESCAPE, DIK_RETURN]) then {
            _return = true;
            call HR_GRG_cleanUp;
            [[clientOwner, player, "HR_GRG_fnc_releaseAllVehicles"], HR_GRG_fnc_execForGarageUsers] remoteExecCall ["call", 2];
            HR_GRG_Placing = false;
        };
        _return
    };

    //complete or cancel placement
    if (_key in [DIK_ESCAPE, DIK_RETURN, DIK_SPACE]) then {
        _return = true;

        //get type from display vehicle, and private copies of pos and dir
        private _class = typeOf HR_GRG_dispVehicle;
        private _state = [HR_GRG_dispVehicle] call HR_GRG_fnc_getState;
        private _pos = HR_GRG_pos;
        private _dir = HR_GRG_dir;
        call HR_GRG_cleanUp;

        //place vehicle if confirming placement
        private _placed = if (_key isEqualTo DIK_SPACE) then {
            //create vehicle
            private _veh = _class createVehicle [0,0,10000];
            [_veh, _state] call HR_GRG_fnc_setState;
            _veh enableSimulation false;
            _veh allowDamage false;
            [_veh, HR_GRG_CurTexture, HR_GRG_CurAnims] call BIS_fnc_initVehicle;
            _veh setDir _dir;
            _veh setPos _pos;
            _veh setVectorUp surfaceNormal position _veh;

            //create and load cargo
            {
                private _static = (_x#0) createVehicle _pos;
                _static allowDamage false;
                private _nodes = [_veh, _static] call A3A_fnc_logistics_canLoad;
                (_nodes + [true]) call A3A_fnc_logistics_load;
                [_static] call HR_GRG_fnc_finalInit;
            } forEach HR_GRG_Mounts_;

            //set pylons loudout
            if !(HR_GRG_Pylons_ isEqualTo []) then {
                {
                    _veh removeWeaponTurret [_x, [-1]];
                    _veh removeWeaponTurret [_x, [0]];
                } forEach HR_GRG_DefaultMags;
                {
                    _x params ["_pylonIndex", "_mag", "_forced", "_turret"];
                    _veh setPylonLoadout [_pylonIndex, _mag, _forced, _turret]
                } forEach HR_GRG_Pylons_;
            };
            _veh spawn {sleep 0.5;_this allowDamage true;_this enableSimulation true; { _x allowDamage true; } forEach (attachedObjects _this); };
            [_veh] call HR_GRG_fnc_finalInit;

            true;
        } else { false };
        //handle garage pool changes
        if (HR_GRG_usePool) then {
            private _fnc = if (_placed) then {"HR_GRG_fnc_removeFromPool"} else {"HR_GRG_fnc_releaseAllVehicles"};
            [[clientOwner, player, _fnc], HR_GRG_fnc_execForGarageUsers] remoteExecCall ["call", 2]; //run code on server as HR_GRG_Users is maintained ONLY on the server
        };
        HR_GRG_Placing = false;
    };

    //block key press if valid key
    _return
}];

HR_GRG_EH_EF = addMissionEventHandler ["EachFrame", {
    private _updateState = false;
    private _hide = {
        {
            _x hideObject _this;
        } forEach (attachedObjects HR_GRG_dispVehicle);
        HR_GRG_dispVehicle hideObject _this;
    };

    //update Pos
    if ( (HR_GRG_pos distance screenToWorld [0.5,0.5]) > 0.1 ) then {
        HR_GRG_pos = screenToWorld [0.5,0.5];
        _updateState = true;

        //if invalid position, block placement
        if (HR_GRG_pos distance player > 50) exitWith { true call _hide; HR_GRG_validPlacement = 1 }; //distance

        private _exit = false;
        {
            _x params ["_start", "_end"];
            if (lineIntersects [
                HR_GRG_dispVehicle modelToWorldVisualWorld _start
                , HR_GRG_dispVehicle modelToWorldVisualWorld _end
                , HR_GRG_dispVehicle
            ]) exitWith { _exit = true; HR_GRG_validPlacement = 2 }; //collision
        } forEach HR_GRG_rays;
        if (_exit) exitWith { true call _hide };

        //player in vehicle
        HR_GRG_dispSquare params ["_adjustment", "_square", "_diameter"];
        _square params ["_a","_b"];
        _nearObjects = HR_GRG_dispVehicle nearObjects ["CAManBase", _diameter];
        private _inArea = _nearObjects inAreaArray [HR_GRG_dispVehicle modelToWorldVisual _adjustment, _a, _b, HR_GRG_dir, true];
        if !(_inArea isEqualTo []) exitWith { true call _hide; HR_GRG_validPlacement = 2 };

        HR_GRG_validPlacement = 0;
        false call _hide;
    };

    //update dir if key pressed
    if (HR_GRG_KeyQ) then {
        HR_GRG_KeyQ = false;
        HR_GRG_dir = HR_GRG_dir - 1;
        _updateState = true;
    };

    if (HR_GRG_KeyE) then {
        HR_GRG_KeyE = false;
        HR_GRG_dir = HR_GRG_dir + 1;
        _updateState = true;
    };

    if (_updateState) then {
        HR_GRG_dispVehicle setPos HR_GRG_pos;
        HR_GRG_dispVehicle setDir HR_GRG_dir;
        private _vecUp = surfaceNormal position HR_GRG_dispVehicle;
        HR_GRG_dispVehicle setVectorUp _vecUp;
        {
            (_x#0) setVectorDirAndUp [_x#2, _vecUp];
            (_x#0) attachTo [HR_GRG_dispVehicle, _x#1];
        } forEach HR_GRG_dispMounts;
    };

    //render keybind hint
    private _text = switch HR_GRG_validPlacement do {
        case 0: {localize "STR_HR_GRG_Feedback_CP_Rotation"};
        case 1: {localize "STR_HR_GRG_Feedback_CP_TooFar"};
        case 2: {localize "STR_HR_GRG_Feedback_CP_Blocked"};
    };

    HR_GRG_keyHint = [
        _text
        ,0,0.98
        ,0.2
        ,0
        ,0
        ,17001
    ] spawn BIS_fnc_dynamicText;

    if (call HR_GRG_CP_closeCnd) exitWith {call HR_GRG_cleanUp};

    #ifdef Debug //Debug render
    HR_GRG_dispSquare params ["_adjustment", "_square"];
    _square params ["_a","_b"];
    drawLine3D [HR_GRG_dispVehicle modelToWorldVisual _adjustment,HR_GRG_dispVehicle modelToWorldVisual (_adjustment vectorAdd [_a,0,0]), [0.9,0,0,1]];
    drawLine3D [HR_GRG_dispVehicle modelToWorldVisual _adjustment,HR_GRG_dispVehicle modelToWorldVisual (_adjustment vectorAdd [0,_b,0]), [0.9,0,0,1]];
    drawLine3D [HR_GRG_dispVehicle modelToWorldVisual _adjustment,HR_GRG_dispVehicle modelToWorldVisual (_adjustment vectorAdd [0,0,_c]), [0.9,0,0,1]];
    drawLine3D [HR_GRG_dispVehicle modelToWorldVisual _adjustment,HR_GRG_dispVehicle modelToWorldVisual (_adjustment vectorAdd [-_a,0,0]), [0.9,0,0,1]];
    drawLine3D [HR_GRG_dispVehicle modelToWorldVisual _adjustment,HR_GRG_dispVehicle modelToWorldVisual (_adjustment vectorAdd [0,-_b,0]), [0.9,0,0,1]];
    drawLine3D [HR_GRG_dispVehicle modelToWorldVisual _adjustment,HR_GRG_dispVehicle modelToWorldVisual (_adjustment vectorAdd [0,0,-_c]), [0.9,0,0,1]];
    { drawLine3D [HR_GRG_dispVehicle modelToWorldVisual _x#0,HR_GRG_dispVehicle modelToWorldVisual _x#1, [0.9,0,0,1]] } forEach HR_GRG_rays;
    #endif
}];
