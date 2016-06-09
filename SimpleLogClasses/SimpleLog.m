//
//  SimpleLog.m
//

#import "SimpleLog.h"
#import <UIKit/UIKit.h>
//#import "NSString+InternalError.h"
#import "NSMutableString+HTMLGeneration.h"
#import "NSString+HTMLStrings.h"
#import "SimpleLogPrimitives.h"

typedef NS_ENUM(NSUInteger, LogErrorType) {
    LogErrorEntryType,
    LogErrorGenericType,
    LogErrorPerformanceType
};

@interface SimpleLogEntry ()
@property (nonatomic) NSDate *time;
@property (nonatomic) NSString *method;
@property (nonatomic) NSError *error;
@property (nonatomic) NSDecimalNumber *latency;
@property (nonatomic) NSNumber *responseSize;
@end

@interface LogCategoryMethod ()
@property (nonatomic, strong) NSString *method;
@property (nonatomic, weak) LogCategory *category;
@end

@interface LogCategory ()
@property (nonatomic, strong) NSString *reason;
@end

@implementation SimpleLogEntry

- (NSString *)convertLogEntryToString
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
                                                       options:0
                                                         error:&error];
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
        return @"";
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                     encoding:NSUTF8StringEncoding];
        return [[jsonString stringByReplacingOccurrencesOfString:jsonBreakerString
                                                      withString:@": : :"] stringByAppendingString:jsonBreakerString];
    }
}

+ (SimpleLogEntry *)logEntryFromString:(NSString *)content
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
@property (nonatomic, strong) NSMutableArray <SimpleLogEntry *> *genericEntries;
@property (nonatomic, strong) NSMutableArray <SimpleLogEntry *> *performanceEntries;

@property (nonatomic, strong) NSMutableDictionary <NSString *, LogCategory *> *categories;
@end

@implementation SimpleErrorLog

SimpleErrorLog *singleton = nil;

+ (SimpleErrorLog *) sharedErrorLog {
    if (singleton == nil) {
        singleton = [[SimpleErrorLog alloc] init];
    }
    return singleton;
}

- (id) init {
    if (self = [super init]) {
        self.errorEntries = [NSMutableArray arrayWithCapacity:LogCapacity];
        self.genericEntries = [NSMutableArray arrayWithCapacity:LogCapacity];
        self.performanceEntries = [NSMutableArray arrayWithCapacity:LogCapacity];
        self.categories = [NSMutableDictionary dictionary];
        self.timeFormatter = [[NSDateFormatter alloc] init];
        [self.timeFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss Z"];
    }
    return self;
}

- (LogCategory *)categoryWithReason:(NSString *)reason
{
    if (reason == nil) return [self categoryWithReason:@""];
    LogCategory *result = nil;
    @synchronized (self) {
        result = self.categories[reason];
        if (result == nil) {
            result = [[LogCategory alloc] init];
            result.reason = reason;
            self.categories[reason] = result;
        }
    }
    return result;
}

- (void)updateErrosList
{
    [self updateErrosListForType:LogErrorEntryType withArray:self.errorEntries];
    [self updateErrosListForType:LogErrorGenericType withArray:self.genericEntries];
    [self updateErrosListForType:LogErrorPerformanceType withArray:self.performanceEntries];
}

- (void)updateErrosListForType:(LogErrorType)type withArray:(NSMutableArray *)array
{
    [array removeAllObjects];
    NSArray *errorsList = [SimpleErrorLog downloadHistoryWithType:type];
    for (NSString *element in errorsList) {
        SimpleLogEntry *entry = [SimpleLogEntry logEntryFromString:element];
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

- (NSUInteger)getGenericRecordCount {
    NSUInteger count = self.genericEntries.count;
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

- (SimpleLogEntry *) genericEntryAtIndex:(NSUInteger)index {
    if (index < self.genericEntries.count) {
        SimpleLogEntry *entry;
        entry = self.genericEntries[index];
        return entry;
    }
    return nil;
}

- (void) logError:(NSError *)error forMethod:(NSString *)method {
    NSDecimalNumber *latency = error.userInfo[@"Latency"];
    @synchronized (self) {
        SimpleLogEntry *entry = [[SimpleLogEntry alloc] init];
        entry.time = [NSDate date];
        entry.method = method;
        entry.error = error;
        entry.latency = latency;
        entry.responseSize = error.userInfo[@"Size"];
        [SimpleErrorLog writeToHistoryFileLogEntry:entry];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:SimpleLogUpdatedNotification
                                                            object:nil
                                                          userInfo:nil];
        
    });
}

- (void) logLatency:(NSDecimalNumber *)latency description:(NSString *)description size:(NSNumber *)size forMethod:(NSString *)method
{
    @synchronized (self) {
        SimpleLogEntry *entry = [[SimpleLogEntry alloc] init];
        entry.time = [NSDate date];
        entry.method = method;
        entry.error = [NSError errorWithDomain:SIMPLELOG_ERROR_DOMAIN
                                          code:SIMPLELOG_ERROR_CODE_PERFORMANCE_RECORD
                                      userInfo:@{@"Latency": UNNIL(latency),
                                                 @"Size": UNNIL(size),
                                                 NSLocalizedDescriptionKey: description}];
        entry.latency = latency;
        entry.responseSize = size;
        [SimpleErrorLog writeToHistoryFileLogEntry:entry];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:SimpleLogUpdatedNotification
                                                            object:nil
                                                          userInfo:nil];
        
    });
}

- (void) logReason:(NSString *)reason message:(NSString *)message description:(NSString *)description forMethod:(NSString *)method
{
    if ((reason == nil) || (message == nil) || (description == nil)) {
        [self logReason:reason?reason:@""
                message:message?message:@""
            description:description?description:@""
              forMethod:method];
    }
    @synchronized (self) {
        SimpleLogEntry *entry = [[SimpleLogEntry alloc] init];
        entry.time = [NSDate date];
        entry.method = method;
        entry.error = [NSError errorWithDomain:SIMPLELOG_ERROR_DOMAIN
                                          code:SIMPLELOG_ERROR_CODE_GENERIC_RECORD
                                      userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@·%@·%@", reason, message, description]}];
        [SimpleErrorLog writeToHistoryFileLogEntry:entry];
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

- (NSString *)getGenericMessage
{
    SimpleErrorLog *log = self;
    NSInteger count = log.genericRecordCount;
    
    NSMutableString *result = [NSMutableString htmlTableRowWithParameters:nil contents:^NSString *(NSInteger column, NSMutableDictionary *cellParams) {
        switch (column) {
            case 0:
                return @"Time<br>Method";
            case 1:
                return @"Reason";
            case 2:
                return @"Data";
            case 3:
                return @"Description";
            default:
                return nil;
        }
    }];
    for (int i = 0; i < count; i++) {
        SimpleLogEntry *entry = [log genericEntryAtIndex:i];
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
    [self tryRemoveHistoryEntryType:LogErrorPerformanceType];
}

- (void) clearGeneric
{
    [self.genericEntries removeAllObjects];
    [self tryRemoveHistoryEntryType:LogErrorGenericType];
}

- (void) clearErrors
{
    [self.errorEntries removeAllObjects];
    [self tryRemoveHistoryEntryType:LogErrorEntryType];
}


#pragma mark - I/O logic for erros saving at file

+ (void)writeToHistoryFileLogEntry:(SimpleLogEntry *)logEntry
{
    LogErrorType type = (logEntry.error.code == SIMPLELOG_ERROR_CODE_PERFORMANCE_RECORD) ? LogErrorPerformanceType:((logEntry.error.code == SIMPLELOG_ERROR_CODE_GENERIC_RECORD) ? LogErrorGenericType : LogErrorEntryType);
    
    NSString *fileName = [self pathForLogType:type];
    //create file if it doesn't exist
    if(![[NSFileManager defaultManager] fileExistsAtPath:fileName])
        [[NSFileManager defaultManager] createFileAtPath:fileName contents:nil attributes:nil];

    NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:fileName];
    [file seekToEndOfFile];
    [file writeData:[[logEntry convertLogEntryToString] dataUsingEncoding:NSUTF8StringEncoding]];
    [file closeFile];
}


+ (NSArray *)downloadHistoryWithType:(LogErrorType)type
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
    NSArray *array = [content componentsSeparatedByString:jsonBreakerString];
    return array;
}

+ (NSString *)pathForLogType:(LogErrorType)type
{
    switch (type) {
        case LogErrorPerformanceType:
            return [self pathForLogFile:@"_performance"];
        case LogErrorGenericType:
            return [self pathForLogFile:@"_generic"];
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
    
    NSString *fileName = [NSString stringWithFormat:@"%@%@.txt", [[UIDevice currentDevice] identifierForVendor].UUIDString, type];
    
    return [folder stringByAppendingPathComponent:fileName];
}

- (BOOL)tryRemoveHistoryEntryType:(LogErrorType)type
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

@implementation LogCategory

- (void) logMessage:(NSString *)message description:(NSString *)description forMethod:(NSString *)method
{
    [[SimpleErrorLog sharedErrorLog] logReason:self.reason
                                       message:message
                                   description:description
                                     forMethod:method];
}

- (LogCategoryMethod *)method:(NSString *)method
{
    if (method == nil) {
        return [self method:@""];
    }
    LogCategoryMethod *result = [[LogCategoryMethod alloc] init];
    result.method = method;
    result.category = self;
    return result;
}

@end

@implementation LogCategoryMethod

- (void)logMessage:(NSString *)message description:(NSString *)description
{
    [self.category logMessage:message description:description forMethod:self.method];
}

@end

