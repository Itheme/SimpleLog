//
//  SimpleLog.m
//  NativeiOSBooker
//
//  Created by Danila Parhomenko on 3/26/14.
//  Copyright (c) 2014 Booker Software. All rights reserved.
//

#import "SimpleLog.h"
#import <UIKit/UIKit.h>
//#import "NSString+InternalError.h"
#import "NSMutableString+HTMLGeneration.h"
#import "NSString+HTMLStrings.h"
#import "SimpleLogPrimitives.h"

typedef NS_ENUM(NSUInteger, BookerErrorType) {
    BookerErrorEntryType,
    BookerErrorSyncType,
    BookerErrorPerformanceType
};

@interface SimpleLogEntry ()
@property (nonatomic) NSDate *time;
@property (nonatomic) NSString *method;
@property (nonatomic) NSError *error;
@property (nonatomic) NSDecimalNumber *latency;
@property (nonatomic) NSNumber *responseSize;
@end

@implementation SimpleLogEntry

- (NSString *)convertBookerLogEntryToString
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"YYYY-MM-dd HH:mm:ss Z"];
    NSString *date = [dateFormat stringFromDate:self.time];
    NSMutableDictionary *userInfoDict = @{}.mutableCopy;
    if (self.error.userInfo) {
        for (NSString *key in self.error.userInfo.allKeys) {
            [userInfoDict setObject:((NSObject *)self.error.userInfo[key]).description forKey:key];
        }
    }
   
    NSDictionary *errorDict = @{@"domain" : UNNIL(self.error.domain),
                                @"code" : UNNIL(@(self.error.code)),
                                @"userInfo" : UNNIL(userInfoDict)
                                };
    NSDictionary *dict = @{@"date" : UNNIL(date),
                           @"method" : UNNIL(self.method),
                           @"error" : UNNIL(errorDict),
                           @"latency" : UNNIL(self.latency),
                           @"size" : UNNIL(self.responseSize)};
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
        return @"";
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return [jsonString stringByAppendingString:@":::"];
    }
}

+ (SimpleLogEntry *)bookerLogEntryFromString:(NSString *)content
{
    
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (!json.allKeys) {
        return nil;
    }
    SimpleLogEntry *entry = [[SimpleLogEntry alloc] init];
    // Convert string to date object
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"YYYY-MM-dd HH:mm:ss Z"];
    NSDate *date = [dateFormat dateFromString:json[@"date"]];
    entry.time = date;
    entry.method = [json[@"method"] isKindOfClass:[NSString class]] ? json[@"method"] : @"";
    NSDictionary *error = json[@"error"];
    NSInteger code = ((NSNumber *)error[@"code"]).integerValue;
    entry.error = [NSError errorWithDomain:error[@"domain"] code:code userInfo:error[@"userInfo"]];
    entry.latency = [json[@"latency"] isKindOfClass:[NSNull class]] ? [NSDecimalNumber numberWithInt:0] : json[@"latency"];
    entry.responseSize = [json[@"size"] isKindOfClass:[NSNull class]] ? @0 : json[@"size"];
    return entry;
}

@end

@interface SimpleErrorLog ()
@property (nonatomic, strong) NSMutableArray <SimpleLogEntry *> *errorEntries;
@property (nonatomic, strong) NSMutableArray <SimpleLogEntry *> *syncEntries;
@property (nonatomic, strong) NSMutableArray <SimpleLogEntry *> *performanceEntries;
@end

@implementation SimpleErrorLog

SimpleErrorLog *singleton = nil;

+ (SimpleErrorLog *) sharedErrorLog {
    if (singleton == nil) {
        singleton = [[SimpleErrorLog alloc] init];
        singleton.errorEntries = [NSMutableArray arrayWithCapacity:LogCapacity];
        singleton.syncEntries = [NSMutableArray arrayWithCapacity:LogCapacity];
        singleton.performanceEntries = [NSMutableArray arrayWithCapacity:LogCapacity];
        singleton.timeFormatter = [[NSDateFormatter alloc] init];
        [singleton.timeFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss Z"];
    }
    return singleton;
}

- (void)updateErrosList
{
    [self updateErrosListForType:BookerErrorEntryType withArray:self.errorEntries];
    [self updateErrosListForType:BookerErrorSyncType withArray:self.syncEntries];
    [self updateErrosListForType:BookerErrorPerformanceType withArray:self.performanceEntries];
}

- (void)updateErrosListForType:(BookerErrorType)type withArray:(NSMutableArray *)array
{
    [array removeAllObjects];
    NSArray *errorsList = [SimpleErrorLog downloadHistoryWithType:type];
    for (NSString *element in errorsList) {
        SimpleLogEntry *entry = [SimpleLogEntry bookerLogEntryFromString:element];
        if (!entry) {
            continue;
        }
        [array addObject:entry];
    }
}

- (NSUInteger)getPerformanceRecordCount {
    NSUInteger count;
    count = self.performanceEntries.count;
    return count;
}

- (NSUInteger)getErrorRecordCount {
    NSUInteger count;
    count = self.errorEntries.count;
    return count;
}

- (NSUInteger)getSyncRecordCount {
    NSUInteger count = self.syncEntries.count;
    return count;
}

- (SimpleLogEntry *) performanceEntryAtIndex:(NSUInteger)index {
    if (index < self.performanceEntries.count) {
        SimpleLogEntry *entry;
        entry = self.performanceEntries[index];
        return entry;
    }
    return nil;
}

- (SimpleLogEntry *) errorEntryAtIndex:(NSUInteger)index {
    if (index < self.errorEntries.count) {
        SimpleLogEntry *entry;
        entry = self.errorEntries[index];
        return entry;
    }
    return nil;
}

- (SimpleLogEntry *) syncEntryAtIndex:(NSUInteger)index {
    if (index < self.syncEntries.count) {
        SimpleLogEntry *entry;
        entry = self.syncEntries[index];
        return entry;
    }
    return nil;
}

- (void) logError:(NSError *)error forMethod:(NSString *)method {
    NSDecimalNumber *latency = error.userInfo[@"Latency"];
//    if ((latency == nil) && (error.code != BOOKERAPI_ERROR_CODE_SYNC_RECORD) && ![[error.localizedDescription lowercaseString] hasPrefix:@"you are not authorized to save this order"] && ![[error.localizedDescription lowercaseString] hasPrefix:@"no parsable response"]) {
//#warning filter only customers cancellation errors, not all "no parsable response" ones
//        [Answers logCustomEventWithName:method customAttributes:error.userInfo];
//    }
    @synchronized (self) {
        NSRange range = [method rangeOfString:@"json/BusinessService.svc"];
        if (range.location != NSNotFound) {
            method = [method substringFromIndex:range.location + range.length];
        }
        SimpleLogEntry *entry = [[SimpleLogEntry alloc] init];
        entry.time = [NSDate date];
        entry.method = method;
        entry.error = error;
        entry.latency = latency;
        entry.responseSize = error.userInfo[@"Size"];
        [SimpleErrorLog writeToHistoryFileBookerLogEntry:entry];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:SimpleLogUpdatedNotification
                                                            object:nil
                                                          userInfo:nil];
        
    });
}


- (NSString *)getPerformanceMessage
{
    SimpleErrorLog *log = self;
    NSInteger count = log.performanceRecordCount;
    
    NSMutableString *result = [NSMutableString htmlTableRowWithParameters:nil contents:^NSString *(NSInteger column, NSMutableDictionary *cellParams) {
        switch (column) {
            case 0:
                return @"Time";
            case 1:
                return @"Method";
            case 2:
                return @"Size";
            case 3:
                return @"Latency";
            default:
                return nil;
        }
    }];
    for (int i = 0; i < count; i++) {
        SimpleLogEntry *entry = [log performanceEntryAtIndex:i];
        [result appendString:[NSMutableString htmlTableRowWithParameters:nil contents:^NSString *(NSInteger column, NSMutableDictionary *cellParams) {
            switch (column) {
                case 0:
                    if (entry.time) {
                        return [log.timeFormatter stringFromDate:entry.time];
                    }
                    return @"-";
                case 1:
                    if (entry.method) {
                        return entry.method.htmlString;
                    }
                    return @"-";
                case 2: {
                    if (entry.responseSize) {
                        NSInteger size = [entry.responseSize integerValue];
                        if (size > 1024) {
                            return [NSString stringWithFormat:@"%d kb", (int)(size/1024)];
                        }
                        return [NSString stringWithFormat:@"%.3f kb", size/1024.0];
                    }
                    return @"-";
                }
                case 3: {
                    if (entry.latency) {
                        return [NSString stringWithFormat:@"%.0f ms", [entry.latency doubleValue]];
                    }
                    return @"-";
                }
                default:
                    return nil;
            }
        }]];
    }
    return [NSMutableString htmlTableWithParameters:nil contents:result];
}

- (NSString *)getSyncMessage
{
    SimpleErrorLog *log = self;
    NSInteger count = log.syncRecordCount;
    
    NSMutableString *result = [NSMutableString htmlTableRowWithParameters:nil contents:^NSString *(NSInteger column, NSMutableDictionary *cellParams) {
        switch (column) {
            case 0:
                return @"Time<br>Method";
            case 1:
                return @"Reason";
            case 2:
                return @"F&B Order".htmlString;
            case 3:
                return @"Booker Order";
            default:
                return nil;
        }
    }];
    for (int i = 0; i < count; i++) {
        SimpleLogEntry *entry = [log syncEntryAtIndex:i];
        NSString *fullDescription = entry.error.localizedDescription;
        NSArray *components = [fullDescription componentsSeparatedByString:@"·"];
        [result appendString:[NSMutableString htmlTableRowWithParameters:nil contents:^NSString *(NSInteger column, NSMutableDictionary *cellParams) {
            switch (column) {
                case 0:
                    return [NSString stringWithFormat:@"%@<br>%@", [log.timeFormatter stringFromDate:entry.time], entry.method.htmlString];
                case 1:
                    if (components.count > 0) {
                        return ((NSString *)components[0]).htmlString;
                    }
                    return @"";
                case 2:
                    if (components.count > 1) {
                        return ((NSString *)components[1]).htmlString;
                    }
                    return @"";
                case 3:
                    if (components.count > 2) {
                        return ((NSString *)components[2]).htmlString;
                    }
                    return @"";
                default:
                    return nil;
            }
        }]];
    }
    return [NSMutableString htmlTableWithParameters:nil contents:result];
}

- (NSString *)getErrorsMessage
{
    SimpleErrorLog *log = self;
    NSInteger count = log.errorRecordCount;
    
    NSMutableString *result = [NSMutableString htmlTableRowWithParameters:nil contents:^NSString *(NSInteger column, NSMutableDictionary *cellParams) {
        switch (column) {
            case 0:
                return @"Time";
            case 1:
                return @"Method";
            case 2:
                return @"Error";
            default:
                return nil;
        }
    }];
    for (int i = 0; i < count; i++) {
        SimpleLogEntry *entry = [log errorEntryAtIndex:i];
        [result appendString:[NSMutableString htmlTableRowWithParameters:nil contents:^NSString *(NSInteger column, NSMutableDictionary *cellParams) {
            switch (column) {
                case 0:
                    return [NSString stringWithFormat:@"%@", [log.timeFormatter stringFromDate:entry.time]];
                case 1:
                    if (entry.method)
                        return entry.method.htmlString;
                    return @"";
                case 2: {
                    NSString *message = entry.error.localizedDescription;
                    message = [NSString stringWithFormat:@"%@ (%ld)", message, (long)entry.error.code];
                    return message.htmlString;
                }
                default:
                    return nil;
            }
        }]];
    }
    return [NSMutableString htmlTableWithParameters:nil contents:result];
}

- (void) clearPerformance
{
    [self.performanceEntries removeAllObjects];
    [self tryRemoveHistoryEntryType:BookerErrorPerformanceType];
}

- (void) clearSync
{
    [self.syncEntries removeAllObjects];
    [self tryRemoveHistoryEntryType:BookerErrorSyncType];
}

- (void) clearErrors
{
    [self.errorEntries removeAllObjects];
    [self tryRemoveHistoryEntryType:BookerErrorEntryType];
}


#pragma mark - I/O logic for erros saving at file

+ (void)writeToHistoryFileBookerLogEntry:(SimpleLogEntry *)logEntry
{
    BookerErrorType type = (logEntry.error.code == SIMPLELOG_ERROR_CODE_PERFORMANCE_RECORD) ? BookerErrorPerformanceType:((logEntry.error.code == SIMPLELOG_ERROR_CODE_SYNC_RECORD) ? BookerErrorSyncType : BookerErrorEntryType);
    
    NSString *fileName = [self pathForLogType:type];
    //create file if it doesn't exist
    if(![[NSFileManager defaultManager] fileExistsAtPath:fileName])
        [[NSFileManager defaultManager] createFileAtPath:fileName contents:nil attributes:nil];

    NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:fileName];
    [file seekToEndOfFile];
    [file writeData:[[logEntry convertBookerLogEntryToString] dataUsingEncoding:NSUTF8StringEncoding]];
    [file closeFile];
}


+ (NSArray *)downloadHistoryWithType:(BookerErrorType)type
{
    NSString *fileName = [self pathForLogType:type];
    if(![[NSFileManager defaultManager] fileExistsAtPath:fileName])
    {
        return nil;
    }
    NSError *error = nil;
    NSString* content = [NSString stringWithContentsOfFile:fileName
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error];
    if (error) {
        NSLog(@"Error %@ No such file %@", error.localizedDescription, fileName);
        return nil;
    }
    NSArray *array = [content componentsSeparatedByString:@":::"];
    return array;
}

+ (NSString *)pathForLogType:(BookerErrorType)type
{
    switch (type) {
        case BookerErrorPerformanceType:
            return [self pathForLogFile:@"_performance"];
        case BookerErrorSyncType:
            return [self pathForLogFile:@"_sync"];
        default:
            return [self pathForLogFile:@"_entry"];
    }
}

+ (NSString *)pathForLogFile:(NSString *)type
{
    NSString* documentsDirectory = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                                                       NSUserDomainMask,
                                                                       YES)[0];
    NSString *folder = [documentsDirectory stringByAppendingPathComponent:@"logsFolder"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    if (![fileManager fileExistsAtPath:folder]){
        [fileManager createDirectoryAtPath:folder
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];
        if (error) {
            NSLog(@"Error %@", error);
        }
    }
    
    NSString *fileName = [NSString stringWithFormat:@"%@%@.txt", [[UIDevice currentDevice] identifierForVendor], type];
    
    return [folder stringByAppendingPathComponent:fileName];
}

- (BOOL)tryRemoveHistoryEntryType:(BookerErrorType)type
{
    
    NSString *fileName = [[self class] pathForLogType:type];
    
    //create file if it doesn't exist
    if([[NSFileManager defaultManager] fileExistsAtPath:fileName])
    {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:fileName error:&error];
        if (error){
            NSLog(@"%@", error);
            return NO;
        }
    }
    return YES;
}


@end
