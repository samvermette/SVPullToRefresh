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
    SVPullToRefreshStateLoading
};

typedef NSUInteger SVPullToRefreshState;

static CGFloat const SVPullToRefreshViewHeight = 60;

@interface SVPullToRefreshArrow : UIView
@property (nonatomic, strong) UIColor *arrowColor;
@end


@interface SVPullToRefresh ()

- (id)initWithScrollView:(UIScrollView*)scrollView;
- (void)rotateArrow:(float)degrees hide:(BOOL)hide;
- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset;
- (void)scrollViewDidScroll:(CGPoint)contentOffset;

- (void)startObservingScrollView;
- (void)stopObservingScrollView;

@property (nonatomic, copy) void (^pullToRefreshActionHandler)(void);
@property (nonatomic, copy) void (^infiniteScrollingActionHandler)(void);
@property (nonatomic, readwrite) SVPullToRefreshState state;

@property (nonatomic, strong) SVPullToRefreshArrow *arrow;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong, readonly) UILabel *dateLabel;

@property (nonatomic, unsafe_unretained) UIScrollView *scrollView;
@property (nonatomic, readwrite) UIEdgeInsets originalScrollViewContentInset;
@property (nonatomic, strong) UIView *originalTableFooterView;

@property (nonatomic, assign) BOOL showsPullToRefresh;
@property (nonatomic, assign) BOOL showsInfiniteScrolling;
@property (nonatomic, assign) BOOL isObservingScrollView;

@end



@implementation SVPullToRefresh

// public properties
@synthesize pullToRefreshActionHandler, infiniteScrollingActionHandler, arrowColor, textColor, activityIndicatorViewStyle, lastUpdatedDate, dateFormatter;

@synthesize state;
@synthesize scrollView = _scrollView;
@synthesize arrow, activityIndicatorView, titleLabel, dateLabel, originalScrollViewContentInset, originalTableFooterView, showsPullToRefresh, showsInfiniteScrolling, isObservingScrollView;

- (void)dealloc {
    [self stopObservingScrollView];
}

- (id)initWithScrollView:(UIScrollView *)scrollView {
    self = [super initWithFrame:CGRectZero];
    self.scrollView = scrollView;
    
    // default styling values
    self.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    self.textColor = [UIColor darkGrayColor];
    
    self.originalScrollViewContentInset = self.scrollView.contentInset;

    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if(newSuperview == self.scrollView)
        [self startObservingScrollView];
    else if(newSuperview == nil)
        [self stopObservingScrollView];
}

- (void)layoutSubviews {
    CGFloat remainingWidth = self.superview.bounds.size.width-200;
    float position = 0.50;
    
    CGRect titleFrame = titleLabel.frame;
    titleFrame.origin.x = ceil(remainingWidth*position+44);
    titleLabel.frame = titleFrame;
    
    CGRect dateFrame = dateLabel.frame;
    dateFrame.origin.x = titleFrame.origin.x;
    dateLabel.frame = dateFrame;
    
    CGRect arrowFrame = arrow.frame;
    arrowFrame.origin.x = ceil(remainingWidth*position);
    arrow.frame = arrowFrame;
	
    if(infiniteScrollingActionHandler) {
        self.activityIndicatorView.center = CGPointMake(round(self.bounds.size.width/2), round(self.bounds.size.height/2));
    } else
        self.activityIndicatorView.center = self.arrow.center;

}

#pragma mark - Getters

- (SVPullToRefreshArrow *)arrow {
    if(!arrow && pullToRefreshActionHandler) {
		arrow = [SVPullToRefreshArrow new];
        arrow.frame = CGRectMake(0, 6, 22, 48);
        arrow.backgroundColor = [UIColor clearColor];
		
		// assign a different default color for arrow
//		arrow.arrowColor = [UIColor blueColor];
    }
    return arrow;
}

- (UIActivityIndicatorView *)activityIndicatorView {
    if(!activityIndicatorView) {
        activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityIndicatorView.hidesWhenStopped = YES;
        [self addSubview:activityIndicatorView];
    }
    return activityIndicatorView;
}

- (UILabel *)dateLabel {
    if(!dateLabel && pullToRefreshActionHandler) {
        dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 28, 180, 20)];
        dateLabel.font = [UIFont systemFontOfSize:12];
        dateLabel.backgroundColor = [UIColor clearColor];
        dateLabel.textColor = textColor;
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

- (UIEdgeInsets)originalScrollViewContentInset {
    return UIEdgeInsetsMake(originalScrollViewContentInset.top, self.scrollView.contentInset.left, self.scrollView.contentInset.bottom, self.scrollView.contentInset.right);
}

#pragma mark - Setters

- (void)setPullToRefreshActionHandler:(void (^)(void))actionHandler {
    pullToRefreshActionHandler = [actionHandler copy];
    [_scrollView addSubview:self];
    self.showsPullToRefresh = YES;
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 150, 20)];
    titleLabel.text = NSLocalizedString(@"Pull to refresh...",);
    titleLabel.font = [UIFont boldSystemFontOfSize:14];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = textColor;
    [self addSubview:titleLabel];
    
    [self addSubview:self.arrow];
    	
    self.state = SVPullToRefreshStateHidden;    
    self.frame = CGRectMake(0, -SVPullToRefreshViewHeight, self.scrollView.bounds.size.width, SVPullToRefreshViewHeight);
}

- (void)setInfiniteScrollingActionHandler:(void (^)(void))actionHandler {
    infiniteScrollingActionHandler = [actionHandler copy];
    self.showsInfiniteScrolling = YES;
    
    self.frame = CGRectMake(0, 0, self.scrollView.bounds.size.width, SVPullToRefreshViewHeight);
    self.originalTableFooterView = [(UITableView*)self.scrollView tableFooterView];
    [(UITableView*)self.scrollView setTableFooterView:self];
    
    self.state = SVPullToRefreshStateHidden;    
    [self layoutSubviews];
}

- (void)setArrowColor:(UIColor *)newArrowColor {
	self.arrow.arrowColor = newArrowColor; // pass through
	[self.arrow setNeedsDisplay];
}

- (UIColor *)arrowColor {
	return self.arrow.arrowColor; // pass through
}

- (void)setTextColor:(UIColor *)newTextColor {
    textColor = newTextColor;
    titleLabel.textColor = newTextColor;
	dateLabel.textColor = newTextColor;
}

- (void)setActivityIndicatorViewStyle:(UIActivityIndicatorViewStyle)viewStyle {
    self.activityIndicatorView.activityIndicatorViewStyle = viewStyle;
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset {
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.scrollView.contentInset = contentInset;
    } completion:^(BOOL finished) {
        if(self.state == SVPullToRefreshStateHidden && contentInset.top == self.originalScrollViewContentInset.top)
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                arrow.alpha = 0;
            } completion:NULL];
    }];
}

- (void)setLastUpdatedDate:(NSDate *)newLastUpdatedDate {
    self.dateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Last Updated: %@",), newLastUpdatedDate?[self.dateFormatter stringFromDate:newLastUpdatedDate]:NSLocalizedString(@"Never",)];
}

- (void)setDateFormatter:(NSDateFormatter *)newDateFormatter {
	dateFormatter = newDateFormatter;
    self.dateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Last Updated: %@",), self.lastUpdatedDate?[newDateFormatter stringFromDate:self.lastUpdatedDate]:NSLocalizedString(@"Never",)];
}

- (void)setShowsInfiniteScrolling:(BOOL)show {
    showsInfiniteScrolling = show;
    if(!show)
        [(UITableView*)self.scrollView setTableFooterView:self.originalTableFooterView];
    else
        [(UITableView*)self.scrollView setTableFooterView:self];
}

#pragma mark -

- (void)startObservingScrollView {
    if (self.isObservingScrollView)
        return;
    
    [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    [self.scrollView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    self.isObservingScrollView = YES;
}

- (void)stopObservingScrollView {
    if(!self.isObservingScrollView)
        return;
    
    [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
    [self.scrollView removeObserver:self forKeyPath:@"frame"];
    self.isObservingScrollView = NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"contentOffset"])
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    else if([keyPath isEqualToString:@"frame"])
        [self layoutSubviews];
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {    
    if(pullToRefreshActionHandler) {
        if (self.state == SVPullToRefreshStateLoading) {
            CGFloat offset = MAX(self.scrollView.contentOffset.y * -1, 0);
            offset = MIN(offset, self.originalScrollViewContentInset.top + SVPullToRefreshViewHeight);
            self.scrollView.contentInset = UIEdgeInsetsMake(offset, 0.0f, 0.0f, 0.0f);
        } else {
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
    }
    else if(infiniteScrollingActionHandler) {
        CGFloat scrollOffsetThreshold = self.scrollView.contentSize.height-self.scrollView.bounds.size.height-self.originalScrollViewContentInset.top;
        
        if(contentOffset.y > MAX(scrollOffsetThreshold, self.scrollView.bounds.size.height-self.scrollView.contentSize.height) && self.state == SVPullToRefreshStateHidden)
            self.state = SVPullToRefreshStateLoading;
        else if(contentOffset.y < scrollOffsetThreshold)
            self.state = SVPullToRefreshStateHidden;
    }
}

- (void)triggerRefresh {
    self.state = SVPullToRefreshStateLoading;
    [self.scrollView setContentOffset:CGPointMake(0, -SVPullToRefreshViewHeight) animated:YES];
}

- (void)stopAnimating {
    self.state = SVPullToRefreshStateHidden;
}

- (void)setState:(SVPullToRefreshState)newState {
    
    if(pullToRefreshActionHandler && !self.showsPullToRefresh && !self.activityIndicatorView.isAnimating) {
        titleLabel.text = NSLocalizedString(@"",);
        [self.activityIndicatorView stopAnimating];
        [self setScrollViewContentInset:self.originalScrollViewContentInset];
        [self rotateArrow:0 hide:YES];
        return;   
    }
    
    if(infiniteScrollingActionHandler && !self.showsInfiniteScrolling)
        return;   
    
    if(state == newState)
        return;
    
    state = newState;
    
    if(pullToRefreshActionHandler) {
        switch (newState) {
            case SVPullToRefreshStateHidden:
                titleLabel.text = NSLocalizedString(@"Pull to refresh...",);
                [self.activityIndicatorView stopAnimating];
                [self setScrollViewContentInset:self.originalScrollViewContentInset];
                [self rotateArrow:0 hide:NO];
                break;
                
            case SVPullToRefreshStateVisible:
                titleLabel.text = NSLocalizedString(@"Pull to refresh...",);
                arrow.alpha = 1;
                [self.activityIndicatorView stopAnimating];
                [self setScrollViewContentInset:self.originalScrollViewContentInset];
                [self rotateArrow:0 hide:NO];
                break;
                
            case SVPullToRefreshStateTriggered:
                titleLabel.text = NSLocalizedString(@"Release to refresh...",);
                [self rotateArrow:M_PI hide:NO];
                break;
                
            case SVPullToRefreshStateLoading:
                titleLabel.text = NSLocalizedString(@"Loading...",);
                [self.activityIndicatorView startAnimating];
                UIEdgeInsets newInsets = self.originalScrollViewContentInset;
                newInsets.top = self.frame.origin.y*-1+self.originalScrollViewContentInset.top;
                newInsets.bottom = self.scrollView.contentInset.bottom;
                [self setScrollViewContentInset:newInsets];
                [self rotateArrow:0 hide:YES];
                pullToRefreshActionHandler();
                break;
        }
    }
    else if(infiniteScrollingActionHandler) {
        switch (newState) {
            case SVPullToRefreshStateHidden:
                [self.activityIndicatorView stopAnimating];
                break;

            case SVPullToRefreshStateLoading:
                [self.activityIndicatorView startAnimating];
                infiniteScrollingActionHandler();
                break;
        }
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
static char UIScrollViewInfiniteScrollingView;

@implementation UIScrollView (SVPullToRefresh)

@dynamic pullToRefreshView, showsPullToRefresh, infiniteScrollingView, showsInfiniteScrolling;

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler {
    self.pullToRefreshView.pullToRefreshActionHandler = actionHandler;
}

- (void)addInfiniteScrollingWithActionHandler:(void (^)(void))actionHandler {
    self.infiniteScrollingView.infiniteScrollingActionHandler = actionHandler;
}

- (void)setPullToRefreshView:(SVPullToRefresh *)pullToRefreshView {
    [self willChangeValueForKey:@"pullToRefreshView"];
    objc_setAssociatedObject(self, &UIScrollViewPullToRefreshView,
                             pullToRefreshView,
                             OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"pullToRefreshView"];
}

- (void)setInfiniteScrollingView:(SVPullToRefresh *)pullToRefreshView {
    [self willChangeValueForKey:@"infiniteScrollingView"];
    objc_setAssociatedObject(self, &UIScrollViewInfiniteScrollingView,
                             pullToRefreshView,
                             OBJC_ASSOCIATION_RETAIN);
    [self didChangeValueForKey:@"infiniteScrollingView"];
}

- (SVPullToRefresh *)pullToRefreshView {
    SVPullToRefresh *pullToRefreshView = objc_getAssociatedObject(self, &UIScrollViewPullToRefreshView);
    if(!pullToRefreshView) {
        pullToRefreshView = [[SVPullToRefresh alloc] initWithScrollView:self];
        self.pullToRefreshView = pullToRefreshView;
    }
    return pullToRefreshView;
}

- (void)setShowsPullToRefresh:(BOOL)showsPullToRefresh {
    self.pullToRefreshView.showsPullToRefresh = showsPullToRefresh;   
}

- (BOOL)showsPullToRefresh {
    return self.pullToRefreshView.showsPullToRefresh;
}

- (SVPullToRefresh *)infiniteScrollingView {
    SVPullToRefresh *infiniteScrollingView = objc_getAssociatedObject(self, &UIScrollViewInfiniteScrollingView);
    if(!infiniteScrollingView) {
        infiniteScrollingView = [[SVPullToRefresh alloc] initWithScrollView:self];
        self.infiniteScrollingView = infiniteScrollingView;
    }
    return infiniteScrollingView;
}

- (void)setShowsInfiniteScrolling:(BOOL)showsInfiniteScrolling {
    self.infiniteScrollingView.showsInfiniteScrolling = showsInfiniteScrolling;   
}

- (BOOL)showsInfiniteScrolling {
    return self.infiniteScrollingView.showsInfiniteScrolling;
}

@end


#pragma mark - SVPullToRefreshArrow

@implementation SVPullToRefreshArrow
@synthesize arrowColor;

- (UIColor *)arrowColor {
	if (arrowColor) return arrowColor;
	return [UIColor grayColor]; // default Color
}

- (void)drawRect:(CGRect)rect {
	CGContextRef c = UIGraphicsGetCurrentContext();
	
	// the rects above the arrow
	CGContextAddRect(c, CGRectMake(5, 0, 12, 4)); // to-do: use dynamic points
	CGContextAddRect(c, CGRectMake(5, 6, 12, 4)); // currently fixed size: 22 x 48pt
	CGContextAddRect(c, CGRectMake(5, 12, 12, 4));
	CGContextAddRect(c, CGRectMake(5, 18, 12, 4));
	CGContextAddRect(c, CGRectMake(5, 24, 12, 4));
	CGContextAddRect(c, CGRectMake(5, 30, 12, 4));
	
	// the arrow
	CGContextMoveToPoint(c, 0, 34);
	CGContextAddLineToPoint(c, 11, 48);
	CGContextAddLineToPoint(c, 22, 34);
	CGContextAddLineToPoint(c, 0, 34);
	CGContextClosePath(c);
	
	CGContextSaveGState(c);
	CGContextClip(c);
	
	
	// Gradient Declaration
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	NSArray* alphaGradientColors = [NSArray arrayWithObjects:
									(id)[self.arrowColor colorWithAlphaComponent:0].CGColor,
									(id)[self.arrowColor colorWithAlphaComponent:1].CGColor,
									nil];
	CGFloat alphaGradientLocations[] = {0, 0.8};
	CGGradientRef alphaGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)alphaGradientColors, alphaGradientLocations);
	
	
	CGContextDrawLinearGradient(c, alphaGradient, CGPointZero, CGPointMake(0, rect.size.height), 0);
	
	CGContextRestoreGState(c);
	
	CGGradientRelease(alphaGradient);
	CGColorSpaceRelease(colorSpace);
}
@end
