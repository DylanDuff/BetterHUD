//Adapted from https://github.com/Muirey03/SmallSiri

#define kWidth [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
#define isX (kHeight >= 812)

@interface UIView (ss)
-(id)_viewControllerForAncestor;
@end

@interface SBAssistantWindow : UIWindow
-(void)didSwipeUp;
-(void)didSwipeDown;
-(void)expandSiriView;
-(void)closeSiriView;
@end

@interface UIStatusBar : UIView
@property (nonatomic, retain) UIColor *foregroundColor;
@end

@interface _UIStatusBar : UIView
@property (nonatomic, retain) UIColor *foregroundColor;
@end

@interface _UIRemoteView : UIView
@end

@interface MTLumaDodgePillView : UIView
@end

@interface SiriUISiriStatusView : UIView
@end

@interface SpringBoard
-(void)_simulateHomeButtonPress;
@end

@interface SiriUIHelpButton : UIView
@end

@interface SUICFlamesView : UIView
@end

@interface NSUserDefaults (inDomain)
-(id)objectForKey:(id)arg1 inDomain:(id)arg2 ;
@end

static CGFloat yChange = 0;
static UISwipeGestureRecognizer* swipeUpGesture;
static UISwipeGestureRecognizer* swipeDownGesture;
static SiriUISiriStatusView* status;
static SiriUIHelpButton* helpButton;
static SUICFlamesView* flames;
static _UIRemoteView* remote;
static BOOL hasExpanded = NO;
static UIView* statusBar;
static UIView* sbSuperview;

//change the frame and corner radius of the siri window - This is where the magic happens
%hook SBAssistantWindow
-(void)becomeKeyWindow
{
    %orig;
    if (!hasExpanded)
    {
        CGFloat yF = isX ? 44 : 25;

        self.frame = CGRectMake(10, yF, kWidth - 20, 90);

        self.subviews[0].layer.cornerRadius = 10;
        self.subviews[0].clipsToBounds = YES;

        //add a recogniser so we can drag the window up to dismiss
        swipeUpGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeUp)];
        swipeUpGesture.direction = UISwipeGestureRecognizerDirectionUp;
        [self.subviews[0] addGestureRecognizer:swipeUpGesture];

        //add a recogniser so we can drag the window down to expand
        swipeDownGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeDown)];
        swipeDownGesture.direction = UISwipeGestureRecognizerDirectionDown;
        [self.subviews[0] addGestureRecognizer:swipeDownGesture];
    }
}

-(void)dealloc
{
    %orig;
    hasExpanded = NO;
}

%new
-(void)closeSiriView
{
    if (!hasExpanded){
        //dismiss siri
        [UIView animateWithDuration:0.3f animations:^{
           self.subviews[0].center = CGPointMake(self.subviews[0].center.x, -90);
        } completion:^(BOOL finished) {
           [(SpringBoard *)[%c(UIApplication) sharedApplication] _simulateHomeButtonPress];
        }];
    }
}

%new
-(void)expandSiriView
{
    if (!hasExpanded)
    {
        //dismiss siri
        [UIView animateWithDuration:0.5f animations:^{
            //animate it expanding
            self.frame = CGRectMake(0, 0, kWidth, kHeight);
        } completion:^(BOOL finished) {
            //undo all changes:

            for (UIView* v in status.subviews)
            {
                if ([v isMemberOfClass:[UIButton class]])
                {
                    //reset button position
                    v.frame = CGRectMake(0, 0, v.frame.size.width, v.frame.size.height);
                }
                else
                {
                    //reset siri icon position
                    v.frame = CGRectMake(v.frame.origin.x, v.frame.origin.y + yChange, v.frame.size.width, v.frame.size.height);
                }
            }

            //remove corner radius
            self.subviews[0].layer.cornerRadius = 0;
            self.subviews[0].clipsToBounds = NO;

            helpButton.frame = CGRectMake(helpButton.frame.origin.x, helpButton.frame.origin.y + yChange, self.frame.size.width, helpButton.frame.size.height);
			flames.frame = CGRectMake(flames.frame.origin.x, flames.frame.origin.y + yChange, flames.frame.size.width, flames.frame.size.height);
			remote.hidden = NO;
			[sbSuperview addSubview:statusBar];
        }];
        hasExpanded = YES;
    }
}

%new
-(void)didSwipeUp
{

    [self closeSiriView];

}

%new
-(void)didSwipeDown
{

        [self expandSiriView];

}

%end

//hide the status bar in the siri window
%hook UIStatusBar
-(void)didMoveToWindow
{
    %orig;
    if ([[self window] isMemberOfClass:objc_getClass("SBAssistantWindow")] && !hasExpanded)
    {
        statusBar = self;
        sbSuperview = self.superview;
        [self removeFromSuperview];
    }
}
%end

%hook _UIStatusBar
-(void)didMoveToWindow
{
    %orig;
    if ([[self window] isMemberOfClass:objc_getClass("SBAssistantWindow")] && !hasExpanded)
    {
        statusBar = self;
        sbSuperview = self.superview;
        [self removeFromSuperview];
    }
}
%end

//force button to be on bottom on iPhone X
%hook SiriUISiriStatusView
-(id)init
{
    self = %orig;
    if (self)
    {
        status = self;
    }
    return self;
}

-(void)layoutSubviews
{
    %orig;
    if (!hasExpanded)
    {
        //get button
        for (UIView* v in self.subviews)
        {
            if ([v isMemberOfClass:[UIButton class]])
            {
                //modify button's frame
                yChange = v.frame.origin.y;
                yChange -= (self.frame.size.height - v.frame.size.height); //will be negative
                v.frame = CGRectMake(0, yChange * -1, v.frame.size.width, v.frame.size.height);
                //move the siri icon down by the same amount:
                for (UIView* b in self.subviews)
                {
                    if (![b isMemberOfClass:[UIButton class]])
                    {
                        //modify icon's frame
                        b.frame = CGRectMake(b.frame.origin.x, b.frame.origin.y - yChange, b.frame.size.width, b.frame.size.height);
                        break;
                    }
                }
                break;
            }
        }
    }
}
%end

//move the help button down so its centered on the iPhoen X
%hook SiriUIHelpButton
-(id)init
{
    self = %orig;
    if (self)
    {
        helpButton = self;
    }
    return self;
}

-(void)setFrame:(CGRect)arg1
{
    if (!hasExpanded)
    {
        arg1 = CGRectMake(arg1.origin.x, arg1.origin.y - yChange, arg1.size.width, arg1.size.height);
    }
    %orig;
}
%end

//move the flames down so its centered on the iPhoen X
%hook SUICFlamesView
-(id)init
{
    self = %orig;
    if (self)
    {
        flames = self;
    }
    return self;
}

-(void)setActiveFrame:(CGRect)arg1
{
    if (!hasExpanded)
    {
        arg1 = CGRectMake(arg1.origin.x, arg1.origin.y - yChange, arg1.size.width, arg1.size.height);
    }
    %orig;
}
%end

//hide grabber on iPhone X
%hook MTLumaDodgePillView
-(void)didMoveToWindow
{
    %orig;
    if ([[[UIApplication sharedApplication] keyWindow] isMemberOfClass:objc_getClass("SBAssistantWindow")] && !hasExpanded)
    {
        [self removeFromSuperview];
    }
}
%end

//hide the results text that would get in the way
%hook _UIRemoteView
-(void)didMoveToSuperview
{
    %orig;
    if ([[self _viewControllerForAncestor] isMemberOfClass:objc_getClass("AFUISiriRemoteViewController")] && !hasExpanded)
    {
        remote = self;
        self.hidden = YES;
    }
}
%end