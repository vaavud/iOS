//
//  AgriManualTemperatureViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 02/10/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#define MIN_TEMP_CELCIUS -40
#define MAX_TEMP_CELCIUS 60
#define DEFAULT_TEMP_CELCIUS 15

#import "AgriManualTemperatureViewController.h"

@interface AgriManualTemperatureViewController ()

@property (weak, nonatomic) IBOutlet UILabel *explanationLabel;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIPickerView *temperaturePickerView;

@end

@implementation AgriManualTemperatureViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.nextButton setTitle:NSLocalizedString(@"BUTTON_NEXT", nil) forState:UIControlStateNormal];
    self.nextButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.nextButton.layer.masksToBounds = YES;
    
    self.navigationItem.title = NSLocalizedString(@"AGRI_ENTER_TEMPERATURE", nil);
    self.navigationItem.backBarButtonItem.title = NSLocalizedString(@"NAVIGATION_BACK", nil);
    
    self.explanationLabel.text = NSLocalizedString(@"AGRI_ENTER_TEMPERATURE_EXPLANATION", nil);
    
    self.temperaturePickerView.dataSource = self;
    self.temperaturePickerView.delegate = self;
    
    NSInteger startTemp = (self.measurementSession && self.measurementSession.temperature && ([self.measurementSession.temperature floatValue] > 0)) ? roundf([self.measurementSession.temperature floatValue] - KELVIN_TO_CELCIUS) : DEFAULT_TEMP_CELCIUS;
    [self.temperaturePickerView selectRow:(startTemp - MIN_TEMP_CELCIUS) inComponent:0 animated:NO];
}

- (IBAction)nextButtonClicked:(id)sender {
    NSNumber *temperatureKelvin = [NSNumber numberWithInteger:[self.temperaturePickerView selectedRowInComponent:0] + MIN_TEMP_CELCIUS + KELVIN_TO_CELCIUS];
    if (self.measurementSession) {
        self.measurementSession.temperature = temperatureKelvin;
        
        NSLog(@"[AgriManualTemperatureViewController] Next with temperature=%@", self.measurementSession.temperature);
        
        if (self.hasDirection) {
            [self performSegueWithIdentifier:@"resultSegue" sender:self];
        }
        else {
            [self performSegueWithIdentifier:@"manualDirectionSegue" sender:self];
        }
    }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger) pickerView:(UIPickerView*)pickerView numberOfRowsInComponent:(NSInteger)component {
    return MAX_TEMP_CELCIUS - MIN_TEMP_CELCIUS;
}

- (NSString*) pickerView:(UIPickerView*)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [NSString stringWithFormat:@"%d °C", row + MIN_TEMP_CELCIUS];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    UIViewController *controller = [segue destinationViewController];
    
    if ([controller conformsToProtocol:@protocol(MeasurementSessionConsumer)]) {
        UIViewController<MeasurementSessionConsumer> *consumer = (UIViewController<MeasurementSessionConsumer>*) controller;
        [consumer setMeasurementSession:self.measurementSession];
        [consumer setHasTemperature:self.hasTemperature];
        [consumer setHasDirection:self.hasDirection];
    }
}

@end
