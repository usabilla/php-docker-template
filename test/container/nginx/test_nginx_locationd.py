import pytest

@pytest.mark.nginx
def test_cors(host):
    assert host.file('/etc/nginx/location.d-enabled/cors.conf').exists is False

    enable_cors = host.run('docker-nginx-location.d-enable cors && nginx -s reload')
    assert enable_cors.rc == 0

    assert host.file('/etc/nginx/location.d-enabled/cors.conf').exists is True

    host.run('apk add --no-cache curl')

    options = host.run('curl -i -X OPTIONS http://localhost/')
    assert u'HTTP/1.1 204 No Content' in options.stdout
    assert u'Access-Control-Allow-Origin: *' in options.stdout

    host.run('rm /etc/nginx/location.d-enabled/cors.conf')

@pytest.mark.nginx
def test_cors_entrypoint(host):
    assert host.file('/etc/nginx/location.d-enabled/cors.conf').exists is False

    enable_cors = host.run('NGINX_CORS_ENABLE=true docker-nginx-entrypoint')
    # This is expected since there's already a running nginx
    assert enable_cors.rc == 1

    assert host.file('/etc/nginx/location.d-enabled/cors.conf').exists is True
