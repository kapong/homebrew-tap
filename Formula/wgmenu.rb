class Wgmenu < Formula
  desc "Menu bar app to run multiple WireGuard tunnels at once"
  homepage "https://github.com/kapong/WGMenu"
  url "https://github.com/kapong/WGMenu/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "9efebbb6e0aec61e370a75f5732fda16c2c3d4b2bad087439d286589427ff160"
  license "MIT"

  depends_on arch: :arm64
  depends_on "bash"
  depends_on macos: :ventura
  depends_on "wireguard-go"
  depends_on "wireguard-tools"

  def install
    system "./build.sh"
    prefix.install "build/WGMenu.app"
    pkgshare.install "helper/wgctl"
    # Point setup at the stable opt paths and symlink the app into /Applications.
    inreplace "wgmenu-setup" do |s|
      s.gsub! 'HELPER_SRC="$HERE/helper/wgctl"', "HELPER_SRC=\"#{opt_pkgshare}/wgctl\""
      s.gsub! 'APP_SRC="$HERE/build/WGMenu.app"', "APP_SRC=\"#{opt_prefix}/WGMenu.app\""
      s.gsub! "LINK_APP=0", "LINK_APP=1"
    end
    bin.install "wgmenu-setup"
  end

  def caveats
    <<~EOS
      One-time root setup (installs the helper to /usr/local/sbin/wgctl, copies the
      WireGuard tools into /usr/local/libexec/wgmenu, adds a narrow sudoers rule,
      and links WGMenu.app into /Applications):
        sudo wgmenu-setup

      Open the app and choose Import Config… to add .conf files:
        open /Applications/WGMenu.app

      To remove the root pieces before `brew uninstall wgmenu`:
        sudo wgmenu-setup --uninstall

      After `brew upgrade` of wgmenu, wireguard-tools, wireguard-go or bash, re-run
      `sudo wgmenu-setup` to refresh the helper and its root-owned copies of
      wg-quick, wg, wireguard-go and bash in /usr/local/libexec/wgmenu.

      Upgrading to 0.4.0: the helper changed, so `sudo wgmenu-setup` must be re-run.
    EOS
  end

  test do
    assert_match "Usage", shell_output("#{bin}/wgmenu-setup --help")
    assert_match "Run with sudo", shell_output("#{bin}/wgmenu-setup 2>&1", 1)
    assert_match "arm64", shell_output("lipo -archs #{prefix}/WGMenu.app/Contents/MacOS/WGMenu")
  end
end
