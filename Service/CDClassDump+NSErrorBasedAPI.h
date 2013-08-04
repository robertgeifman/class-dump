//
//  CDClassDump+NSErrorBasedAPI.h
//  class-dump
//
//  Created by Damien DeVille on 8/3/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "CDClassDump.h"

@interface CDClassDump (NSErrorBasedAPI)

- (BOOL)fmw_loadFile:(CDFile *)file error:(NSError **)errorRef;

@end
