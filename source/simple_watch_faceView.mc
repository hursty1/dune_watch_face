import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Sensor;
import Toybox.Time.Gregorian;
import Toybox.Application.Properties;

class simple_watch_faceView extends WatchUi.WatchFace {
    private var _font as FontResource?;
    private var _font_sm as FontResource?;
    private var _font_ty as FontResource?;
    private var _partialUpdatesAllowed as Boolean;
    private var _isAwake as Boolean?;

    private var _width as Numeric;
    private var _height as Numeric;
    private var _font_px as Numeric;
    
    private var _sand;
    private var _second_fill as Boolean;

    function initialize() {
        WatchFace.initialize();
        _width = 0;
        _height = 0;
        _font_px = 92;
        _sand = 0xc8793c;
        _second_fill = true;
        _partialUpdatesAllowed = (WatchUi.WatchFace has :onPartialUpdate);
        _isAwake = true;
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        // setLayout(Rez.Layouts.WatchFace(dc));
        _font = WatchUi.loadResource($.Rez.Fonts.big_dune_rise) as FontResource;
        _font_sm = WatchUi.loadResource($.Rez.Fonts.sm_dune_rise) as FontResource;
        _font_ty = WatchUi.loadResource($.Rez.Fonts.ty_dune_rise) as FontResource;

        setLayout(Rez.Layouts.WatchFace(dc)); 

        _width = dc.getWidth();
        _height = dc.getHeight();

    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }
    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Get the current time and format it correctly
        var heartRate = Activity.getActivityInfo().currentHeartRate;
        if (heartRate != null){
            heartRate = heartRate.toString();
        } else {
            heartRate = "--";
        }
        System.println( "Heart Rate: " + heartRate);
        var view = View.findDrawableById("HeartRate") as Text;
        view.setText(heartRate);
        View.onUpdate(dc);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        // dc.clear();

        // dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
        // dc.fillCircle(_x.toNumber(), _y.toNumber(), _r);

        var timeFormat = "$1$ $2$";
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        

        if (!System.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            }
        } else {
            if (Properties.getValue("UseMilitaryFormat")){
                timeFormat = "$1$ $2$";
                hours = hours.format("%02d");
            }

        }
        var timeString = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);

        var font = _font;
        if (font != null){
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                _width / 2,
                _height / 2 - _font_px * 0.6, //offset is 1/2 font size
                font,
                timeString,
                Graphics.TEXT_JUSTIFY_CENTER);
        }

        // dc.drawText( //draw heart rate
        //     _width / 2,
        //     _height - _height / 5,
        //     _font_ty,
        //     heartRate,
        //     Graphics.TEXT_JUSTIFY_CENTER
        // );
        // System.println("can partical update: " + Toybox.WatchUi.WatchFace has :onPartialUpdate);
        drawDateString(dc, _width/ 2, _height/ 2 + 44);
        if (_partialUpdatesAllowed) {
            // If this device supports partial updates and they are currently
            // allowed run the onPartialUpdate method to draw the second hand.
            onPartialUpdate(dc);
        } else if (_isAwake) {
            // System.println( "Seconds: " + clockTime.sec);
            drawSecondArc(dc, clockTime.sec);
        }
    }
    private function particalUpdate(dc as Dc) as Void {
        var clockTime = System.getClockTime();
        System.print("Particial update");
        drawSecondArc(dc, clockTime.sec);
    }
    private function drawSecondArc(dc as Dc, sec as Number) as Void {
        var second_pos = 90 + (360 - (sec * 6));
        dc.setColor(_sand, Graphics.COLOR_TRANSPARENT);
        // second_pos = 90; //debug
        // _second_fill = true; //debug
        if (_second_fill) { //filling
            if (sec != 0) {
                dc.drawArc(_width / 2, _height / 2,  _width / 2 - 5, Graphics.ARC_CLOCKWISE, 90, second_pos);
            }
            if (sec == 59) {
                _second_fill = !_second_fill;
            }
        } else { //unfilling
            dc.drawArc(_width / 2, _height / 2,  _width / 2 - 5, Graphics.ARC_CLOCKWISE, second_pos, 90);
            if (sec == 59) {
                _second_fill = !_second_fill;
            }
        }
        
    }
    private function drawDateString(dc as Dc, x as Number, y as Number) as Void {
        var info = Gregorian.info(Time.now(), Time.FORMAT_LONG);
        var dateStr = Lang.format("$1$ $2$ $3$", [info.day_of_week, info.month, info.day]);
        var font = _font_sm;
        
        dc.setColor(_sand, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, dateStr, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        _isAwake = true;
    }


    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        _isAwake = false;
        WatchUi.requestUpdate();
    }

    //! Turn off partial updates
    public function turnPartialUpdatesOff() as Void {
        _partialUpdatesAllowed = false;
    }

}
