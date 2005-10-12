{
  (c) 2004 Directorate of New Technologies, Royal National Institute for Deaf people (RNID)

  The RNID licence covers this unit. Read the licence at:
      http://www.ictrnid.org.uk/docs/gw/rnid_license.txt

  This unit contains code written by:
    * Frank Shearar
}
unit TestIdSipCore;

interface

uses
  IdObservable, IdSipCore, IdSipDialog, IdSipInviteModule, IdSipMessage,
  IdSipMockTransactionDispatcher, IdSipTransport, IdSipUserAgent,
  TestFramework, TestFrameworkSip, TestFrameworkSipTU;

type
  TestTIdSipAbstractCore = class(TTestCaseTU,
                                 IIdSipTransactionUserListener)
  private
    ScheduledEventFired: Boolean;

    procedure CheckCommaSeparatedHeaders(const ExpectedValues: String;
                                         Header: TIdSipHeader;
                                         const Msg: String);
    procedure OnAuthenticationChallenge(UserAgent: TIdSipAbstractCore;
                                        Challenge: TIdSipResponse;
                                        var Username: String;
                                        var Password: String;
                                        var TryAgain: Boolean); overload;
    procedure OnAuthenticationChallenge(UserAgent: TIdSipAbstractCore;
                                        ChallengedRequest: TIdSipRequest;
                                        Challenge: TIdSipResponse); overload;
    procedure OnDroppedUnmatchedMessage(UserAgent: TIdSipAbstractCore;
                                        Message: TIdSipMessage;
                                        Receiver: TIdSipTransport);
    procedure ScheduledEvent(Sender: TObject);
  public
    procedure SetUp; override;
  published
    procedure TestAddAllowedContentType;
    procedure TestAddAllowedContentTypes;
    procedure TestAddAllowedContentTypeMalformed;
    procedure TestAddAllowedLanguage;
    procedure TestAddAllowedLanguageLanguageAlreadyPresent;
    procedure TestAddAllowedMethod;
    procedure TestAddAllowedMethodMethodAlreadyPresent;
    procedure TestAddAllowedScheme;
    procedure TestAddAllowedSchemeSchemeAlreadyPresent;
    procedure TestAddModule;
    procedure TestAddObserver;
    procedure TestHasUnknownAccept;
    procedure TestHasUnknownContentEncoding;
    procedure TestHasUnknownContentType;
    procedure TestIsMethodSupported;
    procedure TestIsSchemeAllowed;
    procedure TestLoopDetection;
    procedure TestModuleForString;
    procedure TestNextCallID;
    procedure TestNextTag;
    procedure TestNotifyOfChange;
    procedure TestRejectUnknownContentEncoding;
    procedure TestRejectUnknownContentLanguage;
    procedure TestRejectUnknownContentType;
    procedure TestRejectUnknownExtension;
    procedure TestRejectUnknownScheme;
    procedure TestRejectUnsupportedMethod;
    procedure TestRejectUnsupportedSipVersion;
    procedure TestRemoveObserver;
    procedure TestScheduleEvent;
  end;

  TIdSipNullAction = class(TIdSipAction)
  protected
    function CreateNewAttempt: TIdSipRequest; override;
  public
    class function Method: String; override;
  end;

  TestTIdSipActions = class(TTestCaseTU)
  private
    ActionProcUsed:      String;
    Actions:             TIdSipActions;
    DidntFindActionName: String;
    FoundActionName:     String;
    Options:             TIdSipRequest;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestActionCount;
    procedure TestAddActionNotifiesObservers;
    procedure TestAddObserver;
    procedure TestCleanOutTerminatedActions;
    procedure TestFindActionAndPerformBlock;
    procedure TestFindActionAndPerformBlockNoActions;
    procedure TestFindActionAndPerformBlockNoMatch;
    procedure TestFindActionAndPerformOrBlock;
    procedure TestFindActionAndPerformOrBlockNoMatch;
    procedure TestInviteCount;
    procedure TestRemoveObserver;
    procedure TestTerminateAllActions;
  end;

  // These tests exercise the SIP discovery algorithms as defined in RFC 3263.
  TestLocation = class(TTestCaseTU,
                       IIdSipActionListener,
                       IIdSipInviteListener)
  private
    InviteOffer:    String;
    InviteMimeType: String;
    NetworkFailure: Boolean;
    TransportParam: String;

    function  CreateAction: TIdSipOutboundInitialInvite;
    procedure OnAuthenticationChallenge(Action: TIdSipAction;
                                        Response: TIdSipResponse);
    procedure OnCallProgress(InviteAgent: TIdSipOutboundInvite;
                        Response: TIdSipResponse);
    procedure OnFailure(InviteAgent: TIdSipOutboundInvite;
                        Response: TIdSipResponse;
                        const Reason: String);
    procedure OnDialogEstablished(InviteAgent: TIdSipOutboundInvite;
                                  NewDialog: TIdSipDialog);
    procedure OnNetworkFailure(Action: TIdSipAction;
                               ErrorCode: Cardinal;
                               const Reason: String);
    procedure OnRedirect(InviteAgent: TIdSipOutboundInvite;
                         Redirect: TIdSipResponse);
    procedure OnSuccess(InviteAgent: TIdSipOutboundInvite;
                        Response: TIdSipResponse);
  public
    procedure SetUp; override;
  published
    procedure TestAllLocationsFail;
    procedure TestLooseRoutingProxy;
    procedure TestStrictRoutingProxy;
    procedure TestUseCorrectTransport;
    procedure TestUseTransportParam;
    procedure TestUseUdpByDefault;
    procedure TestVeryLargeMessagesUseAReliableTransport;
  end;

  TestTIdSipMessageModule = class(TTestCaseTU)
  published
    procedure TestRejectNonInviteWithReplacesHeader;
  end;

  TestTIdSipNullMessageModule = class(TTestCaseTU)
  private
    Module: TIdSipMessageModule;
  public
    procedure SetUp; override;
  published
    procedure TestIsNull;
  end;

  TestTIdSipOptionsModule = class(TTestCaseTU)
  published
    procedure TestReceiveOptions;
    procedure TestRejectOptionsWithReplacesHeader;
  end;

  TestTIdSipInboundOptions = class(TestTIdSipAction)
  private
    Options: TIdSipInboundOptions;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestIsInbound; override;
    procedure TestIsInvite; override;
    procedure TestIsOptions; override;
    procedure TestIsRegistration; override;
    procedure TestIsSession; override;
    procedure TestOptions;
    procedure TestOptionsWhenDoNotDisturb;
  end;

  TestTIdSipOutboundOptions = class(TestTIdSipAction,
                                    IIdSipOptionsListener)
  private
    ReceivedResponse: Boolean;

    procedure OnResponse(OptionsAgent: TIdSipOutboundOptions;
                         Response: TIdSipResponse);
  protected
    function CreateAction: TIdSipAction; override;
  public
    procedure SetUp; override;
  published
    procedure TestAddListener;
    procedure TestIsOptions; override;
    procedure TestReceiveResponse;
    procedure TestRemoveListener;
  end;

  TestTIdSipActionAuthenticationChallengeMethod = class(TActionMethodTestCase)
  private
    Action:   TIdSipAction;
    Listener: TIdSipMockListener;
    Method:   TIdSipActionAuthenticationChallengeMethod;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestRun;
  end;

  TestTIdSipActionNetworkFailureMethod = class(TActionMethodTestCase)
  private
    Action:    TIdSipAction;
    ErrorCode: Cardinal;
    Listener:  TIdSipMockListener;
    Method:    TIdSipActionNetworkFailureMethod;
    Reason:    String;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestRun;
  end;

  TestTIdSipOptionsResponseMethod = class(TActionMethodTestCase)
  private
    Method: TIdSipOptionsResponseMethod;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestRun;
  end;

  TestTIdSipUserAgentDroppedUnmatchedMessageMethod = class(TTestCase)
  private
    Method:   TIdSipUserAgentDroppedUnmatchedMessageMethod;
    Receiver: TIdSipTransport;
    Response: TIdSipResponse;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestRun;
  end;

implementation

uses
  Classes, IdException, IdSdp, IdSimpleParser, IdSipDns, IdSipLocator,
  IdSipMockTransport, IdSipRegistration, IdSipSubscribeModule, SysUtils;

const
  DefaultTimeout = 5000;

type
  TIdSipCoreWithExposedNotify = class(TIdSipAbstractCore)
  public
    procedure TriggerNotify;
  end;

function Suite: ITestSuite;
begin
  Result := TTestSuite.Create('IdSipCore unit tests');
  Result.AddTest(TestTIdSipAbstractCore.Suite);
  Result.AddTest(TestTIdSipActions.Suite);
  Result.AddTest(TestLocation.Suite);
  Result.AddTest(TestTIdSipNullMessageModule.Suite);
  Result.AddTest(TestTIdSipOptionsModule.Suite);
  Result.AddTest(TestTIdSipInboundOptions.Suite);
  Result.AddTest(TestTIdSipOutboundOptions.Suite);
  Result.AddTest(TestTIdSipActionAuthenticationChallengeMethod.Suite);
  Result.AddTest(TestTIdSipActionNetworkFailureMethod.Suite);
  Result.AddTest(TestTIdSipOptionsResponseMethod.Suite);
  Result.AddTest(TestTIdSipUserAgentDroppedUnmatchedMessageMethod.Suite);
end;

//******************************************************************************
//* TIdSipCoreWithExposedNotify                                                *
//******************************************************************************
//* TIdSipCoreWithExposedNotify Public methods *********************************

procedure TIdSipCoreWithExposedNotify.TriggerNotify;
begin
  Self.NotifyOfChange;
end;

//******************************************************************************
//* TestTIdSipAbstractCore                                                     *
//******************************************************************************
//* TestTIdSipAbstractCore Public methods **************************************

procedure TestTIdSipAbstractCore.SetUp;
begin
  inherited SetUp;

  Self.ScheduledEventFired := false;
end;

//* TestTIdSipAbstractCore Private methods *************************************

procedure TestTIdSipAbstractCore.CheckCommaSeparatedHeaders(const ExpectedValues: String;
                                                            Header: TIdSipHeader;
                                                            const Msg: String);
var
  Hdr:    TIdSipCommaSeparatedHeader;
  I:      Integer;
  Values: TStringList;
begin
  CheckEquals(TIdSipCommaSeparatedHeader.ClassName,
              Header.ClassName,
              Msg + ': Unexpected header type in CheckCommaSeparatedHeaders');

  Hdr := Header as TIdSipCommaSeparatedHeader;
  Values := TStringList.Create;
  try
    Values.CommaText := ExpectedValues;

    for I := 0 to Values.Count - 1 do
      CheckEquals(Values[I],
                  Hdr.Values[I],
                  Msg + ': ' + IntToStr(I + 1) + 'th value');
  finally
    Values.Free;
  end;
end;

procedure TestTIdSipAbstractCore.OnAuthenticationChallenge(UserAgent: TIdSipAbstractCore;
                                                           Challenge: TIdSipResponse;
                                                           var Username: String;
                                                           var Password: String;
                                                           var TryAgain: Boolean);
begin
end;

procedure TestTIdSipAbstractCore.OnAuthenticationChallenge(UserAgent: TIdSipAbstractCore;
                                                           ChallengedRequest: TIdSipRequest;
                                                           Challenge: TIdSipResponse);
begin
end;


procedure TestTIdSipAbstractCore.OnDroppedUnmatchedMessage(UserAgent: TIdSipAbstractCore;
                                                           Message: TIdSipMessage;
                                                           Receiver: TIdSipTransport);
begin
end;

procedure TestTIdSipAbstractCore.ScheduledEvent(Sender: TObject);
begin
  Self.ScheduledEventFired := true;
  Self.ThreadEvent.SetEvent;
end;


//* TestTIdSipAbstractCore Published methods ***********************************

procedure TestTIdSipAbstractCore.TestAddAllowedContentType;
var
  ContentTypes: TStrings;
begin
  ContentTypes := TStringList.Create;
  try
    Self.Core.AddAllowedContentType(SdpMimeType);
    Self.Core.AddAllowedContentType(PlainTextMimeType);

    ContentTypes.CommaText := Self.Core.AllowedContentTypes;

    CheckEquals(2, ContentTypes.Count, 'Number of allowed Content-Types');

    CheckEquals(SdpMimeType,       ContentTypes[0], SdpMimeType);
    CheckEquals(PlainTextMimeType, ContentTypes[1], PlainTextMimeType);
  finally
    ContentTypes.Free;
  end;
end;

procedure TestTIdSipAbstractCore.TestAddAllowedContentTypes;
var
  Actual:   TStrings;
  Expected: TStrings;
begin
  Expected := TStringList.Create;
  try
    Actual := TStringList.Create;
    try
      Expected.Add(SdpMimeType);
      Expected.Add('message/sipfrag');

      Self.Core.AddAllowedContentTypes(Expected);

      Actual.CommaText := Self.Core.AllowedContentTypes;

      CheckEquals(Expected.CommaText,
                  Actual.CommaText,
                  'Content types not added');
    finally
      Actual.Free;
    end;
  finally
    Expected.Free;
  end;
end;

procedure TestTIdSipAbstractCore.TestAddAllowedContentTypeMalformed;
var
  ContentTypes: String;
begin
  ContentTypes := Self.Core.AllowedContentTypes;
  Self.Core.AddAllowedContentType(' ');
  CheckEquals(ContentTypes,
              Self.Core.AllowedContentTypes,
              'Malformed Content-Type was allowed');
end;

procedure TestTIdSipAbstractCore.TestAddAllowedLanguage;
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

procedure TestTIdSipAbstractCore.TestAddAllowedLanguageLanguageAlreadyPresent;
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

procedure TestTIdSipAbstractCore.TestAddAllowedMethod;
var
  Methods: TStringList;
begin
  Methods := TStringList.Create;
  try
    Methods.CommaText := Self.Core.KnownMethods;
    Methods.Sort;

    CheckEquals(MethodAck,     Methods[0], 'ACK first');
    CheckEquals(MethodBye,     Methods[1], 'BYE second');
    CheckEquals(MethodCancel,  Methods[2], 'CANCEL third');
    CheckEquals(MethodInvite,  Methods[3], 'INVITE fourth');
    CheckEquals(MethodOptions, Methods[4], 'OPTIONS fifth');

    CheckEquals(5, Methods.Count, 'Number of allowed methods');
  finally
    Methods.Free;
  end;
end;

procedure TestTIdSipAbstractCore.TestAddAllowedMethodMethodAlreadyPresent;
var
  Methods: TStrings;
  MethodCount: Cardinal;
begin
  Methods := TStringList.Create;
  try
    Self.Core.AddModule(TIdSipInviteModule);
    Methods.CommaText := Self.Core.KnownMethods;
    MethodCount := Methods.Count;

    Self.Core.AddModule(TIdSipInviteModule);
    Methods.CommaText := Self.Core.KnownMethods;

    CheckEquals(MethodCount, Methods.Count, MethodInvite + ' was re-added');
  finally
    Methods.Free;
  end;
end;

procedure TestTIdSipAbstractCore.TestAddAllowedScheme;
var
  Schemes: TStrings;
begin
  Schemes := TStringList.Create;
  try
    Self.Core.AddAllowedScheme(SipScheme);
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

procedure TestTIdSipAbstractCore.TestAddAllowedSchemeSchemeAlreadyPresent;
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

procedure TestTIdSipAbstractCore.TestAddModule;
var
  Module:     TIdSipMessageModule;
  ModuleType: TIdSipMessageModuleClass;
begin
  ModuleType := TIdSipSubscribeModule;

  Module := Self.Core.AddModule(ModuleType);
  Check(Assigned(Module),
        'AddModule didn''t return anything');
  CheckEquals(ModuleType.ClassName,
              Module.ClassName,
              'AddModule returned an unexpected module');

  Module := Self.Core.AddModule(ModuleType);
  Check(Assigned(Module),
        'AddModule didn''t return anything for an already-installed module');
end;

procedure TestTIdSipAbstractCore.TestAddObserver;
var
  L1, L2: TIdObserverListener;
begin
  L1 := TIdObserverListener.Create;
  try
    L2 := TIdObserverListener.Create;
    try
      Self.Core.AddObserver(L1);
      Self.Core.AddObserver(L2);

      Self.ReceiveInvite;

      Check(L1.Changed and L2.Changed, 'Not all Listeners notified, hence not added');
    finally
      L2.Free;
    end;
  finally
    L1.Free;
  end;
end;

procedure TestTIdSipAbstractCore.TestHasUnknownAccept;
begin
  Self.Invite.RemoveHeader(Self.Invite.FirstHeader(AcceptHeader));

  Check(not Self.Core.HasUnknownAccept(Self.Invite),
        'Vacuously true');

  Self.Invite.AddHeader(AcceptHeader).Value := SdpMimeType;
  Check(not Self.Core.HasUnknownAccept(Self.Invite),
        SdpMimeType + ' MUST supported');

  Self.Invite.RemoveHeader(Self.Invite.FirstHeader(AcceptHeader));
  Self.Invite.AddHeader(AcceptHeader);
  Check(Self.Core.HasUnknownAccept(Self.Invite),
        'Nothing else is supported');
end;

procedure TestTIdSipAbstractCore.TestHasUnknownContentEncoding;
begin
  Self.Invite.Headers.Remove(Self.Invite.FirstHeader(ContentEncodingHeaderFull));

  Check(not Self.Core.HasUnknownContentEncoding(Self.Invite),
        'Vacuously true');

  Self.Invite.AddHeader(ContentEncodingHeaderFull);
  Check(Self.Core.HasUnknownContentEncoding(Self.Invite),
        'No encodings are supported');
end;

procedure TestTIdSipAbstractCore.TestHasUnknownContentType;
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

procedure TestTIdSipAbstractCore.TestIsMethodSupported;
begin
  Check(not Self.Core.IsMethodSupported(MethodRegister),
        MethodRegister + ' not allowed');

  Self.Core.AddModule(TIdSipRegisterModule);
  Check(Self.Core.IsMethodSupported(MethodRegister),
        MethodRegister + ' not recognised as an allowed method');

  Check(not Self.Core.IsMethodSupported(' '),
        ''' '' recognised as an allowed method');
end;

procedure TestTIdSipAbstractCore.TestIsSchemeAllowed;
begin
  Check(not Self.Core.IsMethodSupported(SipScheme),
        SipScheme + ' not allowed');

  Self.Core.AddAllowedScheme(SipScheme);
  Check(Self.Core.IsSchemeAllowed(SipScheme),
        SipScheme + ' not recognised as an allowed scheme');

  Check(not Self.Core.IsSchemeAllowed(' '),
        ''' '' not recognised as an allowed scheme');
end;

procedure TestTIdSipAbstractCore.TestLoopDetection;
var
  Response: TIdSipResponse;
begin
  // cf. RFC 3261, section 8.2.2.2
  Self.Dispatcher.AddServerTransaction(Self.Invite, Self.Dispatcher.Transport);

  // wipe out the tag & give a different branch
  Self.Invite.ToHeader.Value := Self.Invite.ToHeader.Address.URI;
  Self.Invite.LastHop.Branch := Self.Invite.LastHop.Branch + '1';

  Self.MarkSentResponseCount;

  Self.ReceiveInvite;
  CheckResponseSent('No response sent');

  Response := Self.LastSentResponse;
  CheckEquals(SIPLoopDetected, Response.StatusCode, 'Status-Code');
end;

procedure TestTIdSipAbstractCore.TestModuleForString;
begin
  CheckEquals(TIdSipNullMessageModule.ClassName,
              Self.Core.ModuleFor('').ClassName,
              'Empty string');
  CheckEquals(TIdSipNullMessageModule.ClassName,
              Self.Core.ModuleFor(MethodRegister).ClassName,
              MethodRegister + ' but no module added');

  Self.Core.AddModule(TIdSipRegisterModule);
  CheckNotNull(Self.Core.ModuleFor(MethodRegister),
               MethodRegister + ' but no module added');
  CheckEquals(TIdSipRegisterModule.ClassName,
              Self.Core.ModuleFor(MethodRegister).ClassName,
              MethodRegister + ' after module added: wrong type');
  CheckEquals(TIdSipNullMessageModule.ClassName,
              Self.Core.ModuleFor(Lowercase(MethodRegister)).ClassName,
              Lowercase(MethodRegister)
            + ': RFC 3261 defines REGISTER''s method as "REGISTER"');
end;

procedure TestTIdSipAbstractCore.TestNextCallID;
var
  CallID: String;
begin
  CallID := Self.Core.NextCallID;

  Fetch(CallID, '@');

  CheckEquals(Self.Core.HostName, CallID, 'HostName not used');
end;

procedure TestTIdSipAbstractCore.TestNextTag;
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

procedure TestTIdSipAbstractCore.TestNotifyOfChange;
var
  C: TIdSipCoreWithExposedNotify;
  O: TIdObserverListener;
begin
  C := TIdSipCoreWithExposedNotify.Create;
  try
    O := TIdObserverListener.Create;
    try
      C.AddObserver(O);
      C.TriggerNotify;
      Check(O.Changed,
            'Observer not notified');
      Check(O.Data = C,
           'Core didn''t return itself as parameter in the notify');
    finally
      O.Free;
    end;
  finally
    C.Free;
  end;
end;

procedure TestTIdSipAbstractCore.TestRejectUnknownContentEncoding;
var
  Response: TIdSipResponse;
begin
  Self.Invite.FirstHeader(ContentTypeHeaderFull).Value := SdpMimeType;

  Self.MarkSentResponseCount;

  Self.Invite.AddHeader(ContentEncodingHeaderFull).Value := 'gzip';

  Self.ReceiveInvite;

  CheckResponseSent('No response sent');

  Response := Self.LastSentResponse;
  CheckEquals(SIPUnsupportedMediaType, Response.StatusCode, 'Status-Code');
  Check(Response.HasHeader(AcceptEncodingHeader), 'No Accept-Encoding header');
  CheckEquals('',
              Response.FirstHeader(AcceptEncodingHeader).Value,
              'Accept value');
end;

procedure TestTIdSipAbstractCore.TestRejectUnknownContentLanguage;
var
  Response: TIdSipResponse;
begin
  Self.Core.AddAllowedLanguage('fr');

  Self.Invite.AddHeader(ContentLanguageHeader).Value := 'en_GB';

  Self.MarkSentResponseCount;

  Self.ReceiveInvite;

  CheckResponseSent('No response sent');

  Response := Self.LastSentResponse;
  CheckEquals(SIPUnsupportedMediaType, Response.StatusCode, 'Status-Code');
  Check(Response.HasHeader(AcceptLanguageHeader), 'No Accept-Language header');
  CheckEquals(Self.Core.AllowedLanguages,
              Response.FirstHeader(AcceptLanguageHeader).Value,
              'Accept-Language value');
end;

procedure TestTIdSipAbstractCore.TestRejectUnknownContentType;
var
  Response: TIdSipResponse;
begin
  Self.MarkSentResponseCount;

  Self.Invite.ContentType := 'text/xml';

  Self.ReceiveInvite;

  CheckResponseSent('No response sent');

  Response := Self.LastSentResponse;
  CheckEquals(SIPUnsupportedMediaType, Response.StatusCode, 'Status-Code');
  Check(Response.HasHeader(AcceptHeader), 'No Accept header');
  CheckEquals(SdpMimeType,
              Response.FirstHeader(AcceptHeader).Value,
              'Accept value');
end;

procedure TestTIdSipAbstractCore.TestRejectUnknownExtension;
var
  Response: TIdSipResponse;
begin
  Self.MarkSentResponseCount;

  Self.Invite.AddHeader(RequireHeader).Value := '100rel';

  Self.ReceiveInvite;

  CheckResponseSent('No response sent');

  Response := Self.LastSentResponse;
  CheckEquals(SIPBadExtension, Response.StatusCode, 'Status-Code');
  Check(Response.HasHeader(UnsupportedHeader), 'No Unsupported header');
  CheckEquals(Self.Invite.FirstHeader(RequireHeader).Value,
              Response.FirstHeader(UnsupportedHeader).Value,
              'Unexpected Unsupported header value');
end;

procedure TestTIdSipAbstractCore.TestRejectUnknownScheme;
var
  Response: TIdSipResponse;
begin
  Self.MarkSentResponseCount;

  Self.Invite.RequestUri.URI := 'tel://1';
  Self.ReceiveInvite;

  CheckResponseSent('No response sent');

  Response := Self.LastSentResponse;
  CheckEquals(SIPUnsupportedURIScheme, Response.StatusCode, 'Status-Code');
end;

procedure TestTIdSipAbstractCore.TestRejectUnsupportedMethod;
var
  Response: TIdSipResponse;
begin
  Self.Invite.Method := MethodRegister;
  Self.Invite.CSeq.Method := Self.Invite.Method;

  Self.MarkSentResponseCount;

  Self.ReceiveInvite;

  CheckResponseSent('No response sent');

  Response := Self.LastSentResponse;
  CheckEquals(SIPNotImplemented,
              Response.StatusCode,
              'Unexpected response');
  Check(Response.HasHeader(AllowHeader),
        'Allow header is mandatory. cf. RFC 3261 section 8.2.1');

  CheckCommaSeparatedHeaders(Self.Core.KnownMethods,
                             Response.FirstHeader(AllowHeader),
                             'Allow header');
end;

procedure TestTIdSipAbstractCore.TestRejectUnsupportedSipVersion;
var
  Response: TIdSipResponse;
begin
  Self.MarkSentResponseCount;
  Self.Invite.SIPVersion := 'SIP/1.0';

  Self.ReceiveInvite;

  CheckEquals(Self.ResponseCount + 2, // Trying + reject
              Self.SentResponseCount,
              'No response sent');

  Response := Self.LastSentResponse;
  CheckEquals(SIPSIPVersionNotSupported,
              Response.StatusCode,
              'Status-Code');
end;

procedure TestTIdSipAbstractCore.TestRemoveObserver;
var
  L1, L2: TIdObserverListener;
begin
  L1 := TIdObserverListener.Create;
  try
    L2 := TIdObserverListener.Create;
    try
      Self.Core.AddObserver(L1);
      Self.Core.AddObserver(L2);
      Self.Core.RemoveObserver(L2);

      Self.ReceiveInvite;

      Check(L1.Changed and not L2.Changed,
            'Listener notified, hence not removed');
    finally
      L2.Free
    end;
  finally
    L1.Free;
  end;
end;

procedure TestTIdSipAbstractCore.TestScheduleEvent;
var
  EventCount: Integer;
begin
  EventCount := Self.DebugTimer.EventCount;
  Self.Core.ScheduleEvent(Self.ScheduledEvent, 50, Self.Invite.Copy);
  Check(EventCount < DebugTimer.EventCount,
        'Event not scheduled');
end;

//******************************************************************************
//* TIdSipNullAction                                                           *
//******************************************************************************
//* TIdSipNullAction Public methods ********************************************

class function TIdSipNullAction.Method: String;
begin
  Result := '';
end;

//* TIdSipNullAction Protected methods *****************************************

function TIdSipNullAction.CreateNewAttempt: TIdSipRequest;
begin
  Result := nil;
end;

//******************************************************************************
//* TestTIdSipActions                                                          *
//******************************************************************************
//* TestTIdSipActions Public methods *******************************************

procedure TestTIdSipActions.SetUp;
begin
  inherited SetUp;

  Self.Actions := TIdSipActions.Create;
  Self.Options := TIdSipRequest.Create;
  Self.Options.Assign(Self.Invite);
  Self.Options.Method := MethodOptions;

  Self.ActionProcUsed      := '';
  Self.DidntFindActionName := 'DidntFindAction';
  Self.FoundActionName     := 'FoundActionName';
end;

procedure TestTIdSipActions.TearDown;
begin
  Self.Options.Free;
  Self.Actions.Free;

  inherited TearDown;
end;

//* TestTIdSipActions Published methods ****************************************

procedure TestTIdSipActions.TestActionCount;
var
  I: Integer;
begin
  for I := 1 to 5 do begin
    Self.Actions.Add(TIdSipNullAction.Create(Self.Core));
    CheckEquals(I, Self.Actions.Count, 'Action not added');
  end;
end;

procedure TestTIdSipActions.TestAddActionNotifiesObservers;
var
  L1: TIdObserverListener;
begin
  L1 := TIdObserverListener.Create;
  try
    Self.Actions.AddObserver(L1);

    Self.Actions.Add(TIdSipInboundInvite.CreateInbound(Self.Core, Self.Invite, false));

    Check(L1.Changed, 'L1 not notified');
  finally
    Self.Actions.RemoveObserver(L1);
    L1.Free;
  end;
end;

procedure TestTIdSipActions.TestAddObserver;
var
  L1, L2: TIdObserverListener;
begin
  L1 := TIdObserverListener.Create;
  try
    L2 := TIdObserverListener.Create;
    try
      Self.Actions.AddObserver(L1);
      Self.Actions.AddObserver(L2);

      Self.Actions.Add(TIdSipInboundInvite.CreateInbound(Self.Core, Self.Invite, false));

      Check(L1.Changed, 'L1 not notified, thus not added');
      Check(L2.Changed, 'L2 not notified, thus not added');
    finally
      Self.Actions.RemoveObserver(L2);
      L2.Free;
    end;
  finally
    Self.Actions.RemoveObserver(L1);
    L1.Free;
  end;
end;

procedure TestTIdSipActions.TestCleanOutTerminatedActions;
var
  A:           TIdSipAction;
  ActionCount: Integer;
  O:           TIdObserverListener;
begin
  A := TIdSipNullAction.Create(Self.Core);
  Self.Actions.Add(A);

  ActionCount := Self.Actions.Count;
  A.Terminate;

  O := TIdObserverListener.Create;
  try
    Self.Actions.AddObserver(O);

    Self.Actions.CleanOutTerminatedActions;

    Check(Self.Actions.Count < ActionCount,
          'Terminated action not destroyed');
    Check(O.Changed, 'Observers not notified of change');
  finally
    Self.Actions.RemoveObserver(O);
    O.Free;
  end;
end;

procedure TestTIdSipActions.TestFindActionAndPerformBlock;
var
  A:      TIdSipAction;
  Finder: TIdSipActionFinder;
begin
  Self.Actions.Add(TIdSipInboundOptions.CreateInbound(Self.Core, Self.Options, false));
  A := Self.Actions.Add(TIdSipInboundInvite.CreateInbound(Self.Core, Self.Invite, false));
  Self.Actions.Add(TIdSipOutboundOptions.Create(Self.Core));

  Finder := TIdSipActionFinder.Create;
  try
    Self.Actions.FindActionAndPerform(A.InitialRequest, Finder);

    Check(Finder.Action = A, 'Wrong action found');
  finally
    Finder.Free;
  end;
end;

procedure TestTIdSipActions.TestFindActionAndPerformBlockNoActions;
var
  Finder: TIdSipActionFinder;
begin
  Finder := TIdSipActionFinder.Create;
  try
    Self.Actions.FindActionAndPerform(Self.Options, Finder);

    Check(not Assigned(Finder.Action), 'An action found in an empty list');
  finally
    Finder.Free;
  end;
end;

procedure TestTIdSipActions.TestFindActionAndPerformBlockNoMatch;
var
  Finder: TIdSipActionFinder;
begin
  Self.Actions.Add(TIdSipInboundInvite.CreateInbound(Self.Core, Self.Invite, false));

  Finder := TIdSipActionFinder.Create;
  try
    Self.Actions.FindActionAndPerform(Self.Options, Finder);

    Check(not Assigned(Finder.Action), 'An action found');
  finally
    Finder.Free;
  end;
end;

procedure TestTIdSipActions.TestFindActionAndPerformOrBlock;
var
  A:      TIdSipAction;
  Finder: TIdSipActionFinder;
  Switch: TIdSipActionSwitch;
begin
  Self.Actions.Add(TIdSipInboundOptions.CreateInbound(Self.Core, Self.Options, false));
  A := Self.Actions.Add(TIdSipInboundInvite.CreateInbound(Self.Core, Self.Invite, false));
  Self.Actions.Add(TIdSipOutboundOptions.Create(Self.Core));

  Finder := TIdSipActionFinder.Create;
  try
    Switch := TIdSipActionSwitch.Create;
    try
      Self.Actions.FindActionAndPerformOr(A.InitialRequest,
                                          Finder,
                                          Switch);

      Check(Assigned(Finder.Action), 'Didn''t find action');
      Check(not Switch.Executed, 'Alternative block executed');
    finally
      Switch.Free;
    end;
  finally
    Finder.Free;
  end;
end;

procedure TestTIdSipActions.TestFindActionAndPerformOrBlockNoMatch;
var
  Finder: TIdSipActionFinder;
  Switch: TIdSipActionSwitch;
begin
  Self.Actions.Add(TIdSipInboundInvite.CreateInbound(Self.Core, Self.Invite, false));

  Finder := TIdSipActionFinder.Create;
  try
    Switch := TIdSipActionSwitch.Create;
    try
      Self.Actions.FindActionAndPerformOr(Self.Options,
                                          Finder,
                                          Switch);

      Check(not Assigned(Finder.Action), 'Found action');
      Check(Switch.Executed, 'Alternative block didn''t execute');
    finally
      Switch.Free;
    end;
  finally
    Finder.Free;
  end;
end;

procedure TestTIdSipActions.TestInviteCount;
begin
  CheckEquals(0, Self.Actions.InviteCount, 'No messages received');

  Self.Actions.Add(TIdSipInboundInvite.CreateInbound(Self.Core, Self.Invite, false));
  CheckEquals(1, Self.Actions.InviteCount, 'One INVITE');

  Self.Actions.Add(TIdSipInboundOptions.CreateInbound(Self.Core, Self.Options, false));
  CheckEquals(1, Self.Actions.InviteCount, 'One INVITE, one OPTIONS');

  Self.Actions.Add(TIdSipOutboundInvite.Create(Self.Core));
  CheckEquals(2, Self.Actions.InviteCount, 'Two INVITEs, one OPTIONS');

  Self.Actions.Add(TIdSipOutboundSession.Create(Self.Core));
  CheckEquals(2,
              Self.Actions.InviteCount,
              'Two INVITEs, one OPTIONS, and a Session');
end;

procedure TestTIdSipActions.TestRemoveObserver;
var
  L1, L2: TIdObserverListener;
begin
  L1 := TIdObserverListener.Create;
  try
    L2 := TIdObserverListener.Create;
    try
      Self.Actions.AddObserver(L1);
      Self.Actions.AddObserver(L2);
      Self.Actions.RemoveObserver(L1);

      Self.Actions.Add(TIdSipInboundInvite.CreateInbound(Self.Core, Self.Invite, false));

      Check(not L1.Changed, 'L1 notified, thus not removed');
      Check(L2.Changed, 'L2 not notified, thus not added');
    finally
      Self.Actions.RemoveObserver(L2);
      L2.Free;
    end;
  finally
    Self.Actions.RemoveObserver(L1);
    L1.Free;
  end;
end;

procedure TestTIdSipActions.TestTerminateAllActions;
begin
  // We don't add INVITEs here because INVITEs need additional events to
  // properly terminate: an INVITE needs to wait for a final response, etc.
  Self.Actions.Add(TIdSipInboundOptions.CreateInbound(Self.Core, Self.Options, false));
  Self.Actions.Add(TIdSipOutboundRegistrationQuery.Create(Self.Core));
  Self.Actions.Add(TIdSipOutboundRegister.Create(Self.Core));

  Self.Actions.TerminateAllActions;
  Self.Actions.CleanOutTerminatedActions;
  CheckEquals(0,
              Self.Actions.Count,
              'Actions container didn''t terminate all actions');
end;

//******************************************************************************
//* TestLocation                                                               *
//******************************************************************************
//* TestLocation Public methods ************************************************

procedure TestLocation.SetUp;
begin
  inherited SetUp;

  Self.InviteMimeType := '';
  Self.InviteOffer    := '';
  Self.NetworkFailure := false;
  Self.TransportParam := SctpTransport;
end;

//* TestLocation Private methods ***********************************************

function TestLocation.CreateAction: TIdSipOutboundInitialInvite;
begin
  Result := Self.Core.AddOutboundAction(TIdSipOutboundInitialInvite) as TIdSipOutboundInitialInvite;
  Result.Destination := Self.Destination;
  Result.MimeType    := Self.InviteMimeType;
  Result.Offer       := Self.InviteOffer;
  Result.AddListener(Self);
  Result.Send;
end;

procedure TestLocation.OnAuthenticationChallenge(Action: TIdSipAction;
                                                 Response: TIdSipResponse);
begin
end;

procedure TestLocation.OnCallProgress(InviteAgent: TIdSipOutboundInvite;
                                      Response: TIdSipResponse);
begin
end;

procedure TestLocation.OnFailure(InviteAgent: TIdSipOutboundInvite;
                                 Response: TIdSipResponse;
                                 const Reason: String);
begin
end;

procedure TestLocation.OnDialogEstablished(InviteAgent: TIdSipOutboundInvite;
                                           NewDialog: TIdSipDialog);
begin
end;

procedure TestLocation.OnNetworkFailure(Action: TIdSipAction;
                                        ErrorCode: Cardinal;
                                        const Reason: String);
begin
  Self.NetworkFailure := true;
end;

procedure TestLocation.OnRedirect(InviteAgent: TIdSipOutboundInvite;
                                  Redirect: TIdSipResponse);
begin
end;

procedure TestLocation.OnSuccess(InviteAgent: TIdSipOutboundInvite;
                                 Response: TIdSipResponse);
begin
end;

//* TestLocation Published methods *********************************************

procedure TestLocation.TestAllLocationsFail;
var
  Locations: TIdSipLocations;
begin
  // SRV records point to Self.Destination.Address.Host;
  // Self.Destination.Address.Host resolves to two A records.

  Self.Locator.AddSRV(Self.Destination.Address.Host,
                      SrvTcpPrefix,
                      0,
                      0,
                      5060,
                      Self.Destination.Address.Host);
  Self.Locator.AddA   (Self.Destination.Address.Host, '127.0.0.1');
  Self.Locator.AddAAAA(Self.Destination.Address.Host, '::1');

  Self.Dispatcher.Transport.FailWith := EIdConnectTimeout;
  Self.MarkSentRequestCount;
  Self.CreateAction;

  Locations := TIdSipLocations.Create;
  try
    Self.Locator.FindServersFor(Self.Destination.Address, Locations);

    // Locations.Count >= 0, so the typecast is safe.
    CheckEquals(Self.RequestCount + Cardinal(Locations.Count),
                Self.SentRequestCount,
                'Number of requests sent');
  finally
    Locations.Free;
  end;

  Check(Self.NetworkFailure,
        'No notification of failure after all locations attempted');
end;

procedure TestLocation.TestLooseRoutingProxy;
const
  ProxyAAAARecord = '::1';
  ProxyHost       = 'gw1.leo-ix.net';
  ProxyTransport  = SctpTransport;
  ProxyUri        = 'sip:' + ProxyHost + ';lr';
var
  RequestUriTransport: String;
begin
  RequestUriTransport := Self.Invite.LastHop.Transport;

  Self.Core.Proxy.Uri := ProxyUri;
  Self.Core.HasProxy  := true;

  Self.Locator.AddSRV(ProxyHost, SrvSctpPrefix, 0, 0, 5060, ProxyHost);
  Self.Locator.AddAAAA(ProxyHost, ProxyAAAARecord);

  Self.Locator.AddSRV(Self.Destination.Address.Host, SrvTcpPrefix, 0, 0,
                      5060, Self.Destination.Address.Host);

  Self.Locator.AddA(Self.Destination.Address.Host, '127.0.0.1');

  Self.MarkSentRequestCount;
  Self.CreateAction;
  CheckRequestSent('No request sent');

  CheckEquals(ProxyTransport,
              Self.LastSentRequest.LastHop.Transport,
              'Wrong transport means UA gave Locator wrong URI');
end;

procedure TestLocation.TestStrictRoutingProxy;
const
  ProxyUri = 'sip:127.0.0.1;transport=' + TransportParamSCTP;
var
  RequestUriTransport: String;
begin
  RequestUriTransport := Self.Invite.LastHop.Transport;

  Self.Core.Proxy.Uri := ProxyUri;
  Self.Core.HasProxy  := true;

  Self.Destination.Address.Transport := TransportParamTCP;

  Self.MarkSentRequestCount;
  Self.CreateAction;
  CheckRequestSent('No request sent');

  CheckEquals(RequestUriTransport,
              Self.LastSentRequest.LastHop.Transport,
              'Wrong transport means UA gave Locator wrong URI');
end;

procedure TestLocation.TestUseCorrectTransport;
const
  CorrectTransport = SctpTransport;
var
  Action: TIdSipAction;
  Domain: String;
begin
  Domain := Self.Destination.Address.Host;

  // NAPTR record points to SCTP SRV record whose target resolves to the A
  // record.
  Self.Locator.AddNAPTR(Domain, 0, 0, NaptrDefaultFlags, NaptrSctpService, SrvSctpPrefix + Domain);
  Self.Locator.AddSRV(Domain, SrvSctpPrefix, 0, 0, 5060, Domain);
  Self.Locator.AddSRV(Domain, SrvTcpPrefix,  1, 0, 5060, Domain);

  Self.MarkSentRequestCount;
  Action := Self.CreateAction;

  CheckRequestSent('No request sent');
  CheckEquals(CorrectTransport,
              Self.LastSentRequest.LastHop.Transport,
              'Incorrect transport');
  Check(Self.LastSentRequest.Equals(Action.InitialRequest),
        'Action''s InitialRequest not updated to the latest attempt');
end;

procedure TestLocation.TestUseTransportParam;
begin
  Self.Destination.Address.Transport := Self.TransportParam;

  Self.MarkSentRequestCount;
  Self.CreateAction;
  Self.CheckRequestSent('No request sent');

  CheckEquals(SctpTransport,
              Self.LastSentRequest.LastHop.Transport,
              'INVITE didn''t use transport param');
end;

procedure TestLocation.TestUseUdpByDefault;
begin
  Self.MarkSentRequestCount;
  Self.CreateAction;
  Self.CheckRequestSent('No request sent');

  CheckEquals(UdpTransport,
              Self.LastSentRequest.LastHop.Transport,
              'INVITE didn''t use UDP by default');
end;

procedure TestLocation.TestVeryLargeMessagesUseAReliableTransport;
begin
  Self.InviteOffer    := TIdSipTestResources.VeryLargeSDP('localhost');
  Self.InviteMimeType := SdpMimeType;

  Self.MarkSentRequestCount;
  Self.CreateAction;
  Self.CheckRequestSent('No request sent');

  CheckEquals(TcpTransport,
              Self.LastSentRequest.LastHop.Transport,
              'INVITE didn''t use a reliable transport despite the large size '
            + 'of the message');
end;

//******************************************************************************
//* TestTIdSipMessageModule                                                    *
//******************************************************************************
//* TestTIdSipMessageModule Published methods **********************************

procedure TestTIdSipMessageModule.TestRejectNonInviteWithReplacesHeader;
var
  Request: TIdSipRequest;
begin
  Request := Self.Core.CreateRequest(MethodRegister, Self.Destination);
  try
    Request.AddHeader(ReplacesHeader).Value := '1;from-tag=2;to-tag=3';

    Self.MarkSentResponseCount;
    Self.ReceiveRequest(Request);
    CheckResponseSent('No response sent');
    CheckEquals(SIPBadRequest,
                Self.LastSentResponse.StatusCode,
                'Unexpected response sent');
  finally
    Request.Free;
  end;
end;

//******************************************************************************
//* TestTIdSipNullMessageModule                                                *
//******************************************************************************
//* TestTIdSipNullMessageModule Public methods *********************************

procedure TestTIdSipNullMessageModule.SetUp;
begin
  inherited SetUp;

  Self.Module := Self.Core.ModuleFor('No such method');
end;

//* TestTIdSipNullMessageModule Published methods ******************************

procedure TestTIdSipNullMessageModule.TestIsNull;
begin
  CheckEquals(TIdSipNullMessageModule.ClassName,
              Self.Module.ClassName,
              'Wrong module');
  Check(Self.Module.IsNull,
        'Null message module not marked as null');
end;

//******************************************************************************
//* TestTIdSipOptionsModule                                                    *
//******************************************************************************
//* TestTIdSipOptionsModule Published ******************************************

procedure TestTIdSipOptionsModule.TestReceiveOptions;
var
  Options:  TIdSipRequest;
  Response: TIdSipResponse;
begin
  Options := TIdSipRequest.Create;
  try
    Options.Method := MethodOptions;
    Options.RequestUri.Uri := 'sip:franks@192.168.0.254';
    Options.AddHeader(ViaHeaderFull).Value  := 'SIP/2.0/UDP roke.angband.za.org:3442';
    Options.From.Value := '<sip:sipsak@roke.angband.za.org:3442>';
    Options.ToHeader.Value := '<sip:franks@192.168.0.254>';
    Options.CallID := '1631106896@roke.angband.za.org';
    Options.CSeq.Value := '1 OPTIONS';
    Options.AddHeader(ContactHeaderFull).Value := '<sip:sipsak@roke.angband.za.org:3442>';
    Options.ContentLength := 0;
    Options.MaxForwards := 0;
    Options.AddHeader(UserAgentHeader).Value := 'sipsak v0.8.1';

    Self.Locator.AddA(Options.LastHop.SentBy, '127.0.0.1');

    Self.ReceiveRequest(Options);

    Response := Self.LastSentResponse;
    CheckEquals(SIPOK,
                Response.StatusCode,
                'We should accept all OPTIONS');
  finally
    Options.Free;
  end;
end;

procedure TestTIdSipOptionsModule.TestRejectOptionsWithReplacesHeader;
var
  Options: TIdSipRequest;
begin
  Options := Self.Core.CreateOptions(Self.Destination);
  try
    Options.AddHeader(ReplacesHeader).Value := '1;from-tag=2;to-tag=3';

    Self.MarkSentResponseCount;
    Self.ReceiveRequest(Options);
    CheckResponseSent('No response sent');
    CheckEquals(SIPBadRequest,
                Self.LastSentResponse.StatusCode,
                'Unexpected response');
  finally
    Options.Free;
  end;
end;

//******************************************************************************
//* TestTIdSipInboundOptions                                                   *
//******************************************************************************
//* TestTIdSipInboundOptions Public methods ************************************

procedure TestTIdSipInboundOptions.SetUp;
begin
  inherited SetUp;

  Self.Invite.Method := MethodOptions;
  Self.Options := TIdSipInboundOptions.CreateInbound(Self.Core,
                                                     Self.Invite,
                                                     false);
end;

procedure TestTIdSipInboundOptions.TearDown;
begin
  Self.Options.Free;

  inherited TearDown;
end;

//* TestTIdSipInboundOptions Published methods *********************************

procedure TestTIdSipInboundOptions.TestIsInbound;
begin
  Check(Self.Options.IsInbound,
        Self.Options.ClassName + ' not marked as inbound');
end;

procedure TestTIdSipInboundOptions.TestIsInvite;
begin
  Check(not Self.Options.IsInvite,
          Self.Options.ClassName + ' marked as a Invite');
end;

procedure TestTIdSipInboundOptions.TestIsOptions;
begin
  Check(Self.Options.IsOptions,
        Self.Options.ClassName + ' not marked as an Options');
end;

procedure TestTIdSipInboundOptions.TestIsRegistration;
begin
  Check(not Self.Options.IsRegistration,
        Self.Options.ClassName + ' marked as a Registration');
end;

procedure TestTIdSipInboundOptions.TestIsSession;
begin
  Check(not Self.Options.IsSession,
        Self.Options.ClassName + ' marked as a Session');
end;

procedure TestTIdSipInboundOptions.TestOptions;
var
  Response: TIdSipResponse;
begin
  Check(Self.SentResponseCount > 0,
        'No response sent');

  Response := Self.LastSentResponse;
  Check(Response.HasHeader(AllowHeader),
        'No Allow header');
  CheckEquals(Self.Core.KnownMethods,
              Response.FirstHeader(AllowHeader).FullValue,
              'Allow header');

  Check(Response.HasHeader(AcceptHeader),
        'No Accept header');
  CheckEquals(Self.Core.AllowedContentTypes,
              Response.FirstHeader(AcceptHeader).FullValue,
              'Accept header');

  Check(Response.HasHeader(AcceptEncodingHeader),
        'No Accept-Encoding header');
  CheckEquals(Self.Core.AllowedEncodings,
              Response.FirstHeader(AcceptEncodingHeader).FullValue,
              'Accept-Encoding header');

  Check(Response.HasHeader(AcceptLanguageHeader),
        'No Accept-Language header');
  CheckEquals(Self.Core.AllowedLanguages,
              Response.FirstHeader(AcceptLanguageHeader).FullValue,
              'Accept-Language header');

  Check(Response.HasHeader(SupportedHeaderFull),
        'No Supported header');
  CheckEquals(Self.Core.AllowedExtensions,
              Response.FirstHeader(SupportedHeaderFull).FullValue,
              'Supported header value');

  Check(Response.HasHeader(ContactHeaderFull),
        'No Contact header');
  Check(Self.Core.Contact.Equals(Response.FirstContact),
        'Contact header value');

  Check(Response.HasHeader(WarningHeader),
        'No Warning header');
  CheckEquals(Self.Core.Hostname,
              Response.FirstWarning.Agent,
              'Warning warn-agent');
end;

procedure TestTIdSipInboundOptions.TestOptionsWhenDoNotDisturb;
var
  NewOptions: TIdSipInboundOptions;
  Response:   TIdSipResponse;
begin
  Self.Core.DoNotDisturb := true;

  Self.MarkSentResponseCount;
  NewOptions := TIdSipInboundOptions.CreateInbound(Self.Core,
                                                   Self.Options.InitialRequest,
                                                   false);
  try
    CheckResponseSent('No response sent');

    Response := Self.LastSentResponse;
    CheckEquals(SIPTemporarilyUnavailable,
                Response.StatusCode,
                'Do Not Disturb');
  finally
    NewOptions.Free;
  end;
end;

//******************************************************************************
//* TestTIdSipOutboundOptions                                                  *
//******************************************************************************
//* TestTIdSipOutboundOptions Public methods ***********************************

procedure TestTIdSipOutboundOptions.SetUp;
begin
  inherited SetUp;

  Self.ReceivedResponse := false;
end;

//* TestTIdSipOutboundOptions Protected methods ********************************

function TestTIdSipOutboundOptions.CreateAction: TIdSipAction;
var
  Options: TIdSipOutboundOptions;
begin
  Options := Self.Core.QueryOptions(Self.Destination);
  Options.AddListener(Self);
  Options.Send;
  Result := Options;
end;

//* TestTIdSipOutboundOptions Private methods **********************************

procedure TestTIdSipOutboundOptions.OnResponse(OptionsAgent: TIdSipOutboundOptions;
                                               Response: TIdSipResponse);
begin
  Self.ReceivedResponse := true;
end;

//* TestTIdSipOutboundOptions Published methods ********************************

procedure TestTIdSipOutboundOptions.TestAddListener;
var
  L1, L2:  TIdSipTestOptionsListener;
  Options: TIdSipOutboundOptions;
begin
  Options := Self.Core.QueryOptions(Self.Core.From);
  Options.Send;

  L1 := TIdSipTestOptionsListener.Create;
  try
    L2 := TIdSipTestOptionsListener.Create;
    try
      Options.AddListener(L1);
      Options.AddListener(L2);

      Self.ReceiveOk(Self.LastSentRequest);

      Check(L1.Response, 'L1 not informed of response');
      Check(L2.Response, 'L2 not informed of response');
    finally
      L2.Free;
    end;
  finally
    L1.Free;
  end;
end;

procedure TestTIdSipOutboundOptions.TestIsOptions;
var
  Action: TIdSipAction;
begin
  // Self.UA owns the action!
  Action := Self.CreateAction;
  Check(Action.IsOptions,
        Action.ClassName + ' marked as an Options');
end;

procedure TestTIdSipOutboundOptions.TestReceiveResponse;
var
  OptionsCount: Integer;
  StatusCode:   Cardinal;
begin
  for StatusCode := SIPOKResponseClass to SIPGlobalFailureResponseClass do begin
    Self.ReceivedResponse := false;
    Self.CreateAction;

    OptionsCount := Self.Core.OptionsCount;

    Self.ReceiveResponse(StatusCode * 100);

    Check(Self.ReceivedResponse,
          'Listeners not notified of response ' + IntToStr(StatusCode * 100));
    Check(Self.Core.OptionsCount < OptionsCount,
          'OPTIONS action not terminated for ' + IntToStr(StatusCode) + ' response');
  end;
end;

procedure TestTIdSipOutboundOptions.TestRemoveListener;
var
  L1, L2:  TIdSipTestOptionsListener;
  Options: TIdSipOutboundOptions;
begin
  Options := Self.Core.QueryOptions(Self.Core.From);
  Options.Send;

  L1 := TIdSipTestOptionsListener.Create;
  try
    L2 := TIdSipTestOptionsListener.Create;
    try
      Options.AddListener(L1);
      Options.AddListener(L2);
      Options.RemoveListener(L2);

      Self.ReceiveOk(Self.LastSentRequest);

      Check(L1.Response,
            'First listener not notified');
      Check(not L2.Response,
            'Second listener erroneously notified, ergo not removed');
    finally
      L2.Free
    end;
  finally
    L1.Free;
  end;
end;

//******************************************************************************
//* TestTIdSipActionAuthenticationChallengeMethod                              *
//******************************************************************************
//* TestTIdSipActionAuthenticationChallengeMethod Public methods ***************

procedure TestTIdSipActionAuthenticationChallengeMethod.SetUp;
var
  Nowhere: TIdSipAddressHeader;
begin
  inherited SetUp;

  Nowhere := TIdSipAddressHeader.Create;
  try
    Self.Action := Self.UA.QueryOptions(Nowhere);
  finally
    Nowhere.Free;
  end;

  Self.Listener := TIdSipMockListener.Create;

  Self.Method := TIdSipActionAuthenticationChallengeMethod.Create;
  Self.Method.ActionAgent := Self.Action;
  Self.Method.Challenge   := Self.Response;
end;

procedure TestTIdSipActionAuthenticationChallengeMethod.TearDown;
begin
  Self.Method.Free;
  Self.Listener.Free;

  inherited TearDown;
end;

//* TestTIdSipActionAuthenticationChallengeMethod Published methods ************

procedure TestTIdSipActionAuthenticationChallengeMethod.TestRun;
begin
  Self.Method.Run(Self.Listener);

  Check(Self.Listener.AuthenticationChallenged,
        'Listener not notified');
  Check(Self.Action = Self.Listener.ActionParam,
        'Action param');
  Check(Self.Response = Self.Listener.ResponseParam,
        'Response param');
end;

//******************************************************************************
//* TestTIdSipActionNetworkFailureMethod                                       *
//******************************************************************************
//* TestTIdSipActionNetworkFailureMethod Public methods ************************

procedure TestTIdSipActionNetworkFailureMethod.SetUp;
var
  Nowhere: TIdSipAddressHeader;
begin
  inherited SetUp;

  Nowhere := TIdSipAddressHeader.Create;
  try
    Self.Action := Self.UA.QueryOptions(Nowhere);
  finally
    Nowhere.Free;
  end;

  Self.Listener := TIdSipMockListener.Create;
  Self.Method   := TIdSipActionNetworkFailureMethod.Create;

  Self.ErrorCode := 13;
  Self.Reason    := 'The most random number';

  Self.Method.ActionAgent := Self.Action;
  Self.Method.ErrorCode   := Self.ErrorCode;
  Self.Method.Reason      := Self.Reason;
end;

procedure TestTIdSipActionNetworkFailureMethod.TearDown;
begin
  Self.Method.Free;
  Self.Listener.Free;

  inherited TearDown;
end;

//* TestTIdSipActionNetworkFailureMethod Published methods *********************

procedure TestTIdSipActionNetworkFailureMethod.TestRun;
begin
  Self.Method.Run(Self.Listener);

  Check(Self.Listener.NetworkFailed,
        'Listener not notified');
  Check(Self.Action = Self.Listener.ActionParam,
        'Action param');
  CheckEquals(Self.ErrorCode,
              Self.Listener.ErrorCodeParam,
              'Error code');
  CheckEquals(Self.Reason,
              Self.Listener.ReasonParam,
            'Reason');
end;

//******************************************************************************
//* TestTIdSipOptionsResponseMethod                                            *
//******************************************************************************
//* TestTIdSipOptionsResponseMethod Public methods *****************************

procedure TestTIdSipOptionsResponseMethod.SetUp;
var
  Nowhere: TIdSipAddressHeader;
begin
  inherited SetUp;

  Self.Method := TIdSipOptionsResponseMethod.Create;

  Nowhere := TIdSipAddressHeader.Create;
  try
    Self.Method.Options  := Self.UA.QueryOptions(Nowhere);
    Self.Method.Response := Self.Response;
  finally
    Nowhere.Free;
  end;
end;

procedure TestTIdSipOptionsResponseMethod.TearDown;
begin
  Self.Method.Free;

  inherited TearDown;
end;

//* TestTIdSipOptionsResponseMethod Published methods **************************

procedure TestTIdSipOptionsResponseMethod.TestRun;
var
  Listener: TIdSipTestOptionsListener;
begin
  Listener := TIdSipTestOptionsListener.Create;
  try
    Self.Method.Run(Listener);

    Check(Listener.Response, 'Listener not notified');
    Check(Self.Method.Options = Listener.OptionsAgentParam,
          'OptionsAgent param');
    Check(Self.Method.Response = Listener.ResponseParam,
          'Response param');
  finally
    Listener.Free;
  end;
end;

//******************************************************************************
//* TestTIdSipUserAgentDroppedUnmatchedMessageMethod                           *
//******************************************************************************
//* TestTIdSipUserAgentDroppedUnmatchedMessageMethod Public methods ************

procedure TestTIdSipUserAgentDroppedUnmatchedMessageMethod.SetUp;
begin
  inherited SetUp;

  Self.Receiver := TIdSipMockUdpTransport.Create;
  Self.Response := TIdSipResponse.Create;

  Self.Method := TIdSipUserAgentDroppedUnmatchedMessageMethod.Create;
  Self.Method.Receiver := Self.Receiver;
  Self.Method.Message := Self.Response.Copy;
end;

procedure TestTIdSipUserAgentDroppedUnmatchedMessageMethod.TearDown;
begin
  Self.Method.Free;
  Self.Response.Free;
  Self.Receiver.Free;

  inherited TearDown;
end;

//* TestTIdSipUserAgentDroppedUnmatchedMessageMethod Published methods *********

procedure TestTIdSipUserAgentDroppedUnmatchedMessageMethod.TestRun;
var
  L: TIdSipTestTransactionUserListener;
begin
  L := TIdSipTestTransactionUserListener.Create;
  try
    Self.Method.Run(L);

    Check(L.DroppedUnmatchedMessage, 'Listener not notified');
    Check(Self.Method.Receiver = L.ReceiverParam,
          'Receiver param');
    Check(Self.Method.Message = L.MessageParam,
          'Message param');
    Check(Self.Method.UserAgent = L.AbstractUserAgentParam,
          'UserAgent param');
  finally
    L.Free;
  end;
end;

initialization
  RegisterTest('Transaction User Cores', Suite);
end.
