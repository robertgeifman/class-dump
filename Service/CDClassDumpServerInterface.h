//
//  CDClassDumpServerInterface.h
//  class-dump
//
//  Created by Damien DeVille on 8/3/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CDClassDumpServerInterface <NSObject>

- (void)classDumpBundleOrExecutableAtLocation:(NSURL *)bundleOrExecutableLocation exportDirectoryBookmarkData:(NSData *)exportDirectoryBookmarkData response:(void (^)(NSURL *exportDirectoryLocation, NSError *error))response;

@end
