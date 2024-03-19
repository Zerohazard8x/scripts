#!/bin/sh

if command -v aria2c; then
    mkdir ~/default_wall
    cd ~/default_wall || exit # exit if cd doesnt work

    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?hd-wallpapers" -o daily.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?artificial,hd-wallpapers" -o daily_artificial.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?cloudy,hd-wallpapers" -o daily_winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?cozy,hd-wallpapers" -o daily_cozy.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?drawing,hd-wallpapers" -o daily_drawing.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?dry,hd-wallpapers" -o daily_dry.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?fall,hd-wallpapers" -o daily_fall.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?rainy,hd-wallpapers" -o daily_winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?render,hd-wallpapers" -o daily_render.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?spring,hd-wallpapers" -o daily_spring.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?stormy,hd-wallpapers" -o daily_winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?summer,hd-wallpapers" -o daily_summer.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?sunny,hd-wallpapers" -o daily_winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?wet,hd-wallpapers" -o daily_wet.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?windy,hd-wallpapers" -o daily_windy.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?winter,hd-wallpapers" -o daily_winter.jpg

    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?artificial,hd-wallpapers" -o artificial.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?hd-wallpapers" -o weekly.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?cloudy,hd-wallpapers" -o winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?cozy,hd-wallpapers" -o cozy.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?drawing,hd-wallpapers" -o drawing.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?dry,hd-wallpapers" -o dry.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?fall,hd-wallpapers" -o fall.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?rainy,hd-wallpapers" -o winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?render,hd-wallpapers" -o render.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?spring,hd-wallpapers" -o spring.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?stormy,hd-wallpapers" -o winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?summer,hd-wallpapers" -o summer.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?sunny,hd-wallpapers" -o winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?wet,hd-wallpapers" -o wet.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?windy,hd-wallpapers" -o windy.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?winter,hd-wallpapers" -o winter.jpg

    # phone - 1644x3840
fi

exit