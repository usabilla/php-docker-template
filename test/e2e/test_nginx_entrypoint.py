import pytest


@pytest.mark.nginx_e2e
def test_nginx_sigterm_handling(host, container):
    log_level = host.run('docker exec -t {} sh -c "sed -i \'s/error_log .*;/error_log stderr notice;/g\' /etc/nginx/nginx.conf"'.format(container))
    assert log_level.rc is 0
    assert u'stderr notice' in host.check_output('docker exec -t {} cat /etc/nginx/nginx.conf'.format(container))

    nginx_reload = host.run('docker exec -t {} sh -c "nginx -s reload"'.format(container))
    assert nginx_reload.rc is 0

    nginx_stop = host.run('docker stop -t 3 {}'.format(container))
    assert nginx_stop.rc is 0

    logs = host.run('docker logs {}'.format(container))

    assert u'signal 3 (SIGQUIT) received, shutting down' in logs.stderr
    assert u'exit' in logs.stderr


@pytest.mark.nginx_e2e
@pytest.mark.parametrize('container', [{'env': {'NGINX_PORT': '5556'}, 'port': '5556'}], indirect=True)
def test_nginx_can_host_different_ports(host, container):
    wget_custom_port = host.run('docker exec -t {} sh -c "wget http://127.0.0.1:5556/"'.format(container))
    assert wget_custom_port.rc is 1
    assert u'502 Bad Gateway' in wget_custom_port.stdout
