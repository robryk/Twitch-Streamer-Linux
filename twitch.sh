#! /bin/bash 

# Copyright (c) 2013, Giovanni Dante Grazioli (deroad)

# ================================================ OPTIONS =====================================================
# Streaming Options
OUTRES="1280x720"    # Twitch Output Resolution
FPS="30"             # Frame per Seconds (Suggested 24, 25, 30 or 60)
THREADS="4"          # Change this if you have a good CPU (Suggested 4 threads, Max 6 threads)
QUALITY="medium"     # ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow, placebo
CRF_VAL="23"	     # Is the quality of the encoding. 0 (lossless) and 51 (bad quality). 23 is medium quality

# Webcam Options
WEBCAM="/dev/video1" # WebCam device
WEBCAM_WH="320:240"  # WebCam Width end Height

# You can find YOUR key here: http://www.twitch.tv/broadcast/ (Show Key button)
# Save your key inside the twitch_key file
STREAM_KEY=$(cat twitch_key)

# Twitch Server list http://bashtech.net/twitch/ingest.php
SERVER="live-fra"    # EU server

# ============================================== END OPTIONS ===================================================
# The following values are changed automatically, so do not change them
TOPXY="0,0"          # Position of the Window (You don't need to change this)
INRES="0x0"          # Game Resolution (You don't need to change this)
CBR="400k"           # Constant bitrate (CBR) 

# ================================================= CHECKS =====================================================
# checks to avoid a false "true" where it checks for the webcam
if [ -z "$WEBCAM" ]; then
	echo "Your Webcam has been disabled because there isn't a WEBCAM in the options"
	WEBCAM="/dev/no-webcam"
else 
# checks to avoid a fail on loading the Webcam
	if [ -z "$WEBCAM_WH" ]; then
		echo "Your Webcam has been disabled because there isn't a WEBCAM_WH in the options"
		WEBCAM="/dev/no-webcam"
	fi
fi


# checks to avoid fails
if [ -z "$SERVER" ]; then
     SERVER="live"
fi
if [ -z "$OUTRES" ]; then
     OUTRES="1280x720"
fi
if [ -z "$FPS" ]; then
     FPS="30"
fi
if [ -z "$THREADS" ]; then
     THREADS="4"
fi
if [ -z "$QUALITY" ]; then
     QUALITY="fast"
fi
if [ -z "$CBR" ]; then
     CBR="400k"
fi
if [ -z "$CRF_VAL" ]; then
     CRF_VAL="23"
fi

# ================================================= CODE =======================================================
# DO NOT CHANGE THE CODE!

streamWebcam(){
        echo "Webcam found!!"
        echo "You should be online! Check on http://twitch.tv/ (Press CTRL+C to stop)"
        avconv -f x11grab -s $INRES  -r "$FPS" -i :0.0+$TOPXY  -f alsa -ac 2 -i pulse -vcodec libx264 -s $OUTRES -b $CBR -minrate $CBR -maxrate $CBR -preset $QUALITY -tune film -crf $CRF_VAL -qscale:v 1 -threads:v $THREADS -acodec libmp3lame -ar 44100 -threads $THREADS -qscale:a 1 -bufsize 512k -vf "movie=$WEBCAM:f=video4linux2, scale=$WEBCAM_WH , setpts=PTS-STARTPTS [WebCam]; [in] setpts=PTS-STARTPTS, [WebCam] overlay=main_w-overlay_w-10:10 [out]" -force_key_frames 2 -b $CBR -minrate $CBR -maxrate $CBR -g 2 -keyint_min 2  -f flv "rtmp://$SERVER.twitch.tv/app/$STREAM_KEY"
}

streamNoWebcam(){
        echo "Webcam NOT found!! ("$WEBCAM")"
        echo "You should be online! Check on http://twitch.tv/ (Press CTRL+C to stop)"
        avconv -f x11grab -s $INRES -r "$FPS" -i :0.0+$TOPXY  -f alsa -ac 2 -i pulse -vcodec libx264 -s $OUTRES -b $CBR -minrate $CBR -maxrate $CBR -preset $QUALITY -tune film -crf $CRF_VAL -qscale:v 1 -threads:v $THREADS -acodec libmp3lame -ar 44100 -threads $THREADS -qscale:a 1 -bufsize 512k -force_key_frames 2 -b $CBR -minrate $CBR -maxrate $CBR -g 2 -keyint_min 2 -f flv "rtmp://$SERVER.twitch.tv/app/$STREAM_KEY"
}


echo "Twitch Streamer for Linux"
echo "Copyright (c) 2013, Giovanni Dante Grazioli (deroad)"
echo " "

# Get Game Window
echo "Click, with the mouse, on the Window that you want to Stream"
WININFO=$(xwininfo -stats)
TOPXY=$(awk 'FNR == 8 {print $4}' <<< "$WININFO")","$(awk 'FNR == 9 {print $4}' <<< "$WININFO")
INRES=$(awk 'FNR == 12 {print $2}' <<< "$WININFO")"x"$(awk 'FNR == 13 {print $2}' <<< "$WININFO")
echo " "

# Setup
echo "Please setup the Audio Output (something like 'pavucontrol')"
# if you see errors here, please report on github
MODULE_LOAD1=$(pactl load-module module-null-sink sink_name=GameAudio) # For Game Audio
MODULE_LOAD2=$(pactl load-module module-null-sink sink_name=MicAudio ) # For Mic Audio
pactl load-module module-loopback sink=GameAudio >> /dev/null      
pactl load-module module-loopback sink=MicAudio >> /dev/null
echo " "

# Checks if the webcam is loaded
if [ -c $WEBCAM ]; then
     streamWebcam
else
     streamNoWebcam
fi
echo " "

# Closing..
echo "Stopping Audio (Don't worry if you see errors here)"
pactl unload-module $MODULE_LOAD1
pactl unload-module $MODULE_LOAD2
pactl unload-module module-null-sink
pactl unload-module module-loopback
echo "Exit!"

