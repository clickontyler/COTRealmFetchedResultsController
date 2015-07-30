//
//  COTFetchedResultsController.m
//
//  Created by Tyler Hall on 8/25/14.
//

#import "COTRealmFetchedResultsController.h"

@interface COTRealmFetchedResultsController ()

@property (nonatomic, strong) RLMNotificationToken *notificationToken;

@end

@implementation COTRealmFetchedResultsController

- (void)dealloc
{
    [self endObservingRealmNotifications];
}

- (id)initWithFetchRequest:(COTRealmFetchRequest *)fetchRequest realmPath:(NSString *)realmPath
{
    self = [self initWithFetchRequest:fetchRequest
                            realmPath:realmPath
                   sectionNameKeyPath:nil];
    return self;
}

- (id)initWithFetchRequest:(COTRealmFetchRequest *)fetchRequest realmPath:(NSString *)realmPath sectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    self = [super init];
    if(self) {
        self.fetchRequest = fetchRequest;
        self.realmPath = realmPath;
        self.sectionNameKeyPath = sectionNameKeyPath;
        [self beginObservingRealmNotifications];
    }
    return self;
}

- (RLMRealm *)realm
{
    if(self.realmPath) {
        return [RLMRealm realmWithPath:self.realmPath];
    }

    return [RLMRealm defaultRealm];
}

- (BOOL)performFetch:(NSError **)error
{
    // Get the class of the objects we want to fetch
    Class entityClass = NSClassFromString(self.fetchRequest.entityName);

    // Fetch the request - either with a predicate or all objects of the class
    RLMResults *newlyFetchedObjects;
    if(self.fetchRequest.predicate) {
        newlyFetchedObjects = [entityClass performSelector:@selector(objectsWithPredicate:) withObject:self.fetchRequest.predicate];
    } else {
        newlyFetchedObjects = [entityClass performSelector:@selector(allObjects)];
    }

    // Sort our objects if given a sortDescriptor
    NSSortDescriptor *sortDescriptor = [self.fetchRequest.sortDescriptors firstObject];
    if(sortDescriptor) {
        newlyFetchedObjects = [newlyFetchedObjects sortedResultsUsingProperty:sortDescriptor.key ascending:sortDescriptor.ascending];
    }

    // Parse our objects into the appropriate sections
    NSArray *sections = [self parseObjectsIntoSections:newlyFetchedObjects];
    if(self.sections) { // Don't notify of changes if first time loading objects
        [self computeChangesBetweenOldSections:self.sections newSections:sections];
    }
    
    // Inform the delegate that things are about to change.
    if(self.delegate && [self.delegate respondsToSelector:@selector(controllerWillChangeContent:)]) {
        [self.delegate controllerWillChangeContent:self];
    }

    self.fetchedObjects = newlyFetchedObjects;
    self.sections = sections;

    // Inform the delegate that things changed.
    if(self.delegate && [self.delegate respondsToSelector:@selector(controllerDidChangeContent:)]) {
        [self.delegate controllerDidChangeContent:self];
    }

    return YES;
}

- (NSArray *)parseObjectsIntoSections:(RLMResults *)objects
{
    if(!self.sectionNameKeyPath) {
        // If we only have one section, things are simple...
        COTRealmFetchedResultsSectionInfo *sectionInfo = [[COTRealmFetchedResultsSectionInfo alloc] init];
        sectionInfo.objects = objects;
        return @[ sectionInfo ];
    } else {
        // If we have multiple sections...
        NSMutableDictionary *tempSectionsDict = [NSMutableDictionary dictionary];
        NSMutableArray *tempKeysArray = [NSMutableArray array];
        for(RLMObject *object in objects) {
            NSString *key = [object valueForKeyPath:self.sectionNameKeyPath];

            // Sort the objects into a temporary dictionary of arrays based
            // on the sectionKeyName value we derived above.
            if([tempSectionsDict valueForKeyPath:key]) {
                // Simply add the object if the keyed array already exists
                [tempSectionsDict[key] addObject:object];
            } else {
                // Created the keyed array the first time we encounter that key
                [tempKeysArray addObject:key];
                tempSectionsDict[key] = [NSMutableArray arrayWithObject:object];
            }
        }

        // Once all the fetched objects are sorted, create sectionInfos for each section
        NSMutableArray *mutableSections = [NSMutableArray array];
        for(NSString *key in tempKeysArray) {
            COTRealmFetchedResultsSectionInfo *sectionInfo = [[COTRealmFetchedResultsSectionInfo alloc] init];
            sectionInfo.objects = tempSectionsDict[key];
            sectionInfo.name = key;

            if(self.delegate && [self.delegate respondsToSelector:@selector(controller:sectionIndexTitleForSectionName:)]) {
                sectionInfo.indexTitle = [self.delegate controller:self sectionIndexTitleForSectionName:sectionInfo.name];
            } else {
                if(sectionInfo.name.length > 0) {
                    NSString *firstLetter = [sectionInfo.name substringWithRange:NSMakeRange(0, 1)];
                    sectionInfo.indexTitle = [firstLetter uppercaseString];
                }
            }
            
            [mutableSections addObject:sectionInfo];
        }

        NSArray *sections = [NSArray arrayWithArray:mutableSections];
        return sections;
    }
}

- (void)computeChangesBetweenOldSections:(NSArray *)oldSections newSections:(NSArray *)newSections
{
    // ========== Find New Objects (Additions) ============

    // For each section...
    for(NSUInteger sectionIndex = 0; sectionIndex < newSections.count; sectionIndex++ ) {
        COTRealmFetchedResultsSectionInfo *section = newSections[sectionIndex];
        // For each object in that section...
        for(NSUInteger objectIndex = 0; objectIndex < section.objects.count; objectIndex++) {
            RLMObject *object = [section.objects objectAtIndex:objectIndex];
            NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:objectIndex inSection:sectionIndex];
            // Does it exist in the old dataset?
            NSIndexPath *oldIndexPath = [self indexPathOfObject:object inSectionArray:oldSections];
            // If not, then it's new!
            if(!oldIndexPath) {
                if([self.delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
                    [self.delegate controller:self
                              didChangeObject:object
                                  atIndexPath:nil
                                forChangeType:COTRealmFetchedResultsControllerChangeTypeInsert
                                 newIndexPath:newIndexPath];
                }
            }
        }
    }

    // ========== Find Missing Objects (Deletions) and Moved Objects ============
    
    // For each section...
    for(NSUInteger oldSectionIndex = 0; oldSectionIndex < oldSections.count; oldSectionIndex++ ) {
        COTRealmFetchedResultsSectionInfo *oldSection = oldSections[oldSectionIndex];
        // For each object in that section...
        for(NSUInteger oldObjectIndex = 0; oldObjectIndex < oldSection.objects.count; oldObjectIndex++) {
            RLMObject *oldObject = [oldSection.objects objectAtIndex:oldObjectIndex];
            NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:oldObjectIndex inSection:oldSectionIndex];
            // Does it exist in the new dataset?
            NSIndexPath *newIndexPath = [self indexPathOfObject:oldObject inSectionArray:newSections];
            // If not, then it's been deleted!
            if(!newIndexPath) {
                if([self.delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
                    [self.delegate controller:self
                              didChangeObject:oldObject
                                  atIndexPath:oldIndexPath
                                forChangeType:COTRealmFetchedResultsControllerChangeTypeDelete
                                 newIndexPath:nil];
                }
            } else {
                // Has it changed position? Then it's moved!
                if([oldIndexPath compare:newIndexPath] != NSOrderedSame) {
                    if([self.delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
                        [self.delegate controller:self
                                  didChangeObject:oldObject
                                      atIndexPath:oldIndexPath
                                    forChangeType:COTRealmFetchedResultsControllerChangeTypeMove
                                     newIndexPath:newIndexPath];
                    }
                }
            }
        }
    }
}

- (NSIndexPath *)indexPathOfObject:(RLMObject *)object inSectionArray:(NSArray *)sections
{
    for(NSUInteger sectionIndex = 0; sectionIndex < sections.count; sectionIndex++ ) {
        COTRealmFetchedResultsSectionInfo *section = sections[sectionIndex];
        NSUInteger indexOfObject = [section.objects indexOfObject:object];
        if(indexOfObject != NSNotFound) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexOfObject inSection:sectionIndex];
            return indexPath;
        }
    }

    return nil;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section < self.sections.count) {
        COTRealmFetchedResultsSectionInfo *sectionInfo = self.sections[indexPath.section];
        if(indexPath.row < sectionInfo.objects.count) {
            return sectionInfo.objects[indexPath.row];
        }
    }

    return nil;
}

- (void)beginObservingRealmNotifications
{
    self.notificationToken = [[self realm] addNotificationBlock:^(NSString *notification, RLMRealm *realm) {
        [self performFetch:nil];
    }];
}

- (void)endObservingRealmNotifications
{
    [[self realm] removeNotification:self.notificationToken];
}

@end
