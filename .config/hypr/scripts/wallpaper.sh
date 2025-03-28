default_dir="$HOME/wallpapers/.defaults"
wallpaper_cache_dir="$HOME/wallpapers/.cache"
blurred_wallpaper="$default_dir/blurred-wallpaper.png"
squarred_wallpaper="$default_dir/squared-wallpaper.png"
blur="50x30"

if [ ! -d $default_dir ]; then
    echo ":: Wallpaper defaults directory does not exist. Creating one..."
    mkdir $default_dir
fi

if [ ! -d $wallpaper_cache_dir ]; then
    echo ":: Wallpaper cache directory does not exist. Creating one..."
    mkdir $wallpaper_cache_dir
fi

if [ -z $1 ]; then
    echo ':: No wallpaper was selected. Aborting...'
    exit
else
    wallpaper=$1
fi

wallpaperbasefilename=$(basename $wallpaper)
wallpaperfilename="${wallpaperbasefilename%.*}"
echo ":: Wallpaper Filename: $wallpaperfilename"

if [ -f $wallpaper_cache_dir/blur-$blur-$wallpaperfilename.png ]; then
    echo ":: Use cached wallpaper blur-$blur-$wallpaperfilename"
else
    echo ":: Generate new cached wallpaper blur-$blur-$wallpaperfilename with blur $blur"
    magick $wallpaper -resize 75% $blurred_wallpaper
    echo ":: Resized to 75%"
    if [ ! "$blur" == "0x0" ]; then
        magick $blurred_wallpaper -blur $blur $blurred_wallpaper
        cp $blurred_wallpaper $wallpaper_cache_dir/blur-$blur-$wallpaperfilename.png
        echo ":: Blurred"
    fi
fi

cp $wallpaper_cache_dir/blur-$blur-$wallpaperfilename.png $blurred_wallpaper

if [ -f $wallpaper_cache_dir/square-$wallpaperfilename.png ]; then
    echo ':: Use cached wallpaper square-$wallpaperfilename'
else
    echo ":: Generate new cached wallpaper square-$wallpaperfilename"
    magick $wallpaper -gravity Center -extent 1:1 $squarred_wallpaper
    cp $squarred_wallpaper $wallpaper_cache_dir/square-$wallpaperfilename.png
    echo ":: Squared"
fi

cp $wallpaper_cache_dir/square-$wallpaperfilename.png $squarred_wallpaper
