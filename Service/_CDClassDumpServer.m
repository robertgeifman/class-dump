//
//  CDClassDumpServer.m
//  class-dump
//
//  Created by Damien DeVille on 8/3/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "_CDClassDumpServer.h"

#import "_CDClassDumpServerInterface.h"
#import "_CDClassDumpInternalOperation.h"

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

#pragma mark - _CDClassDumpServerInterface

- (void)classDumpBundleOrExecutableAtLocation:(NSURL *)bundleOrExecutableLocation exportDirectoryLocation:(NSURL *)exportDirectoryLocation response:(void (^)(NSURL *exportDirectoryLocation, NSError *error))response
{
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

#pragma mark - NSXPCListenerDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)connection
{
	[connection setExportedInterface:[NSXPCInterface interfaceWithProtocol:@protocol(_CDClassDumpServerInterface)]];
	[connection setExportedObject:self];
	[connection resume];
	
	return YES;
}

@end
