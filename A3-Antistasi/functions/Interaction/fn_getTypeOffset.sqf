/*
    Author: [Håkon]
    [Description]
        if an object requires a specific offset to feel more natural add them by classname and offset here

    Arguments:
    0. <Object> Object you want offset off

    Return Value:
    <Array> Model center relative offset

    Scope: Any
    Environment: unscheduled
    Public: [Yes]
    Dependencies:

    Example: private _offset = [_object] call A3A_fnc_getTypeOffset;
*/
params ["_object"];
if (isNil "_object") exitWith {[0,0,0]};

private _type = if (_object isEqualType objNull) then {typeOf _object} else {_object};

switch (true) do {
    case ((_object isKindOf "CAManBase") && hasAce): { _object selectionPosition "spine3" }; //upper torso
    case ((_object isKindOf "LandVehicle") && hasAce): { _object selectionPosition "commander_turret"}; //ace being stupid, actions dosnt show otherwise (dont know why, out of reach?)
    case (_object isKindOf "FlagCarrierCore"): { [-0.12,-0.38,-2.5] }; //Flag
    case (_type isEqualTo "Land_TentSolar_01_olive_F"): { [0,0,0.5] }; //tent
    case (_type isEqualTo "MapBoard_seismic_F"): { [0,-0.2,0.5] }; //map
    default { [0,0,0] };
};
