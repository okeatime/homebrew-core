class Folly < Formula
  desc "Collection of reusable C++ library artifacts developed at Facebook"
  homepage "https://github.com/facebook/folly"
  url "https://github.com/facebook/folly/archive/v2016.12.12.00.tar.gz"
  sha256 "ea96682d14423506136edb51a0a761573f50814c1634eb06f1b5d1ea6038cb44"
  head "https://github.com/facebook/folly.git"

  bottle do
    cellar :any
    sha256 "eac9c0ff803ff2a0eff04df3c2a1bd0554ffbee531edba7842265f327d0f6bfe" => :sierra
    sha256 "f8d93406a168817c5993a161dc82191ae1837e89f367eca95bbe7dae490a0581" => :el_capitan
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "double-conversion"
  depends_on "glog"
  depends_on "gflags"
  depends_on "boost"
  depends_on "libevent"
  depends_on "xz"
  depends_on "snappy"
  depends_on "lz4"
  depends_on "jemalloc"
  depends_on "openssl"

  # https://github.com/facebook/folly/issues/451
  depends_on :macos => :el_capitan

  needs :cxx11

  # Known issue upstream. They're working on it:
  # https://github.com/facebook/folly/pull/445
  fails_with :gcc => "6"

  def install
    ENV.cxx11

    cd "folly" do
      if MacOS.version == "10.11" && MacOS::Xcode.installed? && MacOS::Xcode.version >= "8.0"
        # Workaround for "no matching function for call to 'clock_gettime'"
        # See upstream PR from 2 Oct 2016 facebook/folly#488
        inreplace ["Benchmark.cpp", "Benchmark.h"] do |s|
          s.gsub! "clock_gettime(CLOCK_REALTIME",
                  "clock_gettime((clockid_t)CLOCK_REALTIME"
          s.gsub! "clock_getres(CLOCK_REALTIME",
                  "clock_getres((clockid_t)CLOCK_REALTIME", false
        end

        # Fix "candidate function not viable: no known conversion from
        # 'folly::detail::Clock' to 'clockid_t' for 1st argument"
        # See upstream PR mentioned above
        inreplace "portability/Time.h", "typedef uint8_t clockid_t;", ""
      end

      # Build system relies on pkg-config but gflags removed
      # the .pc files so now folly cannot find without flags.
      ENV["GFLAGS_CFLAGS"] = Formula["gflags"].opt_include
      ENV["GFLAGS_LIBS"] = Formula["gflags"].opt_lib

      system "autoreconf", "-fvi"
      system "./configure", "--prefix=#{prefix}", "--disable-silent-rules",
                            "--disable-dependency-tracking",
                            "--with-jemalloc"
      system "make"
      system "make", "install"
    end
  end

  test do
    (testpath/"test.cc").write <<-EOS.undent
      #include <folly/FBVector.h>
      int main() {
        folly::fbvector<int> numbers({0, 1, 2, 3});
        numbers.reserve(10);
        for (int i = 4; i < 10; i++) {
          numbers.push_back(i * 2);
        }
        assert(numbers[6] == 12);
        return 0;
      }
    EOS
    system ENV.cxx, "-std=c++11", "test.cc", "-I#{include}", "-L#{lib}",
                    "-lfolly", "-o", "test"
    system "./test"
  end
end
