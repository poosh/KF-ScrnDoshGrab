class DoshGrabMut extends Mutator
    Config(DoshGrab);

var const string VERSION;  
var const string CfgGroup;  

var KFGameType KF;    
var DoshRules DoshRules;

var globalconfig bool bDropTeamDosh;
var globalconfig bool bZedsCanPickupDosh;
var globalconfig float ZedHealthMult, MaxHealthMult;
var globalconfig float DoshMultBeg, DoshMultNorm, DoshMultHard, DoshMultSui, DoshMultHoe;
var float DoshDifficultyMult;

const DK_TOSS = 0;
const DK_SPAWN= 1;
const DK_FART = 2;
var globalconfig int DropKind;

struct SMonsterDosh {
    var class<KFMonster> MC;
    var int ScoringValue;
};
var array<SMonsterDosh> MonsterData;

static function FillPlayInfo(PlayInfo PlayInfo)
{
    Super.FillPlayInfo(PlayInfo);
    
    PlayInfo.AddSetting(default.CfgGroup, "DoshMultBeg", "0. Dosh Mult. Beginner",1,0, "Text", "6;0.00:4.00",,,True);
    PlayInfo.AddSetting(default.CfgGroup, "DoshMultNorm", "2. Dosh Mult. Normal",1,0, "Text", "6;0.00:4.00",,,True);
    PlayInfo.AddSetting(default.CfgGroup, "DoshMultHard", "4. Dosh Mult. Hard",1,0, "Text", "6;0.00:4.00",,,True);
    PlayInfo.AddSetting(default.CfgGroup, "DoshMultSui", "5. Dosh Mult. Suicidal",1,0, "Text", "6;0.00:4.00",,,True);
    PlayInfo.AddSetting(default.CfgGroup, "DoshMultHoe", "7. Dosh Mult. HoE",1,0, "Text", "6;0.00:4.00",,,True);

    PlayInfo.AddSetting(default.CfgGroup, "bDropTeamDosh", "Drop Team Dosh",1,0, "Check");
    PlayInfo.AddSetting(default.CfgGroup, "bZedsCanPickupDosh", "ZEDs can pickup Dosh",1,0, "Check");
    PlayInfo.AddSetting(default.CfgGroup, "ZedHealthMult", "ZED's Health Mult.",1,0, "Text", "6;0.00:4.00",,,True);
    PlayInfo.AddSetting(default.CfgGroup, "MaxHealthMult", "Max Health Mult.",1,0, "Text", "6;1.00:99.00",,,True);
    
	PlayInfo.AddSetting(default.CfgGroup, "DropKind", "Drop Kind", 0, 1, "Select", "0;Toss;1;Spawn;2;Fart");
}

static function string GetDescriptionText(string PropName)
{
    switch (PropName)
    {
        case "DoshMultBeg":             return "Dropped money multiplier on Beginner difficulty.";
        case "DoshMultNorm":            return "Dropped money multiplier on Normal difficulty.";
        case "DoshMultHard":            return "Dropped money multiplier on Hard difficulty.";
        case "DoshMultSui":             return "Dropped money multiplier on Suicidal difficulty.";
        case "DoshMultHoe":             return "Dropped money multiplier on Hell on Earth difficulty.";

        case "bDropTeamDosh":           return "ZEDs dropping team's money too (that players receive at the end of the wave).";
        case "bZedsCanPickupDosh":      return "ZED picks up dosh. Dosh makes ZED stronger";
        case "ZedHealthMult":           return "Amount of health (%) that ZED receives for picking up a dosh (hp-per-pound)";
        case "MaxHealthMult":           return "Maximum health that zed can gain from grabbing dosh (in per cents of its max health)";
        case "DropKind":                return "How to drop dosh: TOSS - toss in front of zed like players do. SPAWN - spawn on the top of the zed. FART - spawn behind zed";
    }
    return Super.GetDescriptionText(PropName);
}

function PostBeginPlay()
{
    KF = KFGameType(Level.Game);
    if (KF == none) {
        Log("ERROR: Wrong GameType (requires KFGameType)", Class.Outer.Name);
        Destroy();
        return;
    }
    
    DoshRules = Spawn(Class'DoshRules', self);
    if ( DoshRules == none ) {
        log("Unable to spawn Game Rules!", class.outer.name);
        Destroy();
        return;
    }
    
    DoshRules.Mut = self; 
    
    SetupMultipliers();
}   

function Destroyed()
{
    RestoreScoringValues();
    
    super.Destroyed();
}

function SetupMultipliers()
{
    if ( KF.GameDifficulty >= 7.0 ) // HoE
        DoshDifficultyMult = DoshMultHoe;
    else if ( KF.GameDifficulty >= 5.0 ) // Suicidal
        DoshDifficultyMult = DoshMultSui;
    else if ( KF.GameDifficulty >= 4.0 ) // Hard
        DoshDifficultyMult = DoshMultHard;
    else if ( KF.GameDifficulty >= 2.0 ) // Normal
        DoshDifficultyMult = DoshMultNorm;
    else 
        DoshDifficultyMult = DoshMultBeg;

    // Increase score in a short game, so the player can afford to buy cool stuff by the end
    if( KF.KFGameLength == KF.GL_Short )
        DoshDifficultyMult *= 1.75;
        
    if ( bDropTeamDosh )
        DoshDifficultyMult *= 2.0; // no money goes to team.score
    
    // prevent cheating
    ZedHealthMult = fmax(ZedHealthMult, 0.f); 
    MaxHealthMult = fmax(MaxHealthMult, 1.f); 
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
    if ( KFMonster(Other) != none )
        SetupMonster(KFMonster(Other));

    return true;
} 

function SetupMonster(KFMonster M)
{
    local int i;
    
    for ( i=0; i<MonsterData.length; ++i ) {
        if ( MonsterData[i].MC == M.class )
            break;
    }
    
    if ( i == MonsterData.length ) {
        MonsterData.insert(i, 1);
        MonsterData[i].MC = M.class;
        MonsterData[i].ScoringValue = M.default.ScoringValue;
        
        if ( bDropTeamDosh )
            M.default.ScoringValue = 0;
    }
    
    M.ScoringValue = MonsterData[i].ScoringValue * DoshDifficultyMult;
}

// since we are adjusting default values, need to set them back at the end of the game
function RestoreScoringValues()
{
    local int i;
    
    for ( i=0; i<MonsterData.length; ++i ) 
        MonsterData[i].MC.default.ScoringValue = MonsterData[i].ScoringValue;
    
    MonsterData.length = 0;
}

function Mutate(string MutateString, PlayerController Sender)
{
    super.Mutate(MutateString, Sender);
    
    if ( MutateString ~= "VERSION" )
        Sender.ClientMessage(FriendlyName $ " v"$VERSION);
}    

defaultproperties
{
    VERSION="1.0"
    CfgGroup="Dosh Grab"
    
    DoshMultBeg=2.0
    DoshMultNorm=1.0
    DoshMultHard=0.85
    DoshMultSui=0.65
    DoshMultHoe=0.65
    DoshDifficultyMult=1.0
    bZedsCanPickupDosh=True
    ZedHealthMult=1.0
    MaxHealthMult=5.0
    
    bAddToServerPackages=True
    
    GroupName="KF-DoshGrab"
    FriendlyName="Dosh Grab SE"
    Description="Dosh! Grab it while it's hot! Killing zeds makes them dropping money instead of adding it directly to player's wallet."
}