//
//  DAPageControl.m
//  DAPageControl
//
//  Created by Daria Kopaliani on 5/27/14.
//  Copyright (c) 2014 FactorialComplexity. All rights reserved.
//

#import "DAPageControlView.h"

#import "DAPageIndicatorViewCell.h"


static NSUInteger const FCMaximumIndicatorsCount = 21;
static CGFloat const FCMaximumIndicatorViewWidth = 14.;


@interface DAPageControlView () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
{
    NSUInteger _numberOfPages;
    NSUInteger _currentPage;
}

@property (strong, nonatomic) UICollectionView *indicatorsView;

@end


@implementation DAPageControlView


#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        /// Defaults
        self.numberOfPagesAllowingPerspective = 3;
        
        UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        collectionViewLayout.minimumInteritemSpacing = collectionViewLayout.minimumLineSpacing = 0.;
        self.indicatorsView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:collectionViewLayout];
        [self.indicatorsView registerClass:[DAPageIndicatorViewCell class] forCellWithReuseIdentifier:DAPageIndicatorViewCellIdentifier];
        self.indicatorsView.backgroundColor = [UIColor clearColor];
        self.indicatorsView.showsHorizontalScrollIndicator = NO;
        self.indicatorsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.indicatorsView.dataSource = self;
        self.indicatorsView.delegate = self;
        self.indicatorsView.scrollEnabled = YES;
        self.indicatorsView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.indicatorsView];
        
        [self.indicatorsView addObserver:self forKeyPath:@"contentOffset" options:0 context:nil];
        self.currentPage = 0;
    }
    
    return self;
}

- (void)dealloc
{
    [self.indicatorsView removeObserver:self forKeyPath:@"contentOffset"];
}

#pragma mark - Public

- (void)updateForScrollViewContentOffset:(CGFloat)contentOffset pageSize:(CGFloat)pageSize
{
    CGFloat currentIndex = contentOffset / pageSize;
    self.currentPage = roundf(currentIndex);
    
    CGFloat x = self.indicatorsView.contentSize.width * (currentIndex - floorf(0.5 * CGRectGetWidth(self.indicatorsView.frame) / [self indicatorViewWidth])) / self.numberOfPages;
    x = MIN((self.indicatorsView.contentSize.width - CGRectGetWidth(self.indicatorsView.frame)), MAX(0, x));
    self.indicatorsView.contentOffset = CGPointMake(x, 0.);
}

#pragma mark - Convenience Methods

- (void)adjustIndicatorsViewFrame
{
    CGFloat width = MIN(self.numberOfPages, [self maximumIndicatorsCount]) * [self indicatorViewWidth];
    self.indicatorsView.frame = CGRectMake(0.5 * (CGRectGetWidth(self.frame) - width), 0., width, CGRectGetHeight(self.frame));
}

- (CGFloat)indicatorViewWidth
{
    return FCMaximumIndicatorViewWidth;
}

- (NSUInteger)maximumIndicatorsCount
{
    NSUInteger count = floorf(CGRectGetWidth(self.frame) / (CGFloat)[self indicatorViewWidth]);
    
    return MIN(count, FCMaximumIndicatorsCount);
}

- (DAPageIndicatorViewCell *)visibleCellForIndex:(NSUInteger)index
{
    DAPageIndicatorViewCell *cell = nil;
    for (DAPageIndicatorViewCell *aCell in self.indicatorsView.visibleCells) {
        if (aCell.tag == index) {
            cell = aCell;
            break;
        }
    }
    
    return cell;
}

#pragma mark - Overwritten Setters

- (void)setCurrentPage:(NSUInteger)currentPage
{
    if (_currentPage != currentPage && currentPage < self.numberOfPages) {
        _currentPage = currentPage;
    }
    [self.indicatorsView.visibleCells enumerateObjectsUsingBlock:^(DAPageIndicatorViewCell *cell, NSUInteger idx, BOOL *stop) {
        cell.pageIndicatorButton.selected = (cell.tag == currentPage);
    }];
}

- (void)setDisplaysLoadingMoreEffect:(BOOL)displaysLoadingMoreEffect
{
    if (_displaysLoadingMoreEffect != displaysLoadingMoreEffect) {
        _displaysLoadingMoreEffect = displaysLoadingMoreEffect;
        DAPageIndicatorViewCell *cell = [self visibleCellForIndex:self.numberOfPages - 1];
        if (displaysLoadingMoreEffect) {
            [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveEaseInOut animations:^{
                cell.alpha = 0.5;
            } completion:nil];
        } else {
            cell.alpha = 1.;
            [cell.layer removeAllAnimations];
        }
    }
}

- (void)setHidesForSinglePage:(BOOL)hidesForSinglePage
{
    if (_hidesForSinglePage != hidesForSinglePage) {
        _hidesForSinglePage = hidesForSinglePage;
        self.indicatorsView.hidden = (self.numberOfPages <= 1);
    }
}

- (void)setNumberOfPages:(NSUInteger)numberOfPages
{
    if (_numberOfPages != numberOfPages) {
        _numberOfPages = numberOfPages;
        [self adjustIndicatorsViewFrame];
        [self.indicatorsView reloadData];
        self.indicatorsView.hidden = (self.numberOfPages <= 1);
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    CGFloat offset = self.indicatorsView.contentOffset.x;
    
    for (DAPageIndicatorViewCell *aCell in self.indicatorsView.visibleCells) {
        if (CGRectGetMinX(aCell.frame) < offset + self.numberOfPagesAllowingPerspective * [self indicatorViewWidth]) {
            if (offset == 0) {
                [UIView animateWithDuration:0.3 delay:0. options:0 animations:^{
                    aCell.pageIndicatorButton.transform = CGAffineTransformIdentity;
                } completion:nil];
            } else {
                CGFloat delta = CGRectGetMinX(aCell.frame) - (offset + self.numberOfPagesAllowingPerspective * [self indicatorViewWidth]);
                CGFloat scale = 1 - 0.6 * (fabsf(delta)) / (self.numberOfPagesAllowingPerspective * [self indicatorViewWidth]);
                aCell.pageIndicatorButton.transform = CGAffineTransformMakeScale(scale, scale);
            }
        } else {
            if (CGRectGetMaxX(aCell.frame) > offset + CGRectGetWidth(self.indicatorsView.frame) - (self.numberOfPagesAllowingPerspective * [self indicatorViewWidth])) {
                if (offset + CGRectGetWidth(self.indicatorsView.frame) == self.indicatorsView.contentSize.width) {
                    [UIView animateWithDuration:0.3 delay:0. options:0 animations:^{
                        aCell.pageIndicatorButton.transform = CGAffineTransformIdentity;
                    } completion:nil];
                } else {
                    CGFloat delta = (offset + CGRectGetWidth(self.indicatorsView.frame) - (self.numberOfPagesAllowingPerspective * [self indicatorViewWidth])) - CGRectGetMaxX(aCell.frame);
                    CGFloat scale = 1 - 0.6 * (fabsf(delta)) / (self.numberOfPagesAllowingPerspective * [self indicatorViewWidth]);
                    aCell.pageIndicatorButton.transform = CGAffineTransformMakeScale(scale, scale);
                }
            }
        }
    }
}

#pragma mark - UICollectionView Data Source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.numberOfPages;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DAPageIndicatorViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:DAPageIndicatorViewCellIdentifier forIndexPath:indexPath];
    cell.tag = indexPath.row;
    cell.pageIndicatorButton.selected = (indexPath.row == self.currentPage);
    
    if (indexPath.row == self.numberOfPages - 1) {
        if (self.displaysLoadingMoreEffect) {
            [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveEaseInOut animations:^{
                cell.alpha = 0.5;
            } completion:nil];
        } else {
            cell.alpha = 1.;
            [cell.layer removeAllAnimations];
        }
    }
    
    return cell;
}

#pragma mark - UICollectionView Delegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake([self indicatorViewWidth], CGRectGetHeight(self.frame));
}

@end