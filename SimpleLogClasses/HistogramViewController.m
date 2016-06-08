//
//  HistogramViewController.m
//

#import "HistogramViewController.h"
#import "BarCell.h"
#import "SimpleLog.h"

@interface StatsRecord : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) double time;
@property (nonatomic, assign) double maxTime;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, assign) NSInteger size;
@property (nonatomic, assign) NSInteger maxTimeSize;

- (NSString *)getVolumeByCalcMethod:(NSInteger) methodType;

- (double) valueByCalcMethod:(NSInteger) methodType;
- (id) initWithName:(NSString *) name time:(double) time size:(NSInteger) size;

@end

@interface HistogramViewController () <UITableViewDataSource, UITableViewDelegate>
{
    double maxInterval;
}

@property (nonatomic, strong) NSString *selectedMethod;
@property (nonatomic, strong, getter = getRows) NSMutableArray *rows;

@end

@implementation HistogramViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonTapped:(id)sender {
    if (self.selectedMethod) {
        self.selectedMethod = nil;
        self.segment.hidden = NO;
        self.groupSwitch.enabled = YES;
        _rows = nil;
        [self.titleLabel setText:@"Mean Times of Long Calls"];
        [self.tableView reloadData];
    }
}

- (IBAction)sortTypeSwitched:(id)sender {
    if (self.selectedMethod) return;
    _rows = nil;
    [self.tableView reloadData];
}

- (IBAction)groupSwitchSwitched:(id)sender {
    if (self.selectedMethod) return;
    _rows = nil;
    [self.tableView reloadData];
}

- (NSString *)idlessMethod:(NSString *) method
{
    NSRange idRange = [method rangeOfString:@"\\d+" options:NSRegularExpressionSearch];
    if (idRange.location == NSNotFound) {
        return method;
    }
    return [self idlessMethod:[method stringByReplacingCharactersInRange:idRange withString:@"ID"]];
}

- (NSMutableArray *) getRows
{
    if (_rows == nil) {
        SimpleErrorLog *log = [SimpleErrorLog sharedErrorLog];
        maxInterval = 0;
        BOOL group = self.groupSwitch.on;
        if (self.selectedMethod) {
            _rows = [NSMutableArray array];
            NSString *method = self.selectedMethod;
            if (group) {
                method = [self idlessMethod:method];
            }
            @synchronized (log) {
                for (SimpleLogEntry *entry in log.performanceEntries) {
                    if (entry.latency == nil) continue;
                    if (group) {
                        if (![[self idlessMethod:entry.method] isEqualToString:method]) continue;
                    } else {
                        if (![entry.method isEqualToString:method]) continue;
                    }
                    double time = [entry.latency doubleValue];
                    [_rows addObject:[[StatsRecord alloc] initWithName:entry.method time:time size:[entry.responseSize integerValue]]];
                    if (time > maxInterval) {
                        maxInterval = time;
                    }
                }
            }
        } else {
            NSInteger type = self.segment.selectedSegmentIndex;
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            @synchronized (log) {
                for (SimpleLogEntry *entry in log.performanceEntries) {
                    if (entry.latency == nil) continue;
                    NSString *method = entry.method;
                    if (group) {
                        method = [self idlessMethod:method];
                    }
                    StatsRecord *record = dict[method];
                    if (record) {
                        double time = [entry.latency doubleValue];
                        NSInteger size = [entry.responseSize integerValue];
                        if (time > record.maxTime) {
                            record.maxTime = time;
                            record.maxTimeSize = size;
                        }
                        record.time += time;
                        record.size += size;
                        record.count++;
                    } else {
                        dict[method] = [[StatsRecord alloc] initWithName:method time:[entry.latency doubleValue] size:[entry.responseSize integerValue]];
                    }
                }
            }
            _rows = [[dict.allValues sortedArrayUsingComparator:^NSComparisonResult(StatsRecord *obj1, StatsRecord *obj2) {
                switch (type) {
                    case 0: // mean
                        return obj1.time/obj1.count < obj2.time/obj2.count;
                    case 1: // max
                        return obj1.maxTime < obj2.maxTime;
                    default: // total
                        return obj1.time < obj2.time;
                }
            }] mutableCopy];
            StatsRecord *worst = [_rows firstObject];
            if (worst) {
                if (type == 1) {
                    maxInterval = worst.maxTime;
                } else {
                    maxInterval = worst.time;
                    if (type == 0) {
                        maxInterval /= worst.count;
                    }
                }
            }
        }
        NSString *format;
        double worstCase = maxInterval;
        // let's make numbers lovely
        if (maxInterval >= 120) { // for times > 2 minutes they will be displayed in minutes
            worstCase /= 60.0;
            format = (worstCase >= 10.0)?@"%.0f min":@"%.1f min";
        } else {
            for (double i = 100.0; i > 0.1; i-= 10.0) {
                if (maxInterval >= i) {
                    worstCase = maxInterval = i + 10.0;
                    break;
                }
            }
            if (maxInterval >= 10) {
                format = (maxInterval >= 100)?@"%.1f s":@"%.2f s";
            } else {
                format = @"%.3f s";
            }
        }
        [self.maxTime setText:[NSString stringWithFormat:format, worstCase]];
        [self.midTime setText:[NSString stringWithFormat:format, worstCase / 2]];
    }
    return _rows;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return self.rows.count;
    }
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.rows.count == 0)
        return 0;
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BarCell *cell = (BarCell *)[tableView dequeueReusableCellWithIdentifier:@"BarCell"];
    if (cell == nil) {
        [tableView registerNib:[UINib nibWithNibName:@"BarCellView" bundle:[NSBundle mainBundle]]
        forCellReuseIdentifier:@"BarCell"];
        cell = (BarCell *)[tableView dequeueReusableCellWithIdentifier:@"BarCell"];
    }
    StatsRecord *record = self.rows[indexPath.row];
    double c = record.time;
    NSInteger calcType = self.segment.selectedSegmentIndex;
    if (self.selectedMethod) {
        NSString *title;
        if (c >= 120.0) {
            NSInteger minutes = c / 60;
            title = [NSString stringWithFormat:@"%ld:%.0f", (long)minutes, c - (minutes * 60)];
        } else {
            title = [NSString stringWithFormat:(maxInterval >= 10)?((maxInterval >= 100)?@"%.1f s (%@)":@"%.2f s (%@)"):@"%.3f s (%@)", c, [record getVolumeByCalcMethod:calcType]];
        }
        if (record.name) {
            [cell.label setText:[NSString stringWithFormat:@"%@    %@ (%@)", title, record.name, [record getVolumeByCalcMethod:calcType]]];
        } else {
            [cell.label setText:title];
        }
    } else {
        [cell.label setText:[NSString stringWithFormat:@"%@ (%@)", record.name, [record getVolumeByCalcMethod:calcType]]];
    }
    switch (calcType) {
        case 0:
            c /= record.count;
            break;
        case 1:
            c = record.maxTime;
            break;
        default:
            break;
    }
    if ((maxInterval > 0.01) && (c > 0.01)) {
        [cell.barWidth setConstant:(cell.contentView.bounds.size.width - 16)*c/maxInterval];
    } else {
        [cell.barWidth setConstant:0];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 30.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.selectedMethod) {
        return;
    }
    StatsRecord *record = self.rows[indexPath.row];
    self.selectedMethod = record.name;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_rows removeAllObjects];
        [UIView animateWithDuration:0.5
                         animations:^{
                             [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
                         } completion:^(BOOL finished) {
                             [self.titleLabel setText:[NSString stringWithFormat:@"Call Times for %@", record.name]];
                             _rows = nil;
                             self.segment.hidden = YES;
                             self.groupSwitch.enabled = NO;
                             if (finished && (self.rows.count > 0)) {
                                 [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
                             } else {
                                 [self.tableView reloadData];
                             }
                         }];
    });
}
     
@end

@implementation StatsRecord

- (id) initWithName:(NSString *) name time:(double)time size:(NSInteger) size {
    if (self = [super init]) {
        self.name = name;
        self.time = time;
        self.size = self.maxTimeSize = size;
        self.maxTime = time;
        self.count = 1;
    }
    return self;
}

- (double) valueByCalcMethod:(NSInteger) methodType
{
    switch (methodType) {
        case 0: // mean
            return _time/_count;
        case 1: // max
            return _maxTime;
        default: // total
            return _time;
    }
}
         
- (NSString *)getVolumeByCalcMethod:(NSInteger) methodType
{
    double size = _size;
    if (methodType == 1) {
        size = _maxTimeSize;
    } else {
        if (methodType == 0) {
            size /= _count;
        }
    }
    if (self.size) {
        if (size >= (2 << 20)) {
            return [NSString stringWithFormat:@"%.1fMb", size/1024.0/1024.0];
        }
        return [NSString stringWithFormat:@"%.1fkb", size/1024.0];
    }
    return @"unknown volume";
}

@end