//
//  MenuViewController.m
//

#import "MyAppViewController.h"

#import "OFAppViewController.h"
#import "ofApp.h"
using namespace ofxARKit::core;
@interface MyAppViewController()
@property (nonatomic, strong) ARSession *session;
@end

@implementation MyAppViewController


- (void)loadView {
    [super loadView];
    
    SFormat format;
    format.enableLighting();
    self.session = generateNewSession(format);
    
    // World tracking is used for 6DOF, there are other tracking configurations as well, see
    // https://developer.apple.com/documentation/arkit/arconfiguration
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];

    // setup horizontal plane detection - note that this is optional
    configuration.planeDetection = ARPlaneDetectionHorizontal;

    // start the session
    [self.session runWithConfiguration:configuration];
    
    
    OFAppViewController *viewController;
    viewController = [[[OFAppViewController alloc] initWithFrame:[[UIScreen mainScreen] bounds]
                                                                 app:new ofApp(self.session)] autorelease];
    
    [self.navigationController setNavigationBarHidden:TRUE];
    [self.navigationController pushViewController:viewController animated:NO];
    self.navigationController.navigationBar.topItem.title = @"ofApp";
}

@end
