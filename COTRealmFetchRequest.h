//
//  COTRealmFetchRequest.h
//
//  Created by Tyler Hall on 8/25/14.
//

#import <Foundation/Foundation.h>

@interface COTRealmFetchRequest : NSObject

@property (nonatomic, strong) NSString *entityName;
@property (nonatomic, strong) NSPredicate *predicate;
@property (nonatomic, strong) NSArray *sortDescriptors;

+ (COTRealmFetchRequest *)fetchRequestWithEntityName:(NSString *)entityName;

@end
