//
//  ViewController.m
//  GRKImageCropTestApp
//
//  Created by Levi Brown on 4/27/15.
//  Copyright (c) 2015 Levi Brown. All rights reserved.
//

#import "ViewController.h"
#import "UIImage+GRKImageCrop.h"

typedef NS_ENUM(NSUInteger, TargetImage) {
    TargetImageRed,
    TargetImageOrange,
    TargetImageBlue
};
@interface ViewController ()

@property (nonatomic,weak) IBOutlet UIImageView *mainImageView;
@property (nonatomic,weak) IBOutlet UIView *borderView;
@property (nonatomic,weak) IBOutlet UIImageView *backgroundImageView;
@property (nonatomic,weak) IBOutlet UISegmentedControl *imageSegmentedControl;
@property (nonatomic,weak) IBOutlet UISwitch *croppedSwitch;
@property (nonatomic,weak) IBOutlet UISlider *alphaSlider;
@property (nonatomic,weak) IBOutlet UILabel *alphaLabel;

@property (nonatomic,assign) CGFloat alphaThreshold;

- (IBAction)imageSegmentedControlChanged:(UISegmentedControl *)sender;
- (IBAction)croppedSwitchChanged:(UISwitch *)sender;
- (IBAction)alphaSliderChanged:(UISlider *)sender;

@end

@implementation ViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.alphaThreshold = 0;
    
    UIImage *background = [UIImage imageNamed:@"background"];
    background = [background resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeTile];
    self.backgroundImageView.image = background;
    self.borderView.layer.borderWidth = 1.0f;
    self.borderView.layer.borderColor = [[UIColor blackColor] CGColor];
    
    self.croppedSwitch.on = NO;
    [self updateAlphaThreshold: 0.0f];
    self.alphaSlider.value = self.alphaThreshold;
    [self selectTargetImage:TargetImageBlue];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

#pragma mark - Actions

- (IBAction)imageSegmentedControlChanged:(UISegmentedControl *)sender
{
    [self selectTargetImage:sender.selectedSegmentIndex];
}

- (IBAction)croppedSwitchChanged:(id)sender
{
    [self selectTargetImage:self.imageSegmentedControl.selectedSegmentIndex];
}

- (IBAction)alphaSliderChanged:(UISlider *)sender
{
    [self updateAlphaThreshold:sender.value];
    [self selectTargetImage:self.imageSegmentedControl.selectedSegmentIndex];
}

#pragma mark - Helpers

- (void)updateAlphaThreshold:(CGFloat)alphaThreshold
{
    self.alphaThreshold = alphaThreshold;
    self.alphaLabel.text = [NSString stringWithFormat:@"%1.1f", self.alphaThreshold];
}

- (void)selectTargetImage:(TargetImage)targetImage
{
    UIImage *image = nil;
    
    switch (targetImage) {
        case TargetImageRed:
            image = [UIImage imageNamed:@"Red"];
            self.imageSegmentedControl.selectedSegmentIndex = TargetImageRed;
            break;
        case TargetImageOrange:
            image = [UIImage imageNamed:@"Orange"];
            self.imageSegmentedControl.selectedSegmentIndex = TargetImageOrange;
            break;
        case TargetImageBlue:
            image = [UIImage imageNamed:@"Blue"];
            self.imageSegmentedControl.selectedSegmentIndex = TargetImageBlue;
            break;
        default:
            NSLog(@"Unhandled target image.");
            break;
    }
    
    [self updateTargetImage:image cropped:self.croppedSwitch.on];
}

- (void)updateTargetImage:(UIImage *)image cropped:(BOOL)cropped
{
    
    if (cropped)
    {
        [image cropImageBelowAlphaThreshold:self.alphaThreshold completion:^(UIImage *croppedImage, NSError *error) {
            if (image)
            {
                self.mainImageView.image = croppedImage;
            }
            else
            {
                NSLog(@"Error: %@", error);
            }
        }];
    }
    else
    {
        self.mainImageView.image = image;
    }
}

@end
