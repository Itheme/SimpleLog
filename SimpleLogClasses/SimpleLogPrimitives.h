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
static NSString *jsonBreakerString = @":::";

#define SIMPLELOG_ERROR_CODE_PERFORMANCE_RECORD -266537017
#define SIMPLELOG_ERROR_CODE_GENERIC_RECORD -266537018
#define SIMPLELOG_ERROR_DOMAIN @"SimpleLogDomain"
#endif /* SimpleLogPrimitives_h */
