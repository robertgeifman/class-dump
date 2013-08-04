//
//  CDFile+NSErrorBasedAPI.h
//  class-dump
//
//  Created by Damien DeVille on 8/3/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "CDFile.h"

@interface CDFile (NSErrorBasedAPI)

+ (id)fmw_fileWithContentsOfFile:(NSString *)filename searchPathState:(CDSearchPathState *)searchPathState error:(NSError **)errorRef;

- (BOOL)fmw_bestMatchForArch:(CDArch *)ioArchPtr error:(NSError **)errorRef;

@end
