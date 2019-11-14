import pytest

@pytest.mark.php_dev
def test_php_composer_is_available_only_on_dev_images(host):
    composer = host.run("composer")
    assert composer.rc == 0
    assert "Available commands:" in composer.stdout

@pytest.mark.php_no_dev
def test_php_composer_isnt_available_on_non_dev_images(host):
    composer = host.run("composer")
    assert composer.rc == 127
    assert "composer" in composer.stderr
    assert "not found" in composer.stderr
    assert "" == composer.stdout
