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

@interface AddAlarmViewController ()

@property (nonatomic, strong) NSArray * repeatOptions;
@property (weak, nonatomic) IBOutlet UILabel * lbRepeat;
@property (weak, nonatomic) IBOutlet UILabel * lbLabel;
@property (weak, nonatomic) IBOutlet UISwitch *snoozeSwitch;
@property (weak, nonatomic) IBOutlet UIDatePicker *timePicker;

- (BOOL) isOptionSelected:(NSUInteger)index;
- (NSString *) repeatOptionsText;
- (NSString *)repeatOptionsToString;
- (void)repeatOptionsFromString:(NSString *)rpOptions;

@end

@implementation AddAlarmViewController
@synthesize repeatOptions;
@synthesize lbLabel;
@synthesize lbRepeat;
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
    
    if(self.alarmData != nil)
    {
        [self repeatOptionsFromString:[self.alarmData Repeat]];
        [self.lbRepeat setText:[self repeatOptionsText]];
        [self.lbLabel setText:[self.alarmData Name]];
        [self.snoozeSwitch setOn:[[self.alarmData Snooze] boolValue]];
        [self.timePicker setDate:[self.alarmData AlarmTime]];
    }
    
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
    [self.alarmData setName:[self.lbLabel text]];
    [self.alarmData setRepeat:[self repeatOptionsToString]];
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

- (NSString *)repeatOptionsToString
{
    NSString *repeatValue = @"";
    for(int i = 0; i < [self.repeatOptions count]; i++)
        if([self.repeatOptions[i] selected])
            repeatValue = [repeatValue stringByAppendingFormat:@"%d,", i];
    
    if([repeatValue length] > 0)
        repeatValue = [repeatValue substringToIndex:([repeatValue length]-1)];
    
    return repeatValue;
}

- (void)repeatOptionsFromString:(NSString *)rpOptions
{
    for(int i = 0; i < [self.repeatOptions count]; i++)
    {
        if(self.alarmData != nil && [[self.alarmData Repeat] rangeOfString:[NSString stringWithFormat:@"%d", i]].location != NSNotFound )
            [[self.repeatOptions objectAtIndex:i] setSelected:YES];
        else
            [[self.repeatOptions objectAtIndex:i] setSelected:NO];
    }
}

#pragma mark - OptionsSelect delegate
- (void)optionValueChanged:(Option *) option
{
    [self.lbRepeat setText:[self repeatOptionsText]];
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

#pragma mark - TextEdit delegate
- (void) textEditChanged:(TextEditViewController *)textEdit value:(NSString *)newValue
{
    [self.lbLabel setText:newValue];
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
        [vw setText:[self.lbLabel text]];
    }
    else if([[segue identifier] isEqualToString:@"saveAlarm"])
    {
        [self SaveAlarm];
    }
}
@end
