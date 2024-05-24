{ pkgs, specialArgs, system, ...}: {

  ##########################################################################
  #
  #  Install all apps and packages here.
  #
  #  NOTE: Your can find all available options in:
  #    https://daiderd.com/nix-darwin/manual/index.html
  #
  # TODO Fell free to modify this file to fit your needs.
  #
  ##########################################################################

  # Install packages from nix's official package repository.
  #
  # The packages installed here are available to all users, and are reproducible across machines, and are rollbackable.
  # But on macOS, it's less stable than homebrew.
  #
  # Related Discussion: https://discourse.nixos.org/t/darwin-again/29331
  #
  environment.systemPackages = with pkgs; [
    atuin # A shell history replacement that provides advanced features like syncing and advanced searching.
    btop # A resource monitor that shows usage and stats for processor, memory, disks, network, and processes.
    devenv # A development environment manager to configure and switch between development environments easily.
    git # A distributed version control system designed to handle everything from small to very large projects with speed and efficiency.
    multitail # Allows you to monitor logfiles and command output in multiple windows in a terminal, interactively.
    specialArgs.roc.packages.${specialArgs.system}.cli
    specialArgs.roc.packages.${specialArgs.system}.lang-server
    fastfetch # A command-line tool that displays system information alongside an operating system's logo in an aesthetically pleasing format
    tmux # A terminal multiplexer that lets you switch easily between several programs in one terminal, detach them, and reattach them to a different terminal.
  ];

  # TODO To make this work, homebrew need to be installed manually, see https://brew.sh
  #
  # The apps installed by homebrew are not managed by nix, and not reproducible!
  # But on macOS, homebrew has a much larger selection of apps than nixpkgs, especially for GUI apps!

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      # 'zap': uninstalls all formulae(and related files) not listed here.
      # cleanup = "zap";
    };

    taps = [
      "homebrew/cask-fonts"
      "homebrew/services"
      "homebrew/cask-versions"
    ];

    # `brew install`
    # TODO Feel free to add your favorite apps here.
    brews = [
      "awscli" # The official Amazon AWS command-line interface for managing AWS services.
      "coreutils" # A set of command line utilities fundamental to both the GNU and Unix operating systems.
      "curl" # A tool and libcurl library for transferring data with URLs.
      "direnv" # An environment switcher for the shell that loads and unloads environment variables depending on the current directory.
      "ffmpeg" # A complete, cross-platform solution to record, convert and stream audio and video.
      "freeimage" # An open-source library that supports popular graphics image formats.
      "fswatch" # A cross-platform file change monitor that uses the operating system's native event monitoring interface to notify about changes.
      "gcc" # The GNU Compiler Collection - a robust suite of compilers for C, C++, and other programming languages.
      "gmp" # A free library for arbitrary precision arithmetic, operating on signed integers, rational numbers, and floating-point numbers.
      "gpg" # GNU Privacy Guard, a data encryption and decryption program that provides cryptographic privacy and authentication.
      "imagemagick" # A powerful tool for creating, editing, and converting bitmap images.
      "libsndfile" # A C library for reading and writing files containing sampled sound through one standard library interface.
      "libsodium" # A modern, easy-to-use software library for encryption, decryption, signatures, password hashing, and more.
      "libxml2" # A library for parsing XML documents.
      {
        name = "mariadb@10.3";
        restart_service = "changed";
        link = true;
      } # A robust, scalable, and reliable SQL server forked from MySQL.
      "mas" # Mac App Store command-line interface.
      "md5sha1sum" # Utilities for computing message digests including MD5 and SHA1.
      "media-info" # A convenient unified display of the most relevant technical and tag data for video and audio files.
      "mpg123" # A fast console MPEG Audio Player and decoder library.
      "mysql" # A popular database management system used for managing relational databases.
      "mysql-client" # Client programs and libraries for MySQL database access.
      "ollama" # Create, run, and share large language models (LLMs)
      "openssl@1.1" # A robust, commercial-grade, full-featured toolkit for the Transport Layer Security (TLS) and Secure Sockets Layer (SSL) protocols.
      "readline" # A library for providing a set of functions for use by applications that allow users to edit command lines as they are typed in.
      {
        name = "redis";
        restart_service = "changed";
      } # An in-memory data structure store, used as a database, cache, and message broker.
      "sox" # A cross-platform command line utility that can convert various formats of computer audio files into other formats.
      "sqlite" # A C library that implements an SQL database engine.
      "unixodbc" # An open-source ODBC (Open Database Connectivity) library for accessing database systems.
      "wget" # A free utility for non-interactive download of files from the web.
      "zstd" # A fast compression algorithm, providing high compression ratios.
    ];

    # `brew install --cask`
    # TODO Feel free to add your favorite apps here.
    casks = [
      "docker"
      "wezterm@nightly" # a GPU-accelerated terminal emulator and multiplexer written in Rust, offering advanced features and performance for developers.
    ];
  };
}
