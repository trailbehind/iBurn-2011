//
//  util.m
//  iBurn
//
//  Created by Anna Hentzel on 8/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "util.h"
#import <JSONKit.h>
#import <math.h>

#define kHomeLocationLatKey @"kHomeLocationLatKey"
#define kHomeLocationLonKey @"kHomeLocationLonKey"

@implementation util

double cosd(double deg) {
    return cos(deg/57.2957795);
}

double sind(double deg) {
    return sin(deg/57.2957795);
}
double tand(double deg) {return sind(deg)/cosd(deg);}
double atand(double n) {return atan(n) * 57.2957795;}
double acosd(double n) {return acos(n) * 57.2957795;}

RMTile RMTileFromKey(uint64_t tilekey)
{
	RMTile t;
	t.zoom = tilekey >> 56;
	t.x = tilekey >> 28 & 0xFFFFFFFLL;
	t.y = tilekey & 0xFFFFFFFLL;
	return t;
}


+ (NSString*) formatDecimal_0:(float)num {
	static NSNumberFormatter *numFormatter;
	if (!numFormatter) {
		numFormatter = [[NSNumberFormatter alloc] init];
		[numFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[numFormatter setLocale:[NSLocale currentLocale]];
		[numFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[numFormatter setMaximumFractionDigits:0];
		[numFormatter setMinimumFractionDigits:0];
	}
	return [numFormatter stringFromNumber:F(num)];
}


+ (NSString*) formatDecimal_1:(float)num {
	static NSNumberFormatter *numFormatter;
	if (!numFormatter) {
		numFormatter = [[NSNumberFormatter alloc] init];
		[numFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[numFormatter setLocale:[NSLocale currentLocale]];
		[numFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[numFormatter setMaximumFractionDigits:1];
		[numFormatter setMinimumFractionDigits:1];
	}
	return [numFormatter stringFromNumber:F(num)];
}

+ (NSString*) formatDecimal_2:(double)num {
	static NSNumberFormatter *numFormatter;
	if (!numFormatter) {
		numFormatter = [[NSNumberFormatter alloc] init];
		[numFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[numFormatter setLocale:[NSLocale currentLocale]];
		[numFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[numFormatter setMaximumFractionDigits:2];
		[numFormatter setMinimumFractionDigits:2];
	}
	return [numFormatter stringFromNumber:F(num)];
}


+ (float) getDistanceFloat:(float)distance convertMax:(int)convertMax {
  if (distance == 0) return 0;
  
  BOOL useMetric = NO;

  if (useMetric) {
		if (convertMax != -1 && distance > convertMax) {
      return distance / 1000;
		}
    return distance;
  } else if (!useMetric) {
    if (convertMax != -1 && distance > convertMax) {
      
      distance = distance / 5280;
      return metersToFeet(distance);
    
    }
    return metersToFeet(distance);
  }
	return distance;
}


// Returns a formatted string represented the distance in the correct units.
// If distance is greater than convert max in feet or meters, the distance in miles or km is returned
+ (NSString*) distanceString:(float)distance 
                 convertMax:(int)convertMax 
                includeUnit:(BOOL)includeUnit 
              decimalPlaces:(int)decimalPlaces {
  NSString* unitName = @"m";
  
  BOOL useMetric = NO;
  if (useMetric) {
		if (convertMax != -1 && distance > convertMax) {
    
      unitName = @"km";
		}
  } else if (!useMetric) {
    if (convertMax != -1 && distance > convertMax) {
      unitName = @"mi";
    } else {
      unitName = @"ft";
    }
  } 
	
  float displayDistance = [util getDistanceFloat:distance convertMax:convertMax];
  if (decimalPlaces == 0) {
    displayDistance = floor(displayDistance);
  }
  
  NSString* formattedDecimal;
  if (distance < convertMax || decimalPlaces == 0) {
    formattedDecimal = [util formatDecimal_0:displayDistance];
  } else if (decimalPlaces == 1) {
    formattedDecimal = [util formatDecimal_1:displayDistance];
  } else {
    formattedDecimal = [util formatDecimal_2:displayDistance];
  }
  if (includeUnit) return [NSString stringWithFormat:@"%@ %@", formattedDecimal, unitName];
	return formattedDecimal;
}


+ (NSDictionary*) dayDict {
  
  NSData* jsonData = [NSData dataWithContentsOfFile: [[NSBundle mainBundle]pathForResource:@"date_strings" ofType:@"json"]];
  JSONDecoder* decoder = [[JSONDecoder alloc]
                          initWithParseOptions:JKParseOptionNone];
  NSDictionary* days = [decoder objectWithData:jsonData];
  return days;
}


+ (NSArray*) dayArray {
  
  NSData* jsonData = [NSData dataWithContentsOfFile: [[NSBundle mainBundle]pathForResource:@"day_array" ofType:@"json"]];
  JSONDecoder* decoder = [[JSONDecoder alloc]
                          initWithParseOptions:JKParseOptionNone];
  NSArray* days = [decoder objectWithData:jsonData];
  return days;
}

+ (NSArray*) creditsArray {
  
  NSData* jsonData = [NSData dataWithContentsOfFile: [[NSBundle mainBundle]pathForResource:@"credits" ofType:@"json"]];
  JSONDecoder* decoder = [[JSONDecoder alloc]
                          initWithParseOptions:JKParseOptionNone];
  NSArray* days = [decoder objectWithData:jsonData];
  return days;
}

+ (void) checkDirectory:(NSString*) filePath {
  
  if(![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:nil]) {
    if(![[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil])
      NSLog(@"Error: Create folder failed");
  } 
  
}

NSString* privateDocumentsDirectory() {
  static NSString* dir = nil;
  if (!dir) {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSLibraryDirectory, NSUserDomainMask, YES);
    dir = [[paths objectAtIndex:0] stringByAppendingString:@"/Private Documents"];	
    [util checkDirectory:dir];
    
  }
  return dir;
}

+ (double)bearingFromCoordinate:(CLLocationCoordinate2D)fromCoordinate toCoordinate:(CLLocationCoordinate2D)toCoordinate
{
    double dLon = toCoordinate.longitude-fromCoordinate.longitude;
    
    double y = sind(dLon) * cosd(toCoordinate.latitude);
    
    double x = cosd(fromCoordinate.latitude) * sind(toCoordinate.latitude)
    - sind(fromCoordinate.latitude) * cosd(toCoordinate.latitude) * cosd(dLon);
    
    double bearing = atan2(y, x) * 57.2957795;
    
    double bearingInDegrees = (int)(bearing + 360) % 360;
    return bearingInDegrees;
}

+(void)setHomeLocation:(CLLocation*)newHomeCoordinate
{
  NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:[NSNumber numberWithDouble:newHomeCoordinate.coordinate.latitude] forKey:kHomeLocationLatKey];
  [defaults setObject:[NSNumber numberWithDouble:newHomeCoordinate.coordinate.longitude] forKey:kHomeLocationLonKey];
  [defaults synchronize];
}

+(CLLocation*)homeLocation
{
  if (![[[NSUserDefaults standardUserDefaults] objectForKey:kHomeLocationLatKey] boolValue] || ![[[NSUserDefaults standardUserDefaults] objectForKey:kHomeLocationLonKey] boolValue]) {
    return nil;
  }
  NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
  return [[CLLocation alloc] initWithLatitude:[defaults doubleForKey:kHomeLocationLatKey] longitude:[defaults doubleForKey:kHomeLocationLonKey]];
}




@end
