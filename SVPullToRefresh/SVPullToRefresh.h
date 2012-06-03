//
// SVPullToRefresh.h
//
// Created by Sam Vermette on 23.04.12.
// Copyright (c) 2012 samvermette.com. All rights reserved.
//
// https://github.com/samvermette/SVPullToRefresh
//

#import <UIKit/UIKit.h>

@interface SVPullToRefresh : UIView

@property (nonatomic, strong) UIColor *arrowColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, readwrite) UIActivityIndicatorViewStyle activityIndicatorViewStyle;

@property (nonatomic, strong) NSDate *lastUpdatedDate;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

- (void)triggerRefresh;
- (void)stopAnimating;

@end


// extends UIScrollView

@interface UIScrollView (SVPullToRefresh)

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler;
- (void)addInfiniteScrollingWithActionHandler:(void (^)(void))actionHandler;

@property (nonatomic, strong) SVPullToRefresh *pullToRefreshView;
@property (nonatomic, strong) SVPullToRefresh *infiniteScrollingView;

@property (nonatomic, assign) BOOL showsPullToRefresh;
@property (nonatomic, assign) BOOL showsInfiniteScrolling;

@end