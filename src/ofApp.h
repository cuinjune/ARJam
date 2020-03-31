#pragma once

#include "ofxiOS.h"
#include <ARKit/ARKit.h>
#include "ofxARKit.h"

class ofApp : public ofxiOSApp {
    public:
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
    
        // ====== functions ====== //
        void drawPlaneDots(int num, float gap, float radius);
        
    
        // ====== variables ====== //
        ofCamera camera;
        ofImage ipadIcon, arrow, tapIcon;
        ofTrueTypeFont guideFont;
        int screenWidth, screenHeight;
        double ipadIconOffsetX, tapIconScaleAmt;
        
    
        //for debugging
        ofTrueTypeFont font;
        ofImage img;
        
    
        // ====== AR STUFF ======== //
        ARSession *session;
        ARRef processor;

};
