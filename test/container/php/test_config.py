import pytest

CONFIG_DIR = '/usr/local/etc/php'

@pytest.mark.php
def test_php_ini_dir_environment_variable_is_set(host):
    assert CONFIG_DIR == host.run('echo -n $PHP_INI_DIR').stdout

@pytest.mark.php
def test_php_config_files_are_present(host):
    assert host.file(CONFIG_DIR + '/php.ini-development').exists is True
    assert host.file(CONFIG_DIR + '/php.ini-production').exists is True

@pytest.mark.php
def test_php_base_config_is_present(host):
    assert host.file(CONFIG_DIR + '/php.ini').is_symlink is True

@pytest.mark.php_no_dev
def test_production_config_link(host):
    host.file(CONFIG_DIR + '/php.ini').linked_to is '{}/php.ini-production'.format(CONFIG_DIR)

@pytest.mark.php_dev
def test_development_config_link(host):
    host.file(CONFIG_DIR + '/php.ini').linked_to is '{}/php.ini-development'.format(CONFIG_DIR)

@pytest.mark.php
def test_config_files_are_loaded(host):
    files = get_loaded_config_files(host)

    assert '/usr/local/etc/php/php.ini' in files
    assert '/usr/local/etc/php/conf.d/default.ini' in files
    assert '/usr/local/etc/php/conf.d/docker-php-ext-apcu.ini' in files
    assert '/usr/local/etc/php/conf.d/docker-php-ext-opcache.ini' in files
    assert '/usr/local/etc/php/conf.d/docker-php-ext-sodium.ini' in files

@pytest.mark.php_no_dev
def test_production_config_is_effective(host):
    config = get_config(host)

    assert u'display_errors => Off => Off' in config
    assert u'display_startup_errors => Off => Off' in config
    assert u'error_reporting => 22527 => 22527' in config

@pytest.mark.php_dev
def test_development_config_is_effective(host):
    config = get_config(host)

    assert u'display_errors => STDOUT => STDOUT' in config
    assert u'display_startup_errors => On => On' in config
    assert u'error_reporting => 32767 => 32767' in config

@pytest.mark.php_cli
def test_cli_configuration_is_effective(host):
    config = get_config(host)

    assert u'memory_limit => -1 => -1' in config
    assert u'opcache.enable_cli => On => On' in config
    assert u'apc.enable_cli => On => On' in config

@pytest.mark.php_fpm
def test_fpm_configuration_is_effective(host):
    config = get_config(host)

    assert u'memory_limit => -1 => -1' in config

def get_config(host):
    return host.run('php -i').stdout

def get_loaded_config_files(host):
    return host.run('php --ini').stdout
