/*  This loop updates the aggression every minute

    Execution on: Server

    Scope: Internal

    Params:
        None

    Returns:
        Nothing
*/

while {true} do
{
    sleep 60;

    waitUntil {!prestigeIsChanging};
    prestigeIsChanging = true;

    //Calculate new values for each element
    aggressionStackOccupants = aggressionStackOccupants apply {[(_x select 0) + (_x select 1), (_x select 1)]};
    //Filter out all elements which have passed the 0 value
    aggressionStackOccupants = aggressionStackOccupants select {(_x select 0) * (_x select 1) < 0};

    //Calculate new values for each element
    aggressionStackInvaders = aggressionStackInvaders apply {[(_x select 0) + (_x select 1), (_x select 1)]};
    //Filter out all elements which have passed the 0 value
    aggressionStackInvaders = aggressionStackInvaders select {(_x select 0) * (_x select 1) < 0};

    prestigeIsChanging = false;
    [] call A3A_fnc_calculateAggression;

    //Update attack countdown for occupants and execute attack if needed
    attackCountdownOccupants = attackCountdownOccupants - (60 * (0.5 + (aggressionOccupants/100)));
	if (attackCountdownOccupants < 0) then
    {
        [3600, Occupants] call A3A_fnc_timingCA;
        if (!bigAttackInProgress) then
        {
            [Occupants] spawn A3A_fnc_rebelAttack;
        };
    }
    else
    {
        //timingCA broadcasts the value in the if case
        publicVariable "attackCountdownOccupants";
    };


    if ((tierWar > 1) || (gameMode == 4)) then
    {
        //Update attack countdown for invaders and execute attack if needed
        attackCountdownInvaders = attackCountdownInvaders - (60 * (0.5 + (attackCountdownInvaders/100)));
    	if (attackCountdownInvaders < 0) then
        {
            attackCountdownInvaders = 0;
            [3600, Invaders] call A3A_fnc_timingCA;
            if (!bigAttackInProgress) then
            {
                [Invaders] spawn A3A_fnc_rebelAttack;
            };
        }
        else
        {
            //timingCA broadcasts the value in the if case
            publicVariable "attackCountdownOccupants";
        };
    };
};