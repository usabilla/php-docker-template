import pytest

@pytest.mark.php_dev
@pytest.mark.php_no_dev
def test_php_composer_is_available_only_on_dev_images(host):
    composer = host.run("composer")
    assert composer.rc == 0
    assert "Available commands:" in composer.stdout
