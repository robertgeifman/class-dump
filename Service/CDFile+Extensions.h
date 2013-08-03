//
//  CDFile+Extensions.h
//  class-dump
//
//  Created by Damien DeVille on 8/3/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "CDFile.h"

@interface CDFile (Extensions)

+ (id)fileWithContentsOfFile:(NSString *)filename searchPathState:(CDSearchPathState *)searchPathState error:(NSError **)errorRef;

- (BOOL)bestMatchForArch:(CDArch *)ioArchPtr error:(NSError **)errorRef;

@end
