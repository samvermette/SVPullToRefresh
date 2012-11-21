//
// UIScrollView+SVPullToRefresh.m
//
// Created by Sam Vermette on 23.04.12.
// Copyright (c) 2012 samvermette.com. All rights reserved.
//
// https://github.com/samvermette/SVPullToRefresh
//

#import <QuartzCore/QuartzCore.h>
#import "UIScrollView+SVPullToRefresh.h"


static CGFloat const SVPullToRefreshViewHeight = 60;

@interface SVPullToRefreshArrow : UIView

@property (nonatomic, strong) UIColor *arrowColor;

@end


@interface SVPullToRefreshView ()

@property (nonatomic, copy) void (^pullToRefreshActionHandler)(void);

@property (nonatomic, strong) SVPullToRefreshArrow *arrow;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UILabel *subtitleLabel;
@property (nonatomic, readwrite) SVPullToRefreshState state;

@property (nonatomic, strong) NSMutableArray *titles;
@property (nonatomic, strong) NSMutableArray *subtitles;
@property (nonatomic, strong) NSMutableArray *viewForState;

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalTopInset;

@property (nonatomic, assign) BOOL wasTriggeredByUser;
@property (nonatomic, assign) BOOL showsPullToRefresh;
@property (nonatomic, assign) BOOL showsDateLabel;
@property(nonatomic, assign) BOOL isObserving;

- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForLoading;
- (void)setScrollViewContentInset:(UIEdgeInsets)insets;
- (void)rotateArrow:(float)degrees hide:(BOOL)hide;

@end



#pragma mark - UIScrollView (SVPullToRefresh)
#import <objc/runtime.h>

static char UIScrollViewPullToRefreshView;

@implementation UIScrollView (SVPullToRefresh)

@dynamic pullToRefreshView, showsPullToRefresh;

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler {
    
    if(!self.pullToRefreshView) {
        SVPullToRefreshView *view = [[SVPullToRefreshView alloc] initWithFrame:CGRectMake(0, -SVPullToRefreshViewHeight, self.bounds.size.width, SVPullToRefreshViewHeight)];
        view.pullToRefreshActionHandler = actionHandler;
        view.scrollView = self;
        [self addSubview:view];
        
        view.originalTopInset = self.contentInset.top;
        self.pullToRefreshView = view;
        self.showsPullToRefresh = YES;
    }
}

- (void)triggerPullToRefresh {
    self.pullToRefreshView.state = SVPullToRefreshStateTriggered;
    [self.pullToRefreshView startAnimating];
}

- (void)setPullToRefreshView:(SVPullToRefreshView *)pullToRefreshView {
    [self willChangeValueForKey:@"SVPullToRefreshView"];
    objc_setAssociatedObject(self, &UIScrollViewPullToRefreshView,
                             pullToRefreshView,
                             OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"SVPullToRefreshView"];
}

- (SVPullToRefreshView *)pullToRefreshView {
    return objc_getAssociatedObject(self, &UIScrollViewPullToRefreshView);
}

- (void)setShowsPullToRefresh:(BOOL)showsPullToRefresh {
    self.pullToRefreshView.hidden = !showsPullToRefresh;
    
    if(!showsPullToRefresh) {
      if (self.pullToRefreshView.isObserving) {
        [self removeObserver:self.pullToRefreshView forKeyPath:@"contentOffset"];
        [self removeObserver:self.pullToRefreshView forKeyPath:@"frame"];
        [self.pullToRefreshView resetScrollViewContentInset];
        self.pullToRefreshView.isObserving = NO;
      }
    }
    else {
      if (!self.pullToRefreshView.isObserving) {
        [self addObserver:self.pullToRefreshView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self.pullToRefreshView forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
        self.pullToRefreshView.isObserving = YES;
      }
    }
}

- (BOOL)showsPullToRefresh {
    return !self.pullToRefreshView.hidden;
}

@end

#pragma mark - SVPullToRefresh
@implementation SVPullToRefreshView

// public properties
@synthesize pullToRefreshActionHandler, arrowColor, textColor, activityIndicatorViewStyle, lastUpdatedDate, dateFormatter;

@synthesize state = _state;
@synthesize scrollView = _scrollView;
@synthesize showsPullToRefresh = _showsPullToRefresh;
@synthesize arrow = _arrow;
@synthesize activityIndicatorView = _activityIndicatorView;

@synthesize titleLabel = _titleLabel;
@synthesize dateLabel = _dateLabel;


- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        
        // default styling values
        self.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        self.textColor = [UIColor darkGrayColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.state = SVPullToRefreshStateStopped;
        self.showsDateLabel = NO;
        
        self.titles = [NSMutableArray arrayWithObjects:NSLocalizedString(@"Pull to refresh...",),
                                                       NSLocalizedString(@"Release to refresh...",),
                                                       NSLocalizedString(@"Loading...",),
                                                       nil];
        
        self.subtitles = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", nil];
        self.viewForState = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", nil];
    }

    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview { 
    if (self.superview && newSuperview == nil) {
        //use self.superview, not self.scrollView. Why self.scrollView == nil here?
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (scrollView.showsPullToRefresh) {
          if (self.isObserving) {
            //If enter this branch, it is the moment just before "SVPullToRefreshView's dealloc", so remove observer here
            [scrollView removeObserver:self forKeyPath:@"contentOffset"];
            [scrollView removeObserver:self forKeyPath:@"frame"];
            self.isObserving = NO;
          }
        }
    }
}

- (void)layoutSubviews {
    CGFloat remainingWidth = self.superview.bounds.size.width-200;
    float position = 0.50;
    
    CGRect titleFrame = self.titleLabel.frame;
    titleFrame.origin.x = ceil(remainingWidth*position+44);
    self.titleLabel.frame = titleFrame;
    
    CGRect dateFrame = self.subtitleLabel.frame;
    dateFrame.origin.x = titleFrame.origin.x;
    self.subtitleLabel.frame = dateFrame;
    
    CGRect arrowFrame = self.arrow.frame;
    arrowFrame.origin.x = ceil(remainingWidth*position);
    self.arrow.frame = arrowFrame;

    self.activityIndicatorView.center = self.arrow.center;
    
    for(id otherView in self.viewForState) {
        if([otherView isKindOfClass:[UIView class]])
            [otherView removeFromSuperview];
    }
    
    id customView = [self.viewForState objectAtIndex:self.state];
    BOOL hasCustomView = [customView isKindOfClass:[UIView class]];
    
    self.titleLabel.hidden = hasCustomView;
    self.subtitleLabel.hidden = hasCustomView;
    self.arrow.hidden = hasCustomView;
    
    if(hasCustomView) {
        [self addSubview:customView];
        CGRect viewBounds = [customView bounds];
        CGPoint origin = CGPointMake(round((self.bounds.size.width-viewBounds.size.width)/2), round((self.bounds.size.height-viewBounds.size.height)/2));
        [customView setFrame:CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)];
    }
    else {
        self.titleLabel.text = [self.titles objectAtIndex:self.state];
        
        NSString *subtitle = [self.subtitles objectAtIndex:self.state];
        if(subtitle.length > 0)
            self.subtitleLabel.text = subtitle;
        
        switch (self.state) {
            case SVPullToRefreshStateStopped:
                self.arrow.alpha = 1;
                [self.activityIndicatorView stopAnimating];
                [self rotateArrow:0 hide:NO];
                break;
                
            case SVPullToRefreshStateTriggered:
                [self rotateArrow:M_PI hide:NO];
                break;
                
            case SVPullToRefreshStateLoading:
                [self.activityIndicatorView startAnimating];
                [self rotateArrow:0 hide:YES];
                break;
        }
    }
}

#pragma mark - Scroll View

- (void)resetScrollViewContentInset {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = self.originalTopInset;
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInsetForLoading {
    CGFloat offset = MAX(self.scrollView.contentOffset.y * -1, 0);
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = MIN(offset, self.originalTopInset + SVPullToRefreshViewHeight);
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset {
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.scrollView.contentInset = contentInset;
                     }
                     completion:NULL];
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {    
    if([keyPath isEqualToString:@"contentOffset"])
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    else if([keyPath isEqualToString:@"frame"])
        [self layoutSubviews];
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    if(self.state != SVPullToRefreshStateLoading) {
        CGFloat scrollOffsetThreshold = self.frame.origin.y-self.originalTopInset;
        
        if(!self.scrollView.isDragging && self.state == SVPullToRefreshStateTriggered)
            self.state = SVPullToRefreshStateLoading;
        else if(contentOffset.y < scrollOffsetThreshold && self.scrollView.isDragging && self.state == SVPullToRefreshStateStopped)
            self.state = SVPullToRefreshStateTriggered;
        else if(contentOffset.y >= scrollOffsetThreshold && self.state != SVPullToRefreshStateStopped)
            self.state = SVPullToRefreshStateStopped;
    }
}

#pragma mark - Getters

- (SVPullToRefreshArrow *)arrow {
    if(!_arrow) {
		_arrow = [[SVPullToRefreshArrow alloc]initWithFrame:CGRectMake(0, 6, 22, 48)];
        _arrow.backgroundColor = [UIColor clearColor];
		[self addSubview:_arrow];
    }
    return _arrow;
}

- (UIActivityIndicatorView *)activityIndicatorView {
    if(!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityIndicatorView.hidesWhenStopped = YES;
        [self addSubview:_activityIndicatorView];
    }
    return _activityIndicatorView;
}

- (UILabel *)titleLabel {
    if(!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 210, 20)];
        _titleLabel.text = NSLocalizedString(@"Pull to refresh...",);
        _titleLabel.font = [UIFont boldSystemFontOfSize:14];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = textColor;
        [self addSubview:_titleLabel];
    }
    return _titleLabel;
}

- (UILabel *)subtitleLabel {
    if(!_subtitleLabel) {
        _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 28, 210, 20)];
        _subtitleLabel.font = [UIFont systemFontOfSize:12];
        _subtitleLabel.backgroundColor = [UIColor clearColor];
        _subtitleLabel.textColor = textColor;
        [self addSubview:_subtitleLabel];
        
        CGRect titleFrame = self.titleLabel.frame;
        titleFrame.origin.y = 12;
        self.titleLabel.frame = titleFrame;
    }
    return _subtitleLabel;
}

- (UILabel *)dateLabel {
    return self.showsDateLabel ? self.subtitleLabel : nil;
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

- (UIColor *)arrowColor {
	return self.arrow.arrowColor; // pass through
}

- (UIColor *)textColor {
    return self.titleLabel.textColor;
}

- (UIActivityIndicatorViewStyle)activityIndicatorViewStyle {
    return self.activityIndicatorView.activityIndicatorViewStyle;
}

#pragma mark - Setters

- (void)setArrowColor:(UIColor *)newArrowColor {
	self.arrow.arrowColor = newArrowColor; // pass through
	[self.arrow setNeedsDisplay];
}

- (void)setTitle:(NSString *)title forState:(SVPullToRefreshState)state {
    if(!title)
        title = @"";
    
    if(state == SVPullToRefreshStateAll)
        [self.titles replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[title, title, title]];
    else
        [self.titles replaceObjectAtIndex:state withObject:title];
    
    [self setNeedsLayout];
}

- (void)setSubtitle:(NSString *)subtitle forState:(SVPullToRefreshState)state {
    if(!subtitle)
        subtitle = @"";
    
    if(state == SVPullToRefreshStateAll)
        [self.subtitles replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[subtitle, subtitle, subtitle]];
    else
        [self.subtitles replaceObjectAtIndex:state withObject:subtitle];
    
    [self setNeedsLayout];
}

- (void)setCustomView:(UIView *)view forState:(SVPullToRefreshState)state {
    id viewPlaceholder = view;
    
    if(!viewPlaceholder)
        viewPlaceholder = @"";
    
    if(state == SVPullToRefreshStateAll)
        [self.viewForState replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[viewPlaceholder, viewPlaceholder, viewPlaceholder]];
    else
        [self.viewForState replaceObjectAtIndex:state withObject:viewPlaceholder];
    
    [self setNeedsLayout];
}

- (void)setTextColor:(UIColor *)newTextColor {
    textColor = newTextColor;
    self.titleLabel.textColor = newTextColor;
	self.subtitleLabel.textColor = newTextColor;
}

- (void)setActivityIndicatorViewStyle:(UIActivityIndicatorViewStyle)viewStyle {
    self.activityIndicatorView.activityIndicatorViewStyle = viewStyle;
}

- (void)setLastUpdatedDate:(NSDate *)newLastUpdatedDate {
    self.showsDateLabel = YES;
    self.dateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Last Updated: %@",), newLastUpdatedDate?[self.dateFormatter stringFromDate:newLastUpdatedDate]:NSLocalizedString(@"Never",)];
}

- (void)setDateFormatter:(NSDateFormatter *)newDateFormatter {
	dateFormatter = newDateFormatter;
    self.dateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Last Updated: %@",), self.lastUpdatedDate?[newDateFormatter stringFromDate:self.lastUpdatedDate]:NSLocalizedString(@"Never",)];
}

#pragma mark -

- (void)triggerRefresh {
    [self.scrollView triggerPullToRefresh];
}

- (void)startAnimating{
    if(self.scrollView.contentOffset.y == 0) {
        [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -self.frame.size.height) animated:YES];
        self.wasTriggeredByUser = NO;
    }
    else
        self.wasTriggeredByUser = YES;
    
    self.state = SVPullToRefreshStateLoading;
}

- (void)stopAnimating {
    self.state = SVPullToRefreshStateStopped;
    
    if(!self.wasTriggeredByUser)
        [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, 0) animated:YES];
}

- (void)setState:(SVPullToRefreshState)newState {
    
    if(_state == newState)
        return;
    
    SVPullToRefreshState previousState = _state;
    _state = newState;
    
    [self setNeedsLayout];
    
    switch (newState) {
        case SVPullToRefreshStateStopped:
            [self resetScrollViewContentInset];
            break;
            
        case SVPullToRefreshStateTriggered:
            break;
            
        case SVPullToRefreshStateLoading:
            [self setScrollViewContentInsetForLoading];
            
            if(previousState == SVPullToRefreshStateTriggered && pullToRefreshActionHandler)
                pullToRefreshActionHandler();
            
            break;
    }
}

- (void)rotateArrow:(float)degrees hide:(BOOL)hide {
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.arrow.layer.transform = CATransform3DMakeRotation(degrees, 0, 0, 1);
        self.arrow.layer.opacity = !hide;
        //[self.arrow setNeedsDisplay];//ios 4
    } completion:NULL];
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
	CGFloat alphaGradientLocations[] = {0, 0.8};
    
	CGGradientRef alphaGradient = nil;
    if([[[UIDevice currentDevice] systemVersion]floatValue] >= 5){
        NSArray* alphaGradientColors = [NSArray arrayWithObjects:
                                        (id)[self.arrowColor colorWithAlphaComponent:0].CGColor,
                                        (id)[self.arrowColor colorWithAlphaComponent:1].CGColor,
                                        nil];
        alphaGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)alphaGradientColors, alphaGradientLocations);
    }else{
        const CGFloat * components = CGColorGetComponents([self.arrowColor CGColor]);
        int numComponents = CGColorGetNumberOfComponents([self.arrowColor CGColor]);        
        CGFloat colors[8];
        switch(numComponents){
            case 2:{
                colors[0] = colors[4] = components[0];
                colors[1] = colors[5] = components[0];
                colors[2] = colors[6] = components[0];
                break;
            }
            case 4:{
                colors[0] = colors[4] = components[0];
                colors[1] = colors[5] = components[1];
                colors[2] = colors[6] = components[2];
                break;
            }
        }
        colors[3] = 0;
        colors[7] = 1;
        alphaGradient = CGGradientCreateWithColorComponents(colorSpace,colors,alphaGradientLocations,2);
    }
	
	
	CGContextDrawLinearGradient(c, alphaGradient, CGPointZero, CGPointMake(0, rect.size.height), 0);
    
	CGContextRestoreGState(c);
	
	CGGradientRelease(alphaGradient);
	CGColorSpaceRelease(colorSpace);
}
@end
