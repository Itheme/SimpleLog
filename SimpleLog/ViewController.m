//
//  ViewController.m
//  SimpleLog
//
//  Created by Danila Parkhomenko on 08/06/16.
//  Copyright © 2016 Itheme. All rights reserved.
//

#import "ViewController.h"
#import "SimpleLog.h"
#import "HistogramViewController.h"
#import "SimpleLogViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    SimpleLogViewController *vc = [[SimpleLogViewController alloc] init];
//    [self presentViewController:vc
//                       animated:YES
//                     completion:^{
//                        // <#code#>
//                     }];
//    
    [[SimpleErrorLog sharedErrorLog] logLatency:[NSDecimalNumber decimalNumberWithMantissa:1 exponent:0 isNegative:NO] description:@"desc 1" size:@(2) forMethod:@"method"];
    [[SimpleErrorLog sharedErrorLog] logLatency:[NSDecimalNumber decimalNumberWithMantissa:2 exponent:0 isNegative:NO] description:@"desc 1" size:@(2) forMethod:@"method"];
    [[SimpleErrorLog sharedErrorLog] logLatency:[NSDecimalNumber decimalNumberWithMantissa:3 exponent:0 isNegative:NO] description:@"desc 1" size:@(4) forMethod:@"method"];
    [[SimpleErrorLog sharedErrorLog] logLatency:[NSDecimalNumber decimalNumberWithMantissa:4 exponent:0 isNegative:NO] description:@"desc 1" size:@(4) forMethod:@"method"];
    [[SimpleErrorLog sharedErrorLog] updateErrosList];

//    UINib *nib = [UINib nibWithNibName:@"HistogramView" bundle:nil];
//    [nib instantiateWithOwner:self.view options:nil];
    
    //HistogramViewController *vc = [[HistogramViewController alloc] initWithNibName:@"HistogramView" bundle:[NSBundle mainBundle]];
    HistogramViewController *vc = [[HistogramViewController alloc] init];
    [self presentViewController:vc animated:YES completion:^{
       // <#code#>
    }];
}

@end
