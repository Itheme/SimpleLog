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

static NSString *BOOKERUI_LogUpdated;

@interface BookerLogEntry : NSObject
@property (nonatomic, readonly) NSDate *time;
@property (nonatomic, readonly) NSString *method;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, readonly) NSDecimalNumber *latency;
@property (nonatomic, readonly) NSNumber *responseSize;
@end

@interface BookerErrorLog : NSObject

@property (nonatomic, readonly, getter = getPerformanceRecordCount) NSUInteger performanceRecordCount;
@property (nonatomic, readonly, getter = getErrorRecordCount) NSUInteger errorRecordCount;
@property (nonatomic, readonly, getter = getSyncRecordCount) NSUInteger syncRecordCount;
@property (nonatomic, readonly, strong) NSMutableArray *performanceEntries; // access only in sync with error log

+ (BookerErrorLog *) sharedErrorLog;

- (void)updateErrosList;

- (BookerLogEntry *) performanceEntryAtIndex:(NSUInteger)index;
- (BookerLogEntry *) errorEntryAtIndex:(NSUInteger)index;
- (BookerLogEntry *) syncEntryAtIndex:(NSUInteger)index;

- (NSString *)getErrorsMessage;
- (NSString *)getPerformanceMessage;
- (NSString *)getSyncMessage;

- (void) logError:(NSError *)error forMethod:(NSString *)method;

- (void) clearPerformance;
- (void) clearSync;
- (void) clearErrors;

@end
