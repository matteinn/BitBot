//
//  BRLogsDataSource.m
//  Bitrise
//
//  Created by Deszip on 10/02/2019.
//  Copyright © 2019 Bitrise. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "AMR_ANSIEscapeHelper.h"

#import "BRLogsDataSource.h"

#import "BRMacro.h"
#import "BRLogLine+CoreDataClass.h"
#import "BRLogStep+CoreDataClass.h"

#import "BRLogLineView.h"
#import "BRLogStepView.h"

@interface BRLogsDataSource () <NSOutlineViewDataSource, NSOutlineViewDelegate, NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) NSOutlineView *outlineView;
@property (weak, nonatomic) NSTextView *textView;

@property (strong, nonatomic) NSPersistentContainer *container;
@property (strong, nonatomic) NSFetchedResultsController *stepFRC;
@property (strong, nonatomic) NSFetchedResultsController *logFRC;

@property (copy, nonatomic) NSString *buildSlug;

@end

@implementation BRLogsDataSource

- (instancetype)initWithContainer:(NSPersistentContainer *)container {
    if (self = [super init]) {
        _container = container;
    }
    
    return self;
}

- (void)buildFRC:(NSManagedObjectContext *)context buildSlug:(NSString *)buildSlug {
    NSFetchRequest *stepsRequest = [BRLogStep fetchRequest];
    stepsRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]];
    stepsRequest.predicate = [NSPredicate predicateWithFormat:@"log.build.slug = %@", buildSlug];
    [context setAutomaticallyMergesChangesFromParent:YES];
    self.stepFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:stepsRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    [self.stepFRC setDelegate:self];
    
    NSFetchRequest *linesRequest = [BRLogLine fetchRequest];
    linesRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"chunkPosition" ascending:YES],
                                     [NSSortDescriptor sortDescriptorWithKey:@"linePosition" ascending:YES]];
    linesRequest.predicate = [NSPredicate predicateWithFormat:@"log.build.slug = %@", buildSlug];
    [context setAutomaticallyMergesChangesFromParent:YES];
    self.logFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:linesRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    [self.logFRC setDelegate:self];
}

- (void)fetch:(NSString *)buildSlug {
    if (!self.logFRC || ![self.buildSlug isEqualToString:buildSlug]) {
        self.buildSlug = buildSlug;
        [self buildFRC:self.container.viewContext buildSlug:buildSlug];
    }
    
    NSError *fetchError = nil;
    if (![self.stepFRC performFetch:&fetchError]) {
        NSLog(@"Failed to fetch steps: %@ - %@", buildSlug, fetchError);
    }
    if (![self.logFRC performFetch:&fetchError]) {
        NSLog(@"Failed to fetch logs: %@ - %@", buildSlug, fetchError);
    }
    
    [self updateContent];
}

- (void)bindOutlineView:(NSOutlineView *)outlineView {
    _outlineView = outlineView;
    self.outlineView.dataSource = self;
    self.outlineView.delegate = self;
    [self.outlineView reloadData];
}

- (void)bindTextView:(NSTextView *)textView {
    _textView = textView;
}

#pragma mark - Log updates -

- (void)updateContent {
    [self.outlineView reloadData];
    [self.outlineView scrollToEndOfDocument:self];
    
    BOOL hasSelection = self.textView.selectedRange.length > 0;
    if (hasSelection) {
        return;
    }
    
    BOOL needsScroll = (NSMaxY(self.textView.bounds) - NSMaxY(self.textView.visibleRect)) < 100;
    NSString *insertion = [self contentFromLine:0];
    //[self.textView setString:insertion];
    
    AMR_ANSIEscapeHelper *helper = [AMR_ANSIEscapeHelper new];
    NSAttributedString *attrLine = [helper attributedStringWithANSIEscapedString:insertion];
    [[self.textView textStorage] appendAttributedString:attrLine];
    
    if (needsScroll) {
        [(NSScrollView *)self.textView.superview.superview setScrollsDynamically:NO];
        [self.textView scrollToEndOfDocument:self];
        //[self.textView scrollRangeToVisible:NSMakeRange(self.textView.string.length, 0)];
    }
}

#pragma mark - Text processing -

- (NSString *)contentFromLine:(NSUInteger)startLine {
    NSUInteger lineCount = [[self.logFRC.sections[0] objects] count];
    NSMutableString *content = [@"" mutableCopy];
    for (NSUInteger lineIndex = startLine; lineIndex < lineCount; lineIndex++) {
        BRLogLine *line = [self.logFRC objectAtIndexPath:[NSIndexPath indexPathForItem:lineIndex inSection:0]];
        if (line) {
            [content appendString:line.text];
        }
    }
    
    return content;
}

#pragma mark - NSOutlineViewDataSource -

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if ([item isKindOfClass:[BRLogStep class]]) {
        return [[(BRLogStep *)item lines] objectAtIndex:index];
    }
    
    return [self.stepFRC.sections[0] objects][index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return [item isKindOfClass:[BRLogStep class]];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if ([item isKindOfClass:[BRLogStep class]]) {
        return [[(BRLogStep *)item lines] count];
    }
    
    return [[self.stepFRC.sections[0] objects] count];
}

#pragma mark - NSOutlineViewDelegate -

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item {
    if ([item isKindOfClass:[BRLogLine class]]) {
        BRLogLine *line = (BRLogLine *)item;
        BRLogLineView *cell = [outlineView makeViewWithIdentifier:@"BRLogLineView" owner:self];
        NSString *logLine = [line.text stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        
        //[cell.lineLabel setStringValue:logLine];
        
        AMR_ANSIEscapeHelper *helper = [AMR_ANSIEscapeHelper new];
        [cell.lineLabel setAttributedStringValue:[helper attributedStringWithANSIEscapedString:logLine]];
        
        return cell;
    }
    
    if ([item isKindOfClass:[BRLogStep class]]) {
        BRLogStep *step = (BRLogStep *)item;
        BRLogStepView *cell = [outlineView makeViewWithIdentifier:@"BRLogStepView" owner:self];
        [cell.stepLabel setStringValue:step.name];
        
        return cell;
    }
    
    return nil;
}

#pragma mark - NSFetchedResultsControllerDelegate -

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self updateContent];
}

@end
