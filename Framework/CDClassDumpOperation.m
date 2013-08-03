//
//  CDClassDumpOperation.m
//  class-dump
//
//  Created by Damien DeVille on 8/3/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "CDClassDumpOperation.h"

#import "CDClassDump.h"
#import "CDSearchPathState.h"
#import "CDMultiFileVisitor.h"

#import "CDFile+Extensions.h"
#import "CDClassDump+Extensions.h"

#import "ClassDump-Constants.h"

@interface CDClassDumpOperation ()

@property (copy, nonatomic) NSURL *bundleOrExecutableLocation;
@property (copy, nonatomic) NSURL *exportDirectoryLocation;

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
	
	return self;
}

- (void)main
{
	CDClassDump *classDump = [[CDClassDump alloc] init];
	
	NSString *bundleOrExecutablePath = [[self bundleOrExecutableLocation] path];
	NSString *executablePath = [bundleOrExecutablePath executablePathForFilename];
	
	if (executablePath == nil) {
		NSDictionary *userInfo = @{
			NSLocalizedDescriptionKey : NSLocalizedStringFromTableInBundle(@"The input file doesn\u2019t contain an executable", nil, [NSBundle bundleWithIdentifier:CDClassDumpBundleIdentifier], @"CDClassDumpOperation input file not executable error description"),
			NSLocalizedRecoverySuggestionErrorKey : NSLocalizedStringFromTableInBundle(@"Please make sure that the file that you have selected is an executable, a framework or an application bundle.", nil, [NSBundle bundleWithIdentifier:CDClassDumpBundleIdentifier], @"CDClassDumpOperation input file not executable error recovery suggestion"),
		};
		NSError *error = [NSError errorWithDomain:CDClassDumpErrorDomain code:CDClassDumpErrorExecutableNotFound userInfo:userInfo];
		
		[self _completeWithError:error];
		return;
	}
    
	[[classDump searchPathState] setExecutablePath:[executablePath stringByDeletingLastPathComponent]];
    
	NSError *fileOpeningError = nil;
	CDFile *file = [CDFile fileWithContentsOfFile:executablePath searchPathState:[classDump searchPathState] error:&fileOpeningError];
	if (file == nil) {
		[self _completeWithError:fileOpeningError];
		return;
	}
	
	CDArch targetArchitecture;
	NSError *architectureRetrievalError = nil;
	BOOL architectureRetrieved = [file bestMatchForArch:&targetArchitecture error:&architectureRetrievalError];
	if (!architectureRetrieved) {
		[self _completeWithError:architectureRetrievalError];
		return;
	}
	
	[classDump setTargetArch:targetArchitecture];
	
	NSError *fileLoadingError = nil;
	BOOL fileLoaded = [classDump fmw_loadFile:file error:&fileLoadingError];
	if (!fileLoaded) {
		[self _completeWithError:fileLoadingError];
		return;
	}
	
	[classDump processObjectiveCData];
	[classDump registerTypes];
	
	CDMultiFileVisitor *multiFileVisitor = [[CDMultiFileVisitor alloc] init];
	[multiFileVisitor setClassDump:classDump];
	[multiFileVisitor setOutputPath:[[self exportDirectoryLocation] path]];
	
	[[classDump typeController] setDelegate:multiFileVisitor];
	
	[classDump recursivelyVisit:multiFileVisitor];
	
#warning There might be an error while visiting the file so we want to pass an error byref and fail if appropriate
	
	[self _completeWithExportDirectoryLocation:[self exportDirectoryLocation]];
}

- (void)_completeWithError:(NSError *)error
{
	[self setCompletionProvider:^ NSURL * (NSError **errorRef) {
		if (errorRef != NULL) {
			*errorRef = error;
		}
		return nil;
	}];
}

- (void)_completeWithExportDirectoryLocation:(NSURL *)exportDirectoryLocation
{
	[self setCompletionProvider:^ NSURL * (NSError **errorRef) {
		return exportDirectoryLocation;
	}];
}

@end
