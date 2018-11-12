#!/usr/bin/env python

from github import Github
import sqlite3
from pydriller import RepositoryMining
from pathlib import Path
import re

with open('env.py', 'r') as f:
  exec(f.read())

def get_issue_references(text):
  '''
  Does not go cross-repo
  '''
  if len(text) < 3:
    return []
  return [int(s[1:]) for s in re.findall(r'#\d+', text)]


def get_github_issues(repo, c):
  '''
  If we run out of quota, this will die and most likely not resume cleanly when restarted
  '''
  g = Github(TOKEN)

  (initial_quota, _) = g.rate_limiting
  print('initial quota: {}'.format(initial_quota))

  for issue in g.get_repo(repo, lazy=True).get_issues(state='all'):
    print(issue.number)
    c.execute('''insert into issues values(?, ?, ?)''', (issue.number, issue.title, issue.body or ''))

    for r in get_issue_references(issue.body or ''):
      c.execute('''insert or ignore into issue_references values(?, ?)''', (issue.number, r))

    if issue.pull_request:
      pr = issue.as_pull_request()
      for commit in pr.get_commits():
        c.execute('''insert into pr_commits values(?, ?)''', (issue.number, commit.sha))

    for label in issue.labels:
      c.execute('''insert or ignore into labels values(?)''', (label.name,))
      c.execute('''insert into issue_labels values(?, ?)''', (issue.number, label.name))

    comment_id = 0
    for comment in issue.get_comments():
      c.execute('''insert into comments values(?, ?, ?, ?)''', (comment_id, issue.number, comment.user.login, comment.body))
      for r in get_issue_references(comment.body):
        c.execute('''insert or ignore into issue_references values(?, ?)''', (issue.number, r))
      comment_id += 1

  (final_quota, _) = g.rate_limiting
  print('final quota: {} (consumed {})'.format(final_quota, initial_quota - final_quota))


def get_repo_info(repo, c):
  local = 'https://github.com/{}.git'.format(repo)
  commit_count = 0
  for commit in RepositoryMining(local).traverse_commits():
    c.execute('''insert into commits values(?)''', (commit.hash,))
    for mod in commit.modifications:
      c.execute('''insert or ignore into files values(?)''', (mod.filename,))
      c.execute('''insert or ignore into commit_files values(?, ?)''', (commit.hash, mod.filename))
    commit_count += 1
    if commit_count % 100 == 0:
      print(commit_count)


def main():

  db = 'repo.db'
  # check this before connecting
  is_new_db = not Path(db).is_file()

  conn = sqlite3.connect(db)
  c = conn.cursor()

  if is_new_db:
    with open('schema.sql', 'r') as f:
      schema = f.read()
    c.executescript(schema)

  repo = 'HubTurbo/HubTurbo'
  print('issues...')
  get_github_issues(repo, c)

  conn.commit()

  print('drilling...')
  get_repo_info(repo, c)

  conn.commit()
  c.close()
  conn.close()

if __name__ == "__main__":
  main()
