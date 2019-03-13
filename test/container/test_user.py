import pytest

@pytest.mark.php
@pytest.mark.nginx
def test_userPresent(host):
    userName = 'app'
    groupName = 'app'
    homeDir = '/home/app'

    usr = host.user(userName)
    assert userName in usr.name
    assert groupName in usr.group
    assert homeDir in usr.home
