unit IdSipCore;

// Some overarching principles followed in this implementation of a SIP/2.0
// (RFC 3261) stack:
// * The lifetime of all objects is manually managed. Objects that implement
//   interfaces are NOT reference counted.
// * Value Objects are used when possible.
// * If an object A receives some object B that it is expected to store as data
//   then A must store a COPY of B. Typical objects are: TIdURI, TIdSipDialogID,
//   TIdSipMessage.
// * Each layer is aware of the layers beneath it. We try to make each layer
//   aware of ONLY the layer immediately below it, but that's not always
//   possible.
// * Events or Listeners are used to propogate messages up the stack, and method
//   calls to propogate messages down the stack. Preference is given to Listeners
//   as they're more flexible.
// * Typecasting is avoided as much as possible by using polymorphism and, in
//   certain situations where polymorphism can't cut it, the Visitor pattern.
// * TObjectLists always manage the lifetime of the objects they contain. Except
//   in the case of Transports in the Dispatcher.

interface

uses
  Classes, Contnrs, IdSipDialog, IdException, IdSipHeaders,
  IdSipInterfacedObject, IdSipMessage, IdSipTransaction, IdSipTransport, IdUri,
  SyncObjs;

type
  TIdSipSession = class;
  TIdSipSessionEvent = procedure(Sender: TObject; const Session: TIdSipSession) of object;

  // I am the protocol of things that listen for Sessions:
  // * OnNewSession tells us that a session creation is possible - we may
  //   refuse or allow the session.
  // * OnSessionEstablished tells us when a session is fully up and running.
  // * OnSessionEnded lets us clean up.
  IIdSipSessionListener = interface
    ['{59B3C476-D3CA-4C5E-AA2B-2BB587A5A716}']
    procedure OnNewSession(const Session: TIdSipSession);
    procedure OnSessionEstablished(const Session: TIdSipSession);
    procedure OnSessionEnded(const Session: TIdSipSession);
  end;

  TIdSipAbstractCore = class(TIdSipInterfacedObject,
                             IIdSipMessageListener,
                             IIdSipTransactionListener)
  private
    fDispatcher:        TIdSipTransactionDispatcher;
    fHostName:          String;
    fOnTransactionFail: TIdSipFailEvent;
    procedure OnReceiveRequest(const Request: TIdSipRequest); overload;
    procedure OnReceiveResponse(const Response: TIdSipResponse); overload;
    procedure OnFail(const Transaction: TIdSipTransaction;
                     const Reason: String);
    procedure OnReceiveRequest(const Request: TIdSipRequest;
                               const Transaction: TIdSipTransaction;
                               const Transport: TIdSipTransport); overload;
    procedure OnReceiveResponse(const Response: TIdSipResponse;
                                const Transaction: TIdSipTransaction;
                                const Transport: TIdSipTransport); overload;
    procedure OnTerminated(const Transaction: TIdSipTransaction);
    procedure SetDispatcher(const Value: TIdSipTransactionDispatcher);
  public
    constructor Create; virtual;

    function  CreateRequest(const Dest: TIdSipToHeader): TIdSipRequest; virtual; abstract;
    function  CreateResponse(const Request: TIdSipRequest;
                             const ResponseCode: Cardinal): TIdSipResponse; virtual; abstract;
    procedure ReceiveRequest(const Request: TIdSipRequest;
                             const Transaction: TIdSipTransaction;
                             const Transport: TIdSipTransport); virtual; abstract;
    procedure ReceiveResponse(const Response: TIdSipResponse;
                              const Transaction: TIdSipTransaction;
                              const Transport: TIdSipTransport); virtual; abstract;
    function  NextCallID: String;

    property Dispatcher:        TIdSipTransactionDispatcher read fDispatcher write SetDispatcher;
    property HostName:          String                      read fHostName write fHostName;
    property OnTransactionFail: TIdSipFailEvent             read fOnTransactionFail write fOnTransactionFail;
  end;

  // I am a User Agent. I (usually) represent a human being in the SIP network.
  // It is my responsibility to:
  // * inform any listeners when new sessions are established, modified or ended;
  // * allow my users to accept incoming "calls", make outgoing "calls"
  TIdSipUserAgentCore = class(TIdSipAbstractCore)
  private
    BranchLock:           TCriticalSection;
    fAllowedLanguageList: TStrings;
    fAllowedMethodList:   TStrings;
    fAllowedSchemeList:   TStrings;
    fContact:             TIdSipContactHeader;
    fFrom:                TIdSipFromHeader;
    fLastBranch:          Cardinal;
    fUserAgentName:       String;
    SessionLock:          TCriticalSection;
    Sessions:             TObjectList;

    function  AddSession(const Invite: TIdSipRequest;
                         const Transaction: TIdSipTransaction): TIdSipSession; overload;
    function  AddSession(const Invite: TIdSipRequest): TIdSipSession; overload;
    function  GetContact: TIdSipContactHeader;
    function  GetFrom: TIdSipFromHeader;
    procedure RejectBadRequest(const Request: TIdSipRequest;
                               const Reason: String;
                               const Transaction: TIdSipTransaction);
    procedure RejectRequestBadExtension(const Request: TIdSipRequest;
                                        const Transaction: TIdSipTransaction);
    procedure RejectRequestMethodNotAllowed(const Request: TIdSipRequest;
                                            const Transaction: TIdSipTransaction);
    procedure RejectRequestUnknownContentEncoding(const Request: TIdSipRequest;
                                                  const Transaction: TIdSipTransaction);
    procedure RejectRequestUnknownContentLanguage(const Request: TIdSipRequest;
                                                  const Transaction: TIdSipTransaction);
    procedure RejectRequestUnknownContentType(const Request: TIdSipRequest;
                                              const Transaction: TIdSipTransaction);
    procedure ResetLastBranch;
    procedure SendRinging(const Request: TIdSipRequest;
                          const Transaction: TIdSipTransaction);
    procedure SetContact(const Value: TIdSipContactHeader);
    procedure SetFrom(const Value: TIdSipFromHeader);

    property AllowedLanguageList: TStrings read fAllowedLanguageList;
    property AllowedMethodList:   TStrings read fAllowedMethodList;
    property AllowedSchemeList:   TStrings read fAllowedSchemeList;
  public
    constructor Create; override;
    destructor  Destroy; override;

    function  AcceptCall(const Request: TIdSipRequest;
                         const Transaction: TIdSipTransaction;
                         const Transport: TIdSipTransport): TIdSipSession;
    procedure AddAllowedLanguage(const LanguageID: String);
    procedure AddAllowedMethod(const Method: String);
    procedure AddAllowedScheme(const Scheme: String);
    function  AllowedLanguages: String;
    function  AllowedMethods: String;
    function  AllowedSchemes: String;
    function  Call(const Dest: TIdSipToHeader): TIdSipSession;
    function  CreateInvite(const Dest: TIdSipToHeader): TIdSipRequest;
    function  CreateRequest(const Dest: TIdSipToHeader): TIdSipRequest; override;
    function  CreateResponse(const Request: TIdSipRequest;
                             const ResponseCode: Cardinal): TIdSipResponse; override;
    procedure ReceiveRequest(const Request: TIdSipRequest;
                             const Transaction: TIdSipTransaction;
                             const Transport: TIdSipTransport); override;
    procedure ReceiveResponse(const Response: TIdSipResponse;
                              const Transaction: TIdSipTransaction;
                              const Transport: TIdSipTransport); override;
    function  HasUnknownContentLanguage(const Request: TIdSipRequest): Boolean;
    function  HasUnknownContentEncoding(const Request: TIdSipRequest): Boolean;
    function  HasUnknownContentType(const Request: TIdSipRequest): Boolean;
    function  IsExtensionAllowed(const Extension: String): Boolean;
    function  IsMethodAllowed(const Method: String): Boolean;
    function  IsSchemeAllowed(const Scheme: String): Boolean;
    function  NextBranch: String;
    function  NextTag: String;
    procedure RejectRequest(const Request: TIdSipRequest;
                            const Reason: Cardinal;
                            const Transaction: TIdSipTransaction;
                            const Transport: TIdSipTransport);
    function  SessionCount: Integer;

    property Contact:       TIdSipContactHeader read GetContact write SetContact;
    property From:          TIdSipFromHeader    read GetFrom write SetFrom;
    property UserAgentName: String              read fUserAgentName write fUserAgentName;
  end;

  TIdSipSession = class(TIdSipInterfacedObject, IIdSipTransactionListener)
  private
    fCore:   TIdSipUserAgentCore;
    fDialog: TIdSipDialog;
    fInvite: TIdSipRequest;

    procedure OnFail(const Transaction: TIdSipTransaction;
                     const Reason: String);
    procedure OnReceiveRequest(const Request: TIdSipRequest;
                               const Transaction: TIdSipTransaction;
                               const Transport: TIdSipTransport);
    procedure OnReceiveResponse(const Response: TIdSipResponse;
                                const Transaction: TIdSipTransaction;
                                const Transport: TIdSipTransport);
    procedure OnTerminated(const Transaction: TIdSipTransaction);

    property Core:   TIdSipUserAgentCore read fCore;
    property Invite: TIdSipRequest       read fInvite;
  public
    constructor Create(const UA: TIdSipUserAgentCore;
                       const Invite: TIdSipRequest); overload;
    constructor Create(const UA: TIdSipUserAgentCore;
                       const Invite: TIdSipRequest;
                       const InitialTransaction: TIdSipTransaction); overload;
    destructor  Destroy; override;

    procedure AcceptCall(const Invite: TIdSipRequest;
                         const Transport: TIdSipTransport);
    procedure Cancel;
    procedure HangUp;
    procedure Modify;

    property Dialog: TIdSipDialog read fDialog;
  end;

  EIdSipBadSyntax = class(EIdException);

const
  MissingContactHeader = 'Missing Contact Header';

implementation

uses
  IdGlobal, IdSipConsts, IdSipDialogID, IdSipRandom, IdStack, SysUtils;

//******************************************************************************
//* TIdSipAbstractCore                                                         *
//******************************************************************************
//* TIdSipAbstractCore Public methods ******************************************

constructor TIdSipAbstractCore.Create;
begin
end;

function TIdSipAbstractCore.NextCallID: String;
begin
  Result := IntToHex(TIdSipRandomNumber.Next, 8) + '@' + Self.HostName;
end;

//* TIdSipAbstractCore Private methods *****************************************

procedure TIdSipAbstractCore.OnReceiveRequest(const Request: TIdSipRequest);
begin
end;

procedure TIdSipAbstractCore.OnReceiveResponse(const Response: TIdSipResponse);
begin
end;

procedure TIdSipAbstractCore.OnFail(const Transaction: TIdSipTransaction;
                                    const Reason: String);
begin
  if Assigned(Self.OnTransactionFail) then
    Self.OnTransactionFail(Self, Reason);
end;

procedure TIdSipAbstractCore.OnReceiveRequest(const Request: TIdSipRequest;
                                              const Transaction: TIdSipTransaction;
                                              const Transport: TIdSipTransport);
begin
  Self.ReceiveRequest(Request, Transaction, Transport);
end;

procedure TIdSipAbstractCore.OnReceiveResponse(const Response: TIdSipResponse;
                                               const Transaction: TIdSipTransaction;
                                               const Transport: TIdSipTransport);
begin
  Self.ReceiveResponse(Response, Transaction, Transport);
end;

procedure TIdSipAbstractCore.OnTerminated(const Transaction: TIdSipTransaction);
begin
end;

procedure TIdSipAbstractCore.SetDispatcher(const Value: TIdSipTransactionDispatcher);
begin
  fDispatcher := Value;

  fDispatcher.AddMessageListener(Self);
  fDispatcher.AddTransactionListener(Self);
end;

//******************************************************************************
//* TIdSipUserAgentCore                                                        *
//******************************************************************************
//* TIdSipUserAgentCore Public methods *****************************************

constructor TIdSipUserAgentCore.Create;
begin
  inherited Create;

  Self.BranchLock  := TCriticalSection.Create;
  Self.SessionLock := TCriticalSection.Create;
  Self.Sessions    := TObjectList.Create;

  Self.ResetLastBranch;
  Self.fAllowedLanguageList := TStringList.Create;
  Self.fAllowedMethodList := TStringList.Create;
  Self.fAllowedSchemeList := TStringList.Create;

  Self.AddAllowedMethod(MethodBye);
  Self.AddAllowedMethod(MethodCancel);
  Self.AddAllowedMethod(MethodInvite);

  Self.AddAllowedScheme(SipScheme);

  Self.HostName := 'localhost';
end;

destructor TIdSipUserAgentCore.Destroy;
begin
  Self.AllowedSchemeList.Free;
  Self.AllowedMethodList.Free;
  Self.AllowedLanguageList.Free;
  Self.Contact.Free;
  Self.From.Free;
  Self.Sessions.Free;
  Self.SessionLock.Free;
  Self.BranchLock.Free;

  inherited Destroy;
end;

function TIdSipUserAgentCore.AcceptCall(const Request: TIdSipRequest;
                                        const Transaction: TIdSipTransaction;
                                        const Transport: TIdSipTransport): TIdSipSession;
begin
  Result := Self.AddSession(Request, Transaction);
  Result.AcceptCall(Request, Transport);
end;

procedure TIdSipUserAgentCore.AddAllowedLanguage(const LanguageID: String);
begin
  if (Trim(LanguageID) = '') then
    raise EIdSipBadSyntax.Create('Not a valid language identifier');

  if (Self.AllowedLanguageList.IndexOf(LanguageID) = -1) then
    Self.AllowedLanguageList.Add(LanguageID);
end;

procedure TIdSipUserAgentCore.AddAllowedMethod(const Method: String);
begin
  if not TIdSipParser.IsToken(Method) then
    raise EIdSipBadSyntax.Create('Not a token');

  if (Self.AllowedMethodList.IndexOf(Method) = -1) then
    Self.AllowedMethodList.Add(Method);
end;

procedure TIdSipUserAgentCore.AddAllowedScheme(const Scheme: String);
begin
  if not TIdSipParser.IsScheme(Scheme) then
    raise EIdSipBadSyntax.Create('Not a valid scheme');

  if (Self.AllowedSchemeList.IndexOf(Scheme) = -1) then
    Self.AllowedSchemeList.Add(Scheme);
end;

function TIdSipUserAgentCore.AllowedLanguages: String;
begin
  Result := Self.AllowedLanguageList.CommaText;
end;

function TIdSipUserAgentCore.AllowedMethods: String;
begin
  Result := Self.AllowedMethodList.CommaText;
end;

function TIdSipUserAgentCore.AllowedSchemes: String;
begin
  Result := Self.AllowedSchemeList.CommaText;
end;

function TIdSipUserAgentCore.Call(const Dest: TIdSipToHeader): TIdSipSession;
var
  Invite: TIdSipRequest;
begin
  Invite := Self.CreateInvite(Dest);
  try
    Result := Self.AddSession(Invite);
  finally
    Invite.Free;
  end;
end;

function TIdSipUserAgentCore.CreateInvite(const Dest: TIdSipToHeader): TIdSipRequest;
begin
  Result := CreateRequest(Dest);
  Result.Method := MethodInvite;

  Result.CSeq.Method := MethodInvite;
  Result.CSeq.SequenceNo := 0;
end;

function TIdSipUserAgentCore.CreateRequest(const Dest: TIdSipToHeader): TIdSipRequest;
begin
  Result := TIdSipRequest.Create;
  try
    Result.RequestUri := Dest.Address;

    if Dest.HasSipsUri then
      Self.Contact.Address.Protocol := SipsScheme;

    Result.AddHeader(Self.Contact);
    Result.CallID   := Self.NextCallID;
    Result.From     := Self.From;
    Result.From.Tag := Self.NextTag;
    Result.ToHeader := Dest;

    Result.AddHeader(ViaHeaderFull).Value := SipVersion + '/TCP localhost;branch=' + BranchMagicCookie;
    Result.LastHop.Branch := Self.NextBranch;

    if (Self.UserAgentName <> '') then
      Result.AddHeader(UserAgentHeader).Value := Self.UserAgentName;
  except
    Result.Free;

    raise;
  end;
end;

function TIdSipUserAgentCore.CreateResponse(const Request:      TIdSipRequest;
                                            const ResponseCode: Cardinal): TIdSipResponse;
var
  FirstRR:          TIdSipRecordRouteHeader;
  ReqRecordRoutes:  TIdSipHeadersFilter;
  TimestampHeaders: TIdSipHeadersFilter;
begin
  Result := TIdSipResponse.Create;
  try
    Result.StatusCode := ResponseCode;

    // cf RFC 3261 section 8.2.6.1
    if (Result.StatusCode = SIPTrying) then begin
      TimestampHeaders := TIdSipHeadersFilter.Create(Request.Headers,
                                                     TimestampHeader);
      try
        Result.AddHeaders(TimestampHeaders);
      finally
        TimestampHeaders.Free;
      end;
    end;

    // cf RFC 3261 section 8.2.6.2
    Result.CallID   := Request.CallID;
    Result.CSeq     := Request.CSeq;
    Result.From     := Request.From;
    Result.ToHeader := Request.ToHeader;
    Result.Path     := Request.Path;

    // cf RFC 3261 section 12.1.1
    ReqRecordRoutes := TIdSipHeadersFilter.Create(Request.Headers, RecordRouteHeader);
    try
      Result.AddHeaders(ReqRecordRoutes);

      if (ReqRecordRoutes.Count > 0) then begin
        FirstRR := ReqRecordRoutes.Items[0] as TIdSipRecordRouteHeader;
        if (FirstRR.Address.Protocol = SipsScheme) then
          Self.Contact.Address.Protocol := SipsScheme;
      end;

      if Request.HasSipsUri then
        Self.Contact.Address.Protocol := SipsScheme;

      Result.AddHeader(Self.Contact);
      Result.AddHeader(Self.From);

      if (Self.UserAgentName <> '') then
        Result.AddHeader(UserAgentHeader).Value := Self.UserAgentName;
    finally
      ReqRecordRoutes.Free;
    end;
  except
    Result.Free;

    raise;
  end;
end;

procedure TIdSipUserAgentCore.ReceiveRequest(const Request: TIdSipRequest;
                                             const Transaction: TIdSipTransaction;
                                             const Transport: TIdSipTransport);
var
  Session: TIdSipSession;
begin
  // cf RFC 3261 section 8.2
  // inspect the method - 8.2.1
  if not Self.IsMethodAllowed(Request.Method) then begin
    Self.RejectRequestMethodNotAllowed(Request, Transaction);
    Exit;
  end;

  // inspect the headers - 8.2.2

  // To & Request-URI - 8.2.2.1
  if not Self.IsSchemeAllowed(Request.RequestUri.Protocol) then begin
    Self.RejectRequest(Request, SIPUnsupportedURIScheme, Transaction, Transport);
    Exit;
  end;

  // Merged requests - 8.2.2.2
  if not Request.ToHeader.HasTag and Self.Dispatcher.LoopDetected(Request) then begin
    Self.RejectRequest(Request, SIPLoopDetected, Transaction, Transport);
    Exit;
  end;

  // Require - 8.2.2.3
  if Request.HasHeader(RequireHeader) then begin
    Self.RejectRequestBadExtension(Request, Transaction);
    Exit;
  end;

  // Content processing - 8.2.3
  if Self.HasUnknownContentEncoding(Request) then begin
    Self.RejectRequestUnknownContentEncoding(Request, Transaction);
    Exit;
  end;

  if Self.HasUnknownContentLanguage(Request) then begin
    Self.RejectRequestUnknownContentLanguage(Request, Transaction);
    Exit;
  end;

  if Self.HasUnknownContentType(Request) then begin
    Self.RejectRequestUnknownContentType(Request, Transaction);
    Exit;
  end;

  // Processing the request - 8.2.5
  if Request.IsInvite then begin
    // Section 8.1.1.8 says that a request that can start a dialog (like an
    // INVITE), MUST contain a Contact.
    if not Request.HasHeader(ContactHeaderFull) then
      Self.RejectBadRequest(Request, MissingContactHeader, Transaction)
    else begin
      Session := Self.AddSession(Request, Transaction);
    end;
  end
  else if Request.IsBye then
    raise Exception.Create('Handling BYEs not implemented yet')
  else if Request.IsCancel then
    raise Exception.Create('Handling CANCELs not implemented yet');

  // Generating the response - 8.2.6
end;

procedure TIdSipUserAgentCore.ReceiveResponse(const Response: TIdSipResponse;
                                              const Transaction: TIdSipTransaction;
                                              const Transport: TIdSipTransport);
begin
  // User Agents drop unmatched responses on the floor.
end;

function TIdSipUserAgentCore.HasUnknownContentLanguage(const Request: TIdSipRequest): Boolean;
begin
  Result := Request.HasHeader(ContentLanguageHeader)
       and (Self.AllowedLanguageList.IndexOf(Request.FirstHeader(ContentLanguageHeader).Value) = -1);
end;

function TIdSipUserAgentCore.HasUnknownContentEncoding(const Request: TIdSipRequest): Boolean;
begin
  Result := Request.HasHeader(ContentEncodingHeaderFull);
end;

function TIdSipUserAgentCore.HasUnknownContentType(const Request: TIdSipRequest): Boolean;
begin
  Result := Request.HasHeader(ContentTypeHeaderFull)
       and (Request.FirstHeader(ContentTypeHeaderFull).Value <> SdpMimeType);
end;

function TIdSipUserAgentCore.IsExtensionAllowed(const Extension: String): Boolean;
begin
  Result := false;
end;

function TIdSipUserAgentCore.IsMethodAllowed(const Method: String): Boolean;
begin
  Result := Self.AllowedMethodList.IndexOf(Method) >= 0;
end;

function TIdSipUserAgentCore.IsSchemeAllowed(const Scheme: String): Boolean;
begin
  Result := Self.AllowedSchemeList.IndexOf(Scheme) >= 0;
end;

function TIdSipUserAgentCore.NextBranch: String;
begin
  Self.BranchLock.Acquire;
  try
    // TODO
    // This is a CRAP way to generate a branch.
    // cf. RFC 3261 section 8.1.1.7
    // While this (almost) satisfies the uniqueness constraint (the branch is
    // unique for the lifetime of the instantiation of the UA), it just
    // seems sensible to generate an unguessable branch.
    Result := BranchMagicCookie + IntToStr(Self.fLastBranch);

    Inc(Self.fLastBranch);
  finally
    Self.BranchLock.Release;
  end;
end;

function TIdSipUserAgentCore.NextTag: String;
begin
  // TODO
  // This is a CRAP way to generate a tag.
  // cf. RFC 3261 section 19.3
  Result := IntToHex(TIdSipRandomNumber.Next, 8)
          + IntToHex(TIdSipRandomNumber.Next, 8);
end;

procedure TIdSipUserAgentCore.RejectRequest(const Request: TIdSipRequest;
                                            const Reason: Cardinal;
                                            const Transaction: TIdSipTransaction;
                                            const Transport: TIdSipTransport);
var
  Response: TIdSipResponse;
begin
  Response := Self.CreateResponse(Request, Reason);
  try
    Transaction.SendResponse(Response, Transport);
  finally
    Response.Free;
  end;
end;

function TIdSipUserAgentCore.SessionCount: Integer;
begin
  Self.SessionLock.Acquire;
  try
    Result := Self.Sessions.Count;
  finally
    Self.SessionLock.Release;
  end;
end;

//* TIdSipUserAgentCore Private methods ****************************************

function TIdSipUserAgentCore.AddSession(const Invite: TIdSipRequest;
                                        const Transaction: TIdSipTransaction): TIdSipSession;
begin
  Self.SessionLock.Acquire;
  try
    Result := TIdSipSession.Create(Self, Invite, Transaction);
    try
      Self.Sessions.Add(Result);
    except
      FreeAndNil(Result);

      raise;
    end;
  finally
    Self.SessionLock.Release;
  end;
end;

function TIdSipUserAgentCore.AddSession(const Invite: TIdSipRequest): TIdSipSession;
begin
  Self.SessionLock.Acquire;
  try
    Result := TIdSipSession.Create(Self, Invite);
    try
      Self.Sessions.Add(Result);
    except
      FreeAndNil(Result);

      raise;
    end;
  finally
    Self.SessionLock.Release;
  end;
end;

function TIdSipUserAgentCore.GetContact: TIdSipContactHeader;
begin
  if not Assigned(fContact) then
    fContact := TIdSipContactHeader.Create;

  Result := fContact;
end;

function TIdSipUserAgentCore.GetFrom: TIdSipFromHeader;
begin
  if not Assigned(fFrom) then
    fFrom := TIdSipFromHeader.Create;

  Result := fFrom;
end;

procedure TIdSipUserAgentCore.RejectBadRequest(const Request: TIdSipRequest;
                                               const Reason: String;
                                               const Transaction: TIdSipTransaction);
var
  Response: TIdSipResponse;
begin
  Response := Self.CreateResponse(Request, SIPBadRequest);
  try
    Response.StatusText := Reason;

    Transaction.SendResponse(Response, nil);
  finally
    Response.Free;
  end;
end;

procedure TIdSipUserAgentCore.RejectRequestBadExtension(const Request: TIdSipRequest;
                                                        const Transaction: TIdSipTransaction);
var
  Response: TIdSipResponse;
begin
  Response := Self.CreateResponse(Request, SIPBadExtension);
  try
    Response.AddHeader(UnsupportedHeader).Value := Request.FirstHeader(RequireHeader).Value;

    Transaction.SendResponse(Response, nil);
  finally
    Response.Free;
  end;
end;

procedure TIdSipUserAgentCore.RejectRequestMethodNotAllowed(const Request: TIdSipRequest;
                                                            const Transaction: TIdSipTransaction);
var
  Response: TIdSipResponse;
begin
  Response := Self.CreateResponse(Request, SIPMethodNotAllowed);
  try
    Response.AddHeader(AllowHeader).Value := Self.AllowedMethods;

    Transaction.SendResponse(Response, nil);
  finally
    Response.Free;
  end;
end;

procedure TIdSipUserAgentCore.RejectRequestUnknownContentEncoding(const Request: TIdSipRequest;
                                                                  const Transaction: TIdSipTransaction);
var
  Response: TIdSipResponse;
begin
  Response := Self.CreateResponse(Request, SIPUnsupportedMediaType);
  try
    Response.AddHeader(AcceptEncodingHeader).Value := '';

    Transaction.SendResponse(Response, nil);
  finally
    Response.Free;
  end;
end;

procedure TIdSipUserAgentCore.RejectRequestUnknownContentLanguage(const Request: TIdSipRequest;
                                                                  const Transaction: TIdSipTransaction);
var
  Response: TIdSipResponse;
begin
  Response := Self.CreateResponse(Request, SIPUnsupportedMediaType);
  try
    Response.AddHeader(AcceptLanguageHeader).Value := Self.AllowedLanguages;

    Transaction.SendResponse(Response, nil);
  finally
    Response.Free;
  end;
end;

procedure TIdSipUserAgentCore.RejectRequestUnknownContentType(const Request: TIdSipRequest;
                                                              const Transaction: TIdSipTransaction);
var
  Response: TIdSipResponse;
begin
  Response := Self.CreateResponse(Request, SIPUnsupportedMediaType);
  try
    Response.AddHeader(AcceptHeader).Value := SdpMimeType;

    Transaction.SendResponse(Response, nil);
  finally
    Response.Free;
  end;
end;

procedure TIdSipUserAgentCore.ResetLastBranch;
begin
  Self.BranchLock.Acquire;
  try
    Self.fLastBranch := 0;
  finally
    Self.BranchLock.Release;
  end;
end;

procedure TIdSipUserAgentCore.SendRinging(const Request: TIdSipRequest;
                                          const Transaction: TIdSipTransaction);
var
  Response: TIdSipResponse;
begin
  Response := Self.CreateResponse(Request, SIPRinging);
  try
    Transaction.SendResponse(Response, nil);
  finally
    Response.Free;
  end;
end;

procedure TIdSipUserAgentCore.SetContact(const Value: TIdSipContactHeader);
begin
  Assert(not Value.IsWildCard,
         'A wildcard Contact header may not be used here');

  Assert((Value.Address.Protocol = SipScheme) or (Value.Address.Protocol = SipsScheme),
         'Only SIP or SIPS URIs may be used.');

  Self.Contact.Assign(Value);
end;

procedure TIdSipUserAgentCore.SetFrom(const Value: TIdSipFromHeader);
begin
  Assert((Value.Address.Protocol = SipScheme) or (Value.Address.Protocol = SipsScheme),
         'Only SIP or SIPS URIs may be used.');

  Self.From.Assign(Value);
end;

//******************************************************************************
//* TIdSipSession                                                              *
//******************************************************************************
//* TIdSipSession Public methods ***********************************************

constructor TIdSipSession.Create(const UA: TIdSipUserAgentCore;
                                 const Invite: TIdSipRequest);
var
  Tran: TIdSipTransaction;
begin
  inherited Create;

  Self.fCore := UA;
  Self.fInvite := TIdSipRequest.Create;
  Self.Invite.Assign(Invite);

  Tran := Self.Core.Dispatcher.AddClientTransaction(Invite, nil);
  Tran.AddTransactionListener(Self);
end;

constructor TIdSipSession.Create(const UA: TIdSipUserAgentCore;
                                 const Invite: TIdSipRequest;
                                 const InitialTransaction: TIdSipTransaction);
begin
  inherited Create;

  Self.fCore := UA;
  Self.fInvite := TIdSipRequest.Create;
  Self.Invite.Assign(Invite);

  InitialTransaction.AddTransactionListener(Self);
end;

destructor TIdSipSession.Destroy;
begin
  Self.Invite.Free;

  inherited Destroy;
end;

procedure TIdSipSession.AcceptCall(const Invite: TIdSipRequest;
                                   const Transport: TIdSipTransport);
var
  ID:       TIdSipDialogID;
  Response: TIdSipResponse;
  RouteSet: TIdSipHeaderList;
begin
  Response := Self.Core.CreateResponse(Invite, SIPOK);
  try
    Response.ToHeader.Tag := Self.Core.NextTag;

    if not Assigned(Self.Dialog) then begin
      ID := Response.CreateDialogID;
      try
        RouteSet := TIdSipHeadersFilter.Create(Invite.Headers,
                                               RecordRouteHeader);
        try
          fDialog := TIdSipDialog.Create(ID,
                                         0,
                                         Invite.CSeq.SequenceNo,
                                         Invite.ToHeader.Address,
                                         Invite.From.Address,
                                         Invite.FirstContact.Address,
                                         Transport.IsSecure and (Invite.HasSipsUri),
                                         RouteSet);
        finally
          RouteSet.Free;
        end;
      finally
        ID.Free;
      end;
    end;

    Self.Dialog.HandleMessage(Invite);
    Self.Dialog.HandleMessage(Response);

    Self.Core.Dispatcher.SendToTransaction(Response);
  finally
    Response.Free;
  end;
end;

procedure TIdSipSession.Cancel;
begin
end;

procedure TIdSipSession.HangUp;
var
  Bye: TIdSipRequest;
begin
  Bye := Self.Dialog.CreateBye;
  try
    Self.Core.Dispatcher.SendToTransaction(Bye);
  finally
    Bye.Free;
  end;
end;

procedure TIdSipSession.Modify;
begin
end;

//* TIdSipSession Private methods **********************************************

procedure TIdSipSession.OnFail(const Transaction: TIdSipTransaction;
                               const Reason: String);
begin
end;

procedure TIdSipSession.OnReceiveRequest(const Request: TIdSipRequest;
                                         const Transaction: TIdSipTransaction;
                                         const Transport: TIdSipTransport);
begin
  Self.Dialog.HandleMessage(Request);
end;

procedure TIdSipSession.OnReceiveResponse(const Response: TIdSipResponse;
                                          const Transaction: TIdSipTransaction;
                                          const Transport: TIdSipTransport);
var
  ID:       TIdSipDialogID;
  RouteSet: TIdSipHeadersFilter;
begin
  if not Assigned(Self.Dialog) then begin
    ID := Invite.CreateDialogID;
    try
      RouteSet := TIdSipHeadersFilter.Create(Invite.Headers,
                                             RecordRouteHeader);
      try
        fDialog := TIdSipDialog.Create(ID,
                                       Invite.CSeq.SequenceNo,
                                       0,
                                       Invite.From.Address,
                                       Invite.ToHeader.Address,
                                       Response.FirstContact.Address,
                                       Transport.IsSecure and Invite.FirstContact.HasSipsUri,
                                       RouteSet);
      finally
        RouteSet.Free;
      end;
    finally
      ID.Free;
    end;
  end;

  Self.Dialog.HandleMessage(Response);
end;

procedure TIdSipSession.OnTerminated(const Transaction: TIdSipTransaction);
begin
end;

end.
