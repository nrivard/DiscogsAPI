//
//  DGCollectionValue+Mapping.h
//  DiscogsAPI
//
//  Created by Nate Rivard on 7/10/18.
//  Copyright © 2018 Maxime Epain. All rights reserved.
//

#import "DGCollectionValue.h"
#import "DGMapping.h"

@interface DGCollectionValue (Mapping) <DGObject, DGResponseObject>
@end

@interface DGCollectionValueRequest (Mapping) <DGRequestObject>
@end
