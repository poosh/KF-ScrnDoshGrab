class DoshPickup extends CashPickup;

var() bool  bZedPickup; // are zeds allowed to pickup cash?
var() float ZedHealthMult; // dosh makes zeds stronger :)
var() float MaxHealthMult;

function GiveCashTo( Pawn Other )
{
	// You all love the mental-mad typecasting XD
	if( !bDroppedCash )
	{
		CashAmount = (rand(0.5 * default.CashAmount) + default.CashAmount) * (KFGameReplicationInfo(Level.GRI).GameDiff  * 0.5) ;
	}
	else if ( Other.PlayerReplicationInfo != none && DroppedBy != none && DroppedBy.PlayerReplicationInfo != none &&
			  ((DroppedBy.PlayerReplicationInfo.Score + float(CashAmount)) / Other.PlayerReplicationInfo.Score) >= 0.50 &&
			  PlayerController(DroppedBy) != none && KFSteamStatsAndAchievements(PlayerController(DroppedBy).SteamStatsAndAchievements) != none )
	{
		if ( Other.PlayerReplicationInfo != DroppedBy.PlayerReplicationInfo )
		{
			KFSteamStatsAndAchievements(PlayerController(DroppedBy).SteamStatsAndAchievements).AddDonatedCash(CashAmount);
		}
	}
    
    
	if( Other.Controller!=None && Other.Controller.PlayerReplicationInfo!=none )
		Other.Controller.PlayerReplicationInfo.Score += CashAmount;
    else if ( KFMonster(Other) != none ) 
        GiveCashToZed(KFMonster(Other));

    AnnouncePickup(Other);
	SetRespawn();
}

function GiveCashToZed( KFMonster M )
{
    if ( M == none )
        return;
    
    if ( ZedHealthMult > 0 && M.ScoringValue > 0 ) {
        M.Health = min(M.Health + M.Health * ZedHealthMult * float(CashAmount) / M.ScoringValue, M.HealthMax * MaxHealthMult);
        M.HeadHealth *= 1.0 + ZedHealthMult * float(CashAmount) / M.ScoringValue;
    }
    
    M.ScoringValue += CashAmount;
}

auto state Pickup
{
    function bool ValidTouch(Actor Other)
	{
        local bool result;
        local KFMonster M;
        
        if ( !bZedPickup )
            return super.ValidTouch(Other);
            
        M = KFMonster(Other);
        if ( M == none )
            return super.ValidTouch(Other);
            
        if ( M.Health <= 0 ) 
            return false; // no money for dead meat
        
        // hack to allow zed picking up dosh
        M.bCanPickupInventory = true;
        result = super.ValidTouch(Other);
        M.bCanPickupInventory = false;
        return result;
    }
}

state FallingPickup
{
	function BeginState()
	{
	    SetTimer(15, false);
	}    
}

defaultproperties
{
    ZedHealthMult=1.0
    MaxHealthMult=5.0
}
