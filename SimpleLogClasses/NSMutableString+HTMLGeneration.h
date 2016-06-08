//
//  NSString+HTMLGeneration.h
//

#import <Foundation/Foundation.h>

typedef NSString *(^TableContentsGenerationBlock)(NSInteger row, BOOL *tableDone);
typedef NSString *(^RowContentsGenerationBlock)(NSInteger column, NSMutableDictionary *cellParams);

@interface NSString (HTMLGeneration)

+ (NSMutableString *)htmlTableWithParameters:(NSDictionary *) parameters contentsBlock:(TableContentsGenerationBlock) contentsBlock;
+ (NSMutableString *)htmlTableWithParameters:(NSDictionary *) parameters contents:(NSString *) contents;
+ (NSMutableString *)htmlTableRowWithParameters:(NSDictionary *) parameters contents:(RowContentsGenerationBlock) contentsBlock;
+ (NSMutableString *)htmlTableSingleColumnRowWithContents:(RowContentsGenerationBlock) contentsBlock;

@end
