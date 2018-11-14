
create table issues (
  id integer primary key,
  title text not null,
  description text not null
);

create table comments (
  id integer,
  issue_id integer,
  user text not null,
  comment text not null,
  primary key (id, issue_id),
  foreign key (issue_id) references issues(id)
);

create table labels (
  name text primary key
);

create table issue_labels (
  issue integer,
  label text,
  primary key (issue, label),
  foreign key (issue) references issues(id),
  foreign key (label) references labels(name)
);

create table issue_references (
  issue_from integer,
  issue_to integer,
  primary key (issue_from, issue_to),
  foreign key (issue_from) references issues(id),
  foreign key (issue_to) references issues(id)
);

create table commits (
  sha text primary key
);

create table pr_commits (
  pr integer,
  sha text,
  primary key (pr, sha),
  foreign key (pr) references issues(id),
  foreign key (sha) references commits(sha)
);

create table files (
  name text primary key
);

create table commit_files (
  sha text,
  file text,
  primary key (sha, file),
  foreign key (sha) references commits(sha),
  foreign key (file) references files(name)
);

create table commit_diff_tokens (
sha text,
file text,
plus bool,
token text,
primary key (sha, file, plus, token),
foreign key (sha) references commits(sha),
foreign key (file) references files(name)
);
