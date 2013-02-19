//
//  XMPPAutoPingTest.m
//  XMPPFramework-Tests-Mac
//
//  Created by Daniel Rodríguez Troitiño on 02/02/13.
//  Copyright (c) 2013 XMPPFramework. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <GHUnitIOS/GHUnit.h>
#else
#import <GHUnit/GHUnit.h>
#endif

#import <OCMock/OCMock.h>

#import "XMPPFramework.h"


@interface XMPPAutoPingDelegateMock : NSObject <XMPPAutoPingDelegate>

@property (nonatomic, copy) void (^XMPPAutoPingDidSendPing)(XMPPAutoPing *sender);
@property (nonatomic, copy) void (^XMPPAutoPingDidReceivePong)(XMPPAutoPing *sender);
@property (nonatomic, copy) NSUInteger (^XMPPAutoPingDidTimeout)(XMPPAutoPing *sender);

@end


@interface XMPPAutoPingTest : GHTestCase

@end


@implementation XMPPAutoPingTest
{
    XMPPAutoPing<XMPPStreamDelegate> *module;
    dispatch_queue_t moduleQueue;
}

- (void)setUp
{
    moduleQueue = dispatch_queue_create("xmpp.test.queue", 0);
    module = (XMPPAutoPing<XMPPStreamDelegate> *)[[XMPPAutoPing alloc] initWithDispatchQueue:moduleQueue];
}

- (void)tearDown
{
    module = nil;
#if !OS_OBJECT_USE_OBJC
    dispatch_release(moduleQueue);
#endif
    moduleQueue = NULL;
}

- (void)testPingIntervalDefaultsTo60
{
    GHAssertEqualsWithAccuracy(60.0, module.pingInterval, 0.1, nil);
}

- (void)testPingIntervalSetter
{
    module.pingInterval = 123.45;
    GHAssertEqualsWithAccuracy(123.45, module.pingInterval, 0.1, nil);
}

- (void)testPingTimeoutDefaultsTo10
{
    GHAssertEqualsWithAccuracy(10.0, module.pingTimeout, 0.1, nil);
}

- (void)testPingTimeoutSetter
{
    module.pingTimeout = 123.45;
    GHAssertEqualsWithAccuracy(123.45, module.pingTimeout, 0.1, nil);
}

- (void)testTargetJIDDefaultsToNil
{
    GHAssertNil(module.targetJID, nil);
}

- (void)testTargetJIDSetter
{
    XMPPJID *theJID = [XMPPJID jidWithString:@"romeo@montague.net/orchard"];
    module.targetJID = theJID;
    GHAssertEqualObjects(theJID, module.targetJID, nil);
}

- (void)testRespondsToQueriesDefaultToNO
{
    GHAssertFalse(module.respondsToQueries, nil);
}

- (void)testRespondsToQueriesCanBeSetToYES
{
    module.respondsToQueries = YES;
    GHAssertTrue(module.respondsToQueries, nil);
}

- (void)testActivate
{
    id stream = [OCMockObject mockForClass:[XMPPStream class]];

    [[stream expect] addDelegate:module delegateQueue:moduleQueue];
    [[stream expect] registerModule:module];

    // XMPPAutoPing uses XMPPPing underneath
    XMPPPing *pingModule = [module valueForKey:@"xmppPing"];
    dispatch_queue_t pingQueue = pingModule.moduleQueue;

    [[stream expect] addDelegate:pingModule delegateQueue:pingQueue];
    [[stream expect] registerModule:pingModule];

#ifdef _XMPP_CAPABILITIES_H
    [[stream expect] autoAddDelegate:pingModule delegateQueue:pingQueue toModulesOfClass:[XMPPCapabilities class]];
#endif

    GHAssertTrue([module activate:stream], nil);

    GHAssertEquals(module.xmppStream, stream, nil);

    [stream verify];
}

- (void)testDeactivate
{
    id stream = [OCMockObject mockForClass:[XMPPStream class]];
    [module setValue:stream forKey:@"xmppStream"];

    [[stream expect] removeDelegate:module delegateQueue:moduleQueue];
    [[stream expect] unregisterModule:module];

    [module deactivate];

    GHAssertNil(module.xmppStream, nil);

    [stream verify];
}

- (void)testXMPPStreamDidAuthenticateSetsLastReceiveTime
{
  __block NSTimeInterval now = 0;
  // the stream is not used
  dispatch_sync(moduleQueue, ^{
    now = [NSDate timeIntervalSinceReferenceDate];
    [module xmppStreamDidAuthenticate:nil];
  });

  GHAssertEqualsWithAccuracy(now, module.lastReceiveTime, 1.0, nil);
}

- (void)testXMPPStreamDidReceiveIQWithTargetNil
{
  __block NSTimeInterval now = 0;
  // the stream nor the iq is used
  dispatch_sync(moduleQueue, ^{
    now = [NSDate timeIntervalSinceReferenceDate];
    GHAssertFalse([module xmppStream:nil didReceiveIQ:nil], nil);
  });

  GHAssertEqualsWithAccuracy(now, module.lastReceiveTime, 1.0, nil);
}

- (void)testXMPPStreamDidReceiveIQFromTargetJID
{
  XMPPJID *romeo = [XMPPJID jidWithString:@"romeo@montague.net/orchard"];
  XMPPIQ *iq = [XMPPIQ iq];
  [iq addAttributeWithName:@"from" stringValue:romeo.full];
  module.targetJID = romeo;

  __block NSTimeInterval now = 0;
  // the stream is not used
  dispatch_sync(moduleQueue, ^{
    now = [NSDate timeIntervalSinceReferenceDate];
    GHAssertFalse([module xmppStream:nil didReceiveIQ:iq], nil);
  });

  GHAssertEqualsWithAccuracy(now, module.lastReceiveTime, 1.0, nil);
}

- (void)testXMPPStreamDidReceiveIQNotFromTargetJID
{
  XMPPJID *romeo = [XMPPJID jidWithString:@"romeo@montague.net/orchard"];
  XMPPJID *juliet = [XMPPJID jidWithString:@"juliet@capulet.com/balcony"];
  XMPPIQ *iq = [XMPPIQ iq];
  [iq addAttributeWithName:@"from" stringValue:romeo.full];
  module.targetJID = juliet;

  __block NSTimeInterval now = 0;
  // the stream is not used
  dispatch_sync(moduleQueue, ^{
    now = [NSDate timeIntervalSinceReferenceDate];
    GHAssertFalse([module xmppStream:nil didReceiveIQ:iq], nil);
  });

  GHAssertEqualsWithAccuracy(0.0, module.lastReceiveTime, 0, nil);
}

- (void)testXMPPStreamDidReceiveMessageWithTargetNil
{
  __block NSTimeInterval now = 0;
  // the stream nor the message is used
  dispatch_sync(moduleQueue, ^{
    now = [NSDate timeIntervalSinceReferenceDate];
    [module xmppStream:nil didReceiveMessage:nil];
  });

  GHAssertEqualsWithAccuracy(now, module.lastReceiveTime, 1.0, nil);
}

- (void)testXMPPStreamDidReceiveMessageFromTargetJID
{
  XMPPJID *romeo = [XMPPJID jidWithString:@"romeo@montague.net/orchard"];
  XMPPMessage *msg = [XMPPMessage message];
  [msg addAttributeWithName:@"from" stringValue:romeo.full];
  module.targetJID = romeo;

  __block NSTimeInterval now = 0;
  // the stream is not used
  dispatch_sync(moduleQueue, ^{
    now = [NSDate timeIntervalSinceReferenceDate];
    [module xmppStream:nil didReceiveMessage:msg];
  });

  GHAssertEqualsWithAccuracy(now, module.lastReceiveTime, 1.0, nil);
}

- (void)testXMPPStreamDidReceiveMessageNotFromTargetJID
{
  XMPPJID *romeo = [XMPPJID jidWithString:@"romeo@montague.net/orchard"];
  XMPPJID *juliet = [XMPPJID jidWithString:@"juliet@capulet.com/balcony"];
  XMPPMessage *msg = [XMPPMessage message];
  [msg addAttributeWithName:@"from" stringValue:romeo.full];
  module.targetJID = juliet;

  __block NSTimeInterval now = 0;
  // the stream is not used
  dispatch_sync(moduleQueue, ^{
    now = [NSDate timeIntervalSinceReferenceDate];
    [module xmppStream:nil didReceiveMessage:msg];
  });

  GHAssertEqualsWithAccuracy(0.0, module.lastReceiveTime, 0, nil);
}

- (void)testXMPPStreamDidReceivePresenceWithTargetNil
{
  __block NSTimeInterval now = 0;
  // the stream nor the presence is used
  dispatch_sync(moduleQueue, ^{
    now = [NSDate timeIntervalSinceReferenceDate];
    [module xmppStream:nil didReceivePresence:nil];
  });

  GHAssertEqualsWithAccuracy(now, module.lastReceiveTime, 1.0, nil);
}

- (void)testXMPPStreamDidReceivePresenceFromTargetJID
{
  XMPPJID *romeo = [XMPPJID jidWithString:@"romeo@montague.net/orchard"];
  XMPPPresence *pre = [XMPPPresence presence];
  [pre addAttributeWithName:@"from" stringValue:romeo.full];
  module.targetJID = romeo;

  __block NSTimeInterval now = 0;
  // the stream is not used
  dispatch_sync(moduleQueue, ^{
    now = [NSDate timeIntervalSinceReferenceDate];
    [module xmppStream:nil didReceivePresence:pre];
  });

  GHAssertEqualsWithAccuracy(now, module.lastReceiveTime, 1.0, nil);
}

- (void)testXMPPStreamDidReceivePresenceNotFromTargetJID
{
  XMPPJID *romeo = [XMPPJID jidWithString:@"romeo@montague.net/orchard"];
  XMPPJID *juliet = [XMPPJID jidWithString:@"juliet@capulet.com/balcony"];
  XMPPPresence *pre = [XMPPPresence presence];
  [pre addAttributeWithName:@"from" stringValue:romeo.full];
    module.targetJID = juliet;

  __block NSTimeInterval now = 0;
  // the stream is not used
  dispatch_sync(moduleQueue, ^{
    now = [NSDate timeIntervalSinceReferenceDate];
    [module xmppStream:nil didReceivePresence:pre];
  });

  GHAssertEqualsWithAccuracy(0.0, module.lastReceiveTime, 0, nil);
}

- (void)testTargetJIDIsUsedAsPingTarget
{
    XMPPJID *romeo = [XMPPJID jidWithString:@"romeo@montague.net/orchard"];
    module.targetJID = romeo;
    id stream = [OCMockObject mockForClass:[XMPPStream class]];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [(XMPPStream *)[stream stub] setTag:@"1"];
    [[stream stub] addDelegate:module delegateQueue:moduleQueue];
    [[stream stub] registerModule:module];
    [[stream stub] addDelegate:[OCMArg any] delegateQueue:moduleQueue];
    [[stream stub] registerModule:[OCMArg any]];

#ifdef _XMPP_CAPABILITIES_H
    [[stream stub] autoAddDelegate:[OCMArg any] delegateQueue:moduleQueue toModulesOfClass:[XMPPCapabilities class]];
#endif

    [module activate:stream];

    [[[stream stub] andReturnValue:@YES] isAuthenticated];
    [[[stream stub] andReturn:@"DUMMY-GUID"] generateUUID];
    [[stream expect] sendElement:[OCMArg checkWithBlock:^BOOL(XMPPIQ *iq) {
        GHAssertEqualStrings([romeo full], iq.toStr, nil);
        dispatch_semaphore_signal(semaphore);
        return YES;
    }]];

    module.pingInterval = 1.0;

    if (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC)) != 0)
    {
        GHFail(@"The ping was not sent");
    }

    module.pingInterval = 0;

    [stream verify];
}

- (void)testTargetJIDNilSendsPingToServer
{
    id stream = [OCMockObject mockForClass:[XMPPStream class]];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [(XMPPStream *)[stream stub] setTag:@"2"];
    [[stream stub] addDelegate:module delegateQueue:moduleQueue];
    [[stream stub] registerModule:module];
    [[stream stub] addDelegate:[OCMArg any] delegateQueue:moduleQueue];
    [[stream stub] registerModule:[OCMArg any]];

#ifdef _XMPP_CAPABILITIES_H
    [[stream stub] autoAddDelegate:[OCMArg any] delegateQueue:moduleQueue toModulesOfClass:[XMPPCapabilities class]];
#endif

    [module activate:stream];

    [[[stream stub] andReturnValue:@YES] isAuthenticated];
    [[[stream stub] andReturn:@"DUMMY-GUID"] generateUUID];
    [[stream expect] sendElement:[OCMArg checkWithBlock:^BOOL(XMPPIQ *iq) {
        GHAssertNil(iq.toStr, nil);
        dispatch_semaphore_signal(semaphore);
        return YES;
    }]];

    module.pingInterval = 1.0;

    if (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC)) != 0)
    {
        GHFail(@"The ping was not sent");
    }

    module.pingInterval = 0;

    [stream verify];
}

- (void)testNoMorePingsAreSentAfterSettingPingIntervalToZero
{
    id stream = [OCMockObject mockForClass:[XMPPStream class]];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [(XMPPStream *)[stream stub] setTag:@"3"];
    [[stream stub] addDelegate:module delegateQueue:moduleQueue];
    [[stream stub] registerModule:module];
    [[stream stub] addDelegate:[OCMArg any] delegateQueue:moduleQueue];
    [[stream stub] registerModule:[OCMArg any]];

#ifdef _XMPP_CAPABILITIES_H
    [[stream stub] autoAddDelegate:[OCMArg any] delegateQueue:moduleQueue toModulesOfClass:[XMPPCapabilities class]];
#endif

    [module activate:stream];

    [[[stream stub] andReturnValue:@YES] isAuthenticated];
    [[[stream stub] andReturn:@"DUMMY-GUID"] generateUUID];
    [[stream expect] sendElement:[OCMArg checkWithBlock:^BOOL(XMPPIQ *iq) {
        dispatch_semaphore_signal(semaphore);
        return YES;
    }]];

    module.pingInterval = 1.0;

    if (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC)) != 0)
    {
        GHFail(@"The ping was not sent");
    }

    module.pingInterval = 0;

    // Wait for a second, the stream should not receive anything else.
    if (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC)) == 0) {
        GHFail(@"somebody signaled the semaphore, but that should not happen");
    }

    [stream verify];
}

- (void)testNoMorePingsAreSentAfterDeactivate
{
    id stream = [OCMockObject mockForClass:[XMPPStream class]];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [(XMPPStream *)[stream stub] setTag:@"4"];
    [[stream stub] addDelegate:module delegateQueue:moduleQueue];
    [[stream stub] registerModule:module];
    [[stream stub] addDelegate:[OCMArg any] delegateQueue:moduleQueue];
    [[stream stub] registerModule:[OCMArg any]];

#ifdef _XMPP_CAPABILITIES_H
    [[stream stub] autoAddDelegate:[OCMArg any] delegateQueue:moduleQueue toModulesOfClass:[XMPPCapabilities class]];
#endif

    [module activate:stream];

    [[[stream stub] andReturnValue:@YES] isAuthenticated];
    [[[stream stub] andReturn:@"DUMMY-GUID"] generateUUID];
    [[stream expect] sendElement:[OCMArg checkWithBlock:^BOOL(XMPPIQ *iq) {
        dispatch_semaphore_signal(semaphore);
        return YES;
    }]];

    module.pingInterval = 1.0;

    if (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC)) != 0)
    {
        GHFail(@"The ping was not sent");
    }

    [[stream stub] removeDelegate:module delegateQueue:moduleQueue];
    [[stream stub] unregisterModule:module];
    [[stream stub] removeAutoDelegate:[OCMArg any] delegateQueue:moduleQueue fromModulesOfClass:[XMPPCapabilities class]];
    [[stream stub] removeDelegate:[OCMArg any] delegateQueue:moduleQueue];
    [[stream stub] unregisterModule:[OCMArg any]];

    [module deactivate];

    // Wait for a second, the stream should not receive anything else.
    if (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC)) == 0) {
        GHFail(@"somebody signaled the semaphore, but that should not happen");
    }
    
    [stream verify];
}

- (void)testDelegateInvokedAfterSendingPing
{
    XMPPAutoPingDelegateMock *delegate = [[XMPPAutoPingDelegateMock alloc] init];
    id stream = [OCMockObject mockForClass:[XMPPStream class]];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    dispatch_queue_t testQueue = dispatch_queue_create("test", 0);
    [module addDelegate:delegate delegateQueue:testQueue];

    [(XMPPStream *)[stream stub] setTag:@"5"];
    [[stream stub] addDelegate:module delegateQueue:moduleQueue];
    [[stream stub] registerModule:module];
    [[stream stub] addDelegate:[OCMArg any] delegateQueue:moduleQueue];
    [[stream stub] registerModule:[OCMArg any]];

#ifdef _XMPP_CAPABILITIES_H
    [[stream stub] autoAddDelegate:[OCMArg any] delegateQueue:moduleQueue toModulesOfClass:[XMPPCapabilities class]];
#endif

    [module activate:stream];

    [[[stream stub] andReturnValue:@YES] isAuthenticated];
    [[[stream stub] andReturn:@"DUMMY-GUID"] generateUUID];
    [[stream expect] sendElement:[OCMArg any]];

    delegate.XMPPAutoPingDidSendPing = ^(XMPPAutoPing *sender) {
        GHAssertEquals(module, sender, nil);
        dispatch_semaphore_signal(semaphore);
    };

    module.pingInterval = 1.0; // forces the ping after 0.25s

    if (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC)) != 0)
    {
        GHFail(@"The ping was not sent");
    }

    module.pingInterval = 0;

    [stream verify];
}

// TODO: test stopPingIntervalTimer after dealloc ???
// TODO: test xmppPing removeDelegate after dealloc ???
// TODO: test pingTimeout not sending pong
// TODO: test delegate invoked after receiving pong
// TODO: test delegate invoked after not receving pong
// TODO: test startPingIntervalTimer after authenticating
// TODO: test stopPingIntervalTimer after disconnect.

@end

@implementation XMPPAutoPingDelegateMock

- (void)xmppAutoPingDidSendPing:(XMPPAutoPing *)sender
{
    if (self.XMPPAutoPingDidSendPing)
    {
        self.XMPPAutoPingDidSendPing(sender);
    }
}

- (void)xmppAutoPingDidReceivePong:(XMPPAutoPing *)sender
{
    if (self.XMPPAutoPingDidReceivePong)
    {
        self.XMPPAutoPingDidReceivePong(sender);
    }
}

- (void)xmppAutoPingDidTimeout:(XMPPAutoPing *)sender
{
    if (self.XMPPAutoPingDidTimeout)
    {
        self.XMPPAutoPingDidTimeout(sender);
    }
}

@end
