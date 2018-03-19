//
//  FSClient.h
//  Tracker
//
//  Created by Parker Wightman on 11/27/12.
//  Copyright (c) 2012 Mysterious Trousers. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^FSFoodSearchBlock)(NSArray *foods, NSInteger maxResults, NSInteger totalResults, NSInteger pageNumber);

@class FSFood;

@interface FSClient : NSObject

@property (nonatomic, strong) NSString *oauthConsumerKey;
@property (nonatomic, strong) NSString *oauthConsumerSecret;


- (void)searchFoods:(NSString *)foodText
         pageNumber:(NSInteger)pageNumber
         maxResults:(NSInteger)maxResults
         language:(NSString *)language
         region:(NSString *)region
         completion:(FSFoodSearchBlock)completionBlock;

- (void)searchFoods:(NSString *)foodText
         pageNumber:(NSInteger)pageNumber
         maxResults:(NSInteger)maxResults
         completion:(FSFoodSearchBlock)completionBlock;

- (void)searchFoods:(NSString *)foodText language:(NSString *)language region:(NSString *)region completion:(FSFoodSearchBlock)completionBlock;

- (void)searchFoods:(NSString *)foodText completion:(FSFoodSearchBlock)completionBlock;

- (void)getFood:(NSInteger)foodId language:(NSString *)language region:(NSString *)region completion:(void (^)(FSFood *food))completionBlock;

+ (FSClient *)sharedClient;

@end
