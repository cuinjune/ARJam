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
    
    cameraAnchorDistance = numeric_limits<float>::max();
    
    light.setOrientation(ofQuaternion(180, ofVec3f(1, 0, 0)));
    light.setDirectional();
    light.setSpecularColor(ofColor(0,0,0));
    light.setDiffuseColor(ofColor(200, 200, 200));
    light.setAmbientColor(ofColor(0));
    
    material.setSpecularColor(ofColor(100,100,100));
    material.setDiffuseColor(ofColor(200, 200, 200));
    material.setAmbientColor(ofColor(0));
    material.setEmissiveColor(ofColor(50, 50, 50));
    material.setShininess(120);
    
    material2.setSpecularColor(ofColor(50,50,50));
    material2.setDiffuseColor(ofColor(100, 100, 100));
    material2.setAmbientColor(ofColor(0));
    material2.setEmissiveColor(ofColor(25, 25, 25));
    material2.setShininess(60);
    
    anchorShouldAnimateToFront = false;
    animationLerpAmount = 0.0f;
    
    anchorCamera.setNearClip(0.1f);
    
    button1Pressed = false;
    button2Pressed = false;
    button3Pressed = false;
    button4Pressed = false;
    button5Pressed = false;
    button6Pressed = false;
    
    drum1.load("sounds/drum1.wav");
    drum2.load("sounds/drum2.wav");
    drum3.load("sounds/drum3.wav");
    drum4.load("sounds/drum4.wav");
    drum5.load("sounds/drum5.wav");
    drum6.load("sounds/drum6.wav");
    drum1.setVolume(0.75);
    drum2.setVolume(0.75);
    drum3.setVolume(0.75);
    drum4.setVolume(0.75);
    drum5.setVolume(0.75);
    drum6.setVolume(0.75);

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
        closestPlaneAnchorPositionY = 0.0f;
        
        for (int i = 0; i < session.currentFrame.anchors.count; i++) {
            ARAnchor *anchor = session.currentFrame.anchors[i];
            if ([anchor isKindOfClass:[ARPlaneAnchor class]]) { //handle plane anchors
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
            else { //handle instrument anchors
                
                const ofMatrix4x4 &anchorMatrix4x4 = toMat4(anchor.transform);
                const ofVec3f &anchorPosition = anchorMatrix4x4.getTranslation();
                cameraAnchorDistance = anchorPosition.distance(cameraPosition);
                
                ofEnableDepthTest();
                ofEnableLighting();
                light.enable();
                
                ofPushMatrix();
                ofPushStyle();
                
                bool isUsingAnchorCamera = false;
                if (cameraAnchorDistance < 0.2f) {
                    if (animationLerpAmount >= 1.0f) {
                        
                        anchorCamera.begin();
                        ofTranslate(0, 0, -0.12);
                        ofRotateXDeg(90);
                        animationLerpAmount = 1.0f;
                        isUsingAnchorCamera = true;
                    }
                    else { //make below a function and simplify?
                        const float animationLerpAmountPow2 = powf(animationLerpAmount, 2);
                        const ofVec3f &frontPosition = cameraPosition;
                        const ofVec3f &animatedAnchorPosition = anchorPosition.getInterpolated(frontPosition, animationLerpAmountPow2);

                        const ofVec4f &anchorRotation = anchorMatrix4x4.getRotate().asVec4();
                        const ofVec4f &frontRotation = cameraMatrix4x4.getRotate().asVec4();
                        const ofVec4f animatedAnchorRotation = anchorRotation.getInterpolated(frontRotation, animationLerpAmount);

                        ofMatrix4x4 animatedAnchorMatrix4x4;
                        animatedAnchorMatrix4x4.setTranslation(animatedAnchorPosition);
                        animatedAnchorMatrix4x4.setRotate(ofQuaternion(animatedAnchorRotation));
                        
                        ofMultMatrix(animatedAnchorMatrix4x4);
                        ofTranslate(0, 0, animationLerpAmountPow2 * -0.1625);
                        ofRotateXDeg(animationLerpAmount * 90);
                        animationLerpAmount += 0.1f;
                    }
                }
                else {
                    if (animationLerpAmount <= 0.0f) {
                     
                        ofMultMatrix(anchorMatrix4x4);
                        animationLerpAmount = 0.0f;
                    }
                    else { //make below a function and simplify?
                        const float animationLerpAmountPow2 = powf(animationLerpAmount, 2);
                        const ofVec3f &frontPosition = cameraPosition;
                        const ofVec3f &animatedAnchorPosition = anchorPosition.getInterpolated(frontPosition, animationLerpAmountPow2);

                        const ofVec4f &anchorRotation = anchorMatrix4x4.getRotate().asVec4();
                        const ofVec4f &frontRotation = cameraMatrix4x4.getRotate().asVec4();
                        const ofVec4f animatedAnchorRotation = anchorRotation.getInterpolated(frontRotation, animationLerpAmount);

                        ofMatrix4x4 animatedAnchorMatrix4x4;
                        animatedAnchorMatrix4x4.setTranslation(animatedAnchorPosition);
                        animatedAnchorMatrix4x4.setRotate(ofQuaternion(animatedAnchorRotation));
                        
                        ofMultMatrix(animatedAnchorMatrix4x4);
                        ofTranslate(0, 0, animationLerpAmountPow2 * -0.1625);
                        ofRotateXDeg(animationLerpAmount * 90);
                        animationLerpAmount -= 0.1f;
                    }
                }
                const float boxWidth = 0.15;
                const float boxHeight = 0.1125;
                const float boxDepth = 0.03;
           
                material.begin();
                ofDrawBox(boxWidth, boxDepth, boxHeight); //instrument body
                material.end();
                
                material2.begin();
                const float buttonGap = 0.004f;
                const float button1Depth = button1Pressed ? 0.001f : 0.004f;
                const float button2Depth = button2Pressed ? 0.001f : 0.004f;
                const float button3Depth = button3Pressed ? 0.001f : 0.004f;
                const float button4Depth = button4Pressed ? 0.001f : 0.004f;
                const float button5Depth = button5Pressed ? 0.001f : 0.004f;
                const float button6Depth = button6Pressed ? 0.001f : 0.004f;
                ofDrawBox(-boxWidth/2 + boxWidth/6, 0, -boxHeight/2 + boxHeight/4, boxWidth/3 - buttonGap, boxDepth + button1Depth, boxHeight/2 - buttonGap);
                ofDrawBox(0, 0, -boxHeight/2 + boxHeight/4, boxWidth/3, boxDepth + button2Depth, boxHeight/2 - buttonGap);
                ofDrawBox(boxWidth/2 - boxWidth/6, 0, -boxHeight/2 + boxHeight/4, boxWidth/3 - buttonGap, boxDepth + button3Depth, boxHeight/2 - buttonGap);
                ofDrawBox(-boxWidth/2 + boxWidth/6, 0, boxHeight/2 - boxHeight/4, boxWidth/3 - buttonGap, boxDepth + button4Depth, boxHeight/2 - buttonGap);
                ofDrawBox(0, 0, boxHeight/2 - boxHeight/4, boxWidth/3, boxDepth + button5Depth, boxHeight/2 - buttonGap);
                ofDrawBox(boxWidth/2 - boxWidth/6, 0, boxHeight/2 - boxHeight/4, boxWidth/3 - buttonGap, boxDepth + button6Depth, boxHeight/2 - buttonGap);
                material2.end();
                
                if (isUsingAnchorCamera) {
                    anchorCamera.end();
                }
                ofPopStyle();
                ofPopMatrix();
                
                light.disable();
                ofDisableLighting();
                ofDisableDepthTest();
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
            const string &guideText = "Looking for a well-textured surface to place your instrument on";
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
    // ========== DEBUG STUFF ============= //
    processor->debugInfo.drawDebugInformation(font);
}

//--------------------------------------------------------------
void ofApp::exit() {
}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs &touch) {
    
////    reset the AR Tracking
//    [session runWithConfiguration:session.configuration options:ARSessionRunOptionResetTracking];
    
    if (doesInstrumentExist) {
        
        const float boxWidth = screenWidth;
        const float boxHeight = screenHeight;
        
        const float buttonWidth = boxWidth / 3;
        const float buttonHeight = boxHeight / 2;
        
        ofRectangle button1(buttonWidth * 0, buttonHeight * 0, buttonWidth, buttonHeight);
        ofRectangle button2(buttonWidth * 1, buttonHeight * 0, buttonWidth, buttonHeight);
        ofRectangle button3(buttonWidth * 2, buttonHeight * 0, buttonWidth, buttonHeight);
        
        ofRectangle button4(buttonWidth * 0, buttonHeight * 1, buttonWidth, buttonHeight);
        ofRectangle button5(buttonWidth * 1, buttonHeight * 1, buttonWidth, buttonHeight);
        ofRectangle button6(buttonWidth * 2, buttonHeight * 1, buttonWidth, buttonHeight);
        
        if (button1.inside(touch.x, touch.y)) {
            drum1.play();
            button1Pressed = true;
        }
        if (button2.inside(touch.x, touch.y)) {
            drum2.play();
            button2Pressed = true;
        }
        if (button3.inside(touch.x, touch.y)) {
            drum3.play();
            button3Pressed = true;
        }
        if (button4.inside(touch.x, touch.y)) {
            drum4.play();
            button4Pressed = true;
        }
        if (button5.inside(touch.x, touch.y)) {
            drum5.play();
            button5Pressed = true;
        }
        if (button6.inside(touch.x, touch.y)) {
            drum6.play();
            button6Pressed = true;
        }
    }
    
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
            ofMatrix4x4 anchorMatrix4x4 = toMat4(session.currentFrame.camera.transform);
            ofQuaternion anchorRotation = anchorMatrix4x4.getRotate();
            anchorRotation.x() = 0.0f;
            anchorRotation.z() = 0.0f;
            anchorMatrix4x4.setRotate(anchorRotation);
            
            ofVec3f anchorPosition = anchorMatrix4x4.getTranslation();
            anchorPosition.y = closestPlaneAnchorPositionY;
            anchorPosition.z -= 0.2;
            anchorMatrix4x4.setTranslation(anchorPosition);
            
            ARAnchor *anchor = [[ARAnchor alloc] initWithTransform:toSIMDMat4(anchorMatrix4x4)];
            [session addAnchor:anchor];
            doesInstrumentExist = true;
        }
    }
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs &touch) {
}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs &touch) {

    button1Pressed = false;
    button2Pressed = false;
    button3Pressed = false;
    button4Pressed = false;
    button5Pressed = false;
    button6Pressed = false;
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
