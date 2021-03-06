//
//  FSClient.m
//  Tracker
//
//  Created by Parker Wightman on 11/27/12.
//  Copyright (c) 2012 Mysterious Trousers. All rights reserved.
//

#import "FSClient.h"
#import <CommonCrypto/CommonHMAC.h>
#import "OAuthCore.h"
#import "FSFood.h"

#define FAT_SECRET_API_ENDPOINT @"http://platform.fatsecret.com/rest/server.api"


@implementation FSClient

- (void)searchFoods:(NSString *)foodText
         pageNumber:(NSInteger)pageNumber
         maxResults:(NSInteger)maxResults
	 language:(NSString *)language
         region:(NSString *)region
         completion:(FSFoodSearchBlock)completionBlock {

    NSMutableDictionary *params = [@{
        @"search_expression" : foodText,
        @"page_number"       : @(pageNumber),
        @"max_results"       : @(maxResults),
	@"language"	     : language,
	@"region"	     : region
    } mutableCopy];

    [self makeRequestWithMethod:@"foods.search" parameters:params completion:^(NSDictionary *response) {
        NSMutableArray *foods = [@[] mutableCopy];

        id responseFoods = [response objectForKey:@"foods"];

        // Hack because the API sends JSON objects, instead of arrays, when there is only
        // one result. (WTF?)
        if ([[responseFoods objectForKey:@"food"] respondsToSelector:@selector(arrayByAddingObject:)]) {
            for (NSDictionary *food in [responseFoods objectForKey:@"food"]) {
                [foods addObject:[FSFood foodWithJSON:food]];
            }
        } else {
            if ([[responseFoods objectForKey:@"food"] count] == 0) {
                foods = [@[] mutableCopy];
            } else {
                foods = [@[ [FSFood foodWithJSON:[responseFoods objectForKey:@"food"]] ] mutableCopy];
            }
        }
        
        NSInteger maxResults   = [[[response objectForKey:@"foods"] objectForKey:@"max_results"]   integerValue];
        NSInteger totalResults = [[[response objectForKey:@"foods"] objectForKey:@"total_results"] integerValue];
        NSInteger pageNumber   = [[[response objectForKey:@"foods"] objectForKey:@"page_number"]   integerValue];
        
        completionBlock(foods, maxResults, totalResults, pageNumber);
    }];
}

- (void)searchFoods:(NSString *)foodText
         pageNumber:(NSInteger)pageNumber
         maxResults:(NSInteger)maxResults
         completion:(FSFoodSearchBlock)completionBlock {

     [self searchFoods:foodText
           pageNumber:0
           maxResults:20
           language:@"en"
           region:@"US"
           completion:completionBlock];
}

- (void)searchFoods:(NSString *)foodText completion:(FSFoodSearchBlock)completionBlock {
    [self searchFoods:foodText
           pageNumber:0
           maxResults:20
           completion:completionBlock];
}

- (void)searchFoods:(NSString *)foodText language:(NSString *)language region:(NSString *)region completion:(FSFoodSearchBlock)completionBlock {
    [self searchFoods:foodText
   	pageNumber:0
	maxResults:20
   	language:language
   	region:region
   	completion:completionBlock];
}

- (void)getFood:(NSInteger)foodId language:(NSString *)language region:(NSString *)region completion:(void (^)(FSFood *food))completionBlock {
    NSDictionary *params = @{@"food_id" : @(foodId), @"language": language, @"region": region};

    [self makeRequestWithMethod:@"food.get"
                     parameters:params
                     completion:^(NSDictionary *data) {
                         completionBlock([FSFood foodWithJSON:[data objectForKey:@"food"]]);
                     }];
}

- (void)getFood:(NSInteger)foodId completion:(void (^)(FSFood *food))completionBlock {
    NSDictionary *params = @{@"food_id" : @(foodId)};

    [self makeRequestWithMethod:@"food.get"
                     parameters:params
                     completion:^(NSDictionary *data) {
                         completionBlock([FSFood foodWithJSON:[data objectForKey:@"food"]]);
                     }];
}

- (void)getFoodByUPC:(NSString*)upc completion:(void (^)(FSFood *food))completionBlock{
    NSDictionary *params = @{@"barcode" : upc};
    
    [self makeRequestWithMethod:@"food.find_id_for_barcode"
                     parameters:params
                     completion:^(NSDictionary *data) {
                         NSInteger foodid = [[[data objectForKey:@"food_id"] objectForKey:@"value"] integerValue];
                         //completionBlock([FSFood foodWithJSON:[data objectForKey:@"food"]]);
                          NSDictionary *params2 = @{@"food_id" : @(foodid)};
                         [self makeRequestWithMethod:@"food.get"
                                          parameters:params2
                                          completion:^(NSDictionary *data) {
                                              completionBlock([FSFood foodWithJSON:[data objectForKey:@"food"]]);
                                          }];
                     }];
}

- (void) makeRequestWithMethod:(NSString *)method
                    parameters:(NSDictionary *)params
                    completion:(void (^)(NSDictionary *data))completionBlock {

    NSMutableDictionary *parameters = [params mutableCopy];
    [parameters addEntriesFromDictionary:[self defaultParameters]];
    [parameters addEntriesFromDictionary:@{ @"method" : method }];

    NSString *queryString = [self queryStringFromDictionary:parameters];
    NSData *data          = [NSData dataWithBytes:[queryString UTF8String] length:queryString.length];
    NSString *authHeader  = OAuthorizationHeader([NSURL URLWithString:FAT_SECRET_API_ENDPOINT], 
                                                 @"GET", 
                                                 data, 
                                                 _oauthConsumerKey, 
                                                 _oauthConsumerSecret, 
                                                 nil, 
                                                 @"");

	NSURL *url = [NSURL URLWithString:[FAT_SECRET_API_ENDPOINT stringByAppendingFormat:@"?%@", authHeader]];
	[[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		if (data) {
			id JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
			completionBlock(JSON);
		} else {
			completionBlock(nil);
		}
	}] resume];
}

- (NSDictionary *) defaultParameters {
    return @{ @"format": @"json" };
}

- (NSString *) queryStringFromDictionary:(NSDictionary *)dict {
    NSMutableArray *entries = [@[] mutableCopy];

    for (NSString *key in dict) {
        NSString *value = [dict objectForKey:key];
        [entries addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
    }

    return [entries componentsJoinedByString:@"&"];
}

static FSClient *_sharedClient = nil;

+ (FSClient *)sharedClient {
    if (!_sharedClient) {
        _sharedClient = [[FSClient alloc] init];
    }

    return _sharedClient;
}

@end
