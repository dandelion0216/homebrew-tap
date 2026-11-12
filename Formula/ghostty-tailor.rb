class GhosttyTailor < Formula
  desc "GUI for tailoring your Ghostty configuration"
  homepage "https://github.com/dandelion0216/ghostty-tailor"
  url "https://github.com/dandelion0216/ghostty-tailor/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "020a2931a195ed07b35362f3a7d36947924b1d1bee33f5bb02876dea251f91ed"
  license "MIT"
  head "https://github.com/dandelion0216/ghostty-tailor.git", branch: "main"

  depends_on "go" => :build
  depends_on :macos

  def install
    # Built from source on the user's Mac, so the app is not quarantined and
    # Gatekeeper does not block it even though it is not notarized.
    ENV["CGO_ENABLED"] = "1"
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

  def caveats
    <<~EOS
      Start ghostty-tailor with:
        ghostty-tailor

      To show it in Launchpad and Spotlight, link the app into ~/Applications:
        mkdir -p ~/Applications && ln -sf "#{opt_prefix}/ghostty-tailor.app" ~/Applications/
    EOS
  end

  test do
    assert_predicate prefix/"ghostty-tailor.app/Contents/MacOS/ghostty-tailor", :executable?
  end
end
