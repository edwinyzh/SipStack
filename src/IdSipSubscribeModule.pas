{
  (c) 2005 Directorate of New Technologies, Royal National Institute for Deaf people (RNID)

  The RNID licence covers this unit. Read the licence at:
      http://www.ictrnid.org.uk/docs/gw/rnid_license.txt

  This unit contains code written by:
    * Frank Shearar
}
unit IdSipSubscribeModule;

interface
{ TEMPORARY HOLDING SPACE FOR DELETED-FOR-NOW CODE


  TIdSipBlindTransferral = class(TIdSipOutboundReferral)
  private
    Session: TIdSipSession;
  protected
    procedure ReceiveNotify(Notify: TIdSipRequest); override;
  public
    constructor CreateTransferor(UA: TIdSipAbstractCore;
                                 Session: TIdSipSession;
                                 TransferTarget: TIdSipAddressHeader);
  end;

//******************************************************************************
//* TIdSipBlindTransferral                                                     *
//******************************************************************************
//* TIdSipBlindTransferral Public methods **************************************

constructor TIdSipBlindTransferral.CreateTransferor(UA: TIdSipAbstractCore;
                                                    Session: TIdSipSession;
                                                    TransferTarget: TIdSipAddressHeader);
begin
  inherited Create(UA);

  Self.Session := Session;
  Self.Target := TransferTarget;
end;

//* TIdSipBlindTransferral Protected methods ***********************************

procedure TIdSipBlindTransferral.ReceiveNotify(Notify: TIdSipRequest);
var
  NotifyBody: TIdSipResponse;
begin
  inherited ReceiveNotify(Notify);

  NotifyBody := TIdSipResponse.ReadResponseFrom(Notify.Body);
  try
    if NotifyBody.IsOK then begin
      Self.Session.Terminate;
      Self.MarkAsTerminated;
    end;
  finally
    NotifyBody.Free;
  end;
end;

}

uses
  Classes, Contnrs, IdNotification, IdSipCore, IdSipDialog, IdSipDialogID,
  IdSipInviteModule, IdSipMessage, IdTimerQueue, SyncObjs, SysUtils;

type
  TIdSipOutboundNotify = class;

  IIdSipNotifyListener = interface(IIdSipActionListener)
    ['{15BEA69F-16D0-46C8-BB60-75F1CD3EC4CC}']
    procedure OnFailure(NotifyAgent: TIdSipOutboundNotify;
                        Response: TIdSipResponse);
    procedure OnSuccess(NotifyAgent: TIdSipOutboundNotify;
                        Response: TIdSipResponse);
  end;

  TIdSipOutboundSubscribe = class;

  IIdSipSubscribeListener = interface(IIdSipActionListener)
    ['{15BEA69F-16D0-46C8-BB60-75F1CD3EC4CC}']
    procedure OnFailure(SubscribeAgent: TIdSipOutboundSubscribe;
                        Response: TIdSipResponse);
    procedure OnSuccess(SubscribeAgent: TIdSipOutboundSubscribe;
                        Response: TIdSipResponse);
  end;

  TIdSipOutboundSubscription = class;

  // I define the protocol for things that listen for a particular
  // Subscription's events.
  // * OnEstablishedSubscription tells you that the target returned a 202
  //   Accepted or a 200 OK. This means that the remote end is prepared to
  //   notify you, or has consulted the user for permission.
  // * OnExpiredSubscription tells you that the target just sent you a NOTIFY
  //   terminating the subscription. Clear your references to the subscription
  //   because the Transaction-User Core will destroy the subscription after
  //   this.
  // * OnNotify tells you that the target notified you of some state change.
  //   This event will trigger on ALL notifications, so for instance you'll
  //   see this event fire just before OnExpiredSubscription.
  IIdSipSubscriptionListener = interface(IIdSipActionListener)
    ['{6A6F6A2D-D987-47BE-BC70-83622FF99CDF}']
    procedure OnEstablishedSubscription(Subscription: TIdSipOutboundSubscription;
                                        Notify: TIdSipRequest);
    procedure OnExpiredSubscription(Subscription: TIdSipOutboundSubscription;
                                    Notify: TIdSipRequest);
    procedure OnFailure(Subscription: TIdSipOutboundSubscription;
                        Response: TIdSipResponse);
    procedure OnNotify(Subscription: TIdSipOutboundSubscription;
                       Notify: TIdSipRequest);
  end;

  TIdSipInboundSubscription = class;
  TIdSipInboundSubscriptionClass = class of TIdSipInboundSubscription;

  // I define the protocol for things that are interested in subscriptions.
  // * OnRenewedSubscription fires whenever something creates a new outbound
  //   Subscription as part of an automatic process: when the target
  //   deactivates the subscription, when the retry-after time elapses for some
  //   scheduled event, etc.
  IIdSipSubscribeModuleListener = interface(IIdSipMessageModuleListener)
    ['{9BF47363-0182-4E6E-88E0-A1898B3B779B}']
    procedure OnRenewedSubscription(UserAgent: TIdSipAbstractCore;
                                    Subscription: TIdSipOutboundSubscription);
    procedure OnSubscriptionRequest(UserAgent: TIdSipAbstractCore;
                                    Subscription: TIdSipInboundSubscription);
  end;

  TIdSipEventPackage = class;
  TIdSipEventPackageClass = class of TIdSipEventPackage;

  TIdSipOutboundReferral = class;

  TIdSipSubscribeModule = class(TIdSipMessageModule)
  private
    fInboundSubscriptionDuration: Cardinal;
    fMinimumExpiryTime:           Cardinal;
    Listeners:                    TIdNotificationList;
    PackagePrototypes:            TObjectList;

    function  DefaultMinimumExpiryTime: Cardinal;
    function  KnowsEvent(const EventPackage: String): Boolean;
    procedure NotifyOfRenewedSubscription(NewSub: TIdSipOutboundSubscription);
    function  PackageAt(Index: Integer): TIdSipEventPackage;
    procedure RejectUnknownEvent(Request: TIdSipRequest);
    function  SubscriptionMakingRequests: String;
  protected
    function AcceptRequest(Request: TIdSipRequest;
                           UsingSecureTransport: Boolean): TIdSipAction; override;
    function WillAcceptRequest(Request: TIdSipRequest): TIdSipUserAgentReaction; override;
  public
    constructor Create(UA: TIdSipAbstractCore); override;
    destructor  Destroy; override;

    procedure AddListener(Listener: IIdSipSubscribeModuleListener);
    procedure AddLocalHeaders(OutboundMessage: TIdSipMessage); override;
    procedure AddPackage(PackageType: TIdSipEventPackageClass); overload;
    procedure AddPackage(const PackageName: String); overload;
    function  AllowedEvents: String;
    function  CreateNotify(Dialog: TIdSipDialog;
                           Subscribe: TIdSipRequest;
                           const SubscriptionState: String): TIdSipRequest;
    function  CreateRefer(Dest: TIdSipAddressHeader;
                          ReferTo: TIdSipAddressHeader): TIdSipRequest;
    function  CreateSubscribe(Dest: TIdSipAddressHeader;
                              const EventPackage: String): TIdSipRequest; overload;
    function  CreateSubscribe(Dialog: TIdSipDialog;
                              const EventPackage: String): TIdSipRequest; overload;
    function  DefaultSubscriptionDuration: Cardinal;
    function  IsSubscribeMethod(Method: String): Boolean;
    procedure NotifyOfSubscriptionRequest(Subscription: TIdSipInboundSubscription);
    function  Package(const EventType: String): TIdSipEventPackage;
    function  PackageFor(Request: TIdSipRequest): TIdSipEventPackage;
    function  Refer(Target: TIdSipAddressHeader;
                    Resource: TIdSipAddressHeader): TIdSipOutboundReferral;
    procedure RemoveAllPackages;
    procedure RetrySubscriptionAfter(Target: TIdSipAddressHeader;
                                     const EventPackage: String;
                                     WaitTime: Cardinal);
    function  Resubscribe(Target: TIdSipAddressHeader;
                          const EventPackage: String): TIdSipOutboundSubscription;
    procedure RemoveListener(Listener: IIdSipSubscribeModuleListener);
    function  Subscribe(Target: TIdSipAddressHeader;
                        const EventPackage: String): TIdSipOutboundSubscription;
    function  WillAccept(Request: TIdSipRequest): Boolean; override;

    property MinimumExpiryTime:           Cardinal read fMinimumExpiryTime write fMinimumExpiryTime;
    property InboundSubscriptionDuration: Cardinal read fInboundSubscriptionDuration write fInboundSubscriptionDuration;
  end;

  // I supply methods for objects to find out what event packages the stack
  // knows about, and information about those event packages.
  // I also provide a string -> class type mapping for the event packages; the
  // individual event packages each define a mapping from their class type ->
  // string. You must ensure that this mapping remains bijective (i.e., every
  // package type has a package name (the mapping is onto), and that name is
  // unique (the mapping is one-to-one)).
  TIdSipEventPackageRegistry = class(TObject)
  private
    class function PackageAt(Index: Integer): TIdSipEventPackageClass;
    class function Registry: TStrings;
  public
    class function  EventFor(const PackageName: String): TIdSipEventPackageClass;
    class function  IsRegistered(const PackageName: String): Boolean;
    class procedure RegisterEvent(PackageType: TIdSipEventPackageClass);
    class procedure UnregisterEvent(const PackageName: String); overload;
    class procedure UnregisterEvent(PackageType: TIdSipEventPackageClass); overload;
  end;

  TIdSipEventPackage = class(TObject)
  private
    fInboundSubscriptionDuration: Cardinal;
    fMinimumExpiryTime:           Cardinal;
    fModule:                      TIdSipSubscribeModule;
    fProbationRetryTime:          Cardinal;
    fState:                       String;

  protected
    procedure NotifyOfSubscriptionRequest(Subscription: TIdSipInboundSubscription);
    function  UserAgent: TIdSipAbstractCore;
  public
    class function DefaultProbationRetryTime: Cardinal; virtual;
    class function DefaultSubscriptionDuration: Cardinal; virtual;
    class function EventPackage: String; virtual; abstract;

    constructor Create(Module: TIdSipSubscribeModule);

    function  Accept(Request: TIdSipRequest;
                     UsingSecureTransport: Boolean): TIdSipAction; virtual;
    function Clone: TIdSipEventPackage;
    function MimeType: String; virtual;

    property InboundSubscriptionDuration: Cardinal              read fInboundSubscriptionDuration write fInboundSubscriptionDuration;
    property MinimumExpiryTime:           Cardinal              read fMinimumExpiryTime write fMinimumExpiryTime;
    property Module:                      TIdSipSubscribeModule read fModule;
    property ProbationRetryTime:          Cardinal              read fProbationRetryTime write fProbationRetryTime;
    property State:                       String                read fState write fState;
  end;

  // cf. RFC 3515
  TIdSipReferPackage = class(TIdSipEventPackage)
  private
    procedure RejectForbidden(Request: TIdSipRequest);
  public
    class function DefaultSubscriptionDuration: Cardinal; override;
    class function EventPackage: String; override;

    function Accept(Request: TIdSipRequest;
                    UsingSecureTransport: Boolean): TIdSipAction; override;
    function MimeType: String; override;
  end;

  // cf. draft-sparks-sipping-dialogusage-00
  TIdSipTargetDialogPackage = class(TIdSipEventPackage)
  public
    class function EventPackage: String; override;
  end;

  TIdSipNotify = class(TIdSipAction)
  public
    class function Method: String; override;
  end;

  TIdSipOutboundNotifyBase = class(TIdSipNotify)
  private
    fBody:      String;
    fDialog:    TIdSipDialog;
    fMimeType:  String;
    fSubscribe: TIdSipRequest;
  protected
    Module: TIdSipSubscribeModule;

    procedure ConfigureAttempt(Notify: TIdSipRequest); virtual;
    function  CreateNewAttempt: TIdSipRequest; override;
    procedure Initialise(UA: TIdSipAbstractCore;
                         Request: TIdSipRequest;
                         UsingSecureTransport: Boolean); override;
  public
    procedure Send; override;
      
    property Body:              String        read fBody write fBody;
    property Dialog:            TIdSipDialog  read fDialog write fDialog;
    property MimeType:          String        read fMimeType write fMimeType;
    property Subscribe:         TIdSipRequest read fSubscribe write fSubscribe;
  end;

  TIdSipOutboundNotify = class(TIdSipOutboundNotifyBase)
  private
    fExpires:           Cardinal;
    fSubscriptionState: String;
  protected
    procedure ConfigureAttempt(Notify: TIdSipRequest); override;
    procedure NotifyOfFailure(Response: TIdSipResponse); override;
  public
    procedure AddListener(Listener: IIdSipNotifyListener);
    procedure RemoveListener(Listener: IIdSipNotifyListener);

    property Expires:           Cardinal read fExpires write fExpires;
    property SubscriptionState: String   read fSubscriptionState write fSubscriptionState;
  end;

  TIdSipOutboundTerminatingNotify = class(TIdSipOutboundNotifyBase)
  private
    fReason: String;
  protected
    procedure ConfigureAttempt(Notify: TIdSipRequest); override;
  public
    property Reason: String read fReason write fReason;
  end;

  // I provide basic facilities for Actions that handle SUBSCRIBE/NOTIFY
  // messages.
  TIdSipSubscribeBase = class(TIdSipAction)
  protected
    procedure ReceiveNotify(Notify: TIdSipRequest); virtual;
    procedure ReceiveRefer(Refer: TIdSipRequest); virtual;
    procedure ReceiveSubscribe(Subscribe: TIdSipRequest); virtual;
  public
    class function Method: String; override;

    procedure ReceiveRequest(Request: TIdSipRequest); override;
  end;

  TIdSipSubscribe = class(TIdSipSubscribeBase)
  private
    fDuration:     Cardinal; // in seconds
    fEventPackage: String;
    fID:           String;
    Module:        TIdSipSubscribeModule;
  protected
    function  CreateNewAttempt: TIdSipRequest; override;
    procedure Initialise(UA: TIdSipAbstractCore;
                         Request: TIdSipRequest;
                         UsingSecureTransport: Boolean); override;
  public
    property EventPackage: String   read fEventPackage write fEventPackage;
    property Duration:     Cardinal read fDuration write fDuration;
    property ID:           String   read fID write fID;
  end;

  TIdSipOutboundSubscribe = class(TIdSipSubscribe)
  private
    fTarget: TIdSipAddressHeader;

    procedure NotifyOfSuccess(Response: TIdSipResponse);
    procedure SetTarget(Value: TIdSipAddressHeader);
  protected
    function  CreateNewAttempt: TIdSipRequest; override;
    procedure Initialise(UA: TIdSipAbstractCore;
                         Request: TIdSipRequest;
                         UsingSecureTransport: Boolean); override;
    procedure NotifyOfFailure(Response: TIdSipResponse); override;
    function  ReceiveOKResponse(Response: TIdSipResponse;
                                UsingSecureTransport: Boolean): TIdSipActionResult; override;
  public
    destructor  Destroy; override;

    procedure AddListener(Listener: IIdSipSubscribeListener);
    function  Match(Msg: TIdSipMessage): Boolean; override;
    procedure RemoveListener(Listener: IIdSipSubscribeListener);
    procedure Send; override;

    property Target: TIdSipAddressHeader read fTarget write SetTarget;
  end;

  TIdSipOutboundRefreshSubscribe = class(TIdSipOutboundSubscribe)
  private
    fDialog:   TIdSipDialog;
    fDuration: Cardinal;
  protected
    function  CreateNewAttempt: TIdSipRequest; override;
  public
    procedure Send; override;

    property Dialog:   TIdSipDialog read fDialog write fDialog;
    property Duration: Cardinal     read fDuration write fDuration;
  end;

  TIdSipOutboundUnsubscribe = class(TIdSipOutboundSubscribe)
  private
    fCallID:  String;
    fFromTag: String;
  public
    procedure Send; override;

    property CallID: String  read fCallID write fCallID;
    property FromTag: String read fFromTag write fFromTag;
  end;

  TIdSipRefer = class(TIdSipSubscribe)
  public
    class function Method: String; override;

    constructor Create(UA: TIdSipAbstractCore); overload; override;
  end;

  TIdSipInboundRefer = class(TIdSipRefer)
  private
    procedure RejectBadRequest(Refer: TIdSipRequest);
    function  WrongNumberOfReferTos(Refer: TIdSipRequest): Boolean;
  protected
    procedure ReceiveOtherRequest(Request: TIdSipRequest); override;
  end;

  TIdSipOutboundRefer = class(TIdSipOutboundSubscribe)
  private
    fReferTo: TIdSipAddressHeader;

    procedure SetReferTo(Value: TIdSipAddressHeader);
  protected
    function  CreateNewAttempt: TIdSipRequest; override;
  public
    class function Method: String; override;

    constructor Create(UA: TIdSipAbstractCore); overload; override;
    destructor  Destroy; override;

    property ReferTo: TIdSipAddressHeader read fReferTo write SetReferTo;
  end;

  TIdSipSubscriptionExpires = class;

  // I represent a subscription to another entity's state of some kind.
  // The relationship between me, TIdSip(In|Out)boundSubscribe and
  // TIdSip(In|Out)boundNotify resembles that between TIdSipSession,
  // TIdSip(In|Out)boundInvite, etc.
  TIdSipSubscription = class(TIdSipSubscribeBase,
                             IIdSipActionListener)
  private
    fDuration:           Cardinal;
    fEventPackage:       String;
    fExpiryTime:         TDateTime; // Absolute-time expiry
    fID:                 String;
    fSubscriptionState:  String;
    fTarget:             TIdSipAddressHeader;
    fTerminating:        Boolean;

    procedure OnAuthenticationChallenge(Action: TIdSipAction;
                                        Challenge: TIdSipResponse);
    procedure OnNetworkFailure(Action: TIdSipAction;
                               ErrorCode: Cardinal;
                               const Reason: String);
  protected
    Dialog:  TIdSipDialog;
    Module:  TIdSipSubscribeModule;
    Package: TIdSipEventPackage;

    function  CreateDialog(Response: TIdSipResponse): TIdSipDialog; virtual; abstract;
    function  CreateNewAttempt: TIdSipRequest; override;
    function  DialogEstablished: Boolean;
    procedure EstablishDialog(Response: TIdSipResponse); virtual;
    procedure Initialise(UA: TIdSipAbstractCore;
                         Request: TIdSipRequest;
                         UsingSecureTransport: Boolean); override;
    procedure SetEventPackage(const Value: String); virtual;
    procedure SetExpiryTime(Value: TDateTime);
    procedure SetSubscriptionState(const Value: String); virtual;
    procedure SetTerminating(Value: Boolean);
  public
    destructor Destroy; override;

    procedure Expire; virtual;
    function  ExpiryTime: TDateTime;
    function  ExpiryTimeInSeconds: Integer;

    property Duration:          Cardinal            read fDuration write fDuration;
    property EventPackage:      String              read fEventPackage write SetEventPackage;
    property ID:                String              read fID write fID;
    property SubscriptionState: String              read fSubscriptionState;
    property Target:            TIdSipAddressHeader read fTarget write fTarget;
    property Terminating:       Boolean             read fTerminating;
  end;

  // Note that several methods schedule terminations. Since ActionClosures are
  // stateless, we use (Dec|Inc)OutstandingExpires to keep track of how many
  // terminations we've scheduled and how many have triggered. When the last
  // one triggers - when OutstandingExpires = 0 - then we know we've triggered
  // the termination that will actually kill the subscription.
  TIdSipInboundSubscription = class(TIdSipSubscription,
                                    IIdSipNotifyListener)
  private
    OutstandingExpires:   Cardinal;
    UsingSecureTransport: Boolean;

    procedure ConfigureNotify(Notify: TIdSipOutboundNotifyBase);
    function  CreateDialogIDFrom(Msg: TIdSipMessage): TIdSipDialogID;
    procedure DecOutstandingExpires;
    function  DialogMatches(DialogID: TIdSipDialogID): Boolean; overload;
    function  DialogMatches(Msg: TIdSipMessage): Boolean; overload;
    function  ExecutingLastScheduledExpires: Boolean;
    procedure IncOutstandingExpires;
    procedure NotifySubscriberOfState;
    procedure OnFailure(NotifyAgent: TIdSipOutboundNotify;
                        Response: TIdSipResponse);
    procedure OnSuccess(NotifyAgent: TIdSipOutboundNotify;
                        Response: TIdSipResponse);
    function  OurExpires(Subscribe: TIdSipRequest): Cardinal;
    procedure RejectExpiresTooBrief(Subscribe: TIdSipRequest);
    procedure ScheduleRenotify(Seconds: Cardinal);
    procedure ScheduleTermination(Expires: Cardinal);
    procedure SendAccept(Subscribe: TIdSipRequest);
    procedure SendOk(Subscribe: TIdSipRequest);
    procedure SendTerminatingNotify(const Body: String;
                                    const MimeType: String;
                                    const Reason: String);
    procedure TerminateSubscription(const Reason: String);
  protected
    function  CreateDialog(Response: TIdSipResponse): TIdSipDialog; override;
    procedure EstablishDialog(Response: TIdSipResponse); override;
    function  GetEventPackage(Request: TIdSipRequest): String; virtual;
    function  GetID(Request: TIdSipRequest): String; virtual;
    procedure Initialise(UA: TIdSipAbstractCore;
                         Request: TIdSipRequest;
                         UsingSecureTransport: Boolean); override;
    procedure ReceiveSubscribe(Request: TIdSipRequest); override;
    procedure SendResponse(Response: TIdSipResponse); override;
    function  WillAccept(Subscribe: TIdSipRequest): Boolean; virtual;
  public
    procedure Accept;
    procedure Expire; override;
    function  IsInbound: Boolean; override;
    function  Match(Msg: TIdSipMessage): Boolean; override;
    procedure Notify(const Body: String;
                     const MimeType: String;
                     const NewState: String = '';
                     const Reason: String = ''); virtual;
    procedure Renotify;
    procedure Terminate; override;
  end;

  TIdSipOutboundSubscription = class(TIdSipSubscription,
                                     IIdSipSubscribeListener)
  private
    InitialSubscribe: TIdSipOutboundSubscribe;
    Unsubscriber:     TIdSipOutboundUnsubscribe;

    function  CreateRefresh(NewDuration: Cardinal): TIdSipOutboundRefreshSubscribe;
    function  CreateUnsubscribe: TIdSipOutboundUnsubscribe;
    procedure NotifyOfExpiredSubscription(Notify: TIdSipRequest);
    procedure NotifyOfReceivedNotify(Notify: TIdSipRequest);
    procedure NotifyOfSuccess(Notify: TIdSipRequest);
    procedure OnFailure(SubscribeAgent: TIdSipOutboundSubscribe;
                        Response: TIdSipResponse);
    procedure OnSuccess(SubscribeAgent: TIdSipOutboundSubscribe;
                        Response: TIdSipResponse);
//    procedure RejectUnauthorized(Notify: TIdSipRequest);
    procedure RescheduleRefresh(NewDuration: Cardinal);
    procedure ScheduleNewSubscription(Seconds: Cardinal);
    procedure ScheduleSubscriptionAt(SubscriptionState: TIdSipSubscriptionStateHeader;
                                     DefaultSeconds: Cardinal);
    procedure SendResponseFor(Notify: TIdSipRequest);
  protected
    procedure ConfigureRequest(Sub: TIdSipOutboundSubscribe); virtual;
    function  CreateDialog(Response: TIdSipResponse): TIdSipDialog; override;
    function  CreateOutboundSubscribe: TIdSipOutboundSubscribe; virtual;
    procedure Initialise(UA: TIdSipAbstractCore;
                         Request: TIdSipRequest;
                         UsingSecureTransport: Boolean); override;
    procedure NotifyOfFailure(Response: TIdSipResponse); override;
    procedure ReceiveNotify(Notify: TIdSipRequest); override;
    procedure SetEventPackage(const Value: String); override;
    procedure StartNewSubscription(Notify: TIdSipRequest); virtual;
  public
    procedure AddListener(Listener: IIdSipSubscriptionListener);
    procedure Expire; override;
    function  Match(Msg: TIdSipMessage): Boolean; override;
    procedure Refresh(NewDuration: Cardinal);
    procedure RemoveListener(Listener: IIdSipSubscriptionListener);
    procedure Send; override;
    procedure Terminate; override;
    procedure Unsubscribe;
  end;

  TIdSipInboundReferral = class(TIdSipInboundSubscription)
  private
    function  HasUnknownUrlScheme(Refer: TIdSipRequest): Boolean;
    procedure RejectBadRequest(Request: TIdSipRequest);
    function  WrongNumberOfReferTos(Refer: TIdSipRequest): Boolean;
  protected
    function  GetEventPackage(Request: TIdSipRequest): String; override;
    function  GetID(Request: TIdSipRequest): String; override;
    procedure ReceiveRefer(Refer: TIdSipRequest); override;
    function  WillAccept(Refer: TIdSipRequest): Boolean; override;
  public
    class function Method: String; override;
    class function ReferralDeniedBody: String;
    class function ReferralFailedBody: String;
    class function ReferralSucceededBody: String;
    class function ReferralTryingBody: String;

    procedure Notify(const Body: String;
                     const MimeType: String;
                     const NewState: String = '';
                     const Reason: String = ''); override;
    procedure ReferenceDenied;
    procedure ReferenceFailed;
    procedure ReferenceSucceeded;
    procedure ReferenceTrying;
  end;

  TIdSipOutboundReferral = class(TIdSipOutboundSubscription)
  private
    fReferredResource: TIdSipAddressHeader;

    procedure SetReferredResource(Value: TIdSipAddressHeader);
  protected
    procedure ConfigureRequest(Sub: TIdSipOutboundSubscribe); override;
    function  CreateNewAttempt: TIdSipRequest; override;
    function  CreateOutboundSubscribe: TIdSipOutboundSubscribe; override;
    procedure Initialise(UA: TIdSipAbstractCore;
                         Request: TIdSipRequest;
                         UsingSecureTransport: Boolean); override;
    procedure StartNewSubscription(Notify: TIdSipRequest); override;
  public
    class function Method: String; override;

    procedure Send; override;

    property ReferredResource: TIdSipAddressHeader read fReferredResource write SetReferredResource;
  end;

  TIdSipSubscriptionExpires = class(TIdSipActionClosure)
  public
    procedure Execute(Action: TIdSipAction); override;
  end;

  TIdSipSubscriptionRenotify = class(TIdSipActionClosure)
  public
    procedure Execute(Action: TIdSipAction); override;
  end;

  TIdSipOutboundSubscriptionRefresh = class(TIdSipActionClosure)
  private
    fNewDuration: Cardinal; // in seconds
  public
    procedure Execute(Action: TIdSipAction); override;

    property NewDuration: Cardinal read fNewDuration write fNewDuration;
  end;

  TIdSipSubscriptionRetryWait = class(TIdWait)
  private
    fEventPackage: String;
    fTarget:       TIdSipAddressHeader;
    fUserAgent:    TIdSipAbstractCore;

    procedure SetTarget(Value: TIdSipAddressHeader);
  public
    constructor Create; override;
    destructor  Destroy; override;

    procedure Trigger; override;

    property EventPackage: String                  read fEventPackage write fEventPackage;
    property Target:       TIdSipAddressHeader     read fTarget write SetTarget;
    property UserAgent:    TIdSipAbstractCore read fUserAgent write fUserAgent;
  end;

  TIdSipNotifyMethod = class(TIdNotification)
  private
    fResponse: TIdSipResponse;
    fNotify:   TIdSipOutboundNotify;
  public
    property Response: TIdSipResponse       read fResponse write fResponse;
    property Notify:   TIdSipOutboundNotify read fNotify write fNotify;
  end;

  TIdSipNotifyFailedMethod = class(TIdSipNotifyMethod)
  public
    procedure Run(const Subject: IInterface); override;
  end;

  TIdSipNotifySucceededMethod = class(TIdSipNotifyMethod)
  public
    procedure Run(const Subject: IInterface); override;
  end;

  TIdSipOutboundSubscribeMethod = class(TIdNotification)
  private
    fResponse:  TIdSipResponse;
    fSubscribe: TIdSipOutboundSubscribe;
  public
    property Response:  TIdSipResponse          read fResponse write fResponse;
    property Subscribe: TIdSipOutboundSubscribe read fSubscribe write fSubscribe;
  end;

  TIdSipOutboundSubscribeFailedMethod = class(TIdSipOutboundSubscribeMethod)
  public
    procedure Run(const Subject: IInterface); override;
  end;

  TIdSipOutboundSubscribeSucceededMethod = class(TIdSipOutboundSubscribeMethod)
  public
    procedure Run(const Subject: IInterface); override;
  end;

  TIdSipSubscriptionMethod = class(TIdNotification)
  private
    fSubscription: TIdSipOutboundSubscription;
  public
    property Subscription: TIdSipOutboundSubscription read fSubscription write fSubscription;
  end;

  TIdSipEstablishedSubscriptionMethod = class(TIdSipSubscriptionMethod)
  private
    fNotify: TIdSipRequest;
  public
    procedure Run(const Subject: IInterface); override;

    property Notify: TIdSipRequest read fNotify write fNotify;
  end;

  TIdSipExpiredSubscriptionMethod = class(TIdSipSubscriptionMethod)
  private
    fNotify: TIdSipRequest;
  public
    procedure Run(const Subject: IInterface); override;

    property Notify: TIdSipRequest read fNotify write fNotify;
  end;

  TIdSipFailedSubscriptionMethod = class(TIdSipSubscriptionMethod)
  private
    fResponse: TIdSipResponse;
  public
    procedure Run(const Subject: IInterface); override;

    property Response: TIdSipResponse read fResponse write fResponse;
  end;

  TIdSipSubscriptionNotifyMethod = class(TIdSipSubscriptionMethod)
  private
    fNotify: TIdSipRequest;
  public
    procedure Run(const Subject: IInterface); override;

    property Notify: TIdSipRequest read fNotify write fNotify;
  end;

  TIdSipRenewedSubscriptionMethod = class(TIdSipAbstractCoreMethod)
  private
    fSubscription: TIdSipOutboundSubscription;
  public
    procedure Run(const Subject: IInterface); override;

    property Subscription: TIdSipOutboundSubscription read fSubscription write fSubscription;
  end;

  TIdSipSubscriptionRequestMethod = class(TIdSipAbstractCoreMethod)
  private
    fSubscription: TIdSipInboundSubscription;
  public
    procedure Run(const Subject: IInterface); override;

    property Subscription: TIdSipInboundSubscription read fSubscription write fSubscription;
  end;

  EUnknownEventPackage = class(Exception);

const
  SipFragmentMimeType = 'message/sipfrag'; // RFC 3420

const
  DontExpireEventPackageSubscription = 0;
  OneTDateTimeSecond                 = 1/24/60/60;

implementation

const
  BadReferNotifyBody               = 'REFER NOTIFYs MUST have '
                                   + SipFragmentMimeType + ' bodies';
  SubscriptionDidntEstablishDialog = 'Receiving the SUBSCRIBE and sending a '
                                   + 'response didn''t establish a dialog';

var
  GEventPackageTypes: TStrings;

//******************************************************************************
//* TIdSipSubscribeModule                                                      *
//******************************************************************************
//* TIdSipSubscribeModule Public methods ***************************************

constructor TIdSipSubscribeModule.Create(UA: TIdSipAbstractCore);
begin
  inherited Create(UA);

  Self.AddAllowedContentType(SipFragmentMimeType);
  Self.AcceptsMethodsList.Add(MethodSubscribe);
  Self.AcceptsMethodsList.Add(MethodNotify);

  Self.Listeners         := TIdNotificationList.Create;
  Self.PackagePrototypes := TObjectList.Create(true);

  Self.InboundSubscriptionDuration := Self.DefaultSubscriptionDuration;
  Self.MinimumExpiryTime           := Self.DefaultMinimumExpiryTime;
end;

destructor TIdSipSubscribeModule.Destroy;
begin
  Self.PackagePrototypes.Free;
  Self.Listeners.Free;

  inherited Destroy;
end;

procedure TIdSipSubscribeModule.AddListener(Listener: IIdSipSubscribeModuleListener);
begin
  Self.Listeners.AddListener(Listener);
end;

procedure TIdSipSubscribeModule.AddLocalHeaders(OutboundMessage: TIdSipMessage);
begin
  // RFC 3265, section 3.3.7
  if OutboundMessage.WantsAllowEventsHeader then
    OutboundMessage.AddHeader(AllowEventsHeaderFull).Value := Self.AllowedEvents;
end;    

procedure TIdSipSubscribeModule.AddPackage(PackageType: TIdSipEventPackageClass);
var
  NewPkg: TIdSipEventPackage;
begin
  NewPkg := PackageType.Create(Self);
  Self.PackagePrototypes.Add(NewPkg);

  if (NewPkg.EventPackage = PackageRefer) then
    Self.AcceptsMethodsList.Add(MethodRefer)
end;

procedure TIdSipSubscribeModule.AddPackage(const PackageName: String);
begin
  Self.AddPackage(TIdSipEventPackageRegistry.EventFor(PackageName));
end;

function TIdSipSubscribeModule.AllowedEvents: String;
var
  I: Integer;
begin
  Result := '';

  if (Self.PackagePrototypes.Count > 0) then begin
    Result := Self.PackageAt(0).EventPackage;

    for I := 1 to Self.PackagePrototypes.Count - 1 do
      Result := Result + ', ' + Self.PackageAt(I).EventPackage;
  end;
end;

function TIdSipSubscribeModule.CreateNotify(Dialog: TIdSipDialog;
                                            Subscribe: TIdSipRequest;
                                            const SubscriptionState: String): TIdSipRequest;
begin
  Result := Self.UserAgent.CreateRequest(MethodNotify, Dialog);
  try
    // cf RFC 3265, section 3.2.2

    Result.AddHeader(Subscribe.Event);
    Result.SubscriptionState.SubState := SubscriptionState;
  except
    FreeAndNil(Result);

    raise;
  end;
end;

function TIdSipSubscribeModule.CreateRefer(Dest: TIdSipAddressHeader;
                                           ReferTo: TIdSipAddressHeader): TIdSipRequest;
begin
  Result := Self.UserAgent.CreateRequest(MethodRefer, Dest);
  try
    // draft-ietf-sip-gruu, section 8.1
    if Self.UserAgent.UseGruu then
      Result.FirstContact.Grid := Self.UserAgent.NextGrid;

    Result.Event.EventPackage := TIdSipReferPackage.EventPackage;
    Result.ReferTo.Assign(ReferTo);
  except
    FreeAndNil(Result);

    raise;
  end;
end;

function TIdSipSubscribeModule.CreateSubscribe(Dest: TIdSipAddressHeader;
                                               const EventPackage: String): TIdSipRequest;
begin
  Result := Self.UserAgent.CreateRequest(MethodSubscribe, Dest);
  try
    // draft-ietf-sip-gruu, section 8.1
    if Self.UserAgent.UseGruu then
      Result.FirstContact.Grid := Self.UserAgent.NextGrid;

    Result.Event.EventPackage   := EventPackage;
    Result.Expires.NumericValue := Self.Package(EventPackage).DefaultSubscriptionDuration
  except
    FreeAndNil(Result);

    raise;
  end;
end;

function TIdSipSubscribeModule.CreateSubscribe(Dialog: TIdSipDialog;
                                               const EventPackage: String): TIdSipRequest;
begin
  Result := Self.UserAgent.CreateRequest(MethodSubscribe, Dialog);
  try
    Result.Event.EventPackage   := EventPackage;
    Result.Expires.NumericValue := Self.Package(EventPackage).DefaultSubscriptionDuration
  except
    FreeAndNil(Result);

    raise;
  end;
end;

function TIdSipSubscribeModule.DefaultSubscriptionDuration: Cardinal;
begin
  Result := OneHour;
end;

function TIdSipSubscribeModule.IsSubscribeMethod(Method: String): Boolean;
begin
  Result := Pos(Method, Self.SubscriptionMakingRequests) > 0;
end;

procedure TIdSipSubscribeModule.NotifyOfSubscriptionRequest(Subscription: TIdSipInboundSubscription);
var
  Notification: TIdSipSubscriptionRequestMethod;
begin
  Notification := TIdSipSubscriptionRequestMethod.Create;
  try
  finally
    Notification.Subscription := Subscription;
    Notification.UserAgent    := Self.UserAgent;

    Self.Listeners.Notify(Notification);
  end;
end;

function TIdSipSubscribeModule.Package(const EventType: String): TIdSipEventPackage;
var
  I: Integer;
begin
  I      := 0;
  Result := nil;

  while (I < Self.PackagePrototypes.Count) and not Assigned(Result) do begin
    if (Self.PackageAt(I).EventPackage = EventType) then
      Result := Self.PackageAt(I)
    else
      Inc(I);
  end;
end;

function TIdSipSubscribeModule.PackageFor(Request: TIdSipRequest): TIdSipEventPackage;
begin
  // Return nil if
  // * we don't know how to process a particular event package, or
  // * the SUBSCRIBE has no event header.
  Result := nil;

  if Request.IsRefer then begin
    Result := Self.Package(PackageRefer)
  end
  else if Request.IsSubscribe then begin
    if Request.HasHeader(EventHeaderFull) then
      Result := Self.Package(Request.Event.EventPackage);
  end;
end;

function TIdSipSubscribeModule.Refer(Target: TIdSipAddressHeader;
                                     Resource: TIdSipAddressHeader): TIdSipOutboundReferral;
var
  Refer: TIdSipOutboundReferral;
begin
  Refer := Self.UserAgent.AddOutboundAction(TIdSipOutboundReferral) as TIdSipOutboundReferral;
  Refer.ReferredResource := Resource;
  Refer.Target := Target;

  Result := Refer;
end;

procedure TIdSipSubscribeModule.RemoveAllPackages;
begin
  Self.PackagePrototypes.Clear;
end;

procedure TIdSipSubscribeModule.RetrySubscriptionAfter(Target: TIdSipAddressHeader;
                                                       const EventPackage: String;
                                                       WaitTime: Cardinal);
var
  Wait: TIdSipSubscriptionRetryWait;
begin
  Wait := TIdSipSubscriptionRetryWait.Create;
  Wait.EventPackage := EventPackage;
  Wait.Target       := Target;
  Self.UserAgent.ScheduleEvent(WaitTime, Wait);
end;

function TIdSipSubscribeModule.Resubscribe(Target: TIdSipAddressHeader;
                                           const EventPackage: String): TIdSipOutboundSubscription;
begin
  Result := Self.Subscribe(Target, EventPackage);
  Self.NotifyOfRenewedSubscription(Result);
end;

procedure TIdSipSubscribeModule.RemoveListener(Listener: IIdSipSubscribeModuleListener);
begin
  Self.Listeners.RemoveListener(Listener);
end;

function TIdSipSubscribeModule.Subscribe(Target: TIdSipAddressHeader;
                                         const EventPackage: String): TIdSipOutboundSubscription;
var
  Sub: TIdSipOutboundSubscription;
begin
  Sub := Self.UserAgent.AddOutboundAction(TIdSipOutboundSubscription) as TIdSipOutboundSubscription;

  Sub.Target       := Target;
  Sub.EventPackage := EventPackage;

  Result := Sub;
end;

function TIdSipSubscribeModule.WillAccept(Request: TIdSipRequest): Boolean;
begin
  Result := Request.IsSubscribe or Request.IsNotify or Request.IsRefer;
end;

//* TIdSipSubscribeModule Private methods **************************************

function TIdSipSubscribeModule.AcceptRequest(Request: TIdSipRequest;
                                             UsingSecureTransport: Boolean): TIdSipAction;
var
  Package: TIdSipEventPackage;
begin
  Result := nil;

  if not Self.IsSubscribeMethod(Request.Method) then begin
    Self.UserAgent.ReturnResponse(Request,
                                  SIPCallLegOrTransactionDoesNotExist);
    Exit;
  end;

  Package := Self.PackageFor(Request);

  if Assigned(Package) then
    Result := Package.Accept(Request, UsingSecureTransport)
  else
    Self.RejectUnknownEvent(Request);
end;

function TIdSipSubscribeModule.WillAcceptRequest(Request: TIdSipRequest): TIdSipUserAgentReaction;
begin
  Result := inherited WillAcceptRequest(Request);
end;

//* TIdSipSubscribeModule Private methods **************************************

function TIdSipSubscribeModule.DefaultMinimumExpiryTime: Cardinal;
begin
  Result := OneMinute;
end;

function TIdSipSubscribeModule.KnowsEvent(const EventPackage: String): Boolean;
begin
  Result := Pos(EventPackage, Self.AllowedEvents) > 0;
end;

procedure TIdSipSubscribeModule.NotifyOfRenewedSubscription(NewSub: TIdSipOutboundSubscription);
var
  Notification: TIdSipRenewedSubscriptionMethod;
begin
  Notification := TIdSipRenewedSubscriptionMethod.Create;
  try
    Notification.Subscription := NewSub;
    Notification.UserAgent    := Self.UserAgent;

    Self.Listeners.Notify(Notification);
  finally
    Notification.Free;
  end;
end;

function TIdSipSubscribeModule.PackageAt(Index: Integer): TIdSipEventPackage;
begin
  Result := Self.PackagePrototypes[Index] as TIdSipEventPackage;
end;

procedure TIdSipSubscribeModule.RejectUnknownEvent(Request: TIdSipRequest);
var
  Response: TIdSipResponse;
begin
  Response := Self.UserAgent.CreateResponse(Request, SIPBadEvent);
  try
    Response.AddHeader(AllowEventsHeaderFull).Value := Self.AllowedEvents;

    Self.UserAgent.SendResponse(Response);
  finally
    Response.Free;
  end;
end;

function TIdSipSubscribeModule.SubscriptionMakingRequests: String;
begin
  Result := MethodSubscribe;

  if Self.KnowsEvent(PackageRefer) then
    Result := Result + ', '
            + MethodRefer;
end;

//******************************************************************************
//* TIdSipEventPackageRegistry                                                 *
//******************************************************************************
//* TIdSipEventPackageRegistry Public methods **********************************

class function TIdSipEventPackageRegistry.EventFor(const PackageName: String): TIdSipEventPackageClass;
var
  Index: Integer;
begin
  Index := Self.Registry.IndexOf(PackageName);

  if (Index <> ItemNotFoundIndex) then
    Result := Self.PackageAt(Index)
  else
    raise EUnknownEventPackage.Create('TIdSipEventPackageRegistry.EventPackageFor: ' + PackageName);
end;

class function TIdSipEventPackageRegistry.IsRegistered(const PackageName: String): Boolean;
var
  Index: Integer;
begin
  Index := Self.Registry.IndexOf(PackageName);

  Result := Index <> ItemNotFoundIndex;
end;

class procedure TIdSipEventPackageRegistry.RegisterEvent(PackageType: TIdSipEventPackageClass);
begin
  if not Self.IsRegistered(PackageType.EventPackage) then
    Self.Registry.AddObject(PackageType.EventPackage, TObject(PackageType));
end;

class procedure TIdSipEventPackageRegistry.UnregisterEvent(const PackageName: String);
var
  Index: Integer;
begin
  Index := Self.Registry.IndexOf(PackageName);
  if (Index <> ItemNotFoundIndex) then
    Self.Registry.Delete(Index);
end;

class procedure TIdSipEventPackageRegistry.UnregisterEvent(PackageType: TIdSipEventPackageClass);
begin
  Self.UnregisterEvent(PackageType.EventPackage);
end;

//* TIdSipEventPackageRegistry Private methods *********************************

class function TIdSipEventPackageRegistry.PackageAt(Index: Integer): TIdSipEventPackageClass;
begin
  Result := TIdSipEventPackageClass(Self.Registry.Objects[Index]);
end;

class function TIdSipEventPackageRegistry.Registry: TStrings;
begin
  Result := GEventPackageTypes;
end;

//******************************************************************************
//* TIdSipEventPackage                                                         *
//******************************************************************************
//* TIdSipEventPackage Public methods ******************************************

class function TIdSipEventPackage.DefaultProbationRetryTime: Cardinal;
begin
  // This result just seems like a reasonable length of time. It's a thumb-suck.
  Result := FiveMinutes;
end;

class function TIdSipEventPackage.DefaultSubscriptionDuration: Cardinal;
begin
  // This result just seems like a reasonable length of time to subscribe for.
  // It's just a thumb-suck.
  Result := OneHour;
end;

constructor TIdSipEventPackage.Create(Module: TIdSipSubscribeModule);
begin
  inherited Create;

  Self.fModule := Module;

  Self.InboundSubscriptionDuration := Self.Module.InboundSubscriptionDuration;
  Self.MinimumExpiryTime           := Self.Module.MinimumExpiryTime;
  Self.ProbationRetryTime          := Self.DefaultProbationRetryTime;
end;

function TIdSipEventPackage.Accept(Request: TIdSipRequest;
                                   UsingSecureTransport: Boolean): TIdSipAction;
var
  Subscription: TIdSipInboundSubscription;
begin
  Result := nil;
  if not Request.IsSubscribe then Exit;

  Subscription := TIdSipInboundSubscription.CreateInbound(Self.UserAgent,
                                                          Request,
                                                          UsingSecureTransport);
  Self.NotifyOfSubscriptionRequest(Subscription);
  Result := Subscription;
end;

function TIdSipEventPackage.Clone: TIdSipEventPackage;
begin
  Result := TIdSipEventPackageClass(Self.ClassType).Create(Self.Module);
  Result.InboundSubscriptionDuration := Self.InboundSubscriptionDuration;
  Result.MinimumExpiryTime           := Self.MinimumExpiryTime;
end;

function TIdSipEventPackage.MimeType: String;
begin
  Result := 'text/plain';
end;

//* TIdSipEventPackage Protected methods ***************************************

procedure TIdSipEventPackage.NotifyOfSubscriptionRequest(Subscription: TIdSipInboundSubscription);
begin
  Self.Module.NotifyOfSubscriptionRequest(Subscription);
end;

function TIdSipEventPackage.UserAgent: TIdSipAbstractCore;
begin
  Result := Self.Module.UserAgent;
end;

//******************************************************************************
//* TIdSipReferPackage                                                         *
//******************************************************************************
//* TIdSipReferPackage Public methods ******************************************

class function TIdSipReferPackage.DefaultSubscriptionDuration: Cardinal;
begin
  // Note that this value is fairly arbitrary.
  Result := OneMinute;
end;

class function TIdSipReferPackage.EventPackage: String;
begin
  Result := PackageRefer;
end;

function TIdSipReferPackage.Accept(Request: TIdSipRequest;
                                   UsingSecureTransport: Boolean): TIdSipAction;
var
  Referral: TIdSipInboundReferral;
begin
  Result := nil;

  // RFC 3515, section 2.4.4: no SUBSCRIBE may use the refer event package, if
  // it doesn't match an ongoing subscription. And the SUBSCRIBE only reaches
  // here if it doesn't match an ongoing subscription.
  if Request.IsSubscribe then begin
    Self.RejectForbidden(Request);
    Exit;
  end;

  Referral := TIdSipInboundReferral.CreateInbound(Self.UserAgent,
                                                  Request,
                                                  UsingSecureTransport);
  Self.NotifyOfSubscriptionRequest(Referral);
  Result := Referral;
end;

function TIdSipReferPackage.MimeType: String;
begin
  Result := SipFragmentMimeType;
end;

//* TIdSipEventPackage Private methods *****************************************

procedure TIdSipReferPackage.RejectForbidden(Request: TIdSipRequest);
var
  Response: TIdSipResponse;
begin
  Response := Self.UserAgent.CreateResponse(Request, SIPForbidden);
  try
    Self.UserAgent.SendResponse(Response);
  finally
    Response.Free;
  end;
end;

//******************************************************************************
//* TIdSipTargetDialogPackage                                                  *
//******************************************************************************
//* TIdSipTargetDialogPackage Public methods ***********************************

class function TIdSipTargetDialogPackage.EventPackage: String;
begin
  Result := PackageTargetDialog;
end;

//******************************************************************************
//* TIdSipNotify                                                               *
//******************************************************************************
//* TIdSipNotify Public methods ************************************************

class function TIdSipNotify.Method: String;
begin
  Result := MethodNotify;
end;

//******************************************************************************
//* TIdSipOutboundNotifyBase                                                   *
//******************************************************************************
//* TIdSipOutboundNotifyBase Public methods ************************************

procedure TIdSipOutboundNotifyBase.Send;
var
  Notify: TIdSipRequest;
begin
  inherited Send;

  Notify := Self.CreateNewAttempt;
  try
    Self.InitialRequest.Assign(Notify);
    Self.SendRequest(Notify);
  finally
    Notify.Free;
  end;
end;

//* TIdSipOutboundNotifyBase Protected methods *********************************

procedure TIdSipOutboundNotifyBase.ConfigureAttempt(Notify: TIdSipRequest);
begin
  Notify.Body          := Self.Body;
  Notify.ContentLength := Length(Notify.Body);
  Notify.ContentType   := Self.MimeType;
end;

function TIdSipOutboundNotifyBase.CreateNewAttempt: TIdSipRequest;
begin
  Result := Self.Module.CreateNotify(Self.Dialog,
                                     Self.Subscribe,
                                     '');
  Self.ConfigureAttempt(Result);
end;

procedure TIdSipOutboundNotifyBase.Initialise(UA: TIdSipAbstractCore;
                                              Request: TIdSipRequest;
                                              UsingSecureTransport: Boolean);
begin
  inherited Initialise(UA, Request, UsingSecureTransport);

  // NOTIFYs are always owned by a Subscription or Referral
  Self.fIsOwned := true;

  Self.Module := Self.UA.ModuleFor(Self.Method) as TIdSipSubscribeModule;
  Assert(Assigned(Self.Module),
         'The Transaction-User layer cannot process NOTIFY methods without adding the Subscribe module to it');
end;

//******************************************************************************
//* TIdSipOutboundNotify                                                       *
//******************************************************************************
//* TIdSipOutboundNotify Public methods ****************************************

procedure TIdSipOutboundNotify.AddListener(Listener: IIdSipNotifyListener);
begin
  Self.Listeners.AddListener(Listener);
end;

procedure TIdSipOutboundNotify.RemoveListener(Listener: IIdSipNotifyListener);
begin
  Self.Listeners.RemoveListener(Listener);
end;

//* TIdSipOutboundNotify Protected methods *************************************

procedure TIdSipOutboundNotify.ConfigureAttempt(Notify: TIdSipRequest);
begin
  inherited ConfigureAttempt(Notify);

  Assert(Self.Expires > 0,
         'Don''t send a NOTIFY with a zero expires: if you want to terminate a '
       + 'subscription send a NOTIFY with a Subscription-State of "terminated"');

  Notify.SubscriptionState.SubState := Self.SubscriptionState;
  Notify.SubscriptionState.Expires  := Self.Expires;
end;

procedure TIdSipOutboundNotify.NotifyOfFailure(Response: TIdSipResponse);
var
  Notification: TIdSipNotifyFailedMethod;
begin
  Notification := TIdSipNotifyFailedMethod.Create;
  try
    Notification.Notify   := Self;
    Notification.Response := Response;

    Self.Listeners.Notify(Notification);
  finally
    Notification.Free;
  end;

  Self.MarkAsTerminated;
end;

//******************************************************************************
//* TIdSipOutboundTerminatingNotify                                            *
//******************************************************************************
//* TIdSipOutboundTerminatingNotify Public methods *****************************

procedure TIdSipOutboundTerminatingNotify.ConfigureAttempt(Notify: TIdSipRequest);
begin
  inherited ConfigureAttempt(Notify);

  Notify.SubscriptionState.SubState := SubscriptionSubstateTerminated;
  Notify.SubscriptionState.Reason   := Self.Reason;
end;

//******************************************************************************
//* TIdSipSubscribeBase                                                        *
//******************************************************************************
//* TIdSipSubscribeBase Public methods *****************************************

class function TIdSipSubscribeBase.Method: String;
begin
  Result := MethodSubscribe;
end;

procedure TIdSipSubscribeBase.ReceiveRequest(Request: TIdSipRequest);
begin
       if Request.IsNotify    then Self.ReceiveNotify(Request)
  else if Request.IsRefer     then Self.ReceiveRefer(Request)
  else if Request.IsSubscribe then Self.ReceiveSubscribe(Request)
  else
    inherited ReceiveRequest(Request);
end;

//* TIdSipSubscribeBase Protected methods **************************************

procedure TIdSipSubscribeBase.ReceiveNotify(Notify: TIdSipRequest);
begin
  Assert(Notify.IsNotify,
         'TIdSipSubscribeBase.ReceiveNotify must only receive NOTIFYs');
  // By default do nothing
end;

procedure TIdSipSubscribeBase.ReceiveRefer(Refer: TIdSipRequest);
begin
  Assert(Refer.IsRefer,
         'TIdSipSubscribeBase.ReceiveRefer must only receive REFERs');
  // By default do nothing
end;

procedure TIdSipSubscribeBase.ReceiveSubscribe(Subscribe: TIdSipRequest);
begin
  Assert(Subscribe.IsSubscribe,
         'TIdSipSubscribeBase.ReceiveSubscribe must only receive SUBSCRIBEs');
  // By default do nothing
end;

//******************************************************************************
//* TIdSipSubscribe                                                            *
//******************************************************************************
//* TIdSipSubscribe Protected methods ******************************************

function TIdSipSubscribe.CreateNewAttempt: TIdSipRequest;
var
  TempTo: TIdSipToHeader;
begin
  TempTo := TIdSipToHeader.Create;
  try
    TempTo.Address := Self.InitialRequest.RequestUri;

    Result := Self.Module.CreateSubscribe(TempTo, Self.EventPackage);
    Result.Event.ID := Self.ID;
  finally
    TempTo.Free;
  end;
end;

procedure TIdSipSubscribe.Initialise(UA: TIdSipAbstractCore;
                                     Request: TIdSipRequest;
                                     UsingSecureTransport: Boolean);
begin
  inherited Initialise(UA, Request, UsingSecureTransport);

  // I am always owned by a Subscription or Referral.
  Self.fIsOwned := true;

  Self.Module := Self.UA.ModuleFor(Self.Method) as TIdSipSubscribeModule;
  Assert(Assigned(Self.Module),
         'The Transaction-User layer cannot process SUBSCRIBE methods without adding the Subscribe module to it');
end;

//******************************************************************************
//* TIdSipOutboundSubscribe                                                    *
//******************************************************************************
//* TIdSipOutboundSubscribe Public methods *************************************

destructor TIdSipOutboundSubscribe.Destroy;
begin
  Self.fTarget.Free;

  inherited Destroy;
end;

procedure TIdSipOutboundSubscribe.AddListener(Listener: IIdSipSubscribeListener);
begin
  Self.Listeners.AddListener(Listener);
end;

function TIdSipOutboundSubscribe.Match(Msg: TIdSipMessage): Boolean;
begin
  Result := false;

  if Msg.IsResponse then begin
    Result := Self.InitialRequest.CSeq.Equals(Msg.CSeq)
          and (Self.InitialRequest.CallID = Msg.CallID)
          and (Self.InitialRequest.From.Tag = Msg.From.Tag);
  end;
end;

procedure TIdSipOutboundSubscribe.RemoveListener(Listener: IIdSipSubscribeListener);
begin
  Self.Listeners.RemoveListener(Listener);
end;

procedure TIdSipOutboundSubscribe.Send;
var
  Sub: TIdSipRequest;
begin
  inherited Send;

  Sub := Self.CreateNewAttempt;
  try
    Self.InitialRequest.Assign(Sub);

    Self.SendRequest(Sub);
  finally
    Sub.Free;
  end;
end;

//* TIdSipOutboundSubscribe Protected methods **********************************

function TIdSipOutboundSubscribe.CreateNewAttempt: TIdSipRequest;
begin
  Result := Self.Module.CreateSubscribe(Self.Target, Self.EventPackage);
  Result.Event.ID             := Self.ID;
  Result.Expires.NumericValue := Self.Duration;
end;

procedure TIdSipOutboundSubscribe.Initialise(UA: TIdSipAbstractCore;
                                             Request: TIdSipRequest;
                                             UsingSecureTransport: Boolean);
begin
  inherited Initialise(UA, Request, UsingSecureTransport);

  Self.fTarget := TIdSipAddressHeader.Create;
end;

procedure TIdSipOutboundSubscribe.NotifyOfFailure(Response: TIdSipResponse);
var
  Notification: TIdSipOutboundSubscribeFailedMethod;
begin
  Notification := TIdSipOutboundSubscribeFailedMethod.Create;
  try
    Notification.Response  := Response;
    Notification.Subscribe := Self;

    Self.Listeners.Notify(Notification);
  finally
    Notification.Free;
  end;
end;

function TIdSipOutboundSubscribe.ReceiveOKResponse(Response: TIdSipResponse;
                                                   UsingSecureTransport: Boolean): TIdSipActionResult;
begin
  Result := inherited ReceiveOKResponse(Response, UsingSecureTransport);

  Self.NotifyOfSuccess(Response);
end;

//* TIdSipOutboundSubscribe Private methods ************************************

procedure TIdSipOutboundSubscribe.NotifyOfSuccess(Response: TIdSipResponse);
var
  Notification: TIdSipOutboundSubscribeSucceededMethod;
begin
  Notification := TIdSipOutboundSubscribeSucceededMethod.Create;
  try
    Notification.Response  := Response;
    Notification.Subscribe := Self;

    Self.Listeners.Notify(Notification);
  finally
    Notification.Free;
  end;
end;

procedure TIdSipOutboundSubscribe.SetTarget(Value: TIdSipAddressHeader);
begin
  Self.Target.Assign(Value);
end;

//******************************************************************************
//* TIdSipOutboundRefreshSubscribe                                             *
//******************************************************************************
//* TIdSipOutboundRefreshSubscribe Public methods ******************************

procedure TIdSipOutboundRefreshSubscribe.Send;
var
  Sub: TIdSipRequest;
begin
  inherited Send;

  Sub := Self.CreateNewAttempt;
  try
    Self.InitialRequest.Assign(Sub);

    Self.SendRequest(Sub);
  finally
    Sub.Free;
  end;
end;

//* TIdSipOutboundRefreshSubscribe Protected methods ***************************

function TIdSipOutboundRefreshSubscribe.CreateNewAttempt: TIdSipRequest;
begin
  Result := Self.Module.CreateSubscribe(Self.Dialog, Self.EventPackage);
  Result.Event.ID             := Self.ID;
  Result.Expires.NumericValue := Self.Duration;
end;

//******************************************************************************
//* TIdSipOutboundUnSubscribe                                                  *
//******************************************************************************
//* TIdSipOutboundUnSubscribe Public methods ***********************************

procedure TIdSipOutboundUnsubscribe.Send;
var
  Sub: TIdSipRequest;
begin
  inherited Send;

  Sub := Self.Module.CreateSubscribe(Self.Target, Self.EventPackage);
  try
    Sub.CallID                    := Self.CallID;
    Sub.Event.ID             := Self.ID;
    Sub.Expires.NumericValue := 0;
    Sub.From.Tag                  := Self.FromTag;
    Self.InitialRequest.Assign(Sub);

    Self.SendRequest(Sub);
  finally
    Sub.Free;
  end;
end;

//******************************************************************************
//* TIdSipRefer                                                                *
//******************************************************************************
//* TIdSipRefer Public methods *************************************************

class function TIdSipRefer.Method: String;
begin
  Result := MethodRefer;
end;

constructor TIdSipRefer.Create(UA: TIdSipAbstractCore);
begin
  inherited Create(UA);

  Self.EventPackage := PackageRefer;
end;

//******************************************************************************
//* TIdSipInboundRefer                                                         *
//******************************************************************************
//* TIdSipInboundRefer Protected methods ***************************************

procedure TIdSipInboundRefer.ReceiveOtherRequest(Request: TIdSipRequest);
begin
  if Self.WrongNumberOfReferTos(Request) then begin
    Self.RejectBadRequest(Request);
    Exit;
  end;
end;

//* TIdSipInboundRefer Private methods *****************************************

procedure TIdSipInboundRefer.RejectBadRequest(Refer: TIdSipRequest);
begin
end;

function TIdSipInboundRefer.WrongNumberOfReferTos(Refer: TIdSipRequest): Boolean;
begin
  Result := false;
end;

//******************************************************************************
//* TIdSipOutboundRefer                                                        *
//******************************************************************************
//* TIdSipOutboundRefer Public methods *****************************************

class function TIdSipOutboundRefer.Method: String;
begin
  Result := MethodRefer;
end;

constructor TIdSipOutboundRefer.Create(UA: TIdSipAbstractCore);
begin
  inherited Create(UA);

  Self.fReferTo := TIdSipToHeader.Create;
end;

destructor TIdSipOutboundRefer.Destroy;
begin
  Self.ReferTo.Free;

  inherited Destroy;
end;

//* TIdSipOutboundRefer Protected methods **************************************

function TIdSipOutboundRefer.CreateNewAttempt: TIdSipRequest;
begin
  Result := Self.Module.CreateRefer(Self.Target, Self.ReferTo);
  Result.Event.ID             := Self.ID;
  Result.Expires.NumericValue := Self.Duration;
end;

//* TIdSipOutboundRefer Private methods ****************************************

procedure TIdSipOutboundRefer.SetReferTo(Value: TIdSipAddressHeader);
begin
  Self.fReferTo.Assign(Value);
end;

//******************************************************************************
//* TIdSipSubscription                                                         *
//******************************************************************************
//* TIdSipSubscription Public methods ******************************************

destructor TIdSipSubscription.Destroy;
begin
  Self.Package.Free;
  Self.Dialog.Free;

  inherited Destroy;
end;

procedure TIdSipSubscription.Expire;
begin
  // See subclasses' implementations
end;

function TIdSipSubscription.ExpiryTime: TDateTime;
begin
  Result := Self.fExpiryTime;
end;

function TIdSipSubscription.ExpiryTimeInSeconds: Integer;
begin
  Result := Trunc((Self.ExpiryTime - Now) / OneTDateTimeSecond);
end;

//* TIdSipSubscription Protected methods ***************************************

function TIdSipSubscription.CreateNewAttempt: TIdSipRequest;
begin
  Result := Self.Module.CreateSubscribe(Self.Target, Self.EventPackage);
  Result.Event.ID             := Self.ID;
  Result.Expires.NumericValue := Self.Duration;
end;

function TIdSipSubscription.DialogEstablished: Boolean;
begin
  Result := Assigned(Self.Dialog);
end;

procedure TIdSipSubscription.EstablishDialog(Response: TIdSipResponse);
begin
  if not Self.DialogEstablished then
    Self.Dialog := Self.CreateDialog(Response);
end;

procedure TIdSipSubscription.Initialise(UA: TIdSipAbstractCore;
                                        Request: TIdSipRequest;
                                        UsingSecureTransport: Boolean);
begin
  inherited Initialise(UA, Request, UsingSecureTransport);

  Self.fTerminating := false;

  Self.Module := Self.UA.ModuleFor(Self.Method) as TIdSipSubscribeModule;
  Assert(Assigned(Self.Module),
         'The Transaction-User layer cannot process SUBSCRIBE methods without adding the Subscribe module to it');
end;

procedure TIdSipSubscription.SetEventPackage(const Value: String);
begin
  Self.fEventPackage := Value;

  if Assigned(Self.Package) then
    FreeAndNil(Self.Package);

  Self.Package := Self.Module.Package(Self.EventPackage).Clone;
end;

procedure TIdSipSubscription.SetExpiryTime(Value: TDateTime);
begin
  Self.fExpiryTime := Value;
end;

procedure TIdSipSubscription.SetSubscriptionState(const Value: String);
begin
  Self.fSubscriptionState := Value;
end;

procedure TIdSipSubscription.SetTerminating(Value: Boolean);
begin
  Self.fTerminating := Value;
end;

//* TIdSipSubscription Private methods *****************************************

procedure TIdSipSubscription.OnAuthenticationChallenge(Action: TIdSipAction;
                                                       Challenge: TIdSipResponse);
begin
  // NOTIFYs that get challenged aren't visible outside this session, so we
  // re-notify of the authentication challenge.
  Self.NotifyOfAuthenticationChallenge(Challenge);
end;

procedure TIdSipSubscription.OnNetworkFailure(Action: TIdSipAction;
                                              ErrorCode: Cardinal;
                                              const Reason: String);
begin
  Self.NotifyOfNetworkFailure(ErrorCode, Reason);
end;

//******************************************************************************
//* TIdSipInboundSubscription                                                  *
//******************************************************************************
//* TIdSipInboundSubscription Public methods ***********************************

procedure TIdSipInboundSubscription.Accept;
var
  ActiveNotify: TIdSipRequest;
begin
  Assert(Self.DialogEstablished, SubscriptionDidntEstablishDialog);

  ActiveNotify := Self.Module.CreateNotify(Self.Dialog,
                                           Self.InitialRequest,
                                           SubscriptionSubstateActive);
  try
    Self.SetSubscriptionState(SubscriptionSubstateActive);
    Self.SendRequest(ActiveNotify);
  finally
    ActiveNotify.Free;
  end;
end;

procedure TIdSipInboundSubscription.Expire;
begin
  // This bears some explanation: During the course of a subscription, we
  // schedule several terminations: after all, when we establish a subscription
  // we know when we want it to expire, and invoke ScheduleTermination with the
  // appropriate time. If we refresh the subscription, we again know the new
  // expiry time, and schedule another termination. When
  // ExecutingLastScheduledExpires returns true, we know that we've not
  // rescheduled a termination, and that thus we must actually terminate the
  // subscription.
  Self.DecOutstandingExpires;

  if Self.ExecutingLastScheduledExpires then begin
    Self.TerminateSubscription(EventReasonTimeout);
  end;
end;

function TIdSipInboundSubscription.IsInbound: Boolean;
begin
  Result := true;
end;

function TIdSipInboundSubscription.Match(Msg: TIdSipMessage): Boolean;
begin
  if Msg.IsRequest then begin
    if (Msg as TIdSipRequest).IsSubscribe then
      Result := Self.DialogMatches(Msg)
    else
      Result := false;
  end
  else begin
    Result := inherited Match(Msg);
  end;
end;

procedure TIdSipInboundSubscription.Notify(const Body: String;
                                           const MimeType: String;
                                           const NewState: String = '';
                                           const Reason: String = '');
var
  Notify: TIdSipOutboundNotify;
begin
  // Don't set NewState to SubscriptionSubstateTerminated. You'll only confuse
  // everything. If you want to terminate the subscription, use the Terminate
  // method.

  if (NewState <> '') then
    Self.SetSubscriptionState(NewState);

  if (Self.SubscriptionState = SubscriptionSubstateTerminated) then begin
    Self.SendTerminatingNotify(Body, MimeType, Reason);
  end
  else begin
    Notify := Self.UA.AddOutboundAction(TIdSipOutboundNotify) as TIdSipOutboundNotify;
    Self.ConfigureNotify(Notify);
    Notify.Body              := Body;
    Notify.Expires           := Self.ExpiryTimeInSeconds;
    Notify.MimeType          := MimeType;
    Notify.SubscriptionState := Self.SubscriptionState;
    Notify.AddListener(Self);
    Notify.Send;
  end;
end;

procedure TIdSipInboundSubscription.Renotify;
begin
  Self.Notify(Self.Package.State, Self.Package.MimeType);
end;

procedure TIdSipInboundSubscription.Terminate;
begin
  Self.TerminateSubscription(EventReasonNoResource);
end;

//* TIdSipInboundSubscription Protected methods ********************************

function TIdSipInboundSubscription.CreateDialog(Response: TIdSipResponse): TIdSipDialog;
begin
  Result := TIdSipDialog.CreateInboundDialog(Self.InitialRequest,
                                             Response,
                                             false);
  Result.ReceiveResponse(Response);                                           
end;

procedure TIdSipInboundSubscription.EstablishDialog(Response: TIdSipResponse);
begin
  inherited EstablishDialog(Response);

  Self.InitialRequest.ToHeader.Tag := Self.Dialog.ID.LocalTag;
end;

function TIdSipInboundSubscription.GetEventPackage(Request: TIdSipRequest): String;
begin
  // All SUBSCRIBEs must have an Event header. The SubscribeModule rejects any
  // SUBSCRIBEs that don't have one.
  Result := Self.InitialRequest.Event.EventType;
end;

function TIdSipInboundSubscription.GetID(Request: TIdSipRequest): String;
begin
  Result := Self.InitialRequest.Event.ID;
end;

procedure TIdSipInboundSubscription.Initialise(UA: TIdSipAbstractCore;
                                               Request: TIdSipRequest;
                                               UsingSecureTransport: Boolean);
begin
  inherited Initialise(UA, Request, UsingSecureTransport);

  Self.UsingSecureTransport := UsingSecureTransport;
  Self.EventPackage := Self.GetEventPackage(Self.InitialRequest);
  Self.ID           := Self.GetID(Self.InitialRequest);

  // Self.Module.Package WILL return something, because the SubscribeModule
  // rejects all SUBSCRIBEs with unknown Event header values before we get
  // here.
//  Self.Package := Self.Module.Package(Self.EventPackage).Clone;
end;

procedure TIdSipInboundSubscription.ReceiveSubscribe(Request: TIdSipRequest);
begin
  // At this stage, we know we've a SUBSCRIBE request for a known event.

  inherited ReceiveSubscribe(Request);

  if Self.InitialRequest.Equals(Request) then begin
    if Self.WillAccept(Request) then begin
      Self.SetSubscriptionState(SubscriptionSubstatePending);
      Self.SendAccept(Request);
    end
    else
      Self.Terminate;
  end
  else begin
    // Request is a refresh SUBSCRIBE
    if Self.WillAccept(Request) then begin
      Self.ScheduleTermination(Request.Expires.NumericValue);
      Self.Dialog.ReceiveRequest(Request);
      Self.SendOk(Request);
    end;
    // In other words, we don't kill the subscription just because the Refresh's
    // Expires was too short.
  end;
end;

procedure TIdSipInboundSubscription.SendResponse(Response: TIdSipResponse);
begin
  inherited SendResponse(Response);

  if Response.IsOK then
    Self.NotifySubscriberOfState;
end;

function TIdSipInboundSubscription.WillAccept(Subscribe: TIdSipRequest): Boolean;
var
  Expires: Cardinal;
begin
  Result := false;

  if Subscribe.HasHeader(ExpiresHeader) then begin
    Expires := Subscribe.Expires.NumericValue;

    if (Expires < OneHour) and (Expires < Self.Package.MinimumExpiryTime) then
      Self.RejectExpiresTooBrief(Subscribe)
    else begin
      Result := true;
    end;
  end
  else
    Result := true;
end;

//* TIdSipInboundSubscription Private methods **********************************

procedure TIdSipInboundSubscription.ConfigureNotify(Notify: TIdSipOutboundNotifyBase);
begin
  Notify.Dialog    := Self.Dialog;
  Notify.Subscribe := Self.InitialRequest;
end;

function TIdSipInboundSubscription.CreateDialogIDFrom(Msg: TIdSipMessage): TIdSipDialogID;
begin
  // Call-ID, local tag, remote tag. We receive a SUBSCRIBE, so the dialog's an
  // inbound dialog. See TIdSipDialog.CreateInboundDialog.
  Result := TIdSipDialogID.Create(Msg.CallID,
                                  Msg.ToHeader.Tag,
                                  Msg.From.Tag);
end;

procedure TIdSipInboundSubscription.DecOutstandingExpires;
begin
  if (Self.OutstandingExpires > 0) then
    Dec(Self.OutstandingExpires);
end;

function TIdSipInboundSubscription.DialogMatches(DialogID: TIdSipDialogID): Boolean;
begin
  if Self.DialogEstablished then
    Result := Self.Dialog.ID.Equals(DialogID)
  else
    Result := false;
end;

function TIdSipInboundSubscription.DialogMatches(Msg: TIdSipMessage): Boolean;
var
  DialogID: TIdSipDialogID;
begin
  DialogID := Self.CreateDialogIDFrom(Msg);
  try
    Result := Self.DialogMatches(DialogID);
  finally
    DialogID.Free;
  end;
end;

function TIdSipInboundSubscription.ExecutingLastScheduledExpires: Boolean;
begin
  Result := Self.OutstandingExpires = 0;
end;

procedure TIdSipInboundSubscription.IncOutstandingExpires;
begin
  Inc(Self.OutstandingExpires);
end;

procedure TIdSipInboundSubscription.NotifySubscriberOfState;
begin
  Assert(Self.DialogEstablished,
         'You cannot send a NOTIFY when you''ve no dialog');

  Self.Notify(Self.Package.State,
              Self.Package.MimeType);
end;

procedure TIdSipInboundSubscription.OnFailure(NotifyAgent: TIdSipOutboundNotify;
                                              Response: TIdSipResponse);
begin
  if Response.CanRetryRequest
    and Response.HasHeader(RetryAfterHeader) then
    Self.ScheduleRenotify(Response.RetryAfter.NumericValue)
  else
    Self.MarkAsTerminated;
end;

procedure TIdSipInboundSubscription.OnSuccess(NotifyAgent: TIdSipOutboundNotify;
                                              Response: TIdSipResponse);
begin
end;

function TIdSipInboundSubscription.OurExpires(Subscribe: TIdSipRequest): Cardinal;
begin
  Result := Self.Package.InboundSubscriptionDuration;

  if Subscribe.HasHeader(ExpiresHeader) then begin
    if (Result > Subscribe.Expires.NumericValue) then
      Result := Subscribe.Expires.NumericValue;
  end
  else begin
    // SUBSCRIBEs SHOULD have an Expires (RFC 3265 section 3.1.1), but that
    // means they might not, so we ask the event package for a duration.
    Result := Self.Package.DefaultSubscriptionDuration;
  end;
end;

procedure TIdSipInboundSubscription.RejectExpiresTooBrief(Subscribe: TIdSipRequest);
var
  Response: TIdSipResponse;
begin
  Response := Self.UA.CreateResponse(Subscribe, SIPIntervalTooBrief);
  try
    Response.MinExpires.NumericValue := Self.Package.MinimumExpiryTime;

    Self.SendResponse(Response);
  finally
    Response.Free;
  end;
end;

procedure TIdSipInboundSubscription.ScheduleRenotify(Seconds: Cardinal);
begin
  Self.UA.ScheduleEvent(TIdSipSubscriptionRenotify,
                        Seconds*1000,
                        Self.InitialRequest);
end;

procedure TIdSipInboundSubscription.ScheduleTermination(Expires: Cardinal);
begin
  Self.IncOutstandingExpires;
  Self.SetExpiryTime(Now + Expires*OneTDateTimeSecond);
  // Expires contains a value in seconds
  Self.UA.ScheduleEvent(TIdSipSubscriptionExpires,
                        Expires*1000,
                        Self.InitialRequest);
end;

procedure TIdSipInboundSubscription.SendAccept(Subscribe: TIdSipRequest);
var
  Accepted: TIdSipResponse;
begin
  Accepted := Self.UA.CreateResponse(Subscribe, SIPAccepted);
  try
    Accepted.Expires.NumericValue := Self.OurExpires(Subscribe);

    Self.EstablishDialog(Accepted);
    Self.ScheduleTermination(Accepted.Expires.NumericValue);
    Self.SendResponse(Accepted);
  finally
    Accepted.Free;
  end;
end;

procedure TIdSipInboundSubscription.SendOk(Subscribe: TIdSipRequest);
var
  Ok: TIdSipResponse;
begin
  Ok := Self.UA.CreateResponse(Subscribe, SIPOK);
  try
    Ok.Expires.NumericValue := Self.OurExpires(Subscribe);

    Self.ScheduleTermination(Ok.Expires.NumericValue);
    Self.SendResponse(Ok);
  finally
    Ok.Free;
  end;
end;

procedure TIdSipInboundSubscription.SendTerminatingNotify(const Body: String;
                                                          const MimeType: String;
                                                          const Reason: String);
var
  Terminator: TIdSipOutboundTerminatingNotify;
begin
  Terminator := Self.UA.AddOutboundAction(TIdSipOutboundTerminatingNotify) as TIdSipOutboundTerminatingNotify;
  Self.ConfigureNotify(Terminator);
  Terminator.Body     := Body;
  Terminator.MimeType := MimeType;
  Terminator.Reason   := Reason;

  Terminator.Send;

  Self.MarkAsTerminated;
end;

procedure TIdSipInboundSubscription.TerminateSubscription(const Reason: String);
begin
  Self.SetSubscriptionState(SubscriptionSubstateTerminated);

  if Self.DialogEstablished then
    Self.SendTerminatingNotify(Self.Package.State,
                               Self.Package.MimeType,
                               Reason);
  Self.MarkAsTerminated;
end;

//******************************************************************************
//* TIdSipOutboundSubscription                                                 *
//******************************************************************************
//* TIdSipOutboundSubscription Public methods **********************************

procedure TIdSipOutboundSubscription.AddListener(Listener: IIdSipSubscriptionListener);
begin
  Self.Listeners.AddListener(Listener);
end;

procedure TIdSipOutboundSubscription.Expire;
begin
  Self.Terminate;
end;

function TIdSipOutboundSubscription.Match(Msg: TIdSipMessage): Boolean;
var
  Req: TIdSipRequest;
begin
  Result := false;
  if Msg.IsRequest then begin
    Req := Msg as TIdSipRequest;

    // RFC 3261, section 12.2.1.1 explains the From/To tag business: the
    // notifier creates requests as a UAC, and so puts its remote tag (our
    // From tag) in the To tag and its local tag (our To tag) in the From tag.
    if Req.IsNotify then begin
      Result := (Self.InitialRequest.CallID = Req.CallID)
            and (Self.InitialRequest.From.Tag = Req.ToHeader.Tag)
            and Req.HasHeader(EventHeaderFull)
            and (Self.InitialRequest.Event.Equals(Req.Event));
    end
    else if Req.IsSubscribe then
      Result := inherited Match(Msg);
  end
    else
      Result := inherited Match(Msg);
end;

procedure TIdSipOutboundSubscription.Refresh(NewDuration: Cardinal);
var
  RefreshSubscribe: TIdSipOutboundSubscribe;
begin
  // cf. RFC 3265, section 3.1.4.2.

  RefreshSubscribe := Self.CreateRefresh(NewDuration);
  RefreshSubscribe.Send;
end;

procedure TIdSipOutboundSubscription.RemoveListener(Listener: IIdSipSubscriptionListener);
begin
  Self.Listeners.RemoveListener(Listener);
end;

procedure TIdSipOutboundSubscription.Send;
begin
  inherited Send;

  Self.ConfigureRequest(Self.InitialSubscribe);
  Self.InitialSubscribe.Send;
  Self.InitialRequest.Assign(Self.InitialSubscribe.InitialRequest);
  Self.ID := Self.InitialSubscribe.ID;
end;

procedure TIdSipOutboundSubscription.Terminate;
begin
  // Precondition: You've invoked Self.Send.
  Assert(Self.State in [asSent, asResent],
         'Unexpected state; Ord(State) = ' + IntToStr(Ord(Self.State)));

  Self.Unsubscriber := Self.CreateUnsubscribe;
  Self.Unsubscriber.Send;
  Self.SetTerminating(true);
end;

procedure TIdSipOutboundSubscription.Unsubscribe;
begin
  Self.Terminate;
end;

//* TIdSipOutboundSubscription Protected methods *******************************

procedure TIdSipOutboundSubscription.ConfigureRequest(Sub: TIdSipOutboundSubscribe);
begin
  Sub.Duration     := Self.Duration;
  Sub.EventPackage := Self.EventPackage;
  Sub.ID           := Self.ID;
  Sub.Target       := Self.Target;
end;

function TIdSipOutboundSubscription.CreateDialog(Response: TIdSipResponse): TIdSipDialog;
begin
  Result := TIdSipDialog.CreateOutboundDialog(Self.InitialRequest,
                                              Response,
                                              false);
end;

function TIdSipOutboundSubscription.CreateOutboundSubscribe: TIdSipOutboundSubscribe;
begin
  Result := Self.UA.AddOutboundAction(TIdSipOutboundSubscribe) as TIdSipOutboundSubscribe;
  Result.AddListener(Self);
end;

procedure TIdSipOutboundSubscription.Initialise(UA: TIdSipAbstractCore;
                                                Request: TIdSipRequest;
                                                UsingSecureTransport: Boolean);
begin
  inherited Initialise(UA, Request, UsingSecureTransport);

  Self.InitialSubscribe := Self.CreateOutboundSubscribe;
end;

procedure TIdSipOutboundSubscription.NotifyOfFailure(Response: TIdSipResponse);
var
  Notification: TIdSipFailedSubscriptionMethod;
begin
  Notification := TIdSipFailedSubscriptionMethod.Create;
  try
    Notification.Subscription := Self;
    Notification.Response     := Response;

    Self.Listeners.Notify(Notification);
  finally
    Notification.Free;
  end;
end;

procedure TIdSipOutboundSubscription.ReceiveNotify(Notify: TIdSipRequest);
var
  State: TIdSipSubscriptionStateHeader;
begin
  // Precondition: Request contains a NOTIFY.
  inherited ReceiveNotify(Notify);
{
  // No authorisation credentials? Reject with a 401 Unauthorized.
  if not Notify.HasAuthorization then begin
    Self.RejectUnauthorized(Notify);
    Exit;
  end;

  // Incorrect authorisation credentials? Reject with a 401 Unauthorized.
  if not Self.UA.Authenticator.AuthenticateAsUserAgent(Notify) then begin
    Self.RejectUnauthorized(Notify);
    Exit;
  end;
}
  // cf. RFC 3265, section 3.2.4
  Self.NotifyOfReceivedNotify(Notify);

  State := Notify.SubscriptionState;

  if State.IsActive then begin
    if (State.Expires > 0) then
      Self.RescheduleRefresh(State.Expires);

    Self.NotifyOfSuccess(Notify);
  end
  else if State.IsPending then begin
    if (State.Expires > 0) then
      Self.RescheduleRefresh(State.Expires);
  end
  else if State.IsTerminated then begin
    Self.StartNewSubscription(Notify);
    Self.NotifyOfExpiredSubscription(Notify);
    Self.MarkAsTerminated;
  end;

  Self.SendResponseFor(Notify);
end;

procedure TIdSipOutboundSubscription.SetEventPackage(const Value: String);
begin
  inherited SetEventPackage(Value);

  Self.Duration := Self.Module.Package(Value).DefaultSubscriptionDuration;
end;

procedure TIdSipOutboundSubscription.StartNewSubscription(Notify: TIdSipRequest);
var
  SubState: TIdSipSubscriptionStateHeader;
begin
  SubState := Notify.SubscriptionState;

  case SubState.ReasonType of
    ssrDeactivated, ssrTimeout:
      Self.Module.Resubscribe(Self.Target, Self.EventPackage).Send;

    ssrGiveUp: begin
      if SubState.HasRetryAfter then
        Self.ScheduleNewSubscription(SubState.RetryAfter)
      else
        Self.Module.Resubscribe(Self.Target, Self.EventPackage)
    end;

    ssrNoResource, ssrRejected:; // do nothing

    ssrProbation, ssrNoReason, ssrUnknownReason:
      Self.ScheduleSubscriptionAt(SubState, Self.Package.ProbationRetryTime);
  else
    // In case we missed anything else:
    Self.ScheduleSubscriptionAt(SubState, Self.Package.ProbationRetryTime);
  end;
end;

//* TIdSipOutboundSubscription Private methods *********************************

function TIdSipOutboundSubscription.CreateRefresh(NewDuration: Cardinal): TIdSipOutboundRefreshSubscribe;
begin
  Result := Self.UA.AddOutboundAction(TIdSipOutboundRefreshSubscribe) as TIdSipOutboundRefreshSubscribe;
  Result.Dialog   := Self.Dialog;
  Result.Duration := NewDuration;
  Self.ConfigureRequest(Result);
  Result.AddListener(Self);
end;

function TIdSipOutboundSubscription.CreateUnsubscribe: TIdSipOutboundUnsubscribe;
begin
  Result := Self.UA.AddOutboundAction(TIdSipOutboundUnsubscribe) as TIdSipOutboundUnsubscribe;

  // You'd think we'd ask Self.Dialog. However, we can terminate the
  // subscription before we receive a response from the notifier - in other
  // words, before the dialog's established.
  Result.CallID  := Self.InitialRequest.CallID;
  Result.FromTag := Self.InitialRequest.From.Tag;
  Self.ConfigureRequest(Result);
  Result.AddListener(Self);  
end;

procedure TIdSipOutboundSubscription.NotifyOfExpiredSubscription(Notify: TIdSipRequest);
var
  Notification: TIdSipExpiredSubscriptionMethod;
begin
  Notification := TIdSipExpiredSubscriptionMethod.Create;
  try
    Notification.Notify       := Notify;
    Notification.Subscription := Self;

    Self.Listeners.Notify(Notification);
  finally
    Notification.Free;
  end;
end;

procedure TIdSipOutboundSubscription.NotifyOfReceivedNotify(Notify: TIdSipRequest);
var
  Notification: TIdSipSubscriptionNotifyMethod;
begin
  Notification := TIdSipSubscriptionNotifyMethod.Create;
  try
    Notification.Notify       := Notify;
    Notification.Subscription := Self;

    Self.Listeners.Notify(Notification);
  finally
    Notification.Free;
  end;
end;

procedure TIdSipOutboundSubscription.NotifyOfSuccess(Notify: TIdSipRequest);
var
  Notification: TIdSipEstablishedSubscriptionMethod;
begin
  Notification := TIdSipEstablishedSubscriptionMethod.Create;
  try
    Notification.Subscription := Self;
    Notification.Notify       := Notify;

    Self.Listeners.Notify(Notification);
  finally
    Notification.Free;
  end;
end;

procedure TIdSipOutboundSubscription.OnFailure(SubscribeAgent: TIdSipOutboundSubscribe;
                                               Response: TIdSipResponse);
begin
  if (Self.InitialSubscribe = SubscribeAgent) then begin
    Self.NotifyOfFailure(Response);
    Self.MarkAsTerminated;
  end
  else if (Self.Unsubscriber = SubscribeAgent) then begin
    Assert(Self.Terminating,
           'Not flagged as Terminating but the Unsubscriber just failed.');
    Self.Unsubscriber := nil;
    Self.MarkAsTerminated;
  end
  else begin
    // A refreshing Subscribe
    if (Response.StatusCode = SIPCallLegOrTransactionDoesNotExist) then
      Self.NotifyOfFailure(Response);
    // Adjust the expiry time? Schedule a new refresh?
  end
end;

procedure TIdSipOutboundSubscription.OnSuccess(SubscribeAgent: TIdSipOutboundSubscribe;
                                               Response: TIdSipResponse);
begin
  if (Self.Unsubscriber = SubscribeAgent) then
    Exit;

  if (Self.InitialSubscribe = SubscribeAgent) then begin
    Self.InitialRequest.Assign(SubscribeAgent.InitialRequest);
    Self.EstablishDialog(Response);
  end;

  if Response.HasHeader(ExpiresHeader) then
    Self.RescheduleRefresh(Response.Expires.NumericValue)
  else begin
    // We shouldn't actually ever reach this: notifiers MUST have an Expires
    // header.
    Self.RescheduleRefresh(Self.Duration);
  end;
end;
{
procedure TIdSipOutboundSubscription.RejectUnauthorized(Notify: TIdSipRequest);
var
  Response: TIdSipResponse;
begin
  Response := Self.UA.CreateChallengeResponseAsUserAgent(Notify);
  try
    Self.SendResponse(Response);
  finally
    Response.Free;
  end;
end;
}
procedure TIdSipOutboundSubscription.RescheduleRefresh(NewDuration: Cardinal);
begin
  Self.SetExpiryTime(Now + NewDuration*OneTDateTimeSecond);

  // NewDuration is in seconds
  Self.UA.ScheduleEvent(TIdSipOutboundSubscriptionRefresh,
                        NewDuration*1000,
                        Self.InitialRequest);
end;

procedure TIdSipOutboundSubscription.ScheduleNewSubscription(Seconds: Cardinal);
var
  Wait: TIdSipSubscriptionRetryWait;
begin
  Wait := TIdSipSubscriptionRetryWait.Create;
  Wait.EventPackage := Self.EventPackage;
  Wait.Target       := Self.Target;
  Wait.UserAgent    := Self.UA;
  Self.UA.ScheduleEvent(Seconds*1000, Wait);
end;

procedure TIdSipOutboundSubscription.ScheduleSubscriptionAt(SubscriptionState: TIdSipSubscriptionStateHeader;
                                                            DefaultSeconds: Cardinal);
begin
  if SubscriptionState.HasRetryAfter then
    Self.ScheduleNewSubscription(SubscriptionState.RetryAfter)
  else
    Self.ScheduleNewSubscription(DefaultSeconds);
end;

procedure TIdSipOutboundSubscription.SendResponseFor(Notify: TIdSipRequest);
var
  Response: TIdSipResponse;
begin
  Response := TIdSipResponse.InResponseTo(Notify, SIPOK);
  try
    Self.SendResponse(Response);
  finally
    Response.Free;
  end;
end;

//******************************************************************************
//* TIdSipInboundReferral                                                      *
//******************************************************************************
//* TIdSipInboundReferral Public methods ***************************************

class function TIdSipInboundReferral.Method: String;
begin
  Result := MethodRefer;
end;

class function TIdSipInboundReferral.ReferralDeniedBody: String;
begin
  Result := 'SIP/2.0 603 Declined';
end;

class function TIdSipInboundReferral.ReferralFailedBody: String;
begin
  Result := 'SIP/2.0 503 Service Unavailable';
end;

class function TIdSipInboundReferral.ReferralSucceededBody: String;
begin
  Result := 'SIP/2.0 200 OK';
end;

class function TIdSipInboundReferral.ReferralTryingBody: String;
begin
  Result := 'SIP/2.0 100 Trying';
end;

procedure TIdSipInboundReferral.Notify(const Body: String;
                                       const MimeType: String;
                                       const NewState: String = '';
                                       const Reason: String = '');
begin
  if (MimeType <> SipFragmentMimeType) or (Body = '') then
    raise EIdSipTransactionUser.Create(BadReferNotifyBody);

  Self.Package.State := Body;
  
  inherited Notify(Body, MimeType, NewState, Reason);
end;

procedure TIdSipInboundReferral.ReferenceDenied;
begin
  Self.Notify(Self.ReferralDeniedBody,
              SipFragmentMimeType,
              SubscriptionSubstateTerminated,
              EventReasonNoResource);
end;

procedure TIdSipInboundReferral.ReferenceFailed;
begin
  Self.Notify(Self.ReferralFailedBody,
              SipFragmentMimeType,
              SubscriptionSubstateTerminated,
              EventReasonNoResource);
end;

procedure TIdSipInboundReferral.ReferenceSucceeded;
begin
  Self.Notify(Self.ReferralSucceededBody,
              SipFragmentMimeType,
              SubscriptionSubstateTerminated,
              EventReasonNoResource);
end;

procedure TIdSipInboundReferral.ReferenceTrying;
begin
  Self.Notify(Self.ReferralTryingBody,
              SipFragmentMimeType,
              SubscriptionSubstateTerminated,
              EventReasonNoResource);
end;

//* TIdSipInboundReferral Protected methods ************************************

function TIdSipInboundReferral.GetEventPackage(Request: TIdSipRequest): String;
begin
  // REFERs don't have Event headers.
  Result := PackageRefer;
end;

function TIdSipInboundReferral.GetID(Request: TIdSipRequest): String;
begin
  // REFERs don't have Event headers.
  Result := '';
end;

procedure TIdSipInboundReferral.ReceiveRefer(Refer: TIdSipRequest);
begin
  inherited ReceiveRefer(Refer);

  if Self.WillAccept(Refer) then begin
    Self.SetSubscriptionState(SubscriptionSubstatePending);
    Self.Package.State := Self.ReferralTryingBody;
    Self.SendAccept(Refer);
  end;
end;

function TIdSipInboundReferral.WillAccept(Refer: TIdSipRequest): Boolean;
begin
  Result := inherited WillAccept(Refer);

  if Result then begin
    if Self.WrongNumberOfReferTos(Refer) then
      Self.RejectBadRequest(Refer)
    else if Self.HasUnknownUrlScheme(Refer) then
      Self.RejectBadRequest(Refer)
    else
      Result := true;
  end;
end;

//* TIdSipInboundReferral Private methods **************************************

function TIdSipInboundReferral.HasUnknownUrlScheme(Refer: TIdSipRequest): Boolean;
begin
  Result := not Refer.ReferTo.Address.IsSipUri
        and not Refer.ReferTo.Address.IsSipsUri;
end;

procedure TIdSipInboundReferral.RejectBadRequest(Request: TIdSipRequest);
var
  Response: TIdSipResponse;
begin
  Response := Self.UA.CreateResponse(Request, SIPBadRequest);
  try
    Self.SendResponse(Response);
  finally
    Response.Free;
  end;
end;

function TIdSipInboundReferral.WrongNumberOfReferTos(Refer: TIdSipRequest): Boolean;
var
  ReferToHeaders: TIdSipHeadersFilter;
begin
  ReferToHeaders := TIdSipHeadersFilter.Create(Refer.Headers, ReferToHeaderFull);
  try
    Result := ReferToHeaders.Count <> 1;
  finally
    ReferToHeaders.Free;
  end;
end;

//******************************************************************************
//* TIdSipOutboundReferral                                                     *
//******************************************************************************
//* TIdSipOutboundReferral Public methods **************************************

class function TIdSipOutboundReferral.Method: String;
begin
  Result := MethodRefer;
end;

procedure TIdSipOutboundReferral.Send;
begin
  Self.EventPackage := PackageRefer;

  inherited Send;
end;

//* TIdSipOutboundReferral Protected methods ***********************************

procedure TIdSipOutboundReferral.ConfigureRequest(Sub: TIdSipOutboundSubscribe);
var
  Refer: TIdSipOutboundRefer;
begin
  inherited ConfigureRequest(Sub);

  // Refreshing or terminating the subscription sends a SUBSCRIBE request, and
  // hence a TIdSipOutboundSubscribe or TIdSipOutboundUnsubscribe, not a
  // TIdSipOutboundRefer.

  // However, an initial OutboundSubscribe will actually be an OutboundRefer:
  if (Sub is TIdSipOutboundRefer) then begin
    Refer := Sub as TIdSipOutboundRefer;
    Refer.ReferTo := Self.ReferredResource;
  end;
end;

function TIdSipOutboundReferral.CreateNewAttempt: TIdSipRequest;
begin
  Result := Self.Module.CreateRefer(Self.Target, Self.ReferredResource);
  Result.Event.ID             := Self.ID;
  Result.Expires.NumericValue := Self.Duration;
end;

function TIdSipOutboundReferral.CreateOutboundSubscribe: TIdSipOutboundSubscribe;
begin
  Result := Self.UA.AddOutboundAction(TIdSipOutboundRefer) as TIdSipOutboundRefer;
  Result.AddListener(Self);
end;

procedure TIdSipOutboundReferral.Initialise(UA: TIdSipAbstractCore;
                                            Request: TIdSipRequest;
                                            UsingSecureTransport: Boolean);
begin
  inherited Initialise(UA, Request, UsingSecureTransport);

  Self.fReferredResource := TIdSipAddressHeader.Create;
end;

procedure TIdSipOutboundReferral.StartNewSubscription(Notify: TIdSipRequest);
begin
  // REFERs don't resubscribe: the subscription's terminated, so the REFER
  // call flow's completed.
  // cf. RFC 3515, section 2.4.7:
  //   If a NOTIFY indicates a reason that indicates a re-subscribe is
  //   appropriate according to  [2], the agent sending the REFER is NOT
  //   obligated to re-subscribe.
end;

//* TIdSipOutboundReferral Private methods *************************************

procedure TIdSipOutboundReferral.SetReferredResource(Value: TIdSipAddressHeader);
begin
  Self.fReferredResource.Assign(Value);
end;

//******************************************************************************
//* TIdSipSubscriptionExpires                                                  *
//******************************************************************************
//* TIdSipSubscriptionExpires Public methods ***********************************

procedure TIdSipSubscriptionExpires.Execute(Action: TIdSipAction);
var
  Sub: TIdSipSubscription;
begin
  if not (Action is TIdSipSubscription) then Exit;

  Sub := Action as TIdSipSubscription;

  if not Sub.Terminating then
    Sub.Expire;
end;

//******************************************************************************
//* TIdSipSubscriptionRenotify
//******************************************************************************
//* TIdSipSubscriptionRenotify Public methods **********************************

procedure TIdSipSubscriptionRenotify.Execute(Action: TIdSipAction);
var
  Sub: TIdSipInboundSubscription;
begin
  if not (Action is TIdSipInboundSubscription) then Exit;

  Sub := Action as TIdSipInboundSubscription;

  Sub.Renotify;
end;

//******************************************************************************
//* TIdSipOutboundSubscriptionRefresh                                          *
//******************************************************************************
//* TIdSipOutboundSubscriptionRefresh Public methods ***************************

procedure TIdSipOutboundSubscriptionRefresh.Execute(Action: TIdSipAction);
var
  Subscription: TIdSipOutboundSubscription;
begin
  if not (Action is TIdSipOutboundSubscription) then Exit;

  Subscription := Action as TIdSipOutboundSubscription;

  if not Subscription.IsTerminated then
    Subscription.Refresh(Self.NewDuration);
end;

//******************************************************************************
//* TIdSipSubscriptionRetryWait                                                *
//******************************************************************************
//* TIdSipSubscriptionRetryWait Public methods *********************************

constructor TIdSipSubscriptionRetryWait.Create;
begin
  inherited Create;

  Self.fTarget := TIdSipAddressHeader.Create;
end;

destructor TIdSipSubscriptionRetryWait.Destroy;
begin
  Self.Target.Free;

  inherited Destroy;
end;

procedure TIdSipSubscriptionRetryWait.Trigger;
var
  Module: TIdSipSubscribeModule;
begin
  Module := Self.UserAgent.ModuleFor(MethodSubscribe) as TIdSipSubscribeModule;

  if Assigned(Module) then
    Module.Resubscribe(Self.Target, Self.EventPackage);
end;

//* TIdSipSubscriptionRetryWait Private methods ********************************

procedure TIdSipSubscriptionRetryWait.SetTarget(Value: TIdSipAddressHeader);
begin
  Self.fTarget.Value := Value.FullValue;
end;

//******************************************************************************
//* TIdSipNotifyFailedMethod                                                   *
//******************************************************************************
//* TIdSipNotifyFailedMethod Public methods ************************************

procedure TIdSipNotifyFailedMethod.Run(const Subject: IInterface);
begin
  (Subject as IIdSipNotifyListener).OnFailure(Self.Notify,
                                              Self.Response);
end;

//******************************************************************************
//* TIdSipNotifySucceededMethod                                                *
//******************************************************************************
//* TIdSipNotifySucceededMethod Public methods *********************************

procedure TIdSipNotifySucceededMethod.Run(const Subject: IInterface);
begin
  (Subject as IIdSipNotifyListener).OnSuccess(Self.Notify,
                                              Self.Response);
end;

//******************************************************************************
//* TIdSipOutboundSubscribeFailedMethod                                        *
//******************************************************************************
//* TIdSipOutboundSubscribeFailedMethod Public methods *************************

procedure TIdSipOutboundSubscribeFailedMethod.Run(const Subject: IInterface);
begin
  (Subject as IIdSipSubscribeListener).OnFailure(Self.Subscribe,
                                                 Self.Response);
end;

//******************************************************************************
//* TIdSipOutboundSubscribeSucceededMethod                                     *
//******************************************************************************
//* TIdSipOutboundSubscribeSucceededMethod Public methods **********************

procedure TIdSipOutboundSubscribeSucceededMethod.Run(const Subject: IInterface);
begin
  (Subject as IIdSipSubscribeListener).OnSuccess(Self.Subscribe,
                                                 Self.Response);
end;

//******************************************************************************
//* TIdSipEstablishedSubscriptionMethod                                        *
//******************************************************************************
//* TIdSipEstablishedSubscriptionMethod Public methods *************************

procedure TIdSipEstablishedSubscriptionMethod.Run(const Subject: IInterface);
begin
  (Subject as IIdSipSubscriptionListener).OnEstablishedSubscription(Self.Subscription,
                                                                    Self.Notify);
end;

//******************************************************************************
//* TIdSipExpiredSubscriptionMethod                                            *
//******************************************************************************
//* TIdSipExpiredSubscriptionMethod Public methods *****************************

procedure TIdSipExpiredSubscriptionMethod.Run(const Subject: IInterface);
begin
  (Subject as IIdSipSubscriptionListener).OnExpiredSubscription(Self.Subscription,
                                                                Self.Notify);
end;

//******************************************************************************
//* TIdSipFailedSubscriptionMethod                                             *
//******************************************************************************
//* TIdSipFailedSubscriptionMethod Public methods ******************************

procedure TIdSipFailedSubscriptionMethod.Run(const Subject: IInterface);
begin
  (Subject as IIdSipSubscriptionListener).OnFailure(Self.Subscription,
                                                    Self.Response);
end;

//******************************************************************************
//* TIdSipSubscriptionNotifyMethod                                             *
//******************************************************************************
//* TIdSipSubscriptionNotifyMethod Public methods ******************************

procedure TIdSipSubscriptionNotifyMethod.Run(const Subject: IInterface);
begin
  (Subject as IIdSipSubscriptionListener).OnNotify(Self.Subscription,
                                                   Self.Notify);
end;

//******************************************************************************
//* TIdSipRenewedSubscriptionMethod                                            *
//******************************************************************************
//* TIdSipRenewedSubscriptionMethod Public methods *****************************

procedure TIdSipRenewedSubscriptionMethod.Run(const Subject: IInterface);
begin
  (Subject as IIdSipSubscribeModuleListener).OnRenewedSubscription(Self.UserAgent,
                                                                   Self.Subscription);
end;

//******************************************************************************
//* TIdSipSubscriptionRequestMethod                                            *
//******************************************************************************
//* TIdSipSubscriptionRequestMethod Public methods *****************************

procedure TIdSipSubscriptionRequestMethod.Run(const Subject: IInterface);
begin
  (Subject as IIdSipSubscribeModuleListener).OnSubscriptionRequest(Self.UserAgent,
                                                                   Self.Subscription);
end;

initialization
  GEventPackageTypes := TStringList.Create;
finalization
// These objects are purely memory-based, so it's safe not to free them here.
// Still, perhaps we need to review this methodology. How else do we get
// something like class variables?
//  GEventPackageTypes.Free;
end.
