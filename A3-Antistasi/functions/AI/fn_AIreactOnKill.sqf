params ["_group", "_killer"];

/*  Handles the reaction of a group when one of their members dies. Handles individual responces and the calls for support

    Execution on: Server or HC

    Scope: Internal

    Params:
        _group: GROUP : The group of which a unit has been killed
        _killer: OBJECT : The unit which has killed the unit

    Returns:
        Nothing
*/

//Abort if no units are left in fighting condition
if(({([_x] call A3A_fnc_canFight)} count (units _group)) == 0) exitWith {};

//Check for supports and choose best suited to counter the attack
if(_group getVariable ["canCallSupportAt", -1] < dateToNumber date) then
{
    //If _killer is not set or the same side (collision for example), abort here
    if((isNil "_killer") || {(isNull _killer) || {side (group _killer) == side _group}}) exitWith {};

    //Investigate killer
    private _killerPos = getPos _killer;
    if(_killerPos distance2D (getPos (leader _group)) > 600) then
    {
    	//Group is under long range fire which cannot be compensated by them, call for help instantly
    	if(isNull (objectParent _killer) && {_killer isKindOf "Man"}) then
    	{
    		//The killer didnt used a vehicle, most likely a sniper or a missile launcher was used
    		private _enemiesNearKiller = allUnits select {(side (group _x)) == (side (group _killer)) && {_x distance2D _killer < 100}};
    		if(count _enemiesNearKiller > 2) then
    		{
    			//There are multiple enemies, use spread out or precise attacks against them
    			[_group, ["MORTAR", "GUNSHIP"], _killer] spawn A3A_fnc_callForSupport;
    		}
    		else
    		{
    			//Only a small attack, use something precise against them
    			[_group, ["AIRSTRIKE", "GUNSHIP"], _killer] spawn A3A_fnc_callForSupport;
    		};
    	}
    	else
    	{
            //Detect the vehicle of the player (dependant on the killing method, you need another method to grab the vehicle)
    		private _killerVehicle = objectParent _killer;
            if(isNull _killerVehicle) then
            {
                _killerVehicle = _killer;
            };

    		if(_killerVehicle isKindOf "LandVehicle") then
    		{
    			//The group is fighting something ground based
    			if(_killerVehicle isKindOf "Tank") then
    			{
    				//The group is fighting a tank, bring in some heavy guns
    				[_group, ["CAS", "GUNSHIP"], _killerVehicle] spawn A3A_fnc_callForSupport;
    			}
    			else
    			{
    				//The group is fighting an APC or MRAP
    				[_group, ["MORTAR", "GUNSHIP", "AIRSTRIKE"], _killerVehicle] spawn A3A_fnc_callForSupport;
    			};
    		}
    		else
    		{
                if(_killerVehicle isKindOf "StaticWeapon") then
                {
                    //They are fighting a static weapon
                    [_group, ["AIRSTRIKE", "MORTAR"], _killerVehicle] spawn A3A_fnc_callForSupport;
                }
                else
                {
                    if(_killerVehicle isKindOf "Helicopter") then
        			{
        				//They are fighting something flying
        				private _vehicleType = typeOf _killerVehicle;
        				if(_vehicleType in vehNATOAttackHelis || _vehicleType in vehCSATAttackHelis) then
        				{
        					//They are fighting an attack heli, bring in an AA plane
        					[_group, ["SAM", "AAPLANE"], _killerVehicle] spawn A3A_fnc_callForSupport;
        				}
        				else
        				{
        					//They are fighting a transport or patrol heli
        					[_group, ["SAM", "GUNSHIP"], _killerVehicle] spawn A3A_fnc_callForSupport;
        				};
        			}
        			else
        			{
        				//They are fighting an enemy plane, bring an AA plane
        				[_group, ["AAPLANE", "SAM"], _killerVehicle] spawn A3A_fnc_callForSupport;
        			};
                };
    		};
    	};
    }
    else
    {
    	//Groups is in combat range, check for the possible ways to defend otherwise call help
    	if(isNull (objectParent _killer) && {_killer isKindOf "Man"}) then
    	{
    		//The killer didnt used a vehicle, normal fighting
    		private _enemiesNearKiller = count (allUnits select {(side (group _x)) == (side (group _killer)) && {_x distance2D _killer < 100}});
            private _aliveGroupUnits = {[_x] call A3A_fnc_canFight} count (units _group);
    		if(_enemiesNearKiller > 2) then
    		{
    			//There are multiple enemies, use spread out or precise attacks against them
                if((_aliveGroupUnits <= 4) || {(random 2) < (_enemiesNearKiller/_aliveGroupUnits)}) then
                {
                    //Group is too small or outnumbered, call for help
                    [_group, ["QRF", "MORTAR", "AIRSTRIKE"], _killer] spawn A3A_fnc_callForSupport;
                };
    		}
    		else
    		{
                //Only a small attack, normal fighting
                if((random 1) < (_enemiesNearKiller/_aliveGroupUnits)) then
                {
                    //The group units are cowards, send help
        			[_group, ["QRF", "AIRSTRIKE", "MORTAR"], _killer] spawn A3A_fnc_callForSupport;
                };
    		};
    	}
    	else
    	{
            //Get the killing vehicle
    		private _killerVehicle = objectParent _killer;
            if(isNull _killerVehicle) then
            {
                _killerVehicle = _killer;
            };
            private _groupUnitsWithLauncher = {secondaryWeapon _x != ""} count (units _group);
    		if(_killerVehicle isKindOf "LandVehicle") then
    		{
    			//The group is fighting something ground based
    			if(_killerVehicle isKindOf "Tank") then
    			{
    				//The group is fighting a tank, bring in some heavy guns
                    if((_groupUnitsWithLauncher >= 2) && (random 1 < 0.2)) then
                    {
                        [_group, ["CAS", "GUNSHIP"], _killerVehicle] spawn A3A_fnc_callForSupport;
                    };
                    if((_groupUnitsWithLauncher == 1) && (random 1 < 0.5)) then
                    {
                        [_group, ["CAS", "GUNSHIP"], _killerVehicle] spawn A3A_fnc_callForSupport;
                    };
                    if(_groupUnitsWithLauncher == 0) then
                    {
                        [_group, ["CAS", "GUNSHIP"], _killerVehicle] spawn A3A_fnc_callForSupport;
                    };
    			}
    			else
    			{
                    //The group is fighting an APC or MRAP
                    if((_groupUnitsWithLauncher >= 1) && (random 1 < 0.25)) then
                    {
                        [_group, ["AIRSTRIKE", "MORTAR", "GUNSHIP"], _killerVehicle] spawn A3A_fnc_callForSupport;
                    };
                    if(_groupUnitsWithLauncher == 0) then
                    {
                        [_group, ["AIRSTRIKE", "MORTAR", "GUNSHIP"], _killerVehicle] spawn A3A_fnc_callForSupport;
                    };
    			};
    		}
    		else
    		{
                if(_killerVehicle isKindOf "StaticWeapon") then
                {
                    //When fighting against a static, there is no help from launchers
                    [_group, ["QRF", "AIRSTRIKE", "MORTAR"], _killerVehicle] spawn A3A_fnc_callForSupport;
                }
                else
                {
                    if(_killerVehicle isKindOf "Helicopter") then
        			{
        				//They are fighting something flying
        				private _vehicleType = typeOf _killerVehicle;
        				if(_vehicleType in vehNATOAttackHelis || _vehicleType in vehCSATAttackHelis) then
        				{
        					//They are fighting an attack heli, bring in a SAM or AA plane
                            if((_groupUnitsWithLauncher >= 1) && (random 1 < 0.25)) then
                            {
                                [_group, ["SAM", "AAPLANE"], _killerVehicle] spawn A3A_fnc_callForSupport;
                            };
                            if(_groupUnitsWithLauncher == 0) then
                            {
                                [_group, ["SAM", "AAPLANE"], _killerVehicle] spawn A3A_fnc_callForSupport;
                            };

        				}
        				else
        				{
        					//They are fighting a transport or patrol heli
                            if(_groupUnitsWithLauncher == 0) then
                            {
                                //Not that dangerous, only call help if no launcher is available
                                [_group, ["SAM", "GUNSHIP"], _killerVehicle] spawn A3A_fnc_callForSupport;
                            };
        				};
        			}
        			else
        			{
        				//They are fighting an enemy plane, bring an AA plane or SAM
                        if((_groupUnitsWithLauncher >= 2) && (random 1 < 0.2)) then
                        {
                            [_group, ["AAPLANE", "SAM"], _killerVehicle] spawn A3A_fnc_callForSupport;
                        };
                        if((_groupUnitsWithLauncher == 1) && (random 1 < 0.5)) then
                        {
                            [_group, ["AAPLANE", "SAM"], _killerVehicle] spawn A3A_fnc_callForSupport;
                        };
                        if(_groupUnitsWithLauncher == 0) then
                        {
                            [_group, ["AAPLANE", "SAM"], _killerVehicle] spawn A3A_fnc_callForSupport;
                        };
        			};
                };
    		};
    	};
    };
};


{
	if (fleeing _x) then
	{
		if ([_x] call A3A_fnc_canFight) then
		{
			private _enemy = _x findNearestEnemy _x;
			if (!isNull _enemy) then
			{
				if ((_x distance _enemy < 50) and (objectParent _x == _x)) then
				{
					[_x] spawn A3A_fnc_surrenderAction;
				}
				else
				{
					if (([primaryWeapon _x] call BIS_fnc_baseWeapon) in allMachineGuns) then
					{
						[_x,_enemy] call A3A_fnc_suppressingFire
					}
					else
					{
						[_x,_x,_enemy] spawn A3A_fnc_chargeWithSmoke
					};
				};
			};
		};
	}
	else
	{
		if ([_x] call A3A_fnc_canFight) then
		{
			private _enemy = _x findNearestEnemy _x;
			if (!isNull _enemy) then
			{
				if (([primaryWeapon _x] call BIS_fnc_baseWeapon) in allMachineGuns) then
				{
					[_x,_enemy] call A3A_fnc_suppressingFire;
				}
				else
				{
					if (sunOrMoon == 1 or haveNV) then
					{
						[_x,_x,_enemy] spawn A3A_fnc_chargeWithSmoke;
					}
					else
					{
						if (sunOrMoon < 1) then
						{
							if ((hasIFA and (typeOf _x in squadLeaders)) or (count (getArray (configfile >> "CfgWeapons" >> primaryWeapon _x >> "muzzles")) == 2)) then
							{
								[_x,_enemy] spawn A3A_fnc_useFlares;
							};
						};
					};
				};
			}
			else
			{
				if ((sunOrMoon <1) and !haveNV) then
				{
					if ((hasIFA and (typeOf _x in squadLeaders)) or (count (getArray (configfile >> "CfgWeapons" >> primaryWeapon _x >> "muzzles")) == 2)) then
					{
						[_x] call A3A_fnc_useFlares;
					};
				};
			};
			if (random 1 < 0.5) then
			{
				if (count units _group > 0) then
				{
					_x allowFleeing (1 - (_x skill "courage") + (({!([_x] call A3A_fnc_canFight)} count units _group)/(count units _group)))
				};
			};
		};
	};
	sleep 1 + (random 1);
} forEach units _group;
