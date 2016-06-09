//
//  TestableCategories.h
//  SimpleLog
//
//  Created by Danila Parkhomenko on 09/06/16.
//  Copyright © 2016 Itheme. All rights reserved.
//

#ifndef TestableCategories_h
#define TestableCategories_h

#import "SimpleLog.h"

@interface SimpleLogEntry (Testing)

- (NSString *)convertLogEntryToString;
+ (SimpleLogEntry *)logEntryFromString:(NSString *)content;

@end

#endif /* TestableCategories_h */
