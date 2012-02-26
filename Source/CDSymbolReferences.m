// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDSymbolReferences.h"

@interface CDSymbolReferences ()

@property (readonly) NSMutableDictionary *frameworkNamesByClassName;    // NSString (class name)    -> NSString (framework name)

@property (readonly) NSMutableSet *classes;
@property (readonly) NSMutableSet *protocols;

@property (nonatomic, readonly) NSArray *classesSortedByName;
@property (nonatomic, readonly) NSArray *protocolsSortedByName;

- (void)_appendToString:(NSMutableString *)resultString;

@end

#pragma mark -

@implementation CDSymbolReferences
{
    NSMutableDictionary *_frameworkNamesByClassName;
    
    NSMutableSet *_classes;
    NSMutableSet *_protocols;
}

- (id)init;
{
    if ((self = [super init])) {
        _frameworkNamesByClassName = [[NSMutableDictionary alloc] init];
        
        _classes = [[NSMutableSet alloc] init];
        _protocols = [[NSMutableSet alloc] init];
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> frameworkNamesByClassName: %@, classes: %@, protocols: %@",
            NSStringFromClass([self class]), self,
            self.frameworkNamesByClassName,
            self.classesSortedByName, self.protocolsSortedByName];
}

#pragma mark -

@synthesize frameworkNamesByClassName = _frameworkNamesByClassName;

- (void)addClassName:(NSString *)name referencedInFramework:(NSString *)framework;
{
    if (name != nil && framework != nil) {
        [self.frameworkNamesByClassName setObject:framework forKey:name];
    }
}

- (NSString *)frameworkForClassName:(NSString *)className;
{
    return [self.frameworkNamesByClassName objectForKey:className];
}

- (void)addClassName:(NSString *)className;
{
    [self.classes addObject:className];
}

- (void)removeClassName:(NSString *)className;
{
    if (className != nil)
        [self.classes removeObject:className];
}

- (void)addProtocolNamesFromArray:(NSArray *)protocolNames;
{
    [self.protocols addObjectsFromArray:protocolNames];
}

- (NSString *)referenceString;
{
    NSMutableString *referenceString = [[NSMutableString alloc] init];
    [self _appendToString:referenceString];

    if ([referenceString length] == 0)
        return nil;

    return [referenceString copy];
}

- (void)removeAllReferences;
{
    [self.classes removeAllObjects];
    [self.protocols removeAllObjects];
}

- (NSString *)importStringForClassName:(NSString *)className;
{
    if (className != nil) {
        NSString *framework = [self frameworkForClassName:className];
        if (framework == nil)
            return [NSString stringWithFormat:@"#import \"%@.h\"\n", className];
        else
            return [NSString stringWithFormat:@"#import <%@/%@.h>\n", framework, className];
    }

    return nil;
}

#pragma mark -

@synthesize classes = _classes;
@synthesize protocols = _protocols;

- (NSArray *)classesSortedByName;
{
    return [[self.classes allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)protocolsSortedByName;
{
    return [[self.protocols allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (void)_appendToString:(NSMutableString *)resultString;
{
    if ([self.protocols count] > 0) {
        [resultString appendFormat:@"@protocol %@;\n\n", [self.protocolsSortedByName componentsJoinedByString:@", "]];
    }
    
    if ([self.classes count] > 0) {
        [resultString appendFormat:@"@class %@;\n\n", [self.classesSortedByName componentsJoinedByString:@", "]];
    }
}

@end
