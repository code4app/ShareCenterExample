//
//  CUTencentEngine.m
//  ShareCenterExample
//
//  Created by curer yg on 12-3-16.
//  Copyright (c) 2012年 zhubu. All rights reserved.
//

#import "CUTencentEngine.h"
#import "NSURL+QAdditions.h"
#import "QWeiboSyncApi.h"
#import "SFHFKeychainUtils.h"
#import "NSString+SBJSON.h"

#define kWBURLSchemePrefix              @"WB_Tencent_"

#define kWBKeychainServiceNameSuffix    @"_WeiBoServiceName_Tencent"
#define kWBKeychainAppKey               @"WeiBoAppKey_Tencent"
#define kWBKeychainAppKeySecret         @"WeiBoAppKeySecret_Tencent"
#define kWBKeychainAccessToken          @"WeiBoAccessToken_Tencent"
#define kWBKeychainAccessTokenSecret    @"WeiBoAccessTokenSecret_Tencent"

#define kWBAPI_ADD                      @"http://open.t.qq.com/api/t/add"


@implementation CUTencentEngine

@synthesize appKey;
@synthesize appSecret;
@synthesize tokenKey;
@synthesize tokenSecret;
@synthesize verifier;
@synthesize delegate;
@synthesize requestTokenKey;
@synthesize requestTokenSecret;

- (id)initWithAppKey:(NSString *)theAppKey appSecret:(NSString *)theAppSecret
{
    if (self = [super init]) {
        self.appKey = theAppKey;
        self.appSecret = theAppSecret;
        
        [self readAuthorizeDataFromKeychain];
    }
    
    return self;
}

- (void)dealloc
{
    [appKey release];
	[appSecret release];
	[tokenKey release];
	[tokenSecret release];
	[verifier release];
    [requestTokenKey release];
    [requestTokenSecret release];
    
    [super dealloc];
}

- (BOOL)authorizeResponse:(NSString *)aResponse
{
    NSString *aVerifier = [self valueForKey:@"oauth_verifier" ofQuery:aResponse];
	
	if (aVerifier && ![aVerifier isEqualToString:@""]) {
		
		QWeiboSyncApi *api = [[[QWeiboSyncApi alloc] init] autorelease];
		NSString *result = [api getAccessTokenWithConsumerKey:self.appKey 
                                               consumerSecret:self.appSecret 
                                              requestTokenKey:self.requestTokenKey 
                                           requestTokenSecret:self.requestTokenSecret
                                                       verify:aVerifier];
		NSLog(@"\nget access token:%@", result);

        BOOL bRes = [self parseTokenKeyWithResponse:result];
        if (bRes) {
            [self saveAuthorizeDataToKeychain];
            
            if ([delegate respondsToSelector:@selector(engineDidLogIn:)])
            {
                [delegate engineDidLogIn:self];
            }
        }
        else {
            [self deleteAuthorizeDataInKeychain];
            
            if ([delegate respondsToSelector:@selector(engine:didFailToLogInWithError:)]) {
                [delegate engine:self didFailToLogInWithError:nil];
            }
        }
       		
		return YES;
	}

    return NO;
}    

- (BOOL)parseTokenKeyWithResponse:(NSString *)aResponse {
    
	NSDictionary *params = [NSURL parseURLQueryString:aResponse];
	self.tokenKey = [params objectForKey:@"oauth_token"];
	self.tokenSecret = [params objectForKey:@"oauth_token_secret"];
    
    return [self.tokenKey length] && [self.tokenSecret length];
}

- (BOOL)parseRequestTokenKeyWithResponse:(NSString *)aResponse {
    
	NSDictionary *params = [NSURL parseURLQueryString:aResponse];
	self.requestTokenKey = [params objectForKey:@"oauth_token"];
	self.requestTokenSecret = [params objectForKey:@"oauth_token_secret"];
    
    return [self.tokenKey length] && [self.tokenSecret length];
}

- (void)logOut
{
    [self deleteAuthorizeDataInKeychain];
}

- (BOOL)isLoggedIn
{
    return (appKey && self.tokenSecret && self.tokenKey && appSecret);
}

- (BOOL)isAuthorizeExpired
{
    return NO;
}

- (void)sendWeiBoWithText:(NSString *)text imageURL:(NSString *)url
{
    QWeiboSyncApi *api = [[[QWeiboSyncApi alloc] init] autorelease];
    
    NSString *resString = 
    [api publishMsgWithConsumerKey:self.appKey 
                    consumerSecret:self.appSecret 
                    accessTokenKey:self.tokenKey 
                 accessTokenSecret:self.tokenSecret 
                           content:text 
                          imageURL:url
                        resultType:RESULTTYPE_JSON];
    
    NSLog(@"%@", resString);
    
    id jsonObject = [resString JSONValue];
    
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        
        int ret = [[jsonObject objectForKey:@"ret"] intValue];
        
        if (ret == 0) {
            if ([delegate respondsToSelector:@selector(engine:requestDidSucceedWithResult:)])
            {
                [delegate engine:self requestDidSucceedWithResult:jsonObject];
            }
            
            return;
        }
    }
    
    if ([delegate respondsToSelector:@selector(engine:requestDidFailWithError:)]) {
        [delegate engine:self requestDidFailWithError:nil];
    }
}

- (void)loadRequestWithMethodName:(NSString *)methodName
                       httpMethod:(NSString *)httpMethod
                           params:(NSDictionary *)params
                 httpHeaderFields:(NSDictionary *)httpHeaderFields
{
    
}

#pragma mark -  private

- (NSString *)valueForKey:(NSString *)key ofQuery:(NSString *)query
{
	NSArray *pairs = [query componentsSeparatedByString:@"&"];
	for (NSString *aPair in pairs) 
    {
		NSArray *keyAndValue = [aPair componentsSeparatedByString:@"="];
		if([keyAndValue count] != 2) 
        {
            continue;
        }
		
        if([[keyAndValue objectAtIndex:0] isEqualToString:key])
        {
			return [keyAndValue objectAtIndex:1];
		}
	}
    
	return nil;
}

- (NSString *)urlSchemeString
{
    return [NSString stringWithFormat:@"%@%@", kWBURLSchemePrefix, appKey];
}

- (void)saveAuthorizeDataToKeychain
{
    NSString *serviceName = [[self urlSchemeString] stringByAppendingString:kWBKeychainServiceNameSuffix];
        
    [SFHFKeychainUtils storeUsername:kWBKeychainAccessToken 
                         andPassword:tokenKey
                      forServiceName:serviceName 
                      updateExisting:YES 
                               error:nil];

    [SFHFKeychainUtils storeUsername:kWBKeychainAccessTokenSecret 
                         andPassword:tokenSecret
                      forServiceName:serviceName 
                      updateExisting:YES 
                               error:nil];
}

- (void)readAuthorizeDataFromKeychain
{
    NSString *serviceName = [[self urlSchemeString] stringByAppendingString:kWBKeychainServiceNameSuffix];
    
    self.tokenKey = [SFHFKeychainUtils getPasswordForUsername:kWBKeychainAccessToken 
                                               andServiceName:serviceName 
                                                        error:nil];
    
    self.tokenSecret = [SFHFKeychainUtils getPasswordForUsername:kWBKeychainAccessTokenSecret 
                                                  andServiceName:serviceName 
                                                           error:nil];
}

- (void)deleteAuthorizeDataInKeychain
{
    self.tokenKey = nil;
    self.tokenSecret = nil;
    
    NSString *serviceName = [[self urlSchemeString] stringByAppendingString:kWBKeychainServiceNameSuffix];
	[SFHFKeychainUtils deleteItemForUsername:kWBKeychainAccessToken andServiceName:serviceName error:nil];
	[SFHFKeychainUtils deleteItemForUsername:kWBKeychainAccessTokenSecret andServiceName:serviceName error:nil];
}

@end
