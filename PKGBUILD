# Maintainer: Tom Meyers tom@odex.be
pkgname=system-updater
pkgver=r20.7cc776d
pkgrel=1
pkgdesc="TOS System updater takes care of migration old installs to newer versions"
arch=(any)
url="https://github.com/ODEX-TOS/system-updater"
_reponame="system-updater"
license=('MIT')

source=(
"git+https://github.com/ODEX-TOS/system-updater.git")
md5sums=('SKIP')
depends=('bash' 'curl')
makedepends=('git')

pkgver() {
  cd "$srcdir/$_reponame"
  printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}


build() {
    return 0;
}

package() {
        cd "$srcdir/$_reponame"
        install -Dm755 system-updater.sh "$pkgdir"/usr/bin/system-updater
        install -Dm755 system-updater.conf "$pkgdir"/etc/system-updater.conf
}
