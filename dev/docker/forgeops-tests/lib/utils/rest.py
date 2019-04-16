# Lib imports
import pytest

# Framework imports
from utils import logger


def check_http_status(http_result, expected_status, known_issue=None):
    """
    Check HTTP status code
    :param http_result : request.models.Response - request response
    :param expected_status : int or list(int) - status codes to detect that application is deployed
    :param known_issue : Jira issue code (ex : OPENAM-567) - used to add a tag
    """

    if isinstance(expected_status, list):
        is_success = (http_result.status_code in [int(x) for x in expected_status])
    else:
        try:
            is_success = (http_result.status_code == int(expected_status))
        except ValueError:
            is_success = False

    if not is_success:
        # if known_issue is not None:
        #     set_known_issue(known_issue)
        pytest.fail('ERROR:\n-- http status --\nreturned %s, expected %s\n-- content --\n%s'
                    % (http_result.status_code, expected_status, http_result.text))
    else:
        success = 'SUCCESS:\n-- http status --\nreturned %s, expected %s' % (http_result.status_code, expected_status)
        logger.info(success)

        content = '\n-- content --\n%s' % http_result.text
        logger.debug(content)
