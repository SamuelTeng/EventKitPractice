//
//  main.m
//  EventKitPractice
//
//  Created by Samuel Teng on 13/1/23.
//  Copyright (c) 2013年 Samuel Teng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice]systemVersion]compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface MainViewController:UITableViewController<UITableViewDelegate,UITableViewDataSource,
UINavigationBarDelegate,EKEventEditViewDelegate,UINavigationControllerDelegate,
UIActionSheetDelegate,UIAlertViewDelegate>
{
//    EKEventViewController *detailViewController;
//    EKEventStore *eventStore;
//    EKCalendar *defaultCalendar;
//    NSMutableArray *eventsList;
}
/*I used retain first as the sample code but retain is for MRR, and i'm using ARC. Hence, it keeps show the NSMatchError message. Although it doesn't cause app crash, it could trigger future problem. The solution is either use local variable, declared within interface, or replsed retain by strong*/
@property (nonatomic,strong) EKEventViewController *detailViewController;
@property (nonatomic,strong) EKEventStore *eventStore;
@property (nonatomic,strong) EKCalendar *defaultCalendar;
@property (nonatomic,strong) NSMutableArray *eventsList;

-(NSArray *)fetchEventsForToday;
@end

@implementation MainViewController

@synthesize detailViewController,eventsList,defaultCalendar;



-(void)loadView
{
    [super loadView];
    self.view.backgroundColor=[UIColor whiteColor];
    self.navigationItem.title=@"Events List";
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewEvent:)];
    /*experiment in open .ics file*/
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(subscribe:)];
    self.navigationController.delegate=self;
    self.tableView.delegate=self;
    self.tableView.dataSource=self;
    self.eventStore=[[EKEventStore alloc] init];
    [self authorization];
    /*
    //if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    if([self.eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)])
    {
        [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            if (granted) {
                
                
                
                self.eventsList=[[NSMutableArray alloc]initWithArray:0];
                
//                self.defaultCalendar=[self.eventStore defaultCalendarForNewEvents];
//                NSLog(@"event store details:%@", self.defaultCalendar.description);
                
               
                
                //self.defaultCalendar=[self.eventStore defaultCalendarForNewEvents];
                [self.eventsList addObjectsFromArray:[self fetchEventsForToday]];
                
                NSLog(@"defaultCalendar's identifier: %@", defaultCalendar.calendarIdentifier);
                
                [self.tableView reloadData];
            }else{
                NSLog(@"Denial");
            }
        }];
        
    }else{
        self.eventsList=[[NSMutableArray alloc]initWithArray:0];
        
        self.defaultCalendar=[self.eventStore defaultCalendarForNewEvents];
        
        [self.eventsList addObjectsFromArray:[self fetchEventsForToday]];
        
        [self.tableView reloadData];
    }*/
    
}

-(void)viewDidUnload
{
    self.eventsList=nil;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:NO];
   
}

-(void)authorization
{
    EKEventStore *eventStroe = [[EKEventStore alloc] init];
    
    switch ([EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent]){
            
        case EKAuthorizationStatusAuthorized:{
            [self subscribeCalendar];
            break;
        }
        case EKAuthorizationStatusDenied:{
            
            NSLog(@"Access denied");
            break;
        }
        case EKAuthorizationStatusNotDetermined:{
            
            [eventStroe requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
                if (granted) {
                    [self subscribeCalendar];
                }else{
                    NSLog(@"Access denied");
                }
            }];
            break;
        }
        case EKAuthorizationStatusRestricted:{
            NSLog(@"Access restriceted");
            break;
        }
    }
}

-(EKSource *)sourceInEventStore:(EKEventStore *)paramEventStore sourceType:(EKSourceType)paramType souceTitle:(NSString *)paramSoucrTitle
{
    for (EKSource *source in paramEventStore.sources) {
        if (source.sourceType == paramType && [source.title caseInsensitiveCompare:paramSoucrTitle]== NSOrderedSame) {
            return source;
        }
    }
    return nil;
}

-(EKCalendar *)calendarWithTitle:(NSString *)title
                            type:(EKCalendarType)paramType
                        inSource:(EKSource *)paramSource
                    forEventType:(EKEntityType)paramEntityType
{
    for (EKCalendar *calendar in [paramSource calendarsForEntityType:paramEntityType]) {
        if ([calendar.title caseInsensitiveCompare:title] == NSOrderedSame && calendar.type == paramType) {
            return calendar;
        }
    }
    return nil;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark -
#pragma mark Table view data source

// Fetching events happening in the next 24 hours with a predicate, limiting to the default calendar

-(NSArray *)fetchEventsForToday
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    
    // EKSource *iCloudSource = [self sourceInEventStore:eventStore sourceType:EKSourceTypeCalDAV souceTitle:@"iCloud"];
    EKSource *subscribedSource = [self sourceInEventStore:eventStore sourceType:EKSourceTypeSubscribed souceTitle:@"Subscribed Calendars"];
    
    //    if (iCloudSource == nil) {
    //        NSLog(@"you have not configured iCloud in your device");
    //        return;
    //    }
    
    if (subscribedSource == nil) {
        NSLog(@"unable to find subscribed calendar as source");
        
    }
    
    //EKCalendar *calendar = [self calendarWithTitle:@"Calendar" type:EKCalendarTypeCalDAV inSource:iCloudSource forEventType:EKEntityTypeEvent];
    EKCalendar *calendar = [self calendarWithTitle:@"台中潛水" type:EKCalendarTypeSubscription inSource:subscribedSource forEventType:EKEntityTypeEvent];
    
    if (calendar == nil) {
        NSLog(@"Could not find the calendar we are looking for");
        
    }
    
    defaultCalendar = calendar;
    
    NSDate *startDate=[NSDate date];
    
    NSDate *endDate=[NSDate dateWithTimeIntervalSinceNow:31622400];
    
    NSArray *calendarArray=[NSArray arrayWithObject:defaultCalendar];
    NSPredicate *predicate=[self.eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:calendarArray];
    
    NSArray *events=[self.eventStore eventsMatchingPredicate:predicate];
        return events;
}

-(void)displayMessage:(NSString *)paramMessage
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:paramMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
    [alertView show];
}

-(void)subscribeCalendar
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    
    EKSource *subscribedSource = [self sourceInEventStore:eventStore sourceType:EKSourceTypeSubscribed souceTitle:@"Subscribed Calendars"];
    
    if (subscribedSource == nil) {
        NSLog(@"unable to find subscribed calendar as source");
        [self displayMessage:@"Click 'Edit' to subscribe the schedule"];
        return;
    }
    
    EKCalendar *calendar = [self calendarWithTitle:@"台中潛水" type:EKCalendarTypeSubscription inSource:subscribedSource forEventType:EKEntityTypeEvent];
    
    if (calendar == nil) {
        NSLog(@"Could not find the calendar we are looking for");
        [self displayMessage:@"Click 'Edit' to subscribe the schedule"];
        return;
    }else{
        self.eventsList=[[NSMutableArray alloc]initWithArray:0];
        
        [self.eventsList addObjectsFromArray:[self fetchEventsForToday]];
        
        [self.tableView reloadData];
    }
}

#pragma mark -
#pragma mark Table View

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"count of event list: %lu ", (unsigned long)self.eventsList.count);
    return self.eventsList.count;
}

//UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier=@"Cell";
    
    // Add disclosure triangle to cell
    UITableViewCellAccessoryType editableAccessoryType=
    UITableViewCellAccessoryDisclosureIndicator;
    
    UITableViewCell *cell=[self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell==nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }
        cell.accessoryType = editableAccessoryType;
        
        // Get the event at the row selected and display it's title
        cell.textLabel.text=[[self.eventsList objectAtIndex:indexPath.row] title];
    
    
        //cell.detailTextLabel.text=[[self.eventsList objectAtIndex:indexPath.row]location];
    
    
        return cell;

    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*The method permits the delegate to exclude individual rows from being treated as editable*/
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
     NSError *error = nil;
    /*swipe-to-delete*/
    self.detailViewController = [[EKEventViewController alloc] initWithNibName:nil bundle:nil];
    
    detailViewController.event = [self.eventsList objectAtIndex:indexPath.row];
    
    detailViewController.allowsEditing=YES;
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.eventsList removeObject: self.detailViewController.event];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    }
    [self.eventStore removeEvent:self.detailViewController.event span:EKSpanThisEvent error:&error];
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Upon selecting an event, create an EKEventViewController to display the event.
    self.detailViewController = [[EKEventViewController alloc] initWithNibName:nil bundle:nil];
    
    detailViewController.event = [self.eventsList objectAtIndex:indexPath.row];
    
    // Allow event editing.
    detailViewController.allowsEditing=YES;
    
    //	Push detailViewController onto the navigation controller stack
	//	If the underlying event gets deleted, detailViewController will remove itself from
	//	the stack and clear its event property.
    
    
    [self.navigationController pushViewController:detailViewController animated:YES];
    
}


#pragma mark -
#pragma mark Navigation Controller delegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    // if we are navigating back to the rootViewController, and the detailViewController's event
	// has been deleted -  will title being NULL, then remove the events from the eventsList
	// and reload the table view. This takes care of reloading the table view after adding an event too.
    
    
    if (viewController == self && self.detailViewController.event.title == NULL) {
        
        [self.eventsList removeObject:self.detailViewController.event];
        

        [self.tableView reloadData];
    }
}

#pragma mark -
#pragma mark Add a new event

// If event is nil, a new event is created and added to the specified event store. New events are
// added to the default calendar. An exception is raised if set to an event that is not in the
// specified event store.
-(void)addNewEvent:(id)sender
{
    // When add button is pushed, create an EKEventEditViewController to display the event.
    EKEventEditViewController *addController = [[EKEventEditViewController alloc] initWithNibName:nil bundle:nil];
    
    // set the addController's event store to the current event store.
    addController.eventStore = self.eventStore;
    
    // present EventsAddViewController as a modal view controller
    //[self presentModalViewController:addController animated:YES];
    /*the original method is deprecated in iOS6 and replaced by the method implemented below*/
    [self presentViewController:addController animated:YES completion:nil];
    
    addController.editViewDelegate=self;
}
/*experiment in open .ics file*/
-(void)subscribe:(id)sender
{
    NSURL *icsPath = [NSURL URLWithString:@"https://www.google.com/calendar/ical/ntd.club%40gmail.com/public/basic.ics"];
    [[UIApplication sharedApplication] openURL:icsPath];
    
}

#pragma mark -
#pragma mark EKEventEditViewDelegate
- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action
{
    NSError *error = nil;
    EKEvent *thisEvent = controller.event;
    //NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    
    switch (action) {
        case EKEventEditViewActionCanceled:
            // Edit action canceled, do nothing.
            break;
        case EKEventEditViewActionSaved:
            // When user hit "Done" button, save the newly created event to the event store,
			// and reload table view.
			// If the new event is being added to the default calendar, then update its
			// eventsList.
            if (self.defaultCalendar == thisEvent.calendar) {
                [self.eventsList addObject:thisEvent];
            }
            
            [controller.eventStore saveEvent:controller.event span:EKSpanThisEvent error:&error];
            [self.tableView reloadData];
            break;
        case EKEventEditViewActionDeleted:
            // When deleting an event, remove the event from the event store,
			// and reload table view.
			// If deleting an event from the currenly default calendar, then update its
			// eventsList.
            if (self.defaultCalendar == thisEvent.calendar) {
                [self.eventsList removeObject:thisEvent];
            }
            
            [controller.eventStore removeEvent:controller.event span:EKSpanThisEvent error:&error];
//            [self.tableView beginUpdates];
//            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
//            [self.tableView endUpdates];
            [self.tableView reloadData];
            break;
        default:
            break;
    }
    
    // Dismiss the modal view controller
    //[controller dismissModalViewControllerAnimated:YES];
    /*the original method is deprecated in iOS6 and replaced by the method implemented below*/
    [controller dismissViewControllerAnimated:YES completion:nil];
}

// Set the calendar edited by EKEventEditViewController to our chosen calendar - the default calendar.
- (EKCalendar *)eventEditViewControllerDefaultCalendarForNewEvents:(EKEventEditViewController *)controller
{
    
    EKCalendar *calendarForEdit = self.defaultCalendar;
    
    return calendarForEdit;
}


@end


@interface AppDelegate : UIResponder<UIApplicationDelegate>
@property(nonatomic,strong)UIWindow *window;
@property(nonatomic,strong)UINavigationController *navi;
@property(nonatomic,strong)MainViewController *mainViewController;
@end

@implementation AppDelegate
@synthesize window;
@synthesize mainViewController;
@synthesize navi;
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window=[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen]bounds]];
    self.mainViewController=[[MainViewController alloc] init];
    self.navi=[[UINavigationController alloc]initWithRootViewController:mainViewController];
    self.window.rootViewController=navi;
    [self.window makeKeyAndVisible];
    
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"app will resign active");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"app did enter background");
    //[mainViewController refreshControl];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"app will enter foreground");
    
}

@end

int main(int argc, char *argv[])
{
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
