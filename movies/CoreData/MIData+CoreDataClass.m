//
//  MIData+CoreDataClass.m
//  movies
//
//  Created by Jerry Hale on 10/8/17.
//  Copyright © 2019 jhale. All rights reserved.
//
//

#import "MIData+CoreDataClass.h"

@implementation MIData

- (void) awakeFromInsert
{
	[super awakeFromInsert];

	NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateFormat = @"yyyy-MM-dd";
	self.creationDate = [dateFormatter stringFromDate:[NSDate date]];
}

@end
