unit TestIdSipDialog;

interface

uses
  IdSipDialog, IdSipHeaders, IdSipMessage, IdURI, TestFramework, TestFrameworkSip;

type
  TestTIdSipDialogID = class(TTestCase)
  private
    ID: TIdSipDialogID;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestCreationFromParameters;
    procedure TestCreationFromDialogID;
    procedure TestIsEqualToSameID;
    procedure TestIsEqualToDifferentCallID;
    procedure TestIsEqualToDifferentLocalTag;
    procedure TestIsEqualToDifferentRemoteTag;
  end;

  TestTIdSipDialog = class(TTestCaseSip)
  protected
    Dlg:              TIdSipDialog;
    ID:               TIdSipDialogID;
    LocalSequenceNo:  Cardinal;
    LocalUri:         TIdURI;
    RemoteSequenceNo: Cardinal;
    RemoteTarget:     TIdURI;
    RemoteUri:        TIdURI;
    Req:              TIdSipRequest;
    Res:              TIdSipResponse;
    RouteSet:         TIdSipHeaders;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestCreateFromAnotherDialog;
    procedure TestCreateRequest;
    procedure TestCreateRequestRouteSetEmpty;
    procedure TestCreateRequestRouteSetWithLrParam;
    procedure TestCreateRequestRouteSetWithoutLrParam;
    procedure TestCreateWithStrings;
    procedure TestDialogID;
    procedure TestEarlyState;
    procedure TestEmptyRemoteTargetAfterResponse;
    procedure TestIsSecure;
    procedure TestRemoteTarget;
  end;

  TestTIdSipUACDialog = class(TestTIdSipDialog)
  private
    Dlg: TIdSipUACDialog;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestDialogID;
    procedure TestDialogIDToHasNoTag;
    procedure TestRecordRouteHeaders;
    procedure TestSequenceNo;
    procedure TestUri;
  end;

  TestTIdSipDialogs = class(TTestCase)
  private
    D:                TIdSipDialogs;
    Dlg:              TIdSipDialog;
    ID:               TIdSipDialogID;
    LocalSequenceNo:  Cardinal;
    LocalUri:         TIdURI;
    RemoteSequenceNo: Cardinal;
    RemoteTarget:     TIdURI;
    RemoteUri:        TIdURI;
    RouteSet:         TIdSipHeaders;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestAddAndCount;
    procedure TestAddCopiesDialog;
    procedure TestDialogAt;
    procedure TestDialogAtString;
    procedure TestDialogAtStringUnknownID;
    procedure TestDialogAtUnknownID;
  end;

implementation

uses
  Classes, IdSipConsts, SysUtils, TestMessages, TypInfo;

function DialogStateToStr(const S: TIdSipDialogState): String;
begin
  Result := GetEnumName(TypeInfo(TIdSipDialogState), Integer(S));
end;

function Suite: ITestSuite;
begin
  Result := TTestSuite.Create('IdSipDialog unit tests');
  Result.AddTest(TestTIdSipDialogID.Suite);
  Result.AddTest(TestTIdSipDialog.Suite);
  Result.AddTest(TestTIdSipUACDialog.Suite);
  Result.AddTest(TestTIdSipDialogs.Suite);
end;

//******************************************************************************
//* TestTIdSipDialogID                                                         *
//******************************************************************************
//* TestTIdSipDialogID Public methods ******************************************

procedure TestTIdSipDialogID.SetUp;
begin
  inherited SetUp;

  Self.ID := TIdSipDialogID.Create('1', '2', '3');
end;

procedure TestTIdSipDialogID.TearDown;
begin
  Self.ID.Free;

  inherited TearDown;
end;

//* TestTIdSipDialogID Private methods *****************************************

//* TestTIdSipDialogID Published methods ***************************************

procedure TestTIdSipDialogID.TestCreationFromParameters;
begin
  CheckEquals('1', Self.ID.CallID,    'CallID');
  CheckEquals('2', Self.ID.LocalTag,  'LocalTag');
  CheckEquals('3', Self.ID.RemoteTag, 'RemoteTag');
end;

procedure TestTIdSipDialogID.TestCreationFromDialogID;
var
  Dlg:    TIdSipDialogID;
begin
  Dlg := TIdSipDialogID.Create(Self.ID);
  try
    Check(Dlg.IsEqualTo(Self.ID), 'Dialog IDs not equal');
  finally
    Dlg.Free;
  end;
end;

procedure TestTIdSipDialogID.TestIsEqualToSameID;
var
  D: TIdSipDialogID;
begin
  D := TIdSipDialogID.Create(Self.ID);
  try
    Check(D.IsEqualTo(Self.ID), 'Same Dialog ID');
  finally
    D.Free;
  end;
end;

procedure TestTIdSipDialogID.TestIsEqualToDifferentCallID;
var
  D: TIdSipDialogID;
begin
  D := TIdSipDialogID.Create(Self.ID.CallID + '1',
                             Self.ID.LocalTag,
                             Self.ID.RemoteTag);
  try
    Check(not D.IsEqualTo(Self.ID), 'Different Call-ID');
  finally
    D.Free;
  end;
end;

procedure TestTIdSipDialogID.TestIsEqualToDifferentLocalTag;
var
  D: TIdSipDialogID;
begin
  D := TIdSipDialogID.Create(Self.ID.CallID,
                             Self.ID.LocalTag + '1',
                             Self.ID.RemoteTag);
  try
    Check(not D.IsEqualTo(Self.ID), 'Different Local Tag');
  finally
    D.Free;
  end;
end;

procedure TestTIdSipDialogID.TestIsEqualToDifferentRemoteTag;
var
  D: TIdSipDialogID;
begin
  D := TIdSipDialogID.Create(Self.ID.CallID,
                             Self.ID.LocalTag,
                             Self.ID.RemoteTag + '1');
  try
    Check(not D.IsEqualTo(Self.ID), 'Different Remote Tag');
  finally
    D.Free;
  end;
end;

//******************************************************************************
//* TestTIdSipDialog                                                           *
//******************************************************************************
//* TestTIdSipDialog Public methods ********************************************

procedure TestTIdSipDialog.SetUp;
var
  P: TIdSipParser;
begin
  inherited SetUp;

  P := TIdSipParser.Create;
  try
    Self.Req := P.ParseAndMakeRequest(BasicRequest);

    Self.Res := P.ParseAndMakeResponse(BasicResponse);
    Self.Res.StatusCode := SIPTrying;
  finally
    P.Free;
  end;

  Self.ID := TIdSipDialogID.Create('1', '2', '3');

  Self.LocalSequenceNo := 13;
  Self.LocalUri        := TIdUri.Create('sip:case@fried.neurons.org');
  Self.LocalSequenceNo := 42;
  Self.RemoteTarget    := TIdUri.Create('sip:sip-proxy1.tessier-ashpool.co.lu');
  Self.RemoteUri       := TIdUri.Create('sip:wintermute@tessier-ashpool.co.lu');

  Self.RouteSet := TIdSipHeaders.Create;
  Self.RouteSet.Add(RecordRouteHeader).Value := '<sip:127.0.0.1>';
  Self.RouteSet.Add(RecordRouteHeader).Value := '<sip:127.0.0.1:6000>';
  Self.RouteSet.Add(RecordRouteHeader).Value := '<sip:127.0.0.1:8000>';

  Self.Dlg := TIdSipDialog.Create(Self.ID,
                                  Self.LocalSequenceNo,
                                  Self.RemoteSequenceNo,
                                  Self.LocalUri,
                                  Self.RemoteUri,
                                  Self.RemoteTarget,
                                  false,
                                  Self.RouteSet);
end;

procedure TestTIdSipDialog.TearDown;
begin
  Self.Dlg.Free;
  Self.RouteSet.Free;
  Self.RemoteTarget.Free;
  Self.RemoteUri.Free;
  Self.LocalUri.Free;
  Self.ID.Free;
  Self.Res.Free;
  Self.Req.Free;

  inherited TearDown;
end;

//* TestTIdSipDialog Published methods *****************************************

procedure TestTIdSipDialog.TestCreateFromAnotherDialog;
var
  D: TIdSipDialog;
begin
  D := TIdSipDialog.Create(Self.Dlg);
  try
    Check(Self.Dlg.ID.IsEqualTo(D.ID),
          'ID');
    CheckEquals(Self.Dlg.LocalSequenceNo,
                D.LocalSequenceNo,
                'LocalSequenceNo');
    CheckEquals(Self.Dlg.RemoteSequenceNo,
                D.RemoteSequenceNo,
                'RemoteSequenceNo');
    CheckEquals(Self.Dlg.LocalUri,
                D.LocalUri,
                'LocalUri');
    CheckEquals(Self.Dlg.RemoteUri,
                D.RemoteUri,
                'RemoteUri');
    CheckEquals(Self.Dlg.RemoteTarget,
                D.RemoteTarget,
                'RemoteTarget');
    Check(Self.Dlg.IsSecure = D.IsSecure,
          'IsSecure');
    Check(Self.Dlg.RouteSet.IsEqualTo(D.RouteSet),
          'RouteSet');
  finally
    D.Free;
  end;
end;

procedure TestTIdSipDialog.TestCreateRequest;
var
  R: TIdSipRequest;
begin
  R := Self.Dlg.CreateRequest;
  try
    CheckEquals(Self.Dlg.RemoteURI,    R.ToHeader.Address, 'To URI');
    CheckEquals(Self.Dlg.ID.RemoteTag, R.ToHeader.Tag,     'To tag');
    CheckEquals(Self.Dlg.LocalURI,     R.From.Address,     'From URI');
    CheckEquals(Self.Dlg.ID.LocalTag,  R.From.Tag,         'From tag');
    CheckEquals(Self.Dlg.ID.CallID,    R.CallID,           'Call-ID');

    // we should somehow check that CSeq.SequenceNo has been (randomly) generated. How?
  finally
    R.Free;
  end;
end;

procedure TestTIdSipDialog.TestCreateRequestRouteSetEmpty;
var
  R:      TIdSipRequest;
  Routes: TIdSipHeadersFilter;
begin
  Self.Res.StatusCode := SIPTrying;
  Self.Dlg.HandleMessage(Self.Res);

  Self.Dlg.RouteSet.Clear;

  R := Self.Dlg.CreateRequest;
  try
    CheckEquals(Self.Dlg.RemoteTarget,
                R.RequestUri,
                'Request-URI');

    Routes := TIdSipHeadersFilter.Create(R.Headers, RouteHeader);
    try
      Check(Routes.IsEmpty, 'Route headers are present');
    finally
      Routes.Free;
    end;
  finally
    R.Free;
  end;
end;

procedure TestTIdSipDialog.TestCreateRequestRouteSetWithLrParam;
var
  R:      TIdSipRequest;
  Routes: TIdSipHeadersFilter;
begin
  Self.Dlg.RouteSet.Clear;
  Self.Dlg.RouteSet.Add(RecordRouteHeader).Value := '<sip:server10.biloxi.com;lr>';
  Self.Dlg.RouteSet.Add(RecordRouteHeader).Value := '<sip:server9.biloxi.com>';
  Self.Dlg.RouteSet.Add(RecordRouteHeader).Value := '<sip:server8.biloxi.com;lr>';

  R := Self.Dlg.CreateRequest;
  try
    CheckEquals(Self.Dlg.RemoteTarget,
                R.RequestUri,
                'Request-URI');

    Routes := TIdSipHeadersFilter.Create(R.Headers, RecordRouteHeader);
    try
      Check(Routes.IsEqualTo(Self.Dlg.RouteSet),
            'Record-Route headers not set to the Dialog route set');
    finally
      Routes.Free;
    end;
  finally
    R.Free;
  end;
end;

procedure TestTIdSipDialog.TestCreateRequestRouteSetWithoutLrParam;
var
  I:      Integer;
  R:      TIdSipRequest;
  Routes: TIdSipHeadersFilter;
begin
  Self.Res.StatusCode := SIPTrying;
  Self.Dlg.HandleMessage(Self.Res);

  R := Self.Dlg.CreateRequest;
  try
    CheckEquals((Self.Dlg.RouteSet.Items[0] as TIdSipRouteHeader).Address,
                R.RequestUri,
                'Request-URI');

    Routes := TIdSipHeadersFilter.Create(R.Headers, RouteHeader);
    try
      // These are the manipulations the dialog's meant to perform on its route
      // set. Just so you know we're not fiddling our test data.
      Self.Dlg.RouteSet.Delete(0);
      Self.Dlg.RouteSet.Add(RouteHeader).Value := '<' + Self.Dlg.RemoteURI.GetFullURI + '>';

      for I := 0 to Routes.Count - 1 do 
        CheckEquals(Self.Dlg.RouteSet.Items[I].Value,
                    Routes.Items[I].Value,
                    'Route ' + IntToStr(I + 1) + ' value');
    finally
      Routes.Free;
    end;
  finally
    R.Free;
  end;
end;

procedure TestTIdSipDialog.TestCreateWithStrings;
var
  D: TIdSipDialog;
begin
  D := TIdSipDialog.Create(Self.ID,
                           Self.LocalSequenceNo,
                           Self.RemoteSequenceNo,
                           Self.LocalURI,
                           Self.RemoteURI,
                           Self.RemoteTarget,
                           false,
                           Self.RouteSet);
  try
    CheckEquals(Self.LocalUri,
                D.LocalURI,
                'LocalURI');
    CheckEquals(Self.RemoteUri,
                D.RemoteURI,
                'RemoteURI');
    CheckEquals(Self.RemoteTarget,
                D.RemoteTarget,
                'RemoteTarget');
  finally
    D.Free;
  end;
end;

procedure TestTIdSipDialog.TestDialogID;
begin
  Check(Self.Dlg.ID.IsEqualTo(Self.ID), 'Dialog ID not set');
  CheckEquals(Self.LocalSequenceNo,
              Self.Dlg.LocalSequenceNo,
              'Local Sequence number not set');
  CheckEquals(Self.RemoteSequenceNo,
              Self.Dlg.RemoteSequenceNo,
              'Remote Sequence number not set');
  CheckEquals(Self.LocalUri,
              Self.Dlg.LocalUri,
              'Local URI not set');
  CheckEquals(Self.RemoteUri,
              Self.Dlg.RemoteUri,
              'Remote URI not set');
  CheckEquals(Self.RemoteTarget,
              Self.Dlg.RemoteTarget,
              'Remote Target not set');
  Check(not Self.Dlg.IsSecure, 'IsSecure not set');
  Check(Self.Dlg.RouteSet.IsEqualTo(Self.RouteSet), 'Route set not set');
end;

procedure TestTIdSipDialog.TestEarlyState;
begin
  Check(not Self.Dlg.IsEarly,
        'Before any response is received');

  Self.Res.StatusCode := SIPTrying;
  Self.Dlg.HandleMessage(Self.Res);
  Check(Self.Dlg.IsEarly,
        'Received provisional Response: ' + IntToStr(Self.Res.StatusCode));

  Self.Res.StatusCode := SIPOK;
  Self.Dlg.HandleMessage(Self.Res);
  Check(not Self.Dlg.IsEarly,
        'Received final Response: ' + IntToStr(Self.Res.StatusCode));
end;

procedure TestTIdSipDialog.TestEmptyRemoteTargetAfterResponse;
var
  D:        TIdSipDialog;
  EmptyUri: TIdUri;
begin
  EmptyUri := TIdUri.Create('');
  try
    D := TIdSipDialog.Create(Self.ID,
                             Self.LocalSequenceNo,
                             Self.RemoteSequenceNo,
                             Self.LocalUri,
                             Self.RemoteUri,
                             EmptyUri,
                             false,
                             Self.RouteSet);
    try
      D.HandleMessage(Self.Res);
      CheckEquals((Self.Res.Headers[ContactHeaderFull] as TIdSipContactHeader).Address,
                  D.RemoteTarget,
                  'RemoteTarget after response received');
    finally
      D.Free;
    end;
  finally
    EmptyUri.Free;
  end;
end;

procedure TestTIdSipDialog.TestIsSecure;
var
  D: TIdSipDialog;
begin
  Self.Req.RequestUri.URI := 'sip:wintermute@tessier-ashpool.co.lu';
  D := TIdSipDialog.Create(Self.Req, false);
  try
    Check(not D.IsSecure, 'SIP Request-URI, not received over TLS');
  finally
    D.Free;
  end;

  Self.Req.RequestUri.URI := 'sip:wintermute@tessier-ashpool.co.lu';
  D := TIdSipDialog.Create(Self.Req, true);
  try
    Check(not D.IsSecure, 'SIP Request-URI, received over TLS');
  finally
    D.Free;
  end;

  Self.Req.RequestUri.URI := 'sips:wintermute@tessier-ashpool.co.lu';
  D := TIdSipDialog.Create(Self.Req, false);
  try
    Check(not D.IsSecure, 'SIPS Request-URI, not received over TLS');
  finally
    D.Free;
  end;

  Self.Req.RequestUri.URI := 'sips:wintermute@tessier-ashpool.co.lu';
  D := TIdSipDialog.Create(Self.Req, true);
  try
    Check(D.IsSecure, 'SIPS Request-URI, received over TLS');
  finally
    D.Free;
  end;
end;

procedure TestTIdSipDialog.TestRemoteTarget;
begin
  CheckEquals(Self.RemoteTarget,
              Self.Dlg.RemoteTarget,
              'RemoteTarget before response received');
end;

//******************************************************************************
//* TestTIdSipUACDialog                                                        *
//******************************************************************************
//* TestTIdSipUACDialog Public methods *****************************************

procedure TestTIdSipUACDialog.SetUp;
begin
  inherited SetUp;
  Self.Dlg.Free;

  Self.Dlg := TIdSipUACDialog.Create(Self.Req, false);
end;

procedure TestTIdSipUACDialog.TearDown;
begin
  Self.Dlg.Free;

  inherited TearDown;
end;

//* TestTIdSipUACDialog Published methods **************************************

procedure TestTIdSipUACDialog.TestDialogID;
begin
  CheckEquals(Self.Req.CallID,       Self.Dlg.ID.CallID,    'CallID');
  CheckEquals(Self.Req.From.Tag,     Self.Dlg.ID.LocalTag,  'LocalTag');
  CheckEquals(Self.Req.ToHeader.Tag, Self.Dlg.ID.RemoteTag, 'RemoteTag');
end;

procedure TestTIdSipUACDialog.TestDialogIDToHasNoTag;
var
  D: TIdSipUACDialog;
begin
  Self.Req.ToHeader.Value := 'Case <sip:case@fried.neurons.org>';
  D := TIdSipUACDialog.Create(Self.Req, false);
  try
    CheckEquals('', D.ID.RemoteTag, 'LocalTag value with no To tag');
  finally
    D.Free;
  end;
end;

procedure TestTIdSipUACDialog.TestRecordRouteHeaders;
var
  D: TIdSipUACDialog;
begin
  Self.Req.AddHeader(RecordRouteHeader).Value := '<sip:127.0.0.1:5000;foo>';
  Self.Req.AddHeader(RecordRouteHeader).Value := '<sip:127.0.0.1:5001>';
  Self.Req.AddHeader(RecordRouteHeader).Value := '<sip:127.0.0.1:5002>';

  D := TIdSipUACDialog.Create(Self.Req, false);
  try
    CheckEquals(3, D.RouteSet.Count, 'Incorrect number of Record-Route headers');
    CheckEquals('<sip:127.0.0.1:5002>',     D.RouteSet.Items[0].Value, '1st Record-Route header');
    CheckEquals('<sip:127.0.0.1:5001>',     D.RouteSet.Items[1].Value, '2nd Record-Route header');
    CheckEquals('<sip:127.0.0.1:5000;foo>', D.RouteSet.Items[2].Value, '3rd Record-Route header');
  finally
    D.Free;
  end;
end;

procedure TestTIdSipUACDialog.TestSequenceNo;
begin
  CheckEquals(Self.Req.CSeq.SequenceNo, Self.Dlg.LocalSequenceNo,  'LocalSequenceNo');
  CheckEquals(0,                        Self.Dlg.RemoteSequenceNo, 'RemoteSequenceNo');

  Self.Res.StatusCode := SIPTrying;
  Self.Dlg.HandleMessage(Self.Res);
  CheckEquals(Self.Res.CSeq.SequenceNo,
              Self.Dlg.RemoteSequenceNo,
              'RemoteSequenceNo after receiving a response');
end;

procedure TestTIdSipUACDialog.TestUri;
begin
  CheckEquals(Self.Req.From.Address,
              Self.Dlg.LocalURI,
              'LocalUri');

  CheckEquals(Self.Req.ToHeader.Address,
              Self.Dlg.RemoteURI,
              'RemoteUri');
end;

//******************************************************************************
//* TestTIdSipDialogs                                                          *
//******************************************************************************
//* TestTIdSipDialogs Public methods *******************************************

procedure TestTIdSipDialogs.SetUp;
begin
  inherited SetUp;

  Self.D := TIdSipDialogs.Create;

  Self.ID := TIdSipDialogID.Create('1', '2', '3');

  Self.LocalSequenceNo := 13;
  Self.LocalUri        := TIdUri.Create('sip:case@fried.neurons.org');
  Self.LocalSequenceNo := 42;
  Self.RemoteTarget    := TIdUri.Create('sip:sip-proxy1.tessier-ashpool.co.lu');
  Self.RemoteUri       := TIdUri.Create('sip:wintermute@tessier-ashpool.co.lu');

  Self.RouteSet := TIdSipHeaders.Create;
  Self.RouteSet.Add(RecordRouteHeader).Value := '<sip:127.0.0.1>';
  Self.RouteSet.Add(RecordRouteHeader).Value := '<sip:127.0.0.1:6000>';
  Self.RouteSet.Add(RecordRouteHeader).Value := '<sip:127.0.0.1:8000>';

  Self.Dlg := TIdSipDialog.Create(Self.ID,
                                  Self.LocalSequenceNo,
                                  Self.RemoteSequenceNo,
                                  Self.LocalUri,
                                  Self.RemoteUri,
                                  Self.RemoteTarget,
                                  false,
                                  Self.RouteSet);
end;

procedure TestTIdSipDialogs.TearDown;
begin
  Self.Dlg.Free;
  Self.RouteSet.Free;
  Self.RemoteTarget.Free;
  Self.RemoteUri.Free;
  Self.LocalUri.Free;
  Self.ID.Free;
  Self.D.Free;

  inherited TearDown;
end;

//* TestTIdSipDialogs Published methods ****************************************

procedure TestTIdSipDialogs.TestAddAndCount;
var
  Dlg:           TIdSipDialog;
  ID:            TIdSipDialogID;
  OriginalCount: Integer;
  RouteSet:      TIdSipHeaders;
begin
  OriginalCount := Self.D.Count;

  ID := TIdSipDialogID.Create('1', '2', '3');
  try
    RouteSet := TIdSipHeaders.Create;
    try
      Dlg := TIdSipDialog.Create(ID,
                                 1,
                                 2,
                                 'sip:localhost',
                                 'sip:remote.org',
                                 'sips:target.remote.net',
                                 false,
                                 RouteSet);
      try
        Self.D.Add(Dlg);
        CheckEquals(OriginalCount + 1, Self.D.Count, 'After one Add');
      finally
        Dlg.Free;
      end;
    finally
      RouteSet.Free;
    end;
  finally
    ID.Free;
  end;
end;

procedure TestTIdSipDialogs.TestAddCopiesDialog;
var
  Dlg:      TIdSipDialog;
  ID:       TIdSipDialogID;
  RouteSet: TIdSipHeaders;
begin
  ID := TIdSipDialogID.Create('1', '2', '3');
  try
    RouteSet := TIdSipHeaders.Create;
    try
      Dlg := TIdSipDialog.Create(ID,
                                 1,
                                 2,
                                 'sip:localhost',
                                 'sip:remote.org',
                                 'sips:target.remote.net',
                                 false,
                                 RouteSet);
      try
        Self.D.Add(Dlg);
      finally
        Dlg.Free;
      end;

      // This is a sneaky test - we're implicitly testing that the list
      // COPIED Dlg. If a reference to Dlg was stored then this would
      // access violate because we'd have a dangling pointer.
      Check(ID.IsEqualTo(Self.D.Items[0].ID), 'IDs not equal');
    finally
      RouteSet.Free;
    end;
  finally
    ID.Free;
  end;
end;

procedure TestTIdSipDialogs.TestDialogAt;
var
  ID2:  TIdSipDialogID;
  Dlg2: TIdSipDialog;
begin
  ID2 := TIdSipDialogID.Create('a', 'b', 'c');
  try
    Dlg2 := TIdSipDialog.Create(ID2, Self.LocalSequenceNo, Self.RemoteSequenceNo, Self.LocalUri, Self.RemoteUri, Self.RemoteTarget, false, Self.RouteSet);
    try
      Self.D.Add(Dlg);
      Self.D.Add(Dlg2);

      Check(Dlg.ID.IsEqualTo(Self.D.DialogAt(Self.ID).ID), 'Returned dialog is not Dlg');
      Check(Dlg2.ID.IsEqualTo(Self.D.DialogAt(ID2).ID),    'Returned dialog is not Dlg2');
    finally
      Dlg2.Free;
    end;
  finally
    ID2.Free;
  end;
end;

procedure TestTIdSipDialogs.TestDialogAtString;
var
  ID2:  TIdSipDialogID;
  Dlg2: TIdSipDialog;
begin
  ID2 := TIdSipDialogID.Create('a', 'b', 'c');
  try
    Dlg2 := TIdSipDialog.Create(ID2, Self.LocalSequenceNo, Self.RemoteSequenceNo, Self.LocalUri, Self.RemoteUri, Self.RemoteTarget, false, Self.RouteSet);
    try
      Self.D.Add(Dlg);
      Self.D.Add(Dlg2);

      Check(Dlg.ID.IsEqualTo(Self.D.DialogAt(Self.ID.CallID, Self.ID.LocalTag, Self.ID.RemoteTag).ID),
            'Returned dialog is not Dlg');
      Check(Dlg2.ID.IsEqualTo(Self.D.DialogAt(ID2.CallID, ID2.LocalTag, ID2.RemoteTag).ID),
            'Returned dialog is not Dlg2');
    finally
      Dlg2.Free;
    end;
  finally
    ID2.Free;
  end;
end;

procedure TestTIdSipDialogs.TestDialogAtStringUnknownID;
begin
  Check(Self.D.DialogAt(Self.ID.CallID + 'a',
                        Self.ID.CallID + 'b',
                        Self.ID.CallID + 'c').IsNull,
        'Null Dialog not returned');
end;

procedure TestTIdSipDialogs.TestDialogAtUnknownID;
var
  ID2:  TIdSipDialogID;
begin
  ID2 := TIdSipDialogID.Create(Self.ID.CallID + 'a',
                               Self.ID.CallID + 'b',
                               Self.ID.CallID + 'c');
  try
    Check(Self.D.DialogAt(ID2).IsNull, 'Null Dialog not returned');
  finally
    ID2.Free;
  end;
end;

initialization
  RegisterTest('Dialog', Suite);
end.
