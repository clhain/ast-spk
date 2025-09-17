
# author: https://blog.harrison.dev/2016/06/19/integration-testing-with-docker-compose.html
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

cleanup () {
  docker-compose -p ci down -v
}
trap 'cleanup ; printf "${RED}Tests Failed For Unexpected Reasons${NC}\n"' HUP INT QUIT PIPE TERM

run_tests() {
    local compose_file=$1  # The Docker Compose file to use
    docker-compose -p ci -f ${compose_file} build && docker-compose -p ci -f ${compose_file} up -d
    if [ $? -ne 0 ] ; then
    printf "${RED}Docker Compose Failed${NC}\n"
    exit -1
    fi
    TEST_EXIT_CODE=`docker wait ci-integration-tests-1`
    docker logs ci-integration-tests-1
    if [ -z ${TEST_EXIT_CODE+x} ] || [ "$TEST_EXIT_CODE" -ne 0 ] ; then
    printf "${GREEN}========== Collector Logs ===============${NC}\n"
    docker logs ci-otel-collector-1
    printf "${GREEN}========== Test Logs ===============${NC}\n"
    docker logs ci-integration-tests-1
    printf "${RED}Tests Failed${NC} - Exit Code: $TEST_EXIT_CODE\n"
    else
    printf "${GREEN}Tests Passed${NC}\n"
    fi
    cleanup
    exit $TEST_EXIT_CODE
}

run_tests "$1"