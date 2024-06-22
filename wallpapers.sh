#!/bin/sh

# source.unsplash seems deprecated
# if command -v aria2c; then
#     mkdir ~/default_wall
#     cd ~/default_wall || exit # exit if cd doesnt work

#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/daily?hd-wallpapers" -o daily.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/daily?artificial,hd-wallpapers" -o daily_artificial.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/daily?cloudy,hd-wallpapers" -o daily_winter.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/daily?cozy,hd-wallpapers" -o daily_cozy.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/daily?drawing,hd-wallpapers" -o daily_drawing.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/daily?dry,hd-wallpapers" -o daily_dry.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/daily?fall,hd-wallpapers" -o daily_fall.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/daily?rainy,hd-wallpapers" -o daily_winter.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/daily?render,hd-wallpapers" -o daily_render.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/daily?spring,hd-wallpapers" -o daily_spring.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/daily?stormy,hd-wallpapers" -o daily_winter.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/daily?summer,hd-wallpapers" -o daily_summer.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/daily?sunny,hd-wallpapers" -o daily_winter.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/daily?wet,hd-wallpapers" -o daily_wet.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/daily?windy,hd-wallpapers" -o daily_windy.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/daily?winter,hd-wallpapers" -o daily_winter.jpg

#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/weekly?artificial,hd-wallpapers" -o artificial.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/weekly?hd-wallpapers" -o weekly.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/weekly?cloudy,hd-wallpapers" -o winter.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/weekly?cozy,hd-wallpapers" -o cozy.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/weekly?drawing,hd-wallpapers" -o drawing.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/weekly?dry,hd-wallpapers" -o dry.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/weekly?fall,hd-wallpapers" -o fall.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/weekly?rainy,hd-wallpapers" -o winter.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/weekly?render,hd-wallpapers" -o render.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/weekly?spring,hd-wallpapers" -o spring.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/weekly?stormy,hd-wallpapers" -o winter.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/weekly?summer,hd-wallpapers" -o summer.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/weekly?sunny,hd-wallpapers" -o winter.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/weekly?wet,hd-wallpapers" -o wet.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/weekly?windy,hd-wallpapers" -o windy.jpg
#     aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x2160/weekly?winter,hd-wallpapers" -o winter.jpg

#     # phone - 1644x3840
# fi

exit