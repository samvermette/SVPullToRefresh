//
// SVPullToRefresh.m
//
// Created by Sam Vermette on 23.04.12.
// Copyright (c) 2012 samvermette.com. All rights reserved.
//
// https://github.com/samvermette/SVPullToRefresh
//

#import <QuartzCore/QuartzCore.h>
#import "SVPullToRefresh.h"

enum {
    SVPullToRefreshStateHidden = 1,
	SVPullToRefreshStateVisible,
    SVPullToRefreshStateTriggered,
    SVPullToRefreshStateInitialLoading,
    SVPullToRefreshStateLoading
};

typedef NSUInteger SVPullToRefreshState;


@interface SVPullToRefresh () 

- (id)initWithScrollView:(UIScrollView*)scrollView actionHandler:(void (^)(void))aH showAtInitialLoading:(BOOL)showAtInitialLoading;
- (void)rotateArrow:(float)degrees hide:(BOOL)hide;
- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset;
- (void)scrollViewDidScroll:(CGPoint)contentOffset;

@property (nonatomic, copy) void (^actionHandler)(void);
@property (nonatomic, readwrite) SVPullToRefreshState state;

@property (nonatomic, strong) UIImageView *arrow;
@property (nonatomic, strong, readonly) UIImage *arrowImage;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong, readonly) UILabel *dateLabel;
@property (nonatomic, strong, readonly) NSDateFormatter *dateFormatter;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, readwrite) UIEdgeInsets originalScrollViewContentInset;

@end



@implementation SVPullToRefresh

// public properties
@synthesize actionHandler, arrowColor, textColor, activityIndicatorViewStyle, lastUpdatedDate;

@synthesize state;
@synthesize scrollView = _scrollView;
@synthesize arrow, arrowImage, activityIndicatorView, titleLabel, dateLabel, dateFormatter, originalScrollViewContentInset;

- (id)initWithScrollView:(UIScrollView *)scrollView{
    self = [super initWithFrame:CGRectZero];
    self.scrollView = scrollView;
    [_scrollView addSubview:self];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(ceil(self.superview.bounds.size.width*0.10+44), 20, 150, 20)];
    titleLabel.text = NSLocalizedString(@"Pull to refresh...",);
    titleLabel.font = [UIFont boldSystemFontOfSize:14];
    titleLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:titleLabel];
    
    // default styling values
    self.arrowColor = [UIColor grayColor];
    self.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    self.titleLabel.textColor = [UIColor darkGrayColor];
    
    [self addSubview:self.arrow];
    
    [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    self.originalScrollViewContentInset = scrollView.contentInset;
    
    self.frame = CGRectMake(0, -60, scrollView.bounds.size.width, 60);
        
    return self;
}


#pragma mark - Getters

- (UIImageView *)arrow {
    if(!arrow) {
        arrow = [[UIImageView alloc] initWithImage:self.arrowImage];
        arrow.frame = CGRectMake(ceil(self.superview.bounds.size.width*0.10), 6, 22, 48);
        arrow.backgroundColor = [UIColor clearColor];
    }
    return arrow;
}

- (UIImage *)arrowImage {
    CGRect rect = CGRectMake(0, 0, 22, 48);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor clearColor] set];
    CGContextFillRect(context, rect);
    
    [self.arrowColor set];
    CGContextTranslateCTM(context, 0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextClipToMask(context, rect, [[UIImage imageNamed:@"SVPullToRefresh.bundle/arrow"] CGImage]);
    CGContextFillRect(context, rect);
    
    UIImage *output = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return output;
}

- (UIActivityIndicatorView *)activityIndicatorView {
    if(!activityIndicatorView) {
        activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityIndicatorView.hidesWhenStopped = YES;
        [self addSubview:activityIndicatorView];
        self.activityIndicatorView.center = self.arrow.center;
    }
    return activityIndicatorView;
}

- (UILabel *)dateLabel {
    if(!dateLabel) {
        dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.titleLabel.frame.origin.x, 28, 180, 20)];
        dateLabel.font = [UIFont systemFontOfSize:12];
        dateLabel.backgroundColor = [UIColor clearColor];
        dateLabel.textColor = [UIColor darkGrayColor];
        [self addSubview:dateLabel];
        
        CGRect titleFrame = titleLabel.frame;
        titleFrame.origin.y = 12;
        titleLabel.frame = titleFrame;
    }
    return dateLabel;
}

- (NSDateFormatter *)dateFormatter {
    if(!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		dateFormatter.locale = [NSLocale currentLocale];
    }
    return dateFormatter;
}

#pragma mark - Setters

- (void)setArrowColor:(UIColor *)newArrowColor {
    arrowColor = newArrowColor;
    self.arrow.image = self.arrowImage;
}

- (void)setTextColor:(UIColor *)newTextColor {
    self.titleLabel.textColor = newTextColor;
	self.dateLabel.textColor = newTextColor;
}

- (void)setActivityIndicatorViewStyle:(UIActivityIndicatorViewStyle)viewStyle {
    self.activityIndicatorView.activityIndicatorViewStyle = viewStyle;
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset {
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.scrollView.contentInset = contentInset;
    } completion:NULL];
}

- (void)setLastUpdatedDate:(NSDate *)newLastUpdatedDate {
    self.dateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Last Updated: %@",), newLastUpdatedDate?[self.dateFormatter stringFromDate:newLastUpdatedDate]:NSLocalizedString(@"Never",)];
}


#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"contentOffset"])
    {
        if(!loading)
        {
            [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
        }
    }
    else 
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context]; // in case scroll view has another observer or property observed
    }
}


- (void)scrollViewDidScroll:(CGPoint)contentOffset {    
    CGFloat scrollOffsetThreshold = self.frame.origin.y-self.originalScrollViewContentInset.top;
    
    if(!self.scrollView.isDragging && self.state == SVPullToRefreshStateTriggered)
        self.state = SVPullToRefreshStateLoading;
    else if(contentOffset.y > scrollOffsetThreshold && contentOffset.y < -self.originalScrollViewContentInset.top && self.scrollView.isDragging && self.state != SVPullToRefreshStateLoading)
        self.state = SVPullToRefreshStateVisible;
    else if(contentOffset.y < scrollOffsetThreshold && self.scrollView.isDragging && self.state == SVPullToRefreshStateVisible)
        self.state = SVPullToRefreshStateTriggered;
    else if(contentOffset.y >= -self.originalScrollViewContentInset.top && self.state != SVPullToRefreshStateHidden)
        self.state = SVPullToRefreshStateHidden;
}

- (void)stopAnimating {
    loading = NO;
    self.state = SVPullToRefreshStateHidden;
}

- (void)setState:(SVPullToRefreshState)newState {
    state = newState;
    
    switch (newState) {
        case SVPullToRefreshStateHidden:
            titleLabel.text = NSLocalizedString(@"Pull to refresh...",);
            [self.activityIndicatorView stopAnimating];
            [self setScrollViewContentInset:self.originalScrollViewContentInset];
            [self rotateArrow:0 hide:NO];
            break;
            
        case SVPullToRefreshStateVisible:
            titleLabel.text = NSLocalizedString(@"Pull to refresh...",);
            [self.activityIndicatorView stopAnimating];
            [self setScrollViewContentInset:self.originalScrollViewContentInset];
            [self rotateArrow:0 hide:NO];
            break;
            
        case SVPullToRefreshStateTriggered:
            titleLabel.text = NSLocalizedString(@"Release to refresh...",);
            [self rotateArrow:M_PI hide:NO];
            break;
            
        case SVPullToRefreshStateLoading:
            loading = YES;
            titleLabel.text = NSLocalizedString(@"Loading...",);
            [self.activityIndicatorView startAnimating];
            [self setScrollViewContentInset:UIEdgeInsetsMake(self.frame.origin.y*-1+self.originalScrollViewContentInset.top, 0, 0, 0)];
            [self rotateArrow:0 hide:YES];
            if(actionHandler)
                actionHandler();
            break;
            
        case SVPullToRefreshStateInitialLoading:
            loading = YES;
            titleLabel.text = NSLocalizedString(@"Loading...",);
            [self.activityIndicatorView startAnimating];
            [self.scrollView setContentInset:UIEdgeInsetsMake(self.frame.origin.y*-1+self.originalScrollViewContentInset.top, 0, 0, 0)];
            [self rotateArrow:0 hide:YES];
            if(actionHandler)
                actionHandler();
            break;
    }
}

- (void)rotateArrow:(float)degrees hide:(BOOL)hide {
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.arrow.layer.transform = CATransform3DMakeRotation(degrees, 0, 0, 1);
        self.arrow.layer.opacity = !hide;
    } completion:NULL];
}

@end


#pragma mark - UIScrollView (SVPullToRefresh)
#import <objc/runtime.h>

static char UIScrollViewPullToRefreshView;

@implementation UIScrollView (SVPullToRefresh)

@dynamic pullToRefreshView;

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler showAtInitialLoading:(BOOL)showAtInitialLoading{
    SVPullToRefresh *pullToRefreshView = [[SVPullToRefresh alloc] initWithScrollView:self];
    self.pullToRefreshView = pullToRefreshView;
    self.pullToRefreshView.actionHandler = actionHandler;
    if(showAtInitialLoading)
        self.pullToRefreshView.state = SVPullToRefreshStateInitialLoading;
    else
        self.pullToRefreshView.state = SVPullToRefreshStateHidden;
}

- (void)setPullToRefreshView:(SVPullToRefresh *)pullToRefreshView {
    [self willChangeValueForKey:@"pullToRefreshView"];
    objc_setAssociatedObject(self, &UIScrollViewPullToRefreshView,
                             pullToRefreshView,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"pullToRefreshView"];
}

- (SVPullToRefresh *)pullToRefreshView {
    return objc_getAssociatedObject(self, &UIScrollViewPullToRefreshView);
}

@end