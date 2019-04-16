import pytest


@pytest.mark.nginx_e2e
def test_nginx_sigterm_handling(host, container):
    log_level = host.run('docker exec -t {} sh -c "sed -i \'s/error_log .*;/error_log stderr notice;/g\' /etc/nginx/nginx.conf"'.format(container))
    assert log_level.rc is 0
    assert u'stderr notice' in host.check_output('docker exec -t {} cat /etc/nginx/nginx.conf'.format(container))

    nginx_reload = host.run('docker exec -t {} sh -c "nginx -s reload"'.format(container))
    assert nginx_reload.rc is 0

    nginx_stop = host.run('docker stop -t 3 {}'.format(container))
    assert nginx_reload.rc is 0

    logs = host.run('docker logs {}'.format(container))

    assert u'signal 15 (SIGTERM) received, exiting' in logs.stderr
    assert u'exit' in logs.stderr
