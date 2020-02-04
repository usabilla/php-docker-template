import pytest

@pytest.mark.php
def test_php_images_contain_helper_scripts(host):
    official_helper_scripts = [
        "/usr/local/bin/docker-php-entrypoint",
        "/usr/local/bin/docker-php-ext-configure",
        "/usr/local/bin/docker-php-ext-enable",
        "/usr/local/bin/docker-php-ext-install",
        "/usr/local/bin/docker-php-source",
    ]

    for file in official_helper_scripts:
        assert host.file(file).exists is True
        assert host.file(file).is_file is True
        assert host.file(file).mode == 0o775

    helper_scripts = [
        "/usr/local/bin/docker-php-dev-mode",
        "/usr/local/bin/docker-php-entrypoint-init",
        "/usr/local/bin/docker-php-ext-pdo-pgsql",
        "/usr/local/bin/docker-php-ext-rdkafka",
        "/usr/local/bin/docker-php-source-tarball",
        "/usr/local/bin/php-fpm-healthcheck",
    ]

    for file in helper_scripts:
        assert host.file(file).exists is True
        assert host.file(file).is_file is True
        assert host.file(file).mode == 0o755

@pytest.mark.php_dev
def test_php_images_contain_dev_helper_scripts(host):
    file = host.file('/usr/local/bin/docker-php-dev-mode')

    assert file.is_file is True
    assert file.mode == 0o755

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

@pytest.mark.php
def test_php_extension_script_for_rdkafka(host):
    host.run_expect([0], "docker-php-ext-rdkafka")
    assert 'rdkafka' in host.run('php -m').stdout

@pytest.mark.php
def test_php_extension_script_for_pdo_pgsql(host):
    host.run_expect([0], "docker-php-ext-pdo-pgsql")
    assert 'pdo_pgsql' in host.run('php -m').stdout
