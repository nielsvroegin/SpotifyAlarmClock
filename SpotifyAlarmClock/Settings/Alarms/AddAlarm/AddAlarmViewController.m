//
//  AddAlarmViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 16-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "AppDelegate.h"
#import "Alarm.h"
#import "AddAlarmViewController.h"
#import "OptionsSelectViewController.h"
#import "TextEditViewController.h"
#import "Option.h"

#define kRepeat 0
#define kSongs 1
#define kSnooze 2
#define kLabel 3

@interface AddAlarmViewController ()

@property (nonatomic, strong) NSArray * repeatOptions;
@property (nonatomic, strong) NSString * label;
@property (weak, nonatomic) IBOutlet UISwitch *snoozeSwitch;
@property (weak, nonatomic) IBOutlet UIDatePicker *timePicker;

- (BOOL) isOptionSelected:(NSUInteger)index;
- (NSString *) repeatOptionsText;
- (void) setSelectedRepeatOptionsToCellText;
- (NSString *)repeatOptionsToString:(NSArray *)rpOptions;
- (NSArray *)repeatOptionsFromString:(NSString *)rpOptions;

@end

@implementation AddAlarmViewController
@synthesize repeatOptions;
@synthesize label;
@synthesize snoozeSwitch;
@synthesize timePicker;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    self.repeatOptions = [NSArray arrayWithObjects: [[Option alloc] initWithLabel:@"Every Monday" abbreviate:@"Mon" selected:FALSE],
                            [[Option alloc] initWithLabel:@"Every Tuesday" abbreviate:@"Tue" selected:FALSE],
                            [[Option alloc] initWithLabel:@"Every Wednesday" abbreviate:@"Wed" selected:FALSE],
                            [[Option alloc] initWithLabel:@"Every Thursday" abbreviate:@"Thu" selected:FALSE],
                            [[Option alloc] initWithLabel:@"Every Friday" abbreviate:@"Fri" selected:FALSE],
                            [[Option alloc] initWithLabel:@"Every Saturday" abbreviate:@"Sat" selected:FALSE],
                            [[Option alloc] initWithLabel:@"Every Sunday" abbreviate:@"Sun" selected:FALSE], nil];
    
    self.label = @"Alarm";
    
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)SaveAlarm
{
    /****** Get refs to Managed object context ******/
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSError *error;
    
    /****** Create new object if managed object not exists ******/
    if(self.alarmData == nil)
        self.alarmData = [NSEntityDescription insertNewObjectForEntityForName:@"Alarm" inManagedObjectContext:context];
    
    /****** Set new values ******/
    [self.alarmData setName:self.label];
    [self.alarmData setRepeat:[self repeatOptionsToString:self.repeatOptions]];
    [self.alarmData setEnabled:[NSNumber numberWithBool:NO]];
    [self.alarmData setSnooze:[NSNumber numberWithBool:[self.snoozeSwitch isOn]]];
    [self.alarmData setAlarmTime:[self.timePicker date]];
   
    /****** Save alarmData object ******/
    if(![context save:&error])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not save Alarm!" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil];
        [alert show];
        
        NSLog(@"Context save error: %@", error);
    }
}

- (NSString *)repeatOptionsToString:(NSArray *)rpOptions
{
    NSString *repeatValue = @"";
    for(int i = 0; i < [rpOptions count]; i++)
        if([rpOptions[i] selected])
            repeatValue = [repeatValue stringByAppendingFormat:@"%d,", i];
    
    if([repeatValue length] > 0)
        repeatValue = [repeatValue substringToIndex:([repeatValue length]-1)];
    
    return repeatValue;
}

- (NSArray *)repeatOptionsFromString:(NSString *)rpOptions
{
    return nil;
}

#pragma mark - OptionsSelect delegate
- (void)optionValueChanged:(Option *) option
{
    [self setSelectedRepeatOptionsToCellText];
}

- (NSString *) repeatOptionsText
{
    NSString *repeatOptionsText = @"";
    
    //Create text
    if(![self isOptionSelected:0] && ![self isOptionSelected:1] && ![self isOptionSelected:2] && ![self isOptionSelected:3] && ![self isOptionSelected:4] && ![self isOptionSelected:5] && ![self isOptionSelected:6])
        repeatOptionsText = @"Never";
    if([self isOptionSelected:0] && [self isOptionSelected:1] && [self isOptionSelected:2] && [self isOptionSelected:3] && [self isOptionSelected:4] && [self isOptionSelected:5] && [self isOptionSelected:6])
        repeatOptionsText = @"Every day";
    else if([self isOptionSelected:0] && [self isOptionSelected:1] && [self isOptionSelected:2] && [self isOptionSelected:3] && [self isOptionSelected:4] && ![self isOptionSelected:5] && ![self isOptionSelected:6])
        repeatOptionsText = @"Weekdays";
    else if(![self isOptionSelected:0] && ![self isOptionSelected:1] && ![self isOptionSelected:2] && ![self isOptionSelected:3] && ![self isOptionSelected:4] && [self isOptionSelected:5] && [self isOptionSelected:6])
        repeatOptionsText = @"Weekends";
    else
        for(NSUInteger i = 0; i < [self.repeatOptions count]; i++)
            if([self isOptionSelected:i])
                repeatOptionsText = [repeatOptionsText stringByAppendingFormat:@" %@", [[self.repeatOptions objectAtIndex:i] abbreviate]];
    
    return repeatOptionsText;
}

- (BOOL) isOptionSelected:(NSUInteger)index
{
    Option * option = [self.repeatOptions objectAtIndex:index];
    return  option.selected;
}

- (void) setSelectedRepeatOptionsToCellText
{
    UITableViewCell *repeatCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kRepeat inSection:0]];
    repeatCell.detailTextLabel.text = [self repeatOptionsText];
}

#pragma mark - TextEdit delegate
- (void) textEditChanged:(TextEditViewController *)textEdit value:(NSString *)newValue
{
    UITableViewCell *labelCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kLabel inSection:0]];
    self.label = newValue;
    labelCell.detailTextLabel.text = [self label];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"repeatOptionsSelect"])
    {
        OptionsSelectViewController* vw = [segue destinationViewController];
        [vw setTitle:@"Repeat"];
        [vw setDelegate:self];
        [vw setOptions:[self repeatOptions]];
    }
    else if([[segue identifier] isEqualToString:@"labelTextEdit"])
    {
        TextEditViewController* vw = [segue destinationViewController];
        [vw setTitle:@"Label"];
        [vw setDelegate:self];
        [vw setText:[self label]];
    }
    else if([[segue identifier] isEqualToString:@"saveAlarm"])
    {
        [self SaveAlarm];
    }
}
@end
