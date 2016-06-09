//
//  LogEntryTest.m
//  SimpleLog
//
//  Created by Danila Parkhomenko on 09/06/16.
//  Copyright © 2016 Itheme. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SimpleLog.h"
#import "TestableCategories.h"
#import "SimpleLogPrimitives.h"

@interface LogEntryTest : XCTestCase

@property (nonatomic, strong) SimpleErrorLog *log;
@property (nonatomic, strong) SimpleLogEntry *entry;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSDateFormatter *dateFormat;

@end

@implementation LogEntryTest

- (void)setUp {
    [super setUp];
    self.log = [[SimpleErrorLog alloc] init];
    self.entry = [[SimpleLogEntry alloc] init];
    self.date = [NSDate date];
    self.dateFormat = [[NSDateFormatter alloc] init];
    [self.dateFormat setDateFormat:@"YYYY-MM-dd HH:mm:ss Z"];
    [self.log clearErrors];
    [self.log clearGeneric];
    [self.log clearPerformance];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testConvertLogEntryToStringEmptyWithSuffix {
    NSString *string = [self.entry convertLogEntryToString];
    XCTAssert([string hasSuffix:jsonBreakerString]);
}

- (void)testConvertLogEntryToStringJSON {
    NSString *string = [self.entry convertLogEntryToString];
    string = [string substringToIndex:string.length - jsonBreakerString.length];
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:0
                                                           error:&error];
    XCTAssertTrue(dict);
    XCTAssertNil(error);
}

- (void)testConvertLogEntryToStringPerformance {
    NSDecimalNumber *latency = [NSDecimalNumber decimalNumberWithString:@"8.78"];
    NSString *desc = [NSString stringWithFormat:@"%d", rand()];
    NSNumber *size = @(rand());
    NSString *method = [NSString stringWithFormat:@"%d", rand()];
    [self.log logLatency:latency description:desc size:size forMethod:method];
    [self.log updateErrosList];
    SimpleLogEntry *performanceEntry = [self.log performanceEntryAtIndex:0];
    NSString *string = [performanceEntry convertLogEntryToString];
    string = [string substringToIndex:string.length - jsonBreakerString.length];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:0
                                                           error:nil];
    XCTAssertTrue([dict[@"date"] isEqualToString:[self.dateFormat stringFromDate:performanceEntry.time]]);
    XCTAssertTrue([dict[@"method"] isEqualToString:method]);
    XCTAssertTrue([dict[@"latency"] isEqualToNumber:latency]);
    XCTAssertTrue([dict[@"size"] isEqualToNumber:size]);
    dict = dict[@"error"];
    XCTAssertTrue([dict[@"code"] isEqualToNumber:@(SIMPLELOG_ERROR_CODE_PERFORMANCE_RECORD)]);
    XCTAssertTrue([dict[@"domain"] isEqualToString:SIMPLELOG_ERROR_DOMAIN]);
    XCTAssertTrue(dict[@"userInfo"]);
    XCTAssertTrue([dict[@"userInfo"][NSLocalizedDescriptionKey] isEqualToString:desc]);
}

- (void)testConvertLogEntryToStringGeneric {
    NSString *reason = [NSString stringWithFormat:@"%d", rand()];
    NSString *message = [NSString stringWithFormat:@"%d", rand()];
    NSString *desc = [NSString stringWithFormat:@"%d", rand()];
    NSString *method = [NSString stringWithFormat:@"%d", rand()];
    [self.log logReason:reason message:message description:desc forMethod:method];
    [self.log updateErrosList];
    SimpleLogEntry *genericEntry = [self.log genericEntryAtIndex:0];
    NSString *string = [genericEntry convertLogEntryToString];
    string = [string substringToIndex:string.length - jsonBreakerString.length];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:0
                                                           error:nil];
    XCTAssertTrue([dict[@"date"] isEqualToString:[self.dateFormat stringFromDate:genericEntry.time]]);
    XCTAssertTrue([dict[@"method"] isEqualToString:method]);
    dict = dict[@"error"];
    XCTAssertTrue(dict);
    XCTAssertTrue([dict[@"code"] isEqualToNumber:@(SIMPLELOG_ERROR_CODE_GENERIC_RECORD)]);
    XCTAssertTrue([dict[@"domain"] isEqualToString:SIMPLELOG_ERROR_DOMAIN]);
    XCTAssertTrue(dict[@"userInfo"]);
    desc = [NSString stringWithFormat:@"%@·%@·%@", reason, message, desc];
    XCTAssertTrue([dict[@"userInfo"][NSLocalizedDescriptionKey] isEqualToString:desc]);
}

- (void)testConvertLogEntryToStringGenericBreaker {
    NSString *reason = [NSString stringWithFormat:@"%d", rand()];
    NSString *message = [NSString stringWithFormat:@"%d%@", rand(), jsonBreakerString];
    NSString *desc = [NSString stringWithFormat:@"%d", rand()];
    NSString *method = [NSString stringWithFormat:@"%d", rand()];
    [self.log logReason:reason message:message description:desc forMethod:method];
    [self.log updateErrosList];
    SimpleLogEntry *genericEntry = [self.log genericEntryAtIndex:0];
    NSString *string = [genericEntry convertLogEntryToString];
    string = [string substringToIndex:string.length - jsonBreakerString.length];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:0
                                                           error:nil];
    dict = dict[@"error"];
    message = [message stringByReplacingOccurrencesOfString:jsonBreakerString
                                                 withString:@": : :"];
    desc = [NSString stringWithFormat:@"%@·%@·%@", reason, message, desc];
    XCTAssertTrue([dict[@"userInfo"][NSLocalizedDescriptionKey] isEqualToString:desc]);
}

- (void)testConvertLogEntryToStringError {
    NSString *domain = [NSString stringWithFormat:@"%d", rand()];
    NSInteger code = rand();
    NSString *desc = [NSString stringWithFormat:@"%d", rand()];
    NSString *method = [NSString stringWithFormat:@"%d", rand()];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    for (NSInteger i = 10; i--; ) {
        userInfo[[NSString stringWithFormat:@"%d", rand()]] = [NSString stringWithFormat:@"%d", rand()];
    }
    userInfo[NSLocalizedDescriptionKey] = desc;
    [self.log logError:[NSError errorWithDomain:domain code:code userInfo:userInfo] forMethod:method];
    [self.log updateErrosList];
    SimpleLogEntry *errorEntry = [self.log errorEntryAtIndex:0];
    NSString *string = [errorEntry convertLogEntryToString];
    string = [string substringToIndex:string.length - jsonBreakerString.length];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:0
                                                           error:nil];
    XCTAssertTrue([dict[@"date"] isEqualToString:[self.dateFormat stringFromDate:errorEntry.time]]);
    XCTAssertTrue([dict[@"method"] isEqualToString:method]);
    dict = dict[@"error"];
    XCTAssertTrue(dict);
    XCTAssertTrue([dict[@"code"] isEqualToNumber:@(code)]);
    XCTAssertTrue([dict[@"domain"] isEqualToString:domain]);
    XCTAssertTrue(dict[@"userInfo"]);
    [dict[@"userInfo"] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        XCTAssertTrue([userInfo[key] isEqualToString:obj]);
    }];
    XCTAssertTrue([dict[@"userInfo"][NSLocalizedDescriptionKey] isEqualToString:desc]);
}

- (void)testConvertLogEntryFromStringPerformance {
    NSDecimalNumber *latency = [NSDecimalNumber decimalNumberWithString:@"8.78"];
    NSString *desc = [NSString stringWithFormat:@"%d", rand()];
    NSNumber *size = @(rand());
    NSString *method = [NSString stringWithFormat:@"%d", rand()];
    [self.log logLatency:latency description:desc size:size forMethod:method];
    [self.log updateErrosList];
    SimpleLogEntry *performanceEntry = [self.log performanceEntryAtIndex:0];
    NSString *string = [performanceEntry convertLogEntryToString];
    string = [string substringToIndex:string.length - jsonBreakerString.length];
    SimpleLogEntry *res = [SimpleLogEntry logEntryFromString:string];
    XCTAssertTrue([res.time isEqualToDate:performanceEntry.time]);
    XCTAssertTrue([res.method isEqualToString:method]);
    XCTAssertTrue([res.latency isEqualToNumber:latency]);
    XCTAssertTrue([res.responseSize isEqualToNumber:size]);
    XCTAssertTrue([res.error.domain isEqualToString:SIMPLELOG_ERROR_DOMAIN]);
    XCTAssertTrue(res.error.code == SIMPLELOG_ERROR_CODE_PERFORMANCE_RECORD);
    XCTAssertTrue([res.error.localizedDescription isEqualToString:desc]);
}

- (void)testConvertLogEntryFromStringGeneric {
    NSString *reason = [NSString stringWithFormat:@"%d", rand()];
    NSString *message = [NSString stringWithFormat:@"%d", rand()];
    NSString *desc = [NSString stringWithFormat:@"%d", rand()];
    NSString *method = [NSString stringWithFormat:@"%d", rand()];
    [self.log logReason:reason message:message description:desc forMethod:method];
    [self.log updateErrosList];
    SimpleLogEntry *genericEntry = [self.log genericEntryAtIndex:0];
    NSString *string = [genericEntry convertLogEntryToString];
    string = [string substringToIndex:string.length - jsonBreakerString.length];
    SimpleLogEntry *res = [SimpleLogEntry logEntryFromString:string];
    desc = [NSString stringWithFormat:@"%@·%@·%@", reason, message, desc];
    XCTAssertTrue([res.time isEqualToDate:genericEntry.time]);
    XCTAssertTrue([res.method isEqualToString:method]);
    XCTAssertTrue([res.error.domain isEqualToString:SIMPLELOG_ERROR_DOMAIN]);
    XCTAssertTrue(res.error.code == SIMPLELOG_ERROR_CODE_GENERIC_RECORD);
    XCTAssertTrue([res.error.localizedDescription isEqualToString:desc]);
}

- (void)testConvertLogEntryFromStringError {
    NSString *domain = [NSString stringWithFormat:@"%d", rand()];
    NSInteger code = rand();
    NSString *desc = [NSString stringWithFormat:@"%d", rand()];
    NSString *method = [NSString stringWithFormat:@"%d", rand()];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    for (NSInteger i = 10; i--; ) {
        userInfo[[NSString stringWithFormat:@"%d", rand()]] = [NSString stringWithFormat:@"%d", rand()];
    }
    userInfo[NSLocalizedDescriptionKey] = desc;
    [self.log logError:[NSError errorWithDomain:domain code:code userInfo:userInfo] forMethod:method];
    [self.log updateErrosList];
    SimpleLogEntry *errorEntry = [self.log errorEntryAtIndex:0];
    NSString *string = [errorEntry convertLogEntryToString];
    string = [string substringToIndex:string.length - jsonBreakerString.length];
    SimpleLogEntry *res = [SimpleLogEntry logEntryFromString:string];
    XCTAssertTrue([res.time isEqualToDate:errorEntry.time]);
    XCTAssertTrue([res.method isEqualToString:method]);
    XCTAssertTrue([res.error.domain isEqualToString:domain]);
    XCTAssertTrue(res.error.code == code);
    XCTAssertTrue([res.error.localizedDescription isEqualToString:desc]);
    [res.error.userInfo enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        XCTAssertTrue([userInfo[key] isEqualToString:obj]);
    }];
}
- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
