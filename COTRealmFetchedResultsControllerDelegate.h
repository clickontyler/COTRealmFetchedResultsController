//
//  COTRealmFetchedResultsControllerDelegate.h
//
//  Created by Tyler Hall on 8/25/14.
//

#import <Foundation/Foundation.h>

@class COTRealmFetchedResultsController;

enum {
    COTRealmFetchedResultsControllerChangeTypeInsert = 1,
    COTRealmFetchedResultsControllerChangeTypeDelete = 2,
    COTRealmFetchedResultsControllerChangeTypeMove = 3,
    COTRealmFetchedResultsControllerChangeTypeUpdate = 4
};
typedef NSUInteger COTRealmFetchedResultsControllerChangeType;

@protocol COTRealmFetchedResultsControllerDelegate <NSObject>

- (void)controllerDidChangeContent:(COTRealmFetchedResultsController *)controller;

@optional

- (void)controllerWillChangeContent:(COTRealmFetchedResultsController *)controller;

- (NSString *)controller:(COTRealmFetchedResultsController *)controller sectionIndexTitleForSectionName:(NSString *)sectionName;

- (void)controller:(COTRealmFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(COTRealmFetchedResultsControllerChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath;

@end
