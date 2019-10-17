import pytest


def pytest_addoption(parser):
    parser.addoption(
        "--tag", action="store", help="The docker tag"
    )


@pytest.fixture
def tag(request):
    return request.config.getoption("--tag")


@pytest.fixture
def container(host, tag, request):
    port = '80'
    run_flags = ''

    if hasattr(request, 'param') and type(request.param) is dict:
        if 'port' in request.param:
            port = request.param['port']
        if 'env' in request.param and type(request.param['env']) is dict:
            run_flags = run_flags.join("-e {}={} ".format(k, v) for (k, v) in request.param['env'].items())

    container = host.check_output('docker run -p {} {} -d {}'.format(port, run_flags, tag))
    yield container
    host.check_output('docker stop {}'.format(container))

    # Remove afterwards thus the tests still have access to the logs
    host.check_output('docker rm -f {}'.format(container))
