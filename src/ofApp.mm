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
    tapIcon.load("images/tap.png");
    guideFont.load("fonts/Roboto-Regular.ttf", 32);
    
    //for debugging
    img.load("OpenFrameworks.png");
    font.load("fonts/mono0755.ttf", 16);
    
    screenWidth = ofGetWidth();
    screenHeight = ofGetHeight();
    doesClosestPlaneAnchorExist = false;
    doesInstrumentExist = false;
    closestPlaneAnchorPositionY = 0.0f;
    ipadIconOffsetX = 0.0;
    tapIconScaleAmt = 0.0;
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
    
    if (session.currentFrame && session.currentFrame.camera) {
        const ofMatrix4x4 &cameraMatrix4x4 = toMat4(session.currentFrame.camera.transform);
        const ofVec3f &cameraPosition = cameraMatrix4x4.getTranslation();
        camera.begin();
        processor->setARCameraMatrices();
        doesClosestPlaneAnchorExist = false;
//        closestPlaneAnchorPositionY = 0.0f;
        
        for (int i = 0; i < session.currentFrame.anchors.count; i++) {
            ARAnchor *anchor = session.currentFrame.anchors[i];
            if ([anchor isKindOfClass:[ARPlaneAnchor class]]) {
                if (doesInstrumentExist) continue;
                const ofMatrix4x4 &planeAnchorMatrix4x4 = toMat4(anchor.transform);
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
            else { //handle non-plane anchors
                ofPushMatrix();
                ofPushStyle();
                cout << anchorMatrix4x4 << endl;
                ofMultMatrix(anchorMatrix4x4);
                ofSetColor(0, 255, 0, 255);
                ofNoFill();
                ofSetBoxResolution(10, 10, 10);
                ofDrawBox(0.15, 0.03, 0.08);
                ofPopStyle();
                ofPopMatrix();
            }
        }
        if (!doesInstrumentExist && doesClosestPlaneAnchorExist) {
            //draw plane dots
            ofPushMatrix();
            ofPushStyle();
            ofTranslate(0, closestPlaneAnchorPositionY);
            ofRotateXDeg(90);
            ofSetColor(255, 255, 255, 100);
            for (int x = -25; x < 25; ++x) {
                for (int y = -25; y < 25; ++y) {
                    ofDrawCircle(x * 0.05f, y * 0.05f, 0.005f);
                }
            }
            ofPopStyle();
            ofPopMatrix();
        }
        camera.end();
    }
    ofDisableDepthTest();
    // ========== DEBUG STUFF ============= //
    processor->debugInfo.drawDebugInformation(font);
    
    if (!doesInstrumentExist) {
        ofPushStyle();
        ofSetColor(255, 255, 255, 255);
        ofSetRectMode(OF_RECTMODE_CENTER);
        if (!doesClosestPlaneAnchorExist) {
            //draw ipad icon
            ofPushMatrix();
            ipadIconOffsetX = ipadIconOffsetX < TWO_PI ? ipadIconOffsetX + 0.06 : 0.0;
            const double offsetX = sin(ipadIconOffsetX) * screenWidth * 0.02;
            ofTranslate(screenWidth * 0.5 + offsetX, screenHeight * 0.45);
            ipadIcon.draw(0, 0, screenWidth * 0.11, screenHeight * 0.1);
            arrow.draw(-screenWidth * 0.095, 0, -screenWidth * 0.039, screenHeight * 0.03);
            arrow.draw(screenWidth * 0.095, 0, screenWidth * 0.039, screenHeight * 0.03);
            ofPopMatrix();
            
            //draw guide font
            const string &guideText = "Looking for a surface to place your instrument";
            guideFont.drawString(guideText, screenWidth / 2 - guideFont.stringWidth(guideText) * 0.5, screenHeight * 0.575);
        }
        else {
            //draw tap icon
            ofPushMatrix();
            ofTranslate(screenWidth * 0.5, screenHeight * 0.45);
            tapIconScaleAmt = tapIconScaleAmt < TWO_PI ? tapIconScaleAmt + 0.12 : 0.0;
            const double scaleAmt = sin(tapIconScaleAmt) * 0.1;
            ofScale(1 + scaleAmt);
            tapIcon.draw(0, 0, screenWidth * 0.053, screenHeight * 0.1);
            ofPopMatrix();
            
            //draw guide font
            const string &guideText = "Surface Detected! Now tap a location to place the instrument";
            guideFont.drawString(guideText, screenWidth / 2 - guideFont.stringWidth(guideText) * 0.5, screenHeight * 0.575);
        }
        ofPopStyle();
    }
    
}

//--------------------------------------------------------------
void ofApp::exit() {
}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs &touch) {
    
////    reset the AR Tracking
//    [session runWithConfiguration:session.configuration options:ARSessionRunOptionResetTracking];
    
    if (!doesInstrumentExist && doesClosestPlaneAnchorExist) {
        if (session.currentFrame && session.currentFrame.camera) {
            //remove all plane anchors
            for (int i = 0; i < session.currentFrame.anchors.count; i++) {
                ARAnchor *anchor = session.currentFrame.anchors[i];
                if([anchor isKindOfClass:[ARPlaneAnchor class]]) {
                    [session removeAnchor:anchor];
                }
            }
            doesClosestPlaneAnchorExist = false;
            
            //create instrument anchor
            ARFrame *currentFrame = [session currentFrame];
            matrix_float4x4 translation = matrix_identity_float4x4;
//            translation.columns[3].z = -0.2; //-0.2
            matrix_float4x4 transform = matrix_multiply(currentFrame.camera.transform, translation);

            

            // Add a new anchor to the session
            ARAnchor *anchor = [[ARAnchor alloc] initWithTransform:transform];
            [session addAnchor:anchor];
            
            
//            processor->addAnchor(ofVec3f(touch.x + 0.25/2,touch.y + 0.25/2,0));
            doesInstrumentExist = true;
            
            
            
            
            
            // somehow do all these above before adding the anchor?
            const ofMatrix4x4 &cameraMatrix4x4 = toMat4(session.currentFrame.camera.transform);
            anchorMatrix4x4 = toMat4(anchor.transform);
            ofQuaternion q = cameraMatrix4x4.getRotate();
            q.set(0.0, q.y(), 0.0, q.w());
            anchorMatrix4x4.setRotate(q);
            
            ofVec3f anchorPosition = anchorMatrix4x4.getTranslation();
            anchorPosition.y = closestPlaneAnchorPositionY + 0.0;
            anchorPosition.z -= 0.2;
            anchorMatrix4x4.setTranslation(anchorPosition);
        }
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
