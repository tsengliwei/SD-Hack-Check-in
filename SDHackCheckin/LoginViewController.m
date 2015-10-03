//
//  LoginViewController.m
//  SDHackCheckin
//
//  Created by Li-Wei Tseng on 10/3/15.
//  Copyright © 2015 liwei. All rights reserved.
//

#import "LoginViewController.h"
#import "igViewController.h"
@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.password.secureTextEntry = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)login:(id)sender {
    if ([self.username.text isEqualToString:@"UCLAACM"] && [self.password.text isEqualToString:@"meow"]) {
        self.username.text = @"";
        self.password.text = @"";
        UIViewController * vc = [[igViewController alloc] init];
        [self presentViewController:vc animated:YES completion:nil];
    }
    else {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Wrong Username or Password" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
