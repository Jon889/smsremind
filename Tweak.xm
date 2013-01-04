#define ivar(object, name) name; object_getInstanceVariable(object, "_"#name, (void**)&name);
#import <EventKit/EventKit.h>

@interface CKMessageCell : NSObject
-(void)balloonViewDidTapRemind:(id)arg1;
-(void)__performTargetAction:(SEL)arg1;
@end
%hook CKBalloonView

-(void)_showCopyCallout {
    %orig;
    NSMutableArray *menuItems = [NSMutableArray arrayWithArray:[[UIMenuController sharedMenuController] menuItems]];
    UIMenuItem *mitem = [[UIMenuItem alloc] initWithTitle:@"Remind" action:@selector(remind:)];
    [menuItems addObject:mitem];
    [mitem release];
    [[UIMenuController sharedMenuController] setMenuItems:menuItems];
    [[UIMenuController sharedMenuController] update];
    [[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
}

%new
-(void)remind:(id)sender {
    id ivar(self, actionDelegate);
    if ([actionDelegate respondsToSelector:@selector(balloonViewDidTapRemind:)]) {
        [actionDelegate balloonViewDidTapRemind:self];
    }
}

%end

%hook CKMessageCell
%new
-(void)balloonViewDidTapRemind:(id)arg1 {
    [self __performTargetAction:@selector(messageCellTappedRemind)];
}
%end

@interface EKReminder ()
-(void)setAction:(id)arg1;
@end

@interface CKTranscriptController : UIViewController <UIActionSheetDelegate>
-(id)recipients;
-(void)createReminderWithDurationInMinutes:(NSUInteger)minutes;
@end

%hook CKTranscriptController

%new
-(void)messageCellTappedRemind {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"1 minute", @"5 minutes", @"15 minutes", @"1 hour", nil];
    [actionSheet showInView:[self view]];
    [actionSheet release];
}

%new
-(void)createReminderWithDurationInMinutes:(NSUInteger)minutes {
    //use originalAddress method for recipients as it falls back on rawAddress
    NSArray *recipients = [[self recipients] valueForKey:@"originalAddress"];
    NSString *title = [NSString stringWithFormat:@"Text %@", [[[self recipients] valueForKey:@"name"] componentsJoinedByString:@", "]];
    
    EKEventStore *store = [[EKEventStore alloc] init];
    EKReminder *reminder = [EKReminder reminderWithEventStore:store];
    [reminder setTitle:title];
    [reminder setCalendar:[store defaultCalendarForNewReminders]];
    
    NSString *actionURL = [NSString stringWithFormat:@"sms:/open?addresses=%@", [recipients componentsJoinedByString:@","]];
    if ([recipients count] == 1) {
        actionURL = [NSString stringWithFormat:@"sms:/open?address=%@", recipients[0]];
    }
    [reminder setAction:[NSURL URLWithString:actionURL]];
    
    NSDate *alarmDate = [NSDate dateWithTimeIntervalSinceNow:minutes * 60];
    EKAlarm *alarm = [EKAlarm alarmWithAbsoluteDate:alarmDate];
    [reminder setDueDateComponents:[[NSCalendar currentCalendar] components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:alarmDate]];
    [reminder setAlarms:@[alarm]];
    
    NSError *err = nil;
    BOOL didSave = [store saveReminder:reminder commit:YES error:&err];
    [store release];
    if (didSave == NO || err != nil) {
        //show error.
    }
    
}
%new
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([actionSheet cancelButtonIndex] == buttonIndex) {
        return;
    }
    switch (buttonIndex) {
        case 0://1 min
            [self createReminderWithDurationInMinutes:1];
            break;
        case 1://5 min
            [self createReminderWithDurationInMinutes:5];
            break;
        case 2://15 min
            [self createReminderWithDurationInMinutes:15];
            break;
        case 3://1 hour
            [self createReminderWithDurationInMinutes:60];
            break;
    }
}
%end


%hook RemindersCheckboxCell
-(void)tap:(UIGestureRecognizer *)gestureRecognizer {
    NSURL *ivar(self, actionURL); UIView *ivar(self, linkHighlightView);
    BOOL sc = MSHookIvar<BOOL>(self, "_showingClear");
    if ([[actionURL scheme] isEqualToString:@"sms"]) {
        if ([gestureRecognizer state] == 3) {//ended
            [[UIApplication sharedApplication] openURL:actionURL];
        }
        if ([gestureRecognizer state] == 1) {//began
            if (!linkHighlightView) {
                UILabel *ivar(self, titleLabel);
                linkHighlightView = [[%c(RemindersHighlightView) alloc] initWithFrame:[titleLabel frame]];
                [linkHighlightView setOpaque:NO];
                object_setInstanceVariable(self, "_linkHighlightView", linkHighlightView);
            }
            [self addSubview:linkHighlightView];
        }
        if ([gestureRecognizer state] > 2) {
            [linkHighlightView removeFromSuperview];
        }
    } else {
        %orig;
    }
}
%end