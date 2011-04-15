//
//  HoodStatsViewController.m
//  HoodStats
//
//  Created by Shannon Rush on 4/13/11.
//  Copyright 2011 Rush Devo. All rights reserved.
//

#import "HoodStatsViewController.h"
#import "InfoViewController.h"

@implementation HoodStatsViewController

@synthesize currentLocation, captureSession, previewLayer;


-(void)viewDidLoad {
    [super viewDidLoad];
    data = [[NSMutableArray alloc]init];
    NSError *error;
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput 
										  deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] 
										  error:&error];
    if (error) {
        NSLog(@"We couldn't get a capture Input! (%@)", [error localizedDescription]);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Important!" 
														message:@"Unable to find a camera." 
													   delegate:nil 
											  cancelButtonTitle:@"Okay" 
											  otherButtonTitles:nil];
        [alert show];
        [alert autorelease];
        
    }
    AVCaptureSession *aCaptureSession = [[AVCaptureSession alloc] init];
    [aCaptureSession addInput:captureInput];
    
    CALayer *layer = [self.view layer];
    AVCaptureVideoPreviewLayer *aPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:aCaptureSession];
    CGRect frame = [layer frame];
    frame.origin.x = frame.origin.y = 0;
    [aPreviewLayer setFrame:frame];
    [aPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [layer addSublayer:aPreviewLayer];
    [self setCaptureSession:aCaptureSession];
    [self setPreviewLayer:aPreviewLayer];
    [self addLoadingLayer];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
	if (!locationManager) {
		locationManager = [[CLLocationManager alloc] init];
	}	
    
    [[UIAccelerometer sharedAccelerometer] setDelegate:self];
    locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager setDelegate:self];
    [locationManager startUpdatingHeading];
    [locationManager startUpdatingLocation];
    [[self captureSession] startRunning];
    
}

-(void)addLoadingLayer {
    scanningImage = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"scanning.png"]];
    scanningImage.frame = CGRectMake(18, 80, 286, 2);
    [[self view] addSubview:scanningImage];
    loadingImage = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"loading.png"]];
    [[self view] addSubview:loadingImage];
    [self animateScanner];
    [scanningImage release];
    [loadingImage release];
}

-(void)animateScanner {
    [UIView animateWithDuration:2.5 delay:0 options:UIViewAnimationOptionAutoreverse animations:^{
        CGRect newFrame = scanningImage.frame;
        newFrame.origin.y += 350.0;
        scanningImage.frame = newFrame;
    }
                     completion:^ (BOOL finished) {
                         if (finished) {
                             [scanningImage removeFromSuperview];
                             if ([data count]==0) {
                                 sleep(0.01);
                             }
                             [self performSelector:@selector(addOverlay) withObject:nil afterDelay:0.01];
                             [self performSelector:@selector(addButtons) withObject:nil afterDelay:0.01];
                             [loadingImage removeFromSuperview];
                         }
                     }];
}

-(void)addButtons {
    UIImage *infoImage = [UIImage imageNamed:@"info.png"];
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [infoButton setBackgroundImage:infoImage forState:UIControlStateNormal];
    infoButton.frame = CGRectMake(265, 395, 45, 45);
    [infoButton addTarget:self action:@selector(loadInfoScreen) forControlEvents:UIControlEventTouchUpInside];
    [[self view] addSubview:infoButton];
}

- (void)addOverlay {
	NSMutableArray *tempViews = [NSMutableArray arrayWithCapacity:[data count]-1];
    for (NSDictionary *stat in data) {
        if ([[stat allKeys]containsObject:@"label"]&&[[stat allKeys]containsObject:@"value"]) {
            UIView *markerView;
            UILabel *markerLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 200, 220, 55)];
            markerLabel.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bubble.png"]];
            [markerLabel setOpaque:NO];
            markerLabel.adjustsFontSizeToFitWidth = YES;
            markerLabel.textAlignment = UITextAlignmentCenter;
            markerLabel.textColor = [UIColor whiteColor]; 
            markerLabel.font = [UIFont fontWithName:@"Verdana" size:34.0f];
            markerLabel.text = [NSString stringWithFormat:@"  %@: %@  ",[stat objectForKey:@"label"],[stat objectForKey:@"value"]];
            markerView = markerLabel;
            [tempViews addObject:markerView];
            [[self view] addSubview:markerView];
        } else if ([[stat allKeys]containsObject:@"label"]) {
            UIView *markerView;
            UILabel *markerLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 100, 1200, 100)];
            markerLabel.backgroundColor = [UIColor clearColor];
            markerLabel.textColor = [UIColor colorWithRed:25.0f/255.0f green:127.0f/255.0f blue:161.0f/255.0f alpha:1.0]; 
            markerLabel.adjustsFontSizeToFitWidth = YES;
            markerLabel.textAlignment = UITextAlignmentCenter;
            markerLabel.font = [UIFont fontWithName:@"Verdana" size:45.0f];
            markerLabel.text = [stat objectForKey:@"label"];
            markerView = markerLabel;
            [tempViews addObject:markerView];
            [[self view] addSubview:markerView];
        }
    }
	overlayGraphicViews = [tempViews copy];
}

- (void)updateUI {
    if ([data count]>0) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:(1.0/10.0)];
        [UIView setAnimationDelay:(1.0/15.0)];
        
        for (float i=0.0; i<[overlayGraphicViews count]; i=i+1.0) {
            float directionToSite = i*1.0;
            CLLocationDistance dist = 50.0;
            
            double deltaAlt = 0;
            // the first item in array is the city label
            if (i==0.0) {
                deltaAlt = 20.0;
            }             
            
            double vertAngleToSite = atan2(deltaAlt, dist);
            
            double relativeDirectionToSite =  magCompassHeadingInDeg * (M_PI / 180.) - directionToSite;
            if (relativeDirectionToSite < (-M_PI / 2.0)) {
                relativeDirectionToSite = (-M_PI / 2.0); 
            }
            
            if (relativeDirectionToSite > (M_PI / 2.0)) {
                relativeDirectionToSite = (M_PI / 2.0); 
            }
            
            double relativeVertAngleToSite = vertAngleToSite - vertAngle;
            
            UIView *markerView = [overlayGraphicViews objectAtIndex:i];
            CGPoint overlayCenter = [markerView center];
            CGFloat oldY = overlayCenter.y;
            CGFloat oldX = overlayCenter.x;
            overlayCenter.y = 240.0 - 537.8 * sin(relativeVertAngleToSite);    
            overlayCenter.x = 160.0 - 497.8 * sin(relativeDirectionToSite);
            if (oldX != 0.0f) {
                overlayCenter.x += oldX;
                overlayCenter.x *= .5;
            }
            if (oldY != 0.0f) {
                overlayCenter.y += oldY;
                overlayCenter.y *= .5;
            }
            [markerView setCenter:overlayCenter];  
            markerView.transform = CGAffineTransformMakeRotation(angle);
        }
    }
}

-(void)loadInfoScreen {
    InfoViewController *info = [[InfoViewController alloc]initWithNibName:@"InfoViewController" bundle:[NSBundle mainBundle]];
    info.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:info animated:YES];
    [info release];
}

#pragma mark UIAccelerometerDelegate
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration;
{
    vertAngle = atan2(acceleration.y, acceleration.z) + M_PI/2.0;
    vertAngleInDeg = vertAngle * 180.0f/M_PI;
    
    angle = -atan2(acceleration.y, acceleration.x) - M_PI/2.0;
    angleInDeg = angle * 180.0f/M_PI;
    [self updateUI];
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    magCompassHeadingInDeg = [newHeading magneticHeading];
    [self updateUI];
}

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    [self setCurrentLocation:newLocation];
    NSLog(@"%i",[data count]);
    if ([data count]==0) {
        [data setArray:[self getData:newLocation]];
    }
    [self updateUI];
}

#pragma mark memory management

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
    [[UIAccelerometer sharedAccelerometer] setDelegate:nil];
    [locationManager stopUpdatingHeading]; 
	[locationManager stopUpdatingLocation]; 
	[locationManager setDelegate:nil];
}


- (void)dealloc {
    [[UIAccelerometer sharedAccelerometer] setDelegate:nil];
    [locationManager stopUpdatingHeading]; 
	[locationManager stopUpdatingLocation]; 
	[locationManager setDelegate:nil];
    
	[captureSession release];
	[previewLayer release];
    [currentLocation release]; 
    [locationManager release]; 
    [overlayGraphicViews release];
    
    [super dealloc];
}

@end