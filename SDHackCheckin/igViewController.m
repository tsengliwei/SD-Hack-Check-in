//
//  igViewController.m
//  ScanBarCodes
//
//  Created by Torrey Betts on 10/10/13.
//  Copyright (c) 2013 Infragistics. All rights reserved.
//

#import "ConfirmationViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "igViewController.h"

@interface igViewController () <AVCaptureMetadataOutputObjectsDelegate,UIAlertViewDelegate>
{
    AVCaptureSession *_session;
    AVCaptureDevice *_device;
    AVCaptureDeviceInput *_input;
    AVCaptureMetadataOutput *_output;
    AVCaptureVideoPreviewLayer *_prevLayer;
    PFObject *_student;
    UIView *_highlightView;
    UILabel *_label;
    CGRect highlightViewRect;
}
@end

@implementation igViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _highlightView = [[UIView alloc] init];
    _highlightView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
    _highlightView.layer.borderColor = [UIColor greenColor].CGColor;
    _highlightView.layer.borderWidth = 3;
    highlightViewRect = CGRectMake(38, 271, 269, 80);
    _highlightView.frame = highlightViewRect;
    [self.view addSubview:_highlightView];

    _label = [[UILabel alloc] init];
    _label.frame = CGRectMake(0, self.view.bounds.size.height - 40, self.view.bounds.size.width, 40);
    _label.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    _label.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.65];
    _label.textColor = [UIColor whiteColor];
    _label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_label];
    [self startScanning];
    }

- (void)startScanning
{
    _label.text = @"Scanning";
    _session = [[AVCaptureSession alloc] init];
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    if (_input) {
        [_session addInput:_input];
    } else {
        NSLog(@"Error: %@", error);
    }
    
    _output = [[AVCaptureMetadataOutput alloc] init];
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [_session addOutput:_output];
    
    _output.metadataObjectTypes = [_output availableMetadataObjectTypes];
    
    _prevLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _prevLayer.frame = self.view.bounds;
    _prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:_prevLayer];
    
    [_session startRunning];
    
    [self.view bringSubviewToFront:_highlightView];
    [self.view bringSubviewToFront:_label];

}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    AVMetadataMachineReadableCodeObject *barCodeObject;
    NSString *detectionString = nil;
    NSString *studentName = nil;
    NSArray *barCodeTypes = @[AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code,
            AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeCode128Code,
            AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeAztecCode];

    for (AVMetadataObject *metadata in metadataObjects) {
        for (NSString *type in barCodeTypes) {
            if ([metadata.type isEqualToString:type])
            {
                barCodeObject = (AVMetadataMachineReadableCodeObject *)[_prevLayer transformedMetadataObjectForMetadataObject:(AVMetadataMachineReadableCodeObject *)metadata];
                highlightViewRect = barCodeObject.bounds;
                detectionString = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
                break;
            }
        }

        if (detectionString != nil)
        {
            NSString *correctID = [detectionString substringToIndex:[detectionString length]-1];
            PFQuery *query = [PFQuery queryWithClassName:@"student"];
            [query whereKey:@"studentID" equalTo:correctID];
            NSArray *foundObjects = [query findObjects];
            if ([foundObjects count]) {
                _label.text = @"Scanned";
                NSLog(@" data %@",[query findObjects]);
                _student = [[query findObjects] firstObject];
                NSLog(@" data %@",_student);
                NSLog(@" data %@",_student[@"fname"]);
                studentName = [_student[@"fname"] stringByAppendingString:@" "];
                studentName = [studentName stringByAppendingString:_student[@"lname"]];
                [_session stopRunning];
            }
            break;
        }
        else
            _label.text = @"Scanning";
    }
    
    if (studentName) {
        [[[UIAlertView alloc] initWithTitle:@"Is this the person you want to check in?"
                                    message:studentName
                                   delegate:self
                          cancelButtonTitle:nil
                          otherButtonTitles:@"Yes", @"Retry",nil] show];
    }
    
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            NSLog(@"YES Pressed");
            _label.text = @"Scanning";
            [self updateCheckin];
            [_session startRunning];
            break;
        case 1:
            NSLog(@"RETRY Pressed");
            _label.text = @"Scanning";
            [_session startRunning];
            break;
        default:
            break;
    }
}

- (void)updateCheckin
{
    PFQuery *query = [PFQuery queryWithClassName:@"student"];
    [query getObjectInBackgroundWithId:_student.objectId
                                 block:^(PFObject *student, NSError *error) {
                                     [student incrementKey:@"Checkin"];
                                     [student saveInBackground];
                                 }];
}

@end
