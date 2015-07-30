//
//  COTRealmFetchRequest.m
//
//  Created by Tyler Hall on 8/25/14.
//

#import "COTRealmFetchRequest.h"

@implementation COTRealmFetchRequest

+ (COTRealmFetchRequest *)fetchRequestWithEntityName:(NSString *)entityName
{
    COTRealmFetchRequest *fetchRequest = [[COTRealmFetchRequest alloc] init];
    fetchRequest.entityName = entityName;
    return fetchRequest;
}

@end
