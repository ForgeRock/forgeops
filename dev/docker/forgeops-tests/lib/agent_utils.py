from bs4 import BeautifulSoup


def process_autosubmit_form(resp, session):
    """
    Workaround method for agent autosubmit page as requests doesn't support JS
    :param resp: Response to parse and make request as workaround for agent autosubmit page
    :param session: Session into which store cookies
    :return: Response from autosubmit page. As redirect is enabled by default, this will simply return originally
             requested page
    """

    autosub = BeautifulSoup(resp.text, 'html.parser')
    cdsso_url = autosub.body.form['action']
    idtoken_value = autosub.body.form.input['value']
    state_value = autosub.body.form.input.next_sibling['value']
    scope_value = 'openid'

    payload = {'id_token': idtoken_value,
               'state': state_value,
               'scope': scope_value}

    return session.post(url=cdsso_url, data=payload)
