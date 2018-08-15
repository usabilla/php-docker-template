import pytest

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
