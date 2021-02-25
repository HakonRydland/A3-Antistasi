params ["_vehicle", "_fuelStats"];
if !(local _vehicle) exitWith {};
_fuelStats params [["_fuel",0, [0]],["_fuelCargo",-1,[0]], "_aceFuel"];
_vehicle setFuel ([_fuel, 1] select HR_GRG_hasFuelSource);
_vehicle setFuelCargo _fuelCargo;
if (_aceFuel > -2) then { // my nill indicator
    _vehicle setVariable ["ace_refuel_currentFuelCargo", _aceFuel, true];
};
