import pytest

@pytest.mark.php
def test_php_images_contain_helper_scripts(host):
  helper_scripts = [
    "/usr/local/bin/docker-php-source-tarball",
    "/usr/local/bin/docker-php-source",
    "/usr/local/bin/docker-php-ext-install",
    "/usr/local/bin/docker-php-ext-enable",
    "/usr/local/bin/docker-php-ext-configure",
    "/usr/local/bin/docker-php-entrypoint",
  ]

  for file in helper_scripts:
    assert host.file(file).exists is True
    assert host.file(file).is_file is True
    assert host.file(file).mode == 0o775

@pytest.mark.php
def test_php_source_tarball_script(host):
  assert host.file("/usr/src/php.tar.xz").exists is False
  assert host.file("/usr/src/php.tar.xz.asc").exists is False
  assert host.file("/usr/src/php").exists is False

  host.run("apk add --no-cache gnupg")
  host.run("docker-php-source-tarball download")
  assert host.file("/usr/src/php.tar.xz").exists is True
  assert host.file("/usr/src/php.tar.xz.asc").exists is True
  assert host.file("/usr/src/php").exists is False

  host.run("docker-php-source extract")
  assert host.file("/usr/src/php").exists is True

  host.run("docker-php-source-tarball delete")
  assert host.file("/usr/src/php.tar.xz").exists is False
  assert host.file("/usr/src/php.tar.xz.asc").exists is False
  assert host.file("/usr/src/php").exists is True

  host.run("docker-php-source-tarball clean")
  assert host.file("/usr/src/php").exists is False

@pytest.mark.php_fpm
def test_php_fpm_status_is_enabled(host):
    health_check = host.run("php-fpm-healthcheck -v")
    assert health_check.rc == 0
    assert "pool:" in health_check.stdout
