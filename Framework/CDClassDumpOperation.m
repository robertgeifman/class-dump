//
//  CDClassDumpOperation.m
//  class-dump
//
//  Created by Damien DeVille on 8/3/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "CDClassDumpOperation.h"

#import "_CDClassDumpServerInterface.h"

#import "ClassDump-Constants.h"
#import "ClassDumpService-Constants.h"

@interface CDClassDumpOperation ()

@property (copy, nonatomic) NSURL *bundleOrExecutableLocation;
@property (copy, nonatomic) NSURL *exportDirectoryLocation;

@property (strong, nonatomic) NSXPCConnection *connection;

@end

@interface CDClassDumpOperation (/* NSOperation */)

@property (assign, nonatomic) BOOL isExecuting, isFinished;

@property (readwrite, copy, atomic) NSURL * (^completionProvider)(NSError **errorRef);

@end

@implementation CDClassDumpOperation

- (id)initWithBundleOrExecutableLocation:(NSURL *)bundleOrExecutableLocation exportDirectoryLocation:(NSURL *)exportDirectoryLocation
{
	self = [self init];
	if (self == nil) {
		return nil;
	}
	
	NSParameterAssert(bundleOrExecutableLocation != nil);
	_bundleOrExecutableLocation = [bundleOrExecutableLocation copy];
	
	NSParameterAssert(exportDirectoryLocation != nil);
	_exportDirectoryLocation = [exportDirectoryLocation copy];
	
	_completionProvider = [^ NSURL * (NSError **errorRef) {
		if (errorRef != NULL) {
			*errorRef = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
		}
		return nil;
	} copy];
	
	NSXPCConnection *connection = [[NSXPCConnection alloc] initWithServiceName:CDClassDumpServiceName];
	[self setConnection:connection];
	
	NSXPCInterface *classDumpServerInterface = [NSXPCInterface interfaceWithProtocol:@protocol(_CDClassDumpServerInterface)];
	[classDumpServerInterface setClasses:[NSSet setWithObjects:[NSURL class], nil] forSelector:@selector(classDumpBundleOrExecutableAtLocation:exportDirectoryLocation:response:) argumentIndex:0 ofReply:NO];
	[classDumpServerInterface setClasses:[NSSet setWithObjects:[NSURL class], nil] forSelector:@selector(classDumpBundleOrExecutableAtLocation:exportDirectoryLocation:response:) argumentIndex:1 ofReply:NO];
	[classDumpServerInterface setClasses:[NSSet setWithObjects:[NSURL class], nil] forSelector:@selector(classDumpBundleOrExecutableAtLocation:exportDirectoryLocation:response:) argumentIndex:0 ofReply:YES];
	[classDumpServerInterface setClasses:[NSSet setWithObjects:[NSError class], nil] forSelector:@selector(classDumpBundleOrExecutableAtLocation:exportDirectoryLocation:response:) argumentIndex:1 ofReply:YES];
	
	[connection setRemoteObjectInterface:classDumpServerInterface];
	[connection resume];
	
	return self;
}

- (BOOL)isConcurrent
{
	return YES;
}

- (void)start
{
	void (^setExecuting)(BOOL) = ^ void (BOOL executing) {
		[self willChangeValueForKey:@"isExecuting"];
		[self setIsExecuting:executing];
		[self didChangeValueForKey:@"isExecuting"];
	};
	
	void (^setFinished)(BOOL) = ^ void (BOOL finished) {
		[self willChangeValueForKey:@"isFinished"];
		[self setIsFinished:finished];
		[self didChangeValueForKey:@"isFinished"];
	};
	
	if ([self isCancelled]) {
		setFinished(YES);
		return;
	}
	
	setExecuting(YES);
	
	[self _doAsynchronousWorkWithReacquirer:^ {
		setExecuting(NO);
		setFinished(YES);
	}];
}

- (void)_doAsynchronousWorkWithReacquirer:(void (^)(void))reacquirer
{
	id <_CDClassDumpServerInterface> classDumpServer = [[self connection] remoteObjectProxyWithErrorHandler:^ (NSError *error) {
		NSError *classDumpError = [self _remoteProxyObjectError:error];
		[self setCompletionProvider:^ id (NSError **errorRef) {
			if (errorRef != NULL) {
				*errorRef = classDumpError;
			}
			return nil;
		}];
		
		reacquirer();
	}];
	
	[classDumpServer classDumpBundleOrExecutableAtLocation:[self bundleOrExecutableLocation] exportDirectoryLocation:[self exportDirectoryLocation] response:^ (NSURL *exportDirectoryLocation, NSError *error) {
		[self setCompletionProvider:^ NSURL * (NSError **errorRef) {
			if (errorRef != NULL) {
				*errorRef = error;
			}
			return exportDirectoryLocation;
		}];
		
		reacquirer();
	}];
}

- (NSError *)_remoteProxyObjectError:(NSError *)error
{
	NSDictionary *userInfo = @{
		NSLocalizedDescriptionKey : NSLocalizedStringFromTableInBundle(@"Couldn\u2019t complete class-dump for this executable", nil, [NSBundle bundleWithIdentifier:CDClassDumpBundleIdentifier], @"CDClassDumpOperation XPC error description"),
		NSLocalizedRecoverySuggestionErrorKey : NSLocalizedStringFromTableInBundle(@"There was an unknown error when talking to a helper application.", nil, [NSBundle bundleWithIdentifier:CDClassDumpBundleIdentifier], @"CDClassDumpOperation XPC error recovery suggestion"),
		NSUnderlyingErrorKey : error,
	};
	return [NSError errorWithDomain:CDClassDumpErrorDomain code:CDClassDumpErrorXPCService userInfo:userInfo];
}

@end
