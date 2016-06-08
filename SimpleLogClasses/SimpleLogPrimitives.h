//
//  SimpleLogPrimitives.h
//  SimpleLog
//
//  Created by Danila Parkhomenko on 08/06/16.
//  Copyright © 2016 Itheme. All rights reserved.
//

#ifndef SimpleLogPrimitives_h
#define SimpleLogPrimitives_h

#define UNNIL(A) (A)?(A):([NSNull null])
#define LogCapacity 400
static NSString *SimpleLogUpdatedNotification = @"SimpleLogUpdatedNotification";

#define SIMPLELOG_ERROR_CODE_PERFORMANCE_RECORD -266537017
#define SIMPLELOG_ERROR_CODE_SYNC_RECORD -266537018

#endif /* SimpleLogPrimitives_h */
