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
#import "ServerUploadManager.h"
#import "AgriResultComputation.h"
#import "AgriSummaryViewController.h"

@interface AgriResultViewController ()

@property (nonatomic, weak) IBOutlet UILabel *windSpeedHeadingLabel;
@property (nonatomic, weak) IBOutlet UILabel *averageLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureHeadingLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureUnitLabel;
@property (weak, nonatomic) IBOutlet UILabel *windSpeedUnitLabel;
@property (weak, nonatomic) IBOutlet UILabel *directionHeadingLabel;
@property (weak, nonatomic) IBOutlet UILabel *directionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *directionImageView;
@property (weak, nonatomic) IBOutlet UILabel *reducingEquipmentHeadingLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *reducingEquipmentSegmentControl;
@property (weak, nonatomic) IBOutlet UILabel *doseHeadingLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *doseSegmentControl;
@property (weak, nonatomic) IBOutlet UILabel *boomHeightHeadingLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *boomHeightSegmentControl;
@property (weak, nonatomic) IBOutlet UILabel *sprayQualityHeadingLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sprayQualitySegmentControl;
@property (weak, nonatomic) IBOutlet UILabel *protectiveDistanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *generalDistanceHeadingLabel;
@property (weak, nonatomic) IBOutlet UILabel *generalDistanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *generalDistanceUnitLabel;
@property (weak, nonatomic) IBOutlet UILabel *specialDistanceHeadingLabel;
@property (weak, nonatomic) IBOutlet UILabel *specialDistanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *specialDistanceUnitLabel;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;

@property (nonatomic) WindSpeedUnit windSpeedUnit;
@property (nonatomic) NSInteger directionUnit;
@property (nonatomic, strong) NSNumber *generalDistance;
@property (nonatomic, strong) NSNumber *specialDistance;

@end

@implementation AgriResultViewController

- (void)viewDidLoad {
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

    [self.reducingEquipmentSegmentControl setTitle:NSLocalizedString(@"AGRI_REDUCING_EQUIPMENT_NONE", nil) forSegmentAtIndex:0];
    [self.reducingEquipmentSegmentControl setTitle:NSLocalizedString(@"AGRI_REDUCING_EQUIPMENT_50", nil) forSegmentAtIndex:1];
    [self.reducingEquipmentSegmentControl setTitle:NSLocalizedString(@"AGRI_REDUCING_EQUIPMENT_75", nil) forSegmentAtIndex:2];
    [self.reducingEquipmentSegmentControl setTitle:NSLocalizedString(@"AGRI_REDUCING_EQUIPMENT_90", nil) forSegmentAtIndex:3];

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

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.windSpeedUnit = [[Property getAsInteger:KEY_WIND_SPEED_UNIT] intValue];
    self.windSpeedUnitLabel.text = [UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit];
    
    NSNumber *directionUnitNumber = [Property getAsInteger:KEY_DIRECTION_UNIT];
    NSInteger directionUnit = (directionUnitNumber) ? [directionUnitNumber doubleValue] : 0;
    if (self.directionUnit != directionUnit) {
        self.directionUnit = directionUnit;
    }

    if (self.measurementSession.reduceEquipment && ([self.measurementSession.reduceEquipment intValue] > 0)) {
        [self setSelectedReducingEquipment:self.measurementSession.reduceEquipment];
    }
    else {
        [self setSelectedReducingEquipment:[Property getAsInteger:KEY_AGRI_DEFAULT_REDUCING_EQUIPMENT defaultValue:1]];
    }
    
    if (self.measurementSession && self.measurementSession.dose && ([self.measurementSession.dose floatValue] > 0.0F)) {
        [self setSelectedDose:self.measurementSession.dose];
    }
    else {
        [self setSelectedDose:[Property getAsFloat:KEY_AGRI_DEFAULT_DOSE defaultValue:0.25F]];
    }
    
    if (self.measurementSession.boomHeight && ([self.measurementSession.boomHeight intValue] > 0)) {
        [self setSelectedBoomHeight:self.measurementSession.boomHeight];
    }
    else {
        [self setSelectedBoomHeight:[Property getAsInteger:KEY_AGRI_DEFAULT_BOOM_HEIGHT defaultValue:25]];
    }
    
    if (self.measurementSession.sprayQuality && ([self.measurementSession.sprayQuality intValue] > 0)) {
        [self setSelectedSprayQuality:self.measurementSession.sprayQuality];
    }
    else {
        [self setSelectedSprayQuality:[Property getAsInteger:KEY_AGRI_DEFAULT_SPRAY_QUALITY defaultValue:1]];
    }
    
    if (self.measurementSession.startTime) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        
        self.navigationItem.title = [dateFormatter stringFromDate:self.measurementSession.startTime];
    }
    else {
        self.navigationItem.title = @"";
    }

    [self updateMeasuredValues];
    [self updateComputedValues];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Agri Result Screen"];
    }
}

- (void)updateMeasuredValues {
    if (self.measurementSession && self.measurementSession.windSpeedAvg && !isnan([self.measurementSession.windSpeedAvg doubleValue])) {
        self.averageLabel.text = [self formatValue:[UnitUtil displayWindSpeedFromDouble:[self.measurementSession.windSpeedAvg doubleValue] unit:self.windSpeedUnit]];
    }
    else {
        self.averageLabel.text = @"-";
    }
    
    if (self.measurementSession.windDirection && !isnan([self.measurementSession.windDirection doubleValue])) {
        
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
    
    if (self.measurementSession.temperature && [self.measurementSession.temperature floatValue] > 0.0) {
        self.temperatureLabel.text = [self formatValue:[self.measurementSession.temperature floatValue] - KELVIN_TO_CELCIUS];
    }
    else {
        self.temperatureLabel.text = @"-";
    }
}

- (void)updateComputedValues {
    if (self.measurementSession && self.measurementSession.windSpeedAvg && !isnan([self.measurementSession.windSpeedAvg doubleValue])
                                && self.measurementSession.temperature && [self.measurementSession.temperature floatValue] > 0.0) {

        NSNumber *reduceEquipment = [self getReducingEquipmentValue];
        NSNumber *dose = [self getDoseValue];
        NSNumber *boomHeight = [self getBoomHeightValue];
        NSNumber *sprayQuality = [self getSprayQualityValue];
        
        self.generalDistance = [[AgriResultComputation sharedInstance] generalConsideration:self.measurementSession.temperature windSpeed:self.measurementSession.windSpeedAvg reduceEquipment:reduceEquipment dose:dose boomHeight:boomHeight sprayQuality:sprayQuality];
        self.specialDistance = [[AgriResultComputation sharedInstance] specialConsideration:self.measurementSession.temperature windSpeed:self.measurementSession.windSpeedAvg reduceEquipment:reduceEquipment dose:dose boomHeight:boomHeight sprayQuality:sprayQuality];
        
        if (self.generalDistance && self.specialDistance && [self.generalDistance intValue] > 0 && [self.specialDistance intValue] > 0) {
            self.generalDistanceLabel.text = [self.generalDistance stringValue];
            self.specialDistanceLabel.text = [self.specialDistance stringValue];
        }
        else {
            self.generalDistanceLabel.text = @"-";
            self.specialDistanceLabel.text = @"-";
        }
    }
    else {
        self.generalDistance = nil;
        self.specialDistance = nil;
        self.generalDistanceLabel.text = @"-";
        self.specialDistanceLabel.text = @"-";
    }
}

- (NSString *)formatValue:(double)value {
    if (value > 100.0) {
        return [NSString stringWithFormat: @"%.0f", value];
    }
    else {
        return [NSString stringWithFormat: @"%.1f", value];
    }
}

- (void)setSelectedReducingEquipment:(NSNumber *)reduceEquipment {
    if (reduceEquipment) {
        int reducingEquipmentInt = [reduceEquipment intValue];
        if (reducingEquipmentInt == 1) {
            self.reducingEquipmentSegmentControl.selectedSegmentIndex = 0;
        }
        else if (reducingEquipmentInt == 2) {
            self.reducingEquipmentSegmentControl.selectedSegmentIndex = 1;
        }
        else if (reducingEquipmentInt == 3) {
            self.reducingEquipmentSegmentControl.selectedSegmentIndex = 2;
        }
        else if (reducingEquipmentInt == 4) {
            self.reducingEquipmentSegmentControl.selectedSegmentIndex = 3;
        }
        else {
            NSLog(@"[AgriResultViewController] ERROR: Unsupported reducing equipment %d setting UI", reducingEquipmentInt);
            self.reducingEquipmentSegmentControl.selectedSegmentIndex = 0;
        }
    }
    else {
        self.reducingEquipmentSegmentControl.selectedSegmentIndex = 0;
    }
}

- (void)setSelectedDose:(NSNumber *)dose {
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

- (void)setSelectedBoomHeight:(NSNumber*)boomHeight {
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

- (void)setSelectedSprayQuality:(NSNumber *)sprayQuality {
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

- (IBAction)reducingEquipmentValueChanged:(id)sender {
    [Property setAsInteger:[self getReducingEquipmentValue] forKey:KEY_AGRI_DEFAULT_REDUCING_EQUIPMENT];
    [self updateComputedValues];
}

- (NSNumber *)getReducingEquipmentValue {
    switch (self.reducingEquipmentSegmentControl.selectedSegmentIndex) {
        case 0:
            return @1;
        case 1:
            return @2;
        case 2:
            return @3;
        case 3:
            return @4;
        default:
            NSLog(@"[AgriResultViewController] ERROR: Unknown reducing equipment selected segment index %ld", (long)self.reducingEquipmentSegmentControl.selectedSegmentIndex);
            return @1;
    }
}

- (IBAction)doseSegmentControlValueChanged:(id)sender {
    [Property setAsFloat:[self getDoseValue] forKey:KEY_AGRI_DEFAULT_DOSE];
    [self updateComputedValues];
}

- (NSNumber *)getDoseValue {
    switch (self.doseSegmentControl.selectedSegmentIndex) {
        case 0:
            return @0.25f;
        case 1:
            return @0.5f;
        case 2:
            return @1.0f;
        default:
            NSLog(@"[AgriResultViewController] ERROR: Unknown dose selected segment index %ld", (long)self.doseSegmentControl.selectedSegmentIndex);
            return @1.0f;
    }
}

- (IBAction)boomHeightValueChanged:(id)sender {
    [Property setAsInteger:[self getBoomHeightValue] forKey:KEY_AGRI_DEFAULT_BOOM_HEIGHT];
    [self updateComputedValues];
}

- (NSNumber *)getBoomHeightValue {
    switch (self.boomHeightSegmentControl.selectedSegmentIndex) {
        case 0:
            return @25;
        case 1:
            return @40;
        case 2:
            return @60;
        default:
            NSLog(@"[AgriResultViewController] ERROR: Unknown boom height selected segment index %ld", (long)self.boomHeightSegmentControl.selectedSegmentIndex);
            return @60;
    }
}

- (IBAction)sprayQualityValueChanged:(id)sender {

    [Property setAsInteger:[self getSprayQualityValue] forKey:KEY_AGRI_DEFAULT_SPRAY_QUALITY];
    [self updateComputedValues];
}

- (NSNumber *)getSprayQualityValue {
    switch (self.sprayQualitySegmentControl.selectedSegmentIndex) {
        case 0:
            return @1;
        case 1:
            return @2;
        case 2:
            return @3;
        default:
            NSLog(@"[AgriResultViewController] ERROR: Unknown spray quality selected segment index %ld", (long)self.sprayQualitySegmentControl.selectedSegmentIndex);
            return @3;
    }
}

- (IBAction)saveButtonPushed:(id)sender {
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
        [summary appendFormat:@"%@: %@", NSLocalizedString(@"AGRI_REDUCING_EQUIPMENT", nil), [self.reducingEquipmentSegmentControl titleForSegmentAtIndex:self.reducingEquipmentSegmentControl.selectedSegmentIndex]];
        
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
                                                              [self saveAndShowSummary];
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

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        [self saveAndShowSummary];
    }
}

- (void)saveAndShowSummary {
    [self performSave];
    [self performSegueWithIdentifier:@"showSummaryAfterSaveSegue" sender:self];
}

- (void)performSave {
    if (self.measurementSession) {
        self.measurementSession.reduceEquipment = [self getReducingEquipmentValue];
        self.measurementSession.dose = [self getDoseValue];
        self.measurementSession.boomHeight = [self getBoomHeightValue];
        self.measurementSession.sprayQuality = [self getSprayQualityValue];
        self.measurementSession.generalConsideration = self.generalDistance;
        self.measurementSession.specialConsideration = self.specialDistance;
        self.measurementSession.uploaded = @NO;
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
        
        [[ServerUploadManager sharedInstance] triggerUpload];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *controller = [segue destinationViewController];
    if ([controller isKindOfClass:[AgriSummaryViewController class]]) {
        AgriSummaryViewController *summary = (AgriSummaryViewController *)controller;
        summary.measurementSession = self.measurementSession;
        summary.navigationItem.hidesBackButton = YES;

        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:summary
                                                                  action:@selector(popToMeasure:)];
        summary.navigationItem.rightBarButtonItem = button;
    }
}

@end
