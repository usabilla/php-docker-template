import pytest

@pytest.mark.php
@pytest.mark.nginx
def test_userPresent(host):
    userName = 'app'
    groupName = 'app'
    homeDir = '/home/app'
    shell = '/sbin/halt'

    usr = host.user(userName)
    assert userName in usr.name
    assert groupName in usr.group
    assert homeDir in usr.home
    assert shell in usr.shell

@pytest.mark.php_fpm
def test_fpm_can_create_file(host):
    testFile = "/tmp/temptestfile" 
    host.run("rm {0}".format(testFile))

    assert host.file(testFile).exists is False
    host.run("wget -O /dev/null http://nginx?testFile=true")
    assert host.file(testFile).exists is True
    assert host.file(testFile).user == "app"
    assert host.file(testFile).group == "app"
    assert host.file(testFile).mode == 0o644

    host.run("rm {0}".format(testFile))
