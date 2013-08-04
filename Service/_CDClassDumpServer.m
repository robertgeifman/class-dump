//
//  CDClassDumpServer.m
//  class-dump
//
//  Created by Damien DeVille on 8/3/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "_CDClassDumpServer.h"

#import "CDClassDumpServerInterface.h"

#import "_CDClassDumpInternalOperation.h"

#import "ClassDump-Constants.h"
#import "ClassDumpService-Constants.h"

@interface _CDClassDumpServer ()

@property (strong, nonatomic) NSOperationQueue *operationQueue;

@end

@implementation _CDClassDumpServer

- (id)init
{
	self = [super init];
	if (self == nil) {
		return nil;
	}
	
	_operationQueue = [[NSOperationQueue alloc] init];
	
	return self;
}

#pragma mark - CDClassDumpServerInterface

- (void)classDumpBundleOrExecutableAtLocation:(NSURL *)bundleOrExecutableLocation exportDirectoryBookmarkData:(NSData *)exportDirectoryBookmarkData response:(void (^)(NSURL *exportDirectoryLocation, NSError *error))response
{
	NSError *exportLocationRetrievalError = nil;
	NSURL *exportDirectoryLocation = [self _retrieveExportDirectoryLocation:exportDirectoryBookmarkData error:&exportLocationRetrievalError];
	if (exportDirectoryLocation == nil) {
		response(nil, exportLocationRetrievalError);
		return;
	}
	
	_CDClassDumpInternalOperation *classDumpOperation = [[_CDClassDumpInternalOperation alloc] initWithBundleOrExecutableLocation:bundleOrExecutableLocation exportDirectoryLocation:exportDirectoryLocation];
	[[self operationQueue] addOperation:classDumpOperation];
	
	NSOperation *responseOperation = [NSBlockOperation blockOperationWithBlock:^ {
		NSError *classDumpError = nil;
		NSURL *exportLocation = [classDumpOperation completionProvider](&classDumpError);
		response(exportLocation, classDumpError);
	}];
	[responseOperation addDependency:classDumpOperation];
	[[self operationQueue] addOperation:responseOperation];
}

#pragma mark - Private

- (NSURL *)_retrieveExportDirectoryLocation:(NSData *)exportDirectoryBookmarkData error:(NSError **)errorRef
{
	NSError *exportLocationRetrievalError = nil;
	NSURL *exportDirectoryLocation = [NSURL URLByResolvingBookmarkData:exportDirectoryBookmarkData options:(NSURLBookmarkResolutionOptions)0 relativeToURL:nil bookmarkDataIsStale:NULL error:&exportLocationRetrievalError];
	if (exportDirectoryLocation == nil) {
		if (errorRef != NULL) {
			NSDictionary *userInfo = @{
				NSLocalizedDescriptionKey : NSLocalizedStringFromTableInBundle(@"Couldn\u2019t create the export directory", nil, [NSBundle bundleWithIdentifier:CDClassDumpServiceBundleIdentifier], @"_CDClassDumpServer export directory creation error description"),
				NSLocalizedRecoverySuggestionErrorKey : NSLocalizedStringFromTableInBundle(@"There was an unknown error while creating the export directory. Please try again.", nil, [NSBundle bundleWithIdentifier:CDClassDumpServiceBundleIdentifier], @"_CDClassDumpServer export directory creation error recovery suggestion"),
				NSUnderlyingErrorKey : exportLocationRetrievalError,
			};
			*errorRef = [NSError errorWithDomain:CDClassDumpErrorDomain code:CDClassDumpErrorExportDirectoryCreationError userInfo:userInfo];
		}
		return nil;
	}
	
	return exportDirectoryLocation;
}

#pragma mark - NSXPCListenerDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)connection
{
	[connection setExportedInterface:[NSXPCInterface interfaceWithProtocol:@protocol(CDClassDumpServerInterface)]];
	[connection setExportedObject:self];
	[connection resume];
	
	return YES;
}

@end
