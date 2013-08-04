//
//  main.m
//  ClassDump Service
//
//  Created by Damien DeVille on 8/3/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#include <Foundation/Foundation.h>

#import "_CDClassDumpServer.h"

int main(int argc, const char **argv)
{
    NSXPCListener *listener = [NSXPCListener serviceListener];
    
    _CDClassDumpServer *classDumpServer = [[_CDClassDumpServer alloc] init];
    [listener setDelegate:classDumpServer];
    
    [listener resume];
    
    return 0;
}
