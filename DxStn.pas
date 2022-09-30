//------------------------------------------------------------------------------
//This Source Code Form is subject to the terms of the Mozilla Public
//License, v. 2.0. If a copy of the MPL was not distributed with this
//file, You can obtain one at http://mozilla.org/MPL/2.0/.
//------------------------------------------------------------------------------
unit DxStn;

interface

uses
  SysUtils, Classes, Station, RndFunc, Dialogs, Ini, ARRLFD, CWOPS,
  CallLst, Qsb, DxOper, Log, SndTypes;

type
  TDxStation = class(TStation)
  private
    Qsb: TQsb;
  public
    Oper: TDxOperator;
    constructor CreateStation;
    destructor Destroy; override;
    procedure ProcessEvent(AEvent: TStationEvent); override;
    procedure SendMsg(AMsg: TStationMessage); override;
    procedure DataToLastQso;
    function GetBlock: TSingleArray; override;
  var
     Operid: integer;
  end;


implementation

uses
  Contest;

{ TDxStation }

constructor TDxStation.CreateStation;
begin
  inherited Create(nil);

  HisCall := Ini.Call;
  // Adding a contest: DxStation.CreateStation - load a random callsign
  case SimContest of
    scCwt: begin
       Operid := CWOPSCWT.getcwopsid();
       MyCall :=  CWOPSCWT.getcwopscall(Operid);
    end;
    scFieldDay: begin
       Operid := gARRLFD.pickStation();
       MyCall := gARRLFD.getCall(Operid);
    end;
    else
       MyCall := PickCall;     // Pick one Callsign from Calllist
  end;

  Oper := TDxOperator.Create;
  Oper.Call := MyCall;
  Oper.Skills := 1 + Random(3); //1..3
  Oper.SetState(osNeedPrevEnd);
  NrWithError := Ini.Lids and (Random < 0.1);

  Wpm := Oper.GetWpm;

  // Adding a contest: DxStation.CreateStation - get Exch1 (e.g. Name), Exch2 (e.g. NR), and optional UserText
  case SimContest of
    scCwt: begin
      OpName := CWOPSCWT.getcwopsname(Operid);
      NR :=  CWOPSCWT.getcwopsnum(Operid);
    end;
    scFieldDay: begin
      Exch1 := gARRLFD.getExch1(Operid);
      Exch2 := gARRLFD.getExch2(Operid);
      UserText := gARRLFD.getUserText(Operid);
    end;
    else
      NR := Oper.GetNR;
  end;
  //showmessage(MyCall);

  if Ini.Lids and (Random < 0.03) then
    RST := 559 + 10 * Random(4)
  else
    RST := 599;

  Qsb := TQsb.Create;

  Qsb.Bandwidth := 0.1 + Random / 2;
  if Ini.Flutter and (Random < 0.3) then
    Qsb.Bandwidth := 3 + Random * 30;

  Amplitude := 9000 + 18000 * (1 + RndUShaped);
  Pitch := Round(RndGaussLim(0, 300));

  //the MeSent event will follow immediately
  TimeOut := NEVER;
  State := stCopying;
end;


destructor TDxStation.Destroy;
begin
  Oper.Free;
  Qsb.Free;
  inherited;
end;


procedure TDxStation.ProcessEvent(AEvent: TStationEvent);
var
  i: integer;
begin
  if Oper.State = osDone then Exit;

  case AEvent of
    evMsgSent:
      //we finished sending and started listening
      if Tst.Me.State = stSending
        then TimeOut := NEVER
        else TimeOut := Oper.GetReplyTimeout;

    evTimeout:
      begin
      //he did not reply, quit or try again
      if State = stListening then
        begin
        Oper.MsgReceived([msgNone]);
        if Oper.State = osFailed then begin Free; Exit; end;
        State := stPreparingToSend;
        end;
      //preparations to send are done, now send
      if State = stPreparingToSend then
        for i:=1 to Oper.RepeatCnt do SendMsg(Oper.GetReply)
      end;

    evMeFinished: //he finished sending
      //we notice the message only if we are not sending ourselves
      if State <> stSending then
        begin
        //interpret the message
        case State of
          stCopying:
            Oper.MsgReceived(Tst.Me.Msg);

          stListening, stPreparingToSend:
           //these messages can be copied even if partially received
            if (msgCQ in Tst.Me.Msg) or (msgTU in Tst.Me.Msg) or (msgNil in Tst.Me.Msg)
              then Oper.MsgReceived(Tst.Me.Msg)
              else Oper.MsgReceived([msgGarbage]);
          end;

          //react to the message
          if Oper.State = osFailed
            then begin Free; Exit; end         //give up
            else TimeOut := Oper.GetSendDelay; //reply or switch to standby
          State := stPreparingToSend;
        end;

    evMeStarted:
      //If we are not sending, we can start copying
      //Cancel timeout, he is replying
      begin
        if State <> stSending then
          State := stCopying;
        TimeOut := NEVER;
      end;
    end;
end;


// override SendMsg to allow Dx Stations to send alternate field day messages
// (SECT?, CLASS?, CL?) whenever a 'NR?' message (msgNrQm) is sent.
procedure TDxStation.SendMsg(AMsg: TStationMessage);
begin
  if (SimContest = scFieldDay) and
    (AMsg = msgNrQm) then
    begin
      case Random(5) of
        0,1: SendText('NR?');
        2: SendText('SECT?');
        3: SendText('CLASS?');
        4: SendText('CL?');
      end;
    end
  else
    inherited SendMsg(AMsg);
end;


// copies data from this DxStation to top of QsoList[].
// removes Self from Stations[] container array.
procedure TDxStation.DataToLastQso;
begin
  with QsoList[High(QsoList)] do begin
    TrueCall := Self.MyCall;
    TrueRst := Self.Rst;
    TrueNR := Self.NR;
    case ActiveContest.ExchType1 of
      etRST: TrueExch1 := IntToStr(Self.NR);
      etOpName: TrueExch1 := Self.OpName;
      etFdClass: TrueExch1 := Self.Exch1;
      else
        assert(false);
    end;
    case ActiveContest.ExchType2 of
      etSerialNr: TrueExch2 := IntToStr(Self.NR);
      etCwopsNumber: TrueExch2 := IntToStr(Self.NR);
      etArrlSection: TrueExch2 := Self.Exch2;
      else
        assert(false);
    end;
  end;

  Free; // removes Self from Stations[] container
end;




function TDxStation.GetBlock: TSingleArray;
begin
  Result := inherited GetBlock;
  if Ini.Qsb then Qsb.ApplyTo(Result);
end;

end.

