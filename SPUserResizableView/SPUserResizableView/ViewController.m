//
//  ViewController.m
//  SPInteractiveLabel
//
//  Created by Stephen Poletto on 12/10/11.
//

#import "ViewController.h"

@interface ViewController()

@property (nonatomic, strong) SPUserResizableView *imageResizableView;
@property (nonatomic, strong) CAShapeLayer *fillLayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    self.view = [[UIView alloc] initWithFrame:appFrame];
    self.view.backgroundColor = [UIColor brownColor];
    
    //CGRect frame = CGRectMake(0, 40, UIScreen.mainScreen.bounds.size.width, 450);
    //CGRect frame = CGRectMake(0, 40, 306, 473);
    //CGRect frame = UIScreen.mainScreen.bounds;
    //CGRect frame = CGRectMake(0, 40, 275.5, 15.5);
    CGRect frame = CGRectMake(0, 40, 161.6696746122552, 209.1276176147237);
  
  
    self.imageResizableView = [[SPUserResizableView alloc] initWithFrame:frame];
    
    self.imageResizableView.contentView = [[UIView alloc] initWithFrame:frame];
    self.imageResizableView.contentView.backgroundColor = [UIColor darkGrayColor];
    self.imageResizableView.delegate = self;
    self.imageResizableView.disablePan = NO;
    //[self.imageResizableView showEditingHandles];
    
//    self.fillLayer = [CAShapeLayer layer];
//    self.fillLayer.path = self.fillLayer.path = [self getOverlayPath:appFrame transparentBounds:frame].CGPath;
//    self.fillLayer.fillRule = kCAFillRuleEvenOdd;
//    self.fillLayer.fillColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3].CGColor;
//    [self.view.layer addSublayer:self.fillLayer];
    
    [self.view addSubview:self.imageResizableView];    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
    if ([currentlyEditingView hitTest:[touch locationInView:currentlyEditingView] withEvent:nil]) {
        return NO;
    }
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (UIBezierPath *)getOverlayPath:(CGRect)overlayBounds transparentBounds:(CGRect)transparentBounds
{
    UIBezierPath *overlayPath = [UIBezierPath bezierPathWithRect:overlayBounds];
    UIBezierPath *transparentPath = [UIBezierPath bezierPathWithRect:transparentBounds];
    [overlayPath appendPath:transparentPath];
    [overlayPath setUsesEvenOddFillRule:YES];
    return overlayPath;
}

@end
