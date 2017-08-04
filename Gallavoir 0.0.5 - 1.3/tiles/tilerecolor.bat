C:\Users\Nick\Desktop\imagick\magick convert "%~1" ^
 ( -clone 0 ^
      -fill "#f4988c" -opaque %2 ^
      -fill "#d93a3a" -opaque %3 ^
      -fill "#932625" -opaque %4 ^
      -fill "#601119" -opaque %5 ) ^
 ( -clone 0 ^
      -fill "#96cbe7" -opaque %2 ^
      -fill "#5588d4" -opaque %3 ^
      -fill "#344495" -opaque %4 ^
      -fill "#1a1c51" -opaque %5 ) ^
 ( -clone 0 ^
      -fill "#b2e89d" -opaque %2 ^
      -fill "#51bd3b" -opaque %3 ^
      -fill "#247824" -opaque %4 ^
      -fill "#144216" -opaque %5 ) ^
 ( -clone 0 ^
      -fill "#ffffa7" -opaque %2 ^
      -fill "#e2c344" -opaque %3 ^
      -fill "#a46e06" -opaque %4 ^
      -fill "#642f00" -opaque %5 ) ^
 ( -clone 0 ^
      -fill "#ffd495" -opaque %2 ^
      -fill "#ea9931" -opaque %3 ^
      -fill "#a46e06" -opaque %4 ^
      -fill "#642f00" -opaque %5 ) ^
 ( -clone 0 ^
      -fill "#eab3db" -opaque %2 ^
      -fill "#d35eae" -opaque %3 ^
      -fill "#97276d" -opaque %4 ^
      -fill "#59163f" -opaque %5 ) ^
 ( -clone 0 ^
      -fill "#838383" -opaque %2 ^
      -fill "#555555" -opaque %3 ^
      -fill "#383838" -opaque %4 ^
      -fill "#151515" -opaque %5 )^
 ( -clone 0 ^
      -fill "#e6e6e6" -opaque %2 ^
      -fill "#b6b6b6" -opaque %3 ^
      -fill "#7b7b7b" -opaque %4 ^
      -fill "#373737" -opaque %5 )^
 -append new\"%~1"