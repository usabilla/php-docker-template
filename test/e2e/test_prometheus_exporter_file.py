import pytest
import requests


@pytest.mark.prometheus_exporter_file_e2e
def test_prometheus_exporter_file_propagates_content_type_text(host, container):
    sleep = host.run('sleep 1')
    assert sleep.rc is 0

    nginx_port = host.check_output("docker inspect " + container + " --format '{{ (index (index .NetworkSettings.Ports \"80/tcp\") 0).HostPort }}'")

    req_root = requests.get("http://localhost:{}/".format(nginx_port))
    assert req_root.status_code == 404

    add_file = host.run('docker exec -t {} sh -c "mkdir -p /opt/project/public && echo -n \'Hey there!\' > /opt/project/public/hi"'.format(container))
    assert add_file.rc is 0

    req_file = requests.get("http://localhost:{}/hi".format(nginx_port))
    assert req_file.status_code == 200
    assert req_file.text == u'Hey there!'
    
    assert 'content-type' in req_file.headers
    assert req_file.headers['content-type'] == 'text/plain; charset=UTF-8'

@pytest.mark.prometheus_exporter_file_e2e
def test_prometheus_exporter_file_propagates_content_type_json(host, container):
    sleep = host.run('sleep 1')
    assert sleep.rc is 0

    nginx_port = host.check_output("docker inspect " + container + " --format '{{ (index (index .NetworkSettings.Ports \"80/tcp\") 0).HostPort }}'")

    req_root = requests.get("http://localhost:{}/".format(nginx_port))
    assert req_root.status_code == 404

    add_file = host.run('docker exec -t {} sh -c "mkdir -p /opt/project/public && echo -n \'{}\' > /opt/project/public/hi.json"'
        .format(container, '{\\"text\\": \\"Hi thére!\\"}')
        )
    assert add_file.rc is 0

    req_file = requests.get("http://localhost:{}/hi.json".format(nginx_port))
    assert req_file.status_code == 200
    assert req_file.text == u'{"text": "Hi thére!"}'
    
    assert 'content-type' in req_file.headers
    assert req_file.headers['content-type'] == 'application/json'
