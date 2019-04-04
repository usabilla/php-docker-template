import pytest

@pytest.mark.php_dev
def test_configuration_is_present(host):
    assert host.file('/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini').exists is True
    assert host.file('/usr/local/etc/php/conf.d/zzz_xdebug.ini').exists is True
    assert host.file('/usr/local/etc/php/conf.d/zzz_dev.ini').exists is True

@pytest.mark.php_dev
def test_configuration_files_are_loaded(host):
    files = get_loaded_config_files(host)

    assert '/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini' in files
    assert '/usr/local/etc/php/conf.d/zzz_dev.ini' in files
    assert '/usr/local/etc/php/conf.d/zzz_xdebug.ini' in files

@pytest.mark.php_dev
def test_configuration_is_effective(host):
    configuration = host.run('php -i').stdout

    assert u'expose_php => On => On' in configuration
    assert u'opcache.validate_timestamps => On => On' in configuration
    assert u'zend.assertions => 1 => 1' in configuration

@pytest.mark.php_dev
def test_xdebug_is_loaded(host):
    assert 'Xdebug' in host.run('php -m').stdout

@pytest.mark.php_no_dev
def test_configuration_is_not_present(host):
    assert host.file('/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini').exists is False
    assert host.file('/usr/local/etc/php/conf.d/zzz_xdebug.ini').exists is False
    assert host.file('/usr/local/etc/php/conf.d/zzz_dev.ini').exists is False

@pytest.mark.php_no_dev
def test_configuration_files_are_not_loaded(host):
    files = get_loaded_config_files(host)

    assert '/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini' not in files
    assert '/usr/local/etc/php/conf.d/zzz_dev.ini' not in files
    assert '/usr/local/etc/php/conf.d/zzz_xdebug.ini' not in files

@pytest.mark.php_no_dev
def test_configuration_is_not_effective(host):
    configuration = host.run('php -i').stdout

    assert u'expose_php => Off => Off' in configuration
    assert u'opcache.validate_timestamps => Off => Off' in configuration
    assert u'zend.assertions => -1 => -1' in configuration

@pytest.mark.php_no_dev
def test_xdebug_is_not_loaded(host):
    assert 'Xdebug' not in host.run('php -m').stdout

def get_loaded_config_files(host):
    return host.run('php --ini').stdout
