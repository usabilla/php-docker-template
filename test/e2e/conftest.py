import pytest


def pytest_addoption(parser):
    parser.addoption(
        "--tag", action="store", help="The docker tag"
    )


@pytest.fixture
def tag(request):
    return request.config.getoption("--tag")

@pytest.fixture
def container(host, tag):
    container = host.check_output('docker run -p 80 --rm -d {}'.format(tag))
    yield container
    host.check_output('docker stop {}'.format(container))
