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

- (void)setUp
{
    // Since dates do not have a explicit time zone, they are parsed in the
    // current timezone. To make this test repeatable we must fix the time zone.
    _originalTimeZone = [NSTimeZone defaultTimeZone];
    [NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneWithName:@"US/Pacific"]];

    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS z"];
    [_dateFormatter setLocale:[NSLocale systemLocale]];
}

- (void)tearDown
{
    [NSTimeZone setDefaultTimeZone:_originalTimeZone];
}


- (void)testParseDateShouldSucceed
{
    #define XMPPAssertParseDateEqualStrings(date, expected, description, ...) \
        GHAssertEqualStrings([_dateFormatter stringFromDate:[XMPPDateTimeProfiles parseDate:date]], expected, description, ##__VA_ARGS__);

    XMPPAssertParseDateEqualStrings(@"1776-07-04", @"1776-07-04 00:00:00.000 GMT-07:52:58", @"Should be standard GMT+HHMM as this is before DST was invented");
    XMPPAssertParseDateEqualStrings(@"1969-01-21", @"1969-01-21 00:00:00.000 GMT-08:00", @"Takes place during daylight saving time");
    XMPPAssertParseDateEqualStrings(@"1969-07-21", @"1969-07-21 00:00:00.000 GMT-07:00", @"Takes place during standard time.");
	XMPPAssertParseDateEqualStrings(@"2010-04-04", @"2010-04-04 00:00:00.000 GMT-07:00", nil);
	XMPPAssertParseDateEqualStrings(@"2010-12-25", @"2010-12-25 00:00:00.000 GMT-08:00", nil);
}

- (void)testParseDateShouldFail
{
    #define XMPPAssertParseDateNil(date, description, ...) \
        GHAssertNil([XMPPDateTimeProfiles parseDate:date], description, ##__VA_ARGS__);

    XMPPAssertParseDateNil(nil, nil);
    XMPPAssertParseDateNil(@"1776-7-4", nil);
    XMPPAssertParseDateNil(@"cheese", nil);
}

- (void)testParseTimeShouldSucceed
{
    // The date part will be the current day
    NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
    [dayFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dayFormatter setDateFormat:@"yyyy-MM-dd"];
    [dayFormatter setLocale:[NSLocale systemLocale]];

    // The tz part will be the one of the current day (DST/Standard)
    NSDateFormatter *tzFormatter = [[NSDateFormatter alloc] init];
    [tzFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [tzFormatter setDateFormat:@"z"];
    [tzFormatter setLocale:[NSLocale systemLocale]];

    #define XMPPAssertParseTimeEqualStrings(time, expected, description, ...) \
        do { \
            NSString *_expected = [NSString stringWithFormat:@"%@ %@ %@", \
                                   [dayFormatter stringFromDate:[NSDate date]], \
                                   expected, \
                                   [tzFormatter stringFromDate:[NSDate date]]]; \
            GHAssertEqualStrings([_dateFormatter stringFromDate:[XMPPDateTimeProfiles parseTime:time]], _expected, description, ##__VA_ARGS__); \
        } while (0)

	XMPPAssertParseTimeEqualStrings(@"16:00:00",           @"16:00:00.000", nil);
	XMPPAssertParseTimeEqualStrings(@"16:00:00Z",          @"08:00:00.000", nil);
	XMPPAssertParseTimeEqualStrings(@"16:00:00-06:00",     @"14:00:00.000", nil);
	XMPPAssertParseTimeEqualStrings(@"16:00:00.123",       @"16:00:00.123", nil);
	XMPPAssertParseTimeEqualStrings(@"16:00:00.123Z",      @"08:00:00.123", nil);
	XMPPAssertParseTimeEqualStrings(@"16:00:00.123-06:00", @"14:00:00.123", nil);
}

- (void)testParseTimeShouldFail
{
    #define XMPPAssertParseTimeNil(time, description, ...) \
        GHAssertNil([XMPPDateTimeProfiles parseTime:(time)], description, ##__VA_ARGS__);

	XMPPAssertParseTimeNil(nil, nil);
	XMPPAssertParseTimeNil(@"16-00-00", nil);
	XMPPAssertParseTimeNil(@"16:00:00-0600", nil);
	XMPPAssertParseTimeNil(@"16:00:00.1", nil);
	XMPPAssertParseTimeNil(@"16:00.123", nil);
	XMPPAssertParseTimeNil(@"cheese", nil);
}

- (void)testParseDateTimeShouldSucceed
{
    #define XMPPAssertParseDateTimeEqualStrings(date, expected, description, ...) \
        GHAssertEqualStrings([_dateFormatter stringFromDate:[XMPPDateTimeProfiles parseDateTime:date]], expected, description, ##__VA_ARGS__);

	XMPPAssertParseDateTimeEqualStrings(@"1776-07-04T02:56:15Z",          @"1776-07-03 19:03:17.000 GMT-07:52:58", nil);
	XMPPAssertParseDateTimeEqualStrings(@"1776-07-04T21:56:15-05:00",     @"1776-07-04 19:03:17.000 GMT-07:52:58", nil);
	XMPPAssertParseDateTimeEqualStrings(@"1776-07-04T02:56:15.123Z",      @"1776-07-03 19:03:17.123 GMT-07:52:58", nil);
	XMPPAssertParseDateTimeEqualStrings(@"1776-07-04T21:56:15.123-05:00", @"1776-07-04 19:03:17.123 GMT-07:52:58", nil);

    XMPPAssertParseDateTimeEqualStrings(@"1969-01-21T02:56:15Z",          @"1969-01-20 18:56:15.000 GMT-08:00", nil);
	XMPPAssertParseDateTimeEqualStrings(@"1969-01-20T21:56:15-05:00",     @"1969-01-20 18:56:15.000 GMT-08:00", nil);
	XMPPAssertParseDateTimeEqualStrings(@"1969-01-21T02:56:15.123Z",      @"1969-01-20 18:56:15.123 GMT-08:00", nil);
	XMPPAssertParseDateTimeEqualStrings(@"1969-01-20T21:56:15.123-05:00", @"1969-01-20 18:56:15.123 GMT-08:00", nil);

    XMPPAssertParseDateTimeEqualStrings(@"1969-07-21T02:56:15Z",          @"1969-07-20 19:56:15.000 GMT-07:00", nil);
	XMPPAssertParseDateTimeEqualStrings(@"1969-07-20T21:56:15-05:00",     @"1969-07-20 19:56:15.000 GMT-07:00", nil);
	XMPPAssertParseDateTimeEqualStrings(@"1969-07-21T02:56:15.123Z",      @"1969-07-20 19:56:15.123 GMT-07:00", nil);
	XMPPAssertParseDateTimeEqualStrings(@"1969-07-20T21:56:15.123-05:00", @"1969-07-20 19:56:15.123 GMT-07:00", nil);

    XMPPAssertParseDateTimeEqualStrings(@"2010-04-04T02:56:15Z",          @"2010-04-03 19:56:15.000 GMT-07:00", nil);
	XMPPAssertParseDateTimeEqualStrings(@"2010-04-04T21:56:15-05:00",     @"2010-04-04 19:56:15.000 GMT-07:00", nil);
	XMPPAssertParseDateTimeEqualStrings(@"2010-04-04T02:56:15.123Z",      @"2010-04-03 19:56:15.123 GMT-07:00", nil);
	XMPPAssertParseDateTimeEqualStrings(@"2010-04-04T21:56:15.123-05:00", @"2010-04-04 19:56:15.123 GMT-07:00", nil);

    XMPPAssertParseDateTimeEqualStrings(@"2010-12-25T02:56:15Z",          @"2010-12-24 18:56:15.000 GMT-08:00", nil);
	XMPPAssertParseDateTimeEqualStrings(@"2010-12-25T21:56:15-05:00",     @"2010-12-25 18:56:15.000 GMT-08:00", nil);
	XMPPAssertParseDateTimeEqualStrings(@"2010-12-25T02:56:15.123Z",      @"2010-12-24 18:56:15.123 GMT-08:00", nil);
	XMPPAssertParseDateTimeEqualStrings(@"2010-12-25T21:56:15.123-05:00", @"2010-12-25 18:56:15.123 GMT-08:00", nil);
}

- (void)testParseDateTimeShouldFail
{
    #define XMPPAssertParseDateTimeNil(date, description, ...) \
        GHAssertNil([XMPPDateTimeProfiles parseDateTime:date], description, ##__VA_ARGS__);

    XMPPAssertParseDateTimeNil(nil, nil);
	XMPPAssertParseDateTimeNil(@"1969-07-20 21:56:15Z", nil);
	XMPPAssertParseDateTimeNil(@"1969-7-4T02:56:15.123Z", nil);
	XMPPAssertParseDateTimeNil(@"cheese", nil);
}

@end
