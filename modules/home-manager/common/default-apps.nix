{ ... }:

{
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/terminal" = [ "com.mitchellh.ghostty.desktop" ];

      "default-web-browser" = [ "firefox.desktop" ];
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox.desktop" ];

      "inode/directory" = [ "org.kde.dolphin.desktop" ];

      "application/pdf" = [ "firefox.desktop" ];

      "text/plain" = [ "code.desktop" ];
      "inode/x-empty" = [ "code.desktop" ];
      "text/markdown" = [ "code.desktop" ];
      "application/json" = [ "code.desktop" ];
      "application/xml" = [ "code.desktop" ];

      "image/png" = [ "qView.desktop" ];
      "image/jpeg" = [ "qView.desktop" ];
      "image/webp" = [ "qView.desktop" ];
      "image/gif" = [ "qView.desktop" ];
      "image/bmp" = [ "qView.desktop" ];
      "image/tiff" = [ "qView.desktop" ];
      "image/avif" = [ "qView.desktop" ];
      "image/heic" = [ "qView.desktop" ];
      "image/svg+xml" = [ "qView.desktop" ];

      "application/zip" = [ "org.kde.ark.desktop" ];
      "application/x-7z-compressed" = [ "org.kde.ark.desktop" ];
      "application/x-rar" = [ "org.kde.ark.desktop" ];
      "application/vnd.rar" = [ "org.kde.ark.desktop" ];
      "application/x-tar" = [ "org.kde.ark.desktop" ];
      "application/gzip" = [ "org.kde.ark.desktop" ];
      "application/x-gzip" = [ "org.kde.ark.desktop" ];
      "application/x-bzip" = [ "org.kde.ark.desktop" ];
      "application/x-bzip2" = [ "org.kde.ark.desktop" ];
      "application/x-xz" = [ "org.kde.ark.desktop" ];
      "application/zstd" = [ "org.kde.ark.desktop" ];
    };
  };
}
