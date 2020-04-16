import subprocess
import sys
import datetime
import argparse
import operator
import os
import requests

SPRINT_DATE_FMT = '%Y.%m.%d'
GH_REPO = os.environ.get('GH_REPO', 'forgerock/forgeops')
GH_API_URL = f'https://api.github.com/repos/{GH_REPO}/releases'
print(GH_API_URL)
def run(*args):
    result = subprocess.run(args, capture_output=True)
    if result.returncode != 0:
        raise Exception(result.stderr.decode().strip())
    return result.stdout.decode().strip()

def parse_tag(tag):
    sprint_date_str, sprint_name = tag.split('-')
    sprint_date = datetime.datetime.strptime(sprint_date_str, SPRINT_DATE_FMT)
    sprint_name_parts = sprint_name.split('.')
    if len(sprint_name_parts) > 1:
        sprint_name = sprint_name_parts[0]
        patch = sprint_name_parts[1]
        return sprint_date, sprint_name, patch
    patch = '0'
    return sprint_date, sprint_name, patch

def find_last_tag(args):
    if args.tag_name:
        tag_name = args.tag_name
    else:
        tag_name = active_tag()
    try:
        sprint_date, sprint_name, patch = parse_tag(tag_name)
    except ValueError as e:
        print("tag didn't meet proper format")
    except Exception as e:
        print(e)
        sys.exit(1)
    try:
        tag_list = run('git', 'tag', '--list').split('\n')
    except Exception as e:
        print(e)
        sys.exit(1)
    possible_tags = []
    for t in tag_list:
        try:
            parsed = parse_tag(t)
        except ValueError as e:
            continue
        if parsed[0] < sprint_date:
            possible_tags.append(parsed)
    # sort by date, then patch
    possible_tags.sort(key=operator.itemgetter(0, 2), reverse=True)
    last_tag = possible_tags[0]
    if last_tag[2] != '0':
        out = '{}-{}.{}'.format(last_tag[0].strftime(SPRINT_DATE_FMT),
                                *last_tag[1:])
        print(out)
        sys.exit(0)

    print('{}-{}'.format(last_tag[0].strftime(SPRINT_DATE_FMT),
                         last_tag[1]))

def create_release_notes(args):
    try:
        token = os.environ['GH_TOKEN']
    except KeyError:
        print('GH_TOKEN environment variable required')
    notes = ''.join(l for l in args.notes.readlines())
    body = {'tag_name': args.tag_name,
            'name': args.tag_name,
            'body': notes,
            'draft': True}
    try:
        res = requests.post(GH_API_URL,
                            json=body,
                            headers={'Authorization': f'token {token}'},
                            timeout=30)
        res.raise_for_status()
    except Exception as e:
        print(e)
        sys.exit(1)
    print('release created')

def active_tag():
    try:
        commit_sha = run('git', 'rev-parse', 'HEAD')
        tag_name = run('git', 'name-rev', '--tag', '--name-only', commit_sha)
    except Exception as e:
        print(e)
        sys.exit(1)
    if tag_name == 'undefined':
        print('not on a tag')
        sys.exit(1)
    return tag_name

def current_tag(args):
    print(active_tag())

def main():
    parser = argparse.ArgumentParser(description='ForgeOps Repo Command Line')
    subparsers = parser.add_subparsers(help='sub-command help')
    subparsers.dest = 'command'

    # prior tag
    prior_tag_parser = subparsers.add_parser('prior-tag',
                                             help=('determine the tag prior to'
                                                   ' the current tag'))
    prior_tag_parser.add_argument('-t', '--tag-name',
                                  help=('use this tag as the current tag '
                                        'instead of the current commit'))
    prior_tag_parser.set_defaults(func=find_last_tag)

    # current tag
    current_tag_parser = subparsers.add_parser('current-tag',
                                               help=('print the current tag'))
    current_tag_parser.set_defaults(func=current_tag)

    # create release
    release_parser = subparsers.add_parser('create-release',
                                           help=('create a draft release on '
                                                 'github with notes'))
    release_parser.add_argument('-t', '--tag-name', default=active_tag(),
                                help=('tag name of release. defaults to '
                                      'active tag'))
    release_parser.add_argument('notes', type=argparse.FileType('r'),
                                default=sys.stdin)
    release_parser.set_defaults(func=create_release_notes)

    args = parser.parse_args()
    args.func(args)
