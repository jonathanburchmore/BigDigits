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
    var lastsample;
    var lastsampleX;
    var buffer;
    var scaleX;
    var scaleY;
    
    function initialize(dictionary) {
        dictionary.put(:identifier, "HeartRateGraph");
        Drawable.initialize(dictionary);

        scaleX = width / 3600.0;
    }
    
    function update() {
        var app = Application.getApp();
        var now = Time.now();
        var duration;
        var dc;
        
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

            lastsample = null;
        }
        else if (lastupdate != null && now.subtract(lastupdate).value() < 55) {
            return;
        }
        
        if (lastsample) {
            duration = now.subtract(lastsample.when);
        }
        else {
            duration = new Time.Duration(3600);
        }
        
        // Graph data
        var hrIterator = ActivityMonitor.getHeartRateHistory(duration, false);

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

        var current_scaleY;

        if (min_hr == max_hr) {
            current_scaleY = min_hr;
        }
        else { 
            current_scaleY = (height - 4.0) / (max_hr - min_hr);
        }

        if (scaleY == null) {
            scaleY = current_scaleY;
        } else if (scaleY != current_scaleY) {
            /* Scale has changed.  Reset values and recurse to force a full redraw */

            scaleY = current_scaleY;
            lastsample = null;

            update();
        }

        lastupdate = now;

        if (lastsample == null) {
            dc = buffer.getDc();
            dc.setColor(fg, bg);
            dc.clear();
        }
        else {
            var new_lastsampleX = ((3600 - now.subtract(lastsample.when).value()) * scaleX);
            var offset = Math.floor(lastsampleX - new_lastsampleX);

            if (offset < 1) {
                return;
            }

            lastsampleX = new_lastsampleX;

            var newbuffer = new Graphics.BufferedBitmap( {
                :width => width,
                :height => height,
                :palette => [
                    bg,
                    fg
                ]
            } );

            dc = newbuffer.getDc();
            dc.setColor(fg, bg);
            dc.clear();

            dc.drawBitmap(0 - offset, 0, buffer);

            buffer = newbuffer;            
        }

        dc.setPenWidth(4);

        var sample = hrIterator.next();
        var pointX;
        var pointY;
        var lastPointX = null;
        var lastPointY = null;
        
        while (sample != null) {
            pointX = ((3600 - now.subtract(sample.when).value()) * scaleX);

            if (sample.heartRate == ActivityMonitor.INVALID_HR_SAMPLE) {
                lastPointX = pointX;
                lastPointY = null;
            }
            else {
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
            
            lastsample = sample;
            lastsampleX = pointX;

            sample = hrIterator.next();
        }
    }

    function draw(dc) {
        update();
        dc.drawBitmap(locX, locY, buffer);
    }
}
