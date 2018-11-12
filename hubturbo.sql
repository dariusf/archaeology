# PRs modifying more than 20% of the project files of issues labeled bugs

with bug_related_prs as (
  select i.id as issue, pr.id as id
  from issues i, issues pr, issue_labels il
  where il.label = 'type.bug' and il.issue = i.id and (pr.description like 'Fixes #' || i.id or pr.description like 'Fixes #' || i.id || '.%' or pr.description like 'Fixes #' || i.id || '\n%')),
bug_files as (
  select pr.id, cf.file from bug_related_prs pr, pr_commits pc, commit_files cf where pr.id = pc.pr and pc.sha = cf.sha
),
other_files as (
  select i.id, cf.file from issues i, pr_commits pc, commit_files cf where i.id = pc.pr and pc.sha = cf.sha
)
select r.id, max(r.c) as overlap
from (
  select of.id, count(bf.file)*1.0 / (select count(c.id) from bug_files c where c.id = bf.id) as c
  from other_files of, bug_files bf
  where of.file = bf.file group by of.id, bf.id
) r
group by r.id
order by overlap desc
limit 10;

# Bug-related PRs in order of the percentage of the codebase they touch

select i.id as issue, pr.id as pr, count(cf.file) * 1.0 / (select count(*) as c from files) as percentage_files_touched
from issues i, issues pr, issue_labels il, pr_commits pc, commit_files cf
where il.label = 'type.bug' and il.issue = i.id and (pr.description like 'Fixes #' || i.id or pr.description like 'Fixes #' || i.id || '.%' or pr.description like 'Fixes #' || i.id || '\n%') and pr.id = pc.pr and cf.sha = pc.sha
group by issue, pr
order by percentage_files_touched desc
limit 10;

# all issues linked to PRs modifying file X

select i.id as issue, pr.id as pr, cf.file
from issues i, issues pr, pr_commits pc, commit_files cf
where (pr.description like 'Fixes #' || i.id or pr.description like 'Fixes #' || i.id || '.%' or pr.description like 'Fixes #' || i.id || '\n%')
and pr.id = pc.pr and cf.sha = pc.sha and file = 'UI.java'
limit 10;
