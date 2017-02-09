//
//  HTMLGenerationTest.m
//  SimpleLog
//
//  Created by Danila Parkhomenko on 10/06/16.
//  Copyright © 2016 Itheme. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSMutableString+HTMLGeneration.h"

@interface HTMLGenerationTest : XCTestCase

@property (nonatomic, strong) NSRegularExpression *tableFrame;
@property (nonatomic, strong) NSRegularExpression *rowFrame;
@property (nonatomic, strong) NSRegularExpression *cellFrame;
@end

@implementation HTMLGenerationTest

- (void)setUp {
    [super setUp];
    self.tableFrame = [NSRegularExpression regularExpressionWithPattern:@"<table[^>]*>(.*)</table>" options:NSRegularExpressionCaseInsensitive error:nil];
    self.rowFrame = [NSRegularExpression regularExpressionWithPattern:@"<tr[^>]*>(.*)</tr>" options:NSRegularExpressionCaseInsensitive error:nil];
    self.cellFrame = [NSRegularExpression regularExpressionWithPattern:@"<td[^>]*>(.*)</td>" options:NSRegularExpressionCaseInsensitive error:nil];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testHTMLTableWithParametersWithBlockEmpty {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    for (NSInteger i = 10; i--; ) {
        parameters[[NSString stringWithFormat:@"%d", rand()]] = [NSString stringWithFormat:@"%d", rand()];
    }
    NSString *result = [NSMutableString htmlTableWithParameters:parameters contentsBlock:^NSString *(NSInteger row, BOOL *tableDone) {
        *tableDone = YES;
        return nil;
    }];
    NSString *prefix = @"<table ";
    XCTAssertTrue([result hasPrefix:prefix]);
    result = [result substringFromIndex:prefix.length];
    while (parameters.count > 0) {
        BOOL found = NO;
        for (NSInteger i = parameters.allKeys.count; i--; ) {
            NSString *key = parameters.allKeys[i];
            if ([result hasPrefix:key]) {
                prefix = [NSString stringWithFormat:@"%@=\"%@\" ", key, parameters[key]];
                if ([result hasPrefix:prefix]) {
                    [parameters removeObjectForKey:key];
                    result = [result substringFromIndex:prefix.length];
                    found = YES;
                }
            }
        }
        XCTAssertTrue(found || (parameters.count == 0));
        if (!found) break;
    }
    NSString *suffix = @"></table>";
    XCTAssertTrue([result hasSuffix:suffix]);
    result = [result substringToIndex:result.length - suffix.length];
    XCTAssertTrue([result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0);
}

- (void)testHTMLTableWithBlockGeneric {
    NSMutableArray *strings = [NSMutableArray array];
    for (NSInteger i = 10; i--; ) {
        [strings addObject:[NSString stringWithFormat:@"%d", rand()]];
    }
    NSString *result = [NSMutableString htmlTableWithParameters:nil contentsBlock:^NSString *(NSInteger row, BOOL *tableDone) {
        *tableDone = row == 9;
        return strings[row];
    }];
    NSTextCheckingResult *check = [self.tableFrame firstMatchInString:result options:0 range:NSMakeRange(0, result.length)];
    XCTAssertTrue(check.numberOfRanges == 2);
    result = [result substringWithRange:[check rangeAtIndex:1]];
    for (NSString *string in strings) {
        XCTAssertTrue([result hasPrefix:string]);
        result = [result substringFromIndex:string.length];
    }
    XCTAssertTrue(result.length == 0);
}

- (void)testHTMLTableWithContents {
    NSString *string = [NSString stringWithFormat:@"%d", rand()];
    NSString *result = [NSMutableString htmlTableWithParameters:nil contents:string];
    NSTextCheckingResult *check = [self.tableFrame firstMatchInString:result options:0 range:NSMakeRange(0, result.length)];
    XCTAssertTrue(check.numberOfRanges == 2);
    result = [result substringWithRange:[check rangeAtIndex:1]];
    XCTAssertTrue([result hasPrefix:string]);
    result = [result substringFromIndex:string.length];
    XCTAssertTrue(result.length == 0);
}

- (void)testHTMLTableRowWithBlockWithParameters {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    for (NSInteger i = 10; i--; ) {
        parameters[[NSString stringWithFormat:@"%d", rand()]] = [NSString stringWithFormat:@"%d", rand()];
    }
    NSString *result = [NSMutableString htmlTableRowWithParameters:parameters contents:^NSString *(NSInteger column, NSMutableDictionary *cellParams) {
        return nil;
    }];
    NSString *prefix = @"<tr ";
    XCTAssertTrue([result hasPrefix:prefix]);
    result = [result substringFromIndex:prefix.length];
    while (parameters.count > 0) {
        BOOL found = NO;
        for (NSInteger i = parameters.allKeys.count; i--; ) {
            if ([result hasPrefix:parameters.allKeys[i]]) {
                prefix = [NSString stringWithFormat:@"%@=\"%@\" ", parameters.allKeys[i], parameters[parameters.allKeys[i]]];
                if ([result hasPrefix:prefix]) {
                    result = [result substringFromIndex:prefix.length];
                    [parameters removeObjectForKey:parameters.allKeys[i]];
                    found = YES;
                }
            }
        }
        XCTAssertTrue(found || (parameters.count == 0));
        if (!found) break;
    }
    NSString *suffix = @"></tr>";
    XCTAssertTrue([result hasSuffix:suffix]);
    result = [result substringToIndex:result.length - suffix.length];
    XCTAssertTrue([result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0);

}

- (void)testHTMLTableRowOfLotsOfColumsWithBlockWithAccumulatingParameters {
    NSMutableArray *strings = [NSMutableArray array];
    NSMutableArray *params = [NSMutableArray array];
    for (NSInteger i = 10; i--; ) {
        [strings addObject:[NSString stringWithFormat:@"%d", rand()]];
        NSMutableDictionary *columnParam = [NSMutableDictionary dictionary];
        for (NSInteger j = 10; j--; ) {
            columnParam[[NSString stringWithFormat:@"%d", rand()]] = [NSString stringWithFormat:@"%d", rand()];
        }
        [params addObject:columnParam];
    }
    NSString *result = [NSMutableString htmlTableRowWithParameters:nil contents:^NSString *(NSInteger column, NSMutableDictionary *cellParams) {
        if (column < 10) {
            [cellParams addEntriesFromDictionary:params[column]];
            return strings[column];
        }
        return nil;
    }];
    NSTextCheckingResult *check = [self.rowFrame firstMatchInString:result options:0 range:NSMakeRange(0, result.length)];
    XCTAssertTrue(check.numberOfRanges == 2);
    result = [result substringWithRange:[check rangeAtIndex:1]];
    NSMutableDictionary *columnParams = [NSMutableDictionary dictionary];
    while (strings.count) {
        NSString *column = [strings firstObject];
        [strings removeObjectAtIndex:0];
        [columnParams addEntriesFromDictionary:[params firstObject]];
        [params removeObjectAtIndex:0];
        NSString *prefix = @"<td ";
        XCTAssertTrue([result hasPrefix:prefix]);
        result = [result substringFromIndex:prefix.length];
        NSMutableDictionary *paramsCheck = [columnParams mutableCopy];
        while (paramsCheck.count > 0) {
            BOOL found = NO;
            for (NSInteger i = paramsCheck.allKeys.count; i--; ) {
                prefix = [NSString stringWithFormat:@"%@=\"%@\" ", paramsCheck.allKeys[i], paramsCheck[paramsCheck.allKeys[i]]];
                if ([result hasPrefix:prefix]) {
                    result = [result substringFromIndex:prefix.length];
                    [paramsCheck removeObjectForKey:paramsCheck.allKeys[i]];
                    found = YES;
                }
            }
            XCTAssertTrue(found || (paramsCheck.count == 0));
            if (!found) break;
        }
        prefix = [NSString stringWithFormat:@">%@</td>", column];
        XCTAssertTrue([result hasPrefix:prefix]);
        result = [result substringFromIndex:prefix.length];
    }
    XCTAssertTrue(result.length == 0);
}

- (void)testSingleColumnRow {
    NSString *string = [NSString stringWithFormat:@"%d", rand()];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    for (NSInteger i = 10; i--; ) {
        parameters[[NSString stringWithFormat:@"%d", rand()]] = [NSString stringWithFormat:@"%d", rand()];
    }
    NSString *result = [NSMutableString htmlTableSingleColumnRowWithContents:^NSString *(NSInteger column, NSMutableDictionary *cellParams) {
        [cellParams addEntriesFromDictionary:parameters];
        XCTAssert(column == 0);
        return string;
    }];
    NSTextCheckingResult *check = [self.rowFrame firstMatchInString:result options:0 range:NSMakeRange(0, result.length)];
    XCTAssertTrue(check.numberOfRanges == 2);
    result = [result substringWithRange:[check rangeAtIndex:1]];
    check = [self.cellFrame firstMatchInString:result options:0 range:NSMakeRange(0, result.length)];
    XCTAssertTrue(check.numberOfRanges == 2);
    result = [result substringWithRange:[check rangeAtIndex:1]];
    XCTAssertTrue([result isEqualToString:string]);
}

//- (void) appendDictionaryKeysAndValues:(NSDictionary *)dict {
//    [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
//        [self appendFormat:@"%@=\"%@\" ", key, value];
//    }];
//}
//
//+ (NSMutableString *)htmlTableSingleColumnRowWithContents:(RowContentsGenerationBlock) contentsBlock {
//    NSMutableDictionary *cellParams = [NSMutableDictionary dictionary];
//    NSMutableString *cell = [contentsBlock(0, cellParams) mutableCopy];
//    NSMutableString *res = [@"<tr><td " mutableCopy];
//    [res appendDictionaryKeysAndValues:cellParams];
//    [res appendFormat:@">%@</td></tr>", [self normalizedString:cell]];
//    return res;
//}
//

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
