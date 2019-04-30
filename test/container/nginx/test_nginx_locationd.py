import pytest

@pytest.mark.nginx
def test_cors(host):
    enable_cors = host.run('docker-nginx-location.d-enable cors && nginx -s reload')
    assert enable_cors.rc == 0

    assert host.file('/etc/nginx/location.d-enabled/cors.conf').exists is True

    host.run('apk add --no-cache curl')

    options = host.run('curl -i -X OPTIONS http://localhost/')
    assert u'HTTP/1.1 204 No Content' in options.stdout
    assert u'Access-Control-Allow-Origin: *' in options.stdout
