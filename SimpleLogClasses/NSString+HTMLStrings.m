//
//  NSString+HTMLStrings.m
//  NativeiOSBooker
//

#import "NSString+HTMLStrings.h"

@implementation NSString (HTMLStrings)

- (NSString*)getHTMLString {
    NSMutableString *outputText = [self mutableCopy];
    [outputText replaceOccurrencesOfString:@"&"  withString:@"&amp;" options:NSLiteralSearch range:NSMakeRange(0, outputText.length)];
    [outputText replaceOccurrencesOfString:@"<"  withString:@"&lt;" options:NSLiteralSearch range:NSMakeRange(0, outputText.length)];
    [outputText replaceOccurrencesOfString:@">"  withString:@"&gt;" options:NSLiteralSearch range:NSMakeRange(0, outputText.length)];
    [outputText replaceOccurrencesOfString:@"""" withString:@"&quot;" options:NSLiteralSearch range:NSMakeRange(0, outputText.length)];
    [outputText replaceOccurrencesOfString:@"'"  withString:@"&#039;" options:NSLiteralSearch range:NSMakeRange(0, outputText.length)];
    [outputText replaceOccurrencesOfString:@"\n" withString:@"<br>" options:NSLiteralSearch range:NSMakeRange(0, outputText.length)];
    return [outputText copy];
}

@end
