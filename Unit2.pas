unit Unit2;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids, Vcl.ValEdit,
  Vcl.ExtCtrls, inifiles;

type
  TperBandForm = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Button1: TButton;
    Button2: TButton;
    kvgBandLOValues: TValueListEditor;
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure kvgBandLOValuesKeyPress(Sender: TObject; var Key: Char);
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    freqLOperBandList : TStringList;
    { Public declarations }
  end;

var
  perBandForm: TperBandForm;
  saveValuesPermit : boolean;

implementation

{$R *.dfm}

procedure TperBandForm.Button1Click(Sender: TObject);
begin
freqLOperBandList.Values['160'] := kvgBandLOValues.Values['160'];
freqLOperBandList.Values['80'] := kvgBandLOValues.Values['80'];
freqLOperBandList.Values['40'] := kvgBandLOValues.Values['40'];
freqLOperBandList.Values['30'] := kvgBandLOValues.Values['30'];
freqLOperBandList.Values['20'] := kvgBandLOValues.Values['20'];
freqLOperBandList.Values['17'] := kvgBandLOValues.Values['17'];
freqLOperBandList.Values['15'] := kvgBandLOValues.Values['15'];
freqLOperBandList.Values['12'] := kvgBandLOValues.Values['12'];
freqLOperBandList.Values['10'] := kvgBandLOValues.Values['10'];
freqLOperBandList.Values['6'] := kvgBandLOValues.Values['6'];
saveValuesPermit := true;
perBandForm.Close;
end;

procedure TperBandForm.Button2Click(Sender: TObject);
begin
saveValuesPermit := false;
perBandForm.Close;
end;

procedure TperBandForm.FormClose(Sender: TObject; var Action: TCloseAction);
var
  iniFile : TIniFile;
begin
if saveValuesPermit then begin
  iniFile := TIniFile.Create(ChangeFileExt(Application.ExeName,'.ini')) ;
  try
    with iniFile do begin
      WriteString('CWSCSettings', 'LO160', freqLOperBandList.Values['160']);
      WriteString('CWSCSettings', 'LO80', freqLOperBandList.Values['80']);
      WriteString('CWSCSettings', 'LO40', freqLOperBandList.Values['40']);
      WriteString('CWSCSettings', 'LO30', freqLOperBandList.Values['30']);
      WriteString('CWSCSettings', 'LO20', freqLOperBandList.Values['20']);
      WriteString('CWSCSettings', 'LO17', freqLOperBandList.Values['17']);
      WriteString('CWSCSettings', 'LO15', freqLOperBandList.Values['15']);
      WriteString('CWSCSettings', 'LO12', freqLOperBandList.Values['12']);
      WriteString('CWSCSettings', 'LO10', freqLOperBandList.Values['10']);
      WriteString('CWSCSettings', 'LO6', freqLOperBandList.Values['6']);
    end;
  finally
    iniFile.Free;
  end;
end;

End;

procedure TperBandForm.FormCreate(Sender: TObject);
var
  iniFile : TIniFile;
  i : integer;
  lo160, lo80, lo40, lo30, lo20, lo17, lo15, lo12, lo10, lo6 : string;

begin
freqLOperBandList := TStringList.Create;
try
  iniFile := TIniFile.Create(ChangeFileExt(Application.ExeName,'.ini'));
  with iniFile do begin
     lo160 := ReadString('CWSCSettings', 'LO160', '1824000');
     lo80 := ReadString('CWSCSettings', 'LO80', '3524000');
     lo40 := ReadString('CWSCSettings', 'LO40', '7024000');
     lo30 := ReadString('CWSCSettings', 'LO30', '10124000');
     lo20 := ReadString('CWSCSettings', 'LO20', '14024000');
     lo17 := ReadString('CWSCSettings', 'LO17', '18090000');
     lo15 := ReadString('CWSCSettings', 'LO15', '21030000');
     lo12 := ReadString('CWSCSettings', 'LO12', '24910000');
     lo10 := ReadString('CWSCSettings', 'LO10', '28030000');
     lo6 := ReadString('CWSCSettings', 'LO6', '50170000');
  end;
finally
  if iniFile <> nil then
    iniFile.Free;
end;
kvgBandLOValues.InsertRow('160', lo160, true);
freqLOperBandList.Values['160'] := lo160;

kvgBandLOValues.InsertRow('80', lo80, true);
freqLOperBandList.Values['80'] := lo80;

kvgBandLOValues.InsertRow('40', lo40, true);
freqLOperBandList.Values['40'] := lo40;

kvgBandLOValues.InsertRow('30', lo30, true);
freqLOperBandList.Values['30'] := lo30;

kvgBandLOValues.InsertRow('20', lo20, true);
freqLOperBandList.Values['20'] := lo20;

kvgBandLOValues.InsertRow('17', lo17, true);
freqLOperBandList.Values['17'] := lo17;

kvgBandLOValues.InsertRow('15', lo15, true);
freqLOperBandList.Values['15'] := lo15;

kvgBandLOValues.InsertRow('12', lo12, true);
freqLOperBandList.Values['12'] := lo12;

kvgBandLOValues.InsertRow('10', lo10, true);
freqLOperBandList.Values['10'] := lo10;

kvgBandLOValues.InsertRow('6', lo6, true);
freqLOperBandList.Values['6'] := lo6;

kvgBandLOValues.ColWidths[0] := 90;
kvgBandLOValues.ColWidths[1] := 200;

//for i := 0 to kvgBandLOValues.RowCount-1 do
//  kvgBandLOValues.RowHeights[i] := 35;

end;

procedure TperBandForm.kvgBandLOValuesKeyPress(Sender: TObject; var Key: Char);
begin
if not (Key in ['0'..'9', #8]) then
  Key := #0;
end;

end.
