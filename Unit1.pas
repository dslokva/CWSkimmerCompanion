unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, inifiles, Vcl.Samples.Spin,
  Vcl.ActnMan, Vcl.ActnColorMaps, Vcl.ComCtrls, Vcl.Buttons, RegExpr, OmniRig_TLB,
  IdTelnet, IdGlobal, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient,
  Vcl.AppEvnts, Vcl.Menus;

type
  TForm1 = class(TForm)
    TelnetMemo1: TMemo;
    btnConnect: TButton;
    Label10: TLabel;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label11: TLabel;
    rbRig1: TRadioButton;
    rbRig2: TRadioButton;
    Bevel1: TBevel;
    IdTelnet1: TIdTelnet;
    txtCallsign: TEdit;
    Label12: TLabel;
    txtTelnetAddress: TEdit;
    Label13: TLabel;
    Label14: TLabel;
    txtTelnetPort: TSpinEdit;
    delayTuneTimer1: TTimer;
    Bevel2: TBevel;
    Label15: TLabel;
    spinLOOffset: TSpinEdit;
    TrayIcon1: TTrayIcon;
    ApplicationEvents1: TApplicationEvents;
    errLabel1: TLabel;
    errLabelsDissapearTimer1: TTimer;
    TrayPopupMenu1: TPopupMenu;
    Show1: TMenuItem;
    Exit1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure sentTelnetString (ds: String);
    procedure rbRig1Click(Sender: TObject);
    procedure rbRig2Click(Sender: TObject);
    procedure IdTelnet1DataAvailable(Sender: TIdTelnet; const Buffer: TIdBytes);
    procedure delayTuneTimer1Timer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ApplicationEvents1Minimize(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure errLabelsDissapearTimer1Timer(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure IdTelnet1Disconnected(Sender: TObject);
  private
    procedure StatusChangeEvent(Sender: TObject; RigNumber: Integer);
    procedure ParamsChangeEvent(Sender: TObject; RigNumber, Params: Integer);
    procedure RigTypeChangeEvent(Sender: TObject; RigNumber: Integer);
    procedure setTRXFrequency(freqToSet : integer);
    procedure CreateRigControl;
    procedure KillRigControl;
    procedure SetLOFreqToSkimmer(Freq : integer);
    procedure SetTuneFreqToSkimmer(Freq : integer);
    procedure RefreshRigsParams();
    procedure FreqSetAndShow(Freq_TUNE_Str: string; Freq_TUNE_Str_ToShow: string);

  public
    OmniRig: TOmniRigX;
  end;

var
  Form1: TForm1;
  regExp : TRegExpr;
  ActiveRigNumber : word;
  Freq_TUNE, Old_Freq_TUNE : integer;
  DontReactOnSkimmerClick : boolean;
  activeRigMode : string;

implementation

{$R *.DFM}

procedure TForm1.ApplicationEvents1Minimize(Sender: TObject);
begin
  Hide();
  WindowState := wsMinimized;

  TrayIcon1.BalloonHint := 'PSE double click to restore';

  TrayIcon1.Visible := True;
  TrayIcon1.Animate := True;
  TrayIcon1.ShowBalloonHint;
end;

//------------------------------------------------------------------------------
//                  OmniRig object creation and destruction
//------------------------------------------------------------------------------
procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
var
  iniFile : TIniFile;
begin
iniFile := TIniFile.Create(ChangeFileExt(Application.ExeName,'.ini')) ;
try
  with iniFile do begin
    WriteInteger('CWSCSettings', 'ActiveRig', ActiveRigNumber);
    WriteInteger('CWSCSettings', 'LOOffset', StrToInt(spinLOOffset.Text));
    WriteString('CWSCSettings', 'TelnetAddress', txtTelnetAddress.Text);
    WriteInteger('CWSCSettings', 'TelnetPort', StrToInt(txtTelnetPort.Text));
    WriteString('CWSCSettings', 'TelnetCallsign', txtCallsign.Text);
  end;

finally
  iniFile.Free;
end;

end;

procedure TForm1.FormCreate(Sender: TObject);
var
  iniFile : TIniFile;
begin
  ActiveRigNumber := 1;
  IdTelnet1.Terminal:='VT100';
  DontReactOnSkimmerClick := false;

try
  iniFile := TIniFile.Create(ChangeFileExt(Application.ExeName,'.ini'));
  with iniFile do begin
    ActiveRigNumber := ReadInteger('CWSCSettings', 'ActiveRig', 1);
    if ActiveRigNumber = 2 then
      rbRig2.Checked := true;

    spinLOOffset.Value := ReadInteger('CWSCSettings', 'LOOffset', -700);
    txtTelnetPort.Value := ReadInteger('CWSCSettings', 'TelnetPort', 7300);
    txtCallsign.Text := ReadString('CWSCSettings', 'TelnetCallsign', 'XX0XXX');
    txtTelnetAddress.Text := ReadString('CWSCSettings', 'TelnetAddress', '127.0.0.1');
  end;
finally
  iniFile.Free;
end;

  CreateRigControl();
  RefreshRigsParams();
  RigTypeChangeEvent(nil, ActiveRigNumber);
  StatusChangeEvent(nil, ActiveRigNumber);
End;

function ModeName(Mode: integer): string;
begin
  case Mode of
    PM_CW_U,
    PM_CW_L:   Result := 'CW';
    PM_SSB_U:  Result := 'USB';
    PM_SSB_L:  Result := 'LSB';
    PM_DIG_U,
    PM_DIG_L:  Result := 'DIG';
    PM_AM:     Result := 'AM';
    PM_FM:     Result := 'FM';
    else       Result := 'Unknown';
    end;
end;


procedure TForm1.IdTelnet1DataAvailable(Sender: TIdTelnet;
  const Buffer: TIdBytes);
var
  incomeStr, spotFreqStr, fromDXCstr : String;
  start, stop, spotFreq : integer;

begin
incomeStr := BytesToString(Buffer);

Start := 1;
Stop := Pos(CR, incomeStr);

if Stop = 0 then
  Stop := Length(incomeStr) + 1;

if Start <= Length(incomeStr) then
  fromDXCstr := Copy(incomeStr, Start, Stop - Start);


regExp := TRegExpr.Create;
regExp.ModifierM := true;

regExp.Expression := txtCallsign.Text+'+\sde SKIMMER\s\d{4}\-\d{2}\-\d{2}\s\d{2}\:\d{2}Z\sCwSkimmer\s\>';
if regExp.Exec(fromDXCstr) then exit;

TelnetMemo1.Lines.Add(fromDXCstr);

regExp.Expression := 'SKIMMER.*:\sClicked\son\s\"(.*)\"\sat\s(.*).*$';
if regExp.Exec(fromDXCstr) then begin
  spotFreqStr := StringReplace(regExp.Match[2], '.', ',', [rfIgnoreCase, rfReplaceAll]);
  spotFreq := round(StrToFloat(spotFreqStr)*1000);
  setTRXFrequency(spotFreq);
  DebugOutput('SetFreq: '+IntToStr(spotFreq));
end;

regExp.Free;
End;

procedure TForm1.setTRXFrequency(freqToSet : integer);
begin
  if (OmniRig = nil) or ((OmniRig.Rig1.Status <> ST_ONLINE) AND (OmniRig.Rig2.Status <> ST_ONLINE)) then Exit;
  case ActiveRigNumber of
    1:
      if OmniRig.Rig1.Status = ST_ONLINE then begin
        OmniRig.Rig1.SetSimplexMode(freqToSet);
      end;

    2:
      if OmniRig.Rig2.Status = ST_ONLINE then begin
        OmniRig.Rig2.SetSimplexMode(freqToSet);
      end;
    end;
End;

//------------------------------------------------------------------------------
//                         OmniRig event handling
//------------------------------------------------------------------------------
procedure TForm1.ParamsChangeEvent(Sender: TObject; RigNumber,  Params: Integer);
begin
   if OmniRig = nil then Exit;
   RefreshRigsParams();


  if DontReactOnSkimmerClick then Exit;

    if (IdTelnet1.Connected) and ((OmniRig.Rig1.Status = ST_ONLINE) or (OmniRig.Rig2.Status = ST_ONLINE)) then begin
      delayTuneTimer1.Enabled := false;
      if (Old_Freq_TUNE <> Freq_TUNE) then begin
        Old_Freq_TUNE := Freq_TUNE;
        SetLOFreqToSkimmer(Freq_TUNE);
        delayTuneTimer1.Enabled := true;
      end;

    end else begin
      Label10.Caption := '__';
      Label2.Caption := '__';
      Label4.Caption := '__';
    end;
end;

procedure TForm1.SetLOFreqToSkimmer(Freq : integer);
var
  Freq_LO_Str : string;
begin
  Freq_LO_Str := (IntToStr(Freq+spinLOOffset.Value));

  if IdTelnet1.Connected then begin
    sentTelnetString('SKIMMER/LO_FREQ '+ Freq_LO_Str);
    Label10.Caption := Freq_LO_Str;
  end;
End;

procedure TForm1.SetTuneFreqToSkimmer(Freq : integer);
var
  Freq_TUNE_Str, Freq_TUNE_Str_ToShow, cut : string;
begin
  Freq_TUNE_Str := StringReplace(FormatFloat('##.##', Freq/1000), ',', '.', [rfIgnoreCase, rfReplaceAll]);

  cut := Copy(Freq_TUNE_Str, 1, Pos('.', Freq_TUNE_Str)-1);
  if cut = '' then begin
    cut := Freq_TUNE_Str;
    Freq_TUNE_Str := Freq_TUNE_Str + '.00';
  end;

  if Length(cut) = 4 then
    Freq_TUNE_Str_ToShow :=  Copy(Freq_TUNE_Str, 1, 1) + '.' + Copy(Freq_TUNE_Str, 2, 6);

  if (Length(cut) = 5) then
    Freq_TUNE_Str_ToShow :=  Copy(Freq_TUNE_Str, 1, 2) + '.' + Copy(Freq_TUNE_Str, 3, 6);

  FreqSetAndShow(Freq_TUNE_Str, Freq_TUNE_Str_ToShow);

End;

procedure TForm1.FreqSetAndShow(Freq_TUNE_Str: string; Freq_TUNE_Str_ToShow: string);
var
  cut : string;
begin
  if IdTelnet1.Connected then begin
    sentTelnetString('SKIMMER/QSY ' + Freq_TUNE_Str);
  end;

  cut := Copy(Freq_TUNE_Str, Pos('.', Freq_TUNE_Str)+1, 2);
  if Length(cut) = 1 then
    Freq_TUNE_Str_ToShow := Freq_TUNE_Str_ToShow + '0';

  TrayIcon1.BalloonHint := 'QSY to: ' + Freq_TUNE_Str_ToShow;
  TrayIcon1.ShowBalloonHint;
end;

procedure TForm1.RefreshRigsParams();
begin
  case ActiveRigNumber of
    1:
      begin
        Freq_TUNE := OmniRig.Rig1.GetRxFrequency;
        activeRigMode := ModeName(OmniRig.Rig1.Mode);
      end;
    2:
      begin
        Freq_TUNE := OmniRig.Rig2.GetRxFrequency;
        activeRigMode := ModeName(OmniRig.Rig2.Mode);
      end;
  end;
  Label2.Caption := IntToStr(Freq_TUNE);
  Label4.Caption := activeRigMode;
end;

procedure TForm1.CreateRigControl;
begin
  //create and configure the OmniRig object
  OmniRig := TOmniRigX.Create(Self);
  try
    OmniRig.Connect;
    //listen to OmniRig events
    OmniRig.OnRigTypeChange := RigTypeChangeEvent;
    OmniRig.OnStatusChange := StatusChangeEvent;
    OmniRig.OnParamsChange := ParamsChangeEvent;

    //Check OmniRig version: in this demo we want V.1.1 to 1.99
    if OmniRig.InterfaceVersion < $0101 then Abort;
    if OmniRig.InterfaceVersion > $0199 then Abort;


if (OmniRig = nil) or ((OmniRig.Rig1.Status <> ST_ONLINE) AND (OmniRig.Rig2.Status <> ST_ONLINE)) then Exit;
  case ActiveRigNumber of
    1: begin
      RigTypeChangeEvent(nil, 1);
      StatusChangeEvent(nil, 1);
      ParamsChangeEvent(nil, 1, 0);
    end;
    2: begin
      RigTypeChangeEvent(nil, 2);
      StatusChangeEvent(nil, 2);
      ParamsChangeEvent(nil, 2, 0);
    end;
  end;

  except
    KillRigControl;
    MessageDlg('Unable to create the Omnirig object', mtError, [mbOk], 0);
  end;
end;

procedure TForm1.errLabelsDissapearTimer1Timer(Sender: TObject);
begin
errLabel1.Visible := false;
errLabelsDissapearTimer1.Enabled := false;
end;

procedure TForm1.Exit1Click(Sender: TObject);
begin
Application.Terminate;
end;

procedure TForm1.KillRigControl;
begin
  try FreeAndNil(OmniRig); except end;
end;

procedure TForm1.rbRig1Click(Sender: TObject);
begin
GroupBox1.Caption := 'RIG #1';
ActiveRigNumber := 1;
if (OmniRig <> nil) then begin
  RigTypeChangeEvent(nil, 1);
  StatusChangeEvent(nil, 1);
  RefreshRigsParams();
end;
end;

procedure TForm1.rbRig2Click(Sender: TObject);
begin
GroupBox1.Caption := 'RIG #2';
ActiveRigNumber := 2;
if (OmniRig <> nil) then begin
  RigTypeChangeEvent(nil, 2);
  StatusChangeEvent(nil, 2);
  RefreshRigsParams();
end;
end;

procedure TForm1.RigTypeChangeEvent(Sender: TObject; RigNumber: Integer);
begin
  if OmniRig = nil then Exit;

  case ActiveRigNumber of
    1: Label6.Caption := OmniRig.Rig1.RigType;
    2: Label6.Caption := OmniRig.Rig2.RigType;
  end;
end;

procedure TForm1.StatusChangeEvent(Sender: TObject; RigNumber: Integer);
begin
  if OmniRig = nil then Exit;

  case ActiveRigNumber of
    1: Label8.Caption := OmniRig.Rig1.StatusStr;
    2: Label8.Caption := OmniRig.Rig2.StatusStr;
  end;
end;

procedure TForm1.delayTuneTimer1Timer(Sender: TObject);
begin
DontReactOnSkimmerClick := true;
delayTuneTimer1.Enabled := false;
SetTuneFreqToSkimmer(Freq_TUNE);
DontReactOnSkimmerClick := false;
end;

procedure TForm1.TrayIcon1DblClick(Sender: TObject);
begin
  TrayIcon1.Visible := False;
  Show();
  WindowState := wsNormal;
  Application.BringToFront();
end;

procedure TForm1.sentTelnetString(ds: string);
var
  i : Integer;
begin
  for i:= 1 to length(ds) do IdTelnet1.SendCh(ds[i]);
  IdTelnet1.SendCh(#13);
end;


procedure TForm1.btnConnectClick(Sender: TObject);
var
 errText : string;
begin
errText := '';

if IdTelnet1.Connected then begin
  try
    sentTelnetString('BYE');
    sleep(200);
    btnConnect.Caption := 'Connect to CW Skimmer';
    exit;
  except
    on e : Exception do begin
      errText := StringReplace(e.ToString, #$D#$A, '. ', [rfIgnoreCase, rfReplaceAll]);
      IdTelnet1.Disconnect;
      errLabel1.Caption := 'Error: ' + errText;
      errLabel1.Visible := true;
      errLabelsDissapearTimer1.Enabled := true;
    end;
  end;
end;

if not IdTelnet1.Connected then begin
  try
    IdTelnet1.Host := txtTelnetAddress.Text;
    IdTelnet1.Port := txtTelnetPort.Value;
    IdTelnet1.Connect;
    sleep(50);
    sentTelnetString(txtCallsign.Text);
    btnConnect.Caption := 'Disconnect from CW Skimmer';
    ParamsChangeEvent(nil, ActiveRigNumber, 0);
  except
    on e : Exception do begin
      errText := StringReplace(e.ToString, #$D#$A, '. ', [rfIgnoreCase, rfReplaceAll]);
      errLabel1.Caption := 'Error: ' + errText;
      errLabel1.Visible := true;
      errLabelsDissapearTimer1.Enabled := true;
      btnConnect.Caption := 'Connect to CW Skimmer';
    end;
  end;
end;

End;

procedure TForm1.IdTelnet1Disconnected(Sender: TObject);
begin
  btnConnect.Caption := 'Connect to CW Skimmer';
End;

END.

