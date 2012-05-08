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
    SVPullToRefreshStateLoading,
    SVPullToRefreshStateHiddenBottom,
    SVPullToRefreshStateVisibleBottom,
    SVPullToRefreshStateTriggeredBottom,
    SVPullToRefreshStateLoadingBottom
};

typedef NSUInteger SVPullToRefreshState;

@interface SVPullToRefresh () 

- (id)initWithScrollView:(UIScrollView*)scrollView;
- (void)rotateArrow:(float)degrees hide:(BOOL)hide;
- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset;
- (void)scrollViewDidScroll:(CGPoint)contentOffset;

@property (nonatomic, copy) void (^actionHandler)(void);
@property (nonatomic, copy) void (^loadActionHandler)(void);
@property (nonatomic, copy) void (^infiniteScrollActionHandler)(void);
@property (nonatomic, readwrite) SVPullToRefreshState state;

@property (nonatomic, strong) UIImageView *arrow;
@property (nonatomic, strong, readonly) UIImage *arrowImage;
@property (nonatomic, strong, readonly) UIImage *bottomArrowImage;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) UIActivityIndicatorView *bottomActivityIndicatorView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *bottomLabel;
@property (nonatomic, strong) UIImageView *bottomArrow;

@property (nonatomic, strong, readonly) UILabel *dateLabel;
@property (nonatomic, strong, readonly) NSDateFormatter *dateFormatter;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, readwrite) UIEdgeInsets originalScrollViewContentInset;

@end



@implementation SVPullToRefresh

// public properties
@synthesize actionHandler, loadActionHandler, infiniteScrollActionHandler, arrowColor, bottomArrowColor, textColor, activityIndicatorViewStyle, lastUpdatedDate;
@synthesize bottomActivityIndicatorView, bottomLabel;

@synthesize state;
@synthesize scrollView = _scrollView;
@synthesize arrow, arrowImage, bottomArrow, bottomArrowImage, activityIndicatorView, titleLabel, dateLabel, dateFormatter, originalScrollViewContentInset;
@synthesize sectionDisplayLimit;
@synthesize rowDisplayLimit;
@synthesize portionsLoaded;

- (id)initWithScrollView:(UIScrollView *)scrollView {
   return [self initWithScrollView:scrollView andPerpetualLoad:NO];
}

- (id)initWithScrollView:(UIScrollView *)scrollView andPerpetualLoad:(BOOL)shouldPerpetuallyLoad {
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
    self.bottomArrowColor = [UIColor grayColor];
    self.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    self.titleLabel.textColor = [UIColor darkGrayColor];
    
    [self addSubview:self.arrow];
    
    // Add the bottom label and activity indicator
    self.bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(ceil(self.superview.bounds.size.width*0.10+44), 
                                                                 scrollView.contentSize.height + 20,
                                                                 150,
                                                                 20)];
    bottomLabel.text = @"Pull to load...";
    [self addSubview:bottomLabel];
    
    self.bottomActivityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    
    
    [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    [scrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
    self.originalScrollViewContentInset = scrollView.contentInset;
	
    self.state = SVPullToRefreshStateHidden;    
    self.frame = CGRectMake(0, -60, scrollView.bounds.size.width, scrollView.contentSize.height + 60);
    
    portionsLoaded = 1;
    
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

- (UIImageView *)bottomArrow {
    if (!bottomArrow) {
        bottomArrow = [[UIImageView alloc] initWithImage:self.bottomArrowImage];
        bottomArrow.frame = CGRectMake(ceil(self.superview.bounds.size.width), bottomLabel.frame.origin.y, 22, 48);
        bottomArrow.backgroundColor = [UIColor clearColor];
    }
    return bottomArrow;
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

- (UIImage *)bottomArrowImage {
    CGRect rect = CGRectMake(0, 0, 22, 48);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor clearColor] set];
    CGContextFillRect(context, rect);
    
    [self.bottomArrowColor set];
    CGContextTranslateCTM(context, 0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextClipToMask(context, rect, [[UIImage imageNamed:@"SVPullToRefresh.bundle/bottomArrow"] CGImage]);
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

- (UIActivityIndicatorView *)bottomActivityIndicatorView {
    if (!bottomActivityIndicatorView) {
        bottomActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        bottomActivityIndicatorView.hidesWhenStopped = YES;
        [self addSubview:bottomActivityIndicatorView];
        self.bottomActivityIndicatorView.center = self.bottomLabel.center;
    }
    return bottomActivityIndicatorView;
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

- (void)setBottomArrowColor:(UIColor *)newArrowColor {
    bottomArrowColor = newArrowColor;
    self.bottomArrow.image = self.bottomArrowImage;
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
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    else if ([keyPath isEqualToString:@"contentSize"]) {
        [self updateLabelToBottomOfContentSize:[[change valueForKey:NSKeyValueChangeNewKey] CGSizeValue]];
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context]; // in case scroll view has another observer or property observed
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {    
    CGFloat scrollOffsetThreshold = self.frame.origin.y-self.originalScrollViewContentInset.top;
    CGFloat scrollOffsetThresholdBottom = contentOffset.y + self.scrollView.frame.size.height;
    CGFloat loadTrigger = (self.scrollView.contentSize.height - self.scrollView.frame.size.height) * 0.8;
    
    if (contentOffset.y < 25) { // arbitrary value to distinguish top from bottom triggers
        if(!self.scrollView.isDragging && self.state == SVPullToRefreshStateTriggered)
            self.state = SVPullToRefreshStateLoading;
        else if(contentOffset.y > scrollOffsetThreshold && contentOffset.y < -self.originalScrollViewContentInset.top && self.scrollView.isDragging && self.state != SVPullToRefreshStateLoading)
            self.state = SVPullToRefreshStateVisible;
        else if(contentOffset.y < scrollOffsetThreshold && self.scrollView.isDragging && self.state == SVPullToRefreshStateVisible)
            self.state = SVPullToRefreshStateTriggered;
        else if(contentOffset.y >= -self.originalScrollViewContentInset.top && self.state != SVPullToRefreshStateHidden)
            self.state = SVPullToRefreshStateHidden;
    }
    else if (loadActionHandler) {
        if (!self.scrollView.isDragging && self.state == SVPullToRefreshStateTriggeredBottom) {
            self.state = SVPullToRefreshStateLoadingBottom;
        }
        else if(scrollOffsetThresholdBottom > self.scrollView.contentSize.height && scrollOffsetThresholdBottom < (bottomLabel.frame.origin.y + bottomLabel.frame.size.height)  && self.state != SVPullToRefreshStateLoadingBottom && self.scrollView.isDragging) {
            self.state = SVPullToRefreshStateVisibleBottom;
        }
        else if(scrollOffsetThresholdBottom > self.scrollView.contentSize.height + 60 && self.scrollView.isDragging && self.state == SVPullToRefreshStateVisibleBottom) {
                self.state = SVPullToRefreshStateTriggeredBottom;   
        }
        else if(self.state != SVPullToRefreshStateHiddenBottom && scrollOffsetThresholdBottom < self.scrollView.contentSize.height) {
            self.state = SVPullToRefreshStateHiddenBottom;
        }
    }
    else if (infiniteScrollActionHandler) {
        NSLog(@"LT: %f, CS: %f, H: %f", loadTrigger, self.scrollView.contentSize.height, self.scrollView.frame.size.height);
        if (contentOffset.y > loadTrigger && self.state != SVPullToRefreshStateLoadingBottom) {
            self.state = SVPullToRefreshStateLoadingBottom;
        }
    }

}

- (void)updateLabelToBottomOfContentSize:(CGSize)contentSize {
    self.bottomLabel.frame = CGRectMake(bottomLabel.frame.origin.x,
                                        contentSize.height + 80,
                                        bottomLabel.frame.size.width,
                                        bottomLabel.frame.size.height);
    
    // take the bottom spinner with it
    CGPoint labelCenter = self.bottomLabel.center;
    self.bottomActivityIndicatorView.center = CGPointMake(labelCenter.x + 15, labelCenter.y);
    
    // And the arrow
    self.bottomArrow.center = CGPointMake(labelCenter.x - 15, labelCenter.y);
    //self.scrollView.contentSize = CGSizeMake(contentSize.width, contentSize.height + 60);
    
}

- (void)stopAnimating {
    if (self.state == SVPullToRefreshStateLoading) {
        self.state = SVPullToRefreshStateHidden;
    }
    else if (self.state == SVPullToRefreshStateLoadingBottom) {
        self.state = SVPullToRefreshStateHiddenBottom;
    }
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
            //[self rotateArrow:0 hide:NO];
            
            break;
            
        case SVPullToRefreshStateTriggered:
            titleLabel.text = NSLocalizedString(@"Release to refresh...",);
            [self rotateArrow:M_PI hide:NO];
            break;
            
        case SVPullToRefreshStateLoading:
            titleLabel.text = NSLocalizedString(@"Loading...",);
            [self.activityIndicatorView startAnimating];
            [self setScrollViewContentInset:UIEdgeInsetsMake(self.frame.origin.y*-1+self.originalScrollViewContentInset.top, 0, 0, 0)];
            [self rotateArrow:0 hide:YES];
            if(actionHandler)
                actionHandler();
            break;
        case SVPullToRefreshStateHiddenBottom:
            bottomLabel.text = NSLocalizedString(@"Drag to load...",);
            [self.bottomActivityIndicatorView stopAnimating];
            [self setScrollViewContentInset:self.originalScrollViewContentInset];
            [self rotateArrow:1 hide:NO];
            break;
            
        case SVPullToRefreshStateVisibleBottom:
            bottomLabel.text = NSLocalizedString(@"Drag to load...",);
            [self.bottomActivityIndicatorView stopAnimating];
            [self setScrollViewContentInset:self.originalScrollViewContentInset];
            [self rotateArrow:1 hide:NO];
            break;
            
        case SVPullToRefreshStateTriggeredBottom:
            bottomLabel.text = NSLocalizedString(@"Release to load...",);
            [self rotateArrow:M_PI hide:NO];
            break;
            
        case SVPullToRefreshStateLoadingBottom:
            bottomLabel.text = NSLocalizedString(@"Loading...",);
            [self.bottomActivityIndicatorView startAnimating];
            [self setScrollViewContentInset:UIEdgeInsetsMake(0, 0, 60, 0)];
            [self rotateArrow:1 hide:YES];
            if(loadActionHandler)
                loadActionHandler();
            else if (infiniteScrollActionHandler)
                infiniteScrollActionHandler();
            break;    
    }
}

- (void)roateArrow:(UIImageView *)arrowImageView byDegrees:(float)degrees hide:(BOOL)hide {
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        arrowImageView.layer.transform = CATransform3DMakeRotation(degrees, 0, 0, 1);
        arrowImageView.layer.opacity = !hide;
    } completion:NULL];
}

- (void)rotateArrow:(float)degrees hide:(BOOL)hide {
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.arrow.layer.transform = CATransform3DMakeRotation(degrees, 0, 0, 1);
        self.arrow.layer.opacity = !hide;
    } completion:NULL];
}

- (void)loadNextPortion {
    portionsLoaded++;
    if ([[self superview] isMemberOfClass:[UIScrollView class]]) {
        CGSize contentSize = self.scrollView.contentSize;
        contentSize = CGSizeMake(contentSize.width, contentSize.height * 2);
        self.scrollView.contentSize = contentSize;
    }
    else if ([[self superview] isMemberOfClass:[UITableView class]]) {
        UITableView *tableView = (UITableView *)[self superview];
        [tableView reloadData];
    }
}

@end


#pragma mark - UIScrollView (SVPullToRefresh)
#import <objc/runtime.h>

static char UIScrollViewPullToRefreshView;

@implementation UIScrollView (SVPullToRefresh)

@dynamic pullToRefreshView;

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler {
    SVPullToRefresh *pullToRefreshView = [[SVPullToRefresh alloc] initWithScrollView:self];
    pullToRefreshView.actionHandler = actionHandler;
    self.pullToRefreshView = pullToRefreshView;
}

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler andDragToLoadHandler:(void (^)(void))loadActionHandler {
    SVPullToRefresh *pullToRefreshView = [[SVPullToRefresh alloc] initWithScrollView:self];
    pullToRefreshView.actionHandler = actionHandler;
    pullToRefreshView.loadActionHandler = loadActionHandler;
    
    self.pullToRefreshView = pullToRefreshView;
}

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler infiniteScrollActionHandler:(void(^)(void))infiniteScrollActionHandler {
    SVPullToRefresh *pullToRefreshView = [[SVPullToRefresh alloc] initWithScrollView:self];
    pullToRefreshView.actionHandler = actionHandler;
    pullToRefreshView.infiniteScrollActionHandler = infiniteScrollActionHandler;
    
    self.pullToRefreshView = pullToRefreshView;
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
