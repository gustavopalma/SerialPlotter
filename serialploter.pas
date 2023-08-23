unit SerialPloter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, PairSplitter, LazSerial, TAGraph, TASeries, LazSynaSer;

type
  PTSerialPort = ^TLazSerial;

type
  PTSeries = ^TLineSeries;

{ TReceiverThread }
type
  TReceiverThread = class(TThread)
private
  FPTSeries: PTSeries;
  FPTSerialPort: PTSerialPort;
  FRun: Boolean;
  buf : String;
  x : Integer;
public
  property run : Boolean read FRun write FRun default True;
  property SerialPort : PTSerialPort read FPTSerialPort write FPTSerialPort;
  property series : PTSeries read FPTSeries write FPTSeries;
  procedure execute; override;
  procedure updateVisual;
  constructor Create;
  destructor Destroy; override;
end;

type

  { TFrmPlotter }

  TFrmPlotter = class(TForm)
    btnConectar: TButton;
    btnLimpar: TButton;
    btnAtualizar: TButton;
    Chart1: TChart;
    ASeries: TLineSeries;
    cboBaudRate: TComboBox;
    cboPortas: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    LazSerial1: TLazSerial;
    ToolBar1: TToolBar;
    procedure btnAtualizarClick(Sender: TObject);
    procedure btnConectarClick(Sender: TObject);
    procedure btnLimparClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    Receiver: TReceiverThread;
    procedure updateSerial;
    procedure PopulaBaud;
  public

  end;

var
  FrmPlotter: TFrmPlotter;

implementation

{$R *.lfm}

{ TReceiverThread }

procedure TReceiverThread.execute;
begin
  while FRun do
    begin
     if FPTSerialPort^.DataAvailable then
      begin
       buf := buf + FPTSerialPort^.ReadData;
       Synchronize(@updateVisual);
      end;
      Sleep(200);
    end;
end;

procedure TReceiverThread.updateVisual;
var
  BufAux : TStringArray;
  i : integer;
  tmp : String;
begin
 BufAux := TStringArray.create;
 BufAux := buf.Split(#13#10);
 for i := 0 to High(BufAux) do
 begin
   tmp := BufAux[i];
   tmp := tmp.Replace(#13,'');
   tmp := tmp.Replace(#10,'');
   if tmp = EmptyStr then
    continue;

   if series^.Count > 100 then
    begin
     series^.Delete(0);
    end;

   inc(x);
   series^.AddXY(x,StrToFloat(tmp));
 end;

 buf := EmptyStr;
end;

constructor TReceiverThread.Create;
begin
  inherited Create(True);
  FRun := True;
end;

destructor TReceiverThread.Destroy;
begin
  inherited Destroy;
end;

{ TFrmPlotter }

procedure TFrmPlotter.FormCreate(Sender: TObject);
begin
  updateSerial;
  PopulaBaud;

  Receiver := TReceiverThread.create();
  Receiver.FreeOnTerminate:= True;
  Receiver.FPTSerialPort:=@LazSerial1;
  Receiver.series:=@ASeries;
  Receiver.Start;
end;

procedure TFrmPlotter.btnAtualizarClick(Sender: TObject);
begin
  updateSerial;
  PopulaBaud;
end;

procedure TFrmPlotter.btnConectarClick(Sender: TObject);
begin
  if cboPortas.Items[cboPortas.ItemIndex] = EmptyStr then
  begin
    Application.MessageBox('Você Primeiro Deve Selecionar a Porta Serial','Porta Inválida');
  end;

  if cboBaudRate.Items[cboBaudRate.ItemIndex] = EmptyStr then
  begin
    Application.MessageBox('Você Primeiro Deve Selecionar um Baud Rate','Baud Rate Inválido');
  end;

   with LazSerial1 do
   begin
     if not Active then
       begin
        device   := cboPortas.Items[cboPortas.ItemIndex];
        BaudRate := TBaudRate(cboBaudRate.ItemIndex);
        Active:=True;
        btnConectar.Caption:='Desconectar';
       end else
        begin
          device   := EmptyStr;
          BaudRate := br_____0;
          Active:=False;
          btnConectar.Caption:='Conectar';
        end;
   end;

  if LazSerial1.Active then
     begin
       cboBaudRate.Enabled:=False;
       btnAtualizar.Enabled:=False;
       cboPortas.Enabled:=False;
       btnLimpar.Enabled:=True;
       ASeries.Clear;
     end else
      begin
        cboBaudRate.Enabled:=True;
        btnAtualizar.Enabled:=True;
        cboPortas.Enabled:=True;
        btnLimpar.Enabled:=False;
        ASeries.Clear;
      end;

end;

procedure TFrmPlotter.btnLimparClick(Sender: TObject);
begin
  ASeries.Clear;
end;

procedure TFrmPlotter.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  LazSerial1.Active := False;


  Receiver.run := False;
  Receiver.Terminate;
  FreeAndNil(receiver);
end;

procedure TFrmPlotter.PopulaBaud;
var
 i : TBaudRate;
 bauds : TStringList;
begin
  bauds := TStringList.create;
  for i := br_____0 to high(LazSerial.ConstsBaud) do
  begin
    bauds.Add(IntToStr(LazSerial.ConstsBaud[i]));
  end;
  cboBaudRate.Items.CommaText := bauds.CommaText;
  cboBaudRate.ItemIndex := 0 ;
end;

procedure TFrmPlotter.updateSerial;
begin
 cboPortas.Items.CommaText := GetSerialPortNames;
 cboPortas.ItemIndex := 0 ;
end;

end.

