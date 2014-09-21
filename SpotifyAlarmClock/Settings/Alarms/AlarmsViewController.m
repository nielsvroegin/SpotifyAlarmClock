//
//  AlarmsViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 14-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "AlarmsViewController.h"
#import "AddAlarmViewController.h"
#import "AppDelegate.h"
#import "AlarmCell.h"
#import "Alarm.h"

@interface AlarmsViewController ()

@property (nonatomic, strong) NSMutableArray *alarms;
- (IBAction)EditAlarms:(id)sender;
- (IBAction)enabledSwitchChanged:(id)sender;
@end

@implementation AlarmsViewController
@synthesize alarms;

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
    [self loadAlarms];
    
    [super viewDidLoad];
}

- (void)loadAlarms
{
    /****** Get refs to core date requirements ******/
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Alarm" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSError *error;
    
    /****** Fetch alarms ******/
    [request setEntity:entityDescription];
    self.alarms = [NSMutableArray arrayWithArray:[context executeFetchRequest:request error:&error]];
    
    if(self.alarms == nil)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not load Alarms!" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil];
        [alert show];
        
        NSLog(@"Context fetch error: %@", error);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)unwindToAlarms:(UIStoryboardSegue *)unwindSegue
{
    if([[unwindSegue identifier] isEqualToString:@"saveAlarm"])
    {
        AddAlarmViewController *vw = [unwindSegue sourceViewController];
        if(![self.alarms containsObject:vw.alarmData])
        {
            [self.alarms addObject:vw.alarmData];
        }
        
        if(self.tableView.editing)
            [self EditAlarms:nil];
        [self.tableView reloadData];
    }
}

- (IBAction)enabledSwitchChanged:(id)sender
{
    //Get context
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSError *error;
    
    //Find switch and alarm object
    UISwitch *sw = (UISwitch *)sender;
    //Find corresponding AlarmCell
    UIView *view = sw;
    while (view != nil && ![view isKindOfClass:[AlarmCell class]]) {
        view = [view superview];
    }
    AlarmCell *alarmCell = (AlarmCell *)view;
    
    Alarm *alarm = [self.alarms objectAtIndex:[[self.tableView indexPathForCell:alarmCell] row]] ;
    [alarm setEnabled:[NSNumber numberWithBool:[sw isOn]]];
    
    //Save alarm
    if(![context save:&error])
    {
        [sw setOn:!sw.on];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not save alarm switch!" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil];
        [alert show];
        
        NSLog(@"Context save error: %@", error);
    }
}

- (IBAction)EditAlarms:(id)sender
{
    CGFloat visible = 0.0f;

    if(self.tableView.editing == NO)
    {
        self.navigationItem.rightBarButtonItem.title = @"Done";
        visible = 0.0f;
        [self.tableView setEditing:YES animated:YES];
        
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[self.alarms count] inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
    else
    {
        self.navigationItem.rightBarButtonItem.title = @"Edit";
        visible = 1.0f;
        [self.tableView setEditing:NO animated:YES];
        
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[self.alarms count] inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
    
    
    
    
    //Show/Hide switches
    [UIView animateWithDuration:0.3
                     animations:^ {
                         for (NSInteger i = 0; i < [self.alarms count]; i++) {
                             AlarmCell *alarmCell = (AlarmCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                             alarmCell.swAlarmEnabled.alpha = visible;
                         }
                     }
     ];

}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //No action for AddAlarmCell necessary, handled by segue
    if(indexPath.row >= [self.alarms count])
        return;
    
    
    if(tableView.editing && indexPath.row < [self.alarms count])
    {
        [self performSegueWithIdentifier:@"editAlarm" sender:[tableView cellForRowAtIndexPath:indexPath]];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(!tableView.editing && indexPath.row < [self.alarms count])
        return NO;
    else
        return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row < [self.alarms count])
        return 90;
    else
        return 45;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.5;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row < [self.alarms count])
        return UITableViewCellEditingStyleDelete;
    else
        return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row < [self.alarms count])
        return YES;
    else
        return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Load context
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSError *error;
    
    //Remove selected object
    [context deleteObject:[self.alarms objectAtIndex:[indexPath row]]];
    
    //Save context
    if(![context save:&error])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not load Alarms!" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil];
        [alert show];
        
        NSLog(@"Context save error: %@", error);
    }
    [self.alarms removeObjectAtIndex:[indexPath row]];
    
    //Animate table with change
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView.editing)
        return [self.alarms count];
    else
        return [self.alarms count] + 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Return AddAlarm cell when on last cell
    if(indexPath.row == [self.alarms count])
        return [tableView dequeueReusableCellWithIdentifier:@"AddAlarmCell" forIndexPath:indexPath];
    
    //Return alarm cell
    AlarmCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AlarmCell" forIndexPath:indexPath];
    Alarm *alarm = [self.alarms objectAtIndex:[indexPath row]];
   
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"HH:mm"];
    
    [cell.lbLabel setText:alarm.Name];
    [cell.lbTime setText:[format stringFromDate:alarm.AlarmTime]];
    [cell.swAlarmEnabled setOn:[alarm.Enabled boolValue]];
    [cell.swAlarmEnabled setAlpha:1.0f];
    
    return cell;
}

#pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"editAlarm"])
    {
        NSIndexPath* indexPath = [self.tableView indexPathForCell:(AlarmCell*) sender];
        AddAlarmViewController *vw = (AddAlarmViewController *)[[segue destinationViewController] topViewController];
        Alarm* alarm = [self.alarms objectAtIndex:[indexPath row]];

        [vw setAlarmData:alarm];
    }
}

@end
