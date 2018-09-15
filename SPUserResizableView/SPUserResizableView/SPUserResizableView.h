//
//  SPUserResizableView.h
//  SPUserResizableView
//
//  Created by Stephen Poletto on 12/10/11.
//
//  SPUserResizableView is a user-resizable, user-repositionable
//  UIView subclass.

#import <Foundation/Foundation.h>

/* Let's inset everything that's drawn (the handles and the content view)
 so that users can trigger a resize from a few pixels outside of
 what they actually see as the bounding box. */
#define kSPUserResizableViewGlobalInset 0.0

#define kSPUserResizableViewDefaultMinWidth 8.0
#define kSPUserResizableViewDefaultMinHeight 8.0
#define kSPUserResizableViewInteractiveBorderSize 0.0

typedef struct SPUserResizableViewAnchorPoint {
    CGFloat adjustsX;
    CGFloat adjustsY;
    CGFloat adjustsH;
    CGFloat adjustsW;
} SPUserResizableViewAnchorPoint;

@protocol SPUserResizableViewDelegate;
@class SPGripViewBorderView;

@interface SPGripViewBorderView : UIView

@property (nonatomic) float resizableInset;
@property (nonatomic) float interactiveBorderSize;
@property (nonatomic,strong) UIImageView* topLeftAnchor;
@property (nonatomic,strong) UIImageView* topRightAnchor;
@property (nonatomic,strong) UIImageView* bottomLeftAnchor;
@property (nonatomic,strong) UIImageView* bottomRightAnchor;

@end

@interface SPUserResizableView : UIView {
    UIView* contentView;
    CGPoint touchStart;
    CGFloat minWidth;
    CGFloat minHeight;
    CGFloat previousSpanX;
    CGFloat previousSpanY;
    
    // Used to determine which components of the bounds we'll be modifying, based upon where the user's touch started.
    SPUserResizableViewAnchorPoint anchorPoint;
    
    id <SPUserResizableViewDelegate> delegate;
    
    /**
     *  This will ensure that when the resizing is done, it will restore
     *  anchor point.
     */
    CGPoint m_originalAnchorPoint;
    
    BOOL didMakeChange;
}

@property (nonatomic, weak) id <SPUserResizableViewDelegate> delegate;

/**
 *  Will be retained as a subview.
 */
@property (nonatomic, weak) UIView *contentView;
@property (retain) UIView* textView;

#pragma mark - Setup properties
/**
 *  Minimum width to let user resize
 *  @default Default is 48.0 for each.
 */
@property (nonatomic) CGFloat minWidth;
/**
 *  Minimum height that will let user to resize
 */
@property (nonatomic) CGFloat minHeight;

/**
 *  Disables resize of the view
 *  @default NO
 */
@property (nonatomic) BOOL disable;

/**
 *  Disables resize of the view if user use more than 1 finger.
 *  @default NO
 */
@property (nonatomic) BOOL disableOnMultiTouch;
/**
 *  Defaults to YES. Disables the user from dragging the view outside the parent view's bounds.
 */
@property (nonatomic) BOOL preventsPositionOutsideSuperview;

/**
 *  Defines if pan is disabled.
 *  @default NO
 */
@property (nonatomic) BOOL disablePan;

/**
 *  Defines the insent of the content.
 *  Larger == better detection
 */
@property (nonatomic) float resizableInset;
/**
 *  Interactive border size
 */
@property (nonatomic) float interactiveBorderSize;

/**
 *  Is currently resizing?
 *
 *  @return BOOL
 */
- (BOOL)isResizing;

@end

@protocol SPUserResizableViewDelegate <NSObject>

@optional

/**
 *  Called when the resizable view receives touchesBegan: and activates the editing handles.
 *
 *  @param userResizableView
 */
- (void)userResizableViewDidBeginEditing:(SPUserResizableView *)userResizableView;

/**
 *  Called when the resizable view receives touchesEnded: or touchesCancelled:
 *
 *  @param userResizableView
 */
- (void)userResizableViewDidEndEditing:(SPUserResizableView *)userResizableView;

/**
 *  Called when new frame was set.
 *
 *  @param userResizableView
 */
- (void)userResizableViewNewRealFrame:(SPUserResizableView *)userResizableView;

@end
