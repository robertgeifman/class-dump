//
//  ClassDump-Constants.h
//  class-dump
//
//  Created by Damien DeVille on 8/3/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const CDClassDumpBundleIdentifier;

typedef NS_ENUM(NSInteger, CDClassDumpErrorCode) {
	CDClassDumpUnknownError = 0,
	
	CDClassDumpErrorExecutableNotFound = -100,
	CDClassDumpErrorExecutableNotReadable = -101,
	CDClassDumpErrorExecutableUnsupportedType = -101,
	CDClassDumpErrorExecutableNoObjCRuntimeInfo = -102,
	
	CDClassDumpErrorCannotRetrieveArch = -200,
	
	CDClassDumpErrorFileLoading = -300,
	
	CDClassDumpErrorExportDirectoryCreationError = -400,
};

extern NSString * const CDClassDumpErrorDomain;
