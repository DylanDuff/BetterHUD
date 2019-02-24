#import "MediaRemote.h"

@interface SBHUDView : UIView
- (NSString *)title;
@end

@interface SBMediaController : NSObject
+ (id)sharedInstance;
- (float)volume;
- (void)setVolume:(float)volume;
- (BOOL)isRingerMuted;
- (BOOL)isPlaying;
@end

@interface SBHUDController : UIViewController
+ (SBHUDController *)sharedHUDController;
- (void)presentHUDView:(SBHUDView *)arg1 autoDismissWithDelay:(double)arg2;
- (void)volumeSliderShouldShow;
- (void)volumeSliderShouldHide;
@end

@interface SpringBoard
+(id)sharedApplication; 
-(void)getPlaybackState;
-(void)updateAlbumArt;
-(void)togglePlayPause;
-(void)nextTrack;
-(void)lastTrack;
@end

UIWindow *volumeWindow;
UIButton *albumArtView;
UISlider *volumeSlider;
UIView *musicControlsView;
UIImageView *artworkView;
UIButton *playButton;
UIButton *nextButton;
UIButton *backButton;

%hook SpringBoard
- (void)applicationDidFinishLaunching:(UIApplication *)arg1 {
	%orig;

	CGRect screenBounds = [UIScreen mainScreen].bounds;

	volumeWindow = [[UIWindow alloc] initWithFrame:CGRectMake(10, 25, screenBounds.size.width - 20, 50)];
	volumeWindow.backgroundColor = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:0.6];

    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurEffectView.frame = volumeWindow.bounds;
    blurEffectView.layer.cornerRadius = 10;
    blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[blurEffectView.layer setMasksToBounds:YES]; 
    [volumeWindow addSubview:blurEffectView];

	volumeWindow.windowLevel = UIWindowLevelAlert-10;
	volumeWindow.layer.cornerRadius = 10;
	volumeWindow.userInteractionEnabled = YES;
	[volumeWindow setHidden:YES];
	[volumeWindow.layer setMasksToBounds:YES];

    if(!volumeSlider){
		volumeSlider = [[UISlider alloc] initWithFrame:CGRectMake(10, 50/2 - 2.5, screenBounds.size.width - 40, 5)];
		volumeSlider.backgroundColor = [UIColor clearColor];
		volumeSlider.continuous = YES;
		volumeSlider.minimumValue = 0.0;
		volumeSlider.maximumValue = 1.0;
		volumeSlider.value = [[%c(SBMediaController) sharedInstance] volume];
		volumeSlider.maximumTrackTintColor = [UIColor grayColor];

		[volumeSlider setThumbImage:[UIImage new] forState:UIControlStateNormal];

		[volumeWindow addSubview:volumeSlider];
	}

}
%new
-(void)updateAlbumArt{
	if (artworkView){
		[artworkView removeFromSuperview];
	}

	MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef result){
			NSDictionary *dict = (__bridge NSDictionary*)result;

			NSData *artworkData = [dict objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtworkData];
			UIImage *artwork = [UIImage imageWithData:artworkData];
			artworkView = [[UIImageView alloc] initWithImage:artwork];
			artworkView.frame = albumArtView.bounds;
			artworkView.layer.cornerRadius = 8;
			[artworkView.layer setMasksToBounds:YES];
			[albumArtView addSubview:artworkView];
	});

}
%end

%hook SBHUDController
- (void)presentHUDView:(SBHUDView *)arg1 autoDismissWithDelay:(double)arg2 {
		/*
		if ([arg1.title isEqual:@"Ringer"]) {
			volumeSlider.userInteractionEnabled = NO;
			if ([[%c(SBMediaController) sharedInstance] isRingerMuted]) {
				volumeSlider.value = 0.0;
			}

			else {
				volumeSlider.value = 1.0;
			}
		}
		*/
		volumeSlider.userInteractionEnabled = YES;
		volumeSlider.value = [[%c(SBMediaController) sharedInstance] volume];

		if(volumeWindow.hidden == YES){
			[self volumeSliderShouldShow];
		}

}

%new
- (void)volumeSliderShouldShow{
	CGRect screenBounds = [UIScreen mainScreen].bounds;
	UIImage *playImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/BetterHUD/play@3x.png"];
	//UIImage *pauseImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/BetterHUD/pause@3x.png"];
	UIImage *nextImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/BetterHUD/next@3x.png"];
	UIImage* backImage = [UIImage imageWithCGImage:nextImage.CGImage 
	                                            scale:nextImage.scale
	                                      orientation:UIImageOrientationUpMirrored];


	if ([[%c(SBMediaController) sharedInstance] isPlaying]){
		volumeWindow.frame = CGRectMake(10, -100, screenBounds.size.width - 20, 100);
		volumeSlider.frame = CGRectMake(100, 68, screenBounds.size.width - 145, 5);	
		
		if(!albumArtView){
	        albumArtView = [[UIButton alloc] initWithFrame:CGRectMake(15, 15, 70, 70)];
	        albumArtView.alpha = 1;
	        albumArtView.layer.cornerRadius = 8;
	        albumArtView.hidden = NO;
	        albumArtView.backgroundColor = [UIColor whiteColor];
	        [volumeWindow addSubview:albumArtView];
		}
		[[%c(SpringBoard) sharedApplication] updateAlbumArt];
		if(!musicControlsView){
	        musicControlsView = [[UIView alloc] initWithFrame:CGRectMake(screenBounds.size.width/2 - 60, 25, screenBounds.size.width - 145, 80)];
	        musicControlsView.alpha = 1;
	        musicControlsView.layer.cornerRadius = 8;
	        musicControlsView.hidden = NO;
	        musicControlsView.backgroundColor = [UIColor clearColor];
	        [volumeWindow addSubview:musicControlsView];

	        if (!playButton){
	        	playButton = [[UIButton alloc] initWithFrame:CGRectMake(70, 0, 25, 30)];
		        playButton.alpha = 1;
		        playButton.hidden = NO;
		        playButton.backgroundColor = [UIColor clearColor];

		        UIImageView *playImageView = [[UIImageView alloc] initWithImage:playImage];
				playImageView.frame = playButton.bounds;
				[playButton addSubview:playImageView];

				UITapGestureRecognizer *tapPlayPause = [[UITapGestureRecognizer alloc] initWithTarget:self  action:@selector(togglePlayPause)];
		        tapPlayPause.numberOfTapsRequired = 1;
		        [playButton addGestureRecognizer:tapPlayPause];

		        [musicControlsView addSubview:playButton];
	        }
	        if (!backButton){
	        	backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 5, 35, 20)];
		        backButton.alpha = 1;
		        backButton.hidden = NO;
		        backButton.backgroundColor = [UIColor clearColor];

		        UIImageView *backImageView = [[UIImageView alloc] initWithImage:backImage];
				backImageView.frame = backButton.bounds;
				[backButton addSubview:backImageView];

				UITapGestureRecognizer *tapBack = [[UITapGestureRecognizer alloc] initWithTarget:self  action:@selector(lastTrack)];
		        tapBack.numberOfTapsRequired = 1;
		        [backButton addGestureRecognizer:tapBack];

		        [musicControlsView addSubview:backButton];
	        }
	        if (!nextButton){
	        	nextButton = [[UIButton alloc] initWithFrame:CGRectMake(125, 5, 35, 20)];
		        nextButton.alpha = 1;
		        nextButton.hidden = NO;
		        nextButton.backgroundColor = [UIColor clearColor];

		        UIImageView *nextImageView = [[UIImageView alloc] initWithImage:nextImage];
				nextImageView.frame = nextButton.bounds;
				[nextButton addSubview:nextImageView];

				UITapGestureRecognizer *tapNext = [[UITapGestureRecognizer alloc] initWithTarget:self  action:@selector(nextTrack)];
		        tapNext.numberOfTapsRequired = 1;
		        [nextButton addGestureRecognizer:tapNext];

		        [musicControlsView addSubview:nextButton];
	        }

		}

	}else{
		volumeWindow.frame = CGRectMake(10, -50, screenBounds.size.width - 20, 50);
		volumeSlider.frame = CGRectMake(10, 50/2 - 2.5, screenBounds.size.width - 40, 5);	
 		albumArtView.hidden = YES;
 		musicControlsView.hidden = YES;
	}

	[UIView animateWithDuration:0.3f animations:^{				
		volumeWindow.hidden = NO;
		if([[%c(SBMediaController) sharedInstance] isPlaying]){
			volumeWindow.center = CGPointMake(volumeWindow.center.x, +75);
		}else{
			volumeWindow.center = CGPointMake(volumeWindow.center.x, +50);
		}
	}
	completion:^(BOOL finished) {
		[self performSelector:@selector(volumeSliderShouldHide) withObject:self afterDelay:3.0 ];
	}];
}

%new
- (void)volumeSliderShouldHide{
	[UIView animateWithDuration:0.3f animations:^{
		if([[%c(SBMediaController) sharedInstance] isPlaying]){
			volumeWindow.center = CGPointMake(volumeWindow.center.x, -60);
		}else{
			volumeWindow.center = CGPointMake(volumeWindow.center.x, -30);
		}
    } completion:^(BOOL finished) {
    	volumeWindow.hidden = YES;
    }];

}

%new
- (void)togglePlayPause{
	MRMediaRemoteSendCommand(kMRTogglePlayPause, nil);
}
%new
-(void)nextTrack{
	MRMediaRemoteSendCommand(kMRNextTrack, nil);
	[[%c(SpringBoard) sharedApplication] updateAlbumArt];
}
%new
-(void)lastTrack{
	MRMediaRemoteSendCommand(kMRPreviousTrack, nil);
	[[%c(SpringBoard) sharedApplication] updateAlbumArt];
}
%end



