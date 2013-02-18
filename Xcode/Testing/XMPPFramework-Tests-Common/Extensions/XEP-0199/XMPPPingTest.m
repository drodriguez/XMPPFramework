//
//  XMPPPingTest.m
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

@interface XMPPPingDelegateMock : NSObject <XMPPPingDelegate>

@property (nonatomic, copy) void (^XMPPPingDidReceivePongWithRTTHandler)(XMPPPing *sender, XMPPIQ *pong, NSTimeInterval rtt);
@property (nonatomic, copy) void (^XMPPPingDidNotReceivePongDueToTimeoutHandler)(XMPPPing *sender, NSString *pingID, NSTimeInterval timeout);

@end


@interface XMPPPingTest : GHTestCase

@end


@implementation XMPPPingTest

- (void)testRespondsToQueriesDefaultToYES
{
    XMPPPing *module = [[XMPPPing alloc] init];

    GHAssertTrue(module.respondsToQueries, nil);
}

- (void)testRespondsToQueriesCanBeSetToNO
{
    id stream = [OCMockObject mockForClass:[XMPPStream class]];
    XMPPPing *module = [[XMPPPing alloc] init];
    [module setValue:stream forKey:@"xmppStream"];

#ifdef _XMPP_CAPABILITIES_H
    [[stream expect] resendMyPresence];
#endif

    module.respondsToQueries = NO;

    GHAssertFalse(module.respondsToQueries, nil);

    [stream verify];
}

- (void)testActivate
{
    id stream = [OCMockObject mockForClass:[XMPPStream class]];
    XMPPPing *module = [[XMPPPing alloc] init];
    dispatch_queue_t moduleQueue = module.moduleQueue;

    [[stream expect] addDelegate:module delegateQueue:moduleQueue];
    [[stream expect] registerModule:module];

#ifdef _XMPP_CAPABILITIES_H
    [[stream expect] autoAddDelegate:module delegateQueue:moduleQueue toModulesOfClass:[XMPPCapabilities class]];
#endif

    GHAssertTrue([module activate:stream], nil);
    GHAssertEquals(module.xmppStream, stream, nil);

    [stream verify];
}

- (void)testDeactivate
{
    id stream = [OCMockObject mockForClass:[XMPPStream class]];
    XMPPPing *module = [[XMPPPing alloc] init];
    dispatch_queue_t moduleQueue = module.moduleQueue;
    [module setValue:stream forKey:@"xmppStream"];

#ifdef _XMPP_CAPABILITIES_H
    [[stream expect] removeAutoDelegate:module delegateQueue:moduleQueue fromModulesOfClass:[XMPPCapabilities class]];
#endif

    [[stream expect] removeDelegate:module delegateQueue:moduleQueue];
    [[stream expect] unregisterModule:module];

    [module deactivate];

    GHAssertNil(module.xmppStream, nil);

    [stream verify];
}

- (void)testSendPingToServerWithTimeoutReceivingPong
{
    XMPPJID *romeo = [XMPPJID jidWithString:@"romeo@montague.net/orchard"];
    XMPPPingDelegateMock *delegate = [[XMPPPingDelegateMock alloc] init];
    XMPPPing<XMPPStreamDelegate> *module = (XMPPPing<XMPPStreamDelegate> *) [[XMPPPing alloc] init];
    dispatch_queue_t moduleQueue = module.moduleQueue;
    id stream = [OCMockObject mockForClass:[XMPPStream class]];
    __block XMPPIQ *pong = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    dispatch_queue_t queue = dispatch_queue_create("test", 0);
    [module addDelegate:delegate delegateQueue:queue];

    // We need to activate the module to create the id tracker, so we need a
    // mock stream.
    [[stream stub] addDelegate:module delegateQueue:moduleQueue];
    [[stream stub] registerModule:module];

#ifdef _XMPP_CAPABILITIES_H
    [[stream stub] autoAddDelegate:module delegateQueue:moduleQueue toModulesOfClass:[XMPPCapabilities class]];
#endif

    [module activate:stream];

    // sendPingToServerWithTimeout: uses the stream to send the ping, we
    // capture the ping, so we can generate the proper pong.
    [[[stream stub] andReturn:@"DUMMY-GUID"] generateUUID];

    [[stream expect] sendElement:[OCMArg checkWithBlock:^BOOL(XMPPIQ *ping) {
        BOOL valid = ([@"get" isEqualToString:ping.type] &&
                      ping.to == nil &&
                      [@"DUMMY-GUID" isEqualToString:ping.elementID] &&
                      [@"ping" isEqualToString:ping.childElement.name] &&
                      [@"urn:xmpp:ping" isEqualToString:ping.childElement.URI]);
        pong = [XMPPIQ iqWithType:@"result" to:romeo elementID:ping.elementID];
        return valid;
    }]];

    (void)[module sendPingToServerWithTimeout:30];

    // Check the delegate receive the right parameters, signal the semaphore, so
    // the wait below doesn't timeout (and the test fail).
    delegate.XMPPPingDidReceivePongWithRTTHandler = ^(XMPPPing *sender, XMPPIQ *response, NSTimeInterval rtt) {
        GHAssertEquals(sender, module, nil);
        GHAssertEquals(response, pong, nil);
        dispatch_semaphore_signal(semaphore);
    };

    dispatch_sync(moduleQueue, ^{
        (void)[module xmppStream:stream didReceiveIQ:pong];
    });

    if (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC)) != 0)
    {
        GHFail(@"The delegate was not invoked");
    }

    [stream verify];
}

- (void)testSendPingToServerWithTimeoutNotReceivingPong
{
    XMPPPingDelegateMock *delegate = [[XMPPPingDelegateMock alloc] init];
    XMPPPing<XMPPStreamDelegate> *module = (XMPPPing<XMPPStreamDelegate> *) [[XMPPPing alloc] init];
    dispatch_queue_t moduleQueue = module.moduleQueue;
    id stream = [OCMockObject mockForClass:[XMPPStream class]];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    dispatch_queue_t queue = dispatch_queue_create("test", 0);
    [module addDelegate:delegate delegateQueue:queue];

    // We need to activate the module to create the id tracker, so we need a
    // mock stream.
    [[stream stub] addDelegate:module delegateQueue:moduleQueue];
    [[stream stub] registerModule:module];

#ifdef _XMPP_CAPABILITIES_H
    [[stream stub] autoAddDelegate:module delegateQueue:moduleQueue toModulesOfClass:[XMPPCapabilities class]];
#endif

    [module activate:stream];

    // sendPingToServerWithTimeout uses the stream to send the ping
    [[[stream stub] andReturn:@"DUMMY-GUID"] generateUUID];
    [[stream stub] sendElement:[OCMArg any]];

    NSTimeInterval expectedTimeout = 1.0;
    NSString *expectedPingID = [module sendPingToServerWithTimeout:expectedTimeout];
    GHAssertEqualStrings(expectedPingID, @"DUMMY-GUID", nil);

    // Check the delegate receive the right parameters, signal the semaphore, so
    // the wait below doesn't timeout (and the test fail).
    delegate.XMPPPingDidNotReceivePongDueToTimeoutHandler = ^(XMPPPing *sender, NSString *pingID, NSTimeInterval timeout) {
        GHAssertEquals(sender, module, nil);
        GHAssertEqualStrings(pingID, expectedPingID, nil);
        GHAssertEqualsWithAccuracy(timeout, expectedTimeout, 0.1, nil);
        dispatch_semaphore_signal(semaphore);
    };

    if (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC)) != 0)
    {
        GHFail(@"The delegate was not invoked");
    }
    
    [stream verify];
}

- (void)testSendPingToJIDWithTimeoutReceivingPong
{
    XMPPJID *romeo = [XMPPJID jidWithString:@"romeo@montague.net/orchard"];
    XMPPJID *juliet = [XMPPJID jidWithString:@"juliet@capulet.com/balcony"];
    XMPPPingDelegateMock *delegate = [[XMPPPingDelegateMock alloc] init];
    XMPPPing<XMPPStreamDelegate> *module = (XMPPPing<XMPPStreamDelegate> *) [[XMPPPing alloc] init];
    dispatch_queue_t moduleQueue = module.moduleQueue;
    id stream = [OCMockObject mockForClass:[XMPPStream class]];
    __block XMPPIQ *pong = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    dispatch_queue_t queue = dispatch_queue_create("test", 0);
    [module addDelegate:delegate delegateQueue:queue];

    // We need to activate the module to create the id tracker, so we need a
    // mock stream.
    [[stream stub] addDelegate:module delegateQueue:moduleQueue];
    [[stream stub] registerModule:module];

#ifdef _XMPP_CAPABILITIES_H
    [[stream stub] autoAddDelegate:module delegateQueue:moduleQueue toModulesOfClass:[XMPPCapabilities class]];
#endif

    [module activate:stream];

    // sendPingToJID:withTimeout uses the stream to send the ping, we
    // capture the ping, so we can generate the proper pong.
    [[[stream stub] andReturn:@"DUMMY-GUID"] generateUUID];
    [[stream expect] sendElement:[OCMArg checkWithBlock:^BOOL(XMPPIQ *ping) {
        BOOL valid = ([@"get" isEqualToString:ping.type] &&
                      [romeo isEqual:ping.to] &&
                      [@"DUMMY-GUID" isEqualToString:ping.elementID] &&
                      [@"ping" isEqualToString:ping.childElement.name] &&
                      [@"urn:xmpp:ping" isEqualToString:ping.childElement.URI]);
        pong = [XMPPIQ iqWithType:@"result" to:juliet elementID:ping.elementID];
        return valid;
    }]];

    (void)[module sendPingToJID:romeo withTimeout:30];

    // Check the delegate receive the right parameters, signal the semaphore, so
    // the wait below doesn't timeout (and the test fail).
    delegate.XMPPPingDidReceivePongWithRTTHandler = ^(XMPPPing *sender, XMPPIQ *response, NSTimeInterval rtt) {
        GHAssertEquals(sender, module, nil);
        GHAssertEquals(response, pong, nil);
        dispatch_semaphore_signal(semaphore);
    };

    dispatch_sync(moduleQueue, ^{
        (void)[module xmppStream:stream didReceiveIQ:pong];
    });

    if (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC)) != 0)
    {
        GHFail(@"The delegate was not invoked");
    }
    
    [stream verify];
}

- (void)testSendPingToJIDWithTimeoutNotReceivingPong
{
    XMPPJID *romeo = [XMPPJID jidWithString:@"romeo@montague.net/orchard"];
    XMPPPingDelegateMock *delegate = [[XMPPPingDelegateMock alloc] init];
    XMPPPing<XMPPStreamDelegate> *module = (XMPPPing<XMPPStreamDelegate> *) [[XMPPPing alloc] init];
    dispatch_queue_t moduleQueue = module.moduleQueue;
    id stream = [OCMockObject mockForClass:[XMPPStream class]];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    dispatch_queue_t queue = dispatch_queue_create("test", 0);
    [module addDelegate:delegate delegateQueue:queue];

    // We need to activate the module to create the id tracker, so we need a
    // mock stream.
    [[stream stub] addDelegate:module delegateQueue:moduleQueue];
    [[stream stub] registerModule:module];

#ifdef _XMPP_CAPABILITIES_H
    [[stream stub] autoAddDelegate:module delegateQueue:moduleQueue toModulesOfClass:[XMPPCapabilities class]];
#endif

    [module activate:stream];

    // sendPingToJID:withTimeout: uses the stream to send the ping
    [[[stream stub] andReturn:@"DUMMY-GUID"] generateUUID];
    [[stream stub] sendElement:[OCMArg any]];

    NSTimeInterval expectedTimeout = 1.0;
    NSString *expectedPingID = [module sendPingToJID:romeo withTimeout:expectedTimeout];
    GHAssertEqualStrings(expectedPingID, @"DUMMY-GUID", nil);

    // Check the delegate receive the right parameters, signal the semaphore, so
    // the wait below doesn't timeout (and the test fail).
    delegate.XMPPPingDidNotReceivePongDueToTimeoutHandler = ^(XMPPPing *sender, NSString *pingID, NSTimeInterval timeout) {
        GHAssertEquals(sender, module, nil);
        GHAssertEqualStrings(pingID, expectedPingID, nil);
        GHAssertEqualsWithAccuracy(timeout, expectedTimeout, 0.1, nil);
        dispatch_semaphore_signal(semaphore);
    };

    if (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC)) != 0)
    {
        GHFail(@"The delegate was not invoked");
    }
    
    [stream verify];
}

- (void)testXMPPStreamDidReceiveIQWithPongButNoRespondsToQueriesReturnsNo
{
    XMPPJID *romeo = [XMPPJID jidWithString:@"romeo@montague.net/orchard"];
    XMPPPing<XMPPStreamDelegate> *module = (XMPPPing<XMPPStreamDelegate> *) [[XMPPPing alloc] init];
    module.respondsToQueries = NO;

    NSXMLElement *pingChild = [NSXMLElement elementWithName:@"ping" xmlns:@"urn:xmpp:ping"];
    XMPPIQ *ping = [XMPPIQ iqWithType:@"get" to:romeo elementID:@"DUMMY-GUID" child:pingChild];

    // the stream is not used
    dispatch_sync(module.moduleQueue, ^{
        GHAssertFalse([module xmppStream:nil didReceiveIQ:ping], nil);
    });
}

- (void)testXMPPStreamDidReceiveIQWithTypeSetReturnsNo
{
    XMPPJID *romeo = [XMPPJID jidWithString:@"romeo@montague.net/orchard"];
    XMPPPing<XMPPStreamDelegate> *module = (XMPPPing<XMPPStreamDelegate> *) [[XMPPPing alloc] init];

    // Create the ping IQ, but switch its type to set
    NSXMLElement *pingChild = [NSXMLElement elementWithName:@"ping" xmlns:@"urn:xmpp:ping"];
    XMPPIQ *ping = [XMPPIQ iqWithType:@"set" to:romeo elementID:@"DUMMY-GUID" child:pingChild];

    // the stream is not used
    dispatch_sync(module.moduleQueue, ^{
        GHAssertFalse([module xmppStream:nil didReceiveIQ:ping], nil);
    });
}

- (void)testXMPPStreamDidReceiveIQWithOtherChildElementReturnsNo
{
    XMPPJID *romeo = [XMPPJID jidWithString:@"romeo@montague.net/orchard"];
    XMPPPing<XMPPStreamDelegate> *module = (XMPPPing<XMPPStreamDelegate> *) [[XMPPPing alloc] init];
    XMPPIQ *nonPing = [XMPPIQ iqWithType:@"get" to:romeo];

    // the stream is not used
    dispatch_sync(module.moduleQueue, ^{
        GHAssertFalse([module xmppStream:nil didReceiveIQ:nonPing], nil);
    });
}

- (void)testXMPPStreamDidReceiveIQWithPingReturnsYes
{
    XMPPJID *romeo = [XMPPJID jidWithString:@"romeo@montague.net/orchard"];
    XMPPJID *juliet = [XMPPJID jidWithString:@"juliet@capulet.com/balcony"];
    XMPPPing<XMPPStreamDelegate> *module = (XMPPPing<XMPPStreamDelegate> *) [[XMPPPing alloc] init];
    id stream = [OCMockObject mockForClass:[XMPPStream class]];

    NSXMLElement *pingChild = [NSXMLElement elementWithName:@"ping" xmlns:@"urn:xmpp:ping"];
    XMPPIQ *ping = [XMPPIQ iqWithType:@"get" to:romeo elementID:@"DUMMY-GUID" child:pingChild];
    [ping addAttributeWithName:@"from" stringValue:[juliet full]];

    [[stream expect] sendElement:[OCMArg checkWithBlock:^BOOL(XMPPIQ *pong) {
        return ([pong.type isEqualToString:@"result"] &&
                [pong.to isEqualToJID:juliet] &&
                [pong.elementID isEqualToString:@"DUMMY-GUID"]);
    }]];

    dispatch_sync(module.moduleQueue, ^{
        GHAssertTrue([module xmppStream:stream didReceiveIQ:ping], nil);
    });

    [stream verify];
}

- (void)testDeactivateShouldNotCallPendingPingsTimeouts
{
    XMPPPingDelegateMock *delegate = [[XMPPPingDelegateMock alloc] init];
    XMPPPing *module = [[XMPPPing alloc] init];
    dispatch_queue_t moduleQueue = module.moduleQueue;
    id stream = [OCMockObject mockForClass:[XMPPStream class]];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    dispatch_queue_t queue = dispatch_queue_create("test", 0);
    [module addDelegate:delegate delegateQueue:queue];

    // We need to activate the module to create the id tracker, so we need a
    // mock stream.
    [[stream stub] addDelegate:module delegateQueue:moduleQueue];
    [[stream stub] registerModule:module];

#ifdef _XMPP_CAPABILITIES_H
    [[stream stub] autoAddDelegate:module delegateQueue:moduleQueue toModulesOfClass:[XMPPCapabilities class]];
#endif

    [module activate:stream];

    // We now send a ping, that will not be answered because we
    // deactivate the module just after sending, but should not generate the
    // timeout either.
    delegate.XMPPPingDidReceivePongWithRTTHandler = ^(XMPPPing *sender, XMPPIQ *pong, NSTimeInterval rtt) {
        dispatch_semaphore_signal(semaphore);
        GHFail(@"The pong should not be invoked");
    };

    delegate.XMPPPingDidNotReceivePongDueToTimeoutHandler = ^(XMPPPing *sender, NSString *pingID, NSTimeInterval timeout) {
        dispatch_semaphore_signal(semaphore);
        GHFail(@"The timeout should not be invoked");
    };

    [[[stream stub] andReturn:@"DUMMY-GUID"] generateUUID];
    [[stream stub] sendElement:[OCMArg any]];

    [module sendPingToServerWithTimeout:1.0];

    // Now we need to deactivate the module. Set up the expectations.
#ifdef _XMPP_CAPABILITIES_H
    [[stream stub] removeAutoDelegate:module delegateQueue:moduleQueue fromModulesOfClass:[XMPPCapabilities class]];
#endif

    [[stream stub] removeDelegate:module delegateQueue:moduleQueue];
    [[stream stub] unregisterModule:module];

    [module deactivate];

    // Wait for 1.1 seconds, if timeout occurs, the test is good.
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 1100 * NSEC_PER_MSEC));
    [stream verify];
}

- (void)testXMPPDidDisconnectWithErrorShouldNotCallPendingPingsTimeouts
{
    XMPPPingDelegateMock *delegate = [[XMPPPingDelegateMock alloc] init];
    XMPPPing<XMPPStreamDelegate> *module = (XMPPPing<XMPPStreamDelegate> *)[[XMPPPing alloc] init];
    dispatch_queue_t moduleQueue = module.moduleQueue;
    id stream = [OCMockObject mockForClass:[XMPPStream class]];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    dispatch_queue_t queue = dispatch_queue_create("test", 0);
    [module addDelegate:delegate delegateQueue:queue];

    // We need to activate the module to create the id tracker, so we need a
    // mock stream.
    [[stream stub] addDelegate:module delegateQueue:moduleQueue];
    [[stream stub] registerModule:module];

#ifdef _XMPP_CAPABILITIES_H
    [[stream stub] autoAddDelegate:module delegateQueue:moduleQueue toModulesOfClass:[XMPPCapabilities class]];
#endif

    [module activate:stream];

    // We now send a ping, that will not be answered because we
    // deactivate the module just after sending, but should not generate the
    // timeout either.
    delegate.XMPPPingDidReceivePongWithRTTHandler = ^(XMPPPing *sender, XMPPIQ *pong, NSTimeInterval rtt) {
        dispatch_semaphore_signal(semaphore);
        GHFail(@"The pong should not be invoked");
    };

    delegate.XMPPPingDidNotReceivePongDueToTimeoutHandler = ^(XMPPPing *sender, NSString *pingID, NSTimeInterval timeout) {
        dispatch_semaphore_signal(semaphore);
        GHFail(@"The timeout should not be invoked");
    };

    [[[stream stub] andReturn:@"DUMMY-GUID"] generateUUID];
    [[stream stub] sendElement:[OCMArg any]];

    [module sendPingToServerWithTimeout:1.0];

    dispatch_sync(moduleQueue, ^{
        [module xmppStreamDidDisconnect:stream withError:nil];
    });

    // Wait for 1.1 seconds, if timeout occurs, the test is good.
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 1100 * NSEC_PER_MSEC));
    [stream verify];
}

#ifdef _XMPP_CAPABILITIES_H
- (void)testXMPPCapabilitiesColletingMyCapabilitiesShouldAddPingFeature
{
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" URI:@"http://jabber.org/protocol/disco#info"];
    XMPPPing<XMPPCapabilitiesDelegate> *module = (XMPPPing<XMPPCapabilitiesDelegate> *) [[XMPPPing alloc] init];

    dispatch_sync(module.moduleQueue, ^{
        [module xmppCapabilities:nil collectingMyCapabilities:query];
    });

    __block BOOL found = NO;
    [[query elementsForName:@"feature"] enumerateObjectsUsingBlock:^(NSXMLElement *feature, NSUInteger idx, BOOL *stop) {
        found = [[feature attributeStringValueForName:@"var"] isEqualToString:@"urn:xmpp:ping"];
        *stop = found;
    }];

    if (!found) GHFail(@"feature subelement with urn:xmpp:ping var not found");
}

- (void)testXMPPCapabilitiesColletingMyCapabilitiesShouldNotModifyCapabilitiesWhenNoRespondsToQueries
{
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" URI:@"http://jabber.org/protocol/disco#info"];
    XMPPPing<XMPPCapabilitiesDelegate> *module = (XMPPPing<XMPPCapabilitiesDelegate> *) [[XMPPPing alloc] init];
    module.respondsToQueries = NO;

    dispatch_sync(module.moduleQueue, ^{
        [module xmppCapabilities:nil collectingMyCapabilities:query];
    });

    __block BOOL found = NO;
    [[query elementsForName:@"feature"] enumerateObjectsUsingBlock:^(NSXMLElement *feature, NSUInteger idx, BOOL *stop) {
        found = [[feature attributeStringValueForName:@"var"] isEqualToString:@"urn:xmpp:ping"];
        *stop = found;
    }];

    if (found) GHFail(@"feature subelement with urn:xmpp:ping var found");
}

#endif
@end

@implementation XMPPPingDelegateMock

- (void)xmppPing:(XMPPPing *)sender didReceivePong:(XMPPIQ *)pong withRTT:(NSTimeInterval)rtt
{
    if (self.XMPPPingDidReceivePongWithRTTHandler)
    {
        self.XMPPPingDidReceivePongWithRTTHandler(sender, pong, rtt);
    }
}

- (void)xmppPing:(XMPPPing *)sender didNotReceivePong:(NSString *)pingID dueToTimeout:(NSTimeInterval)timeout
{
    if (self.XMPPPingDidNotReceivePongDueToTimeoutHandler)
    {
        self.XMPPPingDidNotReceivePongDueToTimeoutHandler(sender, pingID, timeout);
    }
}

@end
