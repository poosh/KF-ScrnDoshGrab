class DoshRules extends GameRules;

var DoshGrabMut Mut;

function PostBeginPlay()
{
    if( Level.Game.GameRulesModifiers==None )
        Level.Game.GameRulesModifiers = Self;
    else 
        Level.Game.GameRulesModifiers.AddGameRules(Self);
}    
    
function AddGameRules(GameRules GR)
{
    if ( GR!=Self ) //prevent adding same rules more than once
        Super.AddGameRules(GR);
}

function bool CheckEndGame(PlayerReplicationInfo Winner, string Reason)
{
	if ( NextGameRules != None && !NextGameRules.CheckEndGame(Winner,Reason) )
		return false;
    
    Mut.RestoreScoringValues();    
    
    return true;    
}        

function ScoreKill(Controller Killer, Controller Killed)
{
	if ( NextGameRules != None )
		NextGameRules.ScoreKill(Killer,Killed);
        
    if ( KFMonsterController(Killed) != none ) {
        KFMonsterController(Killed).KillAssistants.Length = 0; // do not give any cash to players directly
    }
}


function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation)
{
    if ( (NextGameRules != None) && NextGameRules.PreventDeath(Killed,Killer, damageType,HitLocation) )
        return true;
        
    if ( KFMonster(Killed) != none ) {
        TossCash(KFMonster(Killed));
    }
 
    return false;
}    

// monster tosses his scoring value 
function TossCash(KFMonster M, optional int Amount)  
{
    local Vector X,Y,Z;
    local DoshPickup DoshPickup;
    local Vector TossVel, SpawnLocation;
    
    if ( M == none )
        return;
        
    if ( Amount <= 0 || Amount > M.ScoringValue )
        Amount = M.ScoringValue;
    
    if ( Amount <= 0 )
        return;
        
    M.GetAxes(M.Rotation,X,Y,Z);    
        
    TossVel = Vector(M.GetViewRotation());
    switch ( Mut.DropKind ) {
        case Mut.DK_SPAWN:
            SpawnLocation =  M.Location;
            //SpawnLocation.Z += M.CollisionHeight * 0.5 - 2.5;
            //TossVel = M.PhysicsVolume.Gravity;
            TossVel = vect(0,0,500);
            break;
        case Mut.DK_FART:
            TossVel = TossVel * ((M.Velocity Dot TossVel) + 500) * Vect(-0.2,-0.2,0); 
            TossVel.Z = M.PhysicsVolume.Gravity.Z;
            SpawnLocation =  M.Location - 0.8 * M.CollisionRadius * X - 0.5 * M.CollisionRadius * Y;
            break;
        default:
            TossVel = TossVel * (0.25 + frand()) * ((M.Velocity Dot TossVel) + 500) + Vect(0,0,200); 
            SpawnLocation =  M.Location + 0.8 * M.CollisionRadius * X - 0.5 * M.CollisionRadius * Y;
            break;
    }
    
    DoshPickup = Spawn(class'DoshPickup',,, SpawnLocation);
    // try default spawn location, if unable to spawn in desired location
    if ( DoshPickup == none ) 
        DoshPickup = Spawn(class'DoshPickup',,, M.Location + 0.8 * M.CollisionRadius * X - 0.5 * M.CollisionRadius * Y);
        
    if ( DoshPickup != none ) {
        DoshPickup.CashAmount = Amount;
        DoshPickup.RespawnTime = 0;
        DoshPickup.bDroppedCash = True;
        DoshPickup.Velocity = TossVel;
        DoshPickup.DroppedBy = M.Controller;
        DoshPickup.InitDroppedPickupFor(None);
        DoshPickup.bZedPickup = Mut.bZedsCanPickupDosh;
        DoshPickup.ZedHealthMult = Mut.ZedHealthMult;
        DoshPickup.MaxHealthMult = Mut.MaxHealthMult;
        M.ScoringValue -= Amount; // just in case
    }
}  