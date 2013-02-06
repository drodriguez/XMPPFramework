//
//  XMPPDateTimeProfilesTest.m
//  XMPPFramework-Tests-Mac
//
//  Created by Daniel Rodríguez Troitiño on 06/02/13.
//  Copyright (c) 2013 XMPPFramework. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <GHUnitIOS/GHUnit.h>
#else
#import <GHUnit/GHUnit.h>
#endif

#import <OCMock/OCMock.h>

#import "XMPPFramework.h"

@interface XMPPDateTimeProfilesTest : GHTestCase

@end

@implementation XMPPDateTimeProfilesTest
{
    NSDateFormatter *_dateFormatter;
    NSTimeZone *_originalTimeZone;
}

- (void)setUpClass
{
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS z"];
    [_dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
}

- (void)setUp
{
    // Since dates do not have a explicit time zone, they are parsed in the
    // current timezone. To make this test repeatable we must fix the time zone.
    _originalTimeZone = [NSTimeZone defaultTimeZone];
    [NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
}

- (void)tearDown
{
    [NSTimeZone setDefaultTimeZone:_originalTimeZone];
}

+ (void)testDateWithXmppDateStringShouldSucceed
{
    #define XMPPAssertParseDateEqualStrings(date, expected, description, ...) \
        GHAssertEqualStrings([_dateFormatter stringFromDate:[NSDate dateWithXmppDateString:(date)]], expected, description, ##__VA_ARGS__);

    XMPPAssertParseDateEqualStrings(@"1776-07-04", @"1776-07-04 00:00:00.000 GMT-00:14:44", nil);
    XMPPAssertParseDateEqualStrings(@"1969-01-21", @"1969-01-21 00:00:00.000 GMT+01:00", nil);
    XMPPAssertParseDateEqualStrings(@"1969-07-21", @"1969-07-21 00:00:00.000 GMT+01:00", nil);
	XMPPAssertParseDateEqualStrings(@"2010-04-04", @"2010-04-04 00:00:00.000 GMT+02:00", nil);
	XMPPAssertParseDateEqualStrings(@"2010-12-25", @"2010-12-25 00:00:00.000 GMT+01:00", nil);
}

+ (void)testDateWithXmppDateStringShouldFail
{
}

+ (void)testDateWithXmppTimeString
{
}

+ (void)testDateWithXmppTimeString
{
}

+ (void)testXmppDateString
{
}

+ (void)testXmppTimeString
{
}

+ (void)testXmppDateTimeString
{
}

@end

/*
+ (void)testParseTime
{
	// Should Succeed
	//
	// Notice the proper time zones in the output.
	// All have been converted to the local time zone as needed.

	NSString *t1s = @"16:00:00";
	NSString *t2s = @"16:00:00Z";
	NSString *t3s = @"16:00:00-06:00";
	NSString *t4s = @"16:00:00.123";
	NSString *t5s = @"16:00:00.123Z";
	NSString *t6s = @"16:00:00.123-06:00";

	NSLog(@"S parseTime(%@) = %@", t1s, [df stringFromDate:[XMPPDateTimeProfiles parseTime:t1s]]);
	NSLog(@"S parseTime(%@) = %@", t2s, [df stringFromDate:[XMPPDateTimeProfiles parseTime:t2s]]);
	NSLog(@"S parseTime(%@) = %@", t3s, [df stringFromDate:[XMPPDateTimeProfiles parseTime:t3s]]);
	NSLog(@"S parseTime(%@) = %@", t4s, [df stringFromDate:[XMPPDateTimeProfiles parseTime:t4s]]);
	NSLog(@"S parseTime(%@) = %@", t5s, [df stringFromDate:[XMPPDateTimeProfiles parseTime:t5s]]);
	NSLog(@"S parseTime(%@) = %@", t6s, [df stringFromDate:[XMPPDateTimeProfiles parseTime:t6s]]);

	NSLog(@" ");

	// Should Fail

	NSString *t1f = nil;
	NSString *t2f = @"16-00-00";
	NSString *t3f = @"16:00:00-0600";
	NSString *t4f = @"16:00:00.1";
	NSString *t5f = @"16:00.123";
	NSString *t6f = @"cheese";

	NSLog(@"F parseTime(%@) = %@", t1f, [df stringFromDate:[XMPPDateTimeProfiles parseTime:t1f]]);
	NSLog(@"F parseTime(%@) = %@", t2f, [df stringFromDate:[XMPPDateTimeProfiles parseTime:t2f]]);
	NSLog(@"F parseTime(%@) = %@", t3f, [df stringFromDate:[XMPPDateTimeProfiles parseTime:t3f]]);
	NSLog(@"F parseTime(%@) = %@", t4f, [df stringFromDate:[XMPPDateTimeProfiles parseTime:t4f]]);
	NSLog(@"F parseTime(%@) = %@", t5f, [df stringFromDate:[XMPPDateTimeProfiles parseTime:t5f]]);
	NSLog(@"F parseTime(%@) = %@", t6f, [df stringFromDate:[XMPPDateTimeProfiles parseTime:t6f]]);
}

+ (void)testParseDateTime
{
	// Should Succeed
	//
	// Notice the proper time zones in the output.

	NSString *dt01s = @"1776-07-04T02:56:15Z";
	NSString *dt02s = @"1776-07-04T21:56:15-05:00";
	NSString *dt03s = @"1776-07-04T02:56:15.123Z";
	NSString *dt04s = @"1776-07-04T21:56:15.123-05:00";

	NSLog(@"S parseDateTime(%@) = %@", dt01s, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt01s]]);
	NSLog(@"S parseDateTime(%@) = %@", dt02s, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt02s]]);
	NSLog(@"S parseDateTime(%@) = %@", dt03s, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt03s]]);
	NSLog(@"S parseDateTime(%@) = %@", dt04s, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt04s]]);

	NSLog(@" ");

	NSString *dt05s = @"1969-01-21T02:56:15Z";
	NSString *dt06s = @"1969-01-20T21:56:15-05:00";
	NSString *dt07s = @"1969-01-21T02:56:15.123Z";
	NSString *dt08s = @"1969-01-21T21:56:15.123-05:00";

	NSLog(@"S parseDateTime(%@) = %@", dt05s, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt05s]]);
	NSLog(@"S parseDateTime(%@) = %@", dt06s, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt06s]]);
	NSLog(@"S parseDateTime(%@) = %@", dt07s, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt07s]]);
	NSLog(@"S parseDateTime(%@) = %@", dt08s, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt08s]]);

	NSLog(@" ");

	NSString *dt09s = @"1969-07-21T02:56:15Z";
	NSString *dt10s = @"1969-07-20T21:56:15-05:00";
	NSString *dt11s = @"1969-07-21T02:56:15.123Z";
	NSString *dt12s = @"1969-07-21T21:56:15.123-05:00";

	NSLog(@"S parseDateTime(%@) = %@", dt09s, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt09s]]);
	NSLog(@"S parseDateTime(%@) = %@", dt10s, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt10s]]);
	NSLog(@"S parseDateTime(%@) = %@", dt11s, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt11s]]);
	NSLog(@"S parseDateTime(%@) = %@", dt12s, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt12s]]);

	NSLog(@" ");

	NSString *dt13s = @"2010-04-04T02:56:15Z";
	NSString *dt14s = @"2010-04-04T21:56:15-05:00";
	NSString *dt15s = @"2010-04-04T02:56:15.123Z";
	NSString *dt16s = @"2010-04-04T21:56:15.123-05:00";

	NSLog(@"S parseDateTime(%@) = %@", dt13s, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt13s]]);
	NSLog(@"S parseDateTime(%@) = %@", dt14s, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt14s]]);
	NSLog(@"S parseDateTime(%@) = %@", dt15s, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt15s]]);
	NSLog(@"S parseDateTime(%@) = %@", dt16s, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt16s]]);

	NSLog(@" ");

	NSString *dt17s = @"2010-12-25T02:56:15Z";
	NSString *dt18s = @"2010-12-25T21:56:15-05:00";
	NSString *dt19s = @"2010-12-25T02:56:15.123Z";
	NSString *dt20s = @"2010-12-25T21:56:15.123-05:00";

	NSLog(@"S parseDateTime(%@) = %@", dt17s, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt17s]]);
	NSLog(@"S parseDateTime(%@) = %@", dt18s, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt18s]]);
	NSLog(@"S parseDateTime(%@) = %@", dt19s, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt19s]]);
	NSLog(@"S parseDateTime(%@) = %@", dt20s, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt20s]]);

	NSLog(@" ");

	// Should Fail

	NSString *dt1f = nil;
	NSString *dt2f = @"1969-07-20 21:56:15Z";
	NSString *dt3f = @"1969-7-4T02:56:15.123Z";
	NSString *dt4f = @"cheese";

	NSLog(@"F parseDateTime(%@) = %@", dt1f, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt1f]]);
	NSLog(@"F parseDateTime(%@) = %@", dt2f, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt2f]]);
	NSLog(@"F parseDateTime(%@) = %@", dt3f, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt3f]]);
	NSLog(@"F parseDateTime(%@) = %@", dt4f, [df stringFromDate:[XMPPDateTimeProfiles parseDateTime:dt4f]]);
}

+ (void)testCategory
{
	NSDate *now = [NSDate date];

	NSLog(@"now(%@).xmppDateString = %@", now, [now xmppDateString]);
	NSLog(@"now(%@).xmppTimeString = %@", now, [now xmppTimeString]);
	NSLog(@"now(%@).xmppDateTimeString = %@", now, [now xmppDateTimeString]);
}

*/