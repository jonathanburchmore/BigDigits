using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Graphics;
using Toybox.System;

class NotificationCount extends WatchUi.Drawable {
    var font;
    
    function initialize(dictionary) {
        dictionary.put(:identifier, "NotificationCount");
        Drawable.initialize(dictionary);
        
        font = WatchUi.loadResource(Rez.Fonts.id_suunto_font_25px);
    }

    function draw(dc) {
        var app = Application.getApp();
        var settings = System.getDeviceSettings();
        var info = ActivityMonitor.getInfo();
        
        if (settings.notificationCount) {
            dc.setColor(app.getProperty("NotificationBackground"), Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(locX, locY, 14);
            dc.setColor(app.getProperty("NotificationForeground"), Graphics.COLOR_TRANSPARENT);
            
            if (settings.notificationCount > 9) {
                dc.drawText(locX, locY - 1, font, "+", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
            }
            else {
                dc.drawText(locX, locY - 1, font, settings.notificationCount.format("%d"), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }
        else if (info.steps < info.stepGoal) {
            dc.setColor(app.getProperty("StepGoalCenter"), Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(locX, locY, 14);

            dc.setPenWidth(4);

            dc.setColor(app.getProperty("StepGoalIncomplete"), Graphics.COLOR_TRANSPARENT);
            dc.drawArc(locX, locY, 12, Graphics.ARC_CLOCKWISE, 90, 90);

            var percentComplete = info.steps.toFloat() / info.stepGoal;

            if (percentComplete > 1) {
                percentComplete = 1;
            }
            
            var degrees = 360 * percentComplete;
            if (degrees >= 1) {
                var end;
                
                if (degrees < 90) {
                    end = 90 - degrees;
                }
                else {
                    end = 360 - (degrees - 90);
                }
	
	            dc.setColor(app.getProperty("StepGoalComplete"), Graphics.COLOR_TRANSPARENT);
	            dc.drawArc(locX, locY, 12, Graphics.ARC_CLOCKWISE, 90, end);
	        }
        }
    }
}
