import pytest

@pytest.mark.nginx_fpm_functional
def test_fpm_can_create_file(host):
    testFile = "/opt/project/public/tmp/temptestfile"
    responseFile = "/opt/project/public/tmp/response" 
    host.run("rm {0}".format(testFile))
    assert host.file(testFile).exists is False

    assert host.file("/var/run/php-fpm.sock").exists

    assert host.run("wget -O /opt/project/public/tmp/response -S http://localhost/?testFile=true")
    response = host.file(responseFile)
    assert response.exists is True
    assert "Wrote" in response.content_string

    assert host.file(testFile).exists is True
    assert host.file(testFile).user == "app"
    assert host.file(testFile).group == "app"
    assert host.file(testFile).mode == 0o644

    host.run("rm {0}".format(testFile))
