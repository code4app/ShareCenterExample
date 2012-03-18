//
//  CUTencentEngine.h
//  ShareCenterExample
//
//  Created by curer yg on 12-3-16.
//  Copyright (c) 2012年 zhubu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QWeiboRequest.h"

@class CUTencentEngine;
@protocol CUTencentEngineDelegate <NSObject>
@optional

- (void)engineDidLogIn:(CUTencentEngine *)engine;
- (void)engine:(CUTencentEngine *)engine didFailToLogInWithError:(NSError *)error;

- (void)engine:(CUTencentEngine *)engine requestDidFailWithError:(NSError *)error;
- (void)engine:(CUTencentEngine *)engine requestDidSucceedWithResult:(id)result;

@end

@interface CUTencentEngine : NSObject
{
    NSString *appKey;
	NSString *appSecret;
	NSString *tokenKey;
	NSString *tokenSecret;
	NSString *verifier;
    
    NSString *requestTokenKey;
    NSString *requestTokenSecret;
    
    QWeiboRequest *request;
    
    id<CUTencentEngineDelegate> delegate;
}

@property (nonatomic, copy) NSString *appKey;
@property (nonatomic, copy) NSString *appSecret;
@property (nonatomic, copy) NSString *tokenKey;
@property (nonatomic, copy) NSString *tokenSecret;
@property (nonatomic, copy) NSString *verifier;
@property (nonatomic, copy) NSString *requestTokenKey;
@property (nonatomic, copy) NSString *requestTokenSecret;

@property (nonatomic, assign) id<CUTencentEngineDelegate> delegate;

- (id)initWithAppKey:(NSString *)theAppKey appSecret:(NSString *)theAppSecret;

- (BOOL)parseTokenKeyWithResponse:(NSString *)aResponse;
- (BOOL)authorizeResponse:(NSString *)aResponse;

- (void)logOut;
- (BOOL)isLoggedIn;
- (BOOL)isAuthorizeExpired;

- (void)sendWeiBoWithText:(NSString *)text imageURL:(NSString *)url;

- (void)loadRequestWithMethodName:(NSString *)methodName
                       httpMethod:(NSString *)httpMethod
                           params:(NSDictionary *)params
                 httpHeaderFields:(NSDictionary *)httpHeaderFields;

@end
