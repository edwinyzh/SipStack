program SipClientSpike;

uses
  Forms,
  SpikeClient in 'test\SpikeClient.pas' {Form1},
  IdSipUdpServer in 'src\IdSipUdpServer.pas',
  IdSimpleParser in 'src\IdSimpleParser.pas',
  IdSipConsts in 'src\IdSipConsts.pas',
  IdSipCore in 'src\IdSipCore.pas',
  IdSipDialog in 'src\IdSipDialog.pas',
  IdSipHeaders in 'src\IdSipHeaders.pas',
  IdSipMessage in 'src\IdSipMessage.pas',
  IdSipRandom in 'src\IdSipRandom.pas',
  IdSipTcpClient in 'src\IdSipTcpClient.pas',
  IdSipTcpServer in 'src\IdSipTcpServer.pas',
  IdSipTimer in 'src\IdSipTimer.pas',
  IdSipTransaction in 'src\IdSipTransaction.pas',
  IdSipTransport in 'src\IdSipTransport.pas',
  IdSdpParser in 'src\IdSdpParser.pas',
  IdSipTlsServer in '\\Ictfilesrv\ICT Group\FrankS\Projects\SIP\src\IdSipTlsServer.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
