//
//  AgriResultViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 02/10/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "AgriResultViewController.h"
#import "UIColor+VaavudColors.h"
#import "UnitUtil.h"
#import "Property+Util.h"
#import "Mixpanel.h"

@interface AgriResultViewController ()

@property (nonatomic, weak) IBOutlet UILabel *windSpeedHeadingLabel; // OK
@property (nonatomic, weak) IBOutlet UILabel *averageLabel; // OK
@property (weak, nonatomic) IBOutlet UILabel *temperatureHeadingLabel; // OK
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel; // OK
@property (weak, nonatomic) IBOutlet UILabel *temperatureUnitLabel; // OK
@property (weak, nonatomic) IBOutlet UILabel *windSpeedUnitLabel; // OK
@property (weak, nonatomic) IBOutlet UILabel *directionHeadingLabel; // OK
@property (weak, nonatomic) IBOutlet UILabel *directionLabel; // OK
@property (weak, nonatomic) IBOutlet UIImageView *directionImageView; // OK
@property (weak, nonatomic) IBOutlet UILabel *reducingEquipmentHeadingLabel; // OK
@property (weak, nonatomic) IBOutlet UISwitch *reducingEquipmentSwitch;
@property (weak, nonatomic) IBOutlet UILabel *doseHeadingLabel; // OK
@property (weak, nonatomic) IBOutlet UISegmentedControl *doseSegmentControl;
@property (weak, nonatomic) IBOutlet UILabel *boomHeightHeadingLabel; // OK
@property (weak, nonatomic) IBOutlet UISegmentedControl *boomHeightSegmentControl;
@property (weak, nonatomic) IBOutlet UILabel *sprayQualityHeadingLabel; // OK
@property (weak, nonatomic) IBOutlet UISegmentedControl *sprayQualitySegmentControl;
@property (weak, nonatomic) IBOutlet UILabel *protectiveDistanceLabel; // OK
@property (weak, nonatomic) IBOutlet UILabel *generalDistanceHeadingLabel; // OK
@property (weak, nonatomic) IBOutlet UILabel *generalDistanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *generalDistanceUnitLabel; // OK
@property (weak, nonatomic) IBOutlet UILabel *specialDistanceHeadingLabel; // OK
@property (weak, nonatomic) IBOutlet UILabel *specialDistanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *specialDistanceUnitLabel; // OK
@property (weak, nonatomic) IBOutlet UIButton *saveButton; // OK

@property (nonatomic) WindSpeedUnit windSpeedUnit;
@property (nonatomic) NSInteger directionUnit;
@property (nonatomic, strong) NSNumber *generalDistance;
@property (nonatomic, strong) NSNumber *specialDistance;

@end

@implementation AgriResultViewController

- (void) viewDidLoad {
    [super viewDidLoad];

    self.windSpeedUnit = [[Property getAsInteger:KEY_WIND_SPEED_UNIT] intValue];

    UIColor *vaavudColor = [UIColor vaavudColor];
    
    self.windSpeedHeadingLabel.text = [NSLocalizedString(@"HEADING_WIND_SPEED", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    self.temperatureUnitLabel.text = NSLocalizedString(@"UNIT_CELCIUS", nil);
    self.directionHeadingLabel.text = [NSLocalizedString(@"HEADING_WIND_DIRECTION", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    self.temperatureHeadingLabel.text = [NSLocalizedString(@"HEADING_TEMPERATURE", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    self.reducingEquipmentHeadingLabel.text = NSLocalizedString(@"AGRI_REDUCING_EQUIPMENT", nil);
    self.doseHeadingLabel.text = NSLocalizedString(@"AGRI_DOSE", nil);
    self.boomHeightHeadingLabel.text = NSLocalizedString(@"AGRI_BOOM_HEIGHT", nil);
    self.sprayQualityHeadingLabel.text = NSLocalizedString(@"AGRI_SPRAY_QUALITY", nil);
    self.protectiveDistanceLabel.text = NSLocalizedString(@"AGRI_PROTECTIVE_DISTANCE", nil);
    self.generalDistanceHeadingLabel.text = NSLocalizedString(@"AGRI_GENERAL_DISTANCE", nil);
    self.generalDistanceUnitLabel.text = NSLocalizedString(@"AGRI_DISTANCE_UNIT_M", nil);
    self.specialDistanceHeadingLabel.text = NSLocalizedString(@"AGRI_SPECIAL_DISTANCE", nil);
    self.specialDistanceUnitLabel.text = NSLocalizedString(@"AGRI_DISTANCE_UNIT_M", nil);
    
    [self.doseSegmentControl setTitle:NSLocalizedString(@"AGRI_DOSE_QUARTER", nil) forSegmentAtIndex:0];
    [self.doseSegmentControl setTitle:NSLocalizedString(@"AGRI_DOSE_HALF", nil) forSegmentAtIndex:1];
    [self.doseSegmentControl setTitle:NSLocalizedString(@"AGRI_DOSE_FULL", nil) forSegmentAtIndex:2];

    [self.boomHeightSegmentControl setTitle:NSLocalizedString(@"AGRI_BOOM_HEIGHT_25CM", nil) forSegmentAtIndex:0];
    [self.boomHeightSegmentControl setTitle:NSLocalizedString(@"AGRI_BOOM_HEIGHT_40CM", nil) forSegmentAtIndex:1];
    [self.boomHeightSegmentControl setTitle:NSLocalizedString(@"AGRI_BOOM_HEIGHT_60CM", nil) forSegmentAtIndex:2];

    [self.sprayQualitySegmentControl setTitle:NSLocalizedString(@"AGRI_SPRAY_QUALITY_FINE", nil) forSegmentAtIndex:0];
    [self.sprayQualitySegmentControl setTitle:NSLocalizedString(@"AGRI_SPRAY_QUALITY_MEDIUM", nil) forSegmentAtIndex:1];
    [self.sprayQualitySegmentControl setTitle:NSLocalizedString(@"AGRI_SPRAY_QUALITY_COARSE", nil) forSegmentAtIndex:2];
    
    [self.saveButton setTitle:NSLocalizedString(@"AGRI_RESULT_SAVE_BUTTON", nil) forState:UIControlStateNormal];
    self.saveButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.saveButton.layer.masksToBounds = YES;
    self.saveButton.backgroundColor = vaavudColor;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.windSpeedUnit = [[Property getAsInteger:KEY_WIND_SPEED_UNIT] intValue];
    self.windSpeedUnitLabel.text = [UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit];
    
    NSNumber *directionUnitNumber = [Property getAsInteger:KEY_DIRECTION_UNIT];
    NSInteger directionUnit = (directionUnitNumber) ? [directionUnitNumber doubleValue] : 0;
    if (self.directionUnit != directionUnit) {
        self.directionUnit = directionUnit;
    }

    if (self.measurementSession && self.measurementSession.reducingEquipment) {
        [self.reducingEquipmentSwitch setOn:[self.measurementSession.reducingEquipment boolValue]];
    }
    else {
        [self.reducingEquipmentSwitch setOn:[Property getAsBoolean:KEY_AGRI_DEFAULT_REDUCING_EQUIPMENT defaultValue:NO] animated:NO];
    }
    
    if (self.measurementSession && self.measurementSession.dose && ([self.measurementSession.dose floatValue] > 0.0F)) {
        [self setSelectedDose:self.measurementSession.dose];
    }
    else {
        [self setSelectedDose:[Property getAsFloat:KEY_AGRI_DEFAULT_DOSE defaultValue:0.25F]];
    }
    
    if (self.measurementSession && self.measurementSession.boomHeight && ([self.measurementSession.boomHeight intValue] > 0)) {
        [self setSelectedBoomHeight:self.measurementSession.boomHeight];
    }
    else {
        [self setSelectedBoomHeight:[Property getAsInteger:KEY_AGRI_DEFAULT_BOOM_HEIGHT defaultValue:25]];
    }
    
    if (self.measurementSession && self.measurementSession.sprayQuality && ([self.measurementSession.sprayQuality intValue] > 0)) {
        [self setSelectedSprayQuality:self.measurementSession.sprayQuality];
    }
    else {
        [self setSelectedSprayQuality:[Property getAsInteger:KEY_AGRI_DEFAULT_SPRAY_QUALITY defaultValue:1]];
    }
    
    if (self.measurementSession && self.measurementSession.endTime) {
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        
        self.navigationItem.title = [dateFormatter stringFromDate:self.measurementSession.endTime];
    }
    else {
        self.navigationItem.title = @"";
    }

    [self updateMeasuredValues];
    [self updateComputedValues];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Agri Result Screen"];
    }
}

- (void) updateMeasuredValues {
    
    if (self.measurementSession && self.measurementSession.windSpeedAvg && !isnan([self.measurementSession.windSpeedAvg doubleValue])) {
        self.averageLabel.text = [self formatValue:[UnitUtil displayWindSpeedFromDouble:[self.measurementSession.windSpeedAvg doubleValue] unit:self.windSpeedUnit]];
    }
    else {
        self.averageLabel.text = @"-";
    }
    
    if (self.measurementSession && self.measurementSession.windDirection && !isnan([self.measurementSession.windDirection doubleValue])) {
        
            if (self.directionUnit == 0) {
                self.directionLabel.text = [UnitUtil displayNameForDirection:self.measurementSession.windDirection];
            }
            else {
                self.directionLabel.text = [NSString stringWithFormat:@"%@°", [NSNumber numberWithInt:(int)round([self.measurementSession.windDirection doubleValue])]];
            }
        
            NSString *imageName = [UnitUtil imageNameForDirection:self.measurementSession.windDirection];
            if (imageName) {
                self.directionImageView.image = [UIImage imageNamed:imageName];
                self.directionImageView.hidden = NO;
            }
            else {
                self.directionImageView.hidden = YES;
            }
    }
    else {
        if (self.directionLabel) {
            self.directionLabel.text = @"-";
        }
        if (self.directionImageView) {
            self.directionImageView.hidden = YES;
        }
    }
    
    if (self.measurementSession && self.measurementSession.temperature && [self.measurementSession.temperature floatValue] > 0.0) {
        self.temperatureLabel.text = [self formatValue:[self.measurementSession.temperature floatValue] - KELVIN_TO_CELCIUS];
    }
    else {
        self.temperatureLabel.text = @"-";
    }
}

- (void) updateComputedValues {
    
    if (self.measurementSession && self.measurementSession.windSpeedAvg && !isnan([self.measurementSession.windSpeedAvg doubleValue])
                                && self.measurementSession.windDirection && !isnan([self.measurementSession.windDirection doubleValue])
                                && self.measurementSession.temperature && [self.measurementSession.temperature floatValue] > 0.0) {

        // TODO: Compute real values
        self.generalDistance = nil;
        self.specialDistance = nil;
        
        self.generalDistanceLabel.text = @"-";
        self.specialDistanceLabel.text = @"-";
    }
    else {
        self.generalDistance = nil;
        self.specialDistance = nil;
        self.generalDistanceLabel.text = @"-";
        self.specialDistanceLabel.text = @"-";
    }
}

- (NSString*) formatValue:(double)value {
    if (value > 100.0) {
        return [NSString stringWithFormat: @"%.0f", value];
    }
    else {
        return [NSString stringWithFormat: @"%.1f", value];
    }
}

- (void) setSelectedDose:(NSNumber*)dose {
    
    if (dose) {
        float doseFloat = [dose floatValue];
        if (doseFloat == 0.25) {
            self.doseSegmentControl.selectedSegmentIndex = 0;
        }
        else if (doseFloat == 0.5) {
            self.doseSegmentControl.selectedSegmentIndex = 1;
        }
        else if (doseFloat == 1.0) {
            self.doseSegmentControl.selectedSegmentIndex = 2;
        }
        else {
            NSLog(@"[AgriResultViewController] ERROR: Unsupported dose %f setting UI", doseFloat);
            self.doseSegmentControl.selectedSegmentIndex = 0;
        }
    }
    else {
        self.doseSegmentControl.selectedSegmentIndex = 0;
    }
}

- (void) setSelectedBoomHeight:(NSNumber*)boomHeight {
    
    if (boomHeight) {
        int boomHeightInt = [boomHeight intValue];
        if (boomHeightInt == 25) {
            self.boomHeightSegmentControl.selectedSegmentIndex = 0;
        }
        else if (boomHeightInt == 40) {
            self.boomHeightSegmentControl.selectedSegmentIndex = 1;
        }
        else if (boomHeightInt == 60) {
            self.boomHeightSegmentControl.selectedSegmentIndex = 2;
        }
        else {
            NSLog(@"[AgriResultViewController] ERROR: Unsupported boom height %d setting UI", boomHeightInt);
            self.boomHeightSegmentControl.selectedSegmentIndex = 0;
        }
    }
    else {
        self.boomHeightSegmentControl.selectedSegmentIndex = 0;
    }
}

- (void) setSelectedSprayQuality:(NSNumber*)sprayQuality {
    
    if (sprayQuality) {
        int sprayQualityInt = [sprayQuality intValue];
        if (sprayQualityInt == 1) {
            self.sprayQualitySegmentControl.selectedSegmentIndex = 0;
        }
        else if (sprayQualityInt == 2) {
            self.sprayQualitySegmentControl.selectedSegmentIndex = 1;
        }
        else if (sprayQualityInt == 3) {
            self.sprayQualitySegmentControl.selectedSegmentIndex = 2;
        }
        else {
            NSLog(@"[AgriResultViewController] ERROR: Unsupported spray quality %d setting UI", sprayQualityInt);
            self.sprayQualitySegmentControl.selectedSegmentIndex = 0;
        }
    }
    else {
        self.sprayQualitySegmentControl.selectedSegmentIndex = 0;
    }
}

- (IBAction) reducingEquipmentValueChanged:(id)sender {

    [Property setAsBoolean:self.reducingEquipmentSwitch.on forKey:KEY_AGRI_DEFAULT_REDUCING_EQUIPMENT];
    [self updateComputedValues];
}

- (IBAction) doseSegmentControlValueChanged:(id)sender {
    
    [Property setAsFloat:[self getDoseValue] forKey:KEY_AGRI_DEFAULT_DOSE];
    [self updateComputedValues];
}

- (NSNumber*) getDoseValue {
    
    switch (self.doseSegmentControl.selectedSegmentIndex) {
        case 0:
            return [NSNumber numberWithFloat:0.25];
        case 1:
            return [NSNumber numberWithFloat:0.5];
        case 2:
            return [NSNumber numberWithFloat:1.0];
        default:
            NSLog(@"[AgriResultViewController] ERROR: Unknown dose selected segment index %d", self.doseSegmentControl.selectedSegmentIndex);
            return [NSNumber numberWithFloat:1.0];
    }
}

- (IBAction) boomHeightValueChanged:(id)sender {

    [Property setAsInteger:[self getBoomHeightValue] forKey:KEY_AGRI_DEFAULT_BOOM_HEIGHT];
    [self updateComputedValues];
}

- (NSNumber*) getBoomHeightValue {
    
    switch (self.boomHeightSegmentControl.selectedSegmentIndex) {
        case 0:
            return [NSNumber numberWithInt:25];
        case 1:
            return [NSNumber numberWithInt:40];
        case 2:
            return [NSNumber numberWithInt:60];
        default:
            NSLog(@"[AgriResultViewController] ERROR: Unknown boom height selected segment index %d", self.boomHeightSegmentControl.selectedSegmentIndex);
            return [NSNumber numberWithInt:60];
    }
}

- (IBAction) sprayQualityValueChanged:(id)sender {

    [Property setAsInteger:[self getSprayQualityValue] forKey:KEY_AGRI_DEFAULT_SPRAY_QUALITY];
    [self updateComputedValues];
}

- (NSNumber*) getSprayQualityValue {
    
    switch (self.sprayQualitySegmentControl.selectedSegmentIndex) {
        case 0:
            return [NSNumber numberWithInt:1];
        case 1:
            return [NSNumber numberWithInt:2];
        case 2:
            return [NSNumber numberWithInt:3];
        default:
            NSLog(@"[AgriResultViewController] ERROR: Unknown spray quality selected segment index %d", self.sprayQualitySegmentControl.selectedSegmentIndex);
            return [NSNumber numberWithInt:3];
    }
}

- (IBAction) saveButtonPushed:(id)sender {
    
    NSMutableString *summary = [NSMutableString string];
    
    if (self.measurementSession) {
        
        if (self.measurementSession.windSpeedAvg && !isnan([self.measurementSession.windSpeedAvg doubleValue]) && self.averageLabel.text) {
            if (summary.length > 0) {
                [summary appendString:@"\n"];
            }
            [summary appendFormat:@"%@: %@", NSLocalizedString(@"HEADING_WIND_SPEED", nil), self.averageLabel.text];
        }
        
        if (self.measurementSession.windDirection && !isnan([self.measurementSession.windDirection doubleValue]) && self.directionLabel.text) {
            if (summary.length > 0) {
                [summary appendString:@"\n"];
            }
            [summary appendFormat:@"%@: %@", NSLocalizedString(@"HEADING_WIND_DIRECTION", nil), self.directionLabel.text];
        }
        
        if (self.measurementSession.temperature && ([self.measurementSession.temperature floatValue] > 0.0F) && self.temperatureLabel) {
            if (summary.length > 0) {
                [summary appendString:@"\n"];
            }
            [summary appendFormat:@"%@: %@ %@", NSLocalizedString(@"HEADING_TEMPERATURE", nil), self.temperatureLabel.text, NSLocalizedString(@"UNIT_CELCIUS", nil)];
        }
        
        if (summary.length > 0) {
            [summary appendString:@"\n"];
        }
        [summary appendFormat:@"%@: %@", NSLocalizedString(@"AGRI_REDUCING_EQUIPMENT", nil), self.reducingEquipmentSwitch.on ? NSLocalizedString(@"YES", nil) : NSLocalizedString(@"NO", nil)];
        
        [summary appendString:@"\n"];
        [summary appendFormat:@"%@: %@", NSLocalizedString(@"AGRI_DOSE", nil), [self.doseSegmentControl titleForSegmentAtIndex:self.doseSegmentControl.selectedSegmentIndex]];
        
        [summary appendString:@"\n"];
        [summary appendFormat:@"%@: %@", NSLocalizedString(@"AGRI_BOOM_HEIGHT", nil), [self.boomHeightSegmentControl titleForSegmentAtIndex:self.boomHeightSegmentControl.selectedSegmentIndex]];

        [summary appendString:@"\n"];
        [summary appendFormat:@"%@: %@", NSLocalizedString(@"AGRI_SPRAY_QUALITY", nil), [self.sprayQualitySegmentControl titleForSegmentAtIndex:self.sprayQualitySegmentControl.selectedSegmentIndex]];

        [summary appendString:@"\n"];
        [summary appendFormat:@"%@: %@ %@ / %@ %@", NSLocalizedString(@"AGRI_PROTECTIVE_DISTANCE", nil), self.generalDistanceLabel.text, NSLocalizedString(@"AGRI_DISTANCE_UNIT_M", nil), self.specialDistanceLabel.text, NSLocalizedString(@"AGRI_DISTANCE_UNIT_M", nil)];
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"AGRI_RESULT_CONFIRM_SAVE_TITLE", nil)
                                                                                 message:summary
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction *action) {
                                                          }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              [self performSave];
                                                          }]];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else {
        
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"AGRI_RESULT_CONFIRM_SAVE_TITLE", nil)
                                    message:summary
                                   delegate:self
                          cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                          otherButtonTitles:NSLocalizedString(@"BUTTON_OK", nil), nil] show];
    }
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        [self performSave];
    }
}

- (void) performSave {
    
    if (self.measurementSession) {
        
        self.measurementSession.reducingEquipment = [NSNumber numberWithBool:self.reducingEquipmentSwitch.on];
        self.measurementSession.dose = [self getDoseValue];
        self.measurementSession.boomHeight = [self getBoomHeightValue];
        self.measurementSession.sprayQuality = [self getSprayQualityValue];
        self.measurementSession.generalConsideration = self.generalDistance;
        self.measurementSession.specialConsideration = self.specialDistance;
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
        
        if ([self.navigationController.viewControllers[0] isKindOfClass:[AgriMeasureViewController class]]) {
            
            AgriMeasureViewController *measureController = self.navigationController.viewControllers[0];
            [measureController reset];
            [self.navigationController popToViewController:measureController animated:YES];
        }
    }
}

@end
