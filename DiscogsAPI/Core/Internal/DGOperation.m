// DGOperation.m
//
// Copyright (c) 2017 Maxime Epain
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "DGOperation.h"

#import "DGEndpoint.h"
#import "DGMapping.h"

// The error domain for Discogs generated errors
NSString * const DGErrorDomain = @"com.discogs.api";

@interface DGOperation ()
@property (nonatomic, strong) RKMappingResult *mappingResult;
@end

@implementation DGOperation

@dynamic mappingResult;

+ (instancetype)operationWithRequest:(NSURLRequest *)request responseClass:(Class<DGResponseObject>)responseClass {
    return [[self alloc] initWithRequest:request responseClass:responseClass];
}

- (instancetype)initWithRequest:(NSURLRequest *)request responseClass:(Class<DGResponseObject>)responseClass {
    NSMutableArray *responseDescriptors = [NSMutableArray arrayWithObject:[NSError responseDescriptor]];
    if (responseClass) {
        [responseDescriptors addObject:[responseClass responseDescriptor]];
    }
    
    return [super initWithRequest:request responseDescriptors:responseDescriptors];
}

- (void)setCompletionBlockWithSuccess:(void (^)(id))success failure:(void (^)(NSError *))failure {
    
    __weak typeof(self) weakSelf = self;
    [super setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
        success(weakSelf.response);
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            NSMutableDictionary<NSString *, id> *userInfo = [NSMutableDictionary dictionary];

            NSString *description = error.userInfo[NSLocalizedDescriptionKey];
            if ([description length]) {
                userInfo[NSLocalizedDescriptionKey] = description;
            }

            if (operation) {
                userInfo[DGErrorRKObjectOperationKey] = operation;
            }
            
            NSInteger code = operation.HTTPRequestOperation.response.statusCode;
            failure([NSError errorWithDomain:DGErrorDomain code:code userInfo:userInfo]);
        }
    }];
}

- (void)setMappingResult:(RKMappingResult *)mappingResult {
    _mappingResult = mappingResult;
    
    id object = mappingResult.dictionary[[NSNull null]];
    if (object) {
        _response = object;
    } else {
        _response = mappingResult.array;
    }
}

@end

@implementation NSError (Discogs)

+ (instancetype)errorWithCode:(NSInteger)code description:(NSString *)description {
    return [self errorWithDomain:DGErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey : description}];
}

+ (RKResponseDescriptor *)responseDescriptor {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
    
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"message" toKeyPath:@"errorMessage"]];
    
    return [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassClientError)];
}

@end
