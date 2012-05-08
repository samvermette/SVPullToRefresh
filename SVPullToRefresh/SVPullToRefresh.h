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
@property (nonatomic, strong) UIColor *bottomArrowColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, readwrite) UIActivityIndicatorViewStyle activityIndicatorViewStyle;
@property (nonatomic, strong) NSDate *lastUpdatedDate;
@property (nonatomic, readwrite) NSInteger sectionDisplayLimit;
@property (nonatomic, readwrite) NSInteger rowDisplayLimit;
@property (nonatomic, readonly) NSInteger portionsLoaded;

- (void)stopAnimating;

@end


// extends UIScrollView

@interface UIScrollView (SVPullToRefresh)

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler;
- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler andDragToLoadHandler:(void (^)(void))loadActionHandler;
- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler infiniteScrollActionHandler:(void(^)(void))infiniteScrollActionHandler;

@property (nonatomic, strong) SVPullToRefresh *pullToRefreshView;

@end