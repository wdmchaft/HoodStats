//
//  PhotoViewController.h
//  HoodStats
//
//  Created by Shannon Rush on 4/29/11.
//  Copyright 2011 Rush Devo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


@interface PhotoViewController : UIViewController {
    NSMutableArray *imageViews;
    UIImageView *currentImageView;
    UIButton *backButton;
    UIButton *forwardButton;
    UIButton *navButton;
}

@property (nonatomic, retain) UIImage *initialImage;
@property (nonatomic, retain) NSMutableArray *images;

-(void)initImageViews;
-(void)initButtons;
-(void)backPhoto;
-(void)forwardPhoto;
-(void)resetButtons;
-(void)navBack;

@end
