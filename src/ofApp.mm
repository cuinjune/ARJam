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
    
    cameraAnchorDistance = 100.0f;
    

    light.setOrientation(ofQuaternion(120, ofVec3f(1, 0, 0)));
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
                
                const ofVec3f &anchorPosition = anchorMatrix4x4.getTranslation();
                cameraAnchorDistance = anchorPosition.distance(cameraPosition);
                
                ofEnableDepthTest();
                ofEnableLighting();
                light.enable();
                
                
                ofPushMatrix();
                ofPushStyle();
                ofMultMatrix(anchorMatrix4x4);
                
                const float boxWidth = 0.15;
                const float boxHeight = 0.1125;
                const float boxDepth = 0.03;
           
                material.begin();
                ofDrawBox(boxWidth, boxDepth, boxHeight);
                material.end();
                
                material2.begin();
                
                
                const float buttonDepth = 0.004;
                ofDrawBox(-boxWidth/2 + boxWidth/6, 0, -boxHeight/2 + boxHeight/4, boxWidth/3 - buttonDepth, boxDepth + buttonDepth, boxHeight/2 - buttonDepth);
                
                ofDrawBox(0, 0, -boxHeight/2 + boxHeight/4, boxWidth/3, boxDepth + buttonDepth, boxHeight/2 - buttonDepth);
                
                ofDrawBox(boxWidth/2 - boxWidth/6, 0, -boxHeight/2 + boxHeight/4, boxWidth/3 - buttonDepth, boxDepth + buttonDepth, boxHeight/2 - buttonDepth);
                
                ofDrawBox(-boxWidth/2 + boxWidth/6, 0, boxHeight/2 - boxHeight/4, boxWidth/3 - buttonDepth, boxDepth + buttonDepth, boxHeight/2 - buttonDepth);
                
                ofDrawBox(0, 0, boxHeight/2 - boxHeight/4, boxWidth/3, boxDepth + buttonDepth, boxHeight/2 - buttonDepth);
                
                ofDrawBox(boxWidth/2 - boxWidth/6, 0, boxHeight/2 - boxHeight/4, boxWidth/3 - buttonDepth, boxDepth + buttonDepth, boxHeight/2 - buttonDepth);
                
                
                
                material2.end();
                
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
    else {
        if (cameraAnchorDistance < 0.2f) {

            ofPushMatrix();
            ofPushStyle();
            ofSetRectMode(OF_RECTMODE_CENTER);
            const float boxWidth = screenWidth * 0.95;
            const float boxHeight = screenHeight * 0.95;
            const float buttonDepth = screenHeight * 0.025;
             ofTranslate(ofGetWidth()/2, ofGetHeight()/2);
            ofSetColor(255, 255, 255, 200);
            ofDrawRectangle(0, 0, boxWidth, boxHeight);
            
            ofSetColor(100, 100, 100, 200);
            ofDrawRectangle(-boxWidth/2 + boxWidth/6, -boxHeight/2 + boxHeight/4, boxWidth/3 - buttonDepth, boxHeight/2 - buttonDepth);
            ofDrawRectangle(0, -boxHeight/2 + boxHeight/4, boxWidth/3 - buttonDepth, boxHeight/2 - buttonDepth);
            ofDrawRectangle(boxWidth/2 - boxWidth/6, -boxHeight/2 + boxHeight/4, boxWidth/3 - buttonDepth, boxHeight/2 - buttonDepth);
            
            ofDrawRectangle(-boxWidth/2 + boxWidth/6, boxHeight/2 - boxHeight/4, boxWidth/3 - buttonDepth, boxHeight/2 - buttonDepth);
            ofDrawRectangle(0, boxHeight/2 - boxHeight/4, boxWidth/3 - buttonDepth, boxHeight/2 - buttonDepth);
            ofDrawRectangle(boxWidth/2 - boxWidth/6, boxHeight/2 - boxHeight/4, boxWidth/3 - buttonDepth, boxHeight/2 - buttonDepth);
            ofPopStyle();
            ofPopMatrix();
            
        }
        
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
