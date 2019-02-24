#import "TUCall.h"
#import <AddressBook/AddressBook.h> 

#define PLIST_PATH @"/var/mobile/Library/Preferences/com.dylanduff.betterhudprefs.plist"   
 
inline bool GetPrefBool(NSString *key){
  return [[[NSDictionary dictionaryWithContentsOfFile:PLIST_PATH] valueForKey:key] boolValue];
}

@interface SpringBoard <UIGestureRecognizerDelegate>
@property (retain, nonatomic) UIWindow *callWindow;
@property (retain, nonatomic) UIButton *contactView;
@property (retain, nonatomic) UIButton *acceptButton;
@property (retain, nonatomic) UIButton *declineButton;
@property (retain, nonatomic) UIButton *speakerButton;
@property (retain, nonatomic) UILabel *callerLabel;
@property (retain, nonatomic) UILabel *numberLabel;
+(id)sharedApplication;
-(void)shouldShowCallBanner;
-(void)shouldHideCallBanner;
@end

@interface PHInCallRootViewController
@property (retain, nonatomic) UIViewController* _currentViewController;
@property (assign) BOOL dismissalWasDemandedBeforeRemoteViewControllerWasAvailable;
+(id)sharedInstance;
+(void)setShouldForceDismiss;
-(void)prepareForDismissal;
-(void)dismissPhoneRemoteViewController;
-(void)presentPhoneRemoteViewControllerForView:(id)arg1;
@end

//methods to interact with the call
@interface TUCallCenter
+(id)sharedInstance;
-(id)incomingCall;
-(void)answerCall:(id)arg1;
-(void)disconnectCall:(id)arg1;
-(void)holdCall:(id)arg1 ;
-(void)unholdCall:(id)arg1;
@end

//detect incoming call and present our banner
%hook TUCall
-(void)_handleStatusChange {
	%orig;
	id incomingCallState = [[%c(TUCallCenter) sharedInstance] incomingCall];
	if(incomingCallState){		
		[[%c(SpringBoard) sharedApplication] shouldShowCallBanner];
	}else{
		[[%c(SpringBoard) sharedApplication] shouldHideCallBanner];
	}
	
}
%end

%hook SpringBoard
%property (retain, nonatomic) UIWindow *callWindow;
%property (retain, nonatomic) UIView *contactView;
%property (retain, nonatomic) UIButton *acceptButton;
%property (retain, nonatomic) UIButton *declineButton;
%property (retain, nonatomic) UIButton *speakerButton;
%property (retain, nonatomic) UILabel *callerLabel;
%property (retain, nonatomic) UILabel *numberLabel;
- (void)applicationDidFinishLaunching:(UIApplication *)arg1{
	if(GetPrefBool(@"kTweakEnabled")) {
		CGRect screenBounds = [UIScreen mainScreen].bounds;

		// Call Banner
		self.callWindow = [[UIWindow alloc] initWithFrame:CGRectMake(10, -150, screenBounds.size.width - 20, 100)];
		self.callWindow.backgroundColor = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:0.6];

	    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
	    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
	    blurEffectView.frame = self.callWindow.bounds;
	    blurEffectView.layer.cornerRadius = 10;
	    blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[blurEffectView.layer setMasksToBounds:YES]; 
	    [self.callWindow addSubview:blurEffectView];

		self.callWindow.windowLevel = UIWindowLevelAlert-10;
		self.callWindow.layer.cornerRadius = 10;
		self.callWindow.userInteractionEnabled = YES;
		[self.callWindow setHidden:NO];
		[self.callWindow.layer setMasksToBounds:YES];

		static UISwipeGestureRecognizer* swipeUpGesture;
		swipeUpGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(shouldHideCallBanner)];
	    swipeUpGesture.direction = UISwipeGestureRecognizerDirectionUp;
	    [self.callWindow addGestureRecognizer:swipeUpGesture];

	    //Banner Elements

		if(!self.contactView){

	        self.contactView = [[UIButton alloc] initWithFrame:CGRectMake(15, 15, 70, 70)];
	        self.contactView.alpha = 1;
	        self.contactView.layer.cornerRadius = 8;
	        self.contactView.backgroundColor = [UIColor whiteColor];

	        [self.callWindow addSubview:self.contactView];

	    }

	    if(!self.acceptButton){

	        self.acceptButton = [[UIButton alloc] initWithFrame:CGRectMake(screenBounds.size.width - 138, 30, 45, 45)];
	        self.acceptButton.alpha = 1;
	        self.acceptButton.layer.cornerRadius = 8;
	        self.acceptButton.backgroundColor = [UIColor colorWithRed:0.13 green:0.75 blue:0.42 alpha:1.0];

			UIImage *acceptImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/BetterHUD/answer.png"];
			UIImageView *acceptImageView = [[UIImageView alloc] initWithImage:acceptImage];
			acceptImageView.frame = self.acceptButton.bounds;
			[self.acceptButton addSubview:acceptImageView];

			UITapGestureRecognizer *tapAnswer = [[UITapGestureRecognizer alloc] initWithTarget:self  action:@selector(shouldAnswerCall)];
	        tapAnswer.numberOfTapsRequired = 1;
	        [self.acceptButton addGestureRecognizer:tapAnswer];

	        [self.callWindow addSubview:self.acceptButton];

	    }

	    if(!self.speakerButton){

	        self.speakerButton = [[UIButton alloc] initWithFrame:CGRectMake(screenBounds.size.width - 138, 30, 45, 45)];
	        self.speakerButton.alpha = 1;
	        self.speakerButton.hidden = YES;
	        self.speakerButton.layer.cornerRadius = 8;
	        self.speakerButton.backgroundColor = [UIColor colorWithRed:0.20 green:0.60 blue:0.86 alpha:1.0];

			UITapGestureRecognizer *tapSpeaker = [[UITapGestureRecognizer alloc] initWithTarget:self  action:@selector(shouldAnswerCall)];
	        tapSpeaker.numberOfTapsRequired = 1;
	        [self.speakerButton addGestureRecognizer:tapSpeaker];

	        [self.callWindow addSubview:self.speakerButton];

	    }

	    if(!self.declineButton){

	        self.declineButton = [[UIButton alloc] initWithFrame:CGRectMake(screenBounds.size.width - 80, 30, 45, 45)];
	        self.declineButton.alpha = 1;
	        self.declineButton.layer.cornerRadius = 8;
	        self.declineButton.backgroundColor = [UIColor colorWithRed:0.92 green:0.23 blue:0.35 alpha:1.0];

			UIImage *declineImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/BetterHUD/decline.png"];
			UIImageView *declineImageView = [[UIImageView alloc] initWithImage:declineImage];
			declineImageView.frame = self.declineButton.bounds;
			[self.declineButton addSubview:declineImageView];

			UITapGestureRecognizer *tapDisconnect = [[UITapGestureRecognizer alloc] initWithTarget:self  action:@selector(shouldDisconnectCall)];
	        tapDisconnect.numberOfTapsRequired = 1;
	        [self.declineButton addGestureRecognizer:tapDisconnect];

	        [self.callWindow addSubview:self.declineButton];

	    }

	    if (!self.callerLabel){
			self.callerLabel = [[UILabel alloc] initWithFrame:CGRectMake(95, 10, 100, 50)];
			[self.callerLabel setTextColor:[UIColor blackColor]];
			[self.callerLabel setBackgroundColor:[UIColor clearColor]];
			[self.callerLabel setFont:[UIFont boldSystemFontOfSize:18]]; 
			self.callerLabel.text = @"Jony Ive";
			[self.callWindow addSubview:self.callerLabel];
	    }

	    if (!self.numberLabel){
			self.numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(95, 32, 150, 50)];
			[self.numberLabel setTextColor:[UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:0.7]];
			[self.numberLabel setBackgroundColor:[UIColor clearColor]];
			[self.numberLabel setFont:[UIFont systemFontOfSize:15]]; 
			self.numberLabel.text = @"1 (519) 555 3789";
			[self.callWindow addSubview:self.numberLabel];
	    }
	}
    
    %orig;
}

//Handle functionality

%new
- (void)move:(UIPanGestureRecognizer *)recognizer {
	
	CGRect screenBounds = [UIScreen mainScreen].bounds;

	CGPoint translation = [recognizer translationInView:self.callWindow];
	recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x, 
	                             recognizer.view.center.y + translation.y);
	[recognizer setTranslation:CGPointMake(0, 0) inView:self.callWindow];

	if (recognizer.state == UIGestureRecognizerStateEnded) {

		CGPoint velocity = [recognizer velocityInView:self.callWindow];
		CGFloat magnitude = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));
		CGFloat slideMult = magnitude / 200;

		float slideFactor = 0.1 * slideMult; // Increase for more of a slide
		CGPoint finalPoint = CGPointMake(recognizer.view.center.x + (velocity.x * slideFactor), 
		                         recognizer.view.center.y + (velocity.y * slideFactor));
		finalPoint.x = MIN(MAX(finalPoint.x, 0), screenBounds.size.width);
		finalPoint.y = MIN(MAX(finalPoint.y, 0), screenBounds.size.height);

		[UIView animateWithDuration:slideFactor*2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		 recognizer.view.center = finalPoint;
	 } completion:nil];
	}
}
%new
- (void)shouldShowCallBanner{

	//Try and dismiss the call before it shows, this only ever works on the second call for some reason
	TUCall *incomingCallInfo = [[%c(TUCallCenter) sharedInstance] incomingCall];
	[[%c(PHInCallRootViewController) sharedInstance] prepareForDismissal];
	[[%c(PHInCallRootViewController) sharedInstance] dismissPhoneRemoteViewController];
	[[%c(PHInCallRootViewController) sharedInstance] setShouldForceDismiss];

	self.callerLabel.text = incomingCallInfo.displayName; 				
	self.numberLabel.text = incomingCallInfo.destinationID; 	


	//Trying to use this to get the contact image results in a crash
	//UIImage *contactImage = [UIImage imageWithData:[incomingCallInfo contactImageDataWithFormat:kABPersonImageFormatThumbnail]];
	
	//So lets load a placeholder for now
	UIImage *otherContactImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/BetterHUD/contact.png"];
		
	UIImageView *contactImageView = [[UIImageView alloc] initWithImage:otherContactImage];
	contactImageView.frame = self.contactView.bounds;
	contactImageView.layer.cornerRadius = 8;
	[contactImageView.layer setMasksToBounds:YES];
	[self.contactView addSubview:contactImageView];
	
	//self.acceptButton.hidden = NO;
	//self.speakerButton.hidden = YES;
	
	[UIView animateWithDuration:0.3f animations:^{
		self.callWindow.hidden = NO;
		self.callWindow.center = CGPointMake(self.callWindow.center.x, +85);
	}
	completion:^(BOOL finished) {
		//[self performSelector:@selector(volumeSliderShouldHide) withObject:self afterDelay:3.0 ];
	}];

}
%new
- (void)shouldHideCallBanner{
    [UIView animateWithDuration:0.3f animations:^{
       self.callWindow.center = CGPointMake(self.callWindow.center.x, -90);
    }
	completion:^(BOOL finished) {
		//[self performSelector:@selector(volumeSliderShouldHide) withObject:self afterDelay:3.0 ];
	}];
}
%new
-(void)shouldAnswerCall{	
	[[%c(TUCallCenter) sharedInstance] answerCall:[[%c(TUCallCenter) sharedInstance] incomingCall]];
	
	//If we wanna replace the answer button with a speaker button
	//self.acceptButton.hidden = YES;
	//self.speakerButton.hidden = NO;
}
%new
-(void)shouldDisconnectCall{
	[[%c(TUCallCenter) sharedInstance] disconnectCall:[[%c(TUCallCenter) sharedInstance] incomingCall]];
	//[[%c(TUCallCenter) sharedInstance] disconnectWithReason:1];
	[self shouldHideCallBanner];
}
%end

