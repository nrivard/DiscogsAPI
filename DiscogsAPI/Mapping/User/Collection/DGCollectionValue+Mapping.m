//
//  DGCollectionValue+Mapping.m
//  DiscogsAPI
//
//  Created by Nate Rivard on 7/10/18.
//  Copyright © 2018 Maxime Epain. All rights reserved.
//

#import "DGCollectionValue+Mapping.h"

@implementation DGCollectionValue (Mapping)

+ (RKMapping *)mapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[DGCollectionValue class]];
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"maximum" : @"maximum",
                                                  @"median"  : @"median",
                                                  @"minimum" : @"minimum"
                                                  }];
    return mapping;
}

+ (RKResponseDescriptor *)responseDescriptor {
    return [RKResponseDescriptor responseDescriptorWithMapping:[DGCollectionValue mapping] method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
}

@end


@implementation DGCollectionValueRequest (Mapping)

- (NSDictionary *)parameters {
    return nil;
}

@end
