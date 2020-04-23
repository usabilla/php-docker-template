import pytest


@pytest.mark.php_fpm_exec
def test_php_fpm_exec_has_dumb_init(host):
    php_fpm_exec = host.run("ps 1")

    assert "dumb-init" in php_fpm_exec.stdout
    assert "--rewrite 2:3" in php_fpm_exec.stdout
    assert "--rewrite 15:3" in php_fpm_exec.stdout
    assert "--rewrite 1:17" in php_fpm_exec.stdout

    assert "shush" not in php_fpm_exec.stdout

@pytest.mark.php_fpm_exec
def test_php_fpm_default_config(host):
    config_docker = host.file(
        "/usr/local/etc/php-fpm.d/zz-docker.conf")

    assert config_docker.exists is True
    assert config_docker.is_file is True

    # Remove our custom configuration config in order to check
    # the upstream default configuration
    host.run("mv /usr/local/etc/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf.unused")

    config_effective = host.run("php-fpm -tt").stderr

    assert "access.log = /proc/self/fd/2" in config_effective
    assert "error_log = /proc/self/fd/2" in config_effective
    assert "clear_env = no" in config_effective
    assert "catch_workers_output = yes" in config_effective

    host.run("mv /usr/local/etc/php-fpm.d/zz-docker.conf.unused /usr/local/etc/php-fpm.d/zz-docker.conf")

@pytest.mark.php_fpm_exec_73
@pytest.mark.php_fpm_exec_74
def test_php_fpm_default_config_modern(host):
    # Remove our custom configuration config in order to check
    # the upstream default configuration
    host.run("mv /usr/local/etc/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf.unused")

    config_effective = host.run("php-fpm -tt").stderr

    assert "log_limit = 8192" in config_effective
    assert "decorate_workers_output = no" in config_effective

    host.run("mv /usr/local/etc/php-fpm.d/zz-docker.conf.unused /usr/local/etc/php-fpm.d/zz-docker.conf")

@pytest.mark.php_fpm_exec
def test_php_fpm_templates_config_file(host):
    config_file = host.file("/usr/local/etc/php-fpm.d/zz-docker.conf")

    assert config_file.exists is True
    assert config_file.is_file is True

    # Test default configuration for FPM PM
    config = config_file.content_string

    assert "pm = dynamic" in config
    assert "pm.max_children = 5" in config
    assert "pm.start_servers = 2" in config
    assert "pm.min_spare_servers = 1" in config
    assert "pm.max_spare_servers = 3" in config
    assert "pm.process_idle_timeout = 10" in config
    assert "pm.max_requests = 0" in config

    # Test effective configuration
    config_effective = host.run("php-fpm -tt").stderr

    assert "pm = dynamic" in config_effective
    assert "pm.max_children = 5" in config_effective
    assert "pm.start_servers = 2" in config_effective
    assert "pm.min_spare_servers = 1" in config_effective
    assert "pm.max_spare_servers = 3" in config_effective
    assert "pm.process_idle_timeout = 10" in config_effective
    assert "pm.max_requests = 0" in config_effective


@pytest.mark.php_fpm_exec
def test_php_fpm_templates_config_file_all_vars(host):
    config_template = host.file(
        "/usr/local/etc/php-fpm.d/zz-docker.conf.template")

    assert config_template.exists is True
    assert config_template.is_file is True

    # This will replace the "zz-docker.conf" file with the new ENV configuration
    replace_template = host.run('''
    PHP_FPM_PM=static
    PHP_FPM_PM_MAX_CHILDREN=70
    PHP_FPM_PM_START_SERVERS=10
    PHP_FPM_PM_MIN_SPARE_SERVERS=20
    PHP_FPM_PM_MAX_SPARE_SERVERS=40 
    PHP_FPM_PM_PROCESS_IDLE_TIMEOUT=35
    PHP_FPM_PM_MAX_REQUESTS=500
    docker-php-entrypoint-init php-fpm -tt
    ''')

    assert replace_template.rc is 0
    assert "NOTICE: configuration file /usr/local/etc/php-fpm.conf test is successful" in replace_template.stderr

    config = host.file(
        "/usr/local/etc/php-fpm.d/zz-docker.conf").content_string

    # Test default configuration for FPM PM
    assert "pm = static" in config
    assert "pm.max_children = 70" in config
    assert "pm.start_servers = 10" in config
    assert "pm.min_spare_servers = 20" in config
    assert "pm.max_spare_servers = 40" in config
    assert "pm.process_idle_timeout = 35" in config
    assert "pm.max_requests = 500" in config
