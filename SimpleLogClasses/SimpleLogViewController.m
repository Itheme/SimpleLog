//
//  SimpleLogViewController.m
//

#import "SimpleLogViewController.h"
#import "SimpleLog.h"
#import "LogEntryViewCell.h"
#import <MessageUI/MessageUI.h>

@interface SimpleLogViewController ()<MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) NSDateFormatter *timeFormatter;
@property (nonatomic, strong) MFMailComposeViewController *picker;

@end

@implementation SimpleLogViewController

- (void)loadView
{
    [super loadView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.timeFormatter = [[NSDateFormatter alloc] init];
    [self.timeFormatter setDateFormat:@"h:mm a"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[SimpleErrorLog sharedErrorLog] updateErrosList];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)refreshTable {
    [self.tableView reloadData];

}

- (NSUInteger)recordCountForCurrentMode
{
    switch (self.mode) {
        case SettingsGenericLogMode:
            return [SimpleErrorLog sharedErrorLog].genericRecordCount;
        case SettingsPerformanceLogMode:
            return [SimpleErrorLog sharedErrorLog].performanceRecordCount;
        default:
            return [SimpleErrorLog sharedErrorLog].errorRecordCount;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        NSInteger c = [self recordCountForCurrentMode];
        if (c == 0)
            return 1;
        return c;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SimpleErrorLog *log = [SimpleErrorLog sharedErrorLog];
    NSInteger c = [self recordCountForCurrentMode];
    NSBundle *podBundle = [NSBundle bundleForClass:[SimpleLogViewController class]];//[[NSBundle bundleForClass:[SimpleLogViewController class]] pathForResource:@"SimpleLog" ofType:@"bundle"];
    if (c == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EmptyCell"];
        if (cell == nil) {
            [tableView registerNib:[UINib nibWithNibName:@"EmptyLogEntry" bundle:podBundle]
            forCellReuseIdentifier:@"EmptyCell"];
            cell = [tableView dequeueReusableCellWithIdentifier:@"EmptyCell"];
        }
        return cell;
    } else {
        LogEntryViewCell *cell = (LogEntryViewCell *)[tableView dequeueReusableCellWithIdentifier:@"LogEntryCell"];
        if (cell == nil) {
            [tableView registerNib:[UINib nibWithNibName:@"LogEntry" bundle:podBundle]
            forCellReuseIdentifier:@"LogEntryCell"];
            cell = (LogEntryViewCell *)[tableView dequeueReusableCellWithIdentifier:@"LogEntryCell"];
        }
        SimpleLogEntry *entry;
        switch (self.mode) {
            case SettingsPerformanceLogMode:
                entry = [log performanceEntryAtIndex:indexPath.row];
                break;
            case SettingsGenericLogMode:
                entry = [log genericEntryAtIndex:indexPath.row];
                break;
            default:
                entry = [log errorEntryAtIndex:indexPath.row];
                break;
        }
        cell.dateTimeLabel.text = [self.timeFormatter stringFromDate:entry.time];
        cell.methodLabel.text = [entry.method isKindOfClass:[NSString class]]?entry.method : @"";
        cell.textField.text = [[NSString stringWithFormat:@"%@", entry.error.localizedDescription] stringByReplacingOccurrencesOfString:@"·" withString:@"\n"];
        return cell;
    }
}

- (IBAction)sendEmail:(id)sender {
    if([MFMailComposeViewController canSendMail]){
        self.picker = [[MFMailComposeViewController alloc] init];
        self.picker.mailComposeDelegate = self;
        [self.picker setToRecipients:nil];
        [self.picker setSubject:@"Error logs"];
        switch (self.mode) {
            case SettingsPerformanceLogMode:
                [self.picker setMessageBody:[[SimpleErrorLog sharedErrorLog] getPerformanceMessage] isHTML:YES];
                break;
            case SettingsGenericLogMode:
                [self.picker setMessageBody:[[SimpleErrorLog sharedErrorLog] getGenericMessage] isHTML:YES];
                break;
            default:
                [self.picker setMessageBody:[[SimpleErrorLog sharedErrorLog] getErrorsMessage] isHTML:YES];
                break;
        }
        [self presentViewController:self.picker animated:YES completion:NULL];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:@"Unable to send email" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alertController animated:YES completion:NULL];
    }

}

- (IBAction)clearLogTapped:(id)sender {
    switch (self.mode) {
        case SettingsPerformanceLogMode:
            [[SimpleErrorLog sharedErrorLog] clearPerformance];
            break;
        case SettingsGenericLogMode:
            [[SimpleErrorLog sharedErrorLog] clearGeneric];
            break;
        default:
            [[SimpleErrorLog sharedErrorLog] clearErrors];
            break;
    }
    [self.tableView reloadData];
}


#pragma mark - MFMailComposeViewControllerDelegate
//**********************************************
//MFMailComposeViewControllerDelegate
//**********************************************
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    NSString * message;
    switch (result)
    {
        case MFMailComposeResultCancelled:
            message = @"Sending cancelled";
            break;
        case MFMailComposeResultSaved:
            message = @"Email saved";
            break;
        case MFMailComposeResultSent:
            message = @"Email send";
            break;
        case MFMailComposeResultFailed:
            message = @"Email not sent";
            break;
        default:
            message = @"Email not sent";
            break;
    }
    __weak SimpleLogViewController *weakSelf = self;
    [self.picker dismissViewControllerAnimated:YES completion:^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Log" message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [weakSelf presentViewController:alertController animated:YES completion:NULL];
    }];
}



@end
