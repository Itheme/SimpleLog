//
//  SimpleLog.h
//

#import <Foundation/Foundation.h>

@interface SimpleLogEntry : NSObject
@property (nonatomic, readonly) NSDate *time;
@property (nonatomic, readonly) NSString *method;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, readonly) NSDecimalNumber *latency;
@property (nonatomic, readonly) NSNumber *responseSize;
@end

@interface LogCategoryMethod : NSObject

- (void) logMessage:(NSString *)message description:(NSString *)description;

@end


@interface LogCategory : NSObject

- (LogCategoryMethod *)method:(NSString *)method;

- (void) logMessage:(NSString *)message description:(NSString *)description forMethod:(NSString *)method;

@end

@interface SimpleErrorLog : NSObject

@property (nonatomic, strong) NSDateFormatter *timeFormatter;
@property (nonatomic, readonly, getter = getPerformanceRecordCount) NSUInteger performanceRecordCount;
@property (nonatomic, readonly, getter = getErrorRecordCount) NSUInteger errorRecordCount;
@property (nonatomic, readonly, getter = getGenericRecordCount) NSUInteger genericRecordCount;
@property (nonatomic, readonly, strong) NSMutableArray *performanceEntries;

+ (SimpleErrorLog *) sharedErrorLog;

- (LogCategory *)categoryWithReason:(NSString *)reason;

- (void)updateErrosList;

- (SimpleLogEntry *) performanceEntryAtIndex:(NSUInteger)index;
- (SimpleLogEntry *) errorEntryAtIndex:(NSUInteger)index;
- (SimpleLogEntry *) genericEntryAtIndex:(NSUInteger)index;

- (NSString *)getErrorsMessage;
- (NSString *)getPerformanceMessage;
- (NSString *)getGenericMessage;

- (void) logError:(NSError *)error forMethod:(NSString *)method;
- (void) logLatency:(NSDecimalNumber *)latency description:(NSString *)description size:(NSNumber *)size forMethod:(NSString *)method;
- (void) logReason:(NSString *)reason message:(NSString *)message description:(NSString *)description forMethod:(NSString *)method;

- (void) clearPerformance;
- (void) clearGeneric;
- (void) clearErrors;

@end
