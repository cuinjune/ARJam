#pragma once

#include "ofxiOS.h"
#include <ARKit/ARKit.h>
#include "ofxARKit.h"

class ofApp : public ofxiOSApp {
    public:
        // ====== functions ====== //
        ofApp(ARSession *session);
        ofApp();
        ~ofApp();
    
        void setup();
        void update();
        void draw();
        void exit();
	
        void touchDown(ofTouchEventArgs &touch);
        void touchMoved(ofTouchEventArgs &touch);
        void touchUp(ofTouchEventArgs &touch);
        void touchDoubleTap(ofTouchEventArgs &touch);
        void touchCancelled(ofTouchEventArgs &touch);

        void lostFocus();
        void gotFocus();
        void gotMemoryWarning();
        void deviceOrientationChanged(int newOrientation);
    
        
        // ====== variables ====== //
        ofCamera camera;
        ofImage ipadIcon, arrow, tapIcon;
        ofTrueTypeFont guideFont;
        int screenWidth, screenHeight;
        bool doesClosestPlaneAnchorExist, doesInstrumentExist;
        float closestPlaneAnchorPositionY;
        double ipadIconOffsetX, tapIconScaleAmt;
    
        float cameraAnchorDistance;
    
        ofLight light;
        ofMaterial material, material2;
    
        //for debugging
        ofTrueTypeFont font;
        ofImage img;
    
        bool anchorShouldAnimateToFront;
        float animationLerpAmount; //between 0 and 1
    
        ofCamera anchorCamera;
    
    bool button1Pressed, button2Pressed, button3Pressed, button4Pressed, button5Pressed, button6Pressed;
    
    ofSoundPlayer drum1, drum2, drum3, drum4, drum5, drum6;
    
    
        // ====== AR STUFF ======== //
        ARSession *session;
        ARRef processor;

};
