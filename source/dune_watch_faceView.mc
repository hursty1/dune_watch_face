import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Sensor;
import Toybox.Time.Gregorian;
import Toybox.Application.Properties;
import Toybox.ActivityMonitor;


public var sand_color = 0xc8793c;
public var _secondary_color;   
public var _primary_color;
public var _draw_second_hand;
public var _use_bold_font;
public var _display_icons;
public var _font_sm as FontResource?;
public var _bottomComplication;
public var _showBattery;

class dune_watch_faceView extends WatchUi.WatchFace {
    private var _font as FontResource?;
    // private var _font_bl as FontResource?;
    // private var _font_ty as FontResource?;
    private var _garmin_icons as FontResource?;
    private var _partialUpdatesAllowed as Boolean;
    private var _isAwake as Boolean?;
    private var _font_height as Numeric;
    private var _width as Numeric;
    private var _height as Numeric;
     
    // private var _sand;
    private var _second_fill as Boolean;

    function initialize() {
        WatchFace.initialize();
        _width = 0;
        _height = 0;
        _second_fill = true;
        _partialUpdatesAllowed = (WatchUi.WatchFace has :onPartialUpdate);
        _isAwake = true;
        _secondary_color = Properties.getValue("SecondaryColor");
        _primary_color = Properties.getValue("PrimaryColor");
        _draw_second_hand = Properties.getValue("UseSecondsCircle");
        _use_bold_font = Properties.getValue("UseBoldFont");
        _display_icons = Properties.getValue("DisplayIcons");
        _bottomComplication = Properties.getValue("BottomComplication");
        _showBattery = Properties.getValue("ShowBattery");
        _font_height = 0;
        
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        // setLayout(Rez.Layouts.WatchFace(dc));
        
        _font = WatchUi.loadResource($.Rez.Fonts.dune_rise) as FontResource;
        if (_use_bold_font) {
            _font_sm = WatchUi.loadResource($.Rez.Fonts.dune_rise_text_bold) as FontResource;

        } else {
            _font_sm = WatchUi.loadResource($.Rez.Fonts.dune_rise_text) as FontResource;

        }

        // _font_ty = WatchUi.loadResource($.Rez.Fonts.ty_dune_rise) as FontResource;
        _garmin_icons = WatchUi.loadResource($.Rez.Fonts.garmin_icons) as FontResource;

        // setLayout(Rez.Layouts.WatchFace(dc)); 

        _width = dc.getWidth();
        _height = dc.getHeight();

        _font_height = Graphics.getFontHeight(_font);
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        
    }
    // Update the view
    function onUpdate(dc as Dc) as Void {

        View.onUpdate(dc); //update the layout.xml file
        if (_showBattery){
            drawBatteryComplication(dc);
        }
        drawBottomComplication(dc);

        var timeFormat = "$1$ $2$";
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        
        if (!System.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            }
        } 
        else {
            if (Properties.getValue("UseMilitaryFormat")){
                timeFormat = "$1$ $2$";
                hours = hours.format("%02d");
            }
        }

        var timeString = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);
        // var font = _font;
        // System.println("font size is:" + _font_height);
        
        if (_font != null){
            dc.setColor(_primary_color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                _width / 2,
                _height / 2 - _font_height * 0.6, //offset is 1/2 font size
                _font,
                timeString,
                Graphics.TEXT_JUSTIFY_CENTER);
        }

        drawDateString(
            dc, 
            _width/ 2, 
            _height - (_height/ 3)
        );

        // System.println(_partialUpdatesAllowed);
        if (_draw_second_hand){
            if (_partialUpdatesAllowed) {
                // If this device supports partial updates and they are currently
                // allowed run the onPartialUpdate method to draw the second hand.
                particalUpdate(dc);
            } else if (_isAwake) {
                drawSecondArc(dc, clockTime.sec);
            }
        }
    }
    private function particalUpdate(dc as Dc) as Void {
        var clockTime = System.getClockTime();
        drawSecondArc(dc, clockTime.sec);
    }

    function drawBatteryComplication(dc as Dc) as Void {
        /* 
        draw outside box
        draw positive terminal
        fill with small box
        */
        var fontSize = dc.getFontHeight(Graphics.FONT_SYSTEM_XTINY);
        var width = 40;
        var height = width / 2;
        var x = _width / 2;
        var y = _height / 6;
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        // dc.fillRectangle(x, y, width, height);
        dc.setPenWidth(1);
        dc.drawLine(x, y, x, y+height);
        dc.drawLine(x, y+height, x + width, y+height);
        dc.drawLine(x+width, y+height, x+width, y);
        dc.drawLine(x+width, y, x, y);
        //draw plus line
        dc.setPenWidth(1);
        dc.drawLine(x+width+2, y + height /4, x+width+2, y+ (height/4*3));
        //fill with green
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        var batteryLevel = System.getSystemStats().battery;
        var range = width-3; //full
        if (batteryLevel < 25){
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        }
        // System.println(batteryLevel);
        var batt = (batteryLevel / 100) * range;
        dc.fillRectangle(x+2, y+2, batt, height-3);
        /* TEXT %        */
        var batStr = batteryLevel.format("%0d") + "%";
        dc.setColor(_secondary_color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x- 5, y - fontSize /4, Graphics.FONT_SYSTEM_XTINY, batStr, Graphics.TEXT_JUSTIFY_RIGHT);

    }

    function drawBottomComplication(dc as Dc) as Void {
        /*handle which one here */
        var x = _width / 2;
        var y = _height * 0.8;
        switch (_bottomComplication) {
            case 1:
                drawHeartRate(dc, x, y);
                break;
            case 2:
                drawSteps(dc, x, y);
                break;
            default:
                drawHeartRate(dc, x, y);
        }
        

    }

    function drawHeartRate(dc as Dc, x, y) as Void {
        /*
        x = center of the location text on right
        y = height of the location of complication

        */
        var heartRate = Activity.getActivityInfo().currentHeartRate;
        if (heartRate == null){
            heartRate = " --";
        }
        dc.setColor(_secondary_color,Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            x + _width * .01, 
            y, 
            _font_sm, 
            heartRate, 
            Graphics.TEXT_JUSTIFY_LEFT
        );
        var heartRateIconCode = 0x006D;
        if (!_display_icons){
            heartRateIconCode = "";
        } else {
            dc.drawText(
                x - _width * .01, 
                y - _height * .01, 
                _garmin_icons, 
                heartRateIconCode.toChar().toString(), 
                Graphics.TEXT_JUSTIFY_RIGHT
            );
        }
    }

    function drawSteps(dc as Dc, x, y) as Void {
        /*
        x = center of the location text on right
        y = height of the location of complication

        */
        var stepCount = ActivityMonitor.getInfo().steps;
        if (stepCount == null){
            stepCount = " --";
        }
        dc.setColor(_secondary_color,Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            x + _width * .01 - _width * 0.05, 
            y, 
            _font_sm, 
            stepCount, 
            Graphics.TEXT_JUSTIFY_LEFT
        );
        var stepCountIconCode = 0x00c5;
        if (!_display_icons){
            stepCountIconCode = "";
        } else{
            dc.drawText(
                x - _width * .01 - _width * 0.05, 
                y - _height * .01, 
                _garmin_icons, 
                stepCountIconCode.toChar().toString(), 
                Graphics.TEXT_JUSTIFY_RIGHT
            );
        }
    }

    function ChangeSettings() as Void {
        _secondary_color = Properties.getValue("SecondaryColor"); //when called from a different scope it doesn't have access to the vairables
        _primary_color = Properties.getValue("PrimaryColor");
        _draw_second_hand = Properties.getValue("UseSecondsCircle");
        _use_bold_font = Properties.getValue("UseBoldFont");
        _display_icons = Properties.getValue("DisplayIcons");
        _bottomComplication = Properties.getValue("BottomComplication");
        _showBattery = Properties.getValue("ShowBattery");
        if (_use_bold_font) {
            _font_sm = WatchUi.loadResource($.Rez.Fonts.dune_rise_text_bold) as FontResource;

        } else {
            _font_sm = WatchUi.loadResource($.Rez.Fonts.dune_rise_text) as FontResource;

        }
        
    }

    private function drawSecondArc(dc as Dc, sec as Number) as Void {
        var second_pos = 90 + (360 - (sec * 6));
        var penWidth = 8;
        
        dc.setColor(_secondary_color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(penWidth);

        if (_second_fill) { //filling
            if (sec != 0) {
                dc.drawArc(
                    _width / 2, 
                    _height / 2,  
                    _width / 2 - penWidth, 
                    Graphics.ARC_CLOCKWISE, 
                    90, 
                    second_pos
                );
            }
            if (sec == 59) {
                _second_fill = !_second_fill;
            }
        } else { //unfilling
            dc.drawArc(
                _width / 2, 
                _height / 2,  
                _width / 2 - penWidth, 
                Graphics.ARC_CLOCKWISE, 
                second_pos, 
                90
            );
            if (sec == 59) {
                _second_fill = !_second_fill;
            }
        }
        
    }

    private function drawDateString(dc as Dc, x as Number, y as Number) as Void {
        var info = Gregorian.info(Time.now(), Time.FORMAT_LONG);
        var dateStr = Lang.format("$1$ $2$ $3$", [info.day_of_week, info.month, info.day]);
        var font = _font_sm;
        
        dc.setColor(_secondary_color, Graphics.COLOR_TRANSPARENT);
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
