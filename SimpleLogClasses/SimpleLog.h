//
//  SimpleLog.h
//  NativeiOSBooker
//
//  Created by Danila Parhomenko on 3/26/14.
//  Copyright (c) 2014 Booker Software. All rights reserved.
//

#import <Foundation/Foundation.h>
//#define SYNCLOGPROMPT_FNB @"\nF&B ·"
//#define SYNCLOGPROMPT_BOOKER @"\nBooker ·"

//static NSString *BOOKERUI_LogUpdated;

@interface SimpleLogEntry : NSObject
@property (nonatomic, readonly) NSDate *time;
@property (nonatomic, readonly) NSString *method;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, readonly) NSDecimalNumber *latency;
@property (nonatomic, readonly) NSNumber *responseSize;
@end

@interface SimpleErrorLog : NSObject

@property (nonatomic, strong) NSDateFormatter *timeFormatter;
@property (nonatomic, readonly, getter = getPerformanceRecordCount) NSUInteger performanceRecordCount;
@property (nonatomic, readonly, getter = getErrorRecordCount) NSUInteger errorRecordCount;
@property (nonatomic, readonly, getter = getSyncRecordCount) NSUInteger syncRecordCount;
@property (nonatomic, readonly, strong) NSMutableArray *performanceEntries; // access only in sync with error log

+ (SimpleErrorLog *) sharedErrorLog;

- (void)updateErrosList;

- (SimpleLogEntry *) performanceEntryAtIndex:(NSUInteger)index;
- (SimpleLogEntry *) errorEntryAtIndex:(NSUInteger)index;
- (SimpleLogEntry *) syncEntryAtIndex:(NSUInteger)index;

- (NSString *)getErrorsMessage;
- (NSString *)getPerformanceMessage;
- (NSString *)getSyncMessage;

- (void) logError:(NSError *)error forMethod:(NSString *)method;

- (void) clearPerformance;
- (void) clearSync;
- (void) clearErrors;

@end
