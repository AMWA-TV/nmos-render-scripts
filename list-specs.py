#!/usr/bin/env python3

import json
import argparse
import requests

SPECS_JSON_URL='https://amwa-tv.github.io/nmos/specs.json'
REPO_ROOT='https://github.com/AMWA-TV/'
DOCS_ROOT='https://amwa-tv.github.io/'
API_ROOT='https://api.github.com/repos/AMWA-TV/'

parser = argparse.ArgumentParser(description='List NMOS Specifications.')
group = parser.add_mutually_exclusive_group(required=True)
group.add_argument('-r', '--repo', dest='format', action='store_const', const='repo',
                    help='Output list of repositories')
group.add_argument('-t', '--table', dest='format', action='store_const', const='table',
                    help='Output as Markdown table')
group.add_argument('-m', '--menu', dest='format', action='store_const', const='menu',
                    help='Output as HTML menu')
group.add_argument('-i', '--issues', dest='format', action='store_const', const='issues',
                    help='Output GitHub issues (use sparingly)')
                

args = parser.parse_args()
format = args.format

if format == 'table':
    print('Id | Name  | Spec Status | Release(s) | Repository')
    print(':--:|:---:|:---:|:---:|:--:')

elif format == 'menu':
    print('<div class="dropdown-content">')

elif format == 'issues':
    print('Spec | Issue | Description')
    print(':--:|:--:|:--')


# Local file
# spec_file = open('specs.json', 'r');
# specs = json.load(spec_file)

specs=requests.get(SPECS_JSON_URL).json()

for spec in specs:
    repo = spec['repository']
    repo_url = REPO_ROOT + repo
    docs_url = DOCS_ROOT + repo

    if format == 'repo':
        print(repo)

    elif format == 'table':
        release_str = ''
        for release in spec['releases']:
            release_str += '[' + release + ']' + '(' + docs_url + '/tags/' + release + ')' + '[↓]' + '(' + repo_url + '/releases/tag/' + release + ')<br/>'
        
        print('| ', spec['id'], ' | [', spec['name'], '](', docs_url, ') | ', spec['status'], ' | ', release_str, ' | [', repo, '](', repo_url, ') |', sep='')

    elif format == 'menu':
        print('<p><a href="', docs_url, '">', spec['id'], ' ', spec['name'], '</a></p>', sep='')

    elif format == 'issues':
        issues = requests.get(API_ROOT + repo + '/issues?state=open').json()
        for issue in issues:
            print('| ', spec['id'], ' | ', issue['number'], ' | [', issue['title'], '](', issue['html_url'], ')|', sep='')

    if format == 'menu':
        print('</div>')

