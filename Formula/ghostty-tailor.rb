class GhosttyTailor < Formula
  desc "GUI for tailoring your Ghostty configuration"
  homepage "https://github.com/dandelion0216/ghostty-tailor"
  url "https://github.com/dandelion0216/ghostty-tailor/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "4cf9a77c2a9c41dad11e5f1ddda3bcdc8ef3125ba880dfa9d8158716a71cc03f"
  license "MIT"
  head "https://github.com/dandelion0216/ghostty-tailor.git", branch: "main"

  depends_on "go" => :build

  on_linux do
    depends_on "pkgconf" => :build
    depends_on "gtk+3"
    depends_on "webkitgtk"
  end

  def install
    ENV["CGO_ENABLED"] = "1"
    prefix.install "THIRD_PARTY_NOTICES.md"

    on_linux do
      system "go", "build", *std_go_args(tags: %w[desktop production webkit2_41])
    end

    on_macos do
      # Built from source on the user's Mac, so the app is not quarantined and
      # Gatekeeper does not block it even though it is not notarized.
      ENV["CGO_LDFLAGS"] = "-framework UniformTypeIdentifiers"
      contents = prefix/"ghostty-tailor.app/Contents"
      system "go", "build", *std_go_args(tags: %w[desktop production], output: contents/"MacOS/ghostty-tailor")
      contents.install "packaging/macos/Info.plist"
      (contents/"Resources").install "packaging/macos/iconfile.icns"
      inreplace contents/"Info.plist", "0.0.0", version.to_s
      # Ad-hoc sign the whole bundle so its signature covers Info.plist and the icon.
      system "codesign", "--force", "--sign", "-", prefix/"ghostty-tailor.app"

      (bin/"ghostty-tailor").write <<~SH
        #!/bin/sh
        exec open "#{opt_prefix}/ghostty-tailor.app"
      SH
    end
  end

  def caveats
    s = <<~EOS
      Start ghostty-tailor with:
        ghostty-tailor
    EOS
    on_macos do
      s += <<~EOS

        To show it in Launchpad and Spotlight, link the app into ~/Applications:
          mkdir -p ~/Applications && ln -sf "#{opt_prefix}/ghostty-tailor.app" ~/Applications/
      EOS
    end
    s
  end

  test do
    assert_predicate bin/"ghostty-tailor", :executable?
    on_macos do
      assert_predicate prefix/"ghostty-tailor.app/Contents/MacOS/ghostty-tailor", :executable?
    end
  end
end
