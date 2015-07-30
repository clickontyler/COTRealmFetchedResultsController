//
//  COTRealmFetchedResultsSectionInfo.h
//
//  Created by Tyler Hall on 8/25/14.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

@interface COTRealmFetchedResultsSectionInfo : NSObject

@property (nonatomic, strong) NSString *indexTitle;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) RLMResults *objects;
@property (nonatomic, readonly) NSUInteger numberOfObjects;

@end
