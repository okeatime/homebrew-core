class LibtorrentRasterbar < Formula
  desc "C++ bittorrent library by Rasterbar Software"
  homepage "http://www.libtorrent.org/"
  url "https://github.com/arvidn/libtorrent/releases/download/libtorrent-1_0_10/libtorrent-rasterbar-1.0.10.tar.gz"
  sha256 "a865ceaca8b14acdd7be56d361ce4e64361299647e157ef7b3ac7e2812ca4c3e"

  bottle do
    root_url "https://builds.shiki.hu/homebrew"
    cellar :any
    sha256 "cecada444ad372924a53792f93853f6933337e6e429e8b6c198a3cf7e6ef964f" => :sierra
    sha256 "cecada444ad372924a53792f93853f6933337e6e429e8b6c198a3cf7e6ef964f" => :el_capitan
    sha256 "cecada444ad372924a53792f93853f6933337e6e429e8b6c198a3cf7e6ef964f" => :yosemite
  end

  head do
    url "https://github.com/arvidn/libtorrent.git", :branch => "RC_1_0"
    depends_on "automake" => :build
    depends_on "autoconf" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkg-config" => :build
  depends_on "openssl"
  depends_on :python => :optional
  depends_on "geoip" => :optional
  depends_on "boost"
  depends_on "boost-python" if build.with? "python"

  def install
    args = ["--disable-debug",
            "--disable-dependency-tracking",
            "--disable-silent-rules",
            "--enable-encryption",
            "--prefix=#{prefix}",
            "--with-boost=#{Formula["boost"].opt_prefix}"]

    #Enable C++11
    args << "CXXFLAGS=-std=c++11"

    # Build python bindings requires forcing usage of the mt version of boost_python.
    if build.with? "python"
      args << "--enable-python-binding"
      args << "--with-boost-python=boost_python-mt"
    end

    if build.with? "geoip"
      args << "--enable-geoip"
      args << "--with-libgeoip"
    end

    if build.head?
      system "./autotool.sh", *args
    end

    system "./configure", *args
    system "make", "-j4"
    system "make", "install"
    libexec.install "examples"
  end

  test do
    system ENV.cxx, "-L#{lib}", "-ltorrent-rasterbar",
           "-I#{Formula["boost"].include}/boost", "-lboost_system",
           libexec/"examples/make_torrent.cpp", "-o", "test"
    system "./test", test_fixtures("test.mp3"), "-o", "test.torrent"
    File.exist? testpath/"test.torrent"
  end
end
