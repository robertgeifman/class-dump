// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

#import "CDClassDump.h"

#import <Foundation/Foundation.h>
#import "NSArray-Extensions.h"
#import "CDDylibCommand.h"
#import "CDMachOFile.h"
#import "CDObjCSegmentProcessor.h"

@implementation CDClassDump2

- (id)init;
{
    if ([super init] == nil)
        return nil;

    //machOFiles = [[NSMutableArray alloc] init];
    machOFilesByID = [[NSMutableDictionary alloc] init];
    objCSegmentProcessors = [[NSMutableArray alloc] init];

    return self;
}

- (void)dealloc;
{
    //[machOFiles release];
    [machOFilesByID release];
    [objCSegmentProcessors release];

    [super dealloc];
}

- (BOOL)shouldProcessRecursively;
{
    return shouldProcessRecursively;
}

- (void)setShouldProcessRecursively:(BOOL)newFlag;
{
    shouldProcessRecursively = newFlag;
}

- (void)processFilename:(NSString *)aFilename;
{
    CDMachOFile *aMachOFile;
    CDObjCSegmentProcessor *aProcessor;

    NSLog(@" > %s", _cmd);
    NSLog(@"aFilename: %@", aFilename);

    aMachOFile = [[CDMachOFile alloc] initWithFilename:aFilename];
    [aMachOFile setDelegate:self];
    [aMachOFile process];

    aProcessor = [[CDObjCSegmentProcessor alloc] initWithMachOFile:aMachOFile];
    [aProcessor process];
    //NSLog(@"Formatted result:\n%@", [aProcessor formattedStringByClass]);
    [objCSegmentProcessors addObject:aProcessor];
    [aProcessor release];

    //[machOFiles addObject:aMachOFile];
    [machOFilesByID setObject:aMachOFile forKey:aFilename];

    [aMachOFile release];

    NSLog(@"<  %s", _cmd);
}

- (void)doSomething;
{
    NSLog(@"machOFilesByID keys: %@", [[machOFilesByID allKeys] description]);
    //NSLog(@"machOFiles in order: %@", [[machOFiles arrayByMappingSelector:@selector(filename)] description]);
    NSLog(@"objCSegmentProcessors in order: %@", [objCSegmentProcessors description]);

    {
        NSMutableString *resultString;
        int count, index;

        resultString = [[NSMutableString alloc] init];
        [self appendHeaderToString:resultString];

        count = [objCSegmentProcessors count];
        for (index = 0; index < count; index++) {
            //[resultString appendString:@"----------------------------------------------------------------------\n"];
            //[resultString appendFormat:@"file: %@\n", [objCSegmentProcessors objectAtIndex:index]];
            //[resultString appendString:@"----------------------------------------------------------------------\n"];
            [[objCSegmentProcessors objectAtIndex:index] appendFormattedStringSortedByClass:resultString];
        }

#if 1
        NSLog(@"formatted result:\n%@", resultString);
#else
        // For sampling
        NSLog(@"Done...........");
        sleep(5);
#endif
        [resultString release];
    }
}

- (CDMachOFile *)machOFileWithID:(NSString *)anID;
{
    CDMachOFile *aMachOFile;

    NSLog(@" > %s", _cmd);
    NSLog(@"anID: %@", anID);

    aMachOFile = [machOFilesByID objectForKey:anID];
    if (aMachOFile == nil) {
        [self processFilename:anID];
        aMachOFile = [machOFilesByID objectForKey:anID];
    }
    NSLog(@"<  %s", _cmd);

    return aMachOFile;
}

- (void)machOFile:(CDMachOFile *)aMachOFile loadDylib:(CDDylibCommand *)aDylibCommand;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"aDylibCommand: %@", aDylibCommand);

    if ([aDylibCommand cmd] == LC_LOAD_DYLIB && shouldProcessRecursively == YES) {
        NSLog(@"Load it!");
        [self machOFileWithID:[aDylibCommand name]];
    }

    NSLog(@"<  %s", _cmd);
}

- (void)appendHeaderToString:(NSMutableString *)resultString;
{
    [resultString appendString:@"/*\n"];
    [resultString appendString:@" *     Generated by class-dump (version 3.0 alpha).\n"];
    [resultString appendString:@" *\n"];
    [resultString appendString:@" *     class-dump is Copyright (C) 1997, 1999-2001, 2003 by Steve Nygard.\n"];
    [resultString appendString:@" */\n\n"];
}

@end