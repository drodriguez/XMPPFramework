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


- (void)testParseDateShouldSucceed
{
    #define XMPPAssertParseDateEqualStrings(date, expected, description, ...) \
        GHAssertEqualStrings([_dateFormatter stringFromDate:[XMPPDateTimeProfiles parseDate:(date)]], expected, description, ##__VA_ARGS__);

    XMPPAssertParseDateEqualStrings(@"1776-07-04", @"1776-07-04 00:00:00.000 GMT-00:14:44", @"Should be standard GMT+HHMM as this is before DST was invented");
    XMPPAssertParseDateEqualStrings(@"1969-01-21", @"1969-01-21 00:00:00.000 GMT+01:00", @"Takes place during daylight saving time");
    XMPPAssertParseDateEqualStrings(@"1969-07-21", @"1969-07-21 00:00:00.000 GMT+01:00", @"Takes place during standard time.");
	XMPPAssertParseDateEqualStrings(@"2010-04-04", @"2010-04-04 00:00:00.000 GMT+02:00", nil);
	XMPPAssertParseDateEqualStrings(@"2010-12-25", @"2010-12-25 00:00:00.000 GMT+01:00", nil);
}

- (void)testParseDateShouldFail
{
    #define XMPPAssertParseDateNil(date, description, ...) \
        GHAssertNil([XMPPDateTimeProfiles parseDate:(date)], description, ##__VA_ARGS__);

    XMPPAssertParseDateNil(nil, nil);
    XMPPAssertParseDateNil(@"1776-7-4", nil);
    XMPPAssertParseDateNil(@"cheese", nil);
}

- (void)testParseTimeShouldSucceed
{

}

- (void)testParseTimeShouldFail
{

}

- (void)testParseDateTimeShouldSucceed
{

}

- (void)testParseDateTimeShouldFail
{
    
}

@end
