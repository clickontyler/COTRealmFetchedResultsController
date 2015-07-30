//
//  COTFetchedResultsController.h
//
//  Created by Tyler Hall on 8/25/14.
//

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>

#import "COTRealmFetchedResultsControllerDelegate.h"
#import "COTRealmFetchRequest.h"
#import "COTRealmFetchedResultsSectionInfo.h"

@class COTRealmFetchRequest;

@interface COTRealmFetchedResultsController : NSObject

@property (nonatomic, weak) id <COTRealmFetchedResultsControllerDelegate> delegate;
@property (nonatomic, strong) COTRealmFetchRequest *fetchRequest;
@property (nonatomic, strong) NSString *realmPath;
@property (nonatomic, strong) RLMResults *fetchedObjects;
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSString *sectionNameKeyPath;

- (id)initWithFetchRequest:(COTRealmFetchRequest *)fetchRequest realmPath:(NSString *)realmPath;
- (id)initWithFetchRequest:(COTRealmFetchRequest *)fetchRequest realmPath:(NSString *)realmPath sectionNameKeyPath:(NSString *)sectionNameKeyPath;
- (BOOL)performFetch:(NSError **)error;
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

@end
