//
//  _CDClassDumpOperation.m
//  class-dump
//
//  Created by Damien DeVille on 8/3/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "_CDClassDumpInternalOperation.h"

#import "CDClassDump.h"
#import "CDSearchPathState.h"
#import "CDMultiFileVisitor.h"

#import "CDFile+Extensions.h"
#import "CDClassDump+Extensions.h"

#import "ClassDump-Constants.h"
#import "ClassDumpService-Constants.h"

@interface _CDClassDumpInternalOperation ()

@property (copy, nonatomic) NSURL *bundleOrExecutableLocation;
@property (copy, nonatomic) NSURL *exportDirectoryLocation;

@property (readwrite, copy, atomic) NSURL * (^completionProvider)(NSError **errorRef);

@end

@implementation _CDClassDumpInternalOperation

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
	NSError *executablePathRetrievalError = nil;
	NSString *executablePath = [self _retrieveExecutablePath:&executablePathRetrievalError];
	if (executablePath == nil) {
		[self _completeWithError:executablePathRetrievalError];
		return;
	}
	
	NSError *exportDirectoryCreationError = nil;
	NSString *exportDirectoryPath = [self _retrieveExportDirectoryPath:&exportDirectoryCreationError];
	if (exportDirectoryPath == nil) {
		[self _completeWithError:exportDirectoryCreationError];
		return;
	}
	
	[self _classDumpWithExecutablePath:executablePath exportDirectoryPath:exportDirectoryPath];
}

#pragma mark - Class dump

- (void)_classDumpWithExecutablePath:(NSString *)executablePath exportDirectoryPath:(NSString *)exportDirectoryPath
{
	CDClassDump *classDump = [[CDClassDump alloc] init];
	
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
	
	if (![classDump hasObjectiveCRuntimeInfo]) {
		NSDictionary *userInfo = @{
			NSLocalizedDescriptionKey : NSLocalizedStringFromTableInBundle(@"The executable doesn\u2019 contain any Objective-C runtime information", nil, [NSBundle bundleWithIdentifier:CDClassDumpServiceBundleIdentifier], @"_CDClassDumpOperation no objc runtime info error description"),
			NSLocalizedRecoverySuggestionErrorKey : NSLocalizedStringFromTableInBundle(@"Please make sure that the executable you have selected contains Objective-C runtime information.", nil, [NSBundle bundleWithIdentifier:CDClassDumpServiceBundleIdentifier], @"_CDClassDumpOperation no objc runtime info error recovery suggestion"),
        };
		NSError *error = [NSError errorWithDomain:CDClassDumpErrorDomain code:CDClassDumpErrorExecutableNoObjCRuntimeInfo userInfo:userInfo];
		
		[self _completeWithError:error];
		return;
	}
	
	CDMultiFileVisitor *multiFileVisitor = [[CDMultiFileVisitor alloc] init];
	[multiFileVisitor setClassDump:classDump];
	[multiFileVisitor setOutputPath:exportDirectoryPath];
	
	[[classDump typeController] setDelegate:multiFileVisitor];
	
	[classDump recursivelyVisit:multiFileVisitor];
	
	[self _completeWithExportDirectoryLocation:[self exportDirectoryLocation]];
}

#pragma mark - Path retrieval

- (NSString *)_retrieveExecutablePath:(NSError **)errorRef
{
	NSString *bundleOrExecutablePath = [[self bundleOrExecutableLocation] path];
	NSString *executablePath = [bundleOrExecutablePath executablePathForFilename];
	
	if (executablePath != nil) {
		return executablePath;
	}
	
	if (errorRef != NULL) {
		NSDictionary *userInfo = @{
			NSLocalizedDescriptionKey : NSLocalizedStringFromTableInBundle(@"The input file doesn\u2019t contain an executable", nil, [NSBundle bundleWithIdentifier:CDClassDumpServiceBundleIdentifier], @"_CDClassDumpOperation input file not executable error description"),
			NSLocalizedRecoverySuggestionErrorKey : NSLocalizedStringFromTableInBundle(@"Please make sure that the file you have selected is an executable, a framework or an application bundle.", nil, [NSBundle bundleWithIdentifier:CDClassDumpServiceBundleIdentifier], @"_CDClassDumpOperation input file not executable error recovery suggestion"),
        };
		*errorRef = [NSError errorWithDomain:CDClassDumpErrorDomain code:CDClassDumpErrorExecutableNotFound userInfo:userInfo];
	}
	
	return nil;
}

- (NSString *)_retrieveExportDirectoryPath:(NSError **)errorRef
{
	NSError *exportDirectoryCreationError = nil;
	BOOL exportDirectoryCreated = [[NSFileManager defaultManager] createDirectoryAtURL:[self exportDirectoryLocation] withIntermediateDirectories:YES attributes:nil error:&exportDirectoryCreationError];
	if (exportDirectoryCreated) {
		return [[self exportDirectoryLocation] path];
	}
	
	if (errorRef != NULL) {
		NSDictionary *userInfo = @{
			NSLocalizedDescriptionKey : NSLocalizedStringFromTableInBundle(@"Couldn\u2019t create the export directory", nil, [NSBundle bundleWithIdentifier:CDClassDumpServiceBundleIdentifier], @"_CDClassDumpOperation export directory creation error description"),
			NSLocalizedRecoverySuggestionErrorKey : NSLocalizedStringFromTableInBundle(@"There was an unknown error while creating the export directory. Please try again.", nil, [NSBundle bundleWithIdentifier:CDClassDumpServiceBundleIdentifier], @"_CDClassDumpOperation export directory creation error recovery suggestion"),
			NSUnderlyingErrorKey : exportDirectoryCreationError,
        };
		*errorRef = [NSError errorWithDomain:CDClassDumpErrorDomain code:CDClassDumpErrorExportDirectoryCreationError userInfo:userInfo];
	}
	
	return NO;
}

#pragma mark - Completion

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
