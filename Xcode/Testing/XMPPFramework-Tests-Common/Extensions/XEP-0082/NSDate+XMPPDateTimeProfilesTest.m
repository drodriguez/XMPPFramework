//
//  NSDate+XMPPDateTimeProfilesTest
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

@interface NSDateXMPPDateTimeProfilesTest : GHTestCase

@end

@implementation NSDateXMPPDateTimeProfilesTest
{
    NSDateFormatter *_dateFormatter;
    NSTimeZone *_originalTimeZone;
}

- (void)setUp
{
    // Since dates do not have a explicit time zone, they are parsed in the
    // current timezone. To make this test repeatable we must fix the time zone.
    _originalTimeZone = [NSTimeZone defaultTimeZone];
    [NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneWithName:@"US/Pacific"]];

    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS z"];
}

- (void)tearDown
{
    [NSTimeZone setDefaultTimeZone:_originalTimeZone];
}

// Since the constructors just call the underlaying XMPPDateTimeProfiles methods
// we just do a simple smoke test.

- (void)testDateConstructors
{
    GHAssertEqualStrings([_dateFormatter stringFromDate:[NSDate dateWithXmppDateString:@"1776-07-04"]], @"1776-07-04 00:00:00.000 GMT-07:52:58", nil);
    GHAssertNil([NSDate dateWithXmppDateString:@"1776-7-4"], nil);

    // The date part will be the current day
    NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
    [dayFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dayFormatter setDateFormat:@"yyyy-MM-dd"];

    // The tz part will be the one of the current day (DST/Standard)
    NSDateFormatter *tzFormatter = [[NSDateFormatter alloc] init];
    [tzFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [tzFormatter setDateFormat:@"z"];

    NSString *expected = [NSString stringWithFormat:@"%@ %@ %@",
                          [dayFormatter stringFromDate:[NSDate date]],
                          @"14:00:00.123",
                          [tzFormatter stringFromDate:[NSDate date]]];
    GHAssertEqualStrings([_dateFormatter stringFromDate:[NSDate dateWithXmppTimeString:@"16:00:00.123-06:00"]], expected, nil);
    GHAssertNil([NSDate dateWithXmppTimeString:@"16:00:00-0600"], nil);

    GHAssertEqualStrings([_dateFormatter stringFromDate:[NSDate dateWithXmppDateTimeString:@"2010-04-04T21:56:15.123-05:00"]], @"2010-04-04 19:56:15.123 GMT-07:00", nil);
    GHAssertNil([NSDate dateWithXmppDateTimeString:@"1969-7-4T02:56:15.123Z"], nil);
}

- (void)testXmppDateString
{
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.calendar = [NSCalendar currentCalendar];
    dateComponents.year = 1776;
    dateComponents.month = 7;
    dateComponents.day = 4;
    dateComponents.timeZone = [[NSTimeZone alloc] initWithName:@"US/Eastern"];

    GHAssertEqualStrings([[dateComponents date] xmppDateString], @"1776-07-04", nil);
}

- (void)testXmppTimeString
{
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.calendar = [NSCalendar currentCalendar];
    dateComponents.year = 2013;
    dateComponents.month = 2;
    dateComponents.day = 7;
    dateComponents.hour = 12;
    dateComponents.minute = 34;
    dateComponents.second = 56;
    dateComponents.timeZone = [[NSTimeZone alloc] initWithName:@"US/Eastern"];

    GHAssertEqualStrings([[dateComponents date] xmppTimeString], @"17:34:56Z", nil);
}

- (void)testXmppDateTimeString
{
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.calendar = [NSCalendar currentCalendar];
    dateComponents.year = 2013;
    dateComponents.month = 2;
    dateComponents.day = 7;
    dateComponents.hour = 12;
    dateComponents.minute = 34;
    dateComponents.second = 56;
    dateComponents.timeZone = [[NSTimeZone alloc] initWithName:@"US/Eastern"];

    GHAssertEqualStrings([[dateComponents date] xmppDateTimeString], @"2013-02-07T17:34:56Z", nil);
}

@end
