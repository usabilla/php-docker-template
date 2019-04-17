import pytest


@pytest.mark.php_fpm_exec
def test_php_fpm_exec_has_dumb_init(host):
    php_fpm_exec = host.run("ps 1")

    assert "dumb-init" in php_fpm_exec.stdout
    assert "--rewrite 2:3" in php_fpm_exec.stdout
    assert "--rewrite 15:3" in php_fpm_exec.stdout
    assert "--rewrite 1:17" in php_fpm_exec.stdout

    assert "shush" not in php_fpm_exec.stdout
