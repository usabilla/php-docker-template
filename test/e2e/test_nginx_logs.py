import pytest


@pytest.mark.nginx_e2e
def test_nginx_logs_to_stdout_and_stderr(host, container):
    nginx_port = host.check_output("docker inspect " + container + " --format '{{ (index (index .NetworkSettings.Ports \"80/tcp\") 0).HostPort }}'")

    wget = host.run('wget -O /dev/null -S 127.0.0.1:{}/invalid'.format(nginx_port))
    assert wget.rc is not 0

    logs = host.run('docker logs {}'.format(container))

    assert 'GET /invalid' in logs.stdout
    assert 'connect() to unix:/var/run/php-fpm.sock failed' in logs.stderr
