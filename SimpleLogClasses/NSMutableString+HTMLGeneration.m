//
//  NSString+HTMLGeneration.m
//

#import "NSMutableString+HTMLGeneration.h"

@implementation NSMutableString (HTMLGeneration)

- (void) appendDictionaryKeysAndValues:(NSDictionary *)dict {
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [self appendFormat:@"%@=\"%@\" ", key, value];
    }];
}

+ (NSString *)normalizedString:(NSString *)string
{
    if (string) {
        NSRange nullRange = [string rangeOfString:@"(null)"];
        if (nullRange.location != NSNotFound) {
            NSRange bracketedNullRange = [string rangeOfString:@"((null))"];
            if (bracketedNullRange.location != NSNotFound) {
                return [self normalizedString:[string stringByReplacingCharactersInRange:bracketedNullRange withString:@""]];
            }
            return [self normalizedString:[string stringByReplacingCharactersInRange:nullRange withString:@""]];
        }
        return string;
    }
    return @"";
}

+ (NSMutableString *)htmlTableWithParameters:(NSDictionary *) parameters contentsBlock:(TableContentsGenerationBlock) contentsBlock {
    BOOL tableDone = NO;
    NSMutableString *body = [@"" mutableCopy];
    for (NSInteger row = 0; !tableDone; row++) {
        NSString *rowString = contentsBlock(row, &tableDone);
        if (rowString)
            [body appendString:[self normalizedString:rowString]];
    }
    NSMutableString *res = [@"<table " mutableCopy];
    [res appendDictionaryKeysAndValues:parameters];
    [res appendFormat:@">%@</table>", body];
    return res;
}

+ (NSMutableString *)htmlTableWithParameters:(NSDictionary *) parameters contents:(NSString *) contents {
    NSMutableString *res = [@"<table " mutableCopy];
    [res appendDictionaryKeysAndValues:parameters];
    [res appendFormat:@">%@</table>", [self normalizedString:contents]];
    return res;
}

+ (NSMutableString *)htmlTableRowWithParameters:(NSDictionary *) parameters contents:(RowContentsGenerationBlock) contentsBlock {
    BOOL rowDone = NO;
    NSMutableString *body = [@"" mutableCopy];
    NSMutableDictionary *cellParams = [NSMutableDictionary dictionary];
    for (NSInteger column = 0; !rowDone; column++) {
        NSString *cell = contentsBlock(column, cellParams);
        if (cell) {
            [body appendString:@"<td "];
            [body appendDictionaryKeysAndValues:cellParams];
            [body appendFormat:@">%@</td>", [self normalizedString:cell]];
        } else
            rowDone = YES;
    }
    NSMutableString *res = [@"<tr " mutableCopy];
    [res appendDictionaryKeysAndValues:parameters];
    [res appendFormat:@">%@</tr>", body];
    return res;
}

+ (NSMutableString *)htmlTableSingleColumnRowWithContents:(RowContentsGenerationBlock) contentsBlock {
    NSMutableDictionary *cellParams = [NSMutableDictionary dictionary];
    NSMutableString *cell = [contentsBlock(0, cellParams) mutableCopy];
    NSMutableString *res = [@"<tr><td " mutableCopy];
    [res appendDictionaryKeysAndValues:cellParams];
    [res appendFormat:@">%@</td></tr>", [self normalizedString:cell]];
    return res;
}

@end
