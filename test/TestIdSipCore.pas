unit TestIdSipCore;

interface

uses
  Classes, IdRTP, IdSdp, IdSimpleParser, IdSipCore, IdSipDialog,
  IdSipDialogID, IdSipHeaders, IdSipMessage, IdSipMockCore,
  IdSipMockTransactionDispatcher, IdSipTransaction, IdSipTransport,
  IdSocketHandle, TestFramework, TestFrameworkSip;

type
  TestTIdSipAbstractCore = class(TTestCase)
  private
    Core: TIdSipAbstractCore;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestNextCallID;
  end;

  TTestCaseTU = class(TTestCaseSip)
  private
    procedure RemoveBody(Msg: TIdSipMessage);
  protected
    Core:        TIdSipUserAgentCore;
    Destination: TIdSipToHeader;
    Dispatch:    TIdSipMockTransactionDispatcher;
    Invite:      TIdSipRequest;
    Session:     TIdSipSession;

    function  CreateRemoteBye(const LocalDialog: TIdSipDialog): TIdSipRequest;
    procedure SimulateRemoteInvite;
    procedure SimulateRemoteBye(const LocalDialog: TIdSipDialog);
  public
    procedure SetUp; override;
    procedure TearDown; override;
  end;

  TestTIdSipUserAgentCore = class(TTestCaseTU,
                                  IIdSipSessionListener)
  private
    CheckOnNewSession:         TIdSipSessionEvent;
    Dlg:                       TIdSipDialog;
    ID:                        TIdSipDialogID;
    LocalSequenceNo:           Cardinal;
    LocalUri:                  TIdSipURI;
    OnEndedSessionFired:       Boolean;
    OnEstablishedSessionFired: Boolean;
    OnNewSessionFired:         Boolean;
    RemoteSequenceNo:          Cardinal;
    RemoteTarget:              TIdSipURI;
    RemoteUri:                 TIdSipURI;
    RouteSet:                  TIdSipHeaders;

    procedure CheckCreateRequest(const Dest: TIdSipToHeader; const Request: TIdSipRequest);
    procedure OnEndedSession(const Session: TIdSipSession);
    procedure OnEstablishedSession(const Session: TIdSipSession);
    procedure OnModifiedSession(const Session: TIdSipSession;
                                const Invite: TIdSipRequest);
    procedure OnNewSession(const Session: TIdSipSession);
    procedure SimulateRemoteAck(const Response: TIdSipResponse);
    procedure SimulateRemoteBye(const Dialog: TIdSipDialog);
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestAddAllowedContentType;
    procedure TestAddAllowedContentTypeMalformed;
    procedure TestAddAllowedLanguage;
    procedure TestAddAllowedLanguageLanguageAlreadyPresent;
    procedure TestAddAllowedMethod;
    procedure TestAddAllowedMethodMethodAlreadyPresent;
    procedure TestAddAllowedScheme;
    procedure TestAddAllowedSchemeSchemeAlreadyPresent;
    procedure TestAddObserver;
    procedure TestAddSessionListener;
    procedure TestContentTypeDefault;
    procedure TestCreateBye;
    procedure TestCreateInvite;
    procedure TestCreateInviteWithBody;
    procedure TestCreateRequest;
    procedure TestCreateRequestInDialog;
    procedure TestCreateRequestInDialogRouteSetEmpty;
    procedure TestCreateRequestInDialogRouteSetWithLrParam;
    procedure TestCreateRequestInDialogRouteSetWithoutLrParam;
    procedure TestCreateRequestInDialogTopRouteHasForbiddenParameters;
    procedure TestCreateRequestSipsRequestUri;
    procedure TestCreateRequestUserAgent;
    procedure TestCreateRequestWithTransport;
    procedure TestCreateResponse;
    procedure TestCreateResponseRecordRoute;
    procedure TestCreateResponseSipsRecordRoute;
    procedure TestCreateResponseSipsRequestUri;
    procedure TestCreateResponseToTagMissing;
    procedure TestCreateResponseTryingWithTimestamps;
    procedure TestCreateResponseUserAgent;
    procedure TestCreateResponseUserAgentBlank;
    procedure TestDialogLocalSequenceNoMonotonicallyIncreases;
    procedure TestDispatchToCorrectSession;
    procedure TestDispatchAckToSession;
    procedure TestHasUnknownContentEncoding;
    procedure TestHasUnknownContentType;
    procedure TestIsMethodAllowed;
    procedure TestIsSchemeAllowed;
    procedure TestLoopDetection;
    procedure TestNextTag;
    procedure TestNotificationOfNewSession;
    procedure TestReceiveByeForUnmatchedDialog;
    procedure TestReceiveByeForDialog;
    procedure TestReceiveByeWithoutTags;
    procedure TestRemoveObserver;
    procedure TestRemoveSession;
    procedure TestRemoveSessionListener;
    procedure TestRejectNoContact;
    procedure TestRejectUnknownContentEncoding;
    procedure TestRejectUnknownContentLanguage;
    procedure TestRejectUnknownContentType;
    procedure TestRejectUnknownExtension;
    procedure TestRejectUnknownScheme;
    procedure TestRejectUnsupportedMethod;
    procedure TestRejectUnsupportedSipVersion;
    procedure TestSetContact;
    procedure TestSetContactMailto;
    procedure TestSetContactWildCard;
    procedure TestSetFrom;
    procedure TestSetFromMailto;
    procedure TestHangUpAllCalls;
  end;

  TestTIdSipSession = class(TTestCaseTU,
                            IIdRTPDataListener,
                            IIdSipSessionListener,
                            IIdSipTransportSendingListener)
  private
    EstablishedSession:     TIdSipSession;
    MultiStreamSdp:         TIdSdpPayload;
    OnEndedSessionFired:    Boolean;
    OnModifiedSessionFired: Boolean;
    SentRequestTerminated:  Boolean;
    SimpleSdp:              TIdSdpPayload;

    procedure CheckServerActiveOn(Port: Cardinal);
    function  CreateRemoteReInvite(const LocalDialog: TIdSipDialog): TIdSipRequest;
    function  CreateMultiStreamSdp: TIdSdpPayload;
    function  CreateSimpleSdp: TIdSdpPayload;
    procedure OnEndedSession(const Session: TIdSipSession);
    procedure OnEstablishedSession(const Session: TIdSipSession);
    procedure OnModifiedSession(const Session: TIdSipSession;
                                const Invite: TIdSipRequest);
    procedure OnNewData(Data: TIdRTPPayload;
                        Binding: TIdSocketHandle);
    procedure OnNewSession(const Session: TIdSipSession);
    procedure OnSendRequest(const Request: TIdSipRequest;
                            const Transport: TIdSipTransport);
    procedure OnSendResponse(const Response: TIdSipResponse;
                             const Transport: TIdSipTransport);
    procedure SimulateRemoteAccept(const Invite: TIdSipRequest);
    procedure SimulateRemoteRinging(const Invite: TIdSipRequest);
    procedure SimulateRemoteTryingWithNoToTag(const Invite: TIdSipRequest);
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test2xxRetransmission;
    procedure TestAcceptCall;
    procedure TestAcceptCallWithUnfulfillableOffer;
    procedure TestAcceptCallRespectsContentType;
    procedure TestAcceptCallStartsListeningMedia;
    procedure TestAddSessionListener;
    procedure TestCall;
    procedure TestCallTwice;
    procedure TestCallRemoteRefusal;
    procedure TestCallNetworkFailure;
    procedure TestCallSecure;
    procedure TestCallSipsUriOverTcp;
    procedure TestCallSipUriOverTls;
    procedure TestCreateAck;
    procedure TestCreateCancel;
    procedure TestCreateCancelANonInviteRequest;
    procedure TestCreateCancelWithProxyRequire;
    procedure TestCreateCancelWithRequire;
    procedure TestCreateCancelWithRoute;
    procedure TestDialogNotEstablishedOnTryingResponse;
    procedure TestReceive2xxSendsAck;
    procedure TestReceiveBye;
//    procedure TestReceiveByeWithPendingRequests;
    procedure TestReceiveOutOfOrderRequest;
    procedure TestReceiveReInvite;
    procedure TestRemoveSessionListener;
    procedure TestTerminate;
    procedure TestTerminateUnestablishedSession;
  end;

  TestTIdSipSessionTimer = class(TTestCase)
  private
    Session: TIdSipMockSession;
    Timer:   TIdSipSessionTimer;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestFireResendsSessionsLastResponse;
    procedure TestTimerIntervalIncreases;
  end;

const
  DefaultTimeout = 5000;

implementation

uses
  IdException, IdGlobal, IdSipConsts, IdUdpServer, SyncObjs, SysUtils,
  TestMessages, IdSipMockTransport;

function Suite: ITestSuite;
begin
  Result := TTestSuite.Create('IdSipCore unit tests');
  Result.AddTest(TestTIdSipAbstractCore.Suite);
  Result.AddTest(TestTIdSipUserAgentCore.Suite);
  Result.AddTest(TestTIdSipSession.Suite);
end;

//******************************************************************************
//* TestTIdSipAbstractCore                                                     *
//******************************************************************************
//* TestTIdSipAbstractCore Public methods **************************************

// Self.Core is an (almost) abstract base class. We want to test the (static)
// methods that are not abstract, and we want to do this without the compiler
// moaning about something we know to be safe.
{$WARNINGS OFF}
procedure TestTIdSipAbstractCore.SetUp;
begin
  inherited SetUp;

  Self.Core := TIdSipAbstractCore.Create;
end;
{$WARNINGS ON}

procedure TestTIdSipAbstractCore.TearDown;
begin
  Self.Core.Free;

  inherited TearDown;
end;

//* TestTIdSipAbstractCore Published methods ***********************************

procedure TestTIdSipAbstractCore.TestNextCallID;
var
  CallID: String;
begin
  CallID := Self.Core.NextCallID;

  Fetch(CallID, '@');

  CheckEquals(Self.Core.HostName, CallID, 'HostName not used');
end;

//******************************************************************************
//* TTestCaseTU                                                                *
//******************************************************************************
//* TTestCaseTU Public methods *************************************************

procedure TTestCaseTU.SetUp;
var
  P: TIdSipParser;
begin
  inherited SetUp;

  Self.Destination := TIdSipToHeader.Create;
  Self.Destination.Value := 'sip:franks@localhost';

  Self.Dispatch := TIdSipMockTransactionDispatcher.Create;
  Self.Dispatch.Transport.LocalEchoMessages := false;
  Self.Dispatch.Transport.TransportType := sttTCP;

  Self.Core := TIdSipUserAgentCore.Create;
  Self.Core.Dispatcher := Self.Dispatch;

  Self.Core.Contact.Value := 'sip:wintermute@localhost';
  Self.Core.From.Value    := 'sip:wintermute@localhost';

  P := TIdSipParser.Create;
  try
    Self.Invite := P.ParseAndMakeRequest(BasicRequest);
    Self.RemoveBody(Self.Invite);
  finally
    P.Free;
  end;
end;

procedure TTestCaseTU.TearDown;
begin
  Self.Invite.Free;
  Self.Core.Free;
  Self.Dispatch.Free;
  Self.Destination.Free;

  inherited TearDown;
end;

//* TTestCaseTU Protected methods **********************************************

function TTestCaseTU.CreateRemoteBye(const LocalDialog: TIdSipDialog): TIdSipRequest;
var
  Temp: String;
begin
  Result := Self.Core.CreateBye(LocalDialog);
  try
    // Because this BYE actually comes from the network, its from/to headers will
    // be the REVERSE of a locally generated BYE
    Temp                  := Result.ToHeader.FullValue;
    Result.ToHeader.Value := Result.From.FullValue;
    Result.From.Value     := Temp;
  except
    FreeAndNil(Result);

    raise;
  end;
end;

procedure TTestCaseTU.SimulateRemoteInvite;
begin
  Self.Dispatch.Transport.FireOnRequest(Self.Invite);
end;

procedure TTestCaseTU.SimulateRemoteBye(const LocalDialog: TIdSipDialog);
var
  Bye: TIdSipRequest;
begin
  Bye := Self.CreateRemoteBye(LocalDialog);
  try
    Self.Dispatch.Transport.FireOnRequest(Bye);
  finally
    Bye.Free;
  end;
end;

//* TTestCaseTU Private methods ************************************************

procedure TTestCaseTU.RemoveBody(Msg: TIdSipMessage);
begin
  Msg.RemoveAllHeadersNamed(ContentTypeHeaderFull);
  Msg.Body := '';
  Msg.ToHeader.Value := Msg.ToHeader.DisplayName
                               + ' <' + Msg.ToHeader.Address.URI + '>';
  Msg.RemoveAllHeadersNamed(ContentTypeHeaderFull);
  Msg.ContentLength := 0;
end;

//******************************************************************************
//* TestTIdSipUserAgentCore                                                    *
//******************************************************************************
//* TestTIdSipUserAgentCore Public methods *************************************

procedure TestTIdSipUserAgentCore.SetUp;
var
  C: TIdSipContactHeader;
  F: TIdSipFromHeader;
begin
  inherited SetUp;

  Self.Core.AddSessionListener(Self);

  Self.CheckOnNewSession := nil;

  Self.ID := TIdSipDialogID.Create('1', '2', '3');

  Self.LocalSequenceNo := 13;
  Self.LocalUri        := TIdSipURI.Create('sip:case@fried.neurons.org');
  Self.LocalSequenceNo := 42;
  Self.RemoteTarget    := TIdSipURI.Create('sip:sip-proxy1.tessier-ashpool.co.luna');
  Self.RemoteUri       := TIdSipURI.Create('sip:wintermute@tessier-ashpool.co.luna');

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

  C := TIdSipContactHeader.Create;
  try
    C.Value := 'sip:wintermute@tessier-ashpool.co.luna';
    Self.Core.Contact := C;
  finally
    C.Free;
  end;

  F := TIdSipFromHeader.Create;
  try
    F.Value := 'Wintermute <sip:wintermute@tessier-ashpool.co.luna>';
    Self.Core.From := F;
  finally
    F.Free;
  end;

  Self.OnNewSessionFired         := false;
  Self.OnEstablishedSessionFired := false;
end;

procedure TestTIdSipUserAgentCore.TearDown;
begin
  Self.Dlg.Free;
  Self.RouteSet.Free;
  Self.RemoteUri.Free;
  Self.RemoteTarget.Free;
  Self.LocalUri.Free;
  Self.ID.Free;

  inherited TearDown;
end;

//* TestTIdSipUserAgentCore Private methods ************************************

procedure TestTIdSipUserAgentCore.CheckCreateRequest(const Dest: TIdSipToHeader; const Request: TIdSipRequest);
var
  Contact: TIdSipContactHeader;
begin
  CheckEquals(Dest.Address,
              Request.RequestUri,
              'Request-URI not properly set');

  Check(Request.HasHeader(CallIDHeaderFull), 'No Call-ID header added');
  CheckNotEquals('',
                 (Request.FirstHeader(CallIDHeaderFull) as TIdSipCallIdHeader).Value,
                 'Call-ID must not be empty');

  Check(Request.HasHeader(ContactHeaderFull), 'No Contact header added');
  Contact := Request.FirstContact;
  Check(Contact.IsEqualTo(Self.Core.Contact), 'Contact header incorrectly set');

  CheckEquals(Request.From.DisplayName,
              Self.Core.From.DisplayName,
              'From.DisplayName');
  CheckEquals(Request.From.Address,
              Self.Core.From.Address,
              'From.Address');
    Check(Request.From.HasTag,
          'Requests MUST have a From tag; cf. RFC 3261 section 8.1.1.3');

  CheckEquals(Request.RequestUri,
              Request.ToHeader.Address,
              'To header incorrectly set');

  CheckEquals(1,
              Request.Path.Length,
              'New requests MUST have a Via header; cf. RFC 3261 section 8.1.1.7');
  Check(Request.LastHop.HasBranch,
        'New requests MUST have a branch; cf. RFC 3261 section 8.1.1.7');
  Check(sttTCP = Request.LastHop.Transport,
        'TCP should be the default transport');
end;

procedure TestTIdSipUserAgentCore.OnEndedSession(const Session: TIdSipSession);
begin
  Self.OnEndedSessionFired := true;
end;

procedure TestTIdSipUserAgentCore.OnEstablishedSession(const Session: TIdSipSession);
begin
  Self.OnEstablishedSessionFired := true;
end;

procedure TestTIdSipUserAgentCore.OnModifiedSession(const Session: TIdSipSession;
                                                    const Invite: TIdSipRequest);
begin
end;

procedure TestTIdSipUserAgentCore.OnNewSession(const Session: TIdSipSession);
begin
  if Assigned(Self.CheckOnNewSession) then
    Self.CheckOnNewSession(Session);

  Self.OnNewSessionFired := true;

  Self.Session := Session;
end;

procedure TestTIdSipUserAgentCore.SimulateRemoteAck(const Response: TIdSipResponse);
var
  Ack:  TIdSipRequest;
  Temp: String;
begin
  // Precondition: Self.Session has been established
  Check(Assigned(Self.Session),
        'SimulateRemoteAck called but Self.Session is nil');
  Check(Assigned(Self.Session.Dialog),
        'SimulateRemoteAck called but Self.Session''s dialog isn''t '
      + 'established');

  Ack := Self.Session.CreateAck;
  try
    // We have to swop the tags because CreateAck returns a LOCALLY created ACK,
    // so the remote tag is actually the far end's local tag.
    Temp             := Ack.From.Tag;
    Ack.From.Tag     := Ack.ToHeader.Tag;
    Ack.ToHeader.Tag := Temp;

    Self.Dispatch.Transport.FireOnRequest(Ack);
  finally
    Ack.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.SimulateRemoteBye(const Dialog: TIdSipDialog);
var
  Bye: TIdSipRequest;
begin
  Bye := Self.CreateRemoteBye(Dialog);
  try
    Self.Dispatch.Transport.FireOnRequest(Bye);
  finally
    Bye.Free;
  end;
end;

//* TestTIdSipUserAgentCore Published methods **********************************

procedure TestTIdSipUserAgentCore.TestAddAllowedContentType;
var
  ContentTypes: TStrings;
begin
  ContentTypes := TStringList.Create;
  try
    Self.Core.AddAllowedContentType(PlainTextMimeType);

    ContentTypes.CommaText := Self.Core.AllowedContentTypes;

    CheckEquals(2, ContentTypes.Count, 'Number of allowed ContentTypes');

    CheckEquals(SdpMimeType,       ContentTypes[0], SdpMimeType);
    CheckEquals(PlainTextMimeType, ContentTypes[1], PlainTextMimeType);
  finally
    ContentTypes.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestAddAllowedContentTypeMalformed;
var
  ContentTypes: String;
begin
  ContentTypes := Self.Core.AllowedContentTypes;
  Self.Core.AddAllowedContentType(' ');
  CheckEquals(ContentTypes,
              Self.Core.AllowedContentTypes,
              'Malformed Content-Type was allowed');
end;

procedure TestTIdSipUserAgentCore.TestAddAllowedLanguage;
var
  Languages: TStrings;
begin
  Languages := TStringList.Create;
  try
    Self.Core.AddAllowedLanguage('en');
    Self.Core.AddAllowedLanguage('af');

    Languages.CommaText := Self.Core.AllowedLanguages;

    CheckEquals(2, Languages.Count, 'Number of allowed Languages');

    CheckEquals('en', Languages[0], 'en first');
    CheckEquals('af', Languages[1], 'af second');
  finally
    Languages.Free;
  end;

  try
    Self.Core.AddAllowedLanguage(' ');
    Fail('Failed to forbid adding a malformed language ID');
  except
    on EIdException do;
  end;
end;

procedure TestTIdSipUserAgentCore.TestAddAllowedLanguageLanguageAlreadyPresent;
var
  Languages: TStrings;
begin
  Languages := TStringList.Create;
  try
    Self.Core.AddAllowedLanguage('en');
    Self.Core.AddAllowedLanguage('en');

    Languages.CommaText := Self.Core.AllowedLanguages;

    CheckEquals(1, Languages.Count, 'en was re-added');
  finally
    Languages.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestAddAllowedMethod;
var
  Methods: TStrings;
begin
  Methods := TStringList.Create;
  try
    Self.Core.AddAllowedMethod(MethodOptions);

    Methods.CommaText := Self.Core.AllowedMethods;

    CheckEquals(4, Methods.Count, 'Number of allowed methods');

    CheckEquals(MethodBye,     Methods[0], 'BYE first');
    CheckEquals(MethodCancel,  Methods[1], 'CANCEL second');
    CheckEquals(MethodInvite,  Methods[2], 'INVITE third');
    CheckEquals(MethodOptions, Methods[3], 'OPTIONS fourth');
  finally
    Methods.Free;
  end;

  try
    Self.Core.AddAllowedMethod(' ');
    Fail('Failed to forbid adding a non-token Method');
  except
    on EIdException do;
  end;
end;

procedure TestTIdSipUserAgentCore.TestAddAllowedMethodMethodAlreadyPresent;
var
  Methods: TStrings;
  MethodCount: Cardinal;
begin
  Methods := TStringList.Create;
  try
    Methods.CommaText := Self.Core.AllowedMethods;
    MethodCount := Methods.Count;

    Self.Core.AddAllowedMethod(MethodInvite);
    Methods.CommaText := Self.Core.AllowedMethods;

    CheckEquals(MethodCount, Methods.Count, MethodInvite + ' was re-added');
  finally
    Methods.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestAddAllowedScheme;
var
  Schemes: TStrings;
begin
  Schemes := TStringList.Create;
  try
    Self.Core.AddAllowedScheme(SipsScheme);

    Schemes.CommaText := Self.Core.AllowedSchemes;

    CheckEquals(2, Schemes.Count, 'Number of allowed Schemes');

    CheckEquals(SipScheme,  Schemes[0], 'SIP first');
    CheckEquals(SipsScheme, Schemes[1], 'SIPS second');
  finally
    Schemes.Free;
  end;

  try
    Self.Core.AddAllowedScheme(' ');
    Fail('Failed to forbid adding a malformed URI scheme');
  except
    on EIdException do;
  end;
end;

procedure TestTIdSipUserAgentCore.TestAddAllowedSchemeSchemeAlreadyPresent;
var
  Schemes: TStrings;
begin
  Schemes := TStringList.Create;
  try
    Self.Core.AddAllowedScheme(SipScheme);

    Schemes.CommaText := Self.Core.AllowedSchemes;

    CheckEquals(1, Schemes.Count, 'SipScheme was re-added');
  finally
    Schemes.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestAddObserver;
var
  L1, L2: TIdSipTestObserver;
begin
  L1 := TIdSipTestObserver.Create;
  try
    L2 := TIdSipTestObserver.Create;
    try
      Self.Core.AddObserver(L1);
      Self.Core.AddObserver(L2);

      Self.SimulateRemoteInvite;

      Check(L1.Changed and L2.Changed, 'Not all Listeners notified, hence not added');
    finally
      L2.Free;
    end;
  finally
    L1.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestAddSessionListener;
var
  L1, L2: TIdSipTestSessionListener;
begin
  L1 := TIdSipTestSessionListener.Create;
  try
    L2 := TIdSipTestSessionListener.Create;
    try
      Self.Core.AddSessionListener(L1);
      Self.Core.AddSessionListener(L2);

      Self.SimulateRemoteInvite;

      Check(L1.NewSession and L2.NewSession, 'Not all Listeners notified, hence not added');
    finally
      L2.Free;
    end;
  finally
    L1.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestContentTypeDefault;
begin
  CheckEquals(SdpMimeType,
              Self.Core.AllowedContentTypes,
              'AllowedContentTypes');
end;

procedure TestTIdSipUserAgentCore.TestCreateBye;
var
  Bye: TIdSipRequest;
begin
  Bye := Self.Core.CreateBye(Self.Dlg);
  try
    CheckEquals(MethodBye, Bye.Method, 'Unexpected method');
    CheckEquals(Bye.Method,
                Bye.CSeq.Method,
                'CSeq method doesn''t match request method');
  finally
    Bye.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestCreateInvite;
var
  Request: TIdSipRequest;
  Dest:    TIdSipToHeader;
begin
  Dest := TIdSipToHeader.Create;
  try
    Dest.Address.URI := 'sip:wintermute@tessier-ashpool.co.luna';
    Request := Self.Core.CreateInvite(Dest, '', '');
    try
      Self.CheckCreateRequest(Dest, Request);
      CheckEquals(MethodInvite, Request.Method, 'Incorrect method');

      Check(not Request.ToHeader.HasTag,
            'This request is outside of a dialog, hence MUST NOT have a '
          + 'To tag. See RFC:3261, section 8.1.1.2');

      Check(Request.HasHeader(CSeqHeader), 'No CSeq header');
      Check(not Request.HasHeader(ContentDispositionHeader),
            'Needless Content-Disposition header');
    finally
      Request.Free;
    end;
  finally
    Dest.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestCreateInviteWithBody;
var
  Invite: TIdSipRequest;
  Body:   String;
begin
  Body := 'foo fighters';

  Invite := Self.Core.CreateInvite(Self.Destination, Body, 'text/plain');
  try
    CheckEquals(Length(Body), Invite.ContentLength, 'Content-Length');
    CheckEquals(Body,         Invite.Body,          'Body');

    Check(Invite.HasHeader(ContentDispositionHeader),
          'Missing Content-Disposition');
    CheckEquals(DispositionSession,
                Invite.ContentDisposition.Value,
                'Content-Disposition value');      
  finally
    Invite.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestCreateRequest;
var
  Request: TIdSipRequest;
  Dest:    TIdSipToHeader;
begin
  Dest := TIdSipToHeader.Create;
  try
    Dest.Address.URI := 'sip:wintermute@tessier-ashpool.co.luna';
    Request := Self.Core.CreateRequest(Dest);
    try
      Self.CheckCreateRequest(Dest, Request);
    finally
      Request.Free;
    end;
  finally
    Dest.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestCreateRequestInDialog;
var
  R: TIdSipRequest;
begin
  R := Self.Core.CreateRequest(Dlg);
  try
    CheckEquals(Self.Dlg.RemoteURI,    R.ToHeader.Address,   'To URI');
    CheckEquals(Self.Dlg.ID.RemoteTag, R.ToHeader.Tag,       'To tag');
    CheckEquals(Self.Dlg.LocalURI,     R.From.Address,       'From URI');
    CheckEquals(Self.Dlg.ID.LocalTag,  R.From.Tag,           'From tag');
    CheckEquals(Self.Dlg.ID.CallID,    R.CallID,             'Call-ID');

    Check(R.HasHeader(MaxForwardsHeader), 'Max-Forwards header missing');

    // we should somehow check that CSeq.SequenceNo has been (randomly) generated. How?
  finally
    R.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestCreateRequestInDialogRouteSetEmpty;
var
  P:        TIdSipParser;
  R:        TIdSipRequest;
  Response: TIdSipResponse;
  Routes:   TIdSipHeadersFilter;
begin
  P := TIdSipParser.Create;
  try
    Response := P.ParseAndMakeResponse(LocalLoopResponse);
    try
      Response.StatusCode := SIPTrying;
      Self.Dispatch.Transport.FireOnResponse(Response);
    finally
      Response.Free;
    end;
  finally
    P.Free;
  end;

  Self.Dlg.RouteSet.Clear;

  R := Self.Core.CreateRequest(Self.Dlg);
  try
    CheckEquals(Self.Dlg.RemoteTarget, R.RequestUri, 'Request-URI');

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

procedure TestTIdSipUserAgentCore.TestCreateRequestInDialogRouteSetWithLrParam;
var
  R:      TIdSipRequest;
  Routes: TIdSipHeadersFilter;
begin
  Self.Dlg.RouteSet.Clear;
  Self.Dlg.RouteSet.Add(RouteHeader).Value := '<sip:server10.biloxi.com;lr>';
  Self.Dlg.RouteSet.Add(RouteHeader).Value := '<sip:server9.biloxi.com>';
  Self.Dlg.RouteSet.Add(RouteHeader).Value := '<sip:server8.biloxi.com;lr>';

  R := Self.Core.CreateRequest(Dlg);
  try
    CheckEquals(Self.Dlg.RemoteTarget,
                R.RequestUri,
                'Request-URI');

    Routes := TIdSipHeadersFilter.Create(R.Headers, RouteHeader);
    try
      Check(Routes.IsEqualTo(Self.Dlg.RouteSet),
            'Route headers not set to the Dialog route set');
    finally
      Routes.Free;
    end;
  finally
    R.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestCreateRequestInDialogRouteSetWithoutLrParam;
var
  P:        TIdSipParser;
  R:        TIdSipRequest;
  Response: TIdSipResponse;
  Routes:   TIdSipHeadersFilter;
begin
  P := TIdSipParser.Create;
  try
    Response := P.ParseAndMakeResponse(LocalLoopResponse);
    try
      Response.StatusCode := SIPTrying;
      Self.Dispatch.Transport.FireOnResponse(Response);
    finally
      Response.Free;
    end;
  finally
    P.Free;
  end;

  R := Self.Core.CreateRequest(Self.Dlg);
  try
    CheckEquals((Self.Dlg.RouteSet.Items[0] as TIdSipRouteHeader).Address,
                R.RequestUri,
                'Request-URI');

    Routes := TIdSipHeadersFilter.Create(R.Headers, RouteHeader);
    try
      // These are the manipulations the dialog's meant to perform on its route
      // set. Just so you know we're not fiddling our test data.
      Self.Dlg.RouteSet.Delete(0);
      Self.Dlg.RouteSet.Add(RouteHeader).Value := '<' + Self.Dlg.RemoteURI.URI + '>';

      Check(Self.Dlg.RouteSet.IsEqualTo(Routes), 'Routes not added correctly');
    finally
      Routes.Free;
    end;
  finally
    R.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestCreateRequestInDialogTopRouteHasForbiddenParameters;
var
  Request: TIdSipRequest;
begin
  Self.Dlg.RouteSet.Items[0].Value := '<sip:127.0.0.1;transport=tcp;method=REGISTER?Subject=foo>';
  Request := Self.Core.CreateRequest(Self.Dlg);
  try
    CheckEquals('sip:127.0.0.1;transport=tcp',
                Request.RequestUri.Uri, 'Request-URI; SIP section 12.2.1.1');
  finally
    Request.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestCreateRequestSipsRequestUri;
var
  Contact: TIdSipContactHeader;
  Request: TIdSipRequest;
  Dest:    TIdSipToHeader;
begin
  Dest := TIdSipToHeader.Create;
  try
    Dest.Address.URI := 'sips:wintermute@tessier-ashpool.co.luna';
    Request := Self.Core.CreateRequest(Dest);
    try
      Contact := Request.FirstContact;
      CheckEquals(SipsScheme,
                  Contact.Address.Scheme,
                  'Contact doesn''t have a SIPS URI');
    finally
      Request.Free;
    end;
  finally
    Dest.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestCreateRequestUserAgent;
var
  Request: TIdSipRequest;
  Dest:    TIdSipToHeader;
begin
  Self.Core.UserAgentName := 'SATAN/1.0';

  Dest := TIdSipToHeader.Create;
  try
    Dest.Address.URI := 'sip:wintermute@tessier-ashpool.co.luna';
    Request := Self.Core.CreateRequest(Dest);
    try
      CheckEquals(Self.Core.UserAgentName,
                  Request.FirstHeader(UserAgentHeader).Value,
                  'User-Agent header not set');
    finally
      Request.Free;
    end;
  finally
    Dest.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestCreateRequestWithTransport;
var
  Request: TIdSipRequest;
  Dest:    TIdSipToHeader;
begin
  Dest := TIdSipToHeader.Create;
  try
    Dest.Address.URI := 'sip:wintermute@tessier-ashpool.co.luna;transport=udp';
    Request := Self.Core.CreateRequest(Dest);
    try
      Check(Request.LastHop.Transport = sttUDP,
            'UDP transport not specified');
    finally
      Request.Free;
    end;
  finally
    Dest.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestCreateResponse;
var
  FromFilter: TIdSipHeadersFilter;
  Response:   TIdSipResponse;
begin
  Self.Invite.ToHeader.Tag := Self.Core.NextTag;

  Response := Self.Core.CreateResponse(Self.Invite, SIPOK);
  try
    FromFilter := TIdSipHeadersFilter.Create(Response.Headers, FromHeaderFull);
    try
      CheckEquals(1, FromFilter.Count, 'Number of From headers');
    finally
      FromFilter.Free;
    end;

    CheckEquals(SIPOK, Response.StatusCode,          'StatusCode mismatch');
    Check(Response.CSeq.IsEqualTo(Self.Invite.CSeq), 'Cseq header mismatch');
    Check(Response.From.IsEqualTo(Self.Invite.From), 'From header mismatch');
    Check(Response.Path.IsEqualTo(Self.Invite.Path), 'Via headers mismatch');

    Check(Self.Invite.ToHeader.IsEqualTo(Response.ToHeader),
          'To header mismatch');

    Check(Response.HasHeader(ContactHeaderFull), 'Missing Contact header');
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestCreateResponseRecordRoute;
var
  RequestRecordRoutes:  TIdSipHeadersFilter;
  Response:             TIdSipResponse;
  ResponseRecordRoutes: TIdSipHeadersFilter;
begin
  Self.Invite.AddHeader(RecordRouteHeader).Value := '<sip:127.0.0.1:6000>';
  Self.Invite.AddHeader(RecordRouteHeader).Value := '<sip:127.0.0.1:6001>';
  Self.Invite.AddHeader(RecordRouteHeader).Value := '<sip:127.0.0.1:6002>';

  RequestRecordRoutes := TIdSipHeadersFilter.Create(Self.Invite.Headers, RecordRouteHeader);
  try
    Response := Self.Core.CreateResponse(Self.Invite, SIPOK);
    try
      ResponseRecordRoutes := TIdSipHeadersFilter.Create(Response.Headers, RecordRouteHeader);
      try
        Check(ResponseRecordRoutes.IsEqualTo(RequestRecordRoutes),
              'Record-Route header sets mismatch');
      finally
        ResponseRecordRoutes.Free;
      end;
    finally
      Response.Free;
    end;
  finally
    RequestRecordRoutes.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestCreateResponseSipsRecordRoute;
var
  Contact:  TIdSipContactHeader;
  Response: TIdSipResponse;
begin
  Self.Invite.AddHeader(RecordRouteHeader).Value := '<sips:127.0.0.1:6000>';

  Response := Self.Core.CreateResponse(Self.Invite, SIPOK);
  try
    Contact := Response.FirstContact;
    CheckEquals(SipsScheme, Contact.Address.Scheme,
                'Must use a SIPS URI in the Contact');
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestCreateResponseSipsRequestUri;
var
  Contact:  TIdSipContactHeader;
  Response: TIdSipResponse;
begin
  Self.Invite.RequestUri.URI := 'sips:wintermute@tessier-ashpool.co.luna';

  Response := Self.Core.CreateResponse(Self.Invite, SIPOK);
  try
    Contact := Response.FirstContact;
    CheckEquals(SipsScheme, Contact.Address.Scheme,
                'Must use a SIPS URI in the Contact');
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestCreateResponseToTagMissing;
var
  Response: TIdSipResponse;
begin
  // This culls the parameters
  Self.Invite.ToHeader.Value := Self.Invite.ToHeader.Value;

  Response := Self.Core.CreateResponse(Self.Invite, SIPOK);
  try
    Check(Response.ToHeader.HasTag,
          'To is missing a tag');

    CheckEquals(Response.ToHeader.Address,
                Self.Invite.ToHeader.Address,
                'To header address mismatch');
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestCreateResponseTryingWithTimestamps;
var
  Response: TIdSipResponse;
begin
  Self.Invite.AddHeader(TimestampHeader).Value := '1';

  Response := Self.Core.CreateResponse(Self.Invite, SIPTrying);
  try
    Check(Response.HasHeader(TimestampHeader),
          'Timestamp header(s) not copied');
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestCreateResponseUserAgent;
var
  Response: TIdSipResponse;
begin
  Self.Core.UserAgentName := 'SATAN/1.0';
  Self.Invite.RequestUri.URI := 'sip:wintermute@tessier-ashpool.co.luna';

  Response := Self.Core.CreateResponse(Self.Invite, SIPOK);
  try
    CheckEquals(Self.Core.UserAgentName,
                Response.FirstHeader(UserAgentHeader).Value,
                'User-Agent header not set');
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestCreateResponseUserAgentBlank;
var
  Response: TIdSipResponse;
begin
  Self.Core.UserAgentName := '';
  Self.Invite.RequestUri.URI := 'sip:wintermute@tessier-ashpool.co.luna';

  Response := Self.Core.CreateResponse(Self.Invite, SIPOK);
  try
    Check(not Response.HasHeader(UserAgentHeader),
          'User-Agent header not removed because it''s blank');
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestDialogLocalSequenceNoMonotonicallyIncreases;
var
  BaseSeqNo: Cardinal;
  R:         TIdSipRequest;
begin
  R := Self.Core.CreateRequest(Self.Dlg);
  try
     BaseSeqNo := R.CSeq.SequenceNo;
  finally
    R.Free;
  end;

  R := Self.Core.CreateRequest(Self.Dlg);
  try
    CheckEquals(BaseSeqNo + 1,
                R.CSeq.SequenceNo,
                'Not monotonically increasing by one');
  finally
    R.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestDispatchToCorrectSession;
var
  SessionOne: TIdSipSession;
  SessionTwo: TIdSipSession;
begin
  Self.SimulateRemoteInvite;
  Check(Assigned(Self.Session), 'OnNewSession didn''t fire');
  SessionOne := Self.Session;

  Self.Invite.LastHop.Branch := Self.Invite.LastHop.Branch + '1';
  Self.Invite.From.Tag       := Self.Invite.From.Tag + '1';
  Self.Invite.ToHeader.Tag   := Self.Invite.ToHeader.Tag + '1';
  Self.SimulateRemoteInvite;
  Check(Self.Session <> SessionOne, 'OnNewSession didn''t fire');
  SessionTwo := Self.Session;
  CheckEquals(2,
              Self.Core.SessionCount,
              'Number of sessions after two INVITEs');

  SessionTwo.AcceptCall('', '');
  Self.SimulateRemoteBye(SessionTwo.Dialog);
  Check(not SessionOne.IsTerminated, 'SessionOne was terminated');
  Check(    SessionTwo.IsTerminated, 'SessionTwo wasn''t terminated');
end;

procedure TestTIdSipUserAgentCore.TestDispatchAckToSession;
var
  SessionOne: TIdSipSession;
  SessionTwo: TIdSipSession;
begin
  Self.SimulateRemoteInvite;
  Check(Assigned(Self.Session), 'OnNewSession didn''t fire');
  SessionOne := Self.Session;

  Self.Invite.LastHop.Branch := Self.Invite.LastHop.Branch + '1';
  Self.Invite.From.Tag       := Self.Invite.From.Tag + '1';
  Self.Invite.ToHeader.Tag   := Self.Invite.ToHeader.Tag + '1';
  Self.SimulateRemoteInvite;
  Check(Self.Session <> SessionOne, 'OnNewSession didn''t fire');
  SessionTwo := Self.Session;
  CheckEquals(2,
              Self.Core.SessionCount,
              'Number of sessions after two INVITEs');
  SessionOne.AcceptCall('', '');
  SessionTwo.AcceptCall('', '');
  Self.SimulateRemoteAck(Self.Dispatch.Transport.LastResponse);
  Check(not SessionOne.ReceivedAck, 'SessionOne got the ACK');
  Check(    SessionTwo.ReceivedAck, 'SessionTwo didn''t get the ACK');
end;

procedure TestTIdSipUserAgentCore.TestHasUnknownContentEncoding;
begin
  Self.Invite.Headers.Remove(Self.Invite.FirstHeader(ContentEncodingHeaderFull));

  Check(not Self.Core.HasUnknownContentEncoding(Self.Invite),
        'Vacuously true');

  Self.Invite.AddHeader(ContentEncodingHeaderFull);
  Check(Self.Core.HasUnknownContentEncoding(Self.Invite),
        'No encodings are supported');
end;

procedure TestTIdSipUserAgentCore.TestHasUnknownContentType;
begin
  Self.Invite.RemoveHeader(Self.Invite.FirstHeader(ContentTypeHeaderFull));

  Check(not Self.Core.HasUnknownContentType(Self.Invite),
        'Vacuously true');

  Self.Invite.AddHeader(ContentTypeHeaderFull).Value := SdpMimeType;
  Check(not Self.Core.HasUnknownContentType(Self.Invite),
        SdpMimeType + ' MUST supported');

  Self.Invite.RemoveHeader(Self.Invite.FirstHeader(ContentTypeHeaderFull));
  Self.Invite.AddHeader(ContentTypeHeaderFull);
  Check(Self.Core.HasUnknownContentType(Self.Invite),
        'Nothing else is supported');
end;

procedure TestTIdSipUserAgentCore.TestIsMethodAllowed;
begin
  Check(not Self.Core.IsMethodAllowed(MethodRegister),
        MethodRegister + ' not allowed');

  Self.Core.AddAllowedMethod(MethodRegister);
  Check(Self.Core.IsMethodAllowed(MethodRegister),
        MethodRegister + ' not recognised as an allowed method');

  Check(not Self.Core.IsMethodAllowed(' '),
        ''' '' not recognised as an allowed method');
end;

procedure TestTIdSipUserAgentCore.TestIsSchemeAllowed;
begin
  Check(not Self.Core.IsMethodAllowed(SipScheme),
        SipScheme + ' not allowed');

  Self.Core.AddAllowedScheme(SipScheme);
  Check(Self.Core.IsSchemeAllowed(SipScheme),
        SipScheme + ' not recognised as an allowed scheme');

  Check(not Self.Core.IsSchemeAllowed(' '),
        ''' '' not recognised as an allowed scheme');
end;

procedure TestTIdSipUserAgentCore.TestLoopDetection;
var
  Response:      TIdSipResponse;
  ResponseCount: Cardinal;
  Tran:          TIdSipTransaction;
begin
  // cf. RFC 3261, section 8.2.2.2
  Tran := Self.Dispatch.AddServerTransaction(Self.Invite, Self.Dispatch.Transport);

  // wipe out the tag & give a different branch
  Self.Invite.ToHeader.Value := Self.Invite.ToHeader.Address.URI;
  Self.Invite.LastHop.Branch := Self.Invite.LastHop.Branch + '1';

  ResponseCount := Self.Dispatch.Transport.SentResponseCount;

  Self.Core.ReceiveRequest(Self.Invite, Tran, Self.Dispatch.Transport);
  Check(Self.Dispatch.Transport.SentResponseCount > ResponseCount,
        'No response sent');

  Response := Self.Dispatch.Transport.LastResponse;
  CheckEquals(SIPLoopDetected, Response.StatusCode, 'Status-Code');
end;

procedure TestTIdSipUserAgentCore.TestNextTag;
var
  I:    Integer;
  Tags: TStringList;
begin
  // This is a woefully inadequate test. cf. RFC 3261, section 19.3

  Tags := TStringList.Create;
  try
    for I := 1 to 100 do
      Tags.Add(Self.Core.NextTag);

    // Find duplicates
    Tags.Sort;
    CheckNotEquals('', Tags[0], 'No null tags may be generated');

    for I := 1 to Tags.Count - 1 do begin
      CheckNotEquals('', Tags[I], 'No null tags may be generated (Tag #'
                                + IntToStr(I) + ')');

      CheckNotEquals(Tags[I-1], Tags[I], 'Duplicate tag generated');
    end;
  finally
  end;
end;

procedure TestTIdSipUserAgentCore.TestNotificationOfNewSession;
begin
  Self.SimulateRemoteInvite;

  Check(Self.OnNewSessionFired, 'UI not notified of new session');
end;

procedure TestTIdSipUserAgentCore.TestReceiveByeForUnmatchedDialog;
var
  Bye:           TIdSipRequest;
  Response:      TIdSipResponse;
  ResponseCount: Cardinal;
begin
  Bye := Self.Core.CreateRequest(Self.Destination);
  try
    Bye.Method          := MethodBye;
    Bye.CSeq.SequenceNo := $deadbeef;
    Bye.CSeq.Method     := Bye.Method;

    ResponseCount := Self.Dispatch.Transport.SentResponseCount;

    Self.Dispatch.Transport.FireOnRequest(Bye);

    CheckEquals(ResponseCount + 1,
                Self.Dispatch.Transport.SentResponseCount,
                'no response sent');
    Response := Self.Dispatch.Transport.LastResponse;
    CheckEquals(SIPCallLegOrTransactionDoesNotExist,
                Response.StatusCode,
                'Response Status-Code')

  finally
    Bye.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestReceiveByeForDialog;
var
  Response:      TIdSipResponse;
  ResponseCount: Cardinal;
begin

  Self.SimulateRemoteInvite;

  Check(Assigned(Self.Session), 'OnNewSession didn''t fire');
  Self.Session.AcceptCall('', '');

  ResponseCount := Self.Dispatch.Transport.SentResponseCount;
  Self.SimulateRemoteBye(Self.Session.Dialog);

  CheckEquals(ResponseCount + 1,
              Self.Dispatch.Transport.SentResponseCount,
              'SOMETHING should have sent a response');

  Response := Self.Dispatch.Transport.LastResponse;
  CheckNotEquals(SIPCallLegOrTransactionDoesNotExist,
                 Response.StatusCode,
                 'UA tells us no matching dialog was found');
end;

procedure TestTIdSipUserAgentCore.TestReceiveByeWithoutTags;
var
  Bye:           TIdSipRequest;
  Response:      TIdSipResponse;
  ResponseCount: Cardinal;
begin
  Bye := Self.Core.CreateRequest(Self.Destination);
  try
    Bye.Method          := MethodBye;
    Bye.From.Value      := Bye.From.Address.URI;     // strip the tag
    Bye.ToHeader.Value  := Bye.ToHeader.Address.URI; // strip the tag
    Bye.CSeq.SequenceNo := $deadbeef;
    Bye.CSeq.Method     := Bye.Method;

    ResponseCount := Self.Dispatch.Transport.SentResponseCount;

    Self.Dispatch.Transport.FireOnRequest(Bye);

    CheckEquals(ResponseCount + 1,
                Self.Dispatch.Transport.SentResponseCount,
                'no response sent');
    Response := Self.Dispatch.Transport.LastResponse;
    CheckEquals(SIPCallLegOrTransactionDoesNotExist,
                Response.StatusCode,
                'Response Status-Code')
  finally
    Bye.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestRemoveObserver;
var
  L1, L2: TIdSipTestObserver;
begin
  L1 := TIdSipTestObserver.Create;
  try
    L2 := TIdSipTestObserver.Create;
    try
      Self.Core.AddObserver(L1);
      Self.Core.AddObserver(L2);
      Self.Core.RemoveObserver(L2);

      Self.SimulateRemoteInvite;

      Check(L1.Changed and not L2.Changed,
            'Listener notified, hence not removed');
    finally
      L2.Free
    end;
  finally
    L1.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestRemoveSession;
var
  SessionCount: Cardinal;
begin
  Self.SimulateRemoteInvite;

  Check(Assigned(Self.Session), 'OnNewSession didn''t fire');
  SessionCount := Self.Core.SessionCount;
  Self.Core.RemoveSession(Self.Session);
  CheckEquals(SessionCount - 1,
              Self.Core.SessionCount,
              'Session wasn''t removed');
end;

procedure TestTIdSipUserAgentCore.TestRemoveSessionListener;
var
  L1, L2: TIdSipTestSessionListener;
begin
  L1 := TIdSipTestSessionListener.Create;
  try
    L2 := TIdSipTestSessionListener.Create;
    try
      Self.Core.AddSessionListener(L1);
      Self.Core.AddSessionListener(L2);
      Self.Core.RemoveSessionListener(L2);

      Self.SimulateRemoteInvite;

      Check(L1.NewSession and not L2.NewSession,
            'Listener notified, hence not removed');
    finally
      L2.Free
    end;
  finally
    L1.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestRejectNoContact;
var
  Response:      TIdSipResponse;
  ResponseCount: Cardinal;
begin
  Self.Invite.RemoveHeader(Self.Invite.FirstContact);

  ResponseCount := Self.Dispatch.Transport.SentResponseCount;

  Self.SimulateRemoteInvite;

  Check(Self.Dispatch.Transport.SentResponseCount > ResponseCount,
        'No response sent');

  Response := Self.Dispatch.Transport.LastResponse;
  CheckEquals(SIPBadRequest,        Response.StatusCode, 'Status-Code');
  CheckEquals(MissingContactHeader, Response.StatusText, 'Status-Text');
end;

procedure TestTIdSipUserAgentCore.TestRejectUnknownContentEncoding;
var
  Response:      TIdSipResponse;
  ResponseCount: Cardinal;
begin
  Self.Invite.FirstHeader(ContentTypeHeaderFull).Value := SdpMimeType;

  ResponseCount := Self.Dispatch.Transport.SentResponseCount;

  Self.Invite.AddHeader(ContentEncodingHeaderFull).Value := 'gzip';

  Self.SimulateRemoteInvite;

  Check(Self.Dispatch.Transport.SentResponseCount > ResponseCount,
        'No response sent');

  Response := Self.Dispatch.Transport.LastResponse;
  CheckEquals(SIPUnsupportedMediaType, Response.StatusCode, 'Status-Code');
  Check(Response.HasHeader(AcceptEncodingHeader), 'No Accept-Encoding header');
  CheckEquals('',
              Response.FirstHeader(AcceptEncodingHeader).Value,
              'Accept value');
end;

procedure TestTIdSipUserAgentCore.TestRejectUnknownContentLanguage;
var
  Response:      TIdSipResponse;
  ResponseCount: Cardinal;
begin
  Self.Core.AddAllowedLanguage('fr');

  Self.Invite.AddHeader(ContentLanguageHeader).Value := 'en_GB';

  ResponseCount := Self.Dispatch.Transport.SentResponseCount;

  Self.SimulateRemoteInvite;

  Check(Self.Dispatch.Transport.SentResponseCount > ResponseCount,
        'No response sent');

  Response := Self.Dispatch.Transport.LastResponse;
  CheckEquals(SIPUnsupportedMediaType, Response.StatusCode, 'Status-Code');
  Check(Response.HasHeader(AcceptLanguageHeader), 'No Accept-Language header');
  CheckEquals(Self.Core.AllowedLanguages,
              Response.FirstHeader(AcceptLanguageHeader).Value,
              'Accept-Language value');
end;

procedure TestTIdSipUserAgentCore.TestRejectUnknownContentType;
var
  Response:      TIdSipResponse;
  ResponseCount: Cardinal;
begin
  ResponseCount := Self.Dispatch.Transport.SentResponseCount;

  Self.Invite.ContentType := 'text/xml';

  Self.SimulateRemoteInvite;

  Check(Self.Dispatch.Transport.SentResponseCount > ResponseCount,
        'No response sent');

  Response := Self.Dispatch.Transport.LastResponse;
  CheckEquals(SIPUnsupportedMediaType, Response.StatusCode, 'Status-Code');
  Check(Response.HasHeader(AcceptHeader), 'No Accept header');
  CheckEquals(SdpMimeType,
              Response.FirstHeader(AcceptHeader).Value,
              'Accept value');
end;

procedure TestTIdSipUserAgentCore.TestRejectUnknownExtension;
var
  Response:      TIdSipResponse;
  ResponseCount: Cardinal;
begin
  ResponseCount := Self.Dispatch.Transport.SentResponseCount;

  Self.Invite.AddHeader(RequireHeader).Value := '100rel';

  Self.SimulateRemoteInvite;

  Check(Self.Dispatch.Transport.SentResponseCount > ResponseCount,
        'No response sent');

  Response := Self.Dispatch.Transport.LastResponse;
  CheckEquals(SIPBadExtension, Response.StatusCode, 'Status-Code');
  Check(Response.HasHeader(UnsupportedHeader), 'No Unsupported header');
  CheckEquals(Self.Invite.FirstHeader(RequireHeader).Value,
              Response.FirstHeader(UnsupportedHeader).Value,
              'Unexpected Unsupported header value');
end;

procedure TestTIdSipUserAgentCore.TestRejectUnknownScheme;
var
  Response:      TIdSipResponse;
  ResponseCount: Cardinal;
begin
  ResponseCount := Self.Dispatch.Transport.SentResponseCount;

  Self.Invite.RequestUri.URI := 'tel://1';
  Self.SimulateRemoteInvite;

  Check(Self.Dispatch.Transport.SentResponseCount > ResponseCount,
        'No response sent');

  Response := Self.Dispatch.Transport.LastResponse;
  CheckEquals(SIPUnsupportedURIScheme, Response.StatusCode, 'Status-Code');
end;

procedure TestTIdSipUserAgentCore.TestRejectUnsupportedMethod;
var
  Allow:         TIdSipCommaSeparatedHeader;
  I:             Integer;
  Methods:       TStrings;
  Response:      TIdSipResponse;
  ResponseCount: Cardinal;
begin
  Self.Invite.Method := MethodRegister;
  Self.Invite.CSeq.Method := Self.Invite.Method;

  ResponseCount := Self.Dispatch.Transport.SentResponseCount;

  Self.SimulateRemoteInvite;

  Check(Self.Dispatch.Transport.SentResponseCount > ResponseCount,
        'No response sent');

  Response := Self.Dispatch.Transport.LastResponse;
  Check(Response.HasHeader(AllowHeader),
        'Allow header is mandatory. cf. RFC 3261 section 8.2.1');

  Allow := Response.FirstHeader(AllowHeader) as TIdSipCommaSeparatedHeader;
  Methods := TStringList.Create;
  try
    Methods.CommaText := Self.Core.AllowedMethods;

    for I := 0 to Methods.Count - 1 do
      CheckEquals(Methods[I], Allow.Values[I], IntToStr(I + 1) + 'th value');
  finally
    Methods.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestRejectUnsupportedSipVersion;
var
  Response:      TIdSipResponse;
  ResponseCount: Cardinal;
begin
  ResponseCount := Self.Dispatch.Transport.SentResponseCount;
  Self.Invite.SIPVersion := 'SIP/1.0';

  Self.SimulateRemoteInvite;

  CheckEquals(ResponseCount + 1,
              Self.Dispatch.Transport.SentResponseCount,
              'No response sent');

  Response := Self.Dispatch.Transport.LastResponse;
  CheckEquals(SIPSIPVersionNotSupported,
              Response.StatusCode,
              'Status-Code');
end;

procedure TestTIdSipUserAgentCore.TestSetContact;
var
  C: TIdSipContactHeader;
begin
  C := TIdSipContactHeader.Create;
  try
    C.Value := 'sip:case@fried.neurons.org';
    Self.Core.Contact := C;

    Check(Self.Core.Contact.IsEqualTo(C),
                'Contact not set');
  finally
    C.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestSetContactMailTo;
var
  C: TIdSipContactHeader;
begin
  C := TIdSipContactHeader.Create;
  try
    try
      C.Value := 'mailto:wintermute@tessier-ashpool.co.luna';
      Self.Core.Contact := C;
      Fail('Only a SIP or SIPs URI may be specified');
    except
      on EBadHeader do;
    end;
  finally
    C.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestSetContactWildCard;
var
  C: TIdSipContactHeader;
begin
  C := TIdSipContactHeader.Create;
  try
    try
      C.Value := '*';
      Fail('Wildcard Contact headers make no sense in a response that sets up '
         + 'a dialog');
    except
    end;
  finally
    C.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestSetFrom;
var
  F: TIdSipFromHeader;
begin
  F := TIdSipFromHeader.Create;
  try
    F.Value := 'sip:case@fried.neurons.org';
    Self.Core.From := F;

    Check(Self.Core.From.IsEqualTo(F),
                'From not set');
  finally
    F.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestSetFromMailTo;
var
  F: TIdSipFromHeader;
begin
  F := TIdSipFromHeader.Create;
  try
    try
      F.Value := 'mailto:wintermute@tessier-ashpool.co.luna';
      Self.Core.From := F;
      Fail('Only a SIP or SIPs URI may be specified');
    except
      on EBadHeader do;
    end;
  finally
    F.Free;
  end;
end;

procedure TestTIdSipUserAgentCore.TestHangUpAllCalls;
var
  FirstSession:  TIdSipSession;
  SecondSession: TIdSipSession;
begin
  Self.SimulateRemoteInvite;
  Check(Assigned(Self.Session), 'OnNewSession didn''t fire');
  FirstSession := Self.Session;
  FirstSession.AcceptCall('', '');
  Self.Session := nil;

  Self.SimulateRemoteInvite;
  Check(Assigned(Self.Session), 'OnNewSession didn''t fire');
  SecondSession := Self.Session;
  SecondSession.AcceptCall('', '');

  CheckEquals(2,
              Self.Core.SessionCount,
              'Session count');
  Self.Core.HangUpAllCalls;
  CheckEquals(0,
              Self.Core.SessionCount,
              'Session count after HangUpAllCalls');
end;

//******************************************************************************
//* TestTIdSipSession                                                          *
//******************************************************************************
//* TestTIdSipSession Public methods *******************************************

procedure TestTIdSipSession.SetUp;
begin
  inherited SetUp;

  Self.Core.AddSessionListener(Self);

  Self.OnEndedSessionFired    := false;
  Self.OnModifiedSessionFired := false;
  Self.SentRequestTerminated  := false;

  Self.MultiStreamSdp := Self.CreateMultiStreamSdp;
  Self.SimpleSdp      := Self.CreateSimpleSdp;

  Self.Invite.ContentType := SdpMimeType;
  Self.Invite.Body        := Self.SimpleSdp.AsString;

  Self.EstablishedSession := Self.Core.Call(Self.Destination, '', '');
  Self.SimulateRemoteAccept(Self.EstablishedSession.Invite);
end;

procedure TestTIdSipSession.TearDown;
begin
  Self.Core.HangUpAllCalls;
  Self.SimpleSdp.Free;
  Self.MultiStreamSdp.Free;

  inherited TearDown;
end;

//* TestTIdSipSession Private methods ******************************************

procedure TestTIdSipSession.CheckServerActiveOn(Port: Cardinal);
var
  Server: TIdUDPServer;
begin
  Server := TIdUDPServer.Create(nil);
  try
    Server.DefaultPort := Port;

    try
      Server.Active := true;
      Fail('No server started on ' + IntToStr(Port));
    except
      on EIdCouldNotBindSocket do;
    end;
  finally
    Server.Free;
  end;
end;

function TestTIdSipSession.CreateRemoteReInvite(const LocalDialog: TIdSipDialog): TIdSipRequest;
begin
  Result := Self.Core.CreateRequest(LocalDialog);
  try
    Result.Assign(Self.Invite);
    Result.ToHeader.Tag := LocalDialog.ID.LocalTag;
  except
    FreeAndNil(Result);

    raise;
  end;
end;

function TestTIdSipSession.CreateMultiStreamSdp: TIdSdpPayload;
var
  Connection: TIdSdpConnection;
  MD:         TIdSdpMediaDescription;
begin
  Result := TIdSdpPayload.Create;
  Result.Version                := 0;

  Result.Origin.Username        := 'wintermute';
  Result.Origin.SessionID       := '2890844526';
  Result.Origin.SessionVersion  := '2890842807';
  Result.Origin.NetType         := Id_SDP_IN;
  Result.Origin.AddressType     := Id_IPv4;
  Result.Origin.Address         := '127.0.0.1';

  Result.SessionName            := 'Minimum Session Info';

  Connection := Result.AddConnection;
  Connection.NetType     := Id_SDP_IN;
  Connection.AddressType := Id_IPv4;
  Connection.Address     := '127.0.0.1';

  MD := Result.AddMediaDescription;
  MD.MediaType := mtAudio;
  MD.Port      := 10000;
  MD.Transport := AudioVisualProfile;
  MD.AddFormat('0');

  MD := Result.AddMediaDescription;
  MD.MediaType := mtText;
  MD.Port      := 11000;
  MD.Transport := AudioVisualProfile;
  MD.AddFormat('98');
  MD.AddAttribute(RTPMapAttribute, '98 t140/1000');
end;

function TestTIdSipSession.CreateSimpleSdp: TIdSdpPayload;
var
  Connection: TIdSdpConnection;
  MD:         TIdSdpMediaDescription;
begin
  Result := TIdSdpPayload.Create;
  Result.Version               := 0;

  Result.Origin.Username       := 'wintermute';
  Result.Origin.SessionID      := '2890844526';
  Result.Origin.SessionVersion := '2890842807';
  Result.Origin.NetType        := Id_SDP_IN;
  Result.Origin.AddressType    := Id_IPv4;
  Result.Origin.Address        := '127.0.0.1';

  Result.SessionName           := 'Minimum Session Info';

  MD := Result.AddMediaDescription;
  MD.MediaType := mtText;
  MD.Port      := 11000;
  MD.Transport := AudioVisualProfile;
  MD.AddFormat('98');
  MD.AddAttribute(RTPMapAttribute, '98 t140/1000');

  MD.Connections.Add(TIdSdpConnection.Create);
  Connection := MD.Connections[0];
  Connection.NetType     := Id_SDP_IN;
  Connection.AddressType := Id_IPv4;
  Connection.Address     := '127.0.0.1';
end;

procedure TestTIdSipSession.OnEndedSession(const Session: TIdSipSession);
begin
  Self.Session := Session;
  Self.OnEndedSessionFired := true;
end;

procedure TestTIdSipSession.OnEstablishedSession(const Session: TIdSipSession);
begin
end;

procedure TestTIdSipSession.OnModifiedSession(const Session: TIdSipSession;
                                              const Invite: TIdSipRequest);
begin
  Self.OnModifiedSessionFired := true;
end;

procedure TestTIdSipSession.OnNewData(Data: TIdRTPPayload;
                                      Binding: TIdSocketHandle);
begin
  Self.ThreadEvent.SetEvent;
end;


procedure TestTIdSipSession.OnNewSession(const Session: TIdSipSession);
begin
  Self.Session := Session;
  Self.Session.AddSessionListener(Self);
end;

procedure TestTIdSipSession.OnSendRequest(const Request: TIdSipRequest;
                                          const Transport: TIdSipTransport);
begin
end;

procedure TestTIdSipSession.OnSendResponse(const Response: TIdSipResponse;
                                           const Transport: TIdSipTransport);
begin
  if (Response.StatusCode = SIPRequestTerminated) then
    Self.SentRequestTerminated := true;
end;

procedure TestTIdSipSession.SimulateRemoteAccept(const Invite: TIdSipRequest);
var
  Response: TIdSipResponse;
begin
  // This message appears to originate from the network. Invite originates from
  // us so presumably has no To tag. Having come from the network, the response
  // WILL have a To tag.
  Response := Self.Core.CreateResponse(Invite, SIPOK);
  try
    Response.ToHeader.Tag := Self.Core.NextTag;
    Self.Dispatch.Transport.FireOnResponse(Response);
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipSession.SimulateRemoteRinging(const Invite: TIdSipRequest);
var
  Response: TIdSipResponse;
begin
  Response := Self.Core.CreateResponse(Invite, SIPRinging);
  try
    Self.Dispatch.Transport.FireOnResponse(Response);
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipSession.SimulateRemoteTryingWithNoToTag(const Invite: TIdSipRequest);
var
  Response: TIdSipResponse;
begin
  Response := Self.Core.CreateResponse(Invite, SIPTrying);
  try
    // strip the To header tag
    Response.ToHeader.Value := Response.ToHeader.Value;

    Self.Dispatch.Transport.FireOnResponse(Response);
  finally
    Response.Free;
  end;
end;

//* TestTIdSipSession Published methods ****************************************

procedure TestTIdSipSession.Test2xxRetransmission;
begin
  Self.SimulateRemoteInvite;
  Check(Assigned(Self.Session), 'OnNewSession didn''t fire');

  Self.Session.AcceptCall('', '');
  Self.Dispatch.Transport.ResetSentResponseCount;
  Self.Session.ResendLastResponse;
  CheckEquals(1,
              Self.Dispatch.Transport.SentResponseCount,
              'Response not resent');
  CheckEquals(SIPOK,
              Self.Dispatch.Transport.LastResponse.StatusCode,
              'Unexpected response code');
end;

procedure TestTIdSipSession.TestAcceptCall;
var
  Response:      TIdSipResponse;
  ResponseCount: Cardinal;
begin
  ResponseCount := Self.Dispatch.Transport.SentResponseCount;
  Self.Dispatch.Transport.TransportType := sttTCP;

  Self.SimulateRemoteInvite;
  Check(Assigned(Self.Session), 'OnNewSession didn''t fire');

  Self.Session.AcceptCall('', '');

  Check(ResponseCount < Self.Dispatch.Transport.SentResponseCount,
        'no responses sent');
  CheckNotNull(Session.Dialog, 'Dialog object wasn''t created');

  Response := Self.Dispatch.Transport.LastResponse;
  CheckEquals(SIPOK, Response.StatusCode,      'Status-Code');
  Check(Response.From.HasTag,                  'No From tag');
  Check(Response.ToHeader.HasTag,              'No To tag');
  Check(Response.HasHeader(ContactHeaderFull), 'No Contact header');
//  CheckEquals('', Response.Body,               'Body should be empty');
end;

procedure TestTIdSipSession.TestAcceptCallWithUnfulfillableOffer;
var
  ActualOffer: TIdSdpPayload;
  Offer:       String;
  Udp:         TIdUDPServer;
begin
  // Given an SDP payload describing the desired local port,
  // the session will try open that port but, if that port's
  // already in use, will open the lowest free port higher
  // than the desired local port.

  Udp := TIdUDPServer.Create(nil);
  try
    Udp.DefaultPort := Self.SimpleSdp.MediaDescriptionAt(0).Port;
    Udp.Active := true;

    Self.SimulateRemoteInvite;
    Check(Assigned(Self.Session), 'OnNewSession didn''t fire');
    Offer := Self.Session.AcceptCall(Self.SimpleSdp.AsString,
                                     SdpMimeType);
    Check(Offer <> Self.SimpleSdp.AsString,
          'Actual offer identical to suggested offer');

    Check(Offer <> '', 'AcceptCall returned the empty string');
    ActualOffer := TIdSdpPayload.CreateFrom(Offer);
    try
      Check(ActualOffer.MediaDescriptionCount > 0,
            'No media descriptions');

      Self.CheckServerActiveOn(ActualOffer.MediaDescriptionAt(0).Port);
    finally
      ActualOffer.Free;
    end;
  finally
    Udp.Free;
  end;
end;

procedure TestTIdSipSession.TestAcceptCallRespectsContentType;
var
  Response:      TIdSipResponse;
  ResponseCount: Cardinal;
  S:             TStringStream;
  SDP:           TIdSdpPayload;
begin
  ResponseCount := Self.Dispatch.Transport.SentResponseCount;
  Self.SimulateRemoteInvite;
  Check(Assigned(Self.Session), 'OnNewSession didn''t fire');

  Self.Session.AcceptCall(Self.SimpleSdp.AsString, SdpMimeType);

  Check(ResponseCount < Self.Dispatch.Transport.SentResponseCount,
        'no responses sent');

  Response := Self.Dispatch.Transport.LastResponse;
  Check(Response.HasHeader(ContentTypeHeaderFull),
        'No Content-Type header');
  CheckEquals(SdpMimeType,
              Response.FirstHeader(ContentTypeHeaderFull).Value,
              'Content-Type');
end;

procedure TestTIdSipSession.TestAcceptCallStartsListeningMedia;
var
  Udp: TIdUDPServer;
begin
  Self.SimulateRemoteInvite;
  Check(Assigned(Self.Session), 'OnNewSession didn''t fire');
  Self.Session.AcceptCall(Self.SimpleSdp.AsString,
                          SdpMimeType);

  Udp := TIdUDPServer.Create(nil);
  try
    Udp.DefaultPort := Self.SimpleSdp.MediaDescriptionAt(0).Port;
    try
      Udp.Active := true;
      Fail('No listening ports');
    except
      on EIdCouldNotBindSocket do;
    end;
  finally
    Udp.Free;
  end;
end;

procedure TestTIdSipSession.TestAddSessionListener;
var
  L1, L2: TIdSipTestSessionListener;
begin
  Self.SimulateRemoteInvite;
  Check(Assigned(Self.Session), 'OnNewSession didn''t fire');
  Self.Session.AcceptCall('', '');

  L1 := TIdSipTestSessionListener.Create;
  try
    L2 := TIdSipTestSessionListener.Create;
    try
      Self.Session.AddSessionListener(L1);
      Self.Session.AddSessionListener(L2);

      Self.SimulateRemoteBye(Self.Session.Dialog);

      Check(L1.EndedSession and L2.EndedSession, 'Not all Listeners notified, hence not added');
    finally
      L2.Free;
    end;
  finally
    L1.Free;
  end;
end;

procedure TestTIdSipSession.TestCall;
var
  Invite:       TIdSipRequest;
  RequestCount: Cardinal;
  Response:     TIdSipResponse;
  SessCount:    Integer;
  Session:      TIdSipSession;
  TranCount:    Integer;
begin
  RequestCount := Self.Dispatch.Transport.SentRequestCount;
  SessCount    := Self.Core.SessionCount;
  TranCount    := Self.Dispatch.TransactionCount;

  Session := Self.Core.Call(Self.Destination, '', '');

  CheckEquals(RequestCount + 1,
              Self.Dispatch.Transport.SentRequestCount,
              'no INVITE sent');
  Invite := Self.Dispatch.Transport.LastRequest;

  CheckEquals(TranCount + 1,
              Self.Dispatch.TransactionCount,
              'no client INVITE transaction created');

  CheckEquals(SessCount + 1,
              Self.Core.SessionCount,
              'no new session created');

  Response := Self.Core.CreateResponse(Invite, SIPRinging);
  try
    Self.Dispatch.Transport.FireOnResponse(Response);

    Check(Session.Dialog.IsEarly,
          'Dialog in incorrect state: should be Early');
    Check(not Session.Dialog.IsSecure,
          'Dialog secure when TLS not used');

    CheckEquals(Response.CallID,
                Session.Dialog.ID.CallID,
                'Dialog''s Call-ID');
    CheckEquals(Response.From.Tag,
                Session.Dialog.ID.LocalTag,
                'Dialog''s Local Tag');
    CheckEquals(Response.ToHeader.Tag,
                Session.Dialog.ID.RemoteTag,
                'Dialog''s Remote Tag');
  finally
    Response.Free;
  end;

  Response := Self.Core.CreateResponse(Invite, SIPOK);
  try
    Self.Dispatch.Transport.FireOnResponse(Response);

    Check(not Session.Dialog.IsEarly, 'Dialog in incorrect state: shouldn''t be early');
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipSession.TestCallTwice;
var
  SessCount: Integer;
  Session:   TIdSipSession;
  TranCount: Integer;
begin
  SessCount := Self.Core.SessionCount;
  TranCount := Self.Dispatch.TransactionCount;

  Session := Self.Core.Call(Self.Destination, '', '');
  Session.Call(Self.Destination, '', '');

  CheckEquals(SessCount + 1,
              Self.Core.SessionCount,
              'A second session was created');
  CheckEquals(TranCount + 1,
              Self.Dispatch.TransactionCount,
              'A second transaction was created');
end;

procedure TestTIdSipSession.TestCallRemoteRefusal;
var
  Response: TIdSipResponse;
  Session:  TIdSipSession;
begin
  Session := Self.Core.Call(Self.Destination, '', '');

  Response := Self.Core.CreateResponse(Self.Dispatch.Transport.LastRequest,
                                       SIPForbidden);
  try
    Session.AddSessionListener(Self);
    Self.Dispatch.Transport.FireOnResponse(Response);

    Check(Self.OnEndedSessionFired, 'OnEndedSession wasn''t triggered');
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipSession.TestCallNetworkFailure;
var
  Response: TIdSipResponse;
  Session:  TIdSipSession;
begin
  Session := TIdSipSession.Create(Self.Core);
  try
    Session.AddSessionListener(Self);
    Self.Dispatch.Transport.FailWith := EIdConnectTimeout;
    Session.Call(Self.Destination, '', '');

    Response := Self.Core.CreateResponse(Self.Dispatch.Transport.LastRequest,
                                         SIPForbidden);
    try
      Self.Dispatch.Transport.FireOnResponse(Response);

      Check(Self.OnEndedSessionFired, 'OnEndedSession wasn''t triggered');
    finally
      Response.Free;
    end;
  finally
    Session.Free;
  end;
end;

procedure TestTIdSipSession.TestCallSecure;
var
  Response: TIdSipResponse;
  Session:  TIdSipSession;
begin
  Self.Dispatch.Transport.TransportType := sttTLS;

  Self.Destination.Address.Scheme := SipsScheme;
  Session := Self.Core.Call(Self.Destination, '', '');

  Response := Self.Core.CreateResponse(Self.Dispatch.Transport.LastRequest,
                                       SIPRinging);
  try
    Self.Dispatch.Transport.FireOnResponse(Response);

    Response.StatusCode := SIPOK;
    Check(Session.Dialog.IsSecure, 'Dialog not secure when TLS used');
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipSession.TestCallSipsUriOverTcp;
var
  RequestCount: Cardinal;
  SentInvite:   TIdSipRequest;
  Session:      TIdSipSession;
begin
  RequestCount := Self.Dispatch.Transport.SentRequestCount;
  Self.Dispatch.Transport.TransportType := sttTCP;
  Self.Destination.Address.Scheme := SipsScheme;

  Session := Self.Core.Call(Self.Destination, '', '');

  Check(RequestCount < Self.Dispatch.Transport.SentRequestCount,
        'INVITE wasn''t sent');
  SentInvite := Self.Dispatch.Transport.LastRequest;

  Self.SimulateRemoteRinging(SentInvite);

  Check(not Session.Dialog.IsSecure, 'Dialog secure when TCP used');
end;

procedure TestTIdSipSession.TestCallSipUriOverTls;
var
  Response: TIdSipResponse;
  Session:  TIdSipSession;
begin
  Self.Dispatch.Transport.TransportType := sttTCP;

  Session := Self.Core.Call(Self.Destination, '', '');

  Response := Self.Core.CreateResponse(Self.Dispatch.Transport.LastRequest,
                                       SipRinging);
  try
    Response.FirstContact.Address.Scheme := SipsScheme;
    Response.StatusCode := SIPOK;
    Self.Dispatch.Transport.FireOnResponse(Response);

    Check(not Session.Dialog.IsSecure, 'Dialog secure when TLS used with a SIP URI');
  finally
    Response.Free;
  end;
end;

procedure TestTIdSipSession.TestCreateAck;
var
  Ack:    TIdSipRequest;
  Invite: TIdSipRequest;
begin
  Ack := Self.EstablishedSession.CreateAck;
  try
    CheckEquals(MethodAck, Ack.Method, 'Unexpected method');

    Invite := Self.EstablishedSession.Invite;

    CheckEquals(Invite.CSeq.SequenceNo,
                Ack.CSeq.SequenceNo,
                'CSeq numerical portion');
    CheckEquals(MethodAck,
                Ack.CSeq.Method,
                'ACK must have an INVITE method in the CSeq');

  finally
    Ack.Free;
  end;
end;

procedure TestTIdSipSession.TestCreateCancel;
var
  Cancel: TIdSipRequest;
begin
  Cancel := Self.EstablishedSession.CreateCancel(Self.Invite);
  try
    CheckEquals(MethodCancel, Cancel.Method, 'Unexpected method');
    CheckEquals(MethodCancel,
                Cancel.CSeq.Method,
                'CSeq method');
    Check(Self.Invite.RequestUri.Equals(Cancel.RequestUri),
          'Request-URI');
    CheckEquals(Self.Invite.CallID,
                Cancel.CallID,
                'Call-ID header');
    Check(Self.Invite.ToHeader.IsEqualTo(Cancel.ToHeader),
          'To header');
    CheckEquals(Self.Invite.CSeq.SequenceNo,
                Cancel.CSeq.SequenceNo,
                'CSeq numerical portion');
    Check(Self.Invite.From.IsEqualTo(Cancel.From),
          'From header');
    CheckEquals(1,
                Cancel.Path.Length,
                'Via headers');
  finally
    Cancel.Free;
  end;
end;

procedure TestTIdSipSession.TestCreateCancelANonInviteRequest;
var
  Options: TIdSipRequest;
begin
  Options := TIdSipRequest.Create;
  try
    Options.Method := MethodOptions;
    try
      Self.EstablishedSession.CreateCancel(Options);
      Fail('Failed to bail out of creating a CANCEL for a non-INVITE request');
    except
      on EAssertionFailed do;
    end;
  finally
    Options.Free;
  end;
end;

procedure TestTIdSipSession.TestCreateCancelWithProxyRequire;
var
  Cancel: TIdSipRequest;
begin
  Self.Invite.AddHeader(ProxyRequireHeader).Value := 'foofoo';

  Cancel := Self.EstablishedSession.CreateCancel(Self.Invite);
  try
    Check(not Cancel.HasHeader(ProxyRequireHeader),
          'Proxy-Require headers copied');
  finally
    Cancel.Free;
  end;
end;

procedure TestTIdSipSession.TestCreateCancelWithRequire;
var
  Cancel: TIdSipRequest;
begin
  Self.Invite.AddHeader(RequireHeader).Value := 'foofoo, barbar';

  Cancel := Self.EstablishedSession.CreateCancel(Self.Invite);
  try
    Check(not Cancel.HasHeader(ProxyRequireHeader),
          'Require headers copied');
  finally
    Cancel.Free;
  end;
end;

procedure TestTIdSipSession.TestCreateCancelWithRoute;
var
  Cancel:             TIdSipRequest;
  CancelRouteHeaders: TIdSipHeadersFilter;
  InviteRouteHeaders: TIdSipHeadersFilter;
begin
  Self.Invite.AddHeader(RouteHeader).Value := '<sip:127.0.0.1>';
  Self.Invite.AddHeader(RouteHeader).Value := '<sip:127.0.0.2>';

  Cancel := Self.EstablishedSession.CreateCancel(Self.Invite);
  try
    InviteRouteHeaders := TIdSipHeadersFilter.Create(Invite.Headers,
                                                     RouteHeader);
    try
      CancelRouteHeaders := TIdSipHeadersFilter.Create(Cancel.Headers,
                                                       RouteHeader);
      try
        Check(InviteRouteHeaders.IsEqualTo(CancelRouteHeaders),
              'Route headers not copied');
      finally
        CancelRouteHeaders.Free;
      end;
    finally
      InviteRouteHeaders.Free;
    end;
  finally
    Cancel.Free;
  end;
end;

procedure TestTIdSipSession.TestDialogNotEstablishedOnTryingResponse;
var
  RequestCount: Cardinal;
  SentInvite:   TIdSipRequest;
  Session:      TIdSipSession;
begin
  RequestCount := Self.Dispatch.Transport.SentRequestCount;

  Session := Self.Core.Call(Self.Destination, '', '');
  Check(not Session.DialogEstablished, 'Brand new session');

  Check(RequestCount < Self.Dispatch.Transport.SentRequestCount,
        'The INVITE wasn''t sent');
  SentInvite := Self.Dispatch.Transport.LastRequest;

  Self.SimulateRemoteTryingWithNoToTag(SentInvite);
  Check(not Session.DialogEstablished,
        'Dialog established after receiving a 100 Trying');

  Self.SimulateRemoteRinging(SentInvite);
  Check(Session.DialogEstablished,
        'Dialog not established after receiving a 180 Ringing');
end;

procedure TestTIdSipSession.TestReceive2xxSendsAck;
begin
  // Remember, we established a dialog for EstablishedSession in the SetUp
  CheckEquals(1,
              Self.Dispatch.Transport.ACKCount,
              'Retransmission');
  Self.Dispatch.Transport.FireOnResponse(Self.Dispatch.Transport.LastResponse);
  CheckEquals(2,
              Self.Dispatch.Transport.ACKCount,
              'Retransmission');
end;

procedure TestTIdSipSession.TestReceiveBye;
begin
  Self.SimulateRemoteInvite;

  Check(Assigned(Self.Session), 'OnNewSession didn''t fire');
  Self.Session.AcceptCall('', '');
  Self.Session.AddSessionListener(Self);

  Self.SimulateRemoteBye(Self.Session.Dialog);

  Check(Self.OnEndedSessionFired, 'OnEndedSession didn''t fire');
end;
{
procedure TestTIdSipSession.TestReceiveByeWithPendingRequests;
var
  ReInvite: TIdSipRequest;
  Session:  TIdSipSession;
begin
  Fail('Can''t be done until Session can modify a session');
  Self.SimulateRemoteInvite;
  Check(Assigned(Self.Session), 'OnNewSession wasn''t fired');
  Self.Session.AcceptCall;

  // This must be a CLIENT transaction!
  ReInvite := Self.CreateRemoteReInvite(Self.Session.Dialog);
  try
    Self.Dispatch.Transport.FireOnRequest(ReInvite);
    Self.SimulateRemoteBye(Self.Session.Dialog);

    Check(Self.SentRequestTerminated,
          'Pending request wasn''t responded to with a 481 Request Terminated');
  finally
    ReInvite.Free;
  end;
end;
}
procedure TestTIdSipSession.TestReceiveOutOfOrderRequest;
var
  Invite:   TIdSipRequest;
  Response: TIdSipResponse;
begin
  Self.SimulateRemoteInvite;
  Check(Assigned(Self.Session), 'OnNewSession wasn''t fired');
  Self.Session.AcceptCall('', '');

  Invite := Self.CreateRemoteReInvite(Self.Session.Dialog);
  try
    Invite.CSeq.SequenceNo := Invite.CSeq.SequenceNo - 1;
    Self.Dispatch.Transport.ResetSentResponseCount;
    Self.Dispatch.Transport.FireOnRequest(Invite);
    CheckEquals(1,
                Self.Dispatch.Transport.SentResponseCount,
                'No response sent');
    Response := Self.Dispatch.Transport.LastResponse;
    CheckEquals(SIPInternalServerError,
                Response.StatusCode,
                'Unexpected response');
    CheckEquals(RSSIPRequestOutOfOrder,
                Response.StatusText,
                'Unexpected response, status text');
  finally
    Invite.Free;
  end;
end;

procedure TestTIdSipSession.TestReceiveReInvite;
var
  ReInvite: TIdSipRequest;
begin
  Self.SimulateRemoteInvite;
  Check(Assigned(Self.Session), 'OnNewSession wasn''t fired');
  Self.Session.AcceptCall('', '');

  ReInvite := Self.CreateRemoteReInvite(Self.Session.Dialog);
  try
    Self.Dispatch.Transport.FireOnRequest(ReInvite);

    Check(Self.OnModifiedSessionFired, 'OnModifiedSession didn''t fire');
  finally
    ReInvite.Free;
  end;
end;

procedure TestTIdSipSession.TestRemoveSessionListener;
var
  L1, L2: TIdSipTestSessionListener;
begin
  Self.SimulateRemoteInvite;
  Check(Assigned(Self.Session), 'OnNewSession didn''t fire');
  Self.Session.AcceptCall('', '');

  L1 := TIdSipTestSessionListener.Create;
  try
    L2 := TIdSipTestSessionListener.Create;
    try
      Self.Session.AddSessionListener(L1);
      Self.Session.AddSessionListener(L2);
      Self.Session.RemoveSessionListener(L2);

      Self.SimulateRemoteBye(Self.Session.Dialog);

      Check(L1.EndedSession and not L2.EndedSession,
            'Listener notified, hence not removed');
    finally
      L2.Free
    end;
  finally
    L1.Free;
  end;
end;

procedure TestTIdSipSession.TestTerminate;
var
  Request:      TIdSipRequest;
  RequestCount: Cardinal;
begin
  RequestCount := Self.Dispatch.Transport.SentRequestCount;

  Self.SimulateRemoteInvite;
  Check(Assigned(Self.Session), 'OnNewSession didn''t fire');

  Self.Session.AcceptCall('', '');
  Self.Session.Terminate;

  CheckEquals(RequestCount + 1,
              Self.Dispatch.Transport.SentRequestCount,
              'no BYE sent');

  Request := Self.Dispatch.Transport.LastRequest;
  Check(Request.IsBye, 'Unexpected last request');

  Check(Self.Session.IsTerminated, 'Session not marked as terminated');
end;

procedure TestTIdSipSession.TestTerminateUnestablishedSession;
var
  Request:      TIdSipRequest;
  RequestCount: Cardinal;
  Session:      TIdSipSession;
begin
  Session := Self.Core.Call(Self.Destination, '', '');
  RequestCount := Self.Dispatch.Transport.SentRequestCount;

  Session.Terminate;

  CheckEquals(RequestCount + 1,
              Self.Dispatch.Transport.SentRequestCount,
              'no CANCEL sent');

  Request := Self.Dispatch.Transport.LastRequest;
  Check(Request.IsCancel, 'Unexpected last request');

  Check(Session.IsTerminated, 'Session not marked as terminated');
end;

//******************************************************************************
//* TestTIdSipSessionTimer                                                     *
//******************************************************************************
//* TestTIdSipSessionTimer Public methods **************************************

procedure TestTIdSipSessionTimer.SetUp;
begin
  inherited SetUp;

  Self.Session := TIdSipMockSession.Create;
  Self.Timer := TIdSipSessionTimer.Create(Self.Session, DefaultT1, DefaultT2);
end;

procedure TestTIdSipSessionTimer.TearDown;
begin
  Self.Timer.Free;
  Self.Session.Free;

  inherited TearDown;
end;

//* TestTIdSipSessionTimer Published methods ***********************************

procedure TestTIdSipSessionTimer.TestFireResendsSessionsLastResponse;
begin
  Check(not Self.Session.ResponseResent, 'Sanity check');
  Self.Timer.Fire;
  Check(Self.Session.ResponseResent, 'Fire didn''t affect the Session');
end;

procedure TestTIdSipSessionTimer.TestTimerIntervalIncreases;
begin
  CheckEquals(DefaultT1,   Self.Timer.Interval, 'Initial interval');
  Self.Timer.Fire;
  CheckEquals(2*DefaultT1, Self.Timer.Interval, 'Fire once');
  Self.Timer.Fire;
  CheckEquals(4*DefaultT1, Self.Timer.Interval, 'Fire twice');
  Self.Timer.Fire;
  CheckEquals(DefaultT2,   Self.Timer.Interval, 'Fire thrice');
  Self.Timer.Fire;
  CheckEquals(DefaultT2,   Self.Timer.Interval, 'Fire four times');
end;

initialization
  RegisterTest('Transaction User Cores', Suite);
end.
