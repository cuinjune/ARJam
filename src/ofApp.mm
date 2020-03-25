#include "ofApp.h"

using namespace ofxARKit::common;

//--------------------------------------------------------------
ofApp::ofApp(ARSession *session) {
    this->session = session;
    cout << "creating ofApp" << endl;
}

ofApp::ofApp() {
}

//--------------------------------------------------------------
ofApp :: ~ofApp() {
    cout << "destroying ofApp" << endl;
}

//--------------------------------------------------------------
void ofApp::setup() {
    ofBackground(127);
    ofSetFrameRate(60);
    ofSetVerticalSync(true);
    
    //load assets
    ipadIcon.load("images/ipad.png");
    arrow.load("images/arrow.png");
    guideFont.load("fonts/Roboto-Regular.ttf", 32);
    
    //for debugging
    img.load("OpenFrameworks.png");
    font.load("fonts/mono0755.ttf", 16);
    
    screenWidth = ofGetWidth();
    screenHeight = ofGetHeight();
    ipadIconOffsetX = 0.0;
    cout << screenWidth << " " << screenHeight << endl;
    
    //initialize ARProcessor
    processor = ARProcessor::create(session);
    processor->deviceOrientationChanged(UIInterfaceOrientationLandscapeRight);
    processor->setup();
}

//--------------------------------------------------------------
void ofApp::update() {
    processor->update();
}

//--------------------------------------------------------------
void ofApp::draw() {
    
    ofEnableAlphaBlending();
    ofDisableDepthTest();
    processor->draw();
    ofEnableDepthTest();
    bool isPlaneAnchorFound = false;
    bool doesInstrumentExist = false;
    
    if (session.currentFrame) {
        if (session.currentFrame.camera) {
            const ofMatrix4x4 &cameraMatrix4x4 = convert<matrix_float4x4, ofMatrix4x4>(session.currentFrame.camera.transform);
            const ofVec3f &cameraPosition = cameraMatrix4x4.getTranslation();
            camera.begin();
            processor->setARCameraMatrices();
            
            bool doesClosestPlaneAnchorExist = false;
            float closestPlaneAnchorPositionY = 0.0f;
            
            for (int i = 0; i < session.currentFrame.anchors.count; i++) {
                ARAnchor *anchor = session.currentFrame.anchors[i];
                if ([anchor isKindOfClass:[ARPlaneAnchor class]]) {
                    const ofMatrix4x4 &planeAnchorMatrix4x4 = convert<matrix_float4x4, ofMatrix4x4>(anchor.transform);
                    const ofVec3f &planeAnchorPosition = planeAnchorMatrix4x4.getTranslation();
                    
                    if (planeAnchorPosition.y < cameraPosition.y - 0.1) {
                        if (doesClosestPlaneAnchorExist) {
                            if (planeAnchorPosition.y > closestPlaneAnchorPositionY) {
                                closestPlaneAnchorPositionY = planeAnchorPosition.y;
                            }
                        }
                        else {
                            closestPlaneAnchorPositionY = planeAnchorPosition.y;
                            doesClosestPlaneAnchorExist = true;
                        }
                    }
                }
                else {
                    ofPushMatrix();
                    ofMatrix4x4 mat = convert<matrix_float4x4, ofMatrix4x4>(anchor.transform);
                    ofMultMatrix(mat);
                    ofSetColor(255);
                    img.draw(-0.25 / 2, -0.25 / 2,0.25,0.25);
                    ofPopMatrix();
                    doesInstrumentExist = true;
                }
            }
            if (doesClosestPlaneAnchorExist) {
                ofPushMatrix();
                ofPushStyle();
                ofTranslate(0, closestPlaneAnchorPositionY);
                ofRotateXDeg(90);
                ofSetColor(255, 255, 255, 100);
                drawPlaneDots(50, 0.05f, 0.005f);
                ofPopStyle();
                ofPopMatrix();
                isPlaneAnchorFound = true;
            }
            camera.end();
        }
    }
    ofDisableDepthTest();
    // ========== DEBUG STUFF ============= //
    processor->debugInfo.drawDebugInformation(font);
    
    if (!isPlaneAnchorFound && !doesInstrumentExist) {
        
        //draw ipad icon
        ofPushMatrix();
        ofPushStyle();
        ofSetRectMode(OF_RECTMODE_CENTER);
        ofSetColor(255, 255, 255, 255);
        ipadIconOffsetX = ipadIconOffsetX < TWO_PI ? ipadIconOffsetX + 0.07 : 0.0;
        const int offsetX = static_cast<int>(sin(ipadIconOffsetX) * screenWidth * 0.05);
        ofTranslate(screenWidth * 0.5 + offsetX, screenHeight * 0.45);
        ipadIcon.draw(0, 0, screenWidth * 0.11, screenHeight * 0.1);
        arrow.draw(-screenWidth * 0.095, 0, -screenWidth * 0.039, screenHeight * 0.03);
        arrow.draw(screenWidth * 0.095, 0, screenWidth * 0.039, screenHeight * 0.03);
        ofPopStyle();
        ofPopMatrix();
        
        //draw guide font
        const string &guideText = "Looking for a surface to place your instrument";
        guideFont.drawString(guideText, screenWidth / 2 - guideFont.stringWidth(guideText) * 0.5, screenHeight * 0.575);
    }
}

//--------------------------------------------------------------
void ofApp::exit() {
}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs &touch) {
    
    //remove all plane anchors
    for (int i = 0; i < session.currentFrame.anchors.count; i++) {
        ARAnchor * anchor = session.currentFrame.anchors[i];
        if([anchor isKindOfClass:[ARPlaneAnchor class]]) {
            [session removeAnchor:anchor];
        }
    }
    
////    reset the AR Tracking
//    [session runWithConfiguration:session.configuration options:ARSessionRunOptionResetTracking];
  
    
    if (session.currentFrame) {
        ARFrame *currentFrame = [session currentFrame];
        matrix_float4x4 translation = matrix_identity_float4x4;
        translation.columns[3].z = -1; //-0.2
        matrix_float4x4 transform = matrix_multiply(currentFrame.camera.transform, translation);

        // Add a new anchor to the session
        ARAnchor *anchor = [[ARAnchor alloc] initWithTransform:transform];
        [session addAnchor:anchor];
    }
    
    
    
    

    
    
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs &touch) {
}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs &touch) {
}

//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs &touch) {
}

//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs &touch) {
}

//--------------------------------------------------------------
void ofApp::lostFocus() {
}

//--------------------------------------------------------------
void ofApp::gotFocus() {
}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning() {
}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation) {

}

//--------------------------------------------------------------
void ofApp::drawPlaneDots(int num, float gap, float radius) {
    const int half = num / 2;
    for (int x = -half; x < half; ++x)
        for (int y = -half; y < half; ++y)
            ofDrawCircle(x * gap, y * gap, radius);
}
