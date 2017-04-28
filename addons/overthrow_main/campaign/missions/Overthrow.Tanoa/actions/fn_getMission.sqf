params ["_faction","_factionName"];

private _haveMission = player getVariable [format["MissionData%1",_faction],[]];
if(count _haveMission > 0) exitWith {"You already have an active mission for this faction" call notify_minor};

private _standing = server getvariable [format["standing%1",_faction],0];
if(_faction != OT_currentMissionFaction) then {OT_currentMissionData = nil};

private _data = [];
OT_currentMissionFaction = _faction;
OT_currentMissionFactionName = _factionName;

if(isNil "OT_currentMissionData") then {
    private _missionCode = selectRandom OT_missions;
    _data = call _missionCode;
    OT_currentMissionData = _data;
}else{
    _data = OT_currentMissionData;
};
private _difficulty = _data select 7;
private _rewardStanding = round((((100 - _standing) / 50) * _difficulty) * 100) / 100;
if(_rewardStanding < 0.1) then {_rewardStanding = 0.1}; //minimum standing 0.1
private _rewardMoney = round(_standing * 20);
if(_rewardMoney < 250) then {_rewardMoney = 250}; //minimum reward 250
_rewardMoney = _rewardMoney * _difficulty;
OT_currentMissionRewards = [_rewardStanding,_rewardMoney];

private _txt = _data select 0;
private _description = format["<t size='0.9' align='center'>%5<br/><br/></t><t size='0.65'>%1<br/><br/></t><t size='0.7' align='center'>Reward: $%2 | Standing (%3): +%4</t>",_txt select 1,_rewardMoney,_factionName,_rewardStanding,_txt select 0];

private _options = [_description];

_options pushback ["Accept",{
    player setVariable [format["MissionData%1",OT_currentMissionFaction],OT_currentMissionData,false];

    OT_currentMissionData params ["_description","_markerPos","_code","_fail","_success","_finish","_params"];
    _title = _description select 0;
    _title = format["(%1) %2",OT_currentMissionFactionName,_title];
    _description = _description select 1;
    [player,_markerPos,_title,_description,{
        params ["_target","_pos","_p","_wassuccess"];
        _p params ["_missionParams","_faction","_factionName","_finish","_rewards"];
        player setVariable [format["MissionData%1",_faction],[],false];
        _this call _finish;
        if(_wassuccess) then {
            _rewardStanding = _rewards select 0;
            _standing = server getvariable [format["standing%1",_faction],0];
            server setvariable [format["standing%1",_faction],_standing+_rewardStanding,true];
            format["%1 completed a mission (+%2 %3)",name player,_rewardStanding,_factionName] remoteExec ["notify_minor",0,false];
        };
        OT_currentMissionData = nil;
    },_success,OT_currentMissionRewards select 1,0,_fail,[OT_currentMissionData select 6,OT_currentMissionFaction,OT_currentMissionFactionName,OT_currentMissionData select 5,OT_currentMissionRewards]] spawn OT_fnc_assignMission;

    [OT_currentMissionData select 6,OT_currentMissionFaction,OT_currentMissionFactionName] spawn (OT_currentMissionData select 2);
}];

_options pushback ["Decline",{
    //clear this mission so a new one will generate
    OT_currentMissionData = nil;
    _civ = OT_interactingWith;
    [_civ getvariable ["faction",""],_civ getvariable ["factionrepname",""]] call OT_fnc_getMission;
}];

_options pushback ["Cancel",{
    OT_currentMissionData = nil;
}];

_options spawn playerDecision;
