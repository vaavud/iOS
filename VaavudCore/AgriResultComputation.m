//
//  AgriResultComputation.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 03/11/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "AgriResultComputation.h"
#import "SharedSingleton.h"

@interface AgriResultComputation()

@property (nonatomic, strong) NSDictionary *modelWithReduce;
@property (nonatomic, strong) NSDictionary *modelWithoutReduce;
@end

@implementation AgriResultComputation

SHARED_INSTANCE

- (id) init {
    self = [super init];
    
    if (self) {
        self.modelWithReduce =
            @{
              @10:
                  @{@1.5F:
                        @{@0.25F: @{@2: @[@2, @2],  @3: @[@2, @2],  @4: @[@2, @2]},
                          @0.5F:  @{@2: @[@2, @2],  @3: @[@2, @2],  @4: @[@2, @2]},
                          @1.0F:  @{@2: @[@2, @2],  @3: @[@2, @2],  @4: @[@2, @2]}},
                    @3.0F:
                        @{@0.25F: @{@2: @[@2, @2],  @3: @[@2, @2],  @4: @[@2, @2]},
                          @0.5F:  @{@2: @[@2, @2],  @3: @[@2, @2],  @4: @[@2, @2]},
                          @1.0F:  @{@2: @[@2, @2],  @3: @[@2, @2],  @4: @[@2, @2]}},
                    @4.5F:
                        @{@0.25F: @{@2: @[@2, @2],  @3: @[@2, @2],  @4: @[@2, @2]},
                          @0.5F:  @{@2: @[@2, @2],  @3: @[@2, @2],  @4: @[@2, @2]},
                          @1.0F:  @{@2: @[@2, @4],  @3: @[@2, @2],  @4: @[@2, @2]}}
                    },
              @15:
                  @{@1.5F:
                        @{@0.25F: @{@2: @[@2, @2],  @3: @[@2, @2],  @4: @[@2, @2]},
                          @0.5F:  @{@2: @[@2, @2],  @3: @[@2, @2],  @4: @[@2, @2]},
                          @1.0F:  @{@2: @[@2, @4],  @3: @[@2, @2],  @4: @[@2, @2]}},
                    @3.0F:
                        @{@0.25F: @{@2: @[@2, @2],  @3: @[@2, @2],  @4: @[@2, @2]},
                          @0.5F:  @{@2: @[@2, @2],  @3: @[@2, @2],  @4: @[@2, @2]},
                          @1.0F:  @{@2: @[@2, @8],  @3: @[@2, @2],  @4: @[@2, @2]}},
                    @4.5F:
                        @{@0.25F: @{@2: @[@2, @2],  @3: @[@2, @2],  @4: @[@2, @2]},
                          @0.5F:  @{@2: @[@2, @5],  @3: @[@2, @2],  @4: @[@2, @2]},
                          @1.0F:  @{@2: @[@2, @12], @3: @[@2, @5],  @4: @[@2, @2]}}
                    },
              @20:
                  @{@1.5F:
                        @{@0.25F: @{@2: @[@2, @2],  @3: @[@2, @2],  @4: @[@2, @2]},
                          @0.5F:  @{@2: @[@2, @2],  @3: @[@2, @2],  @4: @[@2, @2]},
                          @1.0F:  @{@2: @[@2, @6],  @3: @[@2, @2],  @4: @[@2, @2]}},
                    @3.0F:
                        @{@0.25F: @{@2: @[@2, @2],  @3: @[@2, @2],  @4: @[@2, @2]},
                          @0.5F:  @{@2: @[@2, @5],  @3: @[@2, @2],  @4: @[@2, @2]},
                          @1.0F:  @{@2: @[@2, @13], @3: @[@2, @5],  @4: @[@2, @2]}},
                    @4.5F:
                        @{@0.25F: @{@2: @[@2, @3],  @3: @[@2, @2],  @4: @[@2, @2]},
                          @0.5F:  @{@2: @[@2, @8],  @3: @[@2, @3],  @4: @[@2, @2]},
                          @1.0F:  @{@2: @[@3, @22], @3: @[@2, @8],  @4: @[@2, @2]}}
                    }
              };

        self.modelWithoutReduce =
            @{
              @10:
                  @{@1.5F:
                        @{@0.25F:
                              @{@25: @{@1: @[@2, @3],  @2: @[@2, @3],  @3: @[@2, @3]},
                                @40: @{@1: @[@2, @3],  @2: @[@2, @3],  @3: @[@2, @3]},
                                @60: @{@1: @[@2, @5],  @2: @[@2, @3],  @3: @[@2, @3]}},
                          @0.5F:
                              @{@25: @{@1: @[@2, @4],  @2: @[@2, @3],  @3: @[@2, @3]},
                                @40: @{@1: @[@2, @8],  @2: @[@2, @3],  @3: @[@2, @3]},
                                @60: @{@1: @[@2, @12], @2: @[@2, @8],  @3: @[@2, @3]}},
                          @1.0F:
                              @{@25: @{@1: @[@2, @12], @2: @[@2, @3],  @3: @[@2, @3]},
                                @40: @{@1: @[@3, @20], @2: @[@2, @9],  @3: @[@2, @3]},
                                @60: @{@1: @[@5, @34], @2: @[@3, @20], @3: @[@2, @9]}}
                        },
                    @3.0F:
                        @{@0.25F:
                              @{@25: @{@1: @[@2, @3],  @2: @[@2, @3],  @3: @[@2, @3]},
                                @40: @{@1: @[@2, @3],  @2: @[@2, @3],  @3: @[@2, @3]},
                                @60: @{@1: @[@2, @5],  @2: @[@2, @3],  @3: @[@2, @3]}},
                          @0.5F:
                              @{@25: @{@1: @[@2, @6],  @2: @[@2, @3],  @3: @[@2, @3]},
                                @40: @{@1: @[@2, @9],  @2: @[@2, @5],  @3: @[@2, @3]},
                                @60: @{@1: @[@2, @14], @2: @[@2, @9],  @3: @[@2, @4]}},
                          @1.0F:
                              @{@25: @{@1: @[@2, @16], @2: @[@2, @5],  @3: @[@2, @3]},
                                @40: @{@1: @[@3, @24], @2: @[@2, @12], @3: @[@2, @3]},
                                @60: @{@1: @[@5, @38], @2: @[@3, @24], @3: @[@2, @12]}}
                          },
                    @4.5F:
                        @{@0.25F:
                              @{@25: @{@1: @[@2, @3],  @2: @[@2, @3],  @3: @[@2, @3]},
                                @40: @{@1: @[@2, @4],  @2: @[@2, @3],  @3: @[@2, @3]},
                                @60: @{@1: @[@2, @6],  @2: @[@2, @4],  @3: @[@2, @3]}},
                          @0.5F:
                              @{@25: @{@1: @[@2, @8],  @2: @[@2, @3],  @3: @[@2, @3]},
                                @40: @{@1: @[@2, @11], @2: @[@2, @6],  @3: @[@2, @3]},
                                @60: @{@1: @[@2, @16], @2: @[@2, @11], @3: @[@2, @6]}},
                          @1.0F:
                              @{@25: @{@1: @[@3, @20], @2: @[@2, @8],  @3: @[@2, @3]},
                                @40: @{@1: @[@4, @30], @2: @[@2, @16], @3: @[@2, @6]},
                                @60: @{@1: @[@6, @44], @2: @[@4, @30], @3: @[@2, @16]}}
                          }
                    },
              @15:
                  @{@1.5F:
                        @{@0.25F:
                              @{@25: @{@1: @[@2, @3],  @2: @[@2, @3],  @3: @[@2, @3]},
                                @40: @{@1: @[@2, @4],  @2: @[@2, @3],  @3: @[@2, @3]},
                                @60: @{@1: @[@2, @6],  @2: @[@2, @4],  @3: @[@2, @3]}},
                          @0.5F:
                              @{@25: @{@1: @[@2, @7],  @2: @[@2, @3],  @3: @[@2, @3]},
                                @40: @{@1: @[@2, @10], @2: @[@2, @5],  @3: @[@2, @3]},
                                @60: @{@1: @[@2, @16], @2: @[@2, @10], @3: @[@2, @5]}},
                          @1.0F:
                              @{@25: @{@1: @[@2, @18], @2: @[@2, @7],  @3: @[@2, @3]},
                                @40: @{@1: @[@4, @28], @2: @[@2, @14], @3: @[@2, @4]},
                                @60: @{@1: @[@6, @42], @2: @[@4, @28], @3: @[@2, @14]}}
                          },
                    @3.0F:
                        @{@0.25F:
                              @{@25: @{@1: @[@2, @4],  @2: @[@2, @3],  @3: @[@2, @3]},
                                @40: @{@1: @[@2, @5],  @2: @[@2, @3],  @3: @[@2, @3]},
                                @60: @{@1: @[@2, @8],  @2: @[@2, @5],  @3: @[@2, @3]}},
                          @0.5F:
                              @{@25: @{@1: @[@2, @11], @2: @[@2, @6],  @3: @[@2, @3]},
                                @40: @{@1: @[@2, @16], @2: @[@2, @9],  @3: @[@2, @4]},
                                @60: @{@1: @[@3, @22], @2: @[@2, @16], @3: @[@2, @9]}},
                          @1.0F:
                              @{@25: @{@1: @[@4, @30], @2: @[@2, @16], @3: @[@2, @5]},
                                @40: @{@1: @[@6, @40], @2: @[@3, @26], @3: @[@2, @12]},
                                @60: @{@1: @[@8, @50], @2: @[@6, @38], @3: @[@3, @26]}}
                          },
                    @4.5F:
                        @{@0.25F:
                              @{@25: @{@1: @[@2, @6],  @2: @[@2, @4],  @3: @[@2, @3]},
                                @40: @{@1: @[@2, @7],  @2: @[@2, @5],  @3: @[@2, @3]},
                                @60: @{@1: @[@2, @10], @2: @[@2, @7],  @3: @[@2, @5]}},
                          @0.5F:
                              @{@25: @{@1: @[@2, @16], @2: @[@2, @10], @3: @[@2, @5]},
                                @40: @{@1: @[@3, @20], @2: @[@2, @14], @3: @[@2, @9]},
                                @60: @{@1: @[@4, @28], @2: @[@3, @20], @3: @[@2, @14]}},
                          @1.0F:
                              @{@25: @{@1: @[@6, @44], @2: @[@4, @28], @3: @[@2, @14]},
                                @40: @{@1: @[@7, @50], @2: @[@5, @38], @3: @[@3, @24]},
                                @60: @{@1: @[@10,@50], @2: @[@7, @50], @3: @[@5, @38]}}
                          }
                    },
              @20:
                  @{@1.5F:
                        @{@0.25F:
                              @{@25: @{@1: @[@2, @3],  @2: @[@2, @3],  @3: @[@2, @3]},
                                @40: @{@1: @[@2, @5],  @2: @[@2, @3],  @3: @[@2, @3]},
                                @60: @{@1: @[@2, @7],  @2: @[@2, @4],  @3: @[@2, @3]}},
                          @0.5F:
                              @{@25: @{@1: @[@2, @9],  @2: @[@2, @4],  @3: @[@2, @3]},
                                @40: @{@1: @[@2, @12], @2: @[@2, @7],  @3: @[@2, @3]},
                                @60: @{@1: @[@2, @18], @2: @[@2, @12], @3: @[@2, @7]}},
                          @1.0F:
                              @{@25: @{@1: @[@3, @24], @2: @[@2, @12], @3: @[@2, @3]},
                                @40: @{@1: @[@5, @34], @2: @[@3, @20], @3: @[@2, @8]},
                                @60: @{@1: @[@7, @50], @2: @[@5, @34], @3: @[@3, @20]}}
                          },
                    @3.0F:
                        @{@0.25F:
                              @{@25: @{@1: @[@2, @6],  @2: @[@2, @4],  @3: @[@2, @3]},
                                @40: @{@1: @[@2, @8],  @2: @[@2, @6],  @3: @[@2, @4]},
                                @60: @{@1: @[@2, @11], @2: @[@2, @8],  @3: @[@2, @6]}},
                          @0.5F:
                              @{@25: @{@1: @[@2, @18], @2: @[@2, @11], @3: @[@2, @6]},
                                @40: @{@1: @[@3, @22], @2: @[@2, @16], @3: @[@2, @10]},
                                @60: @{@1: @[@4, @28], @2: @[@3, @22], @3: @[@2, @16]}},
                          @1.0F:
                              @{@25: @{@1: @[@6, @46], @2: @[@4, @32], @3: @[@2, @14]},
                                @40: @{@1: @[@8, @50], @2: @[@6, @44], @3: @[@4, @26]},
                                @60: @{@1: @[@11,@50], @2: @[@8, @50], @3: @[@6, @44]}}
                          },
                    @4.5F:
                        @{@0.25F:
                              @{@25: @{@1: @[@2, @10], @2: @[@2, @7],  @3: @[@2, @5]},
                                @40: @{@1: @[@2, @11], @2: @[@2, @9],  @3: @[@2, @6]},
                                @60: @{@1: @[@2, @14], @2: @[@2, @11], @3: @[@2, @9]}},
                          @0.5F:
                              @{@25: @{@1: @[@3, @28], @2: @[@2, @20], @3: @[@2, @14]},
                                @40: @{@1: @[@4, @32], @2: @[@3, @24], @3: @[@2, @18]},
                                @60: @{@1: @[@5, @38], @2: @[@4, @32], @3: @[@3, @24]}},
                          @1.0F:
                              @{@25: @{@1: @[@10,@50], @2: @[@7, @50], @3: @[@5, @36]},
                                @40: @{@1: @[@12,@50], @2: @[@9, @50], @3: @[@6, @46]},
                                @60: @{@1: @[@15,@50], @2: @[@12,@50], @3: @[@9, @50]}}
                          }
                    }
              };
    }
    
    return self;
}

- (NSNumber*) generalConsideration:(NSNumber*)temperature windSpeed:(NSNumber*)windSpeed reduceEquipment:(NSNumber*)reduceEquipment dose:(NSNumber*)dose boomHeight:(NSNumber*)boomHeight sprayQuality:(NSNumber*)sprayQuality {
    
    temperature = [self roundTemperature:temperature];
    if (!temperature) {
        return nil;
    }

    windSpeed = [self roundWindSpeed:windSpeed];
    if (!windSpeed) {
        return nil;
    }
    
    if (!dose || [dose floatValue] == 0.0F) {
        NSLog(@"[AgriResultComputation] No dose");
        return nil;
    }
    
    if (!reduceEquipment || [reduceEquipment intValue] == 1) {
        //NSLog(@"[AgriResultComputation] Using no reduce equipment model");
        
        if (!boomHeight || [boomHeight intValue] < 25) {
            NSLog(@"[AgriResultComputation] No boom height");
            return nil;
        }
        
        if (!sprayQuality || [sprayQuality intValue] == 0) {
            NSLog(@"[AgriResultComputation] No spray quality");
            return nil;
        }
        
        NSDictionary *windSpeedDictionary = [self.modelWithoutReduce objectForKey:temperature];
        if (!windSpeedDictionary) {
            NSLog(@"[AgriResultComputation] No wind speed dictionary");
            return nil;
        }
        NSDictionary *doseDictionary = [windSpeedDictionary objectForKey:windSpeed];
        if (!doseDictionary) {
            NSLog(@"[AgriResultComputation] No dose dictionary");
            return nil;
        }
        NSDictionary *boomHeightDictionary = [doseDictionary objectForKey:dose];
        if (!boomHeightDictionary) {
            NSLog(@"[AgriResultComputation] No boom height dictionary");
            return nil;
        }
        NSDictionary *sprayQualityDictionary = [boomHeightDictionary objectForKey:boomHeight];
        if (!sprayQualityDictionary) {
            NSLog(@"[AgriResultComputation] No spray quality dictionary");
            return nil;
        }
        NSArray *result = [sprayQualityDictionary objectForKey:sprayQuality];
        if (!result) {
            NSLog(@"[AgriResultComputation] No result array");
            return nil;
        }
        return result[0];
    }
    else {
        //NSLog(@"[AgriResultComputation] Using reduce equipment model");
        NSDictionary *windSpeedDictionary = [self.modelWithReduce objectForKey:temperature];
        if (!windSpeedDictionary) {
            NSLog(@"[AgriResultComputation] No wind speed dictionary");
            return nil;
        }
        NSDictionary *doseDictionary = [windSpeedDictionary objectForKey:windSpeed];
        if (!doseDictionary) {
            NSLog(@"[AgriResultComputation] No dose dictionary");
            return nil;
        }
        NSDictionary *reduceEquipmentDictionary = [doseDictionary objectForKey:dose];
        if (!reduceEquipmentDictionary) {
            NSLog(@"[AgriResultComputation] No reduce equipment dictionary");
            return nil;
        }
        NSArray *result = [reduceEquipmentDictionary objectForKey:reduceEquipment];
        if (!result) {
            NSLog(@"[AgriResultComputation] No result array");
            return nil;
        }
        return result[0];
    }
}

- (NSNumber*) specialConsideration:(NSNumber*)temperature windSpeed:(NSNumber*)windSpeed reduceEquipment:(NSNumber*)reduceEquipment dose:(NSNumber*)dose boomHeight:(NSNumber*)boomHeight sprayQuality:(NSNumber*)sprayQuality {
    
    temperature = [self roundTemperature:temperature];
    if (!temperature) {
        return nil;
    }

    windSpeed = [self roundWindSpeed:windSpeed];
    if (!windSpeed) {
        return nil;
    }

    if (!dose || [dose floatValue] == 0.0F) {
        NSLog(@"[AgriResultComputation] No dose");
        return nil;
    }

    if (!reduceEquipment || [reduceEquipment intValue] == 1) {
        //NSLog(@"[AgriResultComputation] Using no reduce equipment model");
        
        if (!boomHeight || [boomHeight intValue] < 25) {
            NSLog(@"[AgriResultComputation] No boom height");
            return nil;
        }
        
        if (!sprayQuality || [sprayQuality intValue] == 0) {
            NSLog(@"[AgriResultComputation] No spray quality");
            return nil;
        }
        
        NSDictionary *windSpeedDictionary = [self.modelWithoutReduce objectForKey:temperature];
        if (!windSpeedDictionary) {
            NSLog(@"[AgriResultComputation] No wind speed dictionary");
            return nil;
        }
        NSDictionary *doseDictionary = [windSpeedDictionary objectForKey:windSpeed];
        if (!doseDictionary) {
            NSLog(@"[AgriResultComputation] No dose dictionary");
            return nil;
        }
        NSDictionary *boomHeightDictionary = [doseDictionary objectForKey:dose];
        if (!boomHeightDictionary) {
            NSLog(@"[AgriResultComputation] No boom height dictionary");
            return nil;
        }
        NSDictionary *sprayQualityDictionary = [boomHeightDictionary objectForKey:boomHeight];
        if (!sprayQualityDictionary) {
            NSLog(@"[AgriResultComputation] No spray quality dictionary");
            return nil;
        }
        NSArray *result = [sprayQualityDictionary objectForKey:sprayQuality];
        if (!result) {
            NSLog(@"[AgriResultComputation] No result array");
            return nil;
        }
        return result[1];
    }
    else {
        //NSLog(@"[AgriResultComputation] Using reduce equipment model");
        NSDictionary *windSpeedDictionary = [self.modelWithReduce objectForKey:temperature];
        if (!windSpeedDictionary) {
            NSLog(@"[AgriResultComputation] No wind speed dictionary");
            return nil;
        }
        NSDictionary *doseDictionary = [windSpeedDictionary objectForKey:windSpeed];
        if (!doseDictionary) {
            NSLog(@"[AgriResultComputation] No dose dictionary");
            return nil;
        }
        NSDictionary *reduceEquipmentDictionary = [doseDictionary objectForKey:dose];
        if (!reduceEquipmentDictionary) {
            NSLog(@"[AgriResultComputation] No reduce equipment dictionary");
            return nil;
        }
        NSArray *result = [reduceEquipmentDictionary objectForKey:reduceEquipment];
        if (!result) {
            NSLog(@"[AgriResultComputation] No result array");
            return nil;
        }
        return result[1];
    }
}

- (NSNumber*) roundTemperature:(NSNumber*)temperature {
    if (!temperature || [temperature floatValue] == 0.0F) {
        NSLog(@"[AgriResultComputation] No temperature");
        return nil;
    }
    
    float t = [temperature floatValue] - KELVIN_TO_CELCIUS;
    if (t < 12.5F) {
        return [NSNumber numberWithInt:10];
    }
    else if (t >= 12.5F && t < 17.5F) {
        return [NSNumber numberWithInt:15];
    }
    else {
        return [NSNumber numberWithInt:20];
    }
}

- (NSNumber*) roundWindSpeed:(NSNumber*)windSpeed {
    if (!windSpeed) {
        NSLog(@"[AgriResultComputation] No wind speed");
        return nil;
    }
    
    float s = [windSpeed floatValue];
    if (s < 2.25F) {
        return [NSNumber numberWithFloat:1.5F];
    }
    else if (s >= 2.25F && s < 3.75F) {
        return [NSNumber numberWithFloat:3.0F];
    }
    else {
        return [NSNumber numberWithFloat:4.5F];
    }
}

@end
