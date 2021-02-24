/*
    Author: [Håkon]
    [Description]
        Adds garage access to a object

    Arguments:
    0. <Object> Object to access the garage from

    Return Value:
    <Bool> Action added

    Scope: Clients
    Environment: Any
    Public: [Yes]
    Dependencies:

    Example: [_object] call HR_GRG_fnc_initGarage;

    License: MIT License
*/
params [ ["_object", objNull, [objNull]] ];
if (isNull _object) exitWith {false};
private _oldID = _object getVariable ["HR_GRG_GarageID", -1];
_object removeAction _oldID;

private _id = _object addAction [
    localize "STR_HR_GRG_openGarage_Action"
    , "
        ['HR_GRG','Loading Garage, please wait...'] call BIS_fnc_startLoadingScreen;
        createDialog 'VehicleSelect';
        sleep 1.5;
        'HR_GRG' call BIS_fnc_endLoadingScreen;
    ", nil, 1.5, true, true, ""
    , "(isNil {HR_GRG_Placing}) || {!HR_GRG_Placing}", 6
];
_object setVariable ["HR_GRG_GarageID", _id, true];
true;