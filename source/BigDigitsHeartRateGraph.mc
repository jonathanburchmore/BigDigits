using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Time;
using Toybox.Lang;
using Toybox.ActivityMonitor;
using Toybox.UserProfile;

class HeartRateGraph extends WatchUi.Drawable {
    var lastfg;
    var lastbg;
    var lastupdate;
    var buffer;
    
    function initialize(dictionary) {
        dictionary.put(:identifier, "HeartRateGraph");
        Drawable.initialize(dictionary);
    }
    
    function update() {
        var app = Application.getApp();
        var now = Time.now();
        
        var fg = app.getProperty("HeartRateGraphColor");
        var bg = app.getProperty("BackgroundColor");

        if (buffer == null || fg != lastfg || bg != lastbg) {
            buffer = new Graphics.BufferedBitmap( {
                :width => width,
                :height => height,
                :palette => [
                    bg,
                    fg
                ]
            } );
            
            lastfg = fg;
            lastbg = bg;
        }
        else if (lastupdate != null && now.subtract(lastupdate).value() < 60) {
            return;
        }

        lastupdate = now;
        
        var dc = buffer.getDc();
        dc.setColor(fg, bg);
        dc.clear();
        dc.setPenWidth(4);

        // Graph data
        var hrIterator = ActivityMonitor.getHeartRateHistory(new Time.Duration(3600), false);
        
        var scaleX;
        var scaleY;
        
        scaleX = width / 3600.0;

        var min_hr = hrIterator.getMin();
        var max_hr = hrIterator.getMax();
        
        if (min_hr == 0 && max_hr == 0) {
            return;
        }

        var user_min_hr = UserProfile.getProfile().restingHeartRate;
        var user_max_hr = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC)[5];
        
        if (user_min_hr != null && user_min_hr < min_hr) {
            min_hr = user_min_hr;
        }
        
        if (user_max_hr != null && user_max_hr > max_hr) {
            max_hr = user_max_hr;
        }

        if (min_hr == max_hr) {
            scaleY = min_hr;
        }
        else { 
            scaleY = (height - 4.0) / (max_hr - min_hr);
        }

        var sample = hrIterator.next();
        var pointX;
        var pointY;
        var lastPointX = null;
        var lastPointY = null;
        
        while (sample != null) {
            if (sample.heartRate == ActivityMonitor.INVALID_HR_SAMPLE) {
                lastPointX = null;
                lastPointY = null;
            }
            else {
                pointX = ((3600 - now.subtract(sample.when).value()) * scaleX);
                pointY = (height - 2) - ((sample.heartRate - min_hr) * scaleY);

                if (lastPointX == null || lastPointY == null) {
                    dc.drawPoint(pointX, pointY);
                }
                else {
                    dc.drawLine(lastPointX, lastPointY, pointX, pointY);
                }
                
                lastPointX = pointX;
                lastPointY = pointY;
            }
            
            sample = hrIterator.next();
        }
    }

    function draw(dc) {
        update();
        dc.drawBitmap(locX, locY, buffer);
    }
}
